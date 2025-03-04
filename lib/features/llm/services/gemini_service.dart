import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';  // Add this import for TimeoutException
import 'package:http/http.dart' as http;
import '../models/llm_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as dev;
import 'document_service.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1';
  final http.Client _client;
  final DocumentService _documentService;
  static const _timeout = Duration(seconds: 120);
  static const _maxRetries = 3;
  static const _healthCheckTimeout = Duration(seconds: 5);
  
  // Cache of working models
  static final Map<String, DateTime> _workingModelsCache = {};
  static const _cacheDuration = Duration(minutes: 5);
  
  // List of fallback models in order of preference
  static const List<String> _fallbackModels = [
    'gemini-1.5-pro-latest',  // Latest pro version
    'gemini-1.5-pro',         // Stable 1.5 version
    'gemini-pro',             // Stable pro version
  ];

  static const List<String> _fallbackVisionModels = [
    'gemini-1.5-pro-vision-latest',  // Latest vision version
    'gemini-1.5-pro-vision',         // Stable 1.5 vision version
    'gemini-pro-vision',             // Stable pro vision version
  ];

  GeminiService({
    http.Client? client,
    DocumentService? documentService,
  }) : _client = client ?? http.Client(),
       _documentService = documentService ?? DocumentService();

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Check if a model is available (with caching)
  Future<bool> _isModelAvailable(String model) async {
    // Check cache first
    final cachedTime = _workingModelsCache[model];
    if (cachedTime != null && DateTime.now().difference(cachedTime) < _cacheDuration) {
      dev.log('Using cached status for model: $model');
      return true;
    }

    try {
      dev.log('Checking availability of model: $model');
      final response = await _client.post(
        Uri.parse('$_baseUrl/models/$model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': 'test'
            }]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1,
          },
        }),
      ).timeout(_healthCheckTimeout);

      // Check for quota errors (429)
      if (response.statusCode == 429 || 
          response.body.contains('RESOURCE_EXHAUSTED') ||
          response.body.contains('quota')) {
        dev.log('Quota exceeded for model: $model');
        
        // For the most reliable models, we'll still consider them available
        // even if we hit quota limits, as they might work later
        if (model == 'gemini-1.0-pro' || model == 'gemini-1.0-pro-vision') {
          _workingModelsCache[model] = DateTime.now();
          return true;
        }
        
        return false;
      }

      final isAvailable = response.statusCode != 503;
      if (isAvailable) {
        _workingModelsCache[model] = DateTime.now();
      }
      return isAvailable;
    } catch (e) {
      // For quota errors in exceptions, still consider reliable models available
      if (e.toString().contains('429') || 
          e.toString().contains('RESOURCE_EXHAUSTED') ||
          e.toString().contains('quota')) {
        if (model == 'gemini-1.0-pro' || model == 'gemini-1.0-pro-vision') {
          _workingModelsCache[model] = DateTime.now();
          return true;
        }
      }
      return false;
    }
  }

  // Find the best available model
  Future<String?> _findBestAvailableModel(List<String> models) async {
    // Check all models in parallel
    final futures = models.map((model) async {
      final isAvailable = await _isModelAvailable(model);
      return isAvailable ? model : null;
    }).toList();

    // Wait for all checks to complete
    final results = await Future.wait(futures);
    return results.firstWhere((model) => model != null, orElse: () => null);
  }

  Future<LlmResponse> generateResponse({
    required String prompt,
    String modelName = 'gemini-pro',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    List<String> modelsToTry = [modelName];
    
    // Add fallback models if the initial model is a vision model
    if (modelName.contains('vision')) {
      modelsToTry.addAll(_fallbackVisionModels.where((m) => m != modelName));
    } else {
      modelsToTry.addAll(_fallbackModels.where((m) => m != modelName));
    }

    // Try to find the best available model first
    final bestModel = await _findBestAvailableModel(modelsToTry);
    if (bestModel != null) {
      modelsToTry.remove(bestModel);
      modelsToTry.insert(0, bestModel);
    }

    LlmResponse? lastError;
    
    for (final currentModel in modelsToTry) {
      // Skip models we know are unavailable
      if (!_workingModelsCache.containsKey(currentModel) && 
          bestModel != null && currentModel != bestModel) {
        continue;
      }

      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          dev.log('Attempting with model $currentModel (attempt ${attempt + 1})');
          final startTime = DateTime.now();

          final response = await _client.post(
            Uri.parse('$_baseUrl/models/$currentModel:generateContent?key=$_apiKey'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [{
                'parts': [{
                  'text': prompt
                }]
              }],
              'generationConfig': {
                'temperature': temperature,
                'maxOutputTokens': maxTokens,
              },
            }),
          ).timeout(_timeout);

          final endTime = DateTime.now();
          final totalDuration = endTime.difference(startTime).inMicroseconds / 1000000;

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
            final tokenMetrics = jsonResponse['usageMetadata'];

            // Cache successful model
            _workingModelsCache[currentModel] = DateTime.now();

            return LlmResponse(
              text: text,
              modelName: currentModel,
              totalDuration: totalDuration,
              promptEvalCount: tokenMetrics['promptTokenCount'],
              evalCount: tokenMetrics['candidatesTokenCount'],
              evalRate: tokenMetrics['totalTokenCount'] / totalDuration,
            );
          } else if (response.statusCode == 503) {
            dev.log('Model $currentModel overloaded (attempt ${attempt + 1})');
            // Remove from cache if model becomes unavailable
            _workingModelsCache.remove(currentModel);
            
            lastError = LlmResponse(
              text: '',
              isError: true,
              errorMessage: 'Model overloaded: ${response.body}',
            );
            await Future.delayed(Duration(seconds: attempt + 1));
            continue;
          } else {
            dev.log('Error from Gemini API: ${response.body}');
            final errorBody = jsonDecode(response.body);
            final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
            
            // Check if it's a model not found error
            if (response.statusCode == 404 && errorMessage.contains('not found')) {
              dev.log('Model not found error: $errorMessage');
              
              // Try to fetch available models
              try {
                final modelsResponse = await _client.get(
                  Uri.parse('$_baseUrl/models?key=$_apiKey'),
                  headers: {'Content-Type': 'application/json'},
                ).timeout(_healthCheckTimeout);
                
                if (modelsResponse.statusCode == 200) {
                  final modelsJson = jsonDecode(modelsResponse.body);
                  final availableModels = (modelsJson['models'] as List?)
                      ?.map((m) => m['name'] as String?)
                      ?.where((m) => m != null)
                      ?.map((m) => m!.split('/').last)
                      ?.toList() ?? [];
                  
                  dev.log('Available models: $availableModels');
                  
                  lastError = LlmResponse(
                    text: '',
                    isError: true,
                    errorMessage: 'Model "$currentModel" not found. Available models: ${availableModels.join(", ")}',
                  );
                } else {
                  lastError = LlmResponse(
                    text: '',
                    isError: true,
                    errorMessage: 'Model "$currentModel" not found. Failed to retrieve available models.',
                  );
                }
              } catch (e) {
                lastError = LlmResponse(
                  text: '',
                  isError: true,
                  errorMessage: 'Model "$currentModel" not found. Error retrieving available models: $e',
                );
              }
            } else {
              lastError = LlmResponse(
                text: '',
                isError: true,
                errorMessage: 'Failed to generate response: ${response.statusCode} - ${response.body}',
              );
            }
            break;
          }
        } catch (e) {
          dev.log('Error in Gemini generateResponse: $e');
          lastError = LlmResponse(
            text: '',
            isError: true,
            errorMessage: 'Error connecting to Gemini API: $e',
          );
          if (e is TimeoutException) {
            continue;
          }
          break;
        }
      }
    }

    return lastError ?? LlmResponse(
      text: '',
      isError: true,
      errorMessage: 'All models failed to generate response',
    );
  }

  Future<LlmResponse> generateResponseWithImage({
    required String prompt,
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String modelName = 'gemini-pro-vision',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    List<String> modelsToTry = [modelName, ..._fallbackVisionModels.where((m) => m != modelName)];
    LlmResponse? lastError;

    for (final currentModel in modelsToTry) {
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          dev.log('Attempting vision model $currentModel (attempt ${attempt + 1})');
          final startTime = DateTime.now();

          final base64Image = base64Encode(imageBytes);
          final response = await _client.post(
            Uri.parse('$_baseUrl/models/$currentModel:generateContent?key=$_apiKey'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [{
                'parts': [
                  {
                    'text': prompt,
                  },
                  {
                    'inline_data': {
                      'mime_type': mimeType,
                      'data': base64Image,
                    },
                  },
                ],
              }],
              'generationConfig': {
                'temperature': temperature,
                'maxOutputTokens': maxTokens,
              },
            }),
          ).timeout(_timeout);

          final endTime = DateTime.now();
          final totalDuration = endTime.difference(startTime).inMicroseconds / 1000000;

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
            final tokenMetrics = jsonResponse['usageMetadata'];

            return LlmResponse(
              text: text,
              modelName: currentModel,
              totalDuration: totalDuration,
              promptEvalCount: tokenMetrics['promptTokenCount'],
              evalCount: tokenMetrics['candidatesTokenCount'],
              evalRate: tokenMetrics['totalTokenCount'] / totalDuration,
            );
          } else if (response.statusCode == 503) {
            dev.log('Vision model $currentModel overloaded (attempt ${attempt + 1})');
            lastError = LlmResponse(
              text: '',
              isError: true,
              errorMessage: 'Model overloaded: ${response.body}',
            );
            await Future.delayed(Duration(seconds: attempt + 1));
            continue;
          } else {
            dev.log('Error from Gemini Vision API: ${response.body}');
            lastError = LlmResponse(
              text: '',
              isError: true,
              errorMessage: 'Failed to generate response: ${response.statusCode} - ${response.body}',
            );
            break;
          }
        } catch (e) {
          dev.log('Error in Gemini Vision generateResponse: $e');
          lastError = LlmResponse(
            text: '',
            isError: true,
            errorMessage: 'Error connecting to Gemini Vision API: $e',
          );
          if (e is TimeoutException) {
            continue;
          }
          break;
        }
      }
    }

    return lastError ?? LlmResponse(
      text: '',
      isError: true,
      errorMessage: 'All vision models failed to generate response',
    );
  }

  Future<LlmResponse> analyzeImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String prompt = 'Describe this image in detail.',
    String modelName = 'gemini-1.5-pro-vision-latest',
  }) async {
    return generateResponseWithImage(
      prompt: prompt,
      imageBytes: imageBytes,
      mimeType: mimeType,
      modelName: modelName,
    );
  }

  /// Analyzes a document (PDF or DOCX) and returns insights
  Future<LlmResponse> analyzeDocument({
    required File file,
    String customPrompt = '',
    String modelName = 'gemini-1.5-pro',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      if (!_documentService.isSupportedDocument(file.path)) {
        return LlmResponse(
          text: '',
          isError: true,
          errorMessage: 'Unsupported document type. Please provide a PDF or DOCX file.',
        );
      }

      // Extract text from document
      final text = await _documentService.extractText(file);
      
      // Split text into manageable chunks
      final chunks = _documentService.splitIntoChunks(text);
      
      // Create analysis prompt
      final prompt = customPrompt.isNotEmpty
          ? customPrompt
          : '''Analyze this document and provide key insights. Include:
             1. Main topics and themes
             2. Key points and findings
             3. Important details and data
             4. Recommendations or conclusions (if any)
             
             Document text:
             ${chunks.first}'''; // Using first chunk for initial analysis

      // Generate response
      return generateResponse(
        prompt: prompt,
        modelName: modelName,
        maxTokens: maxTokens,
        temperature: temperature,
      );
    } catch (e) {
      dev.log('Error analyzing document: $e');
      return LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Error analyzing document: $e',
      );
    }
  }

  /// Answers questions about a specific document
  Future<LlmResponse> askAboutDocument({
    required File file,
    required String question,
    String modelName = 'gemini-1.5-pro',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      if (!_documentService.isSupportedDocument(file.path)) {
        return LlmResponse(
          text: '',
          isError: true,
          errorMessage: 'Unsupported document type. Please provide a PDF or DOCX file.',
        );
      }

      // Extract text from document
      final text = await _documentService.extractText(file);
      
      // Split text into manageable chunks
      final chunks = _documentService.splitIntoChunks(text);
      
      // Create question prompt
      final prompt = '''Answer the following question about this document:
          
          Question: $question
          
          Document text:
          ${chunks.first}'''; // Using first chunk for initial answer

      // Generate response
      return generateResponse(
        prompt: prompt,
        modelName: modelName,
        maxTokens: maxTokens,
        temperature: temperature,
      );
    } catch (e) {
      dev.log('Error answering question about document: $e');
      return LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Error answering question about document: $e',
      );
    }
  }

  Future<List<String>> getAvailableModels() async {
    // First try to get models directly from the API
    try {
      dev.log('Fetching available models from API...');
      final response = await _client.get(
        Uri.parse('$_baseUrl/models?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_healthCheckTimeout);
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final apiModels = (jsonResponse['models'] as List?)
            ?.map((m) => m['name'] as String?)
            ?.where((m) => m != null)
            ?.map((m) => m!.split('/').last)
            ?.where((m) => m.startsWith('gemini-'))
            ?.toList() ?? [];
        
        if (apiModels.isNotEmpty) {
          dev.log('Models from API: $apiModels');
          
          // Filter to only include the most reliable models to avoid quota issues
          final reliableModels = _filterReliableModels(apiModels);
          if (reliableModels.isNotEmpty) {
            dev.log('Reliable models: $reliableModels');
            return reliableModels;
          }
          
          return apiModels;
        }
      } else if (response.statusCode == 429 || 
                 response.body.contains('RESOURCE_EXHAUSTED') ||
                 response.body.contains('quota')) {
        // Handle quota exceeded error
        dev.log('API quota exceeded when fetching models');
        // Return only the most reliable models when quota is exceeded
        return _getMostReliableModels();
      }
    } catch (e) {
      dev.log('Error fetching models from API: $e');
      // If error contains quota information, return reliable models
      if (e.toString().contains('429') || 
          e.toString().contains('RESOURCE_EXHAUSTED') ||
          e.toString().contains('quota')) {
        return _getMostReliableModels();
      }
    }
    
    // Fallback to hardcoded models if API call fails
    final allModels = [
      // Pro models for text generation
      'gemini-pro',
      'gemini-1.0-pro',
      'gemini-1.5-pro',
      'gemini-1.5-pro-latest',
      
      // Vision models for image analysis
      'gemini-pro-vision',
      'gemini-1.0-pro-vision',
      'gemini-1.5-pro-vision',
      'gemini-1.5-pro-vision-latest',
    ];
    
    // Check cache first for all models
    final cachedAvailableModels = allModels.where(
      (model) => _workingModelsCache.containsKey(model) && 
                 DateTime.now().difference(_workingModelsCache[model]!) < _cacheDuration
    ).toList();
    
    // If we have cached models, return them immediately
    if (cachedAvailableModels.isNotEmpty) {
      dev.log('Using cached available models: $cachedAvailableModels');
      return cachedAvailableModels;
    }
    
    // Otherwise check availability of all models in parallel
    dev.log('Checking availability of all models...');
    final futures = allModels.map((model) async {
      final isAvailable = await _isModelAvailable(model);
      return isAvailable ? model : null;
    }).toList();
    
    final results = await Future.wait(futures);
    final availableModels = results.whereType<String>().toList();
    
    // If no models are available, return at least the basic ones
    // (they might be temporarily unavailable but we still want to show them)
    if (availableModels.isEmpty) {
      dev.log('No models available, returning most reliable models');
      return _getMostReliableModels();
    }
    
    dev.log('Available models: $availableModels');
    return availableModels;
  }
  
  // Helper method to filter models to only include the most reliable ones
  List<String> _filterReliableModels(List<String> allModels) {
    // These are the models that are most likely to be available and not hit quota limits
    final reliableModelPrefixes = [
      'gemini-1.0-pro',
      'gemini-1.0-pro-vision',
    ];
    
    // Filter the available models to only include the reliable ones
    return allModels.where((model) => 
      reliableModelPrefixes.any((prefix) => model.startsWith(prefix))).toList();
  }
  
  // Return a minimal set of reliable models when quota is exceeded
  List<String> _getMostReliableModels() {
    return [
      'gemini-1.0-pro',
      'gemini-1.0-pro-vision',
    ];
  }

  void dispose() {
    _client.close();
  }
} 