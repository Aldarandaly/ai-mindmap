def get_erd_prompt(text: str) -> str:
    return f"""
You are an expert database architect. Create a professional Mermaid.js ERD diagram.
Output ONLY valid Mermaid code. No explanation. No markdown. No code blocks.

STRICT SYNTAX RULES:
- Start with: erDiagram
- Entity: ENTITY_NAME {{ }}
- Attributes: type name KEY_TYPE (PK, FK, or empty)
- Relationships: ENTITY1 CARDINALITY ENTITY2 : "label"

VALID CARDINALITY:
- One to one:    ENTITY1 ||--|| ENTITY2 : "label"
- One to many:   ENTITY1 ||--o{{ ENTITY2 : "label"
- Many to one:   ENTITY1 }}o--|| ENTITY2 : "label"
- Many to many:  ENTITY1 }}o--o{{ ENTITY2 : "label"
- Zero or one:   ENTITY1 |o--o| ENTITY2 : "label"

CORRECT EXAMPLE:
erDiagram
    USER {{
        int id PK
        string name
        string email
        string password
        datetime created_at
    }}
    PRODUCT {{
        int id PK
        string name
        float price
        int stock
        int category_id FK
    }}
    CATEGORY {{
        int id PK
        string name
        string description
    }}
    ORDER {{
        int id PK
        int user_id FK
        float total
        string status
        datetime ordered_at
    }}
    ORDER_ITEM {{
        int id PK
        int order_id FK
        int product_id FK
        int quantity
        float unit_price
    }}

    USER ||--o{{ ORDER : "places"
    ORDER ||--o{{ ORDER_ITEM : "contains"
    PRODUCT ||--o{{ ORDER_ITEM : "included in"
    CATEGORY ||--o{{ PRODUCT : "categorizes"

RULES:
- Entity names in UPPER_SNAKE_CASE
- Always include PK for each entity
- Mark foreign keys with FK
- Use snake_case for attribute names
- Add meaningful relationship labels
- No commas in attribute blocks
- Each attribute on its own line

Text:
{text}
"""