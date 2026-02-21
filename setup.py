#!/usr/bin/env python3
"""
BiblioGenius — Setup script for new contributors.

Usage:
    python setup.py <profile>

Profiles:
    no-code   — PO, PM, designer (translations, themes, curated lists only)
    junior    — Developer with guardrails (full codebase, guided workflow)
    senior    — Experienced developer (full access, all repos)

What this script does:
    1. Checks prerequisites (git, flutter, rust...)
    2. Clones the repos you need (based on your profile)
    3. Sets up Claude Code / Cursor config for your profile
    4. Prints next steps
"""

import os
import platform
import shutil
import subprocess
import sys
import json
from pathlib import Path

# ─── Configuration ───

GITHUB_ORG = "https://github.com/bibliogenius"

# Repos needed per profile
REPOS_BY_PROFILE = {
    "no-code": [
        "bibliogenius-app",
        "bibliogenius-docs",
    ],
    "junior": [
        "bibliogenius",
        "bibliogenius-app",
        "bibliogenius-docs",
    ],
    "senior": [
        "bibliogenius",
        "bibliogenius-app",
        "bibliogenius-docs",
        "bibliogenius-hub",
        "bibliogenius-docker",
    ],
}

# Prerequisites per profile
PREREQS_BY_PROFILE = {
    "no-code": ["git", "flutter"],
    "junior": ["git", "flutter", "cargo"],
    "senior": ["git", "flutter", "cargo", "docker"],
}

PROFILES = list(REPOS_BY_PROFILE.keys())

# ─── Helpers ───

RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
BOLD = "\033[1m"
RESET = "\033[0m"

# Disable colors on Windows cmd (unless Windows Terminal / WT)
if platform.system() == "Windows" and "WT_SESSION" not in os.environ:
    RED = GREEN = YELLOW = CYAN = BOLD = RESET = ""


def info(msg):
    print(f"{CYAN}> {msg}{RESET}")


def success(msg):
    print(f"{GREEN}  {msg}{RESET}")


def warn(msg):
    print(f"{YELLOW}  {msg}{RESET}")


def error(msg):
    print(f"{RED}  {msg}{RESET}")


def header(msg):
    print(f"\n{BOLD}{msg}{RESET}")
    print("─" * len(msg))


def cmd_exists(cmd):
    """Check if a command is available on PATH."""
    return shutil.which(cmd) is not None


def run(args, cwd=None, check=True):
    """Run a subprocess and return the result."""
    return subprocess.run(
        args, cwd=cwd, check=check,
        capture_output=True, text=True,
    )


# ─── Steps ───

def check_prerequisites(profile):
    """Verify that required tools are installed."""
    header(f"1/4 — Verification des prerequis ({profile})")
    prereqs = PREREQS_BY_PROFILE[profile]
    all_ok = True
    for cmd in prereqs:
        if cmd_exists(cmd):
            success(f"{cmd} ... OK")
        else:
            if cmd == "docker" or (profile == "no-code" and cmd == "cargo"):
                warn(f"{cmd} ... absent (optionnel pour ton profil)")
            else:
                error(f"{cmd} ... MANQUANT")
                all_ok = False

    if not all_ok:
        print()
        error("Il manque des outils. Installe-les avant de continuer :")
        if not cmd_exists("git"):
            if platform.system() == "Darwin":
                print("  git     : xcode-select --install")
            elif platform.system() == "Windows":
                print("  git     : https://git-scm.com/download/win")
            else:
                print("  git     : sudo apt install git  (ou equivalent)")
        if not cmd_exists("flutter"):
            print("  flutter : https://docs.flutter.dev/get-started/install")
        if not cmd_exists("cargo") and profile != "no-code":
            print("  rust    : https://rustup.rs")
        sys.exit(1)

    return True


def clone_repos(profile, root_dir):
    """Clone required repos that are not already present."""
    header(f"2/4 — Clonage des repos ({profile})")
    repos = REPOS_BY_PROFILE[profile]

    for repo_name in repos:
        repo_path = root_dir / repo_name
        if repo_path.exists() and (repo_path / ".git").exists():
            success(f"{repo_name}/ ... deja present")
        elif repo_path.exists():
            warn(f"{repo_name}/ existe mais n'est pas un repo git — ignore")
        else:
            info(f"Clonage de {repo_name}...")
            url = f"{GITHUB_ORG}/{repo_name}.git"
            try:
                run(["git", "clone", url, str(repo_path)])
                success(f"{repo_name}/ ... clone")
            except subprocess.CalledProcessError as e:
                error(f"Echec du clonage de {repo_name}: {e.stderr.strip()}")
                error(f"Tu peux le cloner manuellement : git clone {url}")


