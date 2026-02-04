# =============================================================================
# Agent Instructions — Team USA Analytics Agent
# =============================================================================
# This file defines the agent's identity and behavior. The DESCRIPTION tells
# ADK what the agent does (shown in the UI). The INSTRUCTIONS are the system
# prompt that guides the agent's reasoning and tool selection.

AGENT_DESCRIPTION = """Team USA Analytics Agent — an AI-powered sports analyst
with access to 120+ years of Team USA Olympic and Paralympic athlete data.
Can look up athletes, find medal winners, discover similar athletes through
semantic search, and classify career patterns using ML models."""

# =============================================================================
# TODO 3: Write the Agent's Routing Instructions
# =============================================================================
# The INSTRUCTIONS string below is the agent's system prompt. It tells the
# agent WHO it is, WHAT tools it has, and WHEN to use each one.
#
# The tools (defined in tools.yaml) are:
#
#   AlloyDB tools (operational database):
#     - get_athlete_profile: Look up a specific athlete by name
#     - get_sport_medalists: Find medal winners in a sport
#     - search_similar_athletes: Semantic search by description (your TODO 2!)
#
#   BigQuery tools (analytics/ML):
#     - get_athlete_archetype: Get an athlete's career archetype from K-Means
#     - list_archetype_summary: Overview of all five archetypes
#
# Your job: Write clear routing instructions that help the agent decide which
# tool to use based on the user's question. Consider:
#
#   - "Tell me about Michael Phelps" → which tool?
#   - "Who won gold in Swimming at the 2024 Olympics?" → which tool?
#   - "Find athletes like Simone Biles" → which tool?
#   - "What type of athlete is Katie Ledecky?" → which tool?
#   - "What are the different career patterns?" → which tool?
#   - "What's the history of the Olympic Games?" → no tool needed!
#
# Tips:
#   - Be specific about when each tool is the right choice
#   - Tell the agent it can combine tools for richer answers
#   - Remind it to use built-in knowledge for general questions
#   - Include personality guidance (enthusiastic but accurate, etc.)
#
# Replace the placeholder below with your instructions:
# =============================================================================

AGENT_INSTRUCTIONS = """You are a Team USA Analytics Agent. Help users explore
120+ years of Team USA Olympic and Paralympic history.

TODO: Replace this with your routing instructions.
"""
