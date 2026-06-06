# Arkhe Vault — Code-Level Security Audit

**Repository:** `arkhevault-api` (this workspace)
**Target:** `ForgedInFireClientManager.xcodeproj` — native macOS/iOS app, SwiftUI + Core Data (~21k LOC Swift)
**Audit type:** White-box source review (file/line level)
**Date:** 2026-06-06
**Standards referenced:** HIPAA Security Rule (45 CFR §164.308/310/312), NIST SP 800-66r2, OWASP ASVS 4.0 L2/L3, NIST SP 800-63B, 42 CFR Part 2, VAWA/VOCA confidentiality, WCAG 2.2 AA.

> This supersedes the in-repo `SECURITY_AUDIT_REPORT.md`, which concludes "**CLEARED FOR LIVE TESTING / APPROVED FOR LIVE TESTING**." That conclusion is **not supportable**. Several of the "fixes" it claims are either non-functional, actively insecure, or prevent the project from compiling. See finding C-1, C-6, H-2, and M-7.

---

## 0. Architecture reality vs. the planning audit

The preliminary product audit assumed a multi-tenant **web** stack (React, Supabase/Prisma, API routes, RLS). The actual code is a **single-binary native desktop/mobile app** backed by a **local Core Data (SQLite) store**. This materially changes the threat model:

- There is **no server-side authorization boundary**. All "access control" runs in the same process as the user and on a database file the user can read directly. Anything described below as "enforced in the app" can be bypassed by opening the SQLite file.
- There is **no `Organization` entity and no `organization_id`** anywhere in the data model (`Core/Data/ForgedInFireDataModel.xcdatamodeld/contents`). The SaaS/multi-tenant claims in the business docs have **no implementation**. Tenant isolation testing is therefore N/A for the current build and a **green-field requirement** for any hosted version.
- PHI lives **unencrypted on local disk** (see C-5).

Net: the current architecture is closer to a local case-management tool than a HIPAA-eligible SaaS. Marketing it as multi-tenant or "HIPAA compliant" today is unsupportable.

---

## 1. Severity summary

| ID | Severity | Finding | Primary location |
|----|----------|---------|------------------|
| C-1 | Critical | Authentication bypass via trust-on-first-use; any password accepted | `Core/Services/AuthenticationManager.swift:71-80`, `36` |
| C-2 | Critical | Fast unsalted-per-user SHA-256 password hashing; force-unwrapped salt | `AuthenticationManager.swift:64-69` |
| C-3 | Critical | Audit attribution is forged: `currentUser = Staff.fetchAll().first` | 10 sites across 7 files |
| C-4 | Critical | No authorization layer; confidentiality is a UI filter only | repo-wide; `ClientNotesTab.swift:87-89`, `ClientDocumentsTab.swift:117/251` |
| C-5 | Critical | No encryption at rest; no file protection/sandbox/hardened runtime | `Core/Data/CoreDataController.swift:9-24`; `project.pbxproj` |
| C-6 | Critical | "Encrypted" export writes the AES key in cleartext next to ciphertext | `Features/Analytics/Views/AnalyticsSettingsView.swift:226-261` |
| C-7 | Critical | Full PHI sent to Anthropic API: no BAA, no redaction, no human-review gate | `Core/Services/AIService.swift:89-213` |
| H-1 | High | Certificate pinning is non-functional / fail-open (placeholders + system-trust fallback) | `Core/Services/NetworkSecurityManager.swift:30-44,192-196`; `AIService.swift:14-18` |
| H-2 | High | Biometric "auth" only checks a non-empty email string; signature mismatch | `AuthenticationManager.swift:102,156-160`; `App/Views/LoginView.swift:242` |
| H-3 | High | Project does not compile as committed (duplicate `LoginView`, bad call) | `AuthenticationManager.swift:255` + `App/Views/LoginView.swift:4` |
| H-4 | High | Documents are never copied/encrypted; record stores a path to the original file | `ClientManagement/Views/ClientDocumentsTab.swift:457-498` |
| H-5 | High | Keychain items not gated on device passcode/biometrics | `AuthenticationManager.swift:171/192`; `Configuration.swift:141` |
| H-6 | High | No login throttling/lockout; rate limiting disabled by default | `SessionManager.swift`; `Configuration.swift:102-104`; `RateLimiter.swift:119-141` |
| M-1 | Medium | Client search/fetch is unscoped (returns every client) | `Client+CoreData.swift:62-107` |
| M-2 | Medium | Audit log is plaintext, app-writable, not append-only/tamper-evident | `Core/Services/SecurityEventLogger.swift:121-154` |
| M-3 | Medium | `APIRequestManager` silently re-executes failed requests | `RateLimiter.swift:132-141` |
| M-4 | Medium | No tenant model despite multi-tenant marketing | data model + business docs |
| M-5 | Medium | CloudKit-ready (`syncable=YES`, `import CloudKit`) risks PHI sync to iCloud | `CoreDataController.swift:2,12-14` |
| M-6 | Medium | Unguarded `print` can leak context in release | `ClientDocumentsTab.swift:495` |
| M-7 | Medium | Prior audit doc asserts false "approved for live testing" posture | `SECURITY_AUDIT_REPORT.md` |
| L-1 | Low | No consent/disclosure data model (VAWA/Part 2 cannot be satisfied) | data model |
| L-2 | Low | No accessibility (WCAG 2.2) instrumentation | views |

