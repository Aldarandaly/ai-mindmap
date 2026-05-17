from fastapi import APIRouter, HTTPException, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.schemas.diagram import GenerateRequest, GenerateResponse
from app.services.detector import detect_type
from app.services.generator import generate_mermaid, analyze_text, explain_diagram
from app.services.validator import basic_validate_mermaid, advanced_validate_mermaid
from app.services.error_handling import handle_error
from app.services.rate_limiter import limiter
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter()

@router.post("/generate", response_model=GenerateResponse)
@limiter.limit("10/minute")
async def generate_diagram(request: Request, body: GenerateRequest):
    try:
        # 1. Determine Diagram Type
        diagram_type = body.type
        if diagram_type == "auto":
            diagram_type = detect_type(body.text)

        # 2. Handle different modes
        diagram_code = ""
        explanation = None

        if body.mode == "analyse":
            explanation = analyze_text(body.text)
        elif body.mode == "explain":
            diagram_code = generate_mermaid(body.text, diagram_type)
            explanation = explain_diagram(body.text, diagram_code)
        else:  # Default: generate
            diagram_code = generate_mermaid(body.text, diagram_type)

        # 3. Validate Mermaid Code
        if diagram_code:
            if not basic_validate_mermaid(diagram_code):
                raise HTTPException(
                    status_code=400,
                    detail="Invalid Mermaid code generated"
                )
            if not advanced_validate_mermaid(diagram_code, diagram_type):
                raise HTTPException(
                    status_code=400,
                    detail="Diagram structure is incorrect"
                )

        return GenerateResponse(
            diagram_code=diagram_code,
            type=diagram_type,
            explanation=explanation
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"REAL ERROR: {type(e).__name__}: {str(e)}")
        handle_error(e)

   

class ChatMessage(BaseModel):
    role: str
    message: str

class ChatRequest(BaseModel):
    message: str
    history: List[ChatMessage] = []
    project_name: str = ""

class ChatResponse(BaseModel):
    reply: str

@router.post("/chat", response_model=ChatResponse)
async def chat(request: Request, body: ChatRequest):
    try:
        # Build conversation history for Groq
        messages = []
        
        # System prompt
        messages.append({
            "role": "system",
            "content": f"""You are an AI assistant helping with software diagrams for project: {body.project_name}.
You can help users:
- Generate and improve ERD, Class, Mind Map, Sequence, Use Case diagrams
- Explain diagram concepts
- Suggest improvements
- Answer questions about software design
Keep responses concise and helpful."""
        })
        
        # Add history
        for msg in body.history[-10:]:  # last 10 messages for context
            role = "user" if msg.role == "user" else "assistant"
            messages.append({"role": role, "content": msg.message})
        
        # Add current message
        messages.append({"role": "user", "content": body.message})
        
        from app.services.generator import client
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
            max_tokens=500,
        )
        
        reply = response.choices[0].message.content.strip()
        return ChatResponse(reply=reply)
        
    except Exception as e:
        print(f"Chat Error: {e}")
        raise HTTPException(status_code=500, detail="Chat failed")

@router.get("/health")
async def health_check():
    return {"status": "ok", "service": "AI Diagram Generator"}