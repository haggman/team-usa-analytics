"""
Team USA Analytics Agent — ADK Agent Definition

This agent connects to MCP Toolbox for Databases running locally, which
provides access to both AlloyDB (operational athlete data) and BigQuery
(ML model results) through a single MCP interface.

Architecture:
    User → ADK Agent (Gemini) → MCP Toolbox → AlloyDB + BigQuery

Uncomment the identified solution settings to see solution
"""

import os
from dotenv import load_dotenv

from google.adk.agents import LlmAgent
from google.adk.tools.mcp_tool.mcp_toolset import MCPToolset
from google.adk.tools.mcp_tool.mcp_toolset import StreamableHTTPConnectionParams

# Setup for the visualization agent
# Uncomment the below imports to run solution
# from google.adk.tools.agent_tool import AgentTool
# from .visualization_agent import visualization_agent

load_dotenv()

TOOLBOX_URL = os.getenv("TOOLBOX_URL", "http://localhost:5000/mcp")


def build_toolbox_toolset() -> MCPToolset:
    """Create an MCPToolset that connects to the MCP Toolbox server."""
    return MCPToolset(
        connection_params=StreamableHTTPConnectionParams(url=TOOLBOX_URL)
    )


root_agent = LlmAgent(
    name="team_usa_analyst",
    model="gemini-2.5-flash",
    description="Team USA Olympic and Paralympic analytics agent.",
    instruction="""You are the Team USA Analytics Agent — an expert on United States
Olympic and Paralympic history spanning over 120 years of competition.

You have access to two data sources through MCP Toolbox:
- **BigQuery** — aggregated analytics, medal counts, historical trends, and
  BQML-generated career archetype clusters.
- **AlloyDB** — individual athlete profiles with AI-generated narratives and
  vector embeddings for semantic similarity search.

When answering questions:
1. Determine which data source is most appropriate.
2. Use the MCP tools to query the data.
3. Present findings in a clear, engaging way — you're a sports analyst telling
   a story, not just returning rows.
4. When the user asks for a chart, graph, or visualization, use the
   visualization_agent tool. Pass it the relevant data and describe the chart needed.

For athlete similarity questions (e.g., "find athletes like Simone Biles"),
use the AlloyDB vector search tools.

For aggregated statistics, trends, and archetype analysis, use BigQuery.
""",
    tools=[build_toolbox_toolset(), ],
    # Solution version:
    #tools=[build_toolbox_toolset(), AgentTool(agent=visualization_agent)],
)