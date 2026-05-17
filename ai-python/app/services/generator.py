from groq import Groq
import json
import re
import os
from dotenv import load_dotenv
from app.prompts.class_prompt import get_class_prompt
from app.prompts.erd_prompt import get_erd_prompt
from app.prompts.mindmap_prompt import get_mindmap_prompt
from app.prompts.analyse_prompt import get_analyse_prompt
from app.prompts.explain_prompt import get_explain_prompt
from app.prompts.usecase_prompt import get_usecase_prompt
from app.prompts.activity_prompt import get_activity_prompt
from app.prompts.sequence_prompt import get_sequence_prompt
from app.prompts.context_prompt import get_context_prompt
from app.prompts.state_prompt import get_state_prompt
from app.prompts.dfd_prompt import get_dfd_prompt
from app.prompts.gantt_prompt import get_gantt_prompt

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '..', '.env'))
client = Groq(api_key=os.getenv("GROQ_API_KEY"))


def get_prompt(text: str, diagram_type: str) -> str:
    prompts = {
        "erd":      get_erd_prompt,
        "class":    get_class_prompt,
        "mindmap":  get_mindmap_prompt,
        "usecase":  get_usecase_prompt,
        "activity": get_activity_prompt,
        "sequence": get_sequence_prompt,
        "context":  get_context_prompt,
        "state":    get_state_prompt,
        "dfd":      get_dfd_prompt,
        "gantt":    get_gantt_prompt,
    }
    fn = prompts.get(diagram_type, get_class_prompt)
    return fn(text)


def extract_mermaid(text: str, diagram_type: str = "") -> str:
    if diagram_type == "class":
        m = re.search(r"(classDiagram[\s\S]*)", text)
        if m: return m.group(1).strip()

    if diagram_type == "erd":
        m = re.search(r"(erDiagram[\s\S]*)", text)
        if m: return m.group(1).strip()

    if diagram_type == "sequence":
        m = re.search(r"(sequenceDiagram[\s\S]*)", text)
        if m: return m.group(1).strip()

    if diagram_type == "state":
        m = re.search(r"(stateDiagram[\s\S]*)", text)
        if m: return m.group(1).strip()

    if diagram_type == "gantt":
        m = re.search(r"(gantt[\s\S]*)", text)
        if m: return m.group(1).strip()

    # flowchart types
    if diagram_type in ["usecase", "activity", "context", "dfd"]:
        m = re.search(r"(flowchart[\s\S]*)", text)
        if m: return m.group(1).strip()

    # auto detect
    for pattern in [r"(classDiagram[\s\S]*)", r"(erDiagram[\s\S]*)",
                    r"(sequenceDiagram[\s\S]*)", r"(stateDiagram[\s\S]*)",
                    r"(gantt[\s\S]*)", r"(flowchart[\s\S]*)",
                    r"(mindmap[\s\S]*)"]:
        m = re.search(pattern, text)
        if m: return m.group(1).strip()

    return text.strip()


def clean_mermaid_code(raw: str) -> str:
    raw = (raw.replace("```mermaid", "").replace("```", "").strip())
    lines = [line.rstrip() for line in raw.split("\n") if line.strip()]
    return "\n".join(lines).strip()


def generate_mermaid(text: str, diagram_type: str) -> str:
    if diagram_type == "mindmap":
        return generate_mindmap_from_text(text)

    prompt = get_prompt(text, diagram_type)
    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}]
        )
        raw_code = response.choices[0].message.content.strip()
        print(f"\n===== RAW ({diagram_type}) =====\n{raw_code}")
        extracted = extract_mermaid(raw_code, diagram_type)
        cleaned = clean_mermaid_code(extracted)
        print(f"\n===== CLEANED =====\n{cleaned}")
        return cleaned
    except Exception as e:
        print(f"Generate Mermaid Error: {e}")
        fallbacks = {
            "erd":      "erDiagram\n    ENTITY {\n        int id PK\n    }",
            "sequence": "sequenceDiagram\n    participant A\n    participant B\n    A->>B: Hello",
            "state":    "stateDiagram-v2\n    [*] --> State1\n    State1 --> [*]",
            "gantt":    "gantt\n    title Project\n    dateFormat YYYY-MM-DD\n    section Phase\n    Task: 2024-01-01, 7d",
        }
        return fallbacks.get(diagram_type, "flowchart TD\n    A --> B")


def generate_mindmap_from_text(text: str) -> str:
    raw = ""
    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{
                "role": "user",
                "content": f"""Extract the main topic and subtopics from this text as JSON.
Return ONLY valid JSON, no explanation, no markdown, no code blocks.

Format:
{{
  "root": "Main Topic",
  "children": [
    {{
      "name": "Subtopic 1",
      "children": [
        {{"name": "Detail 1"}},
        {{"name": "Detail 2"}}
      ]
    }},
    {{"name": "Subtopic 2"}}
  ]
}}

Rules:
- root must be a single short phrase
- max 4 children
- max 3 grandchildren per child
- no special characters except spaces
- return ONLY the JSON object

Text: {text}
"""
            }]
        )
        raw = response.choices[0].message.content.strip()
        raw = raw.replace("```json", "").replace("```", "").strip()
        json_match = re.search(r'\{[\s\S]*\}', raw)
        if json_match:
            raw = json_match.group(0)
        data = json.loads(raw)
        result = build_mindmap(data)
        if "root((" not in result:
            raise ValueError("Invalid mindmap")
        return result
    except Exception as e:
        print(f"Mindmap Error: {type(e).__name__}: {e}")
        return f"mindmap\n  root(({text[:20]}))\n    Error generating diagram"


def build_mindmap(data: dict) -> str:
    def clean(text):
        return re.sub(r'[^\w\s\-]', '', str(text)).strip()

    root = clean(data.get("root", "System"))
    lines = ["mindmap", f"  root(({root}))"]

    for child in data.get("children", []):
        if not isinstance(child, dict): continue
        name = clean(child.get("name", ""))
        if not name: continue
        lines.append("    " + name)
        for grandchild in child.get("children", []):
            if not isinstance(grandchild, dict): continue
            gname = clean(grandchild.get("name", ""))
            if not gname: continue
            lines.append("      " + gname)

    result = "\n".join(lines)
    result = result.replace('\r', '')
    return result


def analyze_text(text: str) -> str:
    prompt = get_analyse_prompt(text)
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.choices[0].message.content


def explain_diagram(text: str, diagram_code: str) -> str:
    prompt = get_explain_prompt(text, diagram_code)
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.choices[0].message.content