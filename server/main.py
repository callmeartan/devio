from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pydantic_settings import BaseSettings
import time
import json
import httpx
from typing import List, Optional
import logging
import os

class Settings(BaseSettings):
    ollama_api_base: str = "http://localhost:11434"
    default_max_tokens: int = 1000
    default_temperature: float = 0.7
    request_timeout: float = 1200.0
    custom_ollama_ip: str = ""  # Added new setting for custom Ollama IP

    class Config:
        env_prefix = "OLLAMA_"

settings = Settings()

# Update Ollama API base if custom IP is provided
if settings.custom_ollama_ip:
    if not settings.custom_ollama_ip.startswith(('http://', 'https://')):
        settings.ollama_api_base = f"http://{settings.custom_ollama_ip}:11434"
    else:
        # If protocol is included, use as is
        settings.ollama_api_base = settings.custom_ollama_ip

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

class OllamaConfigRequest(BaseModel):
    custom_ollama_ip: Optional[str] = None

class OllamaConfigResponse(BaseModel):
    custom_ollama_ip: Optional[str]
    ollama_api_base: str

async def get_available_models() -> List[str]:
    """Get list of available models from Ollama."""
    logging.info(f"Attempting to connect to Ollama at {settings.ollama_api_base}")
    
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            logging.info(f"Sending request to {settings.ollama_api_base}/api/tags")
            response = await client.get(f"{settings.ollama_api_base}/api/tags")
            logging.info(f"Response status code: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                logging.info(f"Response data: {data}")
                
                if "models" in data:
                    models = [model["name"] for model in data["models"]]
                    logging.info(f"Found models: {models}")
                    return models
                logging.warning("No models found in response")
                return []
                
            logging.error(f"Failed to fetch models: {response.status_code} - {response.text}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to fetch models from Ollama: {response.status_code} - {response.text}"
            )
        except httpx.ConnectError as e:
            logging.error(f"Connection error: {str(e)}")
            # Return default models instead of throwing an error
            default_models = ["mistral:latest", "llama3:8b", "phi3:14b"]
            logging.info(f"Returning default models: {default_models}")
            return default_models
        except Exception as e:
            logging.error(f"Unexpected error: {str(e)}")
            # Return default models instead of throwing an error
            default_models = ["mistral:latest", "llama3:8b", "phi3:14b"]
            logging.info(f"Returning default models: {default_models}")
            return default_models

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
        logging.info("Received request to list models")
        available_models = await get_available_models()
        logging.info(f"Returning models: {available_models}")
        return ModelListResponse(models=available_models)
    except Exception as e:
        logging.error(f"Error in list_models: {str(e)}")
        # Return default models instead of throwing an error
        default_models = ["mistral:latest", "llama3:8b", "phi3:14b"]
        logging.info(f"Returning default models: {default_models}")
        return ModelListResponse(models=default_models)

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
    logging.info(f"Received generate request for model: {request.model_name}")
    logging.info(f"Prompt: {request.prompt[:100]}...")  # Log first 100 chars of prompt
    
    try:
        # Verify model exists
        available_models = await get_available_models()
        
        # If no models available, use the requested model anyway
        if not available_models:
            logging.warning("No models available, proceeding with requested model")
        elif request.model_name not in available_models:
            logging.warning(f"Model '{request.model_name}' not found in available models: {available_models}")
            # Try to use the model anyway
        
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
        
        logging.info(f"Sending request to Ollama: {ollama_request}")
        
        # Send request to Ollama
        async with httpx.AsyncClient(timeout=settings.request_timeout) as client:
            try:
                response = await client.post(
                    f"{settings.ollama_api_base}/api/generate",
                    json=ollama_request,
                    timeout=settings.request_timeout
                )
                
                logging.info(f"Response status code: {response.status_code}")
                
                if response.status_code != 200:
                    logging.error(f"Ollama API request failed: {response.status_code} - {response.text}")
                    return GenerateResponse(
                        text=f"Error: Failed to generate response. Status code: {response.status_code}",
                        model_name=request.model_name
                    )
                
                result = response.json()
                logging.info(f"Response received with {len(result.get('response', ''))} characters")
                
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
                
            except httpx.ConnectError as e:
                logging.error(f"Connection error: {str(e)}")
                return GenerateResponse(
                    text="Error: Could not connect to Ollama. Make sure Ollama is running (ollama serve)",
                    model_name=request.model_name
                )
            except httpx.TimeoutException as e:
                logging.error(f"Timeout error: {str(e)}")
                return GenerateResponse(
                    text="Error: Request to Ollama timed out. The model might be too slow or resource-intensive.",
                    model_name=request.model_name
                )
            except Exception as e:
                logging.error(f"Unexpected error: {str(e)}")
                return GenerateResponse(
                    text=f"Error: Unexpected error occurred: {str(e)}",
                    model_name=request.model_name
                )
            
    except Exception as e:
        logging.error(f"Error in generate endpoint: {str(e)}")
        return GenerateResponse(
            text=f"Error: {str(e)}",
            model_name=request.model_name
        )

@app.post(
    "/config/ollama",
    response_model=OllamaConfigResponse,
    responses={
        400: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
    }
)
async def update_ollama_config(request: OllamaConfigRequest):
    """
    Update Ollama configuration including custom IP address.
    
    Args:
        request (OllamaConfigRequest): The configuration request with custom_ollama_ip
        
    Returns:
        OllamaConfigResponse: The updated configuration
    """
    try:
        # Update custom Ollama IP
        settings.custom_ollama_ip = request.custom_ollama_ip or ""
        
        # Set env var for persistence between restarts
        if settings.custom_ollama_ip:
            os.environ["OLLAMA_CUSTOM_OLLAMA_IP"] = settings.custom_ollama_ip
        elif "OLLAMA_CUSTOM_OLLAMA_IP" in os.environ:
            del os.environ["OLLAMA_CUSTOM_OLLAMA_IP"]
        
        # Update Ollama API base if custom IP is provided
        if settings.custom_ollama_ip:
            if not settings.custom_ollama_ip.startswith(('http://', 'https://')):
                settings.ollama_api_base = f"http://{settings.custom_ollama_ip}:11434"
            else:
                # If protocol is included, use as is
                settings.ollama_api_base = settings.custom_ollama_ip
        else:
            # Reset to default
            settings.ollama_api_base = "http://localhost:11434"
        
        logging.info(f"Updated Ollama API Base to: {settings.ollama_api_base}")
        
        return OllamaConfigResponse(
            custom_ollama_ip=settings.custom_ollama_ip,
            ollama_api_base=settings.ollama_api_base
        )
    except Exception as e:
        logging.error(f"Error updating Ollama config: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update Ollama configuration: {str(e)}"
        )

@app.get(
    "/config/ollama",
    response_model=OllamaConfigResponse,
    responses={
        500: {"model": ErrorResponse},
    }
)
async def get_ollama_config():
    """
    Get current Ollama configuration.
    
    Returns:
        OllamaConfigResponse: The current configuration
    """
    try:
        return OllamaConfigResponse(
            custom_ollama_ip=settings.custom_ollama_ip,
            ollama_api_base=settings.ollama_api_base
        )
    except Exception as e:
        logging.error(f"Error getting Ollama config: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get Ollama configuration: {str(e)}"
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