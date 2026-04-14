def get_erd_prompt(text: str) -> str:
    return f"""
You are a database architect. Analyze the text below and generate a
Mermaid.js ENTITY RELATIONSHIP DIAGRAM (ERD).

Rules:
- Output ONLY valid Mermaid code starting with: erDiagram
- Identify entities, their attributes, primary keys, and relationships
- Show cardinalities: ||--||, ||--|{{, }}|--|{{
- Do NOT include any explanation, just the Mermaid code

Text:
{text}
"""