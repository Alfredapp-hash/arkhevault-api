# Feature & Component Disposition Matrix

Legend:

- **A — Preserve conceptually** → rebuild as web/API feature using workflow/fields as requirements  
- **B — Rewrite completely** → do not port implementation  
- **C — Design reference only** → intentions useful; code is not a security boundary  
- **D — Move server-side** → logic belongs in API/workers  
- **E — Defer** → after MVP / pilot protections  

---

## 1. Core services

| Component | Path | Disposition | Rationale |
|---|---|---|---|
| AuthenticationManager | `Core/Services/AuthenticationManager.swift` | **B** | Local Staff + SHA-256 + first-login accept + biometrics ≠ Entra |
| SessionManager | `Core/Services/SessionManager.swift` | **C → A (UX)** | Idle timeout UX may inspire web session UX; tokens from Entra |
| NetworkSecurityManager | `Core/Services/NetworkSecurityManager.swift` | **B/C** | Placeholder pins; replace with Azure private networking + standard TLS |
| RateLimiter | `Core/Services/RateLimiter.swift` | **D** | Edge/API rate limits, not client |
| SecurityEventLogger | `Core/Services/SecurityEventLogger.swift` | **D** | Server audit; local diagnostics optional only |
| AIService | `Core/Services/AIService.swift` | **B + E** | Remove client keys; AI deferred behind gateway |
| Configuration | `Core/Services/Configuration.swift` | **B** | Key Vault + App Config + env via managed identity |
| CoreDataController | `Core/Data/CoreDataController.swift` | **B** as SoT; optional later cache | Postgres is authoritative |
| Client+CoreData models | `Core/Data/Models/Client+CoreData.swift` | **A/D** | Domain helpers inform server rules |
| LoginView | `App/Views/LoginView.swift` | **C** | Entra-hosted login replaces form |
| MainWindow / App shell | `App/MainWindow.swift`, `App/ForgedInFireApp.swift` | **A** | Navigation IA for web shell |

---

## 2. Feature modules

| Module | Path | Disposition | Web destination | Notes |
|---|---|---|---|---|
| Dashboard | `Features/Dashboard/Views/DashboardView.swift` | **A** | Org dashboard | Replace sample metrics with tenant-scoped API |
| Client list / 360 | `Features/ClientManagement/Views/ClientListView.swift` | **A** | Clients | Global fetch → org-scoped search |
| Intake | `Features/ClientManagement/Views/IntakeSystemView.swift` | **A** | Intake workflow | Much is sample forms; extract field requirements |
| Notes | `Features/ClientManagement/Views/ClientNotesTab.swift` | **A + D** | Case notes | Visibility + AI enhance → server policy; AI deferred |
| Programs tab | `Features/ClientManagement/Views/ClientProgramsTab.swift` | **A** | Program enrollment | After MVP slice |
| Documents tab | `Features/ClientManagement/Views/ClientDocumentsTab.swift` | **B** storage, **A** UX | Documents | Encryption claims false; Blob pipeline |
| Timeline | `Features/ClientManagement/Views/ClientTimelineTab.swift` | **A** | Audited timeline | Server-derived events |
| Programs | `Features/ProgramManagement/Views/ProgramListView.swift` | **A** | Programs | |
| Safety | `Features/SafetyManagement/Views/SafetyDashboardView.swift` | **A + D** | Safety workspace | Phase 5; L4 controls |
| Tasks | `Features/TaskManagement/Views/TaskListView.swift` | **A** | Tasks | Include in vertical slice |
| Calendar | `Features/Calendar/Views/CalendarView.swift` | **A** | Appointments | EventKit optional later client nicety |
| Referrals | `Features/ReferralManagement/Views/ReferralListView.swift` | **A + D** | Referrals | Requires consent (Phase 5–6) |
| Reporting | `Features/Reporting/Views/ReportListView.swift` | **A + D** | Reports | Deidentified; Phase 7 |
| Safe house | `Features/SafeHouseManagement/Views/SafeHouseListView.swift` | **A + B security** | Restricted capacity | L4 confidential locations |
| Volunteers | `Features/VolunteerManagement/Views/VolunteerListView.swift` | **A** | Volunteers | Many simulated metrics |
| Offline | `Features/OfflineMode/Views/OfflineSettingsView.swift` | **B + E** | — | No full offline v1 |
| Notifications | `Features/Notifications/Views/NotificationSettingsView.swift` | **D** | Preferences UI later | Server-generated notifications |
| Analytics | `Features/Analytics/Views/AnalyticsSettingsView.swift` | **B/E** | — | No L3/L4 in product analytics |
| Document extraction | `Features/DocumentExtraction/Views/DocumentExtractionView.swift` | **E + D** | Later | OCR may stay client assist; persistence/policy server |
| Settings | `Features/Settings/Views/SettingsView.swift` | **B** account/security; **A** prefs | Org/user settings | Password UI removed |

---

## 3. Workflow → phase placement

| Workflow | Phase | Milestone |
|---|---|---|
| Entra login, org membership, roles | 2 | M2 |
| Client + case + assign + note + task + timeline + audit | 3–4 | M3 |
| Safety plans, consent, emergency access | 5 | M4 |
| Documents + referrals | 6 | M4 |
| Reports, org admin, feedback | 7 | M5 |
| Pen test, PIA, DR, signoff | 8 | M5 |

---

## 4. What must never ship from the prototype

1. Local password establishment / SHA-256 Keychain auth  
2. First-login “any password” behavior  
3. Biometric success as authorization without Entra  
4. Client-held Anthropic (or any LLM) API keys  
5. Core Data as authoritative multi-user store  
6. UI copy claiming encryption without cryptographic controls  
7. Local audit file as compliance evidence  
8. Placeholder certificate pins as “network security complete”  
9. Full offline organization database sync  
10. Prior SECURITY_AUDIT_REPORT “cleared for live testing” conclusion  

---

## 5. Requirements extraction priority (for X-1 agent)

1. ClientListView + IntakeSystemView  
2. ClientNotesTab + TaskListView  
3. SafetyDashboardView + SafeHouseListView (classification focus)  
4. ReferralListView + ClientDocumentsTab  
5. DashboardView + ReportListView  
6. Remaining modules  
