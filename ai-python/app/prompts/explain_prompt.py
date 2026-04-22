def get_explain_prompt(text: str, diagram_code: str) -> str:
    return f"""
Given this original text:
{text}

And this generated Mermaid diagram:
{diagram_code}

Explain in simple terms:
1. What the diagram represents
2. The main entities and their roles
3. The relationships between them
4. How it reflects the original text

Keep the explanation clear and concise.
"""