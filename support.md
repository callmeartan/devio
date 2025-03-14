Welcome to Devio Support. This page provides resources to help you get the most out of Devio, your AI-powered development assistant.

## Contact Us

For support inquiries, please contact us through one of the following channels:

- **Email**: artanahmadi@icloud.com
- **GitHub Issues**: [Report a bug](https://github.com/callmeartan/devio/issues/new?template=bug_report.md)

We aim to respond to all inquiries within 1-2 business days.

## Frequently Asked Questions

### General Questions

**Q: What is Devio?**  
A: Devio is an AI-powered development assistant that connects to both local LLMs running on your system and cloud AI services to help you code more efficiently.

**Q: Which platforms does Devio support?**  
A: Devio is currently available for iOS. Android and desktop versions are planned for future releases.

**Q: Is an internet connection required?**  
A: Not necessarily. When using local LLMs, Devio can function offline. However, cloud AI features and certain app functionalities require an internet connection.

### Local LLM Integration

**Q: Which local LLMs are supported?**  
A: Devio supports integration with most popular local LLM implementations, including llama.cpp, Ollama, LocalAI, and others that expose an API endpoint.

**Q: How do I connect Devio to my local LLM?**  
A: Navigate to Settings > AI Providers > Local LLM, then enter the API endpoint URL of your running local LLM server.

**Q: What are the minimum system requirements for local LLM integration?**  
A: Your device should be on the same network as the machine running the LLM. The specific hardware requirements depend on the LLM you're running locally.

## Comprehensive Guide to Connecting Devio with Ollama

Devio is designed to work seamlessly with Ollama, allowing you to leverage powerful AI models locally. This guide will walk you through the setup process on different operating systems.

### 1. Installing Ollama

#### macOS
1. Visit [ollama.ai](https://ollama.ai) and download the macOS installer
2. Open the downloaded file and follow the installation instructions
3. Once installed, Ollama will be available in your Applications folder and as a menu bar item

#### Windows
1. Visit [ollama.ai](https://ollama.ai) and download the Windows installer
2. Run the installer and follow the on-screen instructions
3. After installation, Ollama will be available in your Start menu

#### Linux
1. Open a terminal and run the following command:
   ```bash
   curl -fsSL https://ollama.ai/install.sh | sh
   ```
2. Follow any additional prompts to complete the installation

### 2. Starting Ollama Server

For Devio to connect to Ollama, you need to start the Ollama server with the correct network configuration.

#### macOS
1. Open Terminal
2. Run the following command to make Ollama accessible on your network:
   ```bash
   OLLAMA_HOST=0.0.0.0:11434 ollama serve
   ```
3. Keep this terminal window open while using Devio

#### Windows
1. Open Command Prompt or PowerShell as Administrator
2. Run the following command:
   ```
   set OLLAMA_HOST=0.0.0.0:11434 && ollama serve
   ```
3. Keep this window open while using Devio

#### Linux
1. Open a terminal
2. Run the following command:
   ```bash
   OLLAMA_HOST=0.0.0.0:11434 ollama serve
   ```
3. Keep this terminal window open while using Devio

### 3. Finding Your Computer's IP Address

You'll need your computer's local IP address to connect Devio to Ollama.

#### macOS
1. Open Terminal
2. Run the following command:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
3. Look for an IP address that starts with `192.168.` or `10.` (e.g., `192.168.1.5`)

#### Windows
1. Open Command Prompt
2. Run the following command:
   ```
   ipconfig
   ```
3. Look for the "IPv4 Address" under your active network adapter (usually starts with `192.168.` or `10.`)

#### Linux
1. Open a terminal
2. Run the following command:
   ```bash
   ip addr show | grep "inet " | grep -v 127.0.0.1
   ```
3. Look for an IP address that starts with `192.168.` or `10.`

### 4. Downloading AI Models

Before using Ollama with Devio, you need to download at least one AI model.

1. Open a new terminal or command prompt window (keep the Ollama server running in the original window)
2. Run one of the following commands to download a model:
   ```bash
   # For a smaller, faster model
   ollama pull mistral
   
   # For a more powerful model
   ollama pull llama3
   
   # For a model with image capabilities
   ollama pull llava
   ```
3. Wait for the download to complete (this may take several minutes depending on your internet speed)

### 5. Connecting Devio to Ollama

1. Open the Devio app on your iOS device
2. Tap on the settings icon or navigate to the AI Assistant screen
3. Look for the Ollama connection settings (gear icon in the AI chat interface)
4. Enter your computer's IP address followed by `:11434` (e.g., `192.168.1.5:11434`)
5. Tap "Test Connection"
6. If successful, you'll see a confirmation message: "Connected to Ollama v[version]"
7. Save the connection settings

### 6. Using Ollama with Devio

1. Once connected, you'll see a list of available models in the model selector
2. Select your preferred model
3. Start chatting with your locally hosted AI!

### Troubleshooting Connection Issues

If you're having trouble connecting Devio to Ollama, try these solutions:

1. **Connection Refused Error**
   - Ensure Ollama server is running with `OLLAMA_HOST=0.0.0.0:11434`
   - Check that both devices are on the same network
   - Verify no firewall is blocking port 11434

2. **Models Not Showing**
   - Make sure you've downloaded at least one model using `ollama pull [model_name]`
   - Restart the Ollama server and reconnect from Devio

3. **Slow Responses**
   - Some models require significant computational resources
   - Try using a smaller model like `mistral` or `phi3:mini`
   - Adjust the context size in advanced settings to a smaller value

4. **Network Restrictions**
   - Some networks (especially public Wi-Fi) may block the required ports
   - Try using a personal hotspot or home network instead

5. **Verify Ollama is Running Properly**
   - In a browser on your computer, visit `http://localhost:11434/api/version`
   - You should see a JSON response with version information

For additional assistance, please contact our support team.

### Account & Billing

**Q: Do I need an account to use Devio?**  
A: Basic functionality is available without an account. Creating an account allows you to sync settings across devices and access premium features.

**Q: What's included in the free version vs. premium?**  
A: The free version includes basic coding assistance with limited requests. Premium unlocks unlimited requests, priority support, and advanced features.

**Q: How do I cancel my subscription?**  
A: Subscriptions can be managed through your App Store account settings.

## Troubleshooting

### Connection Issues

**Issue: Can't connect to local LLM**  
- Ensure your LLM server is running
- Verify both devices are on the same network
- Check that you've entered the correct API endpoint URL
- Confirm your firewall allows the connection

**Issue: Cloud AI service not responding**  
- Check your internet connection
- Verify your API key is valid and has remaining credits
- Ensure the service is operational by checking their status page

## Feature Requests

We're constantly improving Devio based on user feedback. To submit a feature request:

1. Check our [public roadmap](https://github.com/username/devio/roadmap) to see if it's already planned
2. Submit new ideas through our [feature request form](https://github.com/username/devio/issues/new?template=feature_request.md)
3. Vote on existing feature requests to help us prioritize

## Updates & Release Notes

Visit our [Releases page](https://github.com/username/devio/releases) for detailed information about each update, including new features, improvements, and bug fixes.

## Privacy & Data Security

For information about how we handle your data, please refer to our [Privacy Policy](https://github.com/callmeartan/devio/privacy-policy).

---