def setup_llm_config(profile, root_dir):
    """Set up Claude Code and Cursor configuration for the profile."""
    header(f"3/4 — Configuration IA ({profile})")

    # ── Claude Code: settings.local.json for no-code guard ──
    if profile == "no-code":
        settings_local = root_dir / ".claude" / "settings.local.json"
        if settings_local.exists():
            warn("settings.local.json existe deja — pas de modification")
        else:
            guard_config = {
                "hooks": {
                    "PreToolUse": [
                        {
                            "matcher": "Edit|Write",
                            "hooks": [
                                {
                                    "type": "command",
                                    "command": '"$CLAUDE_PROJECT_DIR"/.claude/hooks/guard-no-code.sh',
                                    "timeout": 10,
                                }
                            ],
                        }
                    ]
                }
            }
            settings_local.parent.mkdir(parents=True, exist_ok=True)
            settings_local.write_text(
                json.dumps(guard_config, indent=2, ensure_ascii=False) + "\n"
            )
            success("Hook de protection no-code active (settings.local.json)")

    # ── Check that .claude/ config exists ──
    claude_dir = root_dir / ".claude"
    if (claude_dir / "commands" / "onboard.md").exists():
        success("Commandes Claude Code detectees (.claude/commands/)")
    else:
        warn("Dossier .claude/commands/ absent — verifie que tu es dans le bon repertoire")

    if (claude_dir / "hooks" / "guard-no-code.sh").exists():
        success("Hook guard-no-code.sh detecte")
    if (claude_dir / "hooks" / "guard-destructive.sh").exists():
        success("Hook guard-destructive.sh detecte")

    # ── Cursor: .cursorrules will be generated by /onboard ──
    cursorrules = root_dir / ".cursorrules"
    if cursorrules.exists():
        success(".cursorrules existe deja")
    else:
        info(".cursorrules sera genere par la commande /onboard")


def print_next_steps(profile, root_dir):
    """Print what the user should do next."""
    header("4/4 — Prochaines etapes")

    print()
    print(f"  {BOLD}Ton environnement est pret !{RESET}")
    print()

    if profile == "no-code":
        print(f"  {CYAN}Etape 1{RESET} — Lance Claude Code :")
        print(f"    cd {root_dir}")
        print(f"    claude")
        print()
        print(f"  {CYAN}Etape 2{RESET} — Execute la commande d'onboarding :")
        print(f"    /onboard no-code")
        print()
        print(f"  {CYAN}Etape 3{RESET} — Lis le guide du contributeur :")
        print(f"    bibliogenius-docs/docs/project-management/NO_CODE_ONBOARDING.md")
        print()
        print(f"  {CYAN}Etape 4{RESET} — Pour ta premiere modification :")
        print(f"    git checkout -b contrib/ma-premiere-modif")
        print(f"    (fais ta modif avec Claude Code ou Cursor)")
        print(f"    /contrib-check")
        print(f"    git add <fichiers> && git commit -m \"contrib: ma modif\"")
        print(f"    git push -u origin contrib/ma-premiere-modif")
        print()
        print(f"  {GREEN}Tu ne peux modifier que les zones sures :{RESET}")
        print(f"    - Traductions    : bibliogenius-app/assets/i18n/*.po")
        print(f"    - Listes curees  : bibliogenius-app/assets/curated_lists/**/*.yml")
        print(f"    - Themes         : bibliogenius-app/lib/themes/")
        print(f"    - Ecrans simples : help_screen, feedback_screen, splash_screen")
        print(f"    - Images         : bibliogenius-app/assets/images/")

    elif profile == "junior":
        print(f"  {CYAN}Etape 1{RESET} — Lance Claude Code :")
        print(f"    cd {root_dir}")
        print(f"    claude")
        print()
        print(f"  {CYAN}Etape 2{RESET} — Execute la commande d'onboarding :")
        print(f"    /onboard junior")
        print()
        print(f"  {CYAN}Etape 3{RESET} — Verifie que le backend compile :")
        print(f"    cd bibliogenius && cargo build && cargo test")
        print()
        print(f"  {CYAN}Etape 4{RESET} — Lance l'app Flutter :")
        print(f"    cd bibliogenius-app && flutter pub get && flutter run")
        print()
        print(f"  {YELLOW}Rappels :{RESET}")
        print(f"    - Toujours travailler sur une branche (pas main)")
        print(f"    - cargo fmt && cargo clippy && cargo test avant chaque PR")
        print(f"    - flutter analyze avant chaque PR Flutter")
        print(f"    - Lire CLAUDE.md pour les regles d'architecture")

    elif profile == "senior":
        print(f"  {CYAN}Etape 1{RESET} — Lance Claude Code :")
        print(f"    cd {root_dir}")
        print(f"    claude")
        print()
        print(f"  {CYAN}Etape 2{RESET} — Execute la commande d'onboarding :")
        print(f"    /onboard senior")
        print()
        print(f"  {CYAN}Etape 3{RESET} — Lis les fichiers cles :")
        print(f"    - CLAUDE.md (regles d'architecture)")
        print(f"    - bibliogenius/CLAUDE.md (conventions Rust)")
        print(f"    - bibliogenius-app/CLAUDE.md (conventions Flutter)")
        print(f"    - bibliogenius-docs/docs/technical/SECURITY_GUIDELINES.md")
        print()
        print(f"  {CYAN}Etape 4{RESET} — Docker (optionnel) :")
        print(f"    cd bibliogenius-docker && docker-compose up -d")

    # Claude Code installation reminder
    print()
    if not cmd_exists("claude"):
        print(f"  {YELLOW}Note : Claude Code n'est pas installe.{RESET}")
        print(f"    npm install -g @anthropic-ai/claude-code")
        print()


# ─── Main ───

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0)

    profile = sys.argv[1].lower()

    if profile not in PROFILES:
        error(f"Profil inconnu : '{profile}'")
        print(f"  Profils disponibles : {', '.join(PROFILES)}")
        sys.exit(1)

    root_dir = Path(__file__).resolve().parent

    print()
    print(f"{BOLD}BiblioGenius Setup — profil {profile}{RESET}")
    print(f"Repertoire : {root_dir}")
    print()

    check_prerequisites(profile)
    clone_repos(profile, root_dir)
    setup_llm_config(profile, root_dir)
    print_next_steps(profile, root_dir)


if __name__ == "__main__":
    main()
