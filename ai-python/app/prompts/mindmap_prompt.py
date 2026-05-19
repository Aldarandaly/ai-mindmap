def get_mindmap_prompt(text: str) -> str:
    return f"""
You are an expert at creating mind maps. Create a professional Mermaid.js Mind Map.
Output ONLY valid Mermaid code. No explanation. No markdown. No code blocks.

STRICT SYNTAX RULES:
- First line: mindmap
- Root: 2 spaces + root((Central Topic))
- Level 1: 4 spaces + NodeName
- Level 2: 6 spaces + NodeName
- Level 3: 8 spaces + NodeName
- NO brackets [] anywhere except root(())
- NO parentheses () except root(())
- NO special characters (!@#$%^&*)
- NO quotes
- Max 3 levels deep

CORRECT EXAMPLE:
mindmap
  root((Software Engineering))
    Design Patterns
      Creational
      Structural
      Behavioral
    Testing
      Unit Testing
      Integration Testing
      End to End
    Architecture
      Microservices
      Monolithic
      Serverless
    DevOps
      CI CD
      Docker
      Kubernetes
    Databases
      SQL
      NoSQL
      NewSQL

WRONG (never do this):
- root((Topic)) with children at same level
- Using [] brackets: Node[Name]
- Using () parentheses: Node(Name)
- Special chars: Node!Name or Node#1

RULES:
- Root should be short (1-3 words)
- Max 5 Level-1 nodes
- Max 4 Level-2 nodes per parent
- Max 3 Level-3 nodes per parent
- Use simple, clear keywords
- No verbs, just nouns/concepts

Text:
{text}
"""