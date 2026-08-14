# Creates Meshen-style labels, milestones, and issues for Family Price Tracker.
# Run from repo root: python scripts/create_github_board.py
# Requires: gh auth

from __future__ import annotations

import json
import subprocess
import sys
import time

REPO = "max-well-house/PhotoListPriveWatcher"

LABELS = [
    ("Feature", "0fc1ad", "Adds a brand new capability to the application."),
    ("enhancement", "50979c", "Improves an existing feature."),
    ("documentation", "c633ab", "Anything involving writing instead of coding."),
    ("bug", "e11112", "Something that should work but doesn't."),
    ("Research", "dd9110", "Requires investigation before coding."),
    ("tech debt", "7f6d9c", "Cleanup work."),
    ("nice to have", "752508", "Not required."),
    ("ios", "5319e7", "iOS app work"),
    ("worker", "1d76db", "Home PC Python worker"),
    ("sheet", "0e8a16", "Google Sheet schema/UX"),
    ("scraper", "d93f0b", "Retailer fetcher"),
]

MILESTONES = [
    (
        "v0.0.1 - Repo + vision",
        "## Era 0 — Foundation\n\nMonorepo layout, vision/roadmap/decisions docs, legal notes. No runtime required.\n\n**Must-ship:** restructure, vision, roadmap, decisions, scraping legal, LICENSE/env.",
    ),
    (
        "v0.1.0 - Sheet schema",
        "## Era 0 — Foundation\n\nSheet is the contract. Sample data relatives can understand.\n\n**Must-ship:** Items schema, Config tab, sample CSV. Stretch: hyperlink formatting guide.",
    ),
    (
        "v0.2.0 - Worker skeleton",
        "## Era 0 — Foundation\n\nRunnable Python package on home Windows PC.\n\n**Must-ship:** package scaffold, config loader, fetcher protocol, logging/isolation.",
    ),
    (
        "v0.3.0 - Sheets sync foundation",
        "## Era 1 — Sheet + sync\n\nService-account read/write from worker.\n\n**Must-ship:** Google setup guide, read items, update price columns, list-items CLI.",
    ),
    (
        "v0.4.0 - Vertical slice (URL → price)",
        "## Era 1 — P0 demo\n\nAdd tracked URL → Amazon fetch once → Sheet shows linked price.\n\n**Must-ship:** Amazon fetcher, refresh --item, add-tracked CLI, demo checklist.\n\n**Stretch:** Target/Walmart (see v0.8).",
    ),
    (
        "v0.5.0 - iOS read-only list",
        "## Era 1 — Sheet + sync\n\nSee Sheet items on phone (Mac/Xcode required to run).\n\n**Must-ship:** SwiftUI shell, Sign-In research, read list, detail + tappable prices, distribution docs.",
    ),
    (
        "v0.6.0 - Text items + lists + priority",
        "## Era 2 — App CRUD\n\nWishlist text asks without tracking.\n\n**Must-ship:** add text item, edit notes/priority/list/status, Config validation.\n\nLive Sheet write is v0.9.1 (Mac). Windows closeout uses the sample stub.",
    ),
    (
        "v0.7.0 - Add via URL + manual stores",
        "## Era 2 — App CRUD\n\nTracked items from pasted URL; pick stores per item.\n\n**Must-ship:** iOS add-from-URL, per-item store checklist, worker honors stores column.",
    ),
    (
        "v0.8.0 - Target + Walmart fetchers",
        "## Era 2 — Expand retailers\n\n**Must-ship:** Target fetcher, Walmart fetcher, doctor CLI.\n\n**Stretch:** Costco research.",
    ),
    (
        "v0.9.0 - Barcode / UPC identity",
        "## Era 3 — Identity\n\nConfirm-first matching.\n\n**Must-ship:** barcode research, scan+confirm UI, assisted multi-store match (exact UPC).\n\nCamera on a physical device is v0.9.1.",
    ),
    (
        "v0.9.1 - Mac session (live iOS)",
        "## Era 3 — Live device gate (before v1.0.0)\n\nChecklist only — not new features. Sit at a real Mac (borrowed or rented) and prove iOS.\n\n**Must-ship:** Xcode project, Google Sign-In + Sheets write, install on a family iPhone, smoke list/add/edit (and URL add / barcode if those sources already exist).\n\n**Out of scope:** photos (v1.0.0, still Mac), worker fetchers.",
    ),
    (
        "v1.0.0 - Photos + Sheet-visible image",
        "## Era 3 — Daily-driver family Sheet\n\n**Must-ship:** Drive vs cell research, attach photo, Sheet thumbnail. Stretch: screenshot identity.",
    ),
    (
        "v1.1.0 - Scheduled refresh",
        "## Era 4 — Worker cadence\n\nWeekly default; daily for hot items.\n\n**Must-ship:** refresh --due, Task Scheduler doc, hot flag, failure digest.",
    ),
    (
        "v1.2.0 - Custom stores / YouTuber merch",
        "## Era 5 — Expand\n\nManual URL stores reusable in directory.",
    ),
    (
        "v1.3.0 - More retailers",
        "## Era 5 — Phased store directory\n\nShip retailers when a family item needs them. Costco is research-gated.",
    ),
    (
        "Up next (v0.4 polish)",
        "## Between foundation and CRUD\n\nQuick ships: conditional formatting, dry-run, UUID docs, fixture URL.",
    ),
    (
        "Unplanned",
        "## Later / non-goals\n\nHistory, deals, zip pricing, Android. Anti-goals stay closed or marked won't-do.",
    ),
]


