# PySide Browser App

A native desktop browser application built with PySide6 + QtWebEngine featuring a sidebar chat interface and built-in web analysis tools.

## Features

- **Modern Browser Interface**: Full-featured browser with navigation controls, address bar, and tab management
- **AI Chat Sidebar**: Integrated chat interface with LLM support for page analysis and Q&A
- **Web Analysis Tools**: Built-in tools for analytics, usability, and accessibility auditing
- **Page Extraction**: Automatic extraction of page metadata, content, and design tokens
- **Persistent Storage**: SQLite database for chat history and analysis results
- **Cross-Platform**: Works on Windows, macOS, and Linux

## Architecture

```
app/
├── main.py                 # Application entry point
├── ui/                     # User interface components
│   ├── main_window.py      # Main window layout
│   └── widgets/            # UI widgets
│       ├── header.py       # Toolbar with navigation
│       ├── footer.py       # Status bar
│       ├── sidebar.py      # Chat sidebar
│       ├── features_modal.py # Features grid
│       ├── tools_menu.py   # Tools dropdown
│       ├── chat_panel.py   # Chat interface
│       └── settings_dialog.py # Settings dialog
├── core/                   # Core functionality
│   ├── config.py          # Configuration management
│   ├── state.py           # Application state
│   └── llm.py             # LLM client
├── browser/               # Browser components
│   └── view.py            # WebEngine wrapper
└── tools/                 # Analysis tools
    ├── runner.py          # Tool execution
    ├── analytics.py       # Analytics audit
    ├── usability.py       # Usability audit
    └── accessibility.py   # Accessibility audit
```

## Installation

### Prerequisites

- Python 3.11+
- pip
- Git

### Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd pyside-browser
   ```

2. **Install dependencies**:
   ```bash
   python build.py install
   ```

3. **Run the application**:
   ```bash
   python app/main.py
   ```

### Building Executable

To create a standalone executable:

```bash
python build.py
```

This will create `dist/pyside-browser` (or `dist/pyside-browser.exe` on Windows).

## Usage

### Basic Navigation

- **Address Bar**: Enter URLs or search queries
- **Navigation**: Use Back, Forward, Refresh, and Home buttons
- **Menu**: Click the menu button to access features grid

### Chat Interface

- **New Thread**: Click "+ New Thread" to start a new conversation
- **Model Selection**: Choose your preferred LLM model
- **Page Context**: The chat automatically includes current page data
- **Tool Results**: Analysis results are automatically added to chat

### Analysis Tools

Access tools via the "Tools" button in the header:

- **Analytics Audit**: Detects Google Analytics, GTM, Facebook Pixel, and other tracking tools
- **Usability Audit**: Checks heading structure, image alt text, form labels, and touch targets
- **Accessibility Audit**: Analyzes ARIA usage, keyboard navigation, and WCAG compliance

### Settings

Click the settings icon in the sidebar to configure:

- **LLM Configuration**: API base URL, API key, and model selection
- **General Settings**: Home URL and other preferences

## Configuration

The app stores configuration in `~/.pyside-browser/config.json`:

```json
{
  "llm_base": "https://api.openai.com/v1",
  "llm_key": "your-api-key",
  "models": ["gpt-3.5-turbo", "gpt-4"],
  "default_model": "gpt-3.5-turbo",
  "home_url": "https://example.com"
}
```

## Development

### Running Tests

```bash
pytest tests/
```

### Code Formatting

```bash
ruff check --fix .
```

### Project Structure

- **UI Components**: PySide6 widgets with proper signal/slot connections
- **State Management**: Centralized state with SQLite persistence
- **Tool Execution**: Asynchronous Playwright-based analysis tools
- **LLM Integration**: Streaming chat with configurable models

## Dependencies

- **PySide6**: Qt6 bindings for Python
- **Playwright**: Browser automation for analysis tools
- **httpx**: HTTP client for LLM API calls
- **SQLModel**: Database ORM for data persistence
- **PyInstaller**: Application packaging

## Troubleshooting

### Common Issues

1. **Playwright Installation**: Make sure to run `playwright install chromium`
2. **QtWebEngine**: Ensure PySide6 is properly installed
3. **API Keys**: Configure your LLM API key in settings
4. **Permissions**: On Linux, you may need to install additional Qt dependencies

### Platform-Specific Notes

- **Windows**: Uses Edge WebView2
- **macOS**: Uses WKWebView
- **Linux**: Uses WebKitGTK

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Roadmap

- [ ] Tab management
- [ ] Bookmark system
- [ ] Custom CSS injection
- [ ] Plugin system
- [ ] Advanced page extraction
- [ ] Export analysis reports
- [ ] Team collaboration features
