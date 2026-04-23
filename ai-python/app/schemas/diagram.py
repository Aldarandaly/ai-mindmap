from pydantic import BaseModel, field_validator
from typing import Literal, Optional

class GenerateRequest(BaseModel):
    text: str
    type: Literal["auto", "class", "erd", "mindmap"] = "auto"
    mode: Literal["generate", "analyse", "explain"] = "generate"

    @field_validator("text")
    @classmethod
    def validate_text(cls, v):
        if not v or not v.strip():
            raise ValueError("Text cannot be empty")
        
        if len(v.strip()) < 10:
            raise ValueError("Text is too short, minimum 10 characters")
        
        if len(v.strip()) > 5000:
            raise ValueError("Text is too long, maximum 5000 characters")
        
        return v.strip()

class GenerateResponse(BaseModel):
    diagram_code: str
    type: str
    explanation: Optional[str] = None