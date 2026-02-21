# Recommended Confluence Structure — BiblioGenius

> This document proposes a Confluence reorganization to make it
> readable by non-technical contributors. The goal: 4 clear spaces
> + 1 archive for dev-only content.

---

## Overview

```
Home
  └── Contributor Dashboard (quick links to the 4 spaces)

1. Product        — vision, features, high-level architecture
2. Quality        — functional tests, bug reports, beta guides
3. Business       — strategy, competition, partnerships, funding
4. Contribute     — no-code guide for small code changes

Archive (hidden by default)
  └── Technical or obsolete content
```

---

## Space 1 — Product

| Page | Current source | Notes |
|------|---------------|-------|
| Vision & Roadmap | `ROADMAP_V4.md` | Current roadmap, phase planning |
| Feature matrix | `features.md` | Complete feature list by module |
| Architecture (high level) | Mermaid diagram from `README.md` | Simple diagram: Flutter + Rust + SQLite |
| Available modules | Sections of `features.md` | Scan, gamification, P2P, MCP, etc. |
| UX & Mockups | App screenshots | To create: main user flows |
| Milestones | `project_milestones.md` | Project milestones |
| Modular strategy | `MODULAR_STRATEGY.md` | How modules fit together |

---

## Space 2 — Quality

| Page | Current source | Notes |
|------|---------------|-------|
| Functional tests | `QA_NON_REGRESSION.md` (Part A only) | Functional checklist by priority |
| Beta test guide | `PRE_ALPHA_TEST_GUIDE.md` | Instructions for beta testers |
| Network & contacts tests | `QA_NETWORK_CONTACTS.md` | P2P-specific scenarios |
| Bug reports | `qa/bug_report.md` | Template + process |
| Troubleshooting | `qa/deployment_troubleshooting.md` | Known issues and solutions |

> **Note**: `QA_NON_REGRESSION.md` Part B (detailed scenarios, security,
> performance) stays in Archive — too technical for no-code contributors.

---

## Space 3 — Business & Strategy

| Page | Current source | Notes |
|------|---------------|-------|
| Competitive analysis | `COMPETITIVE_ANALYSIS.md` | Positioning vs Gleeph, Babelio, etc. |
| Gleeph strategy | `gleeph_conversion_strategy.md` | User conversion plan |
| Installation profiles | `INSTALLATION_PROFILE_ANALYSIS.md` | User segmentation |
| Pitch & funding | `PITCH_STRATEGY.md` | Sales arguments |
| Funding | `funding/financialRoadmap.md` | Budget, grants, NLnet |
| Opportunities | `funding/funding_opportunities.md` | Funding sources |
| Strategic plan | `strategic_roadmap.md` | Long-term vision |
| Partnerships | `partnerships/` | Inventaire, ENSSIB, Koha |
| ENSSIB strategy | `ENSSIB_STRATEGY_AND_ACTION_PLAN.md` | ENSSIB action plan |
| BSF Synergies | `BSF_SYNERGY_AND_OPPORTUNITIES.md` | BSF opportunities |
| Marketing | `marketing/` | Outreach, announcements, flyer |
| Events | `events/` | FOSDEM, API Days |
| Tenders | `tenders/` | Tender responses |
| Building in Public | `building_in_public.md` | Communication strategy |
| Local experimentation | `local_experimentation_strategy.md` | Field tests |

---

## Space 4 — Contribute (no-code guide)

| Page | Current source | Notes |
|------|---------------|-------|
| Getting started | See `NO_CODE_ONBOARDING.md` | Simplified dev setup |
| Safe zones | New | Translations, curated lists, themes |
| PR workflow | New | Branch, modify, review, merge |
| AI commands | New | `/onboard no-code`, `/contrib-check`, `/review` |
| First tickets | `good-first-issues/` | Accessible topics to contribute |
| Contributing guide | `CONTRIBUTING.md` | General process |

---

## Archive (hidden by default)

> These documents remain in the repo for developers, but are hidden
> from the no-code contributor Confluence view.

### Documents to archive

| Document | Reason |
|----------|--------|
| **Security & Crypto** | |
| `SECURITY_GUIDELINES.md` (~2,850 lines) | Pure crypto, technical audit |
| `ADR-001` to `ADR-004` | E2EE architecture decisions |
| `security/code_audit_dec_2025.md` | Internal code audit |
| **Technical architecture** | |
| `ArchitectureRust.md` | Internal Rust layers |
| `data-model-book-fields.md` | Technical DB schema |
| `data_model_evolution_v4.md` | Data model evolution |
| `DEVELOPMENT_SETUP.md` | Replaced by simplified no-code guide |
| `DOCKER_SETUP.md` | Dev infrastructure |
| **Completed research** | |
| `research/p2p-network/` (6+ files) | Decision made, iroh to LAN direct |
| `research/ai-ml/` (4 files) | Technical explorations |
| `research/quiz-module/` (3 files) | Module not yet launched |
| `research/bookshelf_view.md` | UI exploration completed |
| `research/integrated_module_manager_analysis.md` | Technical analysis |
| **Technical QA** | |
| `qa/p2p_impact_analysis.md` | Dev impact analysis |
| `qa/qa_report_final.md` | Technical QA report |
| `qa/ipad_testing_guide.md` | Platform-specific testing |
| **Deployment & Ops** | |
| `ios_deployment.md` | iOS deployment guide |
| `macos_deployment.md` | macOS deployment guide |
| `beta_distribution_guide.md` | Technical distribution |
| **Obsolete roadmaps** | |
| `_archive/ROADMAP_V2.md` | Replaced by V4 |
| `_archive/POC_ROADMAP.md` | POC completed |
| `_archive/POC_COMPLETE.md` | POC completed |
| `_archive/strategic_roadmap_2025.md` | Replaced |
| **Technical misc** | |
| `CLAUDE.md` (Rust, Flutter) | AI dev instructions |
| `testing_poc.md` | POC tests |
| `inventaire_integration_roadmap.md` | Technical integration roadmap |
| `feature-profile-upload.md`, `feature-bookseller-profile.md` | Technical specs |
| `video_tutorials.md` | Technical content |
| `p2p/` (4 files) | Internal P2P architecture |
| `tasks/multi_author_support.md` | Technical task |
| `modules/mcp/implementation_plan.md` | Technical MCP plan |
| `technical_feasibility_assessment.md` | Technical analysis |
| `gamification_v3_implementation.md` | Technical implementation |

---

## Recommended actions

### Step 1 — Create Confluence spaces

1. Create the 4 main spaces (Product, Quality, Business, Contribute)
2. Create the Archive space (hidden from navigation by default)
3. Create the Dashboard home page with links to each space

### Step 2 — Migrate existing content

1. Copy "keep" documents into corresponding spaces
2. Move "archive" documents into the Archive space
3. Adapt documents to Confluence format (table of contents, internal links)

### Step 3 — Create missing content

1. UX & Mockups page (screenshots of main screens)
2. "Contribute" space pages (getting started, safe zones, PR workflow)
3. Dashboard with key metrics

### Step 4 — Set up maintenance

- Quarterly review: check content is up to date
- When a new technical document is created, immediately decide if it goes in a visible space or Archive
- Any contributor can propose to "unarchive" a document if needed

---

## Quick summary

| Space | Estimated pages | Target audience |
|-------|----------------|-----------------|
| Product | ~7 | Team, stakeholders |
| Quality | ~5 | Contributors, beta testers |
| Business | ~15 | PO, management, partners |
| Contribute | ~6 | No-code contributors |
| Archive | ~30+ | Developers only |
