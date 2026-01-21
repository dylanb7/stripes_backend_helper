# Requirement YAML Examples

This document provides examples of valid YAML configurations for the `Requirement` field in both `Question` and `PageLayout` definitions.

## 1. Questions

For questions, you can often omit the `questionId` to refer to the question itself (Implicit Context).

### A. Implicit "Required" (Self)
Check if *this* question has been answered.
```yaml
requirement:
  exists: true
```

### B. Implicit "Matches Regex" (Self)
Check if *this* question's answer matches a pattern (e.g., specific text or format).
```yaml
requirement:
  regex: '^[0-9]+$'
```

### C. Explicit Dependency
Check if *another* question has been answered.
```yaml
requirement:
  exists: true
  questionId: 'other-question-id'
```

### D. Explicit Equality
Check if *another* question has a specific value.
```yaml
requirement:
  equals: 'Yes'
  questionId: 'has-pain'
```

### E. Complex Logic (AND/OR)
Combine multiple conditions.
```yaml
requirement:
  oneOf: # OR logic
    - exists: true
      questionId: 'symptom-a'
    - allOf: # AND logic (nested)
        - equals: 'Severe'
          questionId: 'symptom-b-severity'
        - exists: true # Implicitly refers to THIS question if used inside a Question definition? 
                       # CAUTION: Nested conditions usually need explicit IDs unless context is clear. 
                       # Best practice for cross-question logic is to be explicit.
```
*Note: The simplified syntax allows mixing `exists: true` with `questionId` at the top level. For nested lists (`oneOf`/`allOf`), each item is a separate condition map.*

---

## 2. PageLayouts

`PageLayouts` do not have a "self" response value, so requirements usually refer to specific questions by ID.

### A. Show Page if Question Answered
```yaml
requirement:
  exists: true
  questionId: 'consent-given'
```

### B. Show Page if Valid Age Range
```yaml
requirement:
  allOf:
    - exists: true
      questionId: 'age'
    - regex: '^(1[8-9]|[2-9][0-9])$' # Simple regex for 18-99
      questionId: 'age'
```

### C. Show Page if Either Condition Met
```yaml
requirement:
  oneOf:
    - equals: 'Admin'
      questionId: 'user-role'
    - equals: 'true'
      questionId: 'debug-mode'
```
