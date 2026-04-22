def get_erd_prompt(text: str) -> str:
    return f"""
Analyze the text below following these steps to create a perfect Mermaid.js ERD (Entity Relationship Diagram):

STEP 1: Identify all main entities (tables).
STEP 2: Extract attributes for each entity and identify the Primary Key (PK).
STEP 3: Determine the relationships and their cardinalities (||--||, ||--|{{, }}|--|{{, etc.).
STEP 4: Structure the code using Mermaid erDiagram syntax.
STEP 5: Output ONLY the final Mermaid code.

Rules for Output:
- Start with 'erDiagram'.
- Use valid relationship notation.
- Attributes should be listed inside braces {{}} after the entity.
- No explanations or extra text.

Text to Analyze:
{text}
"""