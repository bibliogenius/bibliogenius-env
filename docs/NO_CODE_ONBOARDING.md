# Welcome to BiblioGenius — No-Code Contributor Guide

## The project in 2 minutes

BiblioGenius is a personal library management app.
It lets you catalog your books, share them with contacts,
and discover new titles through open sources (Inventaire, OpenLibrary).

**Technical stack** (no need to understand it all):
- **The interface** (what the user sees): Flutter (Dart language)
- **The engine** (business logic): Rust
- **The database**: SQLite (a local file)
- The interface calls the engine directly via FFI (Foreign Function Interface — a bridge that lets Flutter talk to Rust without going through a web server)

**Current version**: v0.8.x (alpha)

**What already works**: book scanning (ISBN, cover), personal catalog,
multi-source search, gamification, local network exchanges between contacts,
end-to-end encryption (E2EE).

---

## Your toolbox

| Tool | Usage | Link |
|------|-------|------|
| **Confluence** | Product docs, QA, business | *(link TBD)* |
| **GitHub** | Source code and issues | *(link TBD)* |
| **Claude Code** | AI assistant for code contributions | Terminal: `claude` |
| **Cursor** | Code editor with built-in AI | VS Code alternative |

---

## Finding your way in Confluence

> See `CONFLUENCE_STRUCTURE.md` for the detailed structure.

| Space | What you'll find |
|-------|-----------------|
| **Product** | Roadmap, feature list, high-level architecture, modules |
| **Quality** | Functional test checklists, beta tester guide, bug reports |
| **Business** | Competitive analysis, pitch, partnerships, funding, marketing |
| **Contribute** | How to make your first code changes (this guide!) |

The **Archive** space contains detailed technical documentation (crypto, Rust architecture, P2P research...).
You don't need it day-to-day — it's hidden by default.

---

## Your first missions

By increasing difficulty:

### 1. Fix a translation (FR/EN)

**Difficulty**: easy

**Files involved**: `bibliogenius-app/assets/i18n/*.po`

`.po` files contain the interface translations.
Each entry has a `msgid` (the key) and a `msgstr` (the translation).

Example — fixing a typo in the French translation:
```
msgid "search_placeholder"
msgstr "Rechercher un livre..."
```

**How to do it**:
1. Open the `.po` file for the relevant language
2. Find the `msgid` to fix
3. Edit the `msgstr`
4. Run `/contrib-check` to verify

---

### 2. Add a curated book list

**Difficulty**: easy

**Files involved**: `bibliogenius-app/assets/curated_lists/**/*.yml`

Curated lists are thematic book selections (e.g., "French Classics",
"Must-read Sci-Fi").

Example format:
```yaml
- title: "Le Petit Prince"
  author: "Antoine de Saint-Exupery"
  isbn: "9782070612758"
```

**How to do it**:
1. Create a new `.yml` file in the appropriate thematic folder
2. Add books with title, author, and ISBN
3. Run `/contrib-check` to verify syntax

---

### 3. Change a theme color

**Difficulty**: medium

**Files involved**: `bibliogenius-app/lib/themes/` or `lib/theme/app_design.dart`

The theme defines the app's colors, fonts, and spacing.
You can modify numeric values (hex colors, pixel sizes).

Example:
```dart
static const primaryColor = Color(0xFF1A73E8);  // Google Blue
```

**How to do it**:
1. Find the color to change in `app_design.dart`
2. Edit the hex value
3. Run `flutter analyze` to check for errors

---

### 4. Update text on a simple screen

**Difficulty**: medium

**Files involved**: `help_screen.dart`, `feedback_screen.dart`, `splash_screen.dart`

These screens contain static text you can modify.
Important: text must use the translation system (no hardcoded strings).

**How to do it**:
1. Add the new translation key in the `.po` files
2. Use `TranslationService.translate(context, 'your_key')` in the Dart code
3. Run `/contrib-check`

---

### 5. Add a simple widget

**Difficulty**: advanced (review required)

**Files involved**: `bibliogenius-app/lib/widgets/` (files < 300 lines)

For this mission, work with Claude Code which will guide you step by step.
The PR will be reviewed by a developer before merging.

---

## Setup — one command

### Prerequisites

Install these tools before starting:

| Tool | Installation | Verification |
|------|-------------|--------------|
| **Git** | Mac: `xcode-select --install` / Windows: https://git-scm.com | `git --version` |
| **Flutter** | https://docs.flutter.dev/get-started/install | `flutter doctor` |
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` | `claude --version` |

### Installation

```bash
# 1. Clone the environment repo
git clone https://codeberg.org/bibliogenius/bibliogenius-env.git
cd bibliogenius-env

