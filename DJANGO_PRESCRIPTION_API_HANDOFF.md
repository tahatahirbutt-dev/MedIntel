# MedIntel — Prescription Scan API Handoff (Flutter → Django)

## Context

The Flutter mobile app (separate repo) needs one new JSON endpoint from the
Django server so it can send a photo of a prescription and get back the
extracted medicines. This replaces a temporary Claude API integration used
during development — the Flutter side wants to use the existing fine-tuned
TrOCR pipeline instead, since it's local, real, and matches this project's
"no external API keys" constraint.

**Ask:** wrap the existing OCR + matching pipeline in one new view that
returns JSON instead of rendering a template. No new AI/OCR logic needed —
this is purely an API surface on top of what already works.

## Endpoint spec

### `POST /api/prescription/scan/`

**Request**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Field: `image` — the prescription photo file (jpg/png)

**Success response — 200**
```json
{
  "medicines": [
    {
      "name": "Amoxicillin",
      "dosage": "500mg",
      "frequency": "Three times daily",
      "duration": "7 days",
      "alternatives": ["Azithromycin", "Cephalexin"]
    }
  ]
}
```
- `medicines` must be a JSON array — empty array `[]` is fine if nothing was
  extracted (the Flutter app will show a "no medicines found" message).
- `name` is the only field that must be non-empty per entry. If the pipeline
  doesn't reliably extract `dosage`/`frequency`/`duration`, send empty
  strings for those — don't omit the keys.
- `alternatives` can come from the medicine catalog's related-drug data per
  matched entry if you have it; an empty array is fine if not.

**Failure response — 4xx/5xx**
```json
{ "error": "human-readable message" }
```

## Implementation notes

- Reuse whatever function the existing "Profile → Prescriptions → Upload New
  Prescription" view already calls — this new endpoint should be a thin
  JSON-returning wrapper around the same OCR + `_match_medicines()` pipeline
  in `user/ai_prescription_service.py`, not a second pipeline.
- Mark the view `@csrf_exempt`. The Flutter app has no Django session/CSRF
  cookie to attach a token from. Fine for a local demo; add a shared-secret
  header check instead if you want a bit more safety without full auth.
- No login required unless you want it — an open endpoint on your local
  network is fine for the defense.
- Known limitation from your own notes: line segmentation is tuned to one
  hospital's prescription layout and can misfire on others. Worth testing
  with whatever photo you plan to actually demo, in advance.

## Network setup — required for two machines to talk to each other

1. Run the server bound to all interfaces, not just localhost:
   ```
   .\venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
   ```
2. In `medintel/settings.py`, make sure `ALLOWED_HOSTS` includes your
   machine's LAN IP (or set `ALLOWED_HOSTS = ['*']` temporarily for the
   demo). Without this, Django rejects every request from the phone with a
   `DisallowedHost` 400 error.
3. If Windows Firewall prompts when the server starts, allow it (private
   network).
4. Find your LAN IP: `ipconfig` → **IPv4 Address** under your active Wi-Fi
   adapter (e.g. `192.168.1.42`). Send that IP to your partner — it goes
   into the Flutter app's config.
5. Both machines need to be on the **same Wi-Fi network**. If the venue's
   Wi-Fi has client isolation (common on campus/guest networks), this won't
   work — have a personal hotspot ready as backup.

## How to test it without the Flutter app

```
curl -X POST http://127.0.0.1:8000/api/prescription/scan/ \
  -F "image=@/path/to/a/test_prescription.jpg"
```

If that returns the JSON shape above, the Flutter side will work once
pointed at your LAN IP instead of `127.0.0.1`.

## Timeline

Needed for a defense tomorrow. The endpoint itself is a small, contained
change since it wraps existing code — the real risk is steps in "Network
setup" above (firewall/`ALLOWED_HOSTS` surprises) and untested OCR accuracy
on the actual demo photo, not writing the view itself.