def issue(title: str, body: str, labels: list[str], milestone: str) -> dict:
    return {"title": title, "body": body, "labels": labels, "milestone": milestone}


def ac(lines: list[str]) -> str:
    return "\n".join(f"- [ ] {x}" for x in lines)


ISSUES: list[dict] = []


def add(title: str, milestone: str, labels: list[str], context: str, goal: str, criteria: list[str], out: list[str] | None = None, notes: str = ""):
    parts = [
        f"## Milestone {milestone.split(' - ')[0]} — context",
        "",
        context.strip(),
        "",
        "### Goal",
        goal.strip(),
        "",
        "### Acceptance criteria",
        ac(criteria),
    ]
    if out:
        parts += ["", "### Out of scope", *[f"- {x}" for x in out]]
    if notes:
        parts += ["", "### Notes", notes.strip()]
    ISSUES.append(issue(title, "\n".join(parts) + "\n", labels, milestone))


# --- v0.0.1 ---
M = "v0.0.1 - Repo + vision"
add("Restructure monorepo (ios/, worker/, docs/, sheet/)", M, ["documentation", "tech debt"],
    "Replace placeholder src/ tree with surface-aligned folders.",
    "Monorepo matches iOS, worker, sheet, and docs surfaces.",
    ["ios/, worker/, docs/, sheet/ exist", "Obsolete scaffold removed", "README points at layout"],
    ["App/worker business logic beyond scaffold"])
add("Write docs/vision.md + root README (product promise)", M, ["documentation"],
    "Restate family wishlist + Sheet SoT + iOS + home worker.",
    "Anyone opening the repo understands the product in under two minutes.",
    ["vision.md covers surfaces, principles, first-demo success", "README links vision/roadmap/setup"])
add("Write docs/roadmap.md (eras + milestone map)", M, ["documentation"],
    "Single roadmap file listing milestones, must-ship vs stretch (Meshen style).",
    "Roadmap mirrors GitHub milestones and calls out the vertical slice.",
    ["Eras 0–5 documented", "Vertical slice called out as next work"])
add("Write docs/decisions.md (stack defaults)", M, ["documentation"],
    "Lock Sheets-direct sync, Python worker, SwiftUI, Amazon-first, priority 1–5.",
    "Decision log answers stack/auth/scraper/API questions without re-debating.",
    ["Decision #001 stack", "Decision #002 auth", "Decision #003 scraper isolation", "Decision #004 no paid token APIs in core loop"])
add("Document scraping / ToS risks", M, ["documentation", "scraper"],
    "Family-only use; scrapers best-effort; prefer official APIs; fail detectably.",
    "Legal/ops expectations are explicit in-repo.",
    ["docs/scraping-and-legal.md exists", "README links it", "No claim of ToS compliance for scrapers"])
add("Add LICENSE + .gitignore + .env.example", M, ["documentation"],
    "MIT (or chosen) license; secrets never committed.",
    "Safe defaults for a private family tool.",
    ["LICENSE present", "env example lists SHEET_ID and GOOGLE_APPLICATION_CREDENTIALS", ".env ignored"])

