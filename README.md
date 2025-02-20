# DevIO - AI Development Guide

A Flutter application that provides an interactive chat interface with local LLMs (Language Learning Models) through Ollama, featuring real-time performance metrics and a modern UI.

## Features

- 🤖 Interactive chat interface with AI models
- 📊 Real-time performance metrics for each response
  - Total processing time
  - Model loading duration
  - Prompt evaluation statistics
  - Response generation metrics
  - Token processing rates
- 🎨 Modern Material Design 3 UI
- 🔄 Support for multiple Ollama models
- ⚡ Real-time text generation
- 📱 Responsive design
- 🔍 Detailed performance insights
- 🎯 Model switching capability

## Prerequisites

- Flutter SDK (latest stable version)
- Python 3.8 or higher
- [Ollama](https://ollama.ai) installed and running
- At least one Ollama model pulled (e.g., `ollama pull deepseek-coder:1.5b`)

## Setup

### 1. Ollama Setup

```bash
# Install Ollama (if not already installed)
# Visit https://ollama.ai for installation instructions

# Start Ollama service
ollama serve

# Pull a model (in a new terminal)
ollama pull deepseek-coder:1.5b
```

### 2. Python FastAPI Server Setup

```bash
# Navigate to server directory
cd server

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Start the server (default port: 8080)
python main.py
```

### 3. Flutter App Setup

```bash
# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## Architecture

```
lib/
├── features/
│   └── llm/
│       ├── cubit/
│       │   ├── llm_cubit.dart
│       │   └── llm_state.dart
│       ├── models/
│       │   └── llm_response.dart
│       ├── presentation/
│       │   └── llm_chat_screen.dart
│       └── services/
│           └── llm_service.dart
└── server/
    ├── main.py
    └── requirements.txt
```

## Usage

1. Ensure all three components are running:
   - Ollama service (`ollama serve`)
   - FastAPI server (`python main.py`)
   - Flutter app (`flutter run`)

2. In the app:
   - Select your preferred AI model from the dropdown
   - Type your prompt in the input field
   - Press send or hit enter
   - View the AI's response
   - Click the "Performance Metrics" button to view detailed processing statistics

## Performance Metrics

The app provides detailed performance metrics for each AI response:

- **Total Time**: Overall processing duration
- **Prompt Metrics**:
  - Token count
  - Processing duration
  - Processing speed (tokens/second)
- **Response Metrics**:
  - Generated tokens
  - Generation duration
  - Generation speed (tokens/second)

## API Endpoints

### GET /models
Lists available Ollama models.

Response:
```json
{
  "models": ["deepseek-coder:1.5b", "llama2:7b", ...]
}
```

### POST /generate
Generates text using the selected model.

Request:
```json
{
  "prompt": "string",
  "model_name": "deepseek-coder:1.5b",
  "max_tokens": 1000,
  "temperature": 0.7
}
```

Response:
```json
{
  "text": "Generated response",
  "model_name": "deepseek-coder:1.5b",
  "total_duration": 1234567890,
  "prompt_eval_count": 100,
  "eval_count": 50,
  ...
}
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Troubleshooting

- If the server fails to start, check if port 8080 is available
- Ensure Ollama is running with `ollama serve`
- Check if you have at least one model pulled with `ollama list`
- For Flutter errors, try `flutter clean` followed by `flutter pub get`

## License

This project is licensed under the MIT License - see the LICENSE file for details.
