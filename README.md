# Quest

A local-first, gamified habit tracker with a terminal look. Track daily
habits and routines, plan your week, earn XP and streaks, and see your
progress as a contribution heatmap.

- **Local-first:** no account, no server. Everything is stored on your
  device (IndexedDB in the browser, a file on Windows) and works offline.
- **Habits & routines:** one-off tasks, recurring habits (fixed weekdays or
  _n_ times a week), quantity targets, sections like morning / deep work.
- **Planner:** this week and next, with a reusable standard week.
- **Progress:** XP, levels, streaks with one forgiven miss, achievements,
  weekly review, life grid with milestones.

## Run it

Requires the Flutter SDK (Dart `^3.12.2`).

```sh
flutter pub get
flutter run -d chrome        # web
flutter run -d windows       # Windows desktop
flutter test                 # tests
```

Build for the web with `flutter build web` and serve `build/web/` from any
static host. Installed from the browser, it runs as a standalone app.

## Your data and backups

Your habits live only on the device you use. In the browser, clearing site
data (or the browser freeing up space) deletes them. To stay safe:

- **system → data → download** saves a dated `quest-backup-YYYY-MM-DD.json`.
- Home shows a reminder when your last backup is older than the interval
  you choose (weekly by default).
- On the web, **system → data → persistent storage → request** asks the
  browser not to clear your data.
- **import backup** restores a backup by pasting its JSON. Your current
  data is replaced (a safety copy is kept internally).

## Project layout

```
lib/
  app/        MaterialApp setup
  data/       Sembast database (web + native)
  domain/     pure logic: streaks, progression, stats, workload, backup reminder
  models/     immutable data classes
  pages/      screens
  services/   PlanService (single write path), materialisation, backup
  state/      MotivationController (in-memory hub)
  theme/      terminal theme
  widgets/    shared widgets
docs/
  architecture.md   domain model and design decisions
  mockups/          UI suggestion mockups
```

See [`docs/architecture.md`](docs/architecture.md) for the domain model and
the rules behind it.
