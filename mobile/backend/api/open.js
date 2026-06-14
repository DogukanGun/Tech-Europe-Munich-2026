// HTTPS "opener" for the Telegram bot button.
// Telegram buttons only allow http(s) URLs and its in-app browser does not fire
// iOS Universal Links — but it DOES honor custom-scheme launches. So this page
// immediately launches the native app via liverflapcheck:// (with a tap fallback).
export default function handler(req, res) {
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.status(200).send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta http-equiv="refresh" content="0; url=liverflapcheck://open" />
  <title>Opening Liver Flap Check…</title>
  <script>window.location.replace("liverflapcheck://open");</script>
  <style>
    body { font-family: -apple-system, system-ui, sans-serif; background:#0f1217; color:#eee;
           text-align:center; padding:48px 24px; }
    a.btn { display:inline-block; margin-top:20px; padding:14px 22px; border-radius:12px;
            background:#4d9eea; color:#fff; text-decoration:none; font-weight:600; }
    small { color:#9aa; display:block; margin-top:18px; }
  </style>
</head>
<body>
  <h2>Opening Liver Flap Check…</h2>
  <a class="btn" href="liverflapcheck://open">Open the app</a>
  <small>If nothing happens, make sure the app is installed (via TestFlight).</small>
</body>
</html>`);
}
