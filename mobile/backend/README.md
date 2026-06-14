# Liver Flap Check — backend

A one-function backend that stores results in MongoDB Atlas (collection `MobileRes`).
The iOS app POSTs the structured result here; the MongoDB connection string stays
**server-side only**.

`POST /api/save-result` with JSON body:
```json
{ "outcome": "...", "decision": "...", "flapEvents": 0, "pattern": "...",
  "symmetry": "...", "confidence": "...", "postureValid": true,
  "summary": "...", "note": "..." }
```
Header (if `API_KEY` is set): `x-api-key: <your key>`.

## Deploy (Vercel)

1. **Rotate** the Atlas DB password first (the earlier one was shared in chat).
2. From this `backend/` folder:
   ```bash
   npm install
   npx vercel            # link/create the project
   ```
3. Set environment variables (Production + Preview):
   ```bash
   npx vercel env add MONGODB_URI       # the SRV string with the rotated password
   npx vercel env add MONGODB_DB        # e.g. health_checker
   npx vercel env add API_KEY           # a long random string
   ```
4. Deploy:
   ```bash
   npx vercel --prod
   ```
5. In Atlas → Network Access, allow Vercel egress (simplest for a prototype:
   `0.0.0.0/0`; tighten later).
6. Copy the deployed URL into the iOS app:
   - `Sources/Backend/BackendConfig.swift` → `resultEndpoint = "https://<your-app>.vercel.app/api/save-result"`
   - `apiKey = "<the same API_KEY>"`

Local dev: copy `.env.example` → `.env.local`, fill it, then `npx vercel dev`.

> Security: a value embedded in the iOS app (the API key) is obfuscation, not strong
> auth — it deters casual abuse but is readable from the binary. The connection
> string, which grants full DB access, never leaves the server. For anything beyond a
> prototype, add real auth and lock down Atlas network access.
