def get_class_prompt(text: str) -> str:
    return f"""
Create a valid Mermaid.js CLASS DIAGRAM. Output ONLY the Mermaid code, nothing else.

STRICT RULES:
- Start with 'classDiagram'
- No explanations or extra text
- No markdown, no code blocks
- Class names: no spaces, no special characters
- Relationships MUST have spaces around them

VALID Relationships (copy exactly):
- Inheritance:   ClassA <|-- ClassB
- Association:   ClassA --> ClassB
- Composition:   ClassA *-- ClassB
- Aggregation:   ClassA o-- ClassB
- Dependency:    ClassA ..> ClassB

CORRECT Example:
classDiagram
    class User {{
        +int id
        +String name
        +String email
        +login()
        +logout()
    }}
    class Order {{
        +int id
        +int userId
        +decimal total
        +place()
    }}
    User --> Order : places

WRONG (never use these):
- User||--o{{Order
- User|--Order
- User--Order

Text:
{text}
"""