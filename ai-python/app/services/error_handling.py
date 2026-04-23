from fastapi import HTTPException

def handle_error(e: Exception):
    error_msg = str(e)

    if "Invalid Mermaid" in error_msg:
        raise HTTPException(
            status_code=400,
            detail="Generated diagram is invalid"
        )

    raise HTTPException(
        status_code=500,
        detail="AI generation failed, try again"
    )