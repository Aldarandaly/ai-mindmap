def get_explain_prompt(text: str, diagram_code: str) -> str:
    return f"""
You are an expert at interpreting diagrams. Below is a text and its corresponding Mermaid.js diagram code. 
Please explain the diagram to the user so they understand the structure and relationships.

Instructions:
- Explain what the nodes and edges represent in the context of the original text.
- Summarize the overall structure (hierarchy, flow, or relationships).
- Respond in the SAME LANGUAGE as the input text.
- Be concise but informative.

Original Text:
{text}

Mermaid Code:
{diagram_code}
"""
