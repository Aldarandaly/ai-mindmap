from pydantic import BaseModel, Field
from typing import Optional

class ChatMessage(BaseModel):
    role: str  # "user" or "assistant"
    content: str

class EditRequest(BaseModel):
    current_code: str = Field(..., min_length=10)
    message: str = Field(..., min_length=2, max_length=1000)
    type: str = Field(..., description="diagram type")
    history: Optional[list[ChatMessage]] = []

class EditResponse(BaseModel):
    diagram_code: str
    reply: str