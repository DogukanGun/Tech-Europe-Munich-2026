"""
Tool functions for the LiverLink Lab Agent.

Patient history is read from the local patient_history/ directory.
This enables trend analysis across sequential lab reports.
"""

import json
from pathlib import Path

HISTORY_DIR = Path(__file__).parent.parent.parent / "data" / "patient_history"


def fetch_patient_history(patient_id: str) -> dict:
    """Return prior LFT records for a patient to enable trend analysis.

    Args:
        patient_id: The patient identifier extracted from the lab report.

    Returns:
        A dict with 'records' (list of prior lab snapshots) and 'count'.
        Returns empty records if no history exists yet.
    """
    history_file = HISTORY_DIR / f"{patient_id}.json"
    if not history_file.exists():
        return {"patient_id": patient_id, "count": 0, "records": []}
    try:
        records = json.loads(history_file.read_text(encoding="utf-8"))
        return {"patient_id": patient_id, "count": len(records), "records": records}
    except Exception:
        return {"patient_id": patient_id, "count": 0, "records": []}
