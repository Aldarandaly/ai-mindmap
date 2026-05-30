from fastapi import APIRouter, HTTPException, Request
from app.schemas.edit import EditRequest, EditResponse
from app.services.editor import edit_diagram
from app.services.rate_limiter import limiter

router = APIRouter()

@router.post("/edit", response_model=EditResponse)
@limiter.limit("15/minute")
async def edit_diagram_route(request: Request, body: EditRequest):
    try:
        result = edit_diagram(
            current_code=body.current_code,
            message=body.message,
            diagram_type=body.type,
            history=body.history or []
        )
        return EditResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))