# --- v0.1.0 ---
M = "v0.1.0 - Sheet schema"
add("Define Items sheet column schema", M, ["sheet", "documentation", "Feature"],
    "Stable columns for wishlist + tracked prices.",
    "SCHEMA.md defines headers worker and iOS must share.",
    ["sheet/SCHEMA.md documents all Items columns", "types tracked|text", "priority 1–5", "status wanted/purchased/dropped"],
    ["6-month history columns"])
add("Config tab: list owners + store directory", M, ["sheet", "Feature"],
    "Editable list owners and built-in store checklist without code changes.",
    "Config tab documents owners and store_key/display_name/enabled.",
    ["Default owners Me/Spouse/Kid A/Kid B/Shared", "Store directory includes amazon/target/walmart/custom"])
add("Sample rows CSV (text + tracked examples)", M, ["sheet", "documentation"],
    "Importable sample so Sheet looks alive for family demo.",
    "At least one text and one tracked sample row.",
    [">=1 text item with notes", ">=1 tracked Amazon URL row", "Photo column placeholder noted"])
add("Sheet formatting guide (hyperlink prices, freeze header)", M, ["sheet", "documentation", "nice to have"],
    "Relatives see price as clickable link; header usable on phone Sheet app.",
    "Document HYPERLINK pattern and freeze row 1.",
    ["Formatting steps in SCHEMA or docs", "Works on mobile Sheet noted"])

# --- v0.2.0 ---
M = "v0.2.0 - Worker skeleton"
add("Python package scaffold (worker/)", M, ["worker", "Feature"],
    "Installable package with CLI entrypoint.",
    "python -m family_price_tracker --help works on Windows.",
    ["requirements.txt or pyproject.toml", "CLI help works", "worker README setup on Windows"])
add("Config loader (env + optional YAML)", M, ["worker", "Feature"],
    "Sheet ID + credentials path from env; no secrets in git.",
    "Clear errors when misconfigured.",
    ["Loads SHEET_ID and GOOGLE_APPLICATION_CREDENTIALS", "Clear error if missing"])
add("Fetcher protocol + registry", M, ["worker", "scraper", "Feature"],
    "Isolate retailers so one broken scraper does not kill the run.",
    "Protocol fetch(...) -> PriceResult | FetchError with registry by store key.",
    ["Base protocol defined", "Registry by store key", "Unit test with fake or Amazon HTML fixture"])
add("Logging + per-item error isolation", M, ["worker", "enhancement"],
    "Run continues after one item/store fails; failures visible.",
    "Structured logs; non-zero exit if any failure but successes still written.",
    ["Per-item errors logged", "Successes persist despite sibling failures"])

# --- v0.3.0 ---
M = "v0.3.0 - Sheets sync foundation"
add("Google Cloud setup guide (Sheet + service account)", M, ["documentation", "sheet"],
    "Create Sheet, share with SA email, paste Sheet ID locally.",
    "docs/setup-google.md is enough to get list-items working.",
    ["Step-by-step enable Sheets API", "Share Sheet with SA as Editor", "Env vars documented"])
add("Sheets client: read all items", M, ["worker", "sheet", "Feature"],
    "Map rows to typed Item models.",
    "Worker can list Items tab rows with stable ids.",
    ["Reads Items tab", "Skips empty ids", "Maps priority/type/notes/amazon fields"])
add("Sheets client: update price columns for one row", M, ["worker", "sheet", "Feature"],
    "Write amazon_price, amazon_url, last_checked by id.",
    "Update does not clobber notes/priority.",
    ["Updates by stable id / row index", "Notes and priority unchanged"])
add("CLI: list-items (smoke against real Sheet)", M, ["worker", "Feature"],
    "Prove credentials work without fetching prices.",
    "Prints id/name/type/priority for manual smoke.",
    ["list-items command works with valid creds", "Docs mark as manual smoke"])

# --- v0.4.0 ---
M = "v0.4.0 - Vertical slice (URL → price)"
add("Amazon fetcher (product URL → price + canonical URL)", M, ["worker", "scraper", "Feature"],
    "Best-effort price from known product URL; loud failure if markup changed.",
    "Returns price + url; typed selector_broken; never invents price.",
    ["Parses price from product page HTML/JSON-LD when possible", "Raises/returns selector_broken on failure", "Module docstring links legal doc"],
    ["UPC search", "Deals", "Other retailers"])
