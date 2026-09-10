# Quest – Architecture

Gamified, local-first habit tracker ("Quest") with a **Wochenplanung** (weekly
planning) feature. Flutter Web (also builds for Windows). No account, no
server, works fully offline. Persistence is Sembast over IndexedDB on web, a
file on native.

The visual direction is a dark "midnight fantasy" theme with parchment-gold
accents, a compass-rose mark, a painted mountain atmosphere (`AtmosphereBackground`,
`GoldRing`, `CompassMark` in `lib/theme/atmosphere.dart`) and motivational
German quotes (`lib/l10n/quotes.dart`). The Dart package is still `motivation`.

This document is the source of truth for the domain model and the rules that
were agreed during design. Implementation follows it; where code and doc
disagree, fix one of them deliberately.

---

## 1. Guiding decisions

| Area | Decision |
| --- | --- |
| Task model | **One unified task concept.** "Recurring" is a schedule attached to a definition; a one-off is just an occurrence with no definition. |
| Recurrence storage | Recurring definitions are **materialised** into concrete dated `TaskOccurrence` rows on a rolling ~14-day horizon. |
| Planner range | This week + next week only. |
| Week | Monday–Sunday, day boundary at local midnight, device local time. |
| De-duplication | **Structural, never text-matched** – you never re-type a recurring task, you attach the existing one. The *only* place normalised title matching runs is **week-template application**. |
| Streaks | Only recurring definitions have streaks. Grace = 1 forgiven miss. Planned skips are neutral. |
| XP | Manual, with a difficulty-derived default. Snapshotted at completion; editable with recalculation. |
| Past | Read-only. Completion only on the actual current day. (Exception: correcting a past completion's awarded XP.) |
| AI | V1 builds the **Proposal** seam and routes every mutation through `PlanService`. No provider, no keys, no network. |
| Language | German UI, English code/identifiers/commits. |

---

## 2. Domain model

All models live in `lib/models/`. Every model is immutable with
`fromMap` / `toMap` / `copyWith`, dates stored as ISO-8601, day keys as
`yyyy-MM-dd`.

### 2.1 `TaskCategory`
User-managed, seeded with defaults. `id`, `name`, `colorValue`,
`iconCodePoint`, `sortOrder`, `isArchived`.

### 2.2 `Difficulty` (enum, `lib/domain/difficulty.dart`)
`leicht`, `mittel`, `schwer`, `episch`. Each maps to a default XP
(`20 / 40 / 60 / 100`). Purely a starting point – the task's XP is an
independent stored integer once set.

### 2.3 `RecurrenceRule` (value object)
```
kind: fixedWeekdays | timesPerWeek
weekdays: Set<int>        // 1=Mon..7=Sun, used by fixedWeekdays
timesPerWeek: int?        // used by timesPerWeek
```

### 2.4 `TaskDefinition`
The template for a recurring task. Never rendered directly as a quest.
`id`, `title`, `note`, `categoryId`, `difficulty?`, `xp`,
`recurrence: RecurrenceRule`, `createdAt`, `updatedAt`,
`isPaused`, `isArchived`.

### 2.5 `TaskOccurrence`
A concrete task on one date – the thing shown as a quest.
```
id
date                 // yyyy-MM-dd
title, note, categoryId, difficulty?, xp
sourceDefinitionId?  // null => pure one-off
origin               // oneOff | recurring | quota  (quota = placed from an X/week chip)
isForked             // occurrence overrides its definition; stop tracking edits
isSkipped            // planned skip (recurring only); streak-neutral, no XP
createdAt, updatedAt
completion: Completion?
```

### 2.6 `Completion` (embedded in `TaskOccurrence`)
`completedAt`, `awardedXp` (snapshot), `note?`, `fraction` (1.0 = full).
`fraction < 1.0` ⇒ XP pro-rated, **does not** count for streak/quota.

### 2.7 `WeekTemplate`
`id`, `name`, `entries: [{weekday, title, note, categoryId, difficulty?, xp}]`.

### 2.8 `Proposal` (AI seam – see §6)
`id`, `createdAt`, `source`, `rationale`, `status`,
`operations: List<PlanOperation>`.

### 2.8a `Reward` (`lib/models/reward.dart`)
A self-chosen treat that unlocks at a level. `id`, `title`, `description`,
`iconKey`, `requiredLevel`, `redeemedCount`, `lastRedeemedAt`, `createdAt`.
Unlocked when `currentLevel >= requiredLevel`. Redeeming has **no XP cost** –
it just records that the user took the break (`redeemedCount++`). Seeded with
five defaults on first run (`rewardsSeeded` settings flag). CRUD +
`redeemReward` go through `PlanService`; the controller emits a toast when a
reward crosses its unlock level.

### 2.9 `Achievement` unlock
`achievementId`, `unlockedAt`. Definitions are code, unlocks are data.

---

## 3. Persistence (`lib/data/`)

`MotivationDatabase` wraps Sembast. Stores:

| Store | Key | Value |
| --- | --- | --- |
| `categories` | id | category map |
| `task_definitions` | id | definition map |
| `occurrences` | id | occurrence map (includes completion) |
| `week_templates` | id | template map |
| `proposals` | id | proposal map |
| `achievement_unlocks` | achievementId | `{unlockedAt}` |
| `settings` | key | scalar |
| `meta` | `horizonMaterialisedThrough` | yyyy-MM-dd |

Platform open is selected by conditional import
(`database_open_io.dart` / `database_open_web.dart`), identical pattern to the
Lighthouse project.

Backup: `BackupService` serialises every store into one versioned JSON
document (`formatVersion`, `appVersion`, `createdAt`, `data`). Import
validates the envelope, writes a safety backup to `settings`, then replaces
all stores in a transaction.

---

## 4. `PlanService` – the single write path

Every mutation to tasks, occurrences, completions and templates goes through
`PlanService`. The UI never touches `MotivationDatabase` for writes. This is
what lets a future AI be given the same surface without new authority.

Key methods (all return the changed rows so the controller can update state):

- `addOneOff({date, title, ...})`
- `createRecurring({..., recurrence})`
- `attachDefinitionToDate({definitionId, date, scope})` – `scope` =
  `thisDateOnly` \| `everyWeekdayFromNow`
- `skipOccurrence(occurrenceId)` / `unskipOccurrence(occurrenceId)`
- `editOccurrence(occurrenceId, patch)` – sets `isForked = true`
- `editDefinition(definitionId, patch)` – re-derives non-forked future
  occurrences on next materialise
- `moveOccurrence(occurrenceId, toDate)` – recurring ⇒ skip source +
  detached one-off on target; one-off ⇒ change date
- `copyOccurrence(occurrenceId, toDate)` – always a detached one-off
- `complete(occurrenceId, {fraction, note})` / `undoComplete`
- `editAwardedXp(occurrenceId, xp)` – past-completion correction, triggers recalc
- `placeQuotaOccurrence({definitionId, date})`
- `applyTemplate(templateId, weekStart)` – **the one title-dedup site**
- `apply(Proposal)` – executes an approved proposal's operations

### 4.1 Materialisation
`MaterialisationService.run(now)` – idempotent, called on startup and after
any definition edit / date rollover:

1. Horizon = `today .. today + 14d`.
2. For each active, non-paused `fixedWeekdays` definition and each matching
   date in the horizon: ensure an occurrence with `sourceDefinitionId`.
   - none ⇒ create from definition (`isForked = false`)
   - exists, not forked, not completed, date ≥ today ⇒ refresh
     title/note/xp/category/difficulty from definition
   - forked / completed / skipped / past ⇒ leave alone
3. `timesPerWeek` definitions are **not** auto-dated. They surface as planner
   chips; the user places occurrences with `placeQuotaOccurrence`.
4. Remove *future*, non-forked, non-completed, non-skipped occurrences whose
   definition no longer schedules that date (e.g. weekday removed).

---

## 5. Derived domain logic (`lib/domain/`)

Pure functions over the loaded lists – no I/O, fully unit-tested.

### 5.1 Progression (`progression.dart`)
`totalXp` = Σ `awardedXp` of all completions **plus** the perfect-day bonus
for every perfect day (see 5.6). Level curve: cumulative XP to *reach* level
`L` is `25 * (L - 1) * (L + 2)`, scaled by the `LevelCurve` setting
(`sanft` ×0.7 / `standard` ×1.0 / `steil` ×1.4).

### 5.2 Streaks (`streaks.dart`) – recurring definitions only
- **fixedWeekdays**: walk scheduled dates backward from the most recent past
  scheduled date. `completed` or `isSkipped` ⇒ continue. `missed` ⇒ consume
  1-miss grace; a second consecutive missed scheduled date breaks it. Today
  and future don't break, they're "offen".
- **timesPerWeek**: walk ISO weeks backward. Week with `≥ target` full
  completions ⇒ continue. One short week is forgiven; two consecutive short
  weeks break. Current week is "in progress".

### 5.3 Workload (`workload.dart`)
Per weekday target XP from settings (`dayTargetXp[1..7]`, default
Mon–Fri 150 / Sat–Sun 80). `plannedXp(date)` = Σ xp of that day's
non-skipped occurrences. `load = plannedXp / target`. Bands:
`≤ 0.85 ok`, `≤ 1.1 voll`, `> 1.1 überladen`. Overload ⇒ a dismissible
rule-based hint suggesting the lightest day in the same week.

### 5.4 Achievements (`achievements.dart`)
Static list of `AchievementDefinition { id, title, description, icon,
test(StatsSnapshot) }`. `AchievementEngine.evaluate(snapshot)` returns newly
satisfied ids; controller persists unlocks and shows a toast. ~12 to start
(first quest, perfect day, 7/30-day streak, level 5/10, 1000/10000 XP,
whole week planned, five categories used, …).

### 5.5 Statistics (`statistics.dart`)
`buildStatsSnapshot` (dashboard + achievements) and `computePeriodStats`
(Statistik page: Woche/Monat/Jahr/Alle Zeit — task/XP totals, week-over-week
deltas, completion-rate donut, bar chart, weekly overview).

### 5.6 Gamification settings (Einstellungen → Gamification)
Persisted as individual `settings` keys, exposed by the controller and
threaded into the domain functions:

| Setting | Effect |
| --- | --- |
| `xpMultiplier` (0.1–5.0) | `awardedXp = round(taskXp × fraction × multiplier)` at completion (snapshot). |
| `levelCurve` | scales the whole XP→level curve. |
| `perfectDayBonus` (0–500, dflt 50) | added to `totalXp` / `xpByDay` for each **perfect day** (≥1 real completion, nothing left open). A toast fires the moment today turns perfect. |
| `streakProtection` (dflt on) | grace limit for `computeStreak` — on = 1 forgiven miss, off = 0. |
| `dailyReminder` + `reminderTime`, `motivationMessages`, `showAtmosphere` | UI-only prefs. Web notification *delivery* is not implemented — the preference is stored and labelled as such. |

---

## 6. AI seam (build the boundary, not the AI)

V1 ships:

- `Proposal` / `PlanOperation` types (`lib/models/proposal.dart`).
- `PlanService.apply(Proposal)` and `rejectProposal`.
- `ProposalReviewSheet` – renders a proposal's operations as a human-readable
  diff (added / edited / moved / removed quests, XP deltas) with
  **Übernehmen** / **Verwerfen**.
- `AssistantGateway` abstract interface with **no implementation**:
  ```
  abstract class AssistantGateway {
    Future<Proposal> planWeek(PlanContext context, String naturalLanguage);
    Future<List<XpSuggestion>> suggestXp(List<DraftTask> drafts);
    Future<String> weeklyReflection(StatsSnapshot snapshot);
  }
  ```

Rules encoded by the architecture:

- Only non-user actors create `Proposal`s. The user's direct edits apply
  immediately (with undo).
- An `AssistantGateway` can only produce `Proposal`s; it has no reference to
  `MotivationDatabase` and cannot call the mutating `PlanService` methods.
- Nothing is persisted from a proposal until `apply` runs after explicit
  user approval.
- No API key ships in the client. A real gateway will call a thin backend
  proxy that holds the key; that backend is out of scope for V1 and the core
  app must never depend on it.

---

## 7. State & UI

`MotivationController extends ChangeNotifier` is the single in-memory hub
(same pattern as Lighthouse). Holds the loaded lists, exposes read selectors
that call into `lib/domain/`, and forwards writes to `PlanService` then
updates its lists.

Navigation (`MotivationShell`): NavigationRail on wide, NavigationBar on
narrow. Destinations:

| DE label | Route content |
| --- | --- |
| Dashboard | greeting + date + quote; hero card (level ring, XP bar, streak/total/encouragement chips, mountain atmosphere); "Heutige Aufgaben" card with per-row motivational subtitle and a "Heute verdient / perfekte Tagesbilanz" footer; "Freigeschaltete Belohnungen" card; "Wochenfortschritt" card (7-day bars + tasks/XP/streak mini-stats with week-over-week deltas) |
| Heute | focused quest list for today, tap-to-complete with optional note/amount |
| Wochenplanung | two-week board, per-day planned XP + workload bar, add/attach/copy/move, quota chips, template save/apply |
| Gewohnheiten | recurring definitions: schedule, current/best streak, completion rate, pause/archive |
| Belohnungen | reward grid, redeem when unlocked, add/edit; level-gated with progress bars |
| Statistik | core charts |
| Erfolge | achievement grid |
| Einstellungen | day targets, categories, backup export/import, clear data |

Quest list order everywhere: incomplete first → category sort order → XP
desc; completed collapse to the bottom.

Visual direction: playful gamified – XP bars, level badges, quest cards,
category colour accents, celebratory feedback on completion and unlocks.

---

## 8. Testing

`test/` mirrors `lib/domain/` and the services. Priority coverage:

- materialisation idempotency + weekday add/remove
- structural de-dup (attach vs create) and the template title-dedup exception
- move/copy/skip/fork occurrence semantics
- streak grace logic for both recurrence kinds
- progression curve boundaries
- workload bands
- achievement engine
- backup round-trip
- `PlanService.apply(Proposal)` for every `PlanOperation` kind
