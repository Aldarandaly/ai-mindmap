def get_class_prompt(text: str) -> str:
    return f"""
You are an expert system analyst. Analyze the text below and generate a
Mermaid.js CLASS DIAGRAM.

Rules:
- Output ONLY valid Mermaid code starting with: classDiagram
- Identify classes, their attributes, methods, and relationships
- Use --> for associations, <|-- for inheritance
- Do NOT include any explanation, just the Mermaid code

Text:
{text}
"""