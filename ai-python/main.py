from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from app.routes.generate import router as generate_router
from app.routes.chat import router as chat_router
from app.routes.edit import router as edit_router
from app.routes.export import router as export_router
from app.services.rate_limiter import limiter

app = FastAPI(
    title="AI Diagram Generator",
    description="Converts text to Mermaid.js diagrams using Claude AI",
    version="1.0.0"
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(generate_router, prefix="/api")
app.include_router(chat_router, prefix="/api")
app.include_router(edit_router, prefix="/api")
app.include_router(export_router, prefix="/api")