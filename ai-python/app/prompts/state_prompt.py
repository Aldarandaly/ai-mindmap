def get_state_prompt(text: str) -> str:
    return f"""
Analyze the text below following these steps to create a perfect Mermaid.js STATE DIAGRAM:

STEP 1: Identify the main object/entity that has states.
STEP 2: Extract all possible states for that entity.
STEP 3: Determine the transitions between states and what triggers them.
STEP 4: Identify the initial state and final state(s).
STEP 5: Output ONLY the final Mermaid code.

Rules for Output:
- Start with 'stateDiagram-v2'.
- Use [*] for initial and final states.
- Define states clearly: state "State Name" as stateName
- Use --> for transitions: stateA --> stateB : trigger
- Group related states if needed using state blocks.
- No explanations or extra text.

Text to Analyze:
{text}
"""