# Human Typer

A simple macOS app that types pasted text into any focused application (Microsoft Word, Notes, a browser, etc.) at a human pace, with natural timing variation and occasional typos that get corrected.

## Requirements

- macOS 13.0 or later
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

- **Timing:** Variable delays based on words-per-minute, with jitter, slower punctuation pauses, faster common letter pairs, and occasional “thinking” pauses every ~12 words.
- **Errors:** At the configured rate, a nearby QWERTY key is typed instead, followed by a short pause, backspace, and the correct character.
- **Target:** Any app with a focused text field — no special Word integration required.

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
├── Views/ContentView.swift
├── Services/
│   ├── AccessibilityChecker.swift
│   ├── KeyboardSimulator.swift
│   └── HumanTypingEngine.swift
├── Models/TypingSettings.swift
└── Info.plist
```

## License

For personal and development use.