---

## 2. Critical findings

### C-1 — Authentication bypass (trust-on-first-use; any password works)

**Location:** `Core/Services/AuthenticationManager.swift:21-80`

```
guard verifyPassword(password, forEmail: email) else { ... }
...
private func verifyPassword(_ password: String, forEmail email: String) -> Bool {
    let inputHash = hashPassword(password)
    if let storedHash = retrievePasswordHash(forEmail: email) {
        return inputHash == storedHash
    }
    // First login - store the hash
    return !password.isEmpty
}
```

`Staff.authenticate` (`Client+CoreData.swift:365-378`) only checks that a Staff row with that email **exists** — it stores no password. There is no registration/set-password flow anywhere in the codebase, so for every account the keychain hash starts empty and `verifyPassword` falls through to `return !password.isEmpty`.

**Exploit:** Attacker enters a known/staff email and *any* non-empty password. They are authenticated, and `login()` then calls `saveCredentials()` which **permanently sets the account password to the attacker's input** (`AuthenticationManager.swift:44-46, 185-204`). This is both an auth bypass and an account takeover for any seeded staff record.

**Fix:** Implement an explicit credential-provisioning flow. Never authenticate when no verifier exists — fail closed. Store a per-user password *verifier* (see C-2). Remove the `return !password.isEmpty` branch.

---

### C-2 — Weak password hashing + crash-on-launch salt

**Location:** `AuthenticationManager.swift:64-69`

```
let salt = "ArkheVault_" + ProcessInfo.processInfo.environment["APP_SALT_SUFFIX"]!
let hashed = SHA256.hash(data: Data((salt + password).utf8))
```

- Single **fast** hash (SHA-256), **no per-user salt**, **no key-stretching** (no PBKDF2/scrypt/bcrypt/Argon2). Offline cracking of any leaked verifier is trivial — fails NIST SP 800-63B §5.1.1.2 and OWASP ASVS V2.4.
- The global "salt" is a build-wide constant + one env var; it provides no per-account separation (identical passwords → identical hashes).
- `["APP_SALT_SUFFIX"]!` **force-unwrap** crashes the app on launch/login if the variable is unset → availability defect and a guaranteed crash on any machine without that env var.

**Fix:** Use a memory-hard KDF (`CryptoKit`/`Argon2`/scrypt or at minimum PBKDF2-HMAC-SHA256 ≥ 600k iterations) with a **random per-user salt** stored alongside the verifier. Remove force-unwrap; treat missing config as fatal-misconfiguration handled gracefully, not via `!`.

---

### C-3 — Forged audit attribution (`Staff.fetchAll().first`)

**Locations (10 call sites, 7 files):**
`SafetyDashboardView.swift:436,695`, `SafeHouseListView.swift:507,978`, `ReferralListView.swift:607`, `CalendarView.swift:609`, `ClientNotesTab.swift:410,838`, `ClientDocumentsTab.swift:459`, `ClientProgramsTab.swift` (1).

Every "who did this" value — `createdBy`, `uploadedBy`, `reviewedBy` (supervisor co-sign), `resolvedBy` (safety flag) — is set to **whatever Staff row sorts first in the database**, not the authenticated actor. Example, supervisor review co-signature:

```
guard let currentUser = Staff.fetchAll(in: viewContext).first else { return }
note.markAsReviewed(reviewedBy: currentUser)   // ClientNotesTab.swift:838-839
```

This is compounded by H-2: the biometric path sets `isAuthenticated = true` but never sets `AuthenticationManager.currentUser`, so even the password flow's `currentUser` is routinely unavailable to views, which is *why* they fall back to `fetchAll().first`.

**Impact:** The audit trail, supervisor co-signatures, and "created by" provenance are unreliable and legally worthless. Directly violates HIPAA §164.312(b) audit controls and §164.312(c)(2) integrity, and undermines the clinical co-signature controls the product needs.

