from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import tickets
from .database import engine, Base
from .config import settings
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create database tables
Base.metadata.create_all(bind=engine)

# Create FastAPI app
app = FastAPI(
    title="Case Management API",
    description="Simple case management system for tax services",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://localhost:3000",
        "https://*.azurestaticapps.net",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(tickets.router, prefix="/api")

@app.get("/")
def read_root():
    """API information endpoint"""
    return {
        "name": "Case Management API",
        "version": "1.0.0",
        "company": settings.company_name,
        "status": "running"
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "database": "connected",
        "email_service": "configured"
    }
