def get_context_prompt(text: str) -> str:
    return f"""
You are an expert software architect. Create a professional Mermaid.js Context Diagram (Level 0 DFD).
Output ONLY valid Mermaid code. No explanation. No markdown. No code blocks.

STRICT SYNTAX RULES:
- Start with: flowchart LR
- Main system: MainSystem([System Name])
- External entities: Entity[Entity Name]
- Data flows: A -->|data description| B
- Use clear, short data flow labels

CORRECT EXAMPLE:
flowchart LR
    Customer[Customer]
    Admin[Admin]
    PaymentGateway[Payment Gateway]
    EmailService[Email Service]
    MainSystem([E-Commerce System])
    Database[(Database)]

    Customer -->|Register/Login| MainSystem
    Customer -->|Browse & Order| MainSystem
    MainSystem -->|Order Confirmation| Customer
    MainSystem -->|Payment Request| PaymentGateway
    PaymentGateway -->|Payment Status| MainSystem
    Admin -->|Manage Products| MainSystem
    Admin -->|View Reports| MainSystem
    MainSystem -->|Send Notifications| EmailService
    MainSystem -->|Store/Retrieve Data| Database

RULES:
- System in center using double parentheses
- External entities as rectangles
- Database as cylinder: [(Name)]
- Label ALL arrows with data description
- Show bidirectional flows as two arrows
- Max 8 external entities

Text:
{text}
"""