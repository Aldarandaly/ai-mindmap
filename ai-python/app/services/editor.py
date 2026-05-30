from groq import Groq
from app.services.validator import basic_validate_mermaid
import os

client = Groq(api_key=os.getenv("GROQ_API_KEY"))

EDIT_SYSTEM_PROMPT = """You are an expert diagram editor. 
You receive a Mermaid diagram and a user request to modify it.

Rules:
- Return ONLY the updated Mermaid code, nothing else
- Keep the same diagram type
- Apply ONLY the requested changes, keep everything else as-is
- The code must be valid Mermaid syntax
- Do NOT add markdown fences (no ```)
"""

REPLY_SYSTEM_PROMPT = """You are a helpful diagram assistant.
Briefly explain in 1-2 sentences what changes you made to the diagram.
Be concise and friendly.
"""

def edit_diagram(current_code: str, message: str, diagram_type: str, history: list) -> dict:
    # Build history context
    history_text = ""
    if history:
        for msg in history[-6:]:  # last 6 messages only
            history_text += f"{msg.role}: {msg.content}\n"

    # Step 1: Get updated diagram code
    code_response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": EDIT_SYSTEM_PROMPT},
            {"role": "user", "content": f"""
Current {diagram_type} diagram:
{current_code}

Previous conversation:
{history_text}

User request: {message}

Return only the updated Mermaid code:
"""}
        ],
        temperature=0.3,
        max_tokens=2000,
    )

    new_code = code_response.choices[0].message.content.strip()
    
    # Clean any accidental markdown fences
    if new_code.startswith("```"):
        lines = new_code.split("\n")
        new_code = "\n".join(lines[1:-1])

    # Validate — fallback to original if invalid
    if not basic_validate_mermaid(new_code):
         new_code = current_code

    # Step 2: Get human-friendly reply
    reply_response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": REPLY_SYSTEM_PROMPT},
            {"role": "user", "content": f'User asked: "{message}". What did you change in the diagram?'}
        ],
        temperature=0.5,
        max_tokens=150,
    )

    reply = reply_response.choices[0].message.content.strip()

    return {
        "diagram_code": new_code,
        "reply": reply
    }