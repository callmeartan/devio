#!/bin/bash

# Prompt for Ollama host
echo "Enter Ollama host IP and port (e.g., 192.168.1.1:2001):"
read ollama_host

# Set the Ollama host environment variable if provided
if [ ! -z "$ollama_host" ]; then
    # Create or update .env file in the parent directory
    if grep -q "OLLAMA_HOST" ../.env; then
        # Replace existing OLLAMA_HOST line
        sed -i '' "s/^.*OLLAMA_HOST.*$/OLLAMA_HOST=$ollama_host/" ../.env
    else
        # Add new OLLAMA_HOST line
        echo "OLLAMA_HOST=$ollama_host" >> ../.env
    fi
    echo "OLLAMA_HOST set to $ollama_host in .env file"
else
    echo "No Ollama host provided. No changes made."
fi 