add("CLI: refresh --item <id> (one retailer)", M, ["worker", "Feature"],
    "Refresh one tracked row Amazon columns.",
    "Reads row, calls fetcher, writes Sheet, logs result.",
    ["refresh --item updates amazon_price/url/last_checked", "Errors printed clearly"])
add("CLI: add-tracked --url --name --notes --priority --list", M, ["worker", "sheet", "Feature"],
    "Create tracked row from CLI until iOS write exists.",
    "Allocates stable id; type=tracked; stores amazon_url; optional --refresh.",
    ["Appends row to Sheet", "Optional immediate refresh flag"])
add("Demo script / checklist in README", M, ["documentation"],
    "5-minute path: add URL → refresh → open Sheet see price.",
    "README checklist with expected columns after success.",
    ["Checklist present in root or worker README"])

# --- v0.5.0 ---
M = "v0.5.0 - iOS read-only list"
add("SwiftUI app shell + project README", M, ["ios", "Feature"],
    "Xcode project / sources open; placeholder UI; distribution notes.",
    "ios/README explains Mac requirement; list screen sources exist.",
    ["SwiftUI sources under ios/FamilyPriceTracker", "ios/README documents Mac/Xcode need"])
add("Research: Google Sign-In + Sheets API on iOS", M, ["Research", "ios", "sheet"],
    "Recommend OAuth for 2 editors; note Windows-dev constraint.",
    "Short research note with chosen approach and Cloud iOS client steps.",
    ["docs note written", "Approach chosen (OAuth)", "Setup steps listed"])
add("iOS: read items from Sheet (list UI)", M, ["ios", "sheet", "Feature"],
    "Show name, list_owner, priority, type, notes; sort by priority.",
    "Filter by list_owner; pull-to-refresh; empty/error states.",
    ["List loads from Sheet (or documented stub until OAuth)", "Sort by priority", "Filter by owner"],
    ["Add/edit"])
add("iOS: item detail + tappable store price links", M, ["ios", "Feature"],
    "Detail shows notes; price opens store URL in Safari.",
    "Uses amazon_url; missing price shows not checked.",
    ["Tappable Amazon link", "Notes visible"])
add("Document iOS distribution (TestFlight / sideload)", M, ["documentation", "ios"],
    "How two devices get builds without public App Store.",
    "docs/ios-distribution.md covers Xcode device + TestFlight later.",
    ["Distribution doc exists"])

# --- v0.6.0 ---
M = "v0.6.0 - Text items + lists + priority"
add("iOS: add text-only item (notes, priority, list)", M, ["ios", "sheet", "Feature"],
    "type=text; store columns empty. SampleSheetClient until v0.9.1 live Sheet.",
    "Confirm save writes a text row (in-memory stub on Windows; live Sheet in v0.9.1).",
    ["Creates text row", "Notes/priority/list set", "Confirm UI before save"],
    ["Live Sheet visibility (v0.9.1)", "Add from URL (v0.7)"])
add("iOS: edit notes / priority / list_owner / status", M, ["ios", "Feature"],
    "CRUD fields relatives rely on. Stub until v0.9.1 live write.",
    "Edits persist through SheetClient; wanted-default filter; purchased/dropped available.",
    ["Edit persists via SheetClient", "Status values wanted/purchased/dropped"],
    ["Live Sheet persistence (v0.9.1)"])
add("Sheet: list_owner validation against Config tab", M, ["sheet", "enhancement"],
    "Do not invent list names ad hoc without Config.",
    "App loads owners from Config (sample_owners.json in stub); schema notes data validation.",
    ["Owners loaded from Config / sample owners", "Schema doc mentions validation"])

# --- v0.7.0 ---
M = "v0.7.0 - Add via URL + manual stores"
add("iOS: add tracked item from product URL", M, ["ios", "Feature"],
    "Paste URL → confirm name/notes → choose stores → save.",
    "Never silent-save without confirm; amazon_url set when Amazon chosen.",
    ["Confirm UI before save", "Writes Sheet", "Stores amazon_url when selected"])
