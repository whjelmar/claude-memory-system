# Code Review Session: [DATE TIME]

## Review Information
- **PR/MR Number**: [#123]
- **PR Title**: [Title]
- **Author**: [Name]
- **Branch**: [feature-branch] -> [main]
- **Review Type**: [Initial / Follow-up / Final]

## PR Summary
<!-- Brief description of what the PR does -->


## Files Changed
| File | Type | LOC | Priority |
|------|------|-----|----------|
| `path/to/file.ts` | Modified | +50/-20 | High |

## Review Checklist

### Code Quality
- [ ] Code is readable and well-organized
- [ ] Naming is clear and consistent
- [ ] No unnecessary complexity
- [ ] DRY principle followed
- [ ] SOLID principles followed (where applicable)
- [ ] No code smells

### Functionality
- [ ] Code does what it's supposed to do
- [ ] Edge cases handled
- [ ] Error handling is appropriate
- [ ] No obvious bugs

### Testing
- [ ] Tests are included
- [ ] Tests cover happy path
- [ ] Tests cover edge cases
- [ ] Tests are readable and maintainable
- [ ] All tests pass

### Security
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] No SQL injection risks
- [ ] No XSS vulnerabilities
- [ ] Authentication/authorization correct

### Performance
- [ ] No obvious performance issues
- [ ] No N+1 queries
- [ ] Appropriate caching (if needed)
- [ ] Large datasets handled efficiently

### Documentation
- [ ] Code is self-documenting where possible
- [ ] Comments explain "why" not "what"
- [ ] README updated (if needed)
- [ ] API docs updated (if needed)

## Detailed Feedback

### Critical Issues (Must Fix)
<!-- Issues that must be addressed before merge -->
1. **File**: `path/to/file.ts:42`
   - **Issue**:
   - **Suggestion**:

### Major Suggestions (Should Fix)
<!-- Important improvements that should be made -->
1. **File**: `path/to/file.ts:15`
   - **Issue**:
   - **Suggestion**:

### Minor Suggestions (Nice to Have)
<!-- Optional improvements -->
1. **File**: `path/to/file.ts:88`
   - **Suggestion**:

### Praise / Good Practices
<!-- Call out things done well -->
- Great use of [pattern] in `file.ts`
- Clean abstraction for [component]

## Questions for Author
<!-- Things that need clarification -->
- [ ] Why was [approach] chosen over [alternative]?
- [ ] How does this handle [scenario]?

## Testing Notes
<!-- If you tested the code yourself -->
- [ ] Tested locally
- [ ] Tested in staging
- [ ] Specific scenarios tested:
  - [ ] Scenario 1: [result]
  - [ ] Scenario 2: [result]

## Session Checklist
- [ ] All files reviewed
- [ ] Security considerations checked
- [ ] Tests reviewed
- [ ] Feedback documented
- [ ] Questions asked where needed
- [ ] Review verdict decided

## Review Verdict
<!-- Your overall assessment -->
- [ ] **Approve** - Good to merge
- [ ] **Approve with suggestions** - Minor changes optional
- [ ] **Request changes** - Issues must be addressed
- [ ] **Needs discussion** - Larger concerns to discuss

## Summary
<!-- Brief summary of your review -->


## Follow-up Items
<!-- Things to check after this review -->
- [ ] Review updated PR when changes are made
- [ ] Verify CI passes
- [ ] Check for conflicts

---
*Session Type: Code Review*
