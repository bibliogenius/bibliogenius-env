# BiblioGenius Ecosystem

A decentralized, cross-platform library management system.

🌐 **Website:** [bibliogenius.org](https://bibliogenius.org)

## ✨ Features

- **📚 Catalog Management**: Add books via ISBN scan (OpenLibrary/Goodreads), manage copies, and track loans.
- **🤝 P2P Sharing**: Connect directly with friends' libraries via QR code to borrow books.
- **🔐 End-to-End Encryption**: Share your library globally via encrypted relay — the server never sees your data.
- **🤖 MCP Integration**: "Speak with your library" using local AI agents via Model Context Protocol.
- **🏆 Gamification**: Earn reputation ("Lender", "Archivist") and level up your librarian status.
- **🛡️ Backup & Export**: Full JSON export of your library data for safekeeping.
- **🚀 Cross-Platform**: Native performance on iOS, Android, macOS, Windows, and Linux.
- **🔒 Digital Sovereignty**: Local-First architecture. You own your data. No central server required.

> 🇪🇺 **Proudly supported by [NLnet](https://nlnet.nl/)** through the NGI Zero Commons Fund.

## 📦 Components

This is a **monorepo** containing all BiblioGenius components. Each folder will be mapped to its own git repository:

### [`bibliogenius/`](./bibliogenius)

**Rust Server** - Autonomous library server with REST API  
🔗 Repository: <https://github.com/bibliogenius/bibliogenius>

### [`bibliogenius-app/`](./bibliogenius-app)

**Flutter Apps** - Mobile and desktop applications  
🔗 Repository: <https://github.com/bibliogenius/bibliogenius-app>

### [`bibliogenius-hub/`](./bibliogenius-hub)

**Symfony Hub** - Optional central directory service  
🔗 Repository: <https://github.com/bibliogenius/bibliogenius-hub>

### [`bibliogenius-bundle/`](./bibliogenius-bundle)

**Symfony Bundle** - Complete PHP-only alternative  
🔗 Repository: <https://github.com/bibliogenius/bibliogenius-bundle>

### [`bibliogenius-docker/`](./bibliogenius-docker)

**Docker Environment** - Development setup with Docker Compose  
🔗 Repository: <https://github.com/bibliogenius/bibliogenius-docker>

## 📚 Documentation

- [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) - Complete ecosystem architecture
- [`docs/REPOSITORIES.md`](./docs/REPOSITORIES.md) - Repository structure and naming
- [`docs/POC_ROADMAP.md`](./docs/POC_ROADMAP.md) - Proof of concept implementation plan
- [`ROADMAP.md`](./ROADMAP.md) - Original project roadmap

## 🚀 Quick Start

### For Users

Download the BiblioGenius app for your platform:
<https://github.com/bibliogenius/bibliogenius-app/releases>

The Rust backend is **embedded in the app** — no separate server installation needed!

### For Developers

```bash
# Clone the environment repo
git clone https://github.com/bibliogenius/bibliogenius-env.git
cd bibliogenius-env

# Setup for your profile (no-code / junior / senior)
python3 setup.py junior

# Then follow the on-screen instructions
```

> **Note**: The setup script clones the right repos, configures your AI tools (Claude Code / Cursor), and guides you through the next steps.

See [NO_CODE_ONBOARDING.md](./bibliogenius-docs/docs/project-management/NO_CODE_ONBOARDING.md) for the non-technical contributor guide.

## 🏗️ Architecture

```mermaid
┌──────────────────────────────┐
│   E2EE Relay Hub (Blind)      │
│   - Encrypted blob storage    │
│   - Anonymous mailboxes       │
│   - Zero-Knowledge            │
└──────────────┬────────────────┘
               │
               │ (Encrypted blobs only)
               │
    ┌──────────┴──────────┐
    │                     │
    ▼                     ▼
┌─────────┐           ┌─────────┐
│ Rust    │ ◄── P2P ──│ Rust    │
│ Server  │  (mDNS)   │ Server  │
└────┬────┘           └────┬────┘
     │                     │
     │ REST API            │ REST API
     │                     │
     ▼                     ▼
┌─────────┐           ┌─────────┐
│ Flutter │           │ Flutter │
│ App     │           │ App     │
└─────────┘           └─────────┘
```

## 🤝 Contributing

Each component has its own repository. Please contribute to the appropriate repo:

- Rust server issues/PRs → `bibliogenius`
- Flutter app issues/PRs → `bibliogenius-app`
- Symfony hub issues/PRs → `bibliogenius-hub`
- Symfony bundle issues/PRs → `bibliogenius-bundle`
- Docker setup issues/PRs → `bibliogenius-docker`

## 📄 License

MIT License - see LICENSE file in each repository

## 👤 Author

**Federico CALO**

- Website: <https://federico-calo.net>
- GitHub: [@federico-calo](https://github.com/federico-calo)
- Organization: [@bibliogenius](https://github.com/bibliogenius)

---

**Status**: In Development (Pre-release)
**Last Updated**: 2026-02-16
