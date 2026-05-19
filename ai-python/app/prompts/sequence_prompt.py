def get_sequence_prompt(text: str) -> str:
    return f"""
You are an expert software architect. Create a professional Mermaid.js Sequence Diagram.
Output ONLY valid Mermaid code. No explanation. No markdown. No code blocks.

STRICT SYNTAX RULES:
- Start with: sequenceDiagram
- Participants: participant Name or actor Name
- Sync message: A->>B: Message
- Async message: A-)B: Message
- Response: B-->>A: Response
- Self message: A->>A: Internal process
- Activation: activate A / deactivate A
- Notes: Note over A,B: text or Note right of A: text
- Groups: rect rgb(200,200,200) / end
- Alt: alt condition / else / end
- Loop: loop label / end
- Opt: opt condition / end

CORRECT EXAMPLE:
sequenceDiagram
    actor User
    participant Frontend
    participant AuthService
    participant Database
    participant EmailService

    User->>Frontend: Enter credentials
    activate Frontend
    Frontend->>AuthService: POST /auth/login
    activate AuthService
    AuthService->>Database: Find user by email
    activate Database
    Database-->>AuthService: User record
    deactivate Database

    alt Valid credentials
        AuthService->>AuthService: Generate JWT token
        AuthService-->>Frontend: Token + user data
        Frontend-->>User: Redirect to dashboard
    else Invalid credentials
        AuthService-->>Frontend: 401 Unauthorized
        Frontend-->>User: Show error message
    end

    deactivate AuthService
    deactivate Frontend

    opt First login
        AuthService->>EmailService: Send welcome email
        EmailService-->>User: Welcome email
    end

RULES:
- Use actor for human users
- Use participant for systems/services
- Always show responses with -->>
- Use activate/deactivate for important operations
- Use alt/else for conditional flows
- Use loop for repeated operations
- Add meaningful message labels
- Max 6 participants for clarity

Text:
{text}
"""