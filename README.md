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

This is the **environment repo** that orchestrates all BiblioGenius components. Run `python3 setup.py <profile>` to clone what you need.

### [`bibliogenius/`](./bibliogenius)

**Rust Server** - Autonomous library server with REST API  
🔗 Repository: <https://github.com/bibliogenius/bibliogenius>

### [`bibliogenius-app/`](./bibliogenius-app)

**Flutter Apps** - Mobile and desktop applications  
🔗 Repository: <https://github.com/bibliogenius/bibliogenius-app>

### [`bibliogenius-hub/`](./bibliogenius-hub)

**Symfony Hub** - Optional central directory service  
🔗 Repository: <https://github.com/bibliogenius/bibliogenius-hub>

## 📚 Documentation

- [NO_CODE_ONBOARDING.md](./docs/NO_CODE_ONBOARDING.md) - Guide for non-technical contributors
- [CONFLUENCE_STRUCTURE.md](./docs/CONFLUENCE_STRUCTURE.md) - Confluence space organization
- [CLAUDE.md](./CLAUDE.md) - Architecture rules and AI assistant guidelines

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
make setup P=junior

# Then follow the on-screen instructions
```

> **Note**: The setup script clones the right repos, configures your AI tools (Claude Code / Cursor), and guides you through the next steps.
>
> Alternative: `python3 setup.py junior`

See [NO_CODE_ONBOARDING.md](./docs/NO_CODE_ONBOARDING.md) for the non-technical contributor guide.

## 🏗️ Architecture

```mermaid
graph TD
    Hub["E2EE Relay Hub (Blind)<br/>Encrypted blob storage<br/>Anonymous mailboxes<br/>Zero-Knowledge"]

    Hub -- "Encrypted blobs only" --> RustA
    Hub -- "Encrypted blobs only" --> RustB

    RustA["Rust Server A"] -- "P2P (mDNS)" --> RustB["Rust Server B"]
    RustB -- "P2P (mDNS)" --> RustA

    RustA -- "FFI" --> FlutterA["Flutter App A"]
    RustB -- "FFI" --> FlutterB["Flutter App B"]
```

## 🤝 Contributing

Each component has its own repository. Please contribute to the appropriate repo:

- Rust server issues/PRs → [`bibliogenius`](https://github.com/bibliogenius/bibliogenius)
- Flutter app issues/PRs → [`bibliogenius-app`](https://github.com/bibliogenius/bibliogenius-app)
- Symfony hub issues/PRs → [`bibliogenius-hub`](https://github.com/bibliogenius/bibliogenius-hub)
- Environment / onboarding → [`bibliogenius-env`](https://github.com/bibliogenius/bibliogenius-env) (this repo)

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
