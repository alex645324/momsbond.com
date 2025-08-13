# PROJECT\_UPDATE\_PLAN.md

This document is the **single source of truth** for the update. It encodes the rules, scope, exact copy, file touch-points, and the step-by-step **confirmation protocol** the developer must follow. There is **no room for assumptions**.

---

## 0) Guiding Rules (must be enforced in every step)

* **Bare minimum only.** Remove scope until it breaks; add back only what's necessary.
* **MVVM, simplest possible.** No extra layers; avoid third-party deps if at all possible.
* **Confirm before coding each step.** Post a "Step N — Plan to implement" (see template) and wait for **"Approved"** before writing code.

### Confirmation Template (use verbatim)

**"Step N — Plan to implement:"**

* Files to add/edit (exact paths)
* Data structures / functions (names + signatures)
* What will be included
* What will **not** be included
* Test cases to run (exact steps)

Wait for "**Approved**". Only then implement. Repeat every step.

---

## 1) Scope (what changes vs. what stays)

### In-scope (required)

1. **Stage labels (UI text only)**
2. **Challenge questions (UI text only; same 3 questions for all stages)**
3. **Chat starter text (UI text only)**
4. **Typing indicator** (minimal, iMessage-like: show "typing…" when peer is typing)

### Out-of-scope (must not change)

* Data models that drive matching logic
* Matching, onboarding, auth, and chat business logic (except minimal fields/events to support typing indicator)
* Navigation flows
* Third-party packages

---

## 2) Source of Truth for Text (hard requirements)

All user-facing strings live in `lib/config/app_config.dart` inside **`AppTexts`** / **`AppTextsEs`**.
Do **not** hardcode strings in views.

### 2.1 Stage Selection — exact labels

Replace current options with these **exact** labels:

* **"Newborn stage (0–3 months)"**
* **"Infant stage (3–12 months)"**
* **"Toddler stage (1–3 years)"**
* **"Preschool & Early School-age (3–6 years)"**
* **"Older Kids (6+ years)"**

> If Spanish is supported via `AppTextsEs`, mirror these labels accurately (developer to provide faithful translations **after approval**).

### 2.2 Challenge Questions — same 3, across all stages

Replace **all existing challenge question variants** with **this single set** (use everywhere questions are shown):

1. "Since giving birth, do you feel people care more about the baby than about you?"
2. "Do you feel like you can't be fully honest about how you're doing without being judged?"
3. "Have you lost friends or connections since becoming a mom?"

### 2.3 Chat Starter (prewritten)

Replace with this **exact** text:

> "Since becoming a mom, I feel like I've disappeared from my own story. Everyone asks about the baby, but no one asks about me. I've been…"

---

## 3) Typing Indicator — minimal design

**Goal:** Show a subtle "typing…" indicator when the **other** user is actively typing, similar to iMessage at a simple level.

**Constraints:**

* No third-party packages.
* Minimal Firestore writes.
* No breaking changes to existing chat schema/logic.

**Approach (bare-minimum):**

* **Write:** Each client toggles a **volatile** typing signal in Firestore while user is typing.
* **Read:** The peer listens and shows "typing…" if the signal is "fresh".

**Data (additions only):**

* In each conversation document (existing collection), add a **`typing`** map:

  ```json
  typing: {
    "<userId>": {
      "isTyping": true/false,
      "updatedAt": <serverTimestamp>
    }
  }
  ```
* Do **not** alter existing fields; **only** add `typing`.

**Client behavior:**

* On input change: set `isTyping = true`, `updatedAt = serverTimestamp()` **debounced** (e.g., fire after 300–500ms idle).
* On input blur / send / idle timeout (e.g., 3s without keystrokes): set `isTyping = false` (best effort; if missed, the freshness rule below will clear it).
* **Freshness rule:** Consider a peer as typing if `isTyping == true` **and** `now - updatedAt < 4s`. UI hides indicator otherwise (prevents stuck "typing…").

**UI:**

* Single line text "typing…" below the last message, aligned left, small, secondary color. No avatars, no animation.

---

## 4) Expected Touch-Points (paths to edit)

> If file names differ in your repo, locate by symbol/strings and list the **actual** paths in your Step-1 plan before coding.

* `lib/config/app_config.dart` — Add/modify stage labels, challenge questions, and chat starter in `AppTexts` (+ `AppTextsEs` if present).
* `lib/views/stage_selection_view.dart` — Use new stage labels from `AppTexts`.
* `lib/views/challenges_view.dart` — Render the **same 3** questions from `AppTexts`.
* `lib/views/chat_view.dart` — Replace starter text; wire typing indicator.
* `lib/viewmodels/chat_view_model.dart` — Minimal methods to set/unset typing with debounce; expose `isPeerTyping` derived from Firestore snapshot data.
* `lib/Database_logic/simple_chat_service.dart` or existing chat service — Minimal Firestore reads/writes for `typing` map.

---

