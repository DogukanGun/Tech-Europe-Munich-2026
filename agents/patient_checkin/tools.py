"""
Tool functions for the LiverLink Patient Check-in Agent.

Each tool logs a piece of daily health data for a CLD patient.
In production these would write to the LiverLink database / FHIR store.
For the hackathon demo, results are returned as structured dicts and printed.
"""

from datetime import datetime, timezone


def _now() -> str:
    """Return a UTC ISO-8601 timestamp."""
    return datetime.now(timezone.utc).isoformat()


# ──────────────────────────────────────────────────────────────────────────────
#  Medication Adherence
# ──────────────────────────────────────────────────────────────────────────────

def log_medication_status(taken: bool, missed_medications: list[str] = [], notes: str = "") -> dict:
    """
    Log whether the patient took their prescribed medications today.

    Args:
        taken: True if all medications were taken, False if any were missed.
        missed_medications: Optional list of specific medications that were missed.
        notes: Any additional context the patient shared.

    Returns:
        A confirmation dict with the logged record.
    """
    record = {
        "timestamp": _now(),
        "event": "medication_adherence",
        "medications_taken": taken,
        "missed_medications": missed_medications,
        "adherence_rate": "100%" if taken else f"{max(0, 100 - len(missed_medications) * 20)}%",
        "notes": notes,
    }
    print(f"[LIVERLINK LOG] {record}")
    return {
        "status": "logged",
        "message": "Medication status recorded successfully.",
        "data": record,
    }


# ──────────────────────────────────────────────────────────────────────────────
#  Sleep Quality
# ──────────────────────────────────────────────────────────────────────────────

def log_sleep_quality(hours: float, quality: str, disturbances: list[str] = [], notes: str = "") -> dict:
    """
    Log the patient's sleep duration and quality from last night.

    Args:
        hours: Number of hours slept (e.g. 7.5).
        quality: Subjective quality — one of: "poor", "fair", "good", "excellent".
        disturbances: Any sleep disturbances reported (e.g. ["itching", "leg cramps"]).
        notes: Additional context from the patient.

    Returns:
        A confirmation dict with the logged record.
    """
    record = {
        "timestamp": _now(),
        "event": "sleep_quality",
        "hours_slept": hours,
        "quality": quality.lower(),
        "disturbances": disturbances,
        "notes": notes,
    }
    print(f"[LIVERLINK LOG] {record}")
    return {
        "status": "logged",
        "message": "Sleep quality recorded successfully.",
        "data": record,
    }


# ──────────────────────────────────────────────────────────────────────────────
#  Protein Intake
# ──────────────────────────────────────────────────────────────────────────────

def log_protein_intake(grams: float, sources: list[str] = [], notes: str = "") -> dict:
    """
    Log the patient's total protein consumption today.

    CLD patients require careful protein monitoring: typically 1.2–1.5 g/kg/day
    to prevent muscle wasting without worsening hepatic encephalopathy.

    Args:
        grams: Estimated total protein intake in grams.
        sources: Food sources of protein (e.g. ["eggs", "chicken", "lentils"]).
        notes: Any additional context.

    Returns:
        A confirmation dict with the logged record.
    """
    record = {
        "timestamp": _now(),
        "event": "protein_intake",
        "protein_grams": grams,
        "sources": sources,
        "notes": notes,
    }
    print(f"[LIVERLINK LOG] {record}")
    return {
        "status": "logged",
        "message": "Protein intake recorded successfully.",
        "data": record,
    }


# ──────────────────────────────────────────────────────────────────────────────
#  Water / Fluid Intake
# ──────────────────────────────────────────────────────────────────────────────

def log_water_intake(liters: float, includes_other_fluids: bool = False, notes: str = "") -> dict:
    """
    Log the patient's water and fluid consumption today.

    Adequate hydration is critical for CLD patients to support kidney function
    and reduce the risk of hepatorenal syndrome.

    Args:
        liters: Total fluid intake in litres (e.g. 1.5).
        includes_other_fluids: Whether the figure includes non-water fluids (juice, soup, etc.).
        notes: Additional context.

    Returns:
        A confirmation dict with the logged record.
    """
    record = {
        "timestamp": _now(),
        "event": "water_intake",
        "fluid_litres": liters,
        "includes_other_fluids": includes_other_fluids,
        "notes": notes,
    }
    print(f"[LIVERLINK LOG] {record}")
    return {
        "status": "logged",
        "message": "Water intake recorded successfully.",
        "data": record,
    }


