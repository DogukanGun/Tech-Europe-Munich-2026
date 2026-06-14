"""
LiverLink Lab Agent — Google ADK definition.

Reads raw LFT JSON, flags abnormal results, performs trend analysis,
and produces a structured payload with dual summaries for the Doctor Agent.
"""

from dotenv import find_dotenv, load_dotenv
from google.adk.agents import LlmAgent

load_dotenv(find_dotenv())

from lab_agent.prompts import LAB_AGENT_INSTRUCTION
from lab_agent.tools import fetch_patient_history, queue_priority_emergency_blood_test


root_agent = LlmAgent(
    name="lab_agent",
    model="gemini-2.5-flash",
    description=(
        "Reads LFT lab reports (JSON or plain text), flags abnormal results, performs trend "
        "analysis via fetch_patient_history(), and produces a structured payload with dual "
        "summaries (doctor_brief + patient_summary) and LOW/MEDIUM/HIGH urgency tiering."
    ),
    instruction=LAB_AGENT_INSTRUCTION,
    tools=[fetch_patient_history, queue_priority_emergency_blood_test],
)

