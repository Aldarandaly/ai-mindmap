from groq import Groq
import os
from dotenv import load_dotenv

load_dotenv()
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

SYSTEM_PROMPT = """
You are a helpful support assistant for DiagramAI — an AI-powered diagram generation application.

You help users with:
1. How to use the app (create projects, generate diagrams, export)
2. Diagram types: ERD, Class, Mind Map, Use Case, Activity, Sequence, Context, State, DFD, Gantt
3. Troubleshooting common issues
4. Explaining what different diagrams mean
5. Subscription and payment questions

Rules:
- Be friendly, clear, and concise
- If you don't know something, say so honestly
- Always respond in the same language the user writes in
- Keep responses short and helpful (max 3-4 sentences)
- If the user has a technical issue, ask for more details
"""

def get_chat_response(message: str, history: list = []) -> str:
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    
    for msg in history:
        messages.append(msg)
    
    messages.append({"role": "user", "content": message})
    
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=messages,
        max_tokens=500
    )
    
    return response.choices[0].message.content