add("Per-item store checklist (directory-backed)", M, ["ios", "sheet", "Feature"],
    "Only fetch/display stores checked on that item.",
    "Checklist from Config directory.",
    ["Checklist UI", "Persists stores column"],
    ["Custom stores (v1.2)"])
add("Worker: refresh only checked stores for row", M, ["worker", "enhancement"],
    "Honor per-item store selection.",
    "Skip unchecked; document stores=amazon,target encoding.",
    ["Skips unchecked stores", "Encoding documented"])

# --- v0.8.0 ---
M = "v0.8.0 - Target + Walmart fetchers"
add("Target fetcher (URL and/or UPC when available)", M, ["worker", "scraper", "Feature"],
    "Second general retailer after Amazon.",
    "Best-effort Target price from product URL; typed failures.",
    ["Fetcher registered as target", "Writes target_price/url when wired", "selector_broken on parse fail"])
add("Walmart fetcher (URL and/or UPC when available)", M, ["worker", "scraper", "Feature"],
    "Third general retailer.",
    "Best-effort Walmart price from product URL; typed failures.",
    ["Fetcher registered as walmart", "Writes walmart_price/url when wired", "selector_broken on parse fail"])
add("Fetcher health check CLI (doctor)", M, ["worker", "scraper", "enhancement"],
    "Probe each fetcher with a known fixture URL; report broken selectors.",
    "doctor lists fetchers; optional probe mode later.",
    ["doctor command lists registered fetchers", "Document how to validate with refresh --item"])

# --- v0.9.0 ---
M = "v0.9.0 - Barcode / UPC identity"
add("Research: on-device barcode scan + UPC→product options", M, ["Research", "ios"],
    "Prefer on-device Vision/AVFoundation; avoid paid token APIs for core loop.",
    "Written recommendation + free/self-hosted lookup options.",
    ["Research note in docs/", "Recommendation chosen"])
add("iOS: barcode scan → propose identity → user confirms", M, ["ios", "Feature"],
    "Never silently assume product.",
    "Confirm screen before save; stores UPC on row.",
    ["Camera/barcode scan path", "Confirm before save", "UPC persisted"])
add("Assisted multi-store match (exact UPC only auto-suggest)", M, ["ios", "worker", "Feature"],
    "Suggest Amazon/Target/Walmart when UPC exact; fuzzy title = suggest only.",
    "No auto-add outside directory; user confirms each store link.",
    ["Exact UPC can pre-check suggestions", "Fuzzy requires confirm", "Never auto-add unknown stores"])

# --- v0.9.1 ---
M = "v0.9.1 - Mac session (live iOS)"
add("Mac: create/sync Xcode project from ios/ sources", M, ["ios", "documentation"],
    "Windows repo has Swift sources but no .xcodeproj.",
    "Xcode iOS 17+ app copies FamilyPriceTracker sources; both sample JSON files in the bundle.",
    ["Xcode project builds", "sample_items.json and sample_owners.json in bundle"],
    ["Photos (v1.0.0)"])
add("iOS: Google Sign-In + Sheets write", M, ["ios", "sheet", "Feature"],
    "v0.5 researched readonly; CRUD needs write scope. No service-account JSON in the app.",
    "Sign-In obtains a token; GoogleSheetsClient reads/writes Items + Config.",
    ["Sign-In works on device or Simulator", "Scope is spreadsheets (write)", "SHEET_ID not committed"])
add("Mac: install on a family iPhone", M, ["ios", "documentation"],
    "Two primary users; at least one phone must run a real build.",
    "Xcode device install or TestFlight internal testing.",
    ["App runs on a physical iPhone"])
add("Mac: live smoke of list, text CRUD, and deferred iOS", M, ["ios", "sheet", "Feature"],
    "Prove Windows-coded flows against the real Sheet before v1.0.0.",
    "Sign In → list from Sheet → add text item visible to a relative → edit persists. Smoke URL add if v0.7 coded; barcode on a physical device if v0.9 coded.",
    ["List loads from live Sheet", "Add text item visible in Sheet", "Edit notes/priority/list/status persists"],
    ["Photos / Drive thumbnails (v1.0.0)"])

