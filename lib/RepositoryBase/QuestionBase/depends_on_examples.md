# DependsOn YAML Examples

This document provides examples of valid YAML configurations for the `dependsOn` field. Unlike `requirement`, `dependsOn` rules **typically require explicit `questionId`s** because they define dependencies on *other* questions.

## 1. Simple Visibility

Show this question (or page) only if another question has been answered.

```yaml
dependsOn:
  exists: true
  questionId: 'other-question-id'
```

## 2. Value-Based Visibility

### A. Exact Match
Show only if specific value is selected.
```yaml
dependsOn:
  equals: 'Yes'
  questionId: 'has-pain'
```

### B. Multiple Valid Values
Show if the answer checks any of these boxes (for Checkbox/MultipleChoice).
```yaml
dependsOn:
  oneOf:
    - equals: 'Headache'
      questionId: 'symptoms'
    - equals: 'Nausea'
      questionId: 'symptoms'
```
*Alternatively, you can use regex if applicable, or just list multiple equals checks.*

### C. Regex Match
Show if the text answer matches a pattern.
```yaml
dependsOn:
  regex: '^(Yes|Maybe)$'
  questionId: 'user-response'
```

## 3. Complex Logic

### A. Multi-Question Dependency (AND)
Show only if **both** conditions are met.
```yaml
dependsOn:
  allOf:
    - exists: true
      questionId: 'consent'
    - equals: 'Female'
      questionId: 'biological-sex'
```

### B. Complex Groups (OR with Nested AND)
Show if Condition A is true **OR** (Condition B AND Condition C) are true.
```yaml
dependsOn:
  oneOf:
    - equals: 'Admin' # Condition A
      questionId: 'role'
    - allOf:          # Group B+C
        - equals: 'User'
          questionId: 'role'
        - exists: true
          questionId: 'beta-access-key'
```

## 4. Key Difference vs Requirement

While `requirement` often implies "check myself" (implicit ID), `dependsOn` is for "check others".
**Always specify `questionId` in `dependsOn` blocks.**
