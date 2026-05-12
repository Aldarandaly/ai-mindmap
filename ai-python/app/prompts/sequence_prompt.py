def get_sequence_prompt(text: str) -> str:
    return f"""
Analyze the text below following these steps to create a perfect Mermaid.js SEQUENCE DIAGRAM:

STEP 1: Identify all participants/actors in the system.
STEP 2: Extract the sequence of messages/interactions between them.
STEP 3: Identify synchronous calls (solid arrows) and responses (dashed arrows).
STEP 4: Detect any loops, alternatives, or optional flows.
STEP 5: Output ONLY the final Mermaid code.

Rules for Output:
- Start with 'sequenceDiagram'.
- Define participants first: participant Name
- Use ->> for synchronous messages
- Use -->> for response messages
- Use loop...end for repeated actions
- Use alt...else...end for conditional flows
- No explanations or extra text.

Text to Analyze:
{text}
"""