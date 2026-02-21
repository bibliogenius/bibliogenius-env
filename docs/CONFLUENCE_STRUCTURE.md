# Structure Confluence recommandee — BiblioGenius

> Ce document propose une reorganisation de l'espace Confluence pour le rendre
> lisible par un Product Owner non-technique. L'objectif : 4 espaces clairs
> + 1 archive pour le contenu dev-only.

---

## Vue d'ensemble

```
Accueil
  └── Dashboard contributeur (liens rapides vers les 4 espaces)

1. Produit          — vision, fonctionnalites, architecture haut niveau
2. Qualite          — tests fonctionnels, bug reports, guides beta
3. Business         — strategie, concurrence, partenariats, financement
4. Contribuer       — guide no-code pour faire de petites modifications au code

Archive (masque par defaut)
  └── Contenu technique ou obsolete
```

---

## Espace 1 — Produit

| Page | Source actuelle | Notes |
|------|-----------------|-------|
| Vision & Roadmap | `ROADMAP_V4.md` | Roadmap actuelle, planning par phase |
| Matrice des fonctionnalites | `features.md` | Liste complete des features par module |
| Architecture (vue haut niveau) | Schema mermaid du `README.md` | Diagramme simple : Flutter + Rust + SQLite |
| Modules disponibles | Sections de `features.md` | Scan, gamification, P2P, MCP, etc. |
| UX & Maquettes | Captures d'ecran de l'app | A creer : flux utilisateur principaux |
| Milestones | `project_milestones.md` | Jalons du projet |
| Strategie modulaire | `MODULAR_STRATEGY.md` | Comment les modules s'articulent |

---

## Espace 2 — Qualite

| Page | Source actuelle | Notes |
|------|-----------------|-------|
| Tests fonctionnels | `QA_NON_REGRESSION.md` (Part A uniquement) | Checklist fonctionnelle par priorite |
| Guide de test beta | `PRE_ALPHA_TEST_GUIDE.md` | Instructions pour les beta testeurs |
| Tests reseau & contacts | `QA_NETWORK_CONTACTS.md` | Scenarios P2P specifiques |
| Bug reports | `qa/bug_report.md` | Template + processus |
| Troubleshooting | `qa/deployment_troubleshooting.md` | Problemes connus et solutions |

> **Note** : `QA_NON_REGRESSION.md` Part B (scenarios detailles, securite,
> performance) reste dans l'Archive — trop technique pour les contributeurs no-code.

---

## Espace 3 — Business & Strategie

| Page | Source actuelle | Notes |
|------|-----------------|-------|
| Analyse concurrentielle | `COMPETITIVE_ANALYSIS.md` | Positionnement vs Gleeph, Babelio, etc. |
| Strategie Gleeph | `gleeph_conversion_strategy.md` | Plan de conversion utilisateurs |
| Profils d'installation | `INSTALLATION_PROFILE_ANALYSIS.md` | Segmentation utilisateurs |
| Pitch & funding | `PITCH_STRATEGY.md` | Arguments de vente |
| Financement | `funding/financialRoadmap.md` | Budget, subventions, NLnet |
| Opportunites | `funding/funding_opportunities.md` | Sources de financement |
| Plan strategique | `strategic_roadmap.md` | Vision long terme |
| Partenariats | `partnerships/` | Inventaire, ENSSIB, Koha |
| Strategy ENSSIB | `ENSSIB_STRATEGY_AND_ACTION_PLAN.md` | Plan d'action ENSSIB |
| BSF Synergies | `BSF_SYNERGY_AND_OPPORTUNITIES.md` | Opportunites BSF |
| Marketing | `marketing/` | Outreach, annonces, flyer |
| Evenements | `events/` | FOSDEM, API Days |
| Appels d'offres | `tenders/` | Reponses aux AO |
| Building in Public | `building_in_public.md` | Strategie de communication |
| Experimentation locale | `local_experimentation_strategy.md` | Tests terrain |

---

## Espace 4 — Contribuer au code (guide no-code)

| Page | Source actuelle | Notes |
|------|-----------------|-------|
| Premiers pas | Nouveau (voir `NO_CODE_ONBOARDING.md`) | Setup dev simplifie |
| Zones sures | Nouveau | Traductions, listes curees, themes |
| Workflow PR | Nouveau | Branche → modif → review → merge |
| Commandes IA | Nouveau | `/onboard no-code`, `/po-check`, `/review` |
| Premiers tickets | `good-first-issues/` | Sujets accessibles pour contribuer |
| Guide de contribution | `CONTRIBUTING.md` | Process general |

