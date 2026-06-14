import { MongoClient } from "mongodb";

// Reuse the client across invocations (Fluid Compute keeps instances warm),
// so we don't open a new connection per request.
let clientPromise;
function getClient() {
  if (!clientPromise) {
    const uri = process.env.MONGODB_URI;
    if (!uri) throw new Error("MONGODB_URI is not set");
    // Fail fast instead of hanging if the cluster can't be reached (e.g. Atlas
    // Network Access hasn't allowlisted Vercel).
    clientPromise = new MongoClient(uri, { serverSelectionTimeoutMS: 8000 }).connect();
  }
  return clientPromise;
}

const ALLOWED = new Set([
  "outcome",
  "decision",
  "flapEvents",
  "pattern",
  "symmetry",
  "confidence",
  "postureValid",
  "summary",
  "note",
]);

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ ok: false, error: "Method not allowed" });
  }

  // Optional shared-secret check to stop random writes. Set API_KEY in env to enable.
  const expectedKey = process.env.API_KEY;
  if (expectedKey && req.headers["x-api-key"] !== expectedKey) {
    return res.status(401).json({ ok: false, error: "Unauthorized" });
  }

  try {
    const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body || {};

    // Whitelist fields, then stamp server-side metadata.
    const doc = {};
    for (const key of ALLOWED) if (key in body) doc[key] = body[key];
    doc.createdAt = new Date();
    doc.source = "ios";

    const client = await getClient();
    const db = client.db(process.env.MONGODB_DB || "health_checker");
    const result = await db.collection("MobileRes").insertOne(doc);

    return res.status(200).json({ ok: true, id: result.insertedId });
  } catch (e) {
    return res.status(500).json({ ok: false, error: String(e?.message || e) });
  }
}
