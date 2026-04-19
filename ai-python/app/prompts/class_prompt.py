def get_class_prompt(text: str) -> str:
    return f"""
Analyze the text below following these steps to create a perfect Mermaid.js CLASS DIAGRAM:

STEP 1: Identify all main entities/classes mentioned.
STEP 2: Extract attributes (properties) and methods (actions) for each class.
STEP 3: Identify relationships (Inheritance <|--, Association -->, Composition *--, Aggregation o--).
STEP 4: Verify that the syntax follows Mermaid classDiagram rules.
STEP 5: Output ONLY the final Mermaid code.

Rules for Output:
- Start with 'classDiagram'.
- No explanations or extra text.
- Use valid brackets and parentheses for methods.
- Avoid special characters in class names.

Text to Analyze:
{text}
"""