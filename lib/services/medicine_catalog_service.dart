import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Offline catalogue of 18,793 Pakistani medicines.
///
/// The database ships inside the APK as an asset and is copied to the app's
/// documents directory on first launch. Every query below runs entirely on the
/// device: no network, no API key, no backend dependency.
///
/// All methods return `Map<String, dynamic>` using the same keys as
/// [MockDataService.mockMedicines], so existing screens work unchanged.
class MedicineCatalogService {
  MedicineCatalogService._internal();
  static final MedicineCatalogService instance =
      MedicineCatalogService._internal();

  static const String _assetPath = 'assets/db/medintel_catalog.db';
  static const String _fileName = 'medintel_catalog.db';

  /// Bump this when you ship a new catalogue file so the old copy is replaced.
  static const int _catalogVersion = 1;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _fileName);
    final stamp = File(p.join(dir.path, '$_fileName.version'));

    final needsCopy = !await File(path).exists() ||
        !await stamp.exists() ||
        (await stamp.readAsString()).trim() != '$_catalogVersion';

    if (needsCopy) {
      final data = await rootBundle.load(_assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
      await stamp.writeAsString('$_catalogVersion');
    }

    return openDatabase(path, readOnly: true);
  }

  /// Call once at startup (e.g. in a splash screen) so the first search is
  /// instant instead of waiting on the ~26 MB asset copy.
  Future<void> warmUp() async {
    final db = await _database;
    await db.rawQuery('SELECT 1 FROM medicines LIMIT 1');
  }

  Future<int> totalCount() async {
    final db = await _database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM medicines');
    return (rows.first['c'] as int?) ?? 0;
  }

  // ───────────────────────────── search ─────────────────────────────

  /// Searches name, generic and brand. Prefix matches rank first, so typing
  /// "pana" puts the Panadol family at the top rather than buried.
  Future<List<Map<String, dynamic>>> searchMedicines(
    String query, {
    int limit = 60,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final db = await _database;
    final like = '%$q%';
    final prefix = '$q%';

    final rows = await db.rawQuery(
      '''
      SELECT * FROM medicines
      WHERE name_lower LIKE ?
         OR LOWER(generic) LIKE ?
         OR LOWER(brand) LIKE ?
      ORDER BY
        CASE
          WHEN name_lower LIKE ? THEN 0
          WHEN LOWER(generic) LIKE ? THEN 1
          ELSE 2
        END,
        LENGTH(name),
        name
      LIMIT ?
      ''',
      [like, like, like, prefix, prefix, limit],
    );

    return rows.map(_toMap).toList();
  }

  /// A–Z browsing, matching the alphabet filter on the web store.
  /// Pass '#' for names that start with a digit or symbol.
  Future<List<Map<String, dynamic>>> browseByLetter(
    String letter, {
    int limit = 30,
    int offset = 0,
  }) async {
    final db = await _database;
    final rows = await db.query(
      'medicines',
      where: 'first_letter = ?',
      whereArgs: [letter.toUpperCase()],
      orderBy: 'name',
      limit: limit,
      offset: offset,
    );
    return rows.map(_toMap).toList();
  }

  // ───────────────────────────── detail ─────────────────────────────

  Future<Map<String, dynamic>?> getMedicineDetails(String idOrSlug) async {
    final db = await _database;
    final asInt = int.tryParse(idOrSlug);

    final rows = await db.query(
      'medicines',
      where: asInt != null ? 'id = ? OR slug = ?' : 'slug = ?',
      whereArgs: asInt != null ? [asInt, idOrSlug] : [idOrSlug],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final map = _toMap(rows.first);
    map['alternatives'] = (await getAlternatives(idOrSlug))
        .map((m) => m['name'] as String)
        .toList();
    return map;
  }

  /// Same active ingredient, different product — the offline equivalent of the
  /// web app's alternatives feature. Cheapest in-stock options first.
  Future<List<Map<String, dynamic>>> getAlternatives(
    String idOrSlug, {
    int limit = 8,
  }) async {
    final db = await _database;
    final asInt = int.tryParse(idOrSlug);

    final self = await db.query(
      'medicines',
      columns: ['id', 'generic_base'],
      where: asInt != null ? 'id = ? OR slug = ?' : 'slug = ?',
      whereArgs: asInt != null ? [asInt, idOrSlug] : [idOrSlug],
      limit: 1,
    );
    if (self.isEmpty) return [];

    final base = (self.first['generic_base'] as String?) ?? '';
    if (base.isEmpty) return [];

    final rows = await db.query(
      'medicines',
      where: 'generic_base = ? AND id != ?',
      whereArgs: [base, self.first['id']],
      orderBy: 'price ASC',
      limit: limit,
    );
    return rows.map(_toMap).toList();
  }

  /// Cheaper products with the same active ingredient — useful for a
  /// "save PKR X" badge on the detail screen.
  Future<List<Map<String, dynamic>>> cheaperAlternatives(
    String idOrSlug,
  ) async {
    final current = await getMedicineDetails(idOrSlug);
    if (current == null) return [];
    final price = (current['price'] as num?)?.toDouble() ?? 0;
    final alts = await getAlternatives(idOrSlug, limit: 20);
    return alts
        .where((m) => ((m['price'] as num?)?.toDouble() ?? 0) < price)
        .toList();
  }

  /// The most common active ingredients — use these as dynamic filter chips
  /// instead of the hardcoded mock categories.
  Future<List<String>> topGenerics({int limit = 12}) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT generic_base, COUNT(*) AS c
      FROM medicines
      WHERE generic_base <> ''
      GROUP BY generic_base
      ORDER BY c DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows
        .map((r) => _titleCase(r['generic_base'] as String? ?? ''))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Matches OCR-extracted medicine names against the catalogue.
  /// Wire this to the prescription result screen so extracted names become
  /// real, orderable products.
  Future<List<Map<String, dynamic>>> matchExtractedNames(
    List<String> names,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (final name in names) {
      final hits = await searchMedicines(name, limit: 1);
      if (hits.isNotEmpty) out.add(hits.first);
    }
    return out;
  }

  // ───────────────────────────── mapping ─────────────────────────────

  Map<String, dynamic> _toMap(Map<String, Object?> r) {
    final generic = (r['generic'] as String?) ?? '';
    return {
      'id': (r['slug'] as String?)?.isNotEmpty == true
          ? r['slug']
          : '${r['id']}',
      'dbId': r['id'],
      'name': r['name'] ?? '',
      'brand': r['brand'] ?? '',
      'generic': generic,
      'category': _titleCase((r['generic_base'] as String?) ?? ''),
      'dosage': _extractDosage(generic),
      'frequency': '',
      'duration': '',
      'chemicalFormula': r['chemical_formula'] ?? '',
      'description': r['uses'] ?? '',
      'uses': r['uses'] ?? '',
      'howToUse': r['how_to_use'] ?? '',
      'indications': r['indications'] ?? '',
      'sideEffects': _toBullets(r['side_effects'] as String?),
      'seriousSideEffects': const <String>[],
      'warnings': const <String>[],
      'alternatives': const <String>[],
      'price': (r['price'] as num?)?.toDouble() ?? 0.0,
      'stock': r['stock_quantity'] ?? 0,
      'inStock': ((r['stock_quantity'] as int?) ?? 0) > 0,
      'imageUrl': r['image_url'] ?? '',
    };
  }

  List<String> _toBullets(String? text) {
    if (text == null || text.trim().isEmpty) return const [];
    return text
        .split(RegExp(r'[.;]\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 3)
        .take(8)
        .toList();
  }

  /// Pulls "500mg" out of "Paracetamol (500mg)".
  String _extractDosage(String generic) {
    final m = RegExp(r'\(([^)]*)\)').firstMatch(generic);
    return m != null ? m.group(1)!.trim() : '';
  }

  String _titleCase(String s) {
    if (s.isEmpty) return '';
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