---

## Archive (masque par defaut)

> Ces documents restent dans le repo pour les developpeurs, mais sont masques
> dans la vue Confluence des contributeurs no-code.

### Documents a archiver

| Document | Raison |
|----------|--------|
| **Securite & Crypto** | |
| `SECURITY_GUIDELINES.md` (~2,850 lignes) | Crypto pur, audit technique |
| `ADR-001` a `ADR-004` | Decisions d'architecture E2EE |
| `security/code_audit_dec_2025.md` | Audit de code interne |
| **Architecture technique** | |
| `ArchitectureRust.md` | Layers Rust internes |
| `data-model-book-fields.md` | Schema DB technique |
| `data_model_evolution_v4.md` | Evolution du modele de donnees |
| `DEVELOPMENT_SETUP.md` | Remplace par le guide simplifie no-code |
| `DOCKER_SETUP.md` | Infrastructure dev |
| **Recherche terminee** | |
| `research/p2p-network/` (6+ fichiers) | Decision prise, iroh → LAN direct |
| `research/ai-ml/` (4 fichiers) | Explorations techniques |
| `research/quiz-module/` (3 fichiers) | Module pas encore lance |
| `research/bookshelf_view.md` | Exploration UI terminee |
| `research/integrated_module_manager_analysis.md` | Analyse technique |
| **QA technique** | |
| `qa/p2p_impact_analysis.md` | Analyse d'impact dev |
| `qa/qa_report_final.md` | Rapport QA technique |
| `qa/ipad_testing_guide.md` | Test specifique plateforme |
| **Deploiement & Ops** | |
| `ios_deployment.md` | Guide deploiement iOS |
| `macos_deployment.md` | Guide deploiement macOS |
| `beta_distribution_guide.md` | Distribution technique |
| **Roadmaps obsoletes** | |
| `_archive/ROADMAP_V2.md` | Remplacee par V4 |
| `_archive/POC_ROADMAP.md` | POC termine |
| `_archive/POC_COMPLETE.md` | POC termine |
| `_archive/strategic_roadmap_2025.md` | Remplacee |
| **Divers technique** | |
| `CLAUDE.md` (Rust, Flutter) | Instructions dev pour IA |
| `testing_poc.md` | POC tests |
| `inventaire_integration_roadmap.md` | Roadmap technique integration |
| `feature-profile-upload.md`, `feature-bookseller-profile.md` | Specs techniques |
| `video_tutorials.md` | Contenu technique |
| `p2p/` (4 fichiers) | Architecture P2P interne |
| `tasks/multi_author_support.md` | Tache technique |
| `modules/mcp/implementation_plan.md` | Plan technique MCP |
| `technical_feasibility_assessment.md` | Analyse technique |
| `gamification_v3_implementation.md` | Implementation technique |

---

## Actions recommandees

### Etape 1 — Creer les espaces Confluence

1. Creer les 4 espaces principaux (Produit, Qualite, Business, Contribuer)
2. Creer l'espace Archive (masque de la navigation par defaut)
3. Creer la page d'accueil Dashboard avec les liens vers chaque espace

### Etape 2 — Migrer le contenu existant

1. Copier les documents "garder" dans les espaces correspondants
2. Deplacer les documents "archiver" dans l'espace Archive
3. Adapter les documents au format Confluence (table des matieres, liens internes)

### Etape 3 — Creer le contenu manquant

1. Page UX & Maquettes (captures d'ecran des ecrans principaux)
2. Pages de l'espace "Contribuer" (premiers pas, zones sures, workflow PR)
3. Dashboard avec les metriques cles

### Etape 4 — Mettre en place la maintenance

- Review trimestrielle : verifier que le contenu est a jour
- Quand un nouveau document technique est cree, decider immediatement s'il va dans un espace visible ou en Archive
- Tout contributeur peut proposer de "desarchiver" un document s'il en a besoin

---

## Resume rapide

| Espace | Nb de pages estimees | Public cible |
|--------|---------------------|--------------|
| Produit | ~7 | Equipe, parties prenantes |
| Qualite | ~5 | Contributeurs, beta testeurs |
| Business | ~15 | PO, direction, partenaires |
| Contribuer | ~6 | Contributeurs no-code |
| Archive | ~30+ | Developpeurs uniquement |
