Generate release notes from recent commits. Follow these steps:

1. Find the latest git tag in both `bibliogenius/` and `bibliogenius-app/` using `git describe --tags --abbrev=0`.
2. Get all commits since that tag: `git log <tag>..HEAD --oneline`.
3. Categorize each commit into:
   - **Nouvelles fonctionnalites** (features)
   - **Corrections de bugs** (bug fixes)
   - **Ameliorations** (improvements, refactors, perf)
   - **Securite** (security fixes)
   - **Infrastructure** (CI, deps, config)
4. Write the release notes in French, in user-friendly language (not commit messages verbatim).
5. Flag any breaking changes or migration steps needed.
6. Output as markdown ready to paste into a GitHub release or changelog.

If an argument is provided (e.g., `/release-notes v0.8.0`), use that as the version header. Otherwise, suggest a version based on the nature of changes (patch/minor/major per semver).
