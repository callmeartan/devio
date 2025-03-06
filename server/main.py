from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pydantic_settings import BaseSettings
import time
import json
import httpx
from typing import List, Optional
import logging

class Settings(BaseSettings):
    ollama_api_base: str = "http://192.168.1.105:11434"
    default_max_tokens: int = 1000
    default_temperature: float = 0.7
    request_timeout: float = 1200.0

    class Config:
        env_prefix = "OLLAMA_"

settings = Settings()
app = FastAPI()

class ErrorResponse(BaseModel):
    detail: str
    status_code: int

class ModelListResponse(BaseModel):
    models: List[str]

class GenerateRequest(BaseModel):
    prompt: str
    model_name: str
    max_tokens: int = settings.default_max_tokens
    temperature: float = settings.default_temperature

class GenerateResponse(BaseModel):
    text: str
    model_name: str
    total_duration: Optional[int] = None
    load_duration: Optional[int] = None
    prompt_eval_count: Optional[int] = None
    prompt_eval_duration: Optional[int] = None
    eval_count: Optional[int] = None
    eval_duration: Optional[int] = None

    class Config:
        schema_extra = {
            "example": {
                "text": "Generated text response",
                "model_name": "llama2",
                "total_duration": 1000,
                "load_duration": 100,
                "prompt_eval_count": 10,
                "prompt_eval_duration": 500,
                "eval_count": 100,
                "eval_duration": 900
            }
        }

async def get_available_models() -> List[str]:
    """Get list of available models from Ollama."""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{settings.ollama_api_base}/api/tags")
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

@app.get(
    "/models",
    response_model=ModelListResponse,
    responses={
        500: {"model": ErrorResponse},
        503: {"model": ErrorResponse}
    }
)
async def list_models():
    """
    List all available models from Ollama.
    
    Returns:
        ModelListResponse: List of available model names
        
    Raises:
        HTTPException: If unable to fetch models or connect to Ollama
    """
    try:
        available_models = await get_available_models()
        return ModelListResponse(models=available_models)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to list models: {str(e)}"
        )

@app.post(
    "/generate",
    response_model=GenerateResponse,
    responses={
        400: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
        503: {"model": ErrorResponse},
        504: {"model": ErrorResponse}
    }
)
async def generate(request: GenerateRequest) -> GenerateResponse:
    """
    Generate text using the specified Ollama model.
    
    Args:
        request (GenerateRequest): The generation request parameters
        
    Returns:
        GenerateResponse: The generated text and performance metrics
        
    Raises:
        HTTPException: If model not found, connection fails, or other errors occur
    """
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
                    f"{settings.ollama_api_base}/api/generate",
                    json=ollama_request,
                    timeout=settings.request_timeout
                )
                
                if response.status_code != 200:
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"Ollama API request failed: {response.text}"
                    )
                
                result = response.json()
                
                # Return typed response
                return GenerateResponse(
                    text=result.get("response", ""),
                    model_name=request.model_name,
                    total_duration=result.get("total_duration"),
                    load_duration=result.get("load_duration"),
                    prompt_eval_count=result.get("prompt_eval_count"),
                    prompt_eval_duration=result.get("prompt_eval_duration"),
                    eval_count=result.get("eval_count"),
                    eval_duration=result.get("eval_duration"),
                )
                
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
    
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    logger = logging.getLogger(__name__)
    
    # Log startup configuration
    logger.info("Starting server with configuration:")
    logger.info(f"Ollama API Base: {settings.ollama_api_base}")
    logger.info(f"Default Max Tokens: {settings.default_max_tokens}")
    logger.info(f"Default Temperature: {settings.default_temperature}")
    logger.info(f"Request Timeout: {settings.request_timeout}")
    
    # Start server
    logger.info("Make sure Ollama is running (ollama serve)")
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8080,
        log_level="info"
    ) 