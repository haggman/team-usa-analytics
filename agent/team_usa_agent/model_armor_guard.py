"""Model Armor guard — screens prompts and responses for security threats."""

import os
from typing import Optional
from google.api_core.client_options import ClientOptions
from google.cloud import modelarmor_v1
from google.adk.agents.callback_context import CallbackContext
from google.adk.models import LlmResponse, LlmRequest
from google.genai import types

# --- Configuration ---
PROJECT_ID = os.environ["PROJECT_ID"]
REGION = os.environ["REGION"]
TEMPLATE_NAME = (
    f"projects/{PROJECT_ID}/locations/{REGION}/templates/team-usa-guardrails"
)

# --- Model Armor client (created once, reused across calls) ---
_client = modelarmor_v1.ModelArmorClient(
    transport="rest",
    client_options=ClientOptions(
        api_endpoint=f"modelarmor.{REGION}.rep.googleapis.com"
    ),
)


def _get_matched_filters(result) -> list[str]:
    """Extract the names of any filters that matched."""
    matched = []
    findings = result.sanitization_result

    if findings.filter_match_state == modelarmor_v1.FilterMatchState.MATCH_FOUND:
        # Check each filter type
        if findings.filter_results.get("pi_and_jailbreak"):
            pi = findings.filter_results["pi_and_jailbreak"]
            if (pi.pi_and_jailbreak_filter_result
                and pi.pi_and_jailbreak_filter_result.match_state
                == modelarmor_v1.FilterMatchState.MATCH_FOUND):
                matched.append("pi_and_jailbreak")

        if findings.filter_results.get("rai"):
            rai = findings.filter_results["rai"]
            if (rai.rai_filter_result and rai.rai_filter_result.match_state
                == modelarmor_v1.FilterMatchState.MATCH_FOUND):
                matched.append("rai")

        if findings.filter_results.get("sdp"):
            sdp = findings.filter_results["sdp"]
            if (sdp.sdp_filter_result and sdp.sdp_filter_result.match_state
                == modelarmor_v1.FilterMatchState.MATCH_FOUND):
                matched.append("sdp")

        if findings.filter_results.get("malicious_uris"):
            uris = findings.filter_results["malicious_uris"]
            if (uris.malicious_uri_filter_result
                and uris.malicious_uri_filter_result.match_state
                == modelarmor_v1.FilterMatchState.MATCH_FOUND):
                matched.append("malicious_uris")

    return matched


# --- ADK Callbacks ---

def screen_input(
    callback_context: CallbackContext, llm_request: LlmRequest
) -> Optional[LlmResponse]:
    """Before-model callback: screens user prompt through Model Armor."""

    # Extract the latest user message
    user_text = ""
    if llm_request.contents and llm_request.contents[-1].role == "user":
        if llm_request.contents[-1].parts:
            user_text = llm_request.contents[-1].parts[0].text

    if not user_text:
        return None  # Nothing to screen, continue normally

    # Call Model Armor
    result = _client.sanitize_user_prompt(
        request=modelarmor_v1.SanitizeUserPromptRequest(
            name=TEMPLATE_NAME,
            user_prompt_data=modelarmor_v1.DataItem(text=user_text),
        )
    )

    matched = _get_matched_filters(result)

    if matched:
        print(f"[Model Armor] 🛡️ BLOCKED — filters matched: {matched}")
        return LlmResponse(
            content=types.Content(
                role="model",
                parts=[types.Part.from_text(
                    text=(
                        "I'm unable to process that request — it was flagged "
                        "by our security screening. If you believe this is an "
                        "error, try rephrasing your question. I'm happy to help "
                        "with Team USA athlete analytics!"
                    )
                )],
            )
        )

    print("[Model Armor] ✅ Prompt passed screening")
    return None  # Continue to LLM


def screen_output(
    callback_context: CallbackContext, llm_response: LlmResponse
) -> Optional[LlmResponse]:
    """After-model callback: screens model response through Model Armor."""

    # Extract the model's response text
    model_text = ""
    if llm_response.content and llm_response.content.parts:
        model_text = llm_response.content.parts[0].text

    if not model_text:
        return None

    # Call Model Armor
    result = _client.sanitize_model_response(
        request=modelarmor_v1.SanitizeModelResponseRequest(
            name=TEMPLATE_NAME,
            model_response_data=modelarmor_v1.DataItem(text=model_text),
        )
    )

    matched = _get_matched_filters(result)

    if matched:
        print(f"[Model Armor] 🛡️ Response filtered — issues: {matched}")
        return LlmResponse(
            content=types.Content(
                role="model",
                parts=[types.Part.from_text(
                    text=(
                        "My response was filtered for security reasons. "
                        "Could you rephrase your question? I'm here to help "
                        "with Team USA athlete data and analytics."
                    )
                )],
            )
        )

    print("[Model Armor] ✅ Response passed screening")
    return None  # Use original response