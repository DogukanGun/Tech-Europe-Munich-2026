"""
LiverLink Lab Agent package.

Exports `root_agent` — required by Google ADK's `adk web` and `adk run` commands.
Also exports `agent` (alias) for backwards compatibility with lab_runner.py.
"""

from lab_agent.agent import root_agent

agent = root_agent  # backwards-compatible alias

__all__ = ["root_agent", "agent"]

