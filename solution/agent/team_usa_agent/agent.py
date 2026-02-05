"""
Team USA Analytics Agent — ADK Agent Definition

This agent connects to MCP Toolbox for Databases running locally, which
provides access to both AlloyDB (operational athlete data) and BigQuery
(ML model results) through a single MCP interface.

Architecture:
    User → ADK Agent (Gemini) → MCP Toolbox → AlloyDB + BigQuery
"""

import os
from dotenv import load_dotenv
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import MCPToolset, StreamableHTTPConnectionParams
from .agent_instructions import AGENT_DESCRIPTION, AGENT_INSTRUCTIONS

# Load environment variables from .env
load_dotenv()

# ---------------------------------------------------------------------------
# MCP Toolbox Connection
# ---------------------------------------------------------------------------
# The Toolbox server runs locally on port 5000. Since it's local, no
# authentication headers are needed (unlike a Cloud Run deployment where
# you'd need ID tokens).

TOOLBOX_URL = os.environ.get("TOOLBOX_URL", "http://localhost:5000")


def build_toolbox_toolset() -> MCPToolset:
    """Create an MCP connection to the local Toolbox server.

    The Toolbox server exposes all tools defined in tools.yaml as MCP
    tools. The agent discovers them automatically at startup.
    """
    return MCPToolset(
        connection_params=StreamableHTTPConnectionParams(
            url=f"{TOOLBOX_URL}/mcp",
            timeout=60,
            sse_read_timeout=300,
        )
    )


# ---------------------------------------------------------------------------
# Agent Definition
# ---------------------------------------------------------------------------
# The agent uses Gemini 2.5 Flash and gets all its database tools from the
# MCP Toolbox connection. Tool descriptions in tools.yaml guide the model
# on when to use each tool.

root_agent = Agent(
    name="team_usa_analyst",
    model="gemini-2.5-flash",
    description=AGENT_DESCRIPTION,
    instruction=AGENT_INSTRUCTIONS,
    tools=[build_toolbox_toolset()],
)