## 5) Tests (must be listed per step)

* **Config tests:** Assert `AppTexts` contains the new labels, 3 questions, and chat starter.
* **UI smoke tests:** Stage selection shows the 5 exact labels; challenges view shows the 3 exact questions irrespective of stage.
* **Typing indicator tests:**

  * When local user types, write occurs (debounced).
  * When remote `typing.<peerId>.isTyping=true` with fresh `updatedAt`, indicator visible.
  * Indicator clears after 4s freshness window or when remote sets `false`.

---

## 6) Step-by-Step Plan (use the protocol at each step)

### Step 1 — Wire text constants

* **Edit** `lib/config/app_config.dart` (`AppTexts`, `AppTextsEs`).
* Add the 5 stage labels, 3 questions (single source), and chat starter.
* **What not to do:** No view edits yet. No hardcoding anywhere.

**Tests:** Config assertions for exact strings.

### Step 2 — Stage Selection uses new labels

* **Edit** `lib/views/stage_selection_view.dart` to consume `AppTexts.stageLabels` (or equivalent).
* Ensure **only** labels change; selection behavior unchanged.

**Tests:** UI shows 5 exact labels.

### Step 3 — Challenges view shows the same 3 questions for all stages

* **Edit** `lib/views/challenges_view.dart` to always render `AppTexts.sharedChallengeQuestions`.
* Remove any branching by stage **in the view** (do not touch matching logic).

**Tests:** UI shows the same 3 questions after any stage selection.

### Step 4 — Chat starter text

* **Edit** `lib/views/chat_view.dart` to render `AppTexts.chatStarter`.
* **What not to do:** No change to send logic or timers.

**Tests:** Starter matches exactly.

### Step 5 — Typing indicator (service + VM)

* **Edit/Add minimal:**

  * Chat service: `setTyping(conversationId, userId, isTyping)` and listener that yields peer typing state.
  * VM: debounce input changes; expose `isPeerTyping`.

**Tests:** Local writes debounced; listener computes `isPeerTyping` using freshness rule.

### Step 6 — Typing indicator (UI)

* **Edit** `lib/views/chat_view.dart`: show "typing…" line when `isPeerTyping` true.
* **What not to do:** No extra UI chrome or animations.

**Tests:** Indicator visibility toggles with mock VM state and timestamp freshness.

---

## 7) Developer workflow (repeat per step)

1. Post the **confirmation template** for the step.
2. Wait for **"Approved."**
3. Implement exactly what was approved.
4. Run the listed tests and report results.
5. Proceed to the next step.

---

## 8) Exact strings (copy/paste payload)

```dart
// lib/config/app_config.dart (AppTexts)
class AppTexts {
  // Stage labels
  static const String stageNewborn = 'Newborn stage (0–3 months)';
  static const String stageInfant = 'Infant stage (3–12 months)';
  static const String stageToddler = 'Toddler stage (1–3 years)';
  static const String stagePreschool = 'Preschool & Early School-age (3–6 years)';
  static const String stageOlderKids = 'Older Kids (6+ years)';

  static const List<String> stageLabels = [
    stageNewborn,
    stageInfant,
    stageToddler,
    stagePreschool,
    stageOlderKids,
  ];

  // Challenges (same 3 everywhere)
  static const List<String> sharedChallengeQuestions = [
    'Since giving birth, do you feel people care more about the baby than about you?',
    'Do you feel like you can't be fully honest about how you're doing without being judged?',
    'Have you lost friends or connections since becoming a mom?',
  ];

  // Chat starter
  static const String chatStarter =
    'Since becoming a mom, I feel like I've disappeared from my own story. Everyone asks about the baby, but no one asks about me. I've been…';
}
```

> If `AppTextsEs` exists, mirror the same keys with Spanish strings (submit as a separate **Step N** for approval).

---

## 9) Minimal Firestore API (typing)

```dart
// Pseudocode signatures — keep minimal
Future<void> setTyping({
  required String conversationId,
  required String userId,
  required bool isTyping,
});

Stream<bool> watchPeerTyping({
  required String conversationId,
  required String peerUserId,
  Duration freshness = const Duration(seconds: 4),
});
```

* Writes to `conversations/{id}`: `typing.{userId} = { isTyping, updatedAt: FieldValue.serverTimestamp() }`
* Reader computes freshness with server timestamp.

---

## 10) Acceptance checklist

* [ ] Stage labels appear exactly as specified (5 labels)
* [ ] Challenges show the **same 3** questions for any stage
* [ ] Chat starter matches exactly
* [ ] Typing indicator appears only while peer is actively typing (≤4s freshness) and disappears reliably
* [ ] No third-party deps added
* [ ] No matching/auth/chat core logic changed (beyond minimal typing fields)
* [ ] All strings centralized in `AppTexts` (+ `AppTextsEs` if applicable)

---

**End of document.**
Begin with **Step 1 — Plan to implement** using the template.