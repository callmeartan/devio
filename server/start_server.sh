#!/bin/bash

# Check if OLLAMA_HOST is already set
if [ -z "$OLLAMA_HOST" ]; then
    # Prompt for Ollama host
    echo "Enter Ollama host IP and port (e.g., 192.168.1.1:2001):"
    read ollama_host
    
    # Set the Ollama host environment variable if provided
    if [ ! -z "$ollama_host" ]; then
        export OLLAMA_HOST="$ollama_host"
        echo "OLLAMA_HOST set to $OLLAMA_HOST"
    else
        echo "No Ollama host provided. Using default (localhost:11434)."
    fi
else
    echo "Using existing OLLAMA_HOST: $OLLAMA_HOST"
fi

# Activate the virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Start the server
python main.py 