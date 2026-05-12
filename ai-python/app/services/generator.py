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

load_dotenv()

client = Groq(
    api_key=os.getenv("GROQ_API_KEY")
)

def get_prompt(text: str, diagram_type: str) -> str:

    if diagram_type == "erd":
        return get_erd_prompt(text)

    elif diagram_type == "mindmap":
        return get_mindmap_prompt(text)

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