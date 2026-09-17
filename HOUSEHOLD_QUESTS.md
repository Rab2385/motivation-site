# 🏠 Household Quests – Predefined Templates

## Overview
The Motivation app now seeds 10 predefined household quest templates on first run. These are designed for a single household and provide a balanced weekly schedule with clear difficulty levels and XP rewards.

---

## Daily Quests (7x per week)

### 1. **Geschirr spülen** (Wash Dishes)
- **XP**: 15
- **Difficulty**: Leicht (Easy)
- **Days**: Every day (Mon–Sun)
- **Note**: Küche sauber halten (Keep kitchen clean)
- **Rationale**: Daily maintenance task

### 2. **Küche aufräumen** (Tidy Kitchen)
- **XP**: 20
- **Difficulty**: Leicht (Easy)
- **Days**: Every day (Mon–Sun)
- **Note**: Oberflächen abwischen, Ordnung halten (Wipe surfaces, maintain order)
- **Rationale**: Daily upkeep

---

## 2x Per Week Quests

### 3. **Badezimmer putzen** (Clean Bathroom)
- **XP**: 35
- **Difficulty**: Mittel (Medium)
- **Days**: Tuesday, Friday
- **Note**: Fliesen, Spiegel, Toilette reinigen (Clean tiles, mirror, toilet)
- **Rationale**: Regular hygiene maintenance

### 4. **Zimmer staubsaugen** (Vacuum Rooms)
- **XP**: 30
- **Difficulty**: Mittel (Medium)
- **Days**: Wednesday, Saturday
- **Note**: Wohn- und Schlafzimmer absaugen (Vacuum living & bedroom)
- **Rationale**: Floor maintenance

### 5. **Wäsche waschen** (Do Laundry)
- **XP**: 40
- **Difficulty**: Mittel (Medium)
- **Days**: Tuesday, Saturday
- **Note**: Wäsche waschen, trocknen und falten (Wash, dry, fold)
- **Rationale**: Clothes care routine

---

## Weekly Quests

### 6. **Bettwäsche wechseln** (Change Bed Sheets)
- **XP**: 25
- **Difficulty**: Mittel (Medium)
- **Days**: Sunday
- **Note**: Betten frische Laken geben (Give beds fresh sheets)
- **Rationale**: Weekly hygiene essential

### 7. **Pflanzen gießen** (Water Plants)
- **XP**: 10
- **Difficulty**: Leicht (Easy)
- **Days**: Thursday
- **Note**: Alle Zimmerpflanzen gießen (Water all houseplants)
- **Rationale**: Plant care

### 8. **Möbel abstauben** (Dust Furniture)
- **XP**: 20
- **Difficulty**: Leicht (Easy)
- **Days**: Monday
- **Note**: Regal, Tische und Regale abstauben (Dust shelves, tables, racks)
- **Rationale**: Weekly dusting

### 9. **Wohnzimmer organisieren** (Organize Living Room)
- **XP**: 15
- **Difficulty**: Leicht (Easy)
- **Days**: Friday
- **Note**: Kissen, Decken, Gegenstände sortieren (Sort cushions, blankets, items)
- **Rationale**: Weekly tidying

---

## Bi-Weekly Quests

### 10. **Fenster putzen** (Clean Windows)
- **XP**: 50
- **Difficulty**: Schwer (Hard)
- **Days**: Sunday (manual every 2 weeks)
- **Note**: Fenster innen und außen reinigen (Clean windows inside & outside)
- **Rationale**: Less frequent but high-effort task

---

## 📊 Weekly XP Distribution

| Category | Frequency | XP Per Week |
|----------|-----------|-------------|
| Daily dishes | 7x | 105 XP |
| Daily kitchen | 7x | 140 XP |
| Bathroom | 2x | 70 XP |
| Vacuum | 2x | 60 XP |
| Laundry | 2x | 80 XP |
| Bed sheets | 1x | 25 XP |
| Plants | 1x | 10 XP |
| Dust furniture | 1x | 20 XP |
| Living room | 1x | 15 XP |
| Windows | ~0.5x | ~25 XP |
| **Total (weekly avg)** | - | **550 XP/week** |

---

## 🎮 Getting Started

1. **First Launch**: All 10 household quests will automatically appear in your definitions
2. **Day 1**: Tasks will materialize on their scheduled days
3. **Customize**: Edit, pause, or archive any quest that doesn't fit your schedule
4. **Difficulty**: Adjust XP values based on how long tasks actually take you

---

## ✏️ Customization Tips

- **Too easy?** Increase XP for completing it faster than expected
- **Too hard?** Reduce XP or change frequency to 1x/week
- **Wrong day?** Edit the recurrence rule (RecurrenceRule.fixedWeekdays)
- **Don't want it?** Archive the definition to hide it

---

## 🔄 Extending the System

You can add more predefined templates by:
1. Adding more `TaskDefinition` objects to `defaultHouseholdQuests()`
2. Creating separate methods like `defaultFitnessQuests()`, `defaultLearningQuests()`
3. Hooking them into the seeding logic in `MotivationController.initialize()`

---

Generated: 2026-09-14