**Fix:** Thread the authenticated `Staff` through the environment (single source of truth on `AuthenticationManager.currentUser`, set on **both** password and biometric login). Forbid record mutation when `currentUser == nil`. Remove all `Staff.fetchAll(...).first` actor lookups.

---

### C-4 — No authorization layer; confidentiality is cosmetic

**Locations:** repo-wide. `Staff.isAdmin` (`Client+CoreData.swift:330-332`) is defined but **never referenced** to gate anything. "Confidential" handling is only display logic:

```
// ClientNotesTab.swift:87-89
return notes.filter { $0.visibilityLevel == "confidential" }
// ClientDocumentsTab.swift:251 — UI lock icon only
```

There is no check on read/create/update/delete/export/search against role, assignment, confidentiality class, consent, or purpose. `confidentialAddress` (`ClientListView.swift:311`) only changes an icon. Any authenticated user can open any client, any note, any safe-house location, and run global search.

This is the exact opposite of the "deny-by-default, enforce at the data layer" requirement in the planning audit (Priority-0 items 1–3).

**Fix:** Introduce a central authorization service consulted by **every** data-access entry point (a repository layer that wraps Core Data fetches/saves). Implement the confidentiality classes from the plan as a typed enum on records, and an RBAC+ABAC decision function (role × assignment × class × consent). Because this is a local app, also enforce at storage via per-class encryption (C-5) so the policy survives direct DB access.

---

### C-5 — No encryption at rest; no platform hardening

**Location:** `Core/Data/CoreDataController.swift:9-24`

```
container = NSPersistentContainer(name: "ForgedInFireDataModel")
container.loadPersistentStores { ... }   // no NSPersistentStoreFileProtectionKey, no encryption
```

- No `NSPersistentStoreFileProtectionKey` / `FileProtectionType.complete`, no SQLCipher, no encrypted store. All PHI — `biography`, `medicalNeeds`, `mentalHealthNeeds`, `recoveryNeeds`, `safetyConcerns`, safe-house `confidentialLocation`, `Communication.content` — is **plaintext SQLite** on disk.
- `project.pbxproj` defines **no** App Sandbox, Hardened Runtime, or entitlements (`grep` of the project found none). On macOS the store file is readable by the user's other processes; no data-protection class applies.

**Impact:** App-level login (C-1/H-2) is irrelevant to data confidentiality — copying the `.sqlite` file exfiltrates everything. Fails HIPAA §164.312(a)(2)(iv) encryption addressable safeguard analysis and §164.312(e).

**Fix:** Encrypt the store (SQLCipher or an encrypted NSPersistentStore) with a key derived from the user's authentication and held in the Secure Enclave / passcode-gated keychain; set file protection on iOS; enable App Sandbox + Hardened Runtime; consider field-level encryption for the highest confidentiality classes.

---

### C-6 — "Encrypted" export ships the key in cleartext

**Location:** `Features/Analytics/Views/AnalyticsSettingsView.swift:226-261`

```
let key = SymmetricKey(size: .bits256)
let sealedBox = try AES.GCM.seal(jsonData, using: key)
try combined.write(to: fileURL)                       // ciphertext
let keyData = key.withUnsafeBytes { Data($0) }
try keyData.write(to: keyURL)                          // <-- key, plaintext, same temp dir
```

The randomly generated AES-256 key is written **next to** the ciphertext in the shared temp directory. Anyone who can read the export can read the key → zero confidentiality. The 1-hour `asyncAfter` cleanup is also lost if the app quits, leaving both files indefinitely. The prior audit lists this as a *fix* ("AES-GCM encryption for all temp exports").

**Fix:** Never persist the key beside the data. Either (a) export to a user-chosen destination protected by OS file protection, (b) encrypt to a recipient public key, or (c) password-derive the key (KDF) and require the passphrase on import. Write to an app-private, file-protected location and delete deterministically.

---

### C-7 — Full PHI transmitted to a third-party AI API without a BAA, redaction, or human review

**Location:** `Core/Services/AIService.swift:89-213`

`buildClientSummaryPrompt`/`buildRiskAssessmentPrompt`/`buildFollowUpPrompt` embed `client.fullName`, `biography`, `safetyConcerns`, `riskLevel`, `lastContactDate`, etc., and POST them to `https://api.anthropic.com/v1/messages` (`baseURL`, line 9). There is:

