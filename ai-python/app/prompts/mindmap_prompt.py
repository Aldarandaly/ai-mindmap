def get_mindmap_prompt(text: str) -> str:
    return f"""
Create a valid Mermaid.js mindmap. Output ONLY the Mermaid code, nothing else.

STRICT RULES:
- First line: mindmap
- Second line: 2 spaces + root((Topic))
- Children: 4 spaces
- Grandchildren: 6 spaces
- NO brackets [], NO parentheses () except root(())
- NO special characters
- NO multiple roots
- Max 3 levels

CORRECT Example:
mindmap
  root((Software Engineering))
    Design Patterns
      Creational
      Structural
      Behavioral
    Testing
      Unit Testing
      Integration
    Deployment
      Docker
      CI CD

Text:
{text}
"""