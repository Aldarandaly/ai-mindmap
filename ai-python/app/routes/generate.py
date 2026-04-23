from fastapi import APIRouter, HTTPException, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.schemas.diagram import GenerateRequest, GenerateResponse
from app.services.detector import detect_type
from app.services.generator import generate_mermaid, analyze_text, explain_diagram
from app.services.validator import basic_validate_mermaid, advanced_validate_mermaid
from app.services.error_handling import handle_error
from app.services.rate_limiter import limiter

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
        handle_error(e)


@router.get("/health")
async def health_check():
    return {"status": "ok", "service": "AI Diagram Generator"}