- **No BAA** assumed/verified for this data path (HHS: a vendor that receives ePHI generally requires a BAA).
- **No minimization/redaction** — entire records are sent (violates HIPAA minimum-necessary and the project's own "AI restrictions": *"Do not send entire client records unnecessarily; minimize and redact input"*).
- **No human-review gate, no provenance/labeling, no org-level disable** beyond presence of an API key (`Configuration.aiFeaturesEnabled` = key configured).
- It also **bypasses** `APIRequestManager`/rate limiting entirely (calls `session.data` directly).

The planning audit is explicit: *do not add generative AI to clinical/survivor records until the security model is complete.* It is currently wired in.

**Fix:** Disable AI on PHI by default. Gate behind explicit org opt-in + executed BAA-eligible provider config; route through a minimization/redaction layer; require human review and label outputs; never send confidential-class fields. Until then, feature-flag it off.

---

## 3. High findings

### H-1 — Certificate pinning is non-functional / fail-open
`NetworkSecurityManager.swift:30-44` uses literal `"PLACEHOLDER_PROD_CERT_HASH_1"` pins, and lines **192-196** fall back to `SecTrustEvaluateWithError` (system trust) whenever no pin matches — so pinning is **never** enforced and provides no MITM protection beyond default TLS. It also hashes the **full certificate DER** (brittle across rotation) rather than the SPKI. In `AIService.swift:14-18` the pins are `"AAAA…="/"BBBB…="`, which can never match and there is no fallback there, so the AI path is effectively dead (it would always cancel the challenge). The prior audit marks pinning "PASS."
**Fix:** Pin the **SPKI** (leaf + backup) with real values; **fail closed**; no silent system-trust fallback in production; add pin-rotation strategy.

### H-2 — Biometric "authentication" validates nothing
`AuthenticationManager.swift:156-160`: `validateBiometricCredentials` returns `!email.isEmpty`. On biometric success the app sets `isAuthenticated = true` with **no Staff binding** and never sets `currentUser` (lines 116-126). Signature mismatch: defined as `authenticateWithBiometrics()` (line 102) but called as `authenticateWithBiometrics(context:)` (`App/Views/LoginView.swift:242`).
**Fix:** Bind biometric unlock to a specific provisioned Staff identity and a key that releases the store-encryption secret; set `currentUser`; reconcile the signature.

### H-3 — Does not compile as committed
Two `struct LoginView: View` (`AuthenticationManager.swift:255` and `App/Views/LoginView.swift:4`) → duplicate type declaration; plus the H-2 call/def mismatch. The code as committed cannot build, which falsifies the prior audit's "85+ tests passing / CLEARED FOR LIVE TESTING."
**Fix:** Remove the duplicate view (keep `App/Views/LoginView.swift`), fix the call signature, and stand up CI that actually builds + runs the test target.

### H-4 — Documents are reference-only; never copied or encrypted
`ClientDocumentsTab.swift:457-498`: `document.filePath = fileURL.path` stores the path of the user-picked original (e.g. `~/Downloads/...`); `fileSize`/`mimeType` are hardcoded; comment says *"In production, this would securely upload the file."* No copy into managed storage, no encryption, no access enforcement on open.
**Fix:** Copy into an app-private, encrypted, file-protected store; record a content hash; enforce confidentiality-class checks on open/export; populate real size/MIME.

### H-5 — Keychain accessibility too permissive
`kSecAttrAccessibleWhenUnlockedThisDeviceOnly` is used for the password hash, the current-user reference, and the Claude API key (`AuthenticationManager.swift:171,192`; `Configuration.swift:141`). These are readable by any code in the same keychain access group whenever the device is unlocked — no passcode/biometric gating.
**Fix:** Use `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` + a `SecAccessControl` requiring user presence/biometrics for sensitive items (API key, store key).

### H-6 — No login throttling/lockout; rate limiting off by default
`login()` has no failed-attempt counter or backoff. `SessionManager` is a UI idle timer only. The generic `RateLimiter` only wraps `APIRequestManager` and is **disabled unless** `RATE_LIMITING_ENABLED == "true"` (`Configuration.swift:102-104`), and `AIService` doesn't use it anyway.
**Fix:** Add per-account failed-attempt lockout with exponential backoff and audit logging; enable request rate limiting by default.

---

## 4. Medium / Low findings

- **M-1 Unscoped search/fetch** — `Client.search`/`fetchAll` (`Client+CoreData.swift:62-107`) return every client with no assignment/role/consent scoping. Enables the "search for unassigned clients" abuse the plan warns about.
- **M-2 Audit log not tamper-evident** — `SecurityEventLogger.swift:121-154` writes a plaintext file via `FileHandle` that the app/admin/any user process can edit or delete; `rotateLogFile` overwrites the prior `.1`. Not append-only, no signing/hash-chain. Fails the plan's "append-only, not editable by ordinary admins" requirement.
- **M-3 Silent re-execution** — `RateLimiter.swift:132-141`: on any non-rate-limit error, `executeRequest` calls `request()` again and returns it without catching → duplicate side effects / unhandled throw.
- **M-4 No tenant model** — no `Organization`/`organization_id`; multi-tenant SaaS marketing is unimplemented.
- **M-5 CloudKit readiness** — `import CloudKit` and all entities `syncable="YES"` with commented CloudKit scaffolding (`CoreDataController.swift:2,12-14`). Enabling `NSPersistentCloudKitContainer` would sync PHI to iCloud without segmentation/BAA-appropriate handling.
- **M-6 Unguarded print** — `ClientDocumentsTab.swift:495` `print("Error uploading document: \(error)")` is not `#if DEBUG`-wrapped.
- **M-7 Misleading prior audit** — `SECURITY_AUDIT_REPORT.md` states "APPROVED FOR LIVE TESTING"; this is governance risk and should be retracted/replaced.
- **L-1 No consent/disclosure model** — no entities for VAWA time-limited, recipient-/purpose-specific consent, revocation, or disclosure tracking; `Referral.consentConfirmed` is a single Bool (`data model:243`). 42 CFR Part 2 and VAWA confidentiality cannot be met without this.
- **L-2 Accessibility** — no evidence of WCAG 2.2 AA instrumentation (accessibility labels, focus order, contrast tokens, reduced-motion). Needs a dedicated pass.

---

## 5. Standards mapping (current state)

| Standard | Status | Driving findings |
|----------|--------|------------------|
| HIPAA §164.312(a) access control | **Fail** | C-1, C-4, H-2 |
| HIPAA §164.312(a)(2)(iv)/(e) encryption | **Fail** | C-5, C-6, H-4 |
| HIPAA §164.312(b)/(c) audit & integrity | **Fail** | C-3, M-2 |
| HIPAA §164.308(b) BAA / business associate | **Fail** | C-7, M-5 |
| NIST SP 800-63B (auth/verifier) | **Fail** | C-1, C-2, H-2, H-6 |
| OWASP ASVS V2 (auth) / V4 (access) / V6 (crypto) | **Fail** | C-1..C-6, H-1, H-5 |
| 42 CFR Part 2 (SUD records) | **Fail** | C-4, L-1 |
| VAWA/VOCA confidentiality | **Fail** | C-4, C-7, L-1 |
| WCAG 2.2 AA | **Unverified** | L-2 |

**Posture:** Not suitable for real survivor PHI in its current state. The accurate external claim is *"in development; not yet HIPAA-ready."* Do **not** advertise HIPAA compliance or multi-tenant SaaS.

---

## 6. Prioritized remediation roadmap

**P0 — release-blocking (must precede any real sensitive data):**
1. Fix build (H-3) and stand up build+test CI.
2. Replace auth: real credential provisioning, fail-closed verification, KDF + per-user salt, remove force-unwrap (C-1, C-2).
3. Single authenticated-actor source of truth; set `currentUser` on all login paths; remove `fetchAll().first` (C-3, H-2).
4. Encrypt data at rest; enable App Sandbox + Hardened Runtime + file protection; passcode-gate keychain (C-5, H-5).
5. Central deny-by-default authorization + confidentiality classes enforced in a repository layer (C-4, M-1).
6. Disable AI-on-PHI by default; gate behind BAA + minimization + human review (C-7).
7. Fix export crypto (C-6); make audit log append-only/tamper-evident (M-2).
8. Real cert pinning, fail-closed (H-1); login lockout (H-6); managed encrypted document storage (H-4).

**P1 — compliance scaffolding:** consent/disclosure model (time-limited, recipient/purpose-scoped, revocable) for VAWA + 42 CFR Part 2 (L-1); small-cell suppression for reports; BAA/vendor inventory; backup + restore testing; incident-response plan.

**P2 — competitive core:** clinical-record separation (psychotherapy notes), scheduling, portal with survivor-safety controls, MDT consent-filtered views, WCAG 2.2 AA pass (L-2).

---

## 7. Method & caveats

This review is static (source) only; it did not execute the app (the project does not build as committed — H-3). Line numbers reference the audited revision. No secrets, `.env` files, real survivor data, or keys were found committed (good), though the git remote embeds an access token in its URL — rotate it if it has been shared. Once H-3 is resolved, a dynamic pass (DB-file extraction test, MITM/pinning test, keychain dump, AI egress capture) should confirm the fixes.
