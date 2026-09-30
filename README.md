# LINE Rich Menu — Mobile

SwiftUI app for **LINE Rich Menu** — design a 6-slot LINE rich menu and export its JSON.

Part of [Chaowalit Greepoke](https://bookchaowalit.com)'s 101 Portfolio Projects.

## Status

This is a Swift package, not yet a shippable app:

- `Sources/LinerichmenuCore` — Foundation-only domain logic, unit-tested in
  `Tests/LinerichmenuCoreTests` (XCTest).
- `Sources/LinerichmenuUI` — SwiftUI tab shell (Home / Explore / Profile). It does not
  use `LinerichmenuCore` yet, and there is no Xcode app target (`@main`) yet.

The code has **not been compiled outside CI** (it was written without a Swift
toolchain); the macOS CI job is the first real build. See
[docs/UPGRADE-PLAN.md](docs/UPGRADE-PLAN.md).

## Core features (`LinerichmenuCore`)

- Slot shorthand parsing shared with the web app: `https://`, `http://`, `tel:`, `line://` → `uri`; `text:<message>` → `message`; `postback:<data>` → `postback`
- 3 × 2 grid bounds that exactly tile the 2500 × 1686 image
- Validation against LINE limits (name ≤ 300, chat bar text ≤ 14, URI ≤ 1000, message/postback ≤ 300) with per-slot messages
- Stable (sorted-key) rich menu JSON export that refuses to emit an invalid payload

## Tech Stack

- **UI:** SwiftUI (iOS 17+ / macOS 14+)
- **Language:** Swift 5.10
- **Tests:** XCTest via SwiftPM

## Getting Started

```bash
swift build
swift test          # runs LinerichmenuCoreTests
open Package.swift  # opens in Xcode 15+
```

CI (`.github/workflows/build.yml`, macOS 14) runs `swift build` and
`swift test`; failures fail the workflow.

## Related

- **Frontend:** [bookchaowalit-website/linerichmenu-frontend](https://github.com/bookchaowalit-website/bookchaowalit-linerichmenu-frontend)
- **Portfolio:** [bookchaowalit.com](https://bookchaowalit.com)

## License

MIT
