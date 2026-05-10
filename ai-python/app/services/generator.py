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

load_dotenv()

client = Groq(
    api_key=os.getenv("GROQ_API_KEY")
)

def get_prompt(text: str, diagram_type: str) -> str:

    if diagram_type == "erd":
        return get_erd_prompt(text)

    elif diagram_type == "mindmap":
        return get_mindmap_prompt(text)

    return get_class_prompt(text)


def extract_mermaid(text: str, diagram_type: str = "") -> str:

    # لو عارف النوع استخدمه مباشرة
    if diagram_type == "class":
        class_match = re.search(r"(classDiagram[\s\S]*)", text)
        if class_match:
            return class_match.group(1).strip()

    if diagram_type == "erd":
        erd_match = re.search(r"(erDiagram[\s\S]*)", text)
        if erd_match:
            return erd_match.group(1).strip()

    # auto detect
    class_match = re.search(r"(classDiagram[\s\S]*)", text)
    if class_match:
        return class_match.group(1).strip()

    erd_match = re.search(r"(erDiagram[\s\S]*)", text)
    if erd_match:
        return erd_match.group(1).strip()

    mindmap_match = re.search(r"(mindmap[\s\S]*)", text)
    if mindmap_match:
        return mindmap_match.group(1).strip()

    return text.strip()

import json

def json_to_mermaid(json_text: str) -> str:

    try:
        data = json.loads(json_text)

        lines = [
            "mindmap",
            f"  root(({data.get('root', 'System')}))"
        ]

        def add_children(children, level):

            if not isinstance(children, list):
                return

            for child in children:

                if not isinstance(child, dict):
                    continue

                name = child.get("name")

                if not name:
                    continue

                indent = "  " * level

                lines.append(f"{indent}{name}")

                if "children" in child:
                    add_children(child["children"], level + 1)

        add_children(data.get("children", []), 2)

        return "\n".join(lines)

    except Exception as e:

        print("JSON ERROR:", e)

        return """mindmap
  root((System))
    Error"""

def clean_mermaid_code(raw: str) -> str:

    raw = (
        raw.replace("```mermaid", "")
           .replace("```", "")
           .strip()
    )

    lines = raw.split("\n")
    cleaned_lines = []

    for line in lines:

        stripped = line.rstrip()

        if not stripped:
            continue

        cleaned_lines.append(stripped)

    return "\n".join(cleaned_lines).strip()


def auto_fix_mindmap(code: str) -> str:
    lines = [l.rstrip() for l in code.split("\n") if l.strip()]
    
    fixed = ["mindmap"]
    root_added = False
    
    for line in lines:
        stripped = line.strip()
        
        # skip mindmap keyword
        if stripped == "mindmap":
            continue
            
        # handle root
        if "root((" in stripped:
            if not root_added:
                fixed.append(f"  {stripped}")
                root_added = True
            continue
        
        # remove brackets and special chars
        stripped = (stripped
            .replace("[", "")
            .replace("]", "")
            .replace("(", "")
            .replace(")", "")
            .replace("{", "")
            .replace("}", "")
            .strip())
        
        if not stripped:
            continue
            
        indent = len(line) - len(line.lstrip())
        if indent == 0:
            fixed.append(f"    {stripped}")
        elif indent <= 2:
            fixed.append(f"    {stripped}")
        elif indent <= 4:
            fixed.append(f"    {stripped}")
        else:
            fixed.append(f"      {stripped}")
    
    if not root_added:
        fixed.insert(1, "  root((System))")
    
    return "\n".join(fixed)

def safe_validate_mindmap(code: str) -> str:

    try:

        lines = [l for l in code.split("\n") if l.strip()]

        if not lines:
            raise ValueError("Empty diagram")

        if lines[0].strip() != "mindmap":
            raise ValueError("Mindmap must start with 'mindmap'")

        root_count = sum(
            1 for l in lines if "root((" in l
        )

        if root_count != 1:
            raise ValueError("Mindmap must contain exactly one root")

        return code

    except Exception as e:

        print("Mindmap validation error:", e)

        return """mindmap
  root((System))
    Error"""

def simple_mindmap_parser(text: str) -> str:

    words = text.split()

    filtered = []

    for word in words:

        word = word.lower()

        if word in ["mindmap", "root", "system"]:
            continue

        filtered.append(word.capitalize())

    result = [
        "mindmap",
        "  root((System))"
    ]

    if len(filtered) > 0:

        # first node
        result.append(f"    {filtered[0]}")

        # children
        for word in filtered[1:]:
            result.append(f"      {word}")

    return "\n".join(result)

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
        extracted = extract_mermaid(raw_code, diagram_type) 
        cleaned = clean_mermaid_code(extracted)
        return cleaned
    except Exception as e:
        print("Generate Mermaid Error:", e)
        if diagram_type == "erd":
            return "erDiagram\n    ENTITY {\n        int id PK\n    }"
        return "classDiagram\n    class System {\n        +init()\n    }"


def generate_mindmap_from_text(text: str) -> str:
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
            raise ValueError("Invalid mindmap generated")
            
        return result
        
    except Exception as e:
        print(f"Mindmap Error: {type(e).__name__}: {e}")
        print(f"Raw response was: {raw}")
        return f"mindmap\n  root(({text[:20]}))\n    Error generating diagram"


def build_mindmap(data: dict) -> str:
    def clean(text):
        return re.sub(r'[^\w\s\-]', '', str(text)).strip()
    
    root = clean(data.get("root", "System"))
    lines = ["mindmap", f"  root(({root}))"]
    
    for child in data.get("children", []):
        if not isinstance(child, dict):
            continue
        name = clean(child.get("name", ""))
        if not name:
            continue
        lines.append("    " + name)
        print(f"DEBUG child: '{name}'")
        
        for grandchild in child.get("children", []):
            if not isinstance(grandchild, dict):
                continue
            gname = clean(grandchild.get("name", ""))
            if not gname:
                continue
            lines.append("      " + gname)
    
    result = "\n".join(lines)
    print(f"DEBUG final mindmap:\n{result}")
    
    return result

def analyze_text(text: str) -> str:

    prompt = get_analyse_prompt(text)

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ]
    )

    return response.choices[0].message.content


def explain_diagram(
    text: str,
    diagram_code: str
) -> str:

    prompt = get_explain_prompt(
        text,
        diagram_code
    )

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ]
    )

    return response.choices[0].message.content