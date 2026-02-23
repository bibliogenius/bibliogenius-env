Simplified verification for no-code contributors. Checks that modifications are within allowed zones and that the code is correct.

## Steps

1. Run `git diff --stat` in `bibliogenius-app/` to see what files changed. If no changes are detected, also check `git diff --cached --stat` for staged changes.

2. **Safe zone check**: Verify that EVERY modified file is in one of these allowed paths:
   - `bibliogenius-app/assets/i18n/*.po` (translations)
   - `bibliogenius-app/assets/curated_lists/**/*.yml` (curated lists)
   - `bibliogenius-app/lib/themes/**` (theme files)
   - `bibliogenius-app/lib/theme/app_design.dart` (design tokens)
   - `bibliogenius-app/lib/widgets/**` (simple widgets)
   - `bibliogenius-app/lib/screens/help_screen.dart`
   - `bibliogenius-app/lib/screens/feedback_screen.dart`
   - `bibliogenius-app/lib/screens/splash_screen.dart`
   - `bibliogenius-app/assets/images/**`

   If ANY file is outside these zones, report it as **ISSUE** with a clear explanation of why it's not allowed.

3. **Flutter analysis**: For each modified `.dart` file, run `flutter analyze <file>`. Report any errors or warnings.

4. **Translation validation**: For each modified `.po` file, check basic format validity:
   - Every `msgid` has a corresponding `msgstr`
   - No empty `msgstr` for non-empty `msgid` (warning only — may be intentional for untranslated strings)
   - No obvious syntax issues (unclosed quotes, missing headers)

5. **Output a structured report** in this format:

```
## /contrib-check Results

### Modified files
- file1.po ✅ Safe zone
- file2.dart ❌ Outside safe zone (explanation)

### Flutter analysis
- ✅ No errors (or list of errors)

### Translations
- ✅ Format correct (or list of issues)

### Verdict
✅ READY FOR PR — you can commit and push
   or
❌ ISSUE(S) TO FIX — see details above
```

6. If the verdict is OK, remind the contributor of the next steps:
   ```
   git add <files>
   git commit -m "contrib: short description of the change"
   git push -u origin contrib/your-branch
   ```

7. If there are problems, explain each one in simple terms and suggest how to fix it.
