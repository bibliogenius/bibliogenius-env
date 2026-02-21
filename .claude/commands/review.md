Review the current changes in the working tree. Follow these steps:

1. Run `git diff --stat` and `git diff --cached --stat` in both `bibliogenius/` and `bibliogenius-app/` to see what changed.
2. Read each modified file to understand the changes in context.
3. Check against the architecture rules in CLAUDE.md:
   - R1: No SeaORM in new api/ handlers
   - R2: No framework deps in domain/
   - R3: Proper layer chain (Handler → Service/Repo → Infrastructure)
   - R4: Infra implements domain traits
   - R5: Model fields frozen
   - F1: No data access in screens
   - F2: Repository pattern for new entities
4. Check for:
   - Security issues (hardcoded secrets, SQL injection, XSS)
   - Missing error handling
   - Code duplication with existing codebase
   - Breaking changes to FFI contract (frb.rs structs)
   - Missing or broken tests
5. Output a structured review with severity levels:
   - **BLOQUANT**: Must fix before merge
   - **IMPORTANT**: Should fix, creates tech debt if ignored
   - **SUGGESTION**: Nice to have, non-blocking
   - **OK**: Things that look good (brief)

Format the output as a clear markdown report.
