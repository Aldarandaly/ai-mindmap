def get_analyse_prompt(text: str) -> str:
    return f"""
Analyze the following text and extract:
1. Main entities or concepts
2. Relationships between them
3. Suggested diagram type (erd, class, or mindmap)
4. Key attributes for each entity

Text:
{text}

Provide a clear structured analysis.
"""