# --- v1.0.0 ---
M = "v1.0.0 - Photos + Sheet-visible image"
add("Research: Drive vs Sheet cell images for thumbnails", M, ["Research", "sheet", "ios"],
    "Pick approach for family-visible thumbnails.",
    "Short research with recommendation.",
    ["docs note with recommendation"])
add("iOS: attach photo / screenshot to item", M, ["ios", "Feature"],
    "Capture or pick image for an item.",
    "Image associated with item id for Sheet visibility path.",
    ["Pick/capture image", "Linked to item"])
add("Sheet shows thumbnail / image link for family", M, ["sheet", "Feature"],
    "Relatives see what to buy from photo + notes.",
    "Photo column populated with viewable image/link.",
    ["Visible in Sheet on phone", "Documented upload path"])
add("Screenshot → assisted identity (confirm UI)", M, ["ios", "Feature", "nice to have"],
    "Optional assist from screenshot; confirm always.",
    "Fall back to manual name+URL if matching weak.",
    ["Confirm UI required", "Manual fallback works"],
    ["Fully automatic identity"])

# --- v1.1.0 ---
M = "v1.1.0 - Scheduled refresh"
add("CLI: refresh --due (weekly default)", M, ["worker", "Feature"],
    "Refresh wanted tracked items on a schedule.",
    "refresh --due processes due rows (initially all wanted tracked).",
    ["Command exists", "Skips non-tracked / purchased as documented"])
add("Windows Task Scheduler (or launchd) setup doc", M, ["documentation", "worker"],
    "Home PC runs weekly without manual start.",
    "Doc with example scheduled task invoking the CLI.",
    ["Windows steps documented", "Mac launchd note optional"])
add("Hot-item daily flag (opt-in per row)", M, ["worker", "sheet", "enhancement"],
    "Daily refresh only for opt-in hot items.",
    "hot=yes column changes cadence.",
    ["Schema hot column used", "Due logic respects hot"])
add("Failure digest log file for broken scrapers", M, ["worker", "scraper", "enhancement"],
    "Maintainers see broken selectors in one place.",
    "Log file or report summarizing fetch failures.",
    ["Failures appended to digest", "Path documented"])

# --- v1.2.0 ---
M = "v1.2.0 - Custom stores / YouTuber merch"
add("Add custom store to directory (name + URL)", M, ["sheet", "ios", "Feature"],
    "Adding a custom store once makes it reusable in the checklist.",
    "Config directory accepts custom entries.",
    ["Can add custom store", "Appears in checklist later"])
add("Per-item custom store URL + price display", M, ["ios", "worker", "Feature"],
    "YouTuber merch: manual name + product URL; usually single-site.",
    "Item can store custom URL and show price/link.",
    ["Custom URL on item", "Displayed in app and Sheet"])
add("Worker: generic manual URL price refresh (best-effort)", M, ["worker", "scraper", "enhancement"],
    "Attempt og:price / JSON-LD; degrade to link only if no price.",
    "Generic fetcher for custom URLs without inventing prices.",
    ["Tries common meta/JSON-LD", "Link-only mode if no price"])

# --- v1.3.0 ---
M = "v1.3.0 - More retailers"
add("Research: Costco pricing access (login walls)", M, ["Research", "scraper"],
    "Costco may require login; decide if in-scope.",
    "Research note: go/no-go and approach.",
    ["Recommendation written"])
add("Harbor Freight fetcher", M, ["scraper", "Feature"],
    "Tools retailer when family needs it.",
    "Best-effort Harbor Freight product URL price.",
    ["Fetcher module", "Registered in directory when enabled"])
add("Home Depot fetcher", M, ["scraper", "Feature"],
    "Tools retailer.",
    "Best-effort Home Depot product URL price.",
    ["Fetcher module", "Typed failures"])
add("Lowe's fetcher", M, ["scraper", "Feature"],
    "Tools retailer.",
    "Best-effort Lowe's product URL price.",
    ["Fetcher module", "Typed failures"])
add("Bass Pro / Cabela's fetcher", M, ["scraper", "Feature"],
    "Outdoors retailers.",
    "Best-effort product URL price for at least one outdoors store.",
    ["At least one outdoors fetcher", "Documented which brand"])
add("Planet / Aerie / American Eagle fetchers", M, ["scraper", "Feature"],
    "Clothing retailers as needed.",
    "Ship when a family item needs them; not all required day one.",
    ["At least one clothing fetcher or explicit defer note"])

