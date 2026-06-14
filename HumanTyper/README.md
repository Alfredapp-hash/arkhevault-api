# Human Typer

A simple macOS app that types pasted text into any focused application (Microsoft Word, Notes, a browser, etc.) at a human pace, with natural timing variation and occasional typos that get corrected.

## Requirements

- macOS 14.0 or later
- Xcode 15 or later (to build)
- **Accessibility** permission (required for keyboard simulation)

## Build

1. Open `HumanTyper/HumanTyper.xcodeproj` in Xcode.
2. Select the **HumanTyper** scheme and your Mac as the run destination.
3. Press **Cmd+R** to build and run.

## First-time setup: Accessibility

Human Typer uses macOS `CGEvent` to simulate keystrokes. Without Accessibility access, keystrokes are silently dropped.

1. Launch Human Typer.
2. If you see the orange banner, click **Open Settings**.
3. In **System Settings → Privacy & Security → Accessibility**, enable **Human Typer**.
4. If prompted on first launch, allow the app to control your computer.

You can also trigger the system prompt by clicking **Start** — macOS may open the Accessibility pane automatically.

## Usage

1. **Paste** your text into the **Source text** field.
2. Adjust **Speed** (WPM), **Error rate**, and **Countdown** if desired.
   - Default speed: 65 WPM
   - Default error rate: 2% (nearby-key typos with backspace correction)
   - Default countdown: 5 seconds
3. Click **Start**.
4. During the countdown, **click into your target app** (e.g. a Word document).
5. Human Typer types the text into whatever field is focused.
6. Click **Stop** at any time to cancel.

## How it works

Human Typer models **long-form writing** — the way someone types a letter or essay, not robotic constant-speed input.

### Natural writing rhythm

| Behavior | What happens |
|----------|----------------|
| **Opening hesitation** | 1–2 second pause before the first character — "how do I begin?" |
| **Flow bursts** | After finishing a thought, types faster for a short stretch when the words come easily |
| **Sentence pauses** | 0.5–1.3s after `.` `!` `?` while planning the next sentence |
| **Deep thought** | Every 2–5 sentences, a longer 1–3s pause as if re-reading or planning |
| **Clause pauses** | Brief hesitations after `,` `;` `:` while choosing phrasing |
| **Paragraph breaks** | 1.4–3.8s pause before starting a new paragraph (after blank line) |
| **Word-search pauses** | Occasional 0.2–1s gaps between words when "finding" the right word |
| **Long words** | Slightly slower keystrokes on longer or uncommon words |
| **Fatigue** | Very subtle slowdown on very long documents (1,200+ characters) |
| **Typos** | Nearby-key mistakes with backspace correction at your error rate |

### Timing engine

- Variable per-keystroke delays with log-normal jitter
- Faster common letter pairs (`th`, `er`, `in`, etc.)
- Estimated duration in the UI accounts for sentence, paragraph, and thinking pauses

## Keyboard layout

This version assumes a **US QWERTY** keyboard layout. Non-US layouts may produce incorrect characters for some symbols.

## Troubleshooting

| Problem | Fix |
|--------|-----|
| Nothing appears in Word | Confirm Accessibility is enabled and Word’s text cursor is active before the countdown ends |
| Characters dropped | Lower the WPM slider slightly |
| Start button disabled | Paste text and grant Accessibility access |
| Wrong characters | Check that your Mac keyboard layout is US QWERTY |

## Project structure

```
HumanTyper/
├── HumanTyperApp.swift
├── Views/
│   ├── ContentView.swift
│   ├── Theme/AppTheme.swift
│   └── Components/
│       ├── AppBackgroundView.swift
│       ├── AppHeaderView.swift
│       ├── AccessibilityBannerView.swift
│       ├── SourceTextEditorView.swift
│       ├── PremiumSliderControl.swift
│       ├── CountdownRingView.swift
│       ├── StatusIndicatorView.swift
│       └── ControlsPanelView.swift
├── Services/
│   ├── AccessibilityChecker.swift
│   ├── KeyboardSimulator.swift
│   ├── HumanTypingEngine.swift
│   └── NaturalWritingCadence.swift
├── Models/TypingSettings.swift
└── Info.plist
```

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘↩ | Start typing |
| Esc | Stop |
| ⇧⌘V | Paste into source field |

## License

For personal and development use.
