from groq import Groq
import os
from dotenv import load_dotenv
from app.prompts.class_prompt import get_class_prompt
from app.prompts.erd_prompt import get_erd_prompt
from app.prompts.mindmap_prompt import get_mindmap_prompt
from app.prompts.analyse_prompt import get_analyse_prompt
from app.prompts.explain_prompt import get_explain_prompt

load_dotenv()
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

def get_prompt(text: str, diagram_type: str) -> str:
    if diagram_type == "erd":
        return get_erd_prompt(text)
    elif diagram_type == "mindmap":
        return get_mindmap_prompt(text)
    else:
        return get_class_prompt(text)

def clean_mermaid_code(raw: str) -> str:
    # Remove markdown code blocks if present
    raw = raw.replace("```mermaid", "").replace("```", "").strip()
    
    # Common hallucinations to remove
    lines = raw.split("\n")
    cleaned_lines = []
    for line in lines:
        # Filter out lines that look like AI chatter but keep Mermaid keywords
        if any(keyword in line.lower() for keyword in ["classdiagram", "erd_diagram", "mindmap", "graph", "subgraph", "-->", "--|", "||", "{", "}", "[", "]"]):
            cleaned_lines.append(line)
        elif line.strip() == "":
            cleaned_lines.append(line)
            
    return "\n".join(cleaned_lines).strip()

def generate_mermaid(text: str, diagram_type: str) -> str:
    prompt = get_prompt(text, diagram_type)

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": prompt}]
    )

    raw_code = response.choices[0].message.content
    return clean_mermaid_code(raw_code)

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