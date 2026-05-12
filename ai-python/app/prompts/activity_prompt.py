def get_activity_prompt(text: str) -> str:
    return f"""
Analyze the text below following these steps to create a perfect Mermaid.js ACTIVITY DIAGRAM:

STEP 1: Identify the start and end points of the process.
STEP 2: Extract all activities/actions in sequence.
STEP 3: Identify decision points (conditions/branches).
STEP 4: Detect parallel activities (fork/join).
STEP 5: Output ONLY the final Mermaid code.

Rules for Output:
- Start with 'flowchart TD'.
- Use rounded rectangles for activities: ActivityName([ActivityName])
- Use diamond shapes for decisions: DecisionName{{DecisionName}}
- Use --> for transitions
- Add labels on transitions where needed: -->|label|
- Start with a filled circle: S((Start))
- End with a double circle: E(((End)))
- No explanations or extra text.

Text to Analyze:
{text}
"""