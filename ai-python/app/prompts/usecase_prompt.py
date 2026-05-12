def get_usecase_prompt(text: str) -> str:
    return f"""
Analyze the text below following these steps to create a perfect Mermaid.js USE CASE DIAGRAM:

STEP 1: Identify all Actors (users or external systems).
STEP 2: Identify all Use Cases (actions/features the system provides).
STEP 3: Determine relationships between actors and use cases.
STEP 4: Identify any include or extend relationships between use cases.
STEP 5: Output ONLY the final Mermaid code.

Rules for Output:
- Start with 'flowchart TD'.
- Actors represented as: ActorName([ActorName])
- Use Cases represented as: UseCaseName(UseCaseName)
- Relationships: Actor --> UseCase
- Include: UseCase1 -->|include| UseCase2
- Extend: UseCase1 -->|extend| UseCase2
- No explanations or extra text.

Text to Analyze:
{text}
"""