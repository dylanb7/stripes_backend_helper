# Modular Test Rewrite Checklist

This checklist outlines the step-by-step migration tasks to complete the YAML-driven, strategy-registered test engine rewrite across `stripes_backend_helper`, `stripes_prod`, and `stripes_ui`.

---

## Phase 1: Core Models & YAML Specification (`stripes_backend_helper`)

- [ ] **Data Model Verification** (`lib/RepositoryBase/ModularTestBase/test_definition.dart`)
  - [ ] Verify `@immutable` data models: `TestDefinition`, `TestStage`, `StageInjection`, `StageTrigger`, `ActiveTestProtocol`, `NotificationConfig`.
  - [ ] Ensure key fields use localization key naming conventions (`nameKey`, `instructionKey`, `titleKey`, `bodyKey`).
- [ ] **YAML Parsing Utility** (`lib/RepositoryBase/ModularTestBase/test_loader.dart`)
  - [ ] Confirm `loadTestDefinitionsFromYaml` parses `tests:` arrays from YAML strings into `List<TestDefinition>`.

---

## Phase 2: Engine & Trigger Strategy Registry (`stripes_backend_helper`)

- [ ] **Strategy Interface & Registry** (`lib/RepositoryBase/ModularTestBase/test_definition.dart`)
  - [ ] Verify `TestTriggerStrategy` signature:
    `shouldTrigger({required Entry currentResponse, required List<Entry> historicalResponses, required ActiveTestProtocol testState})`
  - [ ] Verify `TriggerRegistry` maps string keys to strategy implementations.
- [ ] **Execution Engine** (`lib/RepositoryBase/ModularTestBase/test_engine.dart`)
  - [ ] Confirm `DefaultTestEngine.processEntry` evaluates matching triggers against current and historical [`Entry`](file:///Users/dylanbaker/Desktop/Stripes Repos/stripes_backend_helper/lib/RepositoryBase/EntryBase/entry.dart) records.
  - [ ] Verify support for `TriggerAction.transition` and `TriggerAction.scheduleReview`.
  - [ ] Verify manual stage advancement API: `engine.advanceStage({required ActiveTestProtocol activeTest, String? targetStageId})`.
- [ ] **Repository Layer** (`lib/RepositoryBase/ModularTestBase/modular_test_base_repo.dart`)
  - [ ] Ensure `ModularTestsRepo` exposes `activeProtocols` reactive stream (`rxdart`).
  - [ ] Confirm `ModularTestsRepo.advanceStage()` persists state updates to `ActiveTestProtocolSource`.

---

## Phase 3: Dynamic Localizations (`stripes_prod`)

- [ ] **Translation Key Definitions** (`lib/assets/translations/en.json`)
  - [ ] Add test protocol name keys (e.g. `"test.blue_dye.name"`).
  - [ ] Add stage instruction keys (e.g. `"test.blue_dye.eat_meal.instruction"`, `"test.blue_dye.awaiting.instruction"`).
  - [ ] Add review notification keys (e.g. `"test.blue_dye.review.title"`, `"test.blue_dye.review.body"`).
- [ ] **Localization Resolver Verification**
  - [ ] Ensure `QuestionsLocalizationsDelegate` (or `DynamicContentLocalizations`) resolves dynamic test keys at runtime without requiring `gen-l10n` code-gen.

---

## Phase 4: Blue Dye Protocol & Production Integration (`stripes_prod`)

- [ ] **Protocol Asset** (`lib/assets/blue_dye_test.yaml`)
  - [ ] Ensure `blue_dye_test.yaml` is declared under `assets:` in `pubspec.yaml`.
  - [ ] Verify stage injection definitions for `category.Meal-Time` and `category.BM`.
- [ ] **Concrete Strategy Rules** (`lib/local_repos/blue_dye_modular_test.dart`)
  - [ ] Implement `BlueMealEatenRule` checking blue meal consumption.
  - [ ] Implement `FirstBrownAfterBlueRunRule` inspecting historical BM logs for blue-to-brown transit sequence.
- [ ] **Factory Setup** (`lib/local_repos/blue_dye_modular_test.dart`)
  - [ ] Verify `createBlueDyeModularTestRepo()` binds YAML definition, strategy registry, and `ActiveTestProtocolSource`.

---

## Phase 5: UI Layer Integration (`stripes_ui`)

- [ ] **Stage UI Registry**
  - [ ] Implement `StageUiRegistry` mapping stage IDs (`eat_meal`, `awaiting_transit`, `completed`) to custom Flutter widgets (e.g. `BlueMealInfoWidget`).
- [ ] **Generic Localized Fallback**
  - [ ] Implement `LocalizedDefaultStageCard` rendering `context.translate(stage.instructionKey)` and manual advance action buttons.
- [ ] **Test Screen Integration** (`lib/UI/Record/TestScreen/test_screen.dart`)
  - [ ] Update `TestScreen` to watch `activeTestProtocolsProvider` and delegate stage rendering to `StageUiRegistry.buildStage()`.

---

## Phase 6: Automated Testing & Verification

- [ ] Run `stripes_backend_helper` unit tests:
  ```bash
  flutter test test/modular_test_engine_test.dart
  ```
- [ ] Run `stripes_prod` unit tests:
  ```bash
  flutter test test/blue_dye_modular_test.dart
  ```
