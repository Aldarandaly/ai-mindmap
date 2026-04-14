def get_mindmap_prompt(text: str) -> str:
    return f"""
You are a knowledge expert. Analyze the text below and generate a
Mermaid.js MIND MAP.

Rules:
- Output ONLY valid Mermaid code starting with: mindmap
- Identify the central topic, main branches, and sub-branches
- Use proper indentation for hierarchy
- Do NOT include any explanation, just the Mermaid code

Text:
{text}
"""