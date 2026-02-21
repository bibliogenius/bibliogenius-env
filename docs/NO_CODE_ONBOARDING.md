# Bienvenue sur BiblioGenius — Guide Contributeur No-Code

## Le projet en 2 minutes

BiblioGenius est une application de gestion de bibliotheque personnelle.
Elle permet de cataloguer ses livres, les partager avec des contacts,
et decouvrir de nouveaux titres via des sources ouvertes (BNF, Inventaire, OpenLibrary).

**Stack technique** (pas besoin de tout comprendre) :
- **L'interface** (ce que l'utilisateur voit) : Flutter (langage Dart)
- **Le moteur** (la logique metier) : Rust
- **La base de donnees** : SQLite (un fichier local)
- L'interface appelle directement le moteur via FFI (pas de serveur web entre les deux)

**Version actuelle** : v0.7.x (pre-alpha)

**Ce qui marche deja** : scan de livres (ISBN, couverture), catalogue personnel,
recherche multi-sources, gamification, echanges entre contacts en reseau local,
chiffrement de bout en bout (E2EE).

---

## Ta boite a outils

| Outil | Usage | Lien |
|-------|-------|------|
| **Confluence** | Documentation produit, QA, business | *(lien a remplir)* |
| **GitHub** | Code source et issues | *(lien a remplir)* |
| **Claude Code** | Assistant IA pour contribuer au code | Terminal : `claude` |
| **Cursor** | Editeur de code avec IA integree | Alternative a VS Code |

---

## Comment t'y retrouver dans Confluence

> Voir `CONFLUENCE_STRUCTURE.md` pour la structure detaillee.

| Espace | Ce que tu y trouves |
|--------|---------------------|
| **Produit** | Roadmap, liste des fonctionnalites, architecture haut niveau, modules |
| **Qualite** | Checklist de tests fonctionnels, guide beta testeurs, bug reports |
| **Business** | Analyse concurrentielle, pitch, partenariats, financement, marketing |
| **Contribuer** | Comment faire tes premieres modifications au code (ce guide !) |

L'espace **Archive** contient la documentation technique detaillee (crypto, architecture Rust, recherche P2P...).
Tu n'en as pas besoin au quotidien — il est masque par defaut.

---

## Tes premieres missions

Par difficulte croissante :

### 1. Corriger une traduction (FR/EN)

**Difficulte** : facile

**Fichiers concernes** : `bibliogenius-app/assets/i18n/*.po`

Les fichiers `.po` contiennent les traductions de l'interface.
Chaque entree a un `msgid` (la cle) et un `msgstr` (la traduction).

Exemple — corriger une faute dans la traduction francaise :
```
msgid "search_placeholder"
msgstr "Rechercher un livre..."
```

**Comment faire** :
1. Ouvre le fichier `.po` de la langue concernee
2. Trouve le `msgid` a corriger
3. Modifie le `msgstr`
4. Lance `/contrib-check` pour verifier

---

### 2. Ajouter une liste curee de livres

**Difficulte** : facile

**Fichiers concernes** : `bibliogenius-app/assets/curated_lists/**/*.yml`

Les listes curees sont des selections thematiques de livres (ex : "Classiques francais",
"Science-fiction incontournables").

Exemple de format :
```yaml
- title: "Le Petit Prince"
  author: "Antoine de Saint-Exupery"
  isbn: "9782070612758"
```

**Comment faire** :
1. Cree un nouveau fichier `.yml` dans le bon dossier thematique
2. Ajoute les livres avec titre, auteur, et ISBN
3. Lance `/contrib-check` pour verifier la syntaxe

---

### 3. Modifier une couleur du theme

**Difficulte** : moyenne

**Fichiers concernes** : `bibliogenius-app/lib/themes/` ou `lib/theme/app_design.dart`

Le theme definit les couleurs, polices et espacements de l'app.
Tu peux modifier des valeurs numeriques (couleurs en hexadecimal, tailles en pixels).

Exemple :
```dart
static const primaryColor = Color(0xFF1A73E8);  // Bleu Google
```

**Comment faire** :
1. Identifie la couleur a changer dans `app_design.dart`
2. Modifie la valeur hexadecimale
3. Lance `flutter analyze` pour verifier qu'il n'y a pas d'erreur

---

### 4. Mettre a jour le texte d'un ecran simple

**Difficulte** : moyenne

**Fichiers concernes** : `help_screen.dart`, `feedback_screen.dart`, `splash_screen.dart`

Ces ecrans contiennent du texte statique que tu peux modifier.
Attention : le texte doit utiliser le systeme de traduction (pas de texte "en dur").

**Comment faire** :
1. Ajoute la nouvelle cle de traduction dans les fichiers `.po`
2. Utilise `TranslationService.translate(context, 'ta_cle')` dans le code Dart
3. Lance `/contrib-check`

---

### 5. Ajouter un widget simple

**Difficulte** : avancee (avec review obligatoire)

**Fichiers concernes** : `bibliogenius-app/lib/widgets/` (fichiers < 300 lignes)

Pour cette mission, travaille avec Claude Code qui te guidera pas a pas.
La PR sera obligatoirement relue par un developpeur avant d'etre mergee.

---

## Setup — une seule commande

### Prerequis

Installe ces outils avant de commencer :