# 2. Run the setup (one command!)
make setup P=no-code
```

That's it. The script will:
- Check your prerequisites (git, flutter)
- Clone the repos you need (bibliogenius-app, bibliogenius-docs)
- Activate the protection hook that prevents modifying forbidden files
- Display next steps

> Alternative: `python3 setup.py no-code`

> **Switching profile**: If you later need more access (e.g., junior or senior),
> just re-run `make setup P=junior`. It will clone the missing repos and adjust
> your AI tool configuration automatically.

### After setup

```bash
# 3. Launch Claude Code
claude

# 4. Run the onboarding (configures your AI tool)
/onboard no-code
```

### Run the app (debug mode)

```bash
cd bibliogenius-app
flutter run
```

> Note: the Rust backend compiles automatically via FFI.
> You don't need to install Rust for simple front-end changes.
> If `flutter run` fails on Rust compilation, ask a developer for help.

---

## PR workflow

### Step by step

```
1. Create a branch
   git checkout -b contrib/my-change

2. Make the change
   - With Claude Code: describe what you want to change
   - With Cursor: edit the file directly

3. Verify
   /contrib-check

4. Save locally
   git add <modified-files>
   git commit -m "contrib: short description of the change"

5. Push to GitHub
   git push -u origin contrib/my-change

6. Create the Pull Request
   - Go to GitHub, click "Compare & pull request"
   - Describe what you changed and why
   - Wait for a developer review

7. After the review
   - If changes are requested: make them on the same branch
   - When approved: the developer will merge for you
```

### Naming conventions

- Branches: `contrib/short-description` (e.g., `contrib/fix-homepage-translation`)
- Commits: `contrib: short description` (e.g., `contrib: fix help screen typo`)
- PR title: descriptive (e.g., "Fix homepage translation")

### Checklist before submitting your PR

- [ ] `/contrib-check` returns OK (no errors)
- [ ] Only "safe zone" files are modified
- [ ] I tested the app locally (`flutter run`) and it works
- [ ] My PR description explains what I changed and why

---

## Safe zones vs forbidden zones

### You CAN modify

| Zone | Path | Examples |
|------|------|----------|
| Translations | `assets/i18n/*.po` | Fix a translation, add a language |
| Curated lists | `assets/curated_lists/**/*.yml` | Add a book selection |
| Themes | `lib/themes/` | Change a color, spacing |
| Design tokens | `lib/theme/app_design.dart` | Numeric values and colors only |
| Simple screens | `help_screen.dart`, `feedback_screen.dart`, `splash_screen.dart` | Text, basic layout |
| Simple widgets | `lib/widgets/` (< 300 lines) | With Claude Code guidance |
| Images | `assets/images/` | Replace a logo, illustration |

### You MUST NOT modify

| Zone | Reason |
|------|--------|
| All Rust code (`bibliogenius/`) | Technical backend, risk of breaking the engine |
| `lib/models/` | Interface contract with Rust |
| `lib/services/` | Flutter business logic |
| `lib/providers/` | State management |
| `lib/data/` | Data access |
| `lib/src/rust/` | Auto-generated code (FFI) |
| `lib/config/`, `lib/utils/` | Internal configuration |
| `pubspec.yaml`, `Cargo.toml` | Project dependencies |
| CI files, migrations | Infrastructure |
| `.claude/hooks/` | Security guards |

> If the no-code hook is active, Claude Code will automatically refuse
> any modification outside safe zones.

---

## Quick glossary

| Term | Simple explanation |
|------|-------------------|
| **Flutter** | Framework for building the interface (screens, buttons, etc.) |
| **Dart** | Programming language used by Flutter |
| **Rust** | Programming language for the engine (backend) |
| **FFI** | Bridge between Flutter and Rust (they "talk" directly) |
| **PR (Pull Request)** | Request to integrate your changes into the main code |
| **Branch** | Isolated working copy of the code (so you don't break the main one) |
| **Merge** | Integrate a branch into the main code |
| **Review** | Code review by a developer before merging |
| **`.po`** | Standard file format for translations |
| **`.yml`** | Structured file format (lists, configurations) |
| **`flutter analyze`** | Tool that checks for errors in Flutter code |
| **Hook** | Automatic script triggered by certain actions |
| **E2EE** | End-to-end encryption (security for exchanges between users) |
| **SeaORM** | Rust tool for database access (you don't touch this) |
