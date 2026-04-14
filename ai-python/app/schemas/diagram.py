from pydantic import BaseModel
from typing import Literal, Optional

class GenerateRequest(BaseModel):
    text: str
    type: Literal["auto", "class", "erd", "mindmap"] = "auto"
    mode: Literal["generate", "analyse", "explain"] = "generate"

class GenerateResponse(BaseModel):
    diagram_code: str
    type: str
    explanation: Optional[str] = None