| Outil | Installation | Verification |
|-------|-------------|--------------|
| **Git** | Mac : `xcode-select --install` / Windows : https://git-scm.com | `git --version` |
| **Flutter** | https://docs.flutter.dev/get-started/install | `flutter doctor` |
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` | `claude --version` |

### Installation

```bash
# 1. Clone le repo d'environnement
git clone https://github.com/bibliogenius/bibliogenius-env.git
cd bibliogenius-env

# 2. Lance le setup (une seule commande !)
make setup P=no-code
```

C'est tout. Le script va :
- Verifier tes prerequis (git, flutter)
- Cloner les repos dont tu as besoin (bibliogenius-app, bibliogenius-docs)
- Activer le hook de protection qui t'empeche de modifier des fichiers interdits
- T'afficher les prochaines etapes

> Alternative : `python3 setup.py no-code`

### Apres le setup

```bash
# 3. Lance Claude Code
claude

# 4. Execute l'onboarding (genere ton fichier .cursorrules)
/onboard no-code
```

### Lancer l'app (mode debug)

```bash
cd bibliogenius-app
flutter run
```

> Note : le backend Rust est compile automatiquement via FFI.
> Tu n'as pas besoin d'installer Rust pour les modifications front-end simples.
> Si `flutter run` echoue sur la compilation Rust, demande de l'aide a un developpeur.

---

## Workflow pour tes PRs

### Etape par etape

```
1. Creer une branche
   git checkout -b contrib/ma-modification

2. Faire la modification
   - Avec Claude Code : decris ce que tu veux changer
   - Avec Cursor : edite directement le fichier

3. Verifier
   /contrib-check

4. Sauvegarder localement
   git add <fichiers-modifies>
   git commit -m "contrib: description courte de la modif"

5. Envoyer sur GitHub
   git push -u origin contrib/ma-modification

6. Creer la Pull Request
   - Va sur GitHub, clique "Compare & pull request"
   - Decris ce que tu as change et pourquoi
   - Attends la review d'un developpeur

7. Apres la review
   - Si des corrections sont demandees : fais-les sur la meme branche
   - Quand c'est approuve : le developpeur mergera pour toi
```

### Convention de nommage

- Branches : `contrib/description-courte` (ex : `contrib/fix-traduction-accueil`)
- Commits : `contrib: description courte` (ex : `contrib: corriger typo ecran d'aide`)
- PR title : en francais, descriptif (ex : "Correction traduction ecran d'accueil")

### Checklist avant de proposer ta PR

- [ ] `/contrib-check` retourne OK (pas d'erreur)
- [ ] Seuls des fichiers "zone sure" sont modifies
- [ ] J'ai teste l'app localement (`flutter run`) et ca marche
- [ ] Ma description de PR explique ce que j'ai change et pourquoi

---

## Zones sures vs zones interdites

### Tu PEUX modifier

| Zone | Chemin | Exemples |
|------|--------|----------|
| Traductions | `assets/i18n/*.po` | Corriger une traduction, ajouter une langue |
| Listes curees | `assets/curated_lists/**/*.yml` | Ajouter une selection de livres |
| Themes | `lib/themes/` | Changer une couleur, un espacement |
| Design tokens | `lib/theme/app_design.dart` | Valeurs numeriques et couleurs uniquement |
| Ecrans simples | `help_screen.dart`, `feedback_screen.dart`, `splash_screen.dart` | Texte, mise en page basique |
| Widgets simples | `lib/widgets/` (< 300 lignes) | Avec guidage Claude Code |
| Images | `assets/images/` | Remplacer un logo, une illustration |

### Tu ne DOIS PAS modifier

| Zone | Raison |
|------|--------|
| Tout le Rust (`bibliogenius/`) | Backend technique, risque de casser le moteur |
| `lib/models/` | Contrat d'interface avec le Rust |
| `lib/services/` | Logique metier Flutter |
| `lib/providers/` | Gestion d'etat |
| `lib/data/` | Acces aux donnees |
| `lib/src/rust/` | Code genere automatiquement (FFI) |
| `lib/config/`, `lib/utils/` | Configuration interne |
| `pubspec.yaml`, `Cargo.toml` | Dependances du projet |
| Fichiers CI, migrations | Infrastructure |
| `.claude/hooks/` | Gardes de securite |

> Si le hook no-code est actif, Claude Code refusera automatiquement
> toute modification hors zone sure.

---

## Glossaire rapide

| Terme | Explication simple |
|-------|-------------------|
| **Flutter** | Framework pour creer l'interface (les ecrans, boutons, etc.) |
| **Dart** | Langage de programmation utilise par Flutter |
| **Rust** | Langage de programmation du moteur (backend) |
| **FFI** | Pont entre Flutter et Rust (ils se "parlent" directement) |
| **PR (Pull Request)** | Demande pour integrer tes modifications dans le code principal |
| **Branch (branche)** | Copie de travail isolee du code (pour ne pas casser le principal) |
| **Merge** | Integrer une branche dans le code principal |
| **Review** | Relecture de ton code par un developpeur avant le merge |
| **`.po`** | Format de fichier standard pour les traductions |
| **`.yml`** | Format de fichier structure (listes, configurations) |
| **`flutter analyze`** | Outil qui verifie les erreurs dans le code Flutter |
| **Hook** | Script automatique qui se declenche a certaines actions |
| **E2EE** | Chiffrement de bout en bout (securite des echanges entre utilisateurs) |
| **SeaORM** | Outil Rust pour acceder a la base de donnees (tu n'y touches pas) |
