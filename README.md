# MarkdownViewer

A lightweight macOS markdown viewer built with SwiftUI and [MarkdownKit](https://github.com/AnYuan/MarkdownKit).

## Features

- Open `.md` files via **Cmd+O** or **drag & drop**
- Live reload — file changes are reflected automatically
- Native rendering with full CommonMark + GFM support (tables, task lists, code blocks, math, diagrams)
- Minimal, distraction-free UI

## Requirements

- macOS 26.0+
- Swift 6.2+

## Build & Run

```bash
swift build
swift run MarkdownViewer
```

## Install As macOS App

Build a release `.app` bundle and install it to `~/Applications`:

```bash
./scripts/install-app.sh
```

The installer also regenerates the app icon before packaging.

Install to a different directory:

```bash
./scripts/install-app.sh /Applications
```

## Dependencies

- [MarkdownKit](https://github.com/AnYuan/MarkdownKit) — Native markdown rendering engine for Apple platforms
