from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from contextlib import asynccontextmanager

from routers import users, stations, predictions, notifications
from database import init_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(title="FloodSense API", version="1.0.0", lifespan=lifespan)

# CORS - allow all origins for dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(stations.router, prefix="/stations", tags=["stations"])
app.include_router(predictions.router, prefix="/predictions", tags=["predictions"])
app.include_router(notifications.router, prefix="/notifications", tags=["notifications"])

# Direct /predict endpoint alias
app.add_api_route("/predict", predictions.predict, methods=["POST"], response_model=predictions.FloodRiskScore, tags=["predictions"])


@app.get("/health", tags=["health"])
def health_check():
    return {"status": "ok", "service": "FloodSense API"}


@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse(url="/docs")


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
