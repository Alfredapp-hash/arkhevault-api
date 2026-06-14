# Human Typer

A macOS app that types pasted text into any focused application at a **human pace** — with natural WPM variation, thinking pauses, typos, and self-corrections.

## Requirements

- macOS 14.0+
- Xcode 15+
- **Accessibility** permission

## Quick start

1. Open `HumanTyper/HumanTyper.xcodeproj` in Xcode → **Cmd+R**
2. Complete onboarding and grant **Accessibility**
3. Paste text, choose scope (**All**, **Selection**, **From Cursor**, or **Queue**)
4. Pick a document mode (**Essay**, **Email**, **Notes**, **Code**)
5. Click **Start** → switch to Word during countdown

## Features

### Typing scopes
| Scope | How |
|-------|-----|
| **All** | Types the full pasted text |
| **Selection** | Highlight text → type only that part |
| **From Cursor** | Place cursor (or highlight range) → type from there |
| **Queue** | Add multiple selections → type in order |

### Document modes
- **Essay** — full pauses, deep thought, paragraph arcs
- **Email** — shorter pauses, moderate speed
- **Notes** — fast, informal
- **Code** — steady bursts, fewer thinking breaks

### Natural typing
- Variable WPM waves, paragraph/sentence arcs
- Sentence & paragraph planning pauses
- Nearby-key typos, doubled letters, word revisions
- Structure-aware slowdown (headings, quotes, citations)
- Rare-word slowdown
- Paste fallback for unsupported characters

### Workflow tools
- **Dry run** — preview timing/events without keystrokes
- **Saved profiles** — Slow Essay, Quick Email, etc.
- **Run summary** — actual WPM, typos, pauses
- **History** — last 20 runs
- **Export log** — JSON or CSV
- **Menu bar** — status, dry-run toggle, stop
- **Pre-flight checklist** — permissions & focus warnings
- **Auto-focus Word** (optional)

### Keyboard shortcuts
| Shortcut | Action |
|----------|--------|
| ⌘↩ | Start |
| Esc | Stop |
| ⇧⌘V | Paste into source |

## Tests

Unit tests are in `HumanTyper/Tests/`. In Xcode: **File → New → Target → Unit Testing Bundle**, then add the test files to the target.

## Project structure

```
HumanTyper/
├── Models/           # Settings, profiles, history, preferences
├── Services/         # Typing engine, cadence, errors, focus, paste
├── Views/            # UI components
└── Tests/            # Unit tests
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Nothing types | Grant Accessibility; focus target app before countdown ends |
| Wrong characters | US QWERTY assumed; unsupported chars use paste fallback |
| Human Typer still frontmost | Switch to Word during countdown (warning banner shown) |

## License

Personal and development use.
