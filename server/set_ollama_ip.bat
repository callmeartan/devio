@echo off

REM Prompt for Ollama host
echo Enter Ollama host IP and port (e.g., 192.168.1.1:2001):
set /p ollama_host=

REM Set the Ollama host environment variable if provided
if not "%ollama_host%" == "" (
    REM Create or update .env file in the parent directory
    set env_file=..\.env
    set temp_file=..\temp.env
    
    if exist %env_file% (
        REM Check if OLLAMA_HOST already exists in the file
        findstr /C:"OLLAMA_HOST" %env_file% >nul
        if errorlevel 1 (
            REM OLLAMA_HOST not found, append it
            echo OLLAMA_HOST=%ollama_host%>> %env_file%
        ) else (
            REM OLLAMA_HOST found, replace it
            type nul > %temp_file%
            for /f "tokens=*" %%a in (%env_file%) do (
                echo %%a | findstr /C:"OLLAMA_HOST" >nul
                if errorlevel 1 (
                    echo %%a>> %temp_file%
                ) else (
                    echo OLLAMA_HOST=%ollama_host%>> %temp_file%
                )
            )
            move /y %temp_file% %env_file% >nul
        )
    ) else (
        REM .env file doesn't exist, create it
        echo OLLAMA_HOST=%ollama_host%> %env_file%
    )
    
    echo OLLAMA_HOST set to %ollama_host% in .env file
) else (
    echo No Ollama host provided. No changes made.
) 