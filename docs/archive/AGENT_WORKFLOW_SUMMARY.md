# Agent Operations Guide for Sike

## Core Philosophy: Concise & Spec-Driven

**1. Be Concise:**
*   **Chat:** Short, direct answers. No fluff.
*   **Docs:** Bullet points, clear headers, minimal prose.

**2. Spec-Driven Development:**
*   Code follows specs. Specs live in `docs/`.
*   Never write code without a plan.

## Workflow

### 1. Plan (Spec)
*   **Check Version:** `docs/versions/vX.Y.Z/`.
*   **Define:** Create/Update `0 - REQUIREMENTS.md`.
*   **Design:** Create `1 - PLAN.md` (Files, Complexity, Verification).

### 2. Execute (Code)
*   **Log:** Update `2 - CHANGES.md` with every meaningful change.
*   **Format:** `[Type] Description (File: path)`.
*   **Pattern:** UI -> Provider -> Service -> Hive.

### 3. Finalize (Doc)
*   **Document:** Create `3 - UPDATES.md`.
*   **Verify:** Run tests.

## Architecture Rules

*   **State:** `Provider` only.
*   **Data:** `Hive` only.
*   **UI:** Material Design 3.
*   **Async:** Always `await`.

## Key Paths

*   `docs/`: Source of truth.
*   `lib/providers/`: Logic.
*   `lib/services/`: Data.
*   `lib/models/`: Structure.

## Commands

*   **Gen:** `flutter pub run build_runner build --delete-conflicting-outputs`
*   **Test:** `flutter test`
*   **Fmt:** `dart format .`
