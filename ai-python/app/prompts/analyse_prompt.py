def get_analyse_prompt(text: str) -> str:
    return f"""
Analyze the text below and provide a clear, professional explanation of its contents.

Instructions:
- Identify the main topic and key entities.
- Explain the relationships and processes described.
- Use bullet points for readability.
- Respond in the SAME LANGUAGE as the input text.
- Do NOT mention Mermaid, diagrams, or technical code. Just analyze the content.

Text to Analyze:
{text}
"""
