"""
LiverLink — Lab Agent runner (google-adk 2.x)
CSV pipeline and CLI for batch-processing LFT data.
Agent definition lives in agents/lab_agent/__init__.py.
"""

import sys
import json
import asyncio
import csv
import os
from dotenv import load_dotenv
load_dotenv()

# Import the canonical agent definition from agents/lab_agent
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "agents"))
from lab_agent import agent as lab_agent  # noqa: E402

from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

# ---------------------------------------------------------------------------
# CSV column → LFT biomarker mapping (ILPD dataset)
# ---------------------------------------------------------------------------
# The ILPD CSV header is mislabeled. True positional order (UCI source):
#   0:age  1:gender  2:tot_bilirubin  3:direct_bilirubin
#   4:alkphos  5:sgpt(ALT)  6:sgot(AST)  7:tot_proteins  8:albumin
#   9:ag_ratio  10:is_patient
ILPD_COLS = [
    "age", "gender", "tot_bilirubin", "direct_bilirubin",
    "alkphos", "sgpt", "sgot", "tot_proteins", "albumin",
    "ag_ratio", "is_patient",
]

def csv_row_to_lft(raw_row: dict, row_index: int) -> dict:
    # Re-key by true column order, ignoring the mislabeled header
    values = list(raw_row.values())
    row = {ILPD_COLS[i]: values[i] for i in range(min(len(ILPD_COLS), len(values)))}

    def safe_float(val):
        try:
            return float(val)
        except (ValueError, TypeError):
            return None

    return {
        "patient_id": f"ILPD-{row_index:04d}",
        "age": safe_float(row.get("age")),
        "gender": row.get("gender", "").strip(),
        "biomarkers": {
            "ALT":             safe_float(row.get("sgpt")),
            "AST":             safe_float(row.get("sgot")),
            "ALP":             safe_float(row.get("alkphos")),
            "total_bilirubin": safe_float(row.get("tot_bilirubin")),
            "albumin":         safe_float(row.get("albumin")),
            "total_proteins":  safe_float(row.get("tot_proteins")),
        },
        "is_patient_label": int(float(row.get("is_patient", -1))),
    }


def load_csv(path: str) -> list[dict]:
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return [csv_row_to_lft(row, i + 1) for i, row in enumerate(reader)]


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------
APP_NAME = "liverlink"
USER_ID = "system"

async def run_lab_agent(lft_data: dict) -> dict:
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID)

    runner = Runner(agent=lab_agent, app_name=APP_NAME, session_service=session_service)

    message = types.Content(
        role="user",
        parts=[types.Part(text=f"Analyze the following LFT data:\n\n{json.dumps(lft_data, indent=2)}")],
    )

    response_text = ""
    async for event in runner.run_async(
        user_id=USER_ID,
        session_id=session.id,
        new_message=message,
    ):
        if event.is_final_response() and event.content:
            for part in event.content.parts:
                if part.text:
                    response_text += part.text

    cleaned = response_text.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
    return json.loads(cleaned)


async def run_batch(csv_path: str, limit: int = 5) -> list[dict]:
    """Process up to `limit` rows from the CSV concurrently."""
    rows = load_csv(csv_path)[:limit]
    tasks = [run_lab_agent(row) for row in rows]
    return await asyncio.gather(*tasks)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import sys

    csv_path = sys.argv[1] if len(sys.argv) > 1 else None
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 5

    if csv_path:
        print(f"Processing first {limit} rows from: {csv_path}\n")
        results = asyncio.run(run_batch(csv_path, limit=limit))
    else:
        # Fallback smoke-test
        sample = {
            "patient_id": "PT-00421",
            "biomarkers": {
                "ALT": 142, "AST": 98, "ALP": 130,
                "total_bilirubin": 2.4, "albumin": 3.1, "total_proteins": 6.8,
            },
        }
        print("No CSV supplied — running smoke-test patient...\n")
        results = [asyncio.run(run_lab_agent(sample))]

    for r in results:
        print(json.dumps(r, indent=2))
        print("-" * 60)