# ──────────────────────────────────────────────────────────────────────────────
#  Salt / Sodium Intake
# ──────────────────────────────────────────────────────────────────────────────

def log_salt_intake(grams: float, high_sodium_foods: list[str] = [], notes: str = "") -> dict:
    """
    Log the patient's estimated sodium/salt intake today.

    CLD patients with ascites or oedema are typically restricted to < 2 g sodium/day
    (≈ 5 g of table salt) to prevent fluid retention.

    Args:
        grams: Estimated total salt intake in grams.
        high_sodium_foods: Any notably salty foods the patient mentioned.
        notes: Additional context.

    Returns:
        A confirmation dict with the logged record.
    """
    threshold_g = 5.0  # 5 g salt ≈ 2 g sodium — standard CLD limit
    within_limit = grams <= threshold_g

    record = {
        "timestamp": _now(),
        "event": "salt_intake",
        "salt_grams": grams,
        "within_recommended_limit": within_limit,
        "recommended_limit_grams": threshold_g,
        "high_sodium_foods": high_sodium_foods,
        "notes": notes,
    }
    print(f"[LIVERLINK LOG] {record}")
    return {
        "status": "logged",
        "message": "Salt intake recorded successfully.",
        "data": record,
        "flag": None if within_limit else "EXCEEDS_SODIUM_LIMIT",
    }


# ──────────────────────────────────────────────────────────────────────────────
#  Mood & Symptoms
# ──────────────────────────────────────────────────────────────────────────────

def log_mood(
    mood: str,
    energy_level: int,
    physical_symptoms: list[str] = [],
    emotional_notes: str = "",
) -> dict:
    """
    Log the patient's overall mood, energy level, and any physical or emotional symptoms.

    Args:
        mood: Overall mood descriptor (e.g. "good", "tired", "anxious", "pain").
        energy_level: Self-reported energy on a 1–10 scale (1 = exhausted, 10 = great).
        physical_symptoms: Any physical symptoms reported (e.g. ["fatigue", "nausea", "itching"]).
        emotional_notes: Free-text emotional or mental health notes from the patient.

    Returns:
        A confirmation dict with the logged record.
    """
    # Flag symptoms that may indicate hepatic encephalopathy or decompensation
    red_flag_symptoms = {
        "confusion", "disorientation", "forgetfulness", "tremor",
        "jaundice", "yellow skin", "yellow eyes", "vomiting blood",
        "black stool", "severe pain", "swelling", "fever",
    }
    flagged = [s for s in physical_symptoms if any(r in s.lower() for r in red_flag_symptoms)]

    record = {
        "timestamp": _now(),
        "event": "mood_and_symptoms",
        "mood": mood.lower(),
        "energy_level": max(1, min(10, energy_level)),  # clamp to 1–10
        "physical_symptoms": physical_symptoms,
        "emotional_notes": emotional_notes,
        "red_flag_symptoms_detected": flagged,
    }
    print(f"[LIVERLINK LOG] {record}")
    return {
        "status": "logged",
        "message": "Mood and symptoms recorded successfully.",
        "data": record,
        "flag": "RED_FLAG_SYMPTOMS_DETECTED" if flagged else None,
    }


# ──────────────────────────────────────────────────────────────────────────────
#  Hand AI Test
# ──────────────────────────────────────────────────────────────────────────────

def initiate_hand_ai_test() -> dict:
    """
    Initiate the Hand AI neurological assessment test.

    This test analyses hand movement patterns via the device camera to help detect
    early signs of hepatic encephalopathy (HE) — a serious complication of CLD
    where toxins affect brain function. Early detection enables faster intervention.

    Returns:
        A dict with test session details and instructions for the patient.
    """
    test_id = f"hand_ai_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}"

    record = {
        "timestamp": _now(),
        "event": "hand_ai_test_initiated",
        "test_id": test_id,
        "test_name": "Hand AI Neurological Assessment",
        "estimated_duration_minutes": 2,
    }
    print(f"[LIVERLINK LOG] {record}")
    return {
        "status": "initiated",
        "test_id": test_id,
        "instructions": (
            "Your Hand AI test is ready! 🤲\n\n"
            "Here's what to do:\n"
            "1. Find a well-lit space and hold your device at eye level.\n"
            "2. When prompted, hold out one hand and follow the on-screen movements.\n"
            "3. Stay relaxed — there are no wrong answers, just data to help your care team.\n"
            "4. The test takes about 2 minutes.\n\n"
            "Tap 'Begin Test' whenever you're ready."
        ),
        "data": record,
    }
