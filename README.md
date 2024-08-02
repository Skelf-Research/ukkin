# Ukkin : AI-Powered Browser

An innovative web browser with integrated AI assistance, built using Flutter and Dart.

## Features

- **AI-Powered Chat**: Interact with an AI assistant that understands your browsing context.
- **Offline AI Capabilities**: Utilizes on-device LLM for privacy and offline usage.
- **Intelligent Search**: Combines results from open tabs and web searches for context-aware answers.
- **Privacy-Focused**: Keeps user data on the device with no tracking or ads.
- **Multi-Tab Browsing**: Supports multiple tabs with a visual tab manager.
- **Low Data Mode**: Option to reduce data usage while browsing.
- **Incognito Mode**: Private browsing option available.

## Components

1. **BrowserHome**: Main interface for web browsing with tab management.
2. **AIChatWindow**: Interface for interacting with the AI assistant.
3. **ModelDownloadService**: Handles downloading and managing the AI model.
4. **LLMService**: Manages the on-device language model for AI interactions.
5. **WebViewModel**: Represents individual browser tabs.

## Setup

1. Ensure you have Flutter installed on your development machine.
2. Clone this repository:
   ```
   git clone https://github.com/yourusername/ai-powered-browser.git
   ```
3. Navigate to the project directory:
   ```
   cd ai-powered-browser
   ```
4. Install dependencies:
   ```
   flutter pub get
   ```
5. Run the app:
   ```
   flutter run
   ```

## Model Download

The app will automatically download the required AI model on first run. Ensure you have a stable internet connection for the initial setup.

## Dependencies

- flutter: ^2.10.0
- webview_flutter: ^4.0.0
- fllama: ^0.1.0
- sqflite: ^2.0.0
- path_provider: ^2.0.0
- http: ^0.13.0

## Configuration

- Update the `_searxngInstance` URL in `ai_chat_window.dart` to your preferred SearXNG instance.
- Modify model URLs in `model_download_service.dart` if you want to use different AI models.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to the Flutter team for the excellent framework.
- The fllama package for enabling on-device LLM capabilities.
- SearXNG for providing a privacy-focused search API.
