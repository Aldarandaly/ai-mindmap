def get_gantt_prompt(text: str) -> str:
    return f"""
Analyze the text below following these steps to create a perfect Mermaid.js GANTT CHART:

STEP 1: Identify the project title and main sections/phases.
STEP 2: Extract all tasks within each section.
STEP 3: Determine the duration and sequence of each task.
STEP 4: Identify any dependencies between tasks.
STEP 5: Output ONLY the final Mermaid code.

Rules for Output:
- Start with 'gantt'.
- Add title: title Project Title
- Set date format: dateFormat YYYY-MM-DD
- Group tasks in sections: section Section Name
- Define tasks: taskName :status, startDate, duration
- Status can be: done, active, crit (critical), or empty
- Use 'after taskName' for dependencies
- No explanations or extra text.

Text to Analyze:
{text}
"""