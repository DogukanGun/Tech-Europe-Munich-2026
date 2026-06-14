"""
LiverLink Patient Check-in Agent package.

Exports `root_agent` — required by Google ADK's `adk web` and `adk run` commands.
"""

from patient_agent.agent import root_agent

__all__ = ["root_agent"]
