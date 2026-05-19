def get_gantt_prompt(text: str) -> str:
    return f"""
You are an expert project manager. Create a professional Mermaid.js Gantt Chart.
Output ONLY valid Mermaid code. No explanation. No markdown. No code blocks.

STRICT SYNTAX RULES:
- Start with: gantt
- Title: title Project Name
- Date format: dateFormat YYYY-MM-DD
- Axis format: axisFormat %d/%m
- Sections: section Section Name
- Tasks: TaskName :status, id, startDate, duration
- Status options: done, active, crit, milestone
- Dependencies: after taskId
- Milestones: milestone, id, date, 0d

CORRECT EXAMPLE:
gantt
    title E-Commerce Platform Development
    dateFormat YYYY-MM-DD
    axisFormat %d %b

    section Planning
    Requirements Gathering    :done, req, 2024-01-01, 7d
    System Design            :done, design, after req, 5d
    Database Design          :done, db, after req, 5d

    section Development
    Backend API Development   :active, api, after design, 21d
    Frontend Development      :active, fe, after design, 21d
    Database Implementation   :done, dbi, after db, 10d

    section Testing
    Unit Testing             :crit, ut, after api, 7d
    Integration Testing      :crit, it, after ut, 7d
    User Acceptance Testing  :uat, after it, 5d

    section Deployment
    Staging Deployment       :stg, after uat, 2d
    Production Deployment    :milestone, prod, after stg, 0d

RULES:
- Use realistic dates starting from 2024-01-01
- Include done/active/crit status appropriately
- Group tasks in logical sections
- Use dependencies (after taskId) for sequential tasks
- Add milestones for key deliverables
- Task IDs: short, no spaces (use camelCase)
- Duration format: Nd (days) or Nw (weeks)
- Max 5 sections, max 4 tasks per section

Text:
{text}
"""