def get_context_prompt(text: str) -> str:
    return f"""
Analyze the text below following these steps to create a perfect Mermaid.js CONTEXT DIAGRAM:

STEP 1: Identify the main system at the center.
STEP 2: Identify all external entities (users, systems, services) that interact with the system.
STEP 3: Determine the data flows between external entities and the system.
STEP 4: Label each data flow clearly.
STEP 5: Output ONLY the final Mermaid code.

Rules for Output:
- Start with 'flowchart LR'.
- Central system as a rectangle: System[System Name]
- External entities as rectangles: Entity[Entity Name]
- Data flows as arrows with labels: Entity -->|data flow| System
- Show bidirectional flows where needed
- No explanations or extra text.

Text to Analyze:
{text}
"""