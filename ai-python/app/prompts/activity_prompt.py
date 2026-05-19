def get_activity_prompt(text: str) -> str:
    return f"""
You are an expert software architect. Create a professional Mermaid.js Activity Diagram.
Output ONLY valid Mermaid code. No explanation. No markdown. No code blocks.

STRICT SYNTAX RULES:
- Start with: flowchart TD
- Start node: Start([Start])
- End node: End([End])
- Activities: A[Activity Name]
- Decisions: D{{Decision?}}
- Arrows: A --> B
- Labeled arrows: A -->|Yes| B or A -->|No| C
- Parallel: use subgraph for parallel flows

CORRECT EXAMPLE:
flowchart TD
    Start([Start])
    A[User Opens App]
    B[Enter Credentials]
    C{{Valid Credentials?}}
    D[Show Dashboard]
    E[Show Error Message]
    F[Increment Attempt Counter]
    G{{Max Attempts Reached?}}
    H[Lock Account]
    End([End])

    Start --> A
    A --> B
    B --> C
    C -->|Yes| D
    C -->|No| E
    E --> F
    F --> G
    G -->|Yes| H
    G -->|No| B
    D --> End
    H --> End

RULES:
- Every node must be defined before use
- No special characters in node labels
- Always have Start and End nodes
- Max 15 nodes for clarity
- Use meaningful action names (verbs)

Text:
{text}
"""