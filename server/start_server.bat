@echo off

REM Check if OLLAMA_HOST is already set
if "%OLLAMA_HOST%" == "" (
    REM Prompt for Ollama host
    echo Enter Ollama host IP and port (e.g., 192.168.1.1:2001):
    set /p ollama_host=
    
    REM Set the Ollama host environment variable if provided
    if not "%ollama_host%" == "" (
        set OLLAMA_HOST=%ollama_host%
        echo OLLAMA_HOST set to %OLLAMA_HOST%
    ) else (
        echo No Ollama host provided. Using default (localhost:11434).
    )
) else (
    echo Using existing OLLAMA_HOST: %OLLAMA_HOST%
)

REM Activate the virtual environment if it exists
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
)

REM Start the server
python main.py 