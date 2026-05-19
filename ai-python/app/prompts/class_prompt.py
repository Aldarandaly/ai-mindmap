def get_class_prompt(text: str) -> str:
    return f"""
You are an expert software architect. Create a professional Mermaid.js Class Diagram.
Output ONLY valid Mermaid code. No explanation. No markdown. No code blocks.

STRICT SYNTAX RULES:
- Start with: classDiagram
- Class definition: class ClassName {{ }}
- Attributes: +type name or -type name
- Methods: +methodName() or +methodName(param type) returnType
- Relationships MUST have spaces: ClassA --> ClassB

VALID RELATIONSHIPS:
- Association:  ClassA --> ClassB : label
- Inheritance:  ClassA <|-- ClassB
- Composition:  ClassA *-- ClassB : label
- Aggregation:  ClassA o-- ClassB : label
- Dependency:   ClassA ..> ClassB : label
- Realization:  ClassA ..|> ClassB

CORRECT EXAMPLE:
classDiagram
    class User {{
        +int id
        +String name
        +String email
        +String password
        +login() bool
        +logout() void
        +updateProfile(name String) void
    }}
    class Order {{
        +int id
        +int userId
        +float total
        +String status
        +DateTime createdAt
        +place() void
        +cancel() void
        +getTotal() float
    }}
    class Product {{
        +int id
        +String name
        +float price
        +int stock
        +updateStock(qty int) void
    }}
    class OrderItem {{
        +int id
        +int quantity
        +float unitPrice
        +getSubtotal() float
    }}

    User --> Order : places
    Order *-- OrderItem : contains
    Product --> OrderItem : referenced by

RULES:
- No spaces in class names (use CamelCase)
- No special chars in names
- Always add visibility (+/-/#)
- Include return types for methods
- Add relationship labels
- Max 8 classes for clarity

Text:
{text}
"""