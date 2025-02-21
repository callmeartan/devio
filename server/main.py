from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import time
import json
import httpx
from typing import List, Optional

app = FastAPI()

class GenerateRequest(BaseModel):
    prompt: str
    model_name: str
    max_tokens: int = 1000
    temperature: float = 0.7

class GenerateResponse(BaseModel):
    text: str
    model_name: str
    total_duration: Optional[int] = None
    load_duration: Optional[int] = None
    prompt_eval_count: Optional[int] = None
    prompt_eval_duration: Optional[int] = None
    eval_count: Optional[int] = None
    eval_duration: Optional[int] = None

OLLAMA_API_BASE = "http://localhost:11434"

async def get_available_models() -> List[str]:
    """Get list of available models from Ollama."""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{OLLAMA_API_BASE}/api/tags")
            if response.status_code == 200:
                data = response.json()
                if "models" in data:
                    return [model["name"] for model in data["models"]]
                return []
            raise HTTPException(
                status_code=500,
                detail=f"Failed to fetch models from Ollama: {response.status_code}"
            )
        except httpx.ConnectError:
            raise HTTPException(
                status_code=503,
                detail="Could not connect to Ollama. Make sure Ollama is running (ollama serve)"
            )
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to fetch models: {str(e)}"
            )

@app.get("/models")
async def list_models():
    """List all available models from Ollama."""
    try:
        available_models = await get_available_models()
        return {"models": available_models}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to list models: {str(e)}"
        )

@app.post("/generate")
async def generate(request: GenerateRequest):
    """Generate text using Ollama and return response with metrics."""
    try:
        # Verify model exists
        available_models = await get_available_models()
        if not available_models:
            raise HTTPException(
                status_code=400,
                detail="No models available in Ollama. Please install a model first using 'ollama pull model:latest'"
            )
        
        if request.model_name not in available_models:
            raise HTTPException(
                status_code=400,
                detail=f"Model '{request.model_name}' not found. Available models: {available_models}"
            )
        
        # Prepare request for Ollama
        ollama_request = {
            "model": request.model_name,
            "prompt": request.prompt,
            "stream": False,
            "options": {
                "num_predict": request.max_tokens,
                "temperature": request.temperature
            }
        }
        
        # Send request to Ollama
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{OLLAMA_API_BASE}/api/generate",
                    json=ollama_request,
                    timeout=1200.0
                )
                
                if response.status_code != 200:
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"Ollama API request failed: {response.text}"
                    )
                
                result = response.json()
                
                # Forward the response with metrics
                return {
                    "text": result.get("response", ""),
                    "model_name": request.model_name,
                    "total_duration": result.get("total_duration"),
                    "load_duration": result.get("load_duration"),
                    "prompt_eval_count": result.get("prompt_eval_count"),
                    "prompt_eval_duration": result.get("prompt_eval_duration"),
                    "eval_count": result.get("eval_count"),
                    "eval_duration": result.get("eval_duration"),
                }
                
            except httpx.ConnectError:
                raise HTTPException(
                    status_code=503,
                    detail="Could not connect to Ollama. Make sure Ollama is running (ollama serve)"
                )
            except httpx.TimeoutException:
                raise HTTPException(
                    status_code=504,
                    detail="Request to Ollama timed out"
                )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Unexpected error: {str(e)}"
        )

if __name__ == "__main__":
    import uvicorn
    print("Starting server... Make sure Ollama is running (ollama serve)")
    uvicorn.run(app, host="0.0.0.0", port=8080) 