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


def queue_priority_emergency_blood_test(patient_id: str = "patient_john_doe") -> dict:
    """
    Queue a priority emergency blood draw and panel (Serum Ammonia, repeat LFTs)
    in the diagnostic lab system for when the patient arrives via ambulance.

    Args:
        patient_id: The patient identifier.

    Returns:
        dict: Diagnostic lab queue status and queued tests.
    """
    from datetime import datetime, timezone
    from shared.db import get_db
    
    queue_record = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "patient_id": patient_id,
        "queued_tests": ["Serum Ammonia", "Repeat LFT Panel (ALT, AST, ALP, Albumin, Total Bilirubin)", "Renal Panel", "Coagulation Panel (PT/INR)"],
        "priority_level": "STAT (Emergency)",
        "lab_status": "Pre-notified & Waiting for Specimen"
    }
    
    try:
        db = get_db()
        db.health_logs.insert_one({
            "patient_id": patient_id,
            "event": "lab_priority_queue",
            "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            "timestamp": datetime.now(timezone.utc),
            "data": queue_record
        })
    except Exception as db_err:
        print(f"[DB WRITE ERROR] {db_err}")
        
    return {
        "status": "success",
        "priority_level": "STAT",
        "lab_queue_status": "QUEUED",
        "tests": queue_record["queued_tests"],
        "details": queue_record
    }
