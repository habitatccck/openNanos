# openNanos Platform

Cross-platform containers and UI for OpenClaw gateway.

## Repository Structure

```
opennanos-platform/
├── containers/       # Platform-specific containers
│   └── macos/       # macOS Swift application
├── ui/              # Shared React/Vite UI
├── shared/          # Shared utilities
├── docs/            # Documentation
└── scripts/         # Build and deployment scripts
```

## Development

### Prerequisites

- Node.js 22+
- pnpm
- Xcode (for macOS container)
- OpenClaw gateway running at `ws://127.0.0.1:18789`

### Setup

```bash
# Install dependencies
pnpm install

# Run UI dev server
pnpm dev

# Build macOS container
pnpm build:macos
```

## Related Repositories

- [openclaw-mind](../openclaw-mind) - OpenClaw gateway (fork for syncing with upstream)

## Architecture

The platform connects to OpenClaw gateway via WebSocket protocol (version 3):

1. **UI Layer**: React/Vite web application
2. **Container Layer**: Native applications (macOS, Windows)
3. **Bridge Layer**: WebView ↔ Native bridge for communication
4. **Gateway**: OpenClaw WebSocket gateway (openclaw-mind)

## License

MIT
