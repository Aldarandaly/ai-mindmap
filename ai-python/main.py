from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.generate import router

app = FastAPI(
    title="AI Diagram Generator",
    description="Converts text to Mermaid.js diagrams using Claude AI",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="/api")