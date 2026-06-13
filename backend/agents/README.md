# LiverLink — Agents Overview

Five components live in this folder: four patient-care agents, an orchestrator, and a shared utility layer.

```
agents/
├── patient_agent/      # Daily check-in with the patient
├── caregiver_agent/    # Monitors patient data, supports the carer
├── lab_agent/          # Screens LFT results for anomalies
├── doctor_agent/       # (in progress) Clinical decision support
├── orchestrator/       # Routes conversations to the right agent
└── shared/             # MongoDB helpers used by all agents
```

Also note: `LiverLink/lab_agent.py` contains a standalone version of the lab agent used in the LiverLink pipeline (`LiverLink/liverlink_pipeline/`).

---

## patient_agent

Guides the patient through a daily health check-in and writes every reading to MongoDB. When a reading crosses a clinical threshold it automatically writes an alert to the `caregiver_alerts` collection (the A2A channel read by the caregiver agent).

| Tool | What it does |
|---|---|
| `log_medication_status` | Records whether prescribed medications were taken; fires a **moderate** caregiver alert on a missed dose |
| `log_sleep_quality` | Logs hours slept and subjective quality; flags `POOR_SLEEP` when < 4 h or quality is "poor" |
| `log_protein_intake` | Logs protein intake in grams and food sources |
| `log_water_intake` | Logs total fluid intake in litres |
| `log_salt_intake` | Logs sodium intake; fires a **mild** caregiver alert when > 5 g (the CLD daily limit) |
| `log_mood` | Logs mood, energy level, and any symptoms; fires an **urgent** caregiver alert when red-flag symptoms are detected (e.g. confusion, jaundice, vomiting blood) |
| `log_fatigue` | Logs fatigue level 1–10; fires a **moderate** caregiver alert at level ≥ 8 |
| `log_appetite` | Logs appetite level 1–10; fires a **moderate** caregiver alert at level ≤ 3 |
| `log_activity_level` | Logs steps, activity type, duration, and intensity; fires a **mild** caregiver alert on a completely inactive day |
| `log_weight` | Logs weight in kg; fires a **moderate** caregiver alert on rapid gain (≥ 1 kg) or significant loss (≥ 2 kg) |
| `initiate_hand_ai_test` | Starts the Hand AI neurological test to screen for early hepatic encephalopathy |

---

## caregiver_agent

Gives the carer a real-time view of the patient's health data and tools to respond to alerts and escalate when needed.

| Tool | What it does |
|---|---|
| `get_patient_daily_summary` | Returns all check-in data logged for a given date (today, yesterday, or YYYY-MM-DD) |
| `get_health_trend_report` | Analyses the last 7 / 14 / 30 days of data and surfaces pattern flags (e.g. persistent low appetite, weight gain trend, extended inactivity) |
| `get_pending_alerts` | Fetches all unacknowledged alerts written by the patient agent — the A2A inbox |
| `acknowledge_patient_alert` | Marks an alert as acknowledged and logs the carer's action |
| `log_caregiver_observation` | Records a free-text observation about the patient's condition |
| `send_escalation_to_care_team` | Sends a formal escalation (routine / soon / urgent / emergency) to the clinical care team |
| `get_cld_care_tip` | Returns practical CLD care guidance on topics such as sodium, fatigue, hepatic encephalopathy, medications, and burnout |

---

## lab_agent

Receives raw Liver Function Test (LFT) JSON, screens every biomarker against clinical reference ranges, and returns a structured anomaly payload intended for the doctor agent.

| Tool | What it does |
|---|---|
| *(no callable tools)* | The agent itself is the processing unit — it uses its system prompt and Gemini to reason over the LFT JSON and produce a structured JSON response |

**Biomarkers screened:** ALT, AST, ALP, Total Bilirubin, Albumin, Total Proteins  
**Escalation rule:** urgency set to `HIGH` when ALT > 112 U/L, AST > 80 U/L, or Total Bilirubin > 1.2 mg/dL

> The standalone `LiverLink/lab_agent.py` is a self-contained copy of this agent used by the LiverLink pipeline demo.

---

## doctor_agent

*(In progress — placeholder only)*

Intended to receive the structured payload from `lab_agent` and generate clinical recommendations for the care team.

---

## orchestrator

Routes incoming conversations to the appropriate sub-agent based on the user's role and context. No domain-specific tools of its own.

---

## shared

MongoDB helpers (`shared/db.py`) used by all agents — not an agent itself.

| Helper | What it does |
|---|---|
| `get_db()` | Returns the MongoDB database connection |
| `PATIENT_ID` | The active patient identifier used across all collections |
