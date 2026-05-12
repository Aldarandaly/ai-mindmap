def get_mindmap_prompt(text: str) -> str:
    return f"""
Create a valid Mermaid.js mindmap. Output ONLY the Mermaid code, nothing else.

STRICT RULES:
- First line must be: mindmap
- Second line must be: 2 spaces + root((MainTopic))
- Level 1 children: 4 spaces
- Level 2 children: 6 spaces
- Maximum 3 levels deep
- NO brackets [] anywhere
- NO parentheses () except in root(())
- NO special characters
- NO markdown
- NO explanations

CORRECT Example:
mindmap
  root((Software Engineering))
    Design Patterns
      Creational
      Structural
    Testing
      Unit Testing
      Integration
    Deployment
      Docker
      CI CD

Text:
{text}
"""