# --- Up next ---
M = "Up next (v0.4 polish)"
add("Sheet conditional formatting by priority", M, ["sheet", "enhancement"],
    "Make high-priority rows obvious for relatives.",
    "Document or apply conditional formatting for priority 1–2.",
    ["Formatting guide or template noted"])
add("Worker dry-run mode (no Sheet writes)", M, ["worker", "enhancement"],
    "Test fetchers without mutating the Sheet.",
    "refresh --dry-run prints would-write values.",
    ["Flag documented", "No Sheet mutations in dry-run"])
add("Idempotent id generator (UUID) documented", M, ["documentation"],
    "Stable ids for rows across app and worker.",
    "UUID approach documented in schema/decisions.",
    ["Docs mention UUID ids"])
add("Sample Amazon fixture URL for fetcher tests", M, ["worker", "scraper"],
    "Stable-ish public product page for manual doctor checks; expect breakage.",
    "Document a fixture URL and that it may break.",
    ["Fixture noted in worker README or tests"])

# --- Unplanned ---
M = "Unplanned"
add("6-month low / price history chart", M, ["nice to have", "enhancement"],
    "Later plus — not required for v1.",
    "Track min seen + date; optional chart.",
    ["Design note only until prioritized"])
add("Deals / coupon scraping", M, ["nice to have"],
    "Explicit non-goal for v1; prices matter more than deals.",
    "Keep parked unless product direction changes.",
    ["Remains nice-to-have unless reopened"])
add("Local zip / in-store inventory (2 zips)", M, ["nice to have", "Research"],
    "Optional later geo pricing.",
    "Research when online-only is not enough.",
    ["Not started for v1"])
add("Android app", M, ["nice to have"],
    "Sheet is enough for non-iOS family.",
    "Do not build unless need proven.",
    ["Deferred"])
add("Fully automatic unconfirmed store linking", M, ["nice to have"],
    "Anti-goal: never auto-link without confirm.",
    "If filed, close as won't-do.",
    ["Documented as won't-do"])


def run(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True)


def ensure_label(name: str, color: str, description: str) -> None:
    r = run(["gh", "label", "create", name, "--repo", REPO, "--color", color, "--description", description])
    if r.returncode != 0 and "already exists" not in (r.stderr + r.stdout).lower():
        # try edit
        run(["gh", "label", "edit", name, "--repo", REPO, "--color", color, "--description", description])


def ensure_milestone(title: str, description: str) -> None:
    # create; ignore if exists
    r = run([
        "gh", "api", f"repos/{REPO}/milestones",
        "-f", f"title={title}",
        "-f", f"description={description}",
        "-f", "state=open",
    ])
    if r.returncode != 0 and "already_exists" not in (r.stderr + r.stdout):
        # update existing by title
        listing = run(["gh", "api", f"repos/{REPO}/milestones?state=all&per_page=100"])
        if listing.returncode == 0:
            for m in json.loads(listing.stdout):
                if m["title"] == title:
                    run([
                        "gh", "api", f"repos/{REPO}/milestones/{m['number']}",
                        "-X", "PATCH",
                        "-f", f"description={description}",
                    ])
                    return
        print("milestone warn:", title, r.stderr, file=sys.stderr)


def create_issue(item: dict) -> None:
    cmd = [
        "gh", "issue", "create",
        "--repo", REPO,
        "--title", item["title"],
        "--body", item["body"],
        "--milestone", item["milestone"],
    ]
    for lab in item["labels"]:
        cmd.extend(["--label", lab])
    r = run(cmd)
    if r.returncode != 0:
        print("FAIL", item["title"], r.stderr, file=sys.stderr)
    else:
        print(r.stdout.strip())


def main() -> int:
    print("Labels...")
    for name, color, desc in LABELS:
        ensure_label(name, color, desc)
    print("Milestones...")
    for title, desc in MILESTONES:
        ensure_milestone(title, desc)
        time.sleep(0.2)
    print(f"Issues ({len(ISSUES)})...")
    for i, item in enumerate(ISSUES, 1):
        create_issue(item)
        if i % 5 == 0:
            time.sleep(1)
        else:
            time.sleep(0.35)
    print("Done:", len(ISSUES), "issues")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
