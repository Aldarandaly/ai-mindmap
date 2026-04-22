from fastapi import APIRouter, HTTPException
from app.schemas.diagram import GenerateRequest, GenerateResponse
from app.services.detector import detect_type
from app.services.generator import generate_mermaid, analyze_text, explain_diagram

router = APIRouter()

@router.post("/generate", response_model=GenerateResponse)
async def generate_diagram(request: GenerateRequest):
    try:
        # 1. Determine Diagram Type
        diagram_type = request.type
        if diagram_type == "auto":
            diagram_type = detect_type(request.text)

        # 2. Handle different modes
        diagram_code = ""
        explanation = None

        if request.mode == "analyse":
            explanation = analyze_text(request.text)
        elif request.mode == "explain":
            diagram_code = generate_mermaid(request.text, diagram_type)
            explanation = explain_diagram(request.text, diagram_code)
        else:  # Default: generate
            diagram_code = generate_mermaid(request.text, diagram_type)

        return GenerateResponse(
            diagram_code=diagram_code,
            type=diagram_type,
            explanation=explanation
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health_check():
    return {"status": "ok", "service": "AI Diagram Generator"}