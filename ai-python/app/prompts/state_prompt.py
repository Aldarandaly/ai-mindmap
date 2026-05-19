def get_state_prompt(text: str) -> str:
    return f"""
You are an expert software architect. Create a professional Mermaid.js State Diagram.
Output ONLY valid Mermaid code. No explanation. No markdown. No code blocks.

STRICT SYNTAX RULES:
- Start with: stateDiagram-v2
- Initial state: [*] --> StateName
- Final state: StateName --> [*]
- Transition: StateA --> StateB : event/trigger
- State description: StateA : description
- Composite states: state StateName {{ }}
- Choice: state choice_id <<choice>>
- Fork: state fork_id <<fork>>
- Join: state join_id <<join>>
- Notes: note right of StateName / end note

CORRECT EXAMPLE:
stateDiagram-v2
    [*] --> Idle

    Idle : Waiting for user input
    Processing : Handling request
    Success : Operation completed
    Failed : Operation failed
    Cancelled : User cancelled

    Idle --> Processing : submit request
    Processing --> Success : operation succeeds
    Processing --> Failed : error occurs
    Processing --> Cancelled : user cancels
    Failed --> Idle : retry
    Cancelled --> Idle : reset
    Success --> Idle : new request
    Success --> [*] : exit
    Failed --> [*] : give up

    state Processing {{
        [*] --> Validating
        Validating --> Executing : valid input
        Validating --> [*] : invalid input
        Executing --> [*] : done
    }}

RULES:
- Always start with [*] --> FirstState
- Always end with at least one State --> [*]
- Add transition labels (events/triggers)
- Add state descriptions for clarity
- Use composite states for complex flows
- Max 10 states for clarity
- State names: no spaces (use CamelCase)

Text:
{text}
"""