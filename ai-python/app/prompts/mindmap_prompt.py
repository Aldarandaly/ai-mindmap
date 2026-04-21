def get_mindmap_prompt(text: str) -> str:
    return f"""
Analyze the text below following these steps to create a perfect Mermaid.js MIND MAP:

STEP 1: Determine the core central topic.
STEP 2: Identify major categories/branches.
STEP 3: Extract sub-topics and details for each branch.
STEP 4: Organize the hierarchy using indentation.
STEP 5: Output ONLY the final Mermaid code.

Rules for Output:
- Start with 'mindmap'.
- Indent child nodes to show hierarchy.
- No explanation or side comments.

Text to Analyze:
{text}
"""