def get_usecase_prompt(text: str) -> str:
    return f"""
You are an expert software architect. Create a professional Mermaid.js Use Case Diagram.
Output ONLY valid Mermaid code. No explanation. No markdown. No code blocks.

STRICT SYNTAX RULES:
- Start with: flowchart LR
- Actors: ActorName([👤 Actor Name])
- Use Cases: UC1(Use Case Name)
- System boundary: subgraph SystemName / end
- Associations: Actor --> UseCase
- Include: UC1 -->|include| UC2
- Extend: UC1 -.->|extend| UC2
- Generalization: Actor1 ---|generalize| Actor2

CORRECT EXAMPLE:
flowchart LR
    Customer([👤 Customer])
    Admin([👤 Admin])
    Guest([👤 Guest])

    subgraph OnlineStore[Online Store System]
        UC1(Browse Products)
        UC2(Search Products)
        UC3(Add to Cart)
        UC4(Checkout)
        UC5(Make Payment)
        UC6(Track Order)
        UC7(Manage Products)
        UC8(View Reports)
        UC9(Login)
        UC10(Register)
    end

    Guest --> UC1
    Guest --> UC2
    Guest --> UC10
    Customer --> UC1
    Customer --> UC2
    Customer --> UC3
    Customer --> UC4
    Customer --> UC6
    Customer --> UC9
    Admin --> UC7
    Admin --> UC8
    Admin --> UC9
    UC4 -->|include| UC5
    UC3 -.->|extend| UC2

RULES:
- Always use subgraph for system boundary
- Actors outside the system boundary
- Use emoji 👤 for human actors
- Include for mandatory relationships
- Extend for optional relationships
- Max 4 actors, max 12 use cases
- Use clear action-oriented names for use cases

Text:
{text}
"""