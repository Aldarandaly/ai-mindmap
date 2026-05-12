def get_erd_prompt(text: str) -> str:
    return f"""
Create a valid Mermaid.js ERD diagram. Output ONLY the Mermaid code, nothing else.

STRICT RULES:
- Start with 'erDiagram'
- Each attribute on its own line inside braces
- Format: TYPE NAME or TYPE NAME PK or TYPE NAME FK
- Valid relationships: ||--||, ||--|{{, }}|--|{{, }}o--o{{
- No commas inside attribute blocks
- No explanations
- No markdown

CORRECT Example:
erDiagram
    USER {{
        int id PK
        string name
        string email
    }}
    ORDER {{
        int id PK
        int user_id FK
        decimal total
    }}
    USER ||--|{{ ORDER : places

Text:
{text}
"""