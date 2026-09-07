# Task List: Quick Social

Companion to `tasks/plan.md`. Work top to bottom; do not start a task whose dependencies are unchecked.

**Scope confirmed 2026-09-07:** state management is `provider`; all of Phase 4 (T12–T18) is in scope.
All 21 tasks below are committed work.

**Standing rules for every task (Definition of Done):**

- `flutter analyze` reports no issues.
- `flutter test` passes.
- The app still runs (`flutter run -d chrome`) and the touched screen was looked at, not just compiled.
- No new lint suppressions (`// ignore:`) without a comment explaining why.
- **No `git commit` and no `git push`** — the human does that.

**Commands referenced below:**

```bash
flutter analyze
```

```bash
flutter test
```

```bash
MSYS_NO_PATHCONV=1 flutter build web --base-href /quick_social/
```

---

## Phase 0 — Guardrails

### Task 1: Test harness and CI quality gate — **DONE**

**Description:** Create the `test/` directory with a smoke test and the first widget tests, add a
`test/helpers/` pump helper, and extend the GitHub Actions workflow so `flutter analyze` and
`flutter test` run before the deploy job. Also correct the `pubspec.yaml` description and bump
`google_fonts` to 8.2.1. Nothing else changes until this exists — it is the regression net for every
task after it.

**Acceptance criteria:**
- [x] `test/widget/app_smoke_test.dart` pumps `MyApp` and asserts the splash logo renders.
- [x] `test/helpers/pump_app.dart` exposes a `pumpApp(tester, widget)` helper that wraps a widget in
      `MaterialApp` with the app theme, so later tests do not repeat the boilerplate.
- [x] `.github/workflows/deploy.yml` runs `flutter analyze` and `flutter test` as steps in the `build`
      job, before `flutter build web`; a failure in either blocks the deploy.
- [x] `pubspec.yaml` description reads as a real description, not "A new Flutter project."

**Verification:**
- [x] `flutter test` passes locally — 2 tests green.
- [x] `flutter analyze` clean.
- [x] Deliberately broke an assertion, `flutter test` failed, restored it.

**Dependencies:** None

**Files touched:**
- `test/widget/app_smoke_test.dart` (new)
- `test/helpers/pump_app.dart` (new)
- `test/helpers/mock_network_images.dart` (new — see note)
- `.github/workflows/deploy.yml`
- `pubspec.yaml` (description, `google_fonts` 8.2.0 → 8.2.1)

**Estimated scope:** S (3 files) — **actual: 5 files**

**Notes from implementation:**
- A third helper was needed and was not in the original plan. The widget-test binding fails every HTTP
  request with a 400, so any widget containing an `Image.network` throws and the test fails.
  `test/helpers/mock_network_images.dart` installs an `HttpOverrides` that serves a 1x1 transparent PNG
  for every request. Every image-bearing widget test in T7–T11 depends on it.
- `pump_app.dart` also exports `phoneSize` / `tabletSize` / `desktopSize` constants. The binding's
  800x600 default sits just inside the app's own tablet breakpoint (768), which makes "default size"
  tests quietly exercise the tablet layout — worth naming explicitly.
- **Correction, made during T4:** the first version of `setSurfaceSize` used
  `tester.binding.setSurfaceSize`, which does **not** reach `MediaQuery`. Every test written in T1 and
  T3, and the width sweep that first found E21, therefore ran at 800x600 no matter what size they asked
  for — silently exercising the tablet layout. It now sets `tester.view.physicalSize` and
  `devicePixelRatio` instead. The E21 width figures in `plan.md` were re-measured afterwards and the
  original claim ("every tablet and desktop width") was wrong; the corrected range is recorded there.
  Lesson for later tasks: assert the viewport actually took effect before trusting a layout test.
- `pump_app.dart`'s `testAppTheme()` duplicates the theme currently inlined in `MyApp.build`. **T3 must
  delete it** and point the helper at `AppTheme.light()`.
- The smoke test has to drain the splash screen's 3-second delay, or the binding fails with
  "A Timer is still pending even after the widget tree was disposed". **T4 should simplify this** once
  the splash navigates from `initState`.
- **The harness immediately found a new defect, E21** (post action row overflows at every tablet and
  desktop width). Logged in `tasks/plan.md` and added to T7b's acceptance criteria.

---

### Task 2: Modernize the web bootstrap and metadata (E1, E18) — **DONE**

**Description:** `web/index.html` uses `FlutterLoader.loadEntrypoint` and the manual
`serviceWorkerVersion` variable, both deprecated and warned about on every build. Replace the bootstrap
with the current `_flutter.loader.load()` form and the `{{flutter_service_worker_version}}` token, then
fix the app metadata that is still Flutter-template boilerplate.

**Acceptance criteria:**
- [x] `flutter build web` emits no `loadEntrypoint` or service-worker deprecation warnings.
- [x] `web/index.html` title, description, and `apple-mobile-web-app-title` name the real app.
- [x] `web/manifest.json` name, short name, description, and `theme_color`/`background_color` match the
      app's actual brand colour; `orientation` is `any` rather than `portrait-primary`, since the app
      ships a desktop layout.
- [x] The built app still loads and reaches the feed when served locally.

**Verification:**
- [x] `MSYS_NO_PATHCONV=1 flutter build web --base-href /quick_social/` — no deprecation warnings.
- [x] Served `build/web`, app boots to the feed, tab title is "Quick Social", no console errors.
- [x] `flutter analyze` clean, `flutter test` green.

**Dependencies:** None (independent of T1)

**Files touched:**
- `web/index.html` (rewritten on the current template)
- `web/manifest.json`
- `lib/app.dart` (one line — see note)

**Estimated scope:** XS (2 files) — **actual: 3 files**

**Notes from implementation:**
- The whole inline bootstrap is gone. The current template is a single
  `<script src="flutter_bootstrap.js" async></script>`; `serviceWorkerVersion` and
  `loadEntrypoint` no longer exist. Also swapped the deprecated `apple-mobile-web-app-capable` for
  `mobile-web-app-capable`, and added the missing `viewport` meta (the file had none, so mobile
  browsers were free to apply a virtual viewport).
- **Beyond the stated criteria:** added a themed pre-boot splash. Before this, the user stared at a
  blank white page for the whole `main.dart.js` download, *then* got the in-app 3-second splash. Now
  the first paint is the brand wordmark on the app's surface colour, removed on the
  `flutter-first-frame` event with a `setTimeout` fallback. Honours `prefers-color-scheme` and
  `prefers-reduced-motion`.
- Brand colours are not guesses. Probed `ColorScheme.fromSeed(seedColor: Colors.tealAccent)`:
  light `primary #0d6b58`, light `surface #f5fbf7`, dark `surface #0f1513`, dark `primary #86d6bf`.
  `theme_color` is the light primary; `background_color` is the light surface, so the manifest splash
  and the boot splash match. **T3 should reuse these values** rather than re-deriving them.
- `MaterialApp(title:)` was `'Quick Social App'` while the HTML said `'Quick Social'`. Flutter
  overwrites `document.title` at runtime, so the HTML title alone does not settle it — changed the
  `MaterialApp` title to match. One line in `lib/app.dart`.

**Handoff to T3:** the Flutter web engine injects its own
`<meta name="theme-color" content="rgba(0,0,0,0)">` at runtime, which overrides the two declared in
`index.html` and leaves mobile browser chrome untinted. Fix it by calling
`SystemChrome.setSystemUIOverlayStyle` from the app once the theme exists.

---

### Checkpoint: Phase 0 — **PASSED**

- [x] `flutter analyze` clean, `flutter test` green (2 tests)
- [x] `flutter build web` warning-free
- [x] CI fails when a test fails (verified locally by breaking an assertion)

---

## Phase 1 — Foundation

### Task 3: Design tokens, Material 3 light and dark themes, bundled font (E14, E15) — **DONE**

**Description:** Build the visual foundation the rest of the modernization sits on: a tokens file
(spacing, radii, elevation, animation durations), a `ThemeData` builder producing matched light and dark
`ColorScheme`s from the seed, component themes for `NavigationBar`, `NavigationRail`, `Card`,
`FilledButton`, and `AppBar`, DM Sans bundled as an asset instead of fetched by `google_fonts`, and a
`PrefsService` wrapper over `SharedPreferences` plus a `ThemeController` so the user's theme choice
persists.

**Acceptance criteria:**
- [x] `lib/theme/` contains `app_theme.dart` (light and dark), `app_tokens.dart` (spacing, radii,
      durations), and no colour or spacing literal remains in `lib/app.dart`.
- [x] DM Sans (weights 400/500/700) ships in `assets/fonts/` and is declared in `pubspec.yaml`;
      `google_fonts` is removed from the dependencies.
- [x] `MaterialApp` supplies `theme`, `darkTheme`, and a `themeMode` driven by a persisted setting whose
      default is `ThemeMode.system`.
- [x] Every text and surface colour pair meets WCAG AA contrast in both themes — enforced by a test
      rather than eyeballed.

**Verification:**
- [x] `flutter test` — 15 tests green, including brightness, font family, contrast, and persistence.
- [x] `flutter analyze` clean.
- [x] Manual: built and served the web app. Dark scheme renders dark, light renders light. The three
      DM Sans weights are fetched from `/assets/assets/fonts/`, and there are **zero** requests to
      `fonts.gstatic.com` — E15 closed and provable.

**Dependencies:** T1

**Files touched:**
- `lib/theme/app_theme.dart`, `lib/theme/app_tokens.dart` (new)
- `lib/services/prefs_service.dart`, `lib/state/theme_controller.dart` (new)
- `lib/app.dart`, `lib/main.dart`, `lib/common/build_context_extension.dart`
- `pubspec.yaml`, `assets/fonts/` (3 TTFs + `OFL.txt`)
- `test/helpers/pump_app.dart`, `test/helpers/test_prefs.dart` (new)
- `test/unit/app_theme_test.dart`, `test/unit/theme_controller_test.dart` (new)
- `test/widget/app_smoke_test.dart`

**Estimated scope:** M (5 files plus assets) — **actual: 13 files**

**Notes from implementation:**
- **Fonts.** `google/fonts` only ships DM Sans as a variable font now, and Flutter needs explicit
  `FontVariation` to hit a weight on one of those — `FontWeight.bold` would have been faux-bolded.
  Pulled static instances from the Google Fonts CSS API instead, using a legacy Android user agent so
  it serves `.ttf` rather than `.woff2`. (An IE6 user agent serves `.eot`, which Flutter cannot read —
  first attempt, caught by checking the magic bytes.) Three latin-subset files, ~48KB each, ~145KB
  total. `OFL.txt` ships beside them, which vendoring an OFL font requires.
- **Contrast is tested, not eyeballed.** `test/unit/app_theme_test.dart` computes WCAG relative
  luminance and asserts 4.5:1 across eight foreground/background pairs in both brightnesses, plus
  `primary` on `surface` since the app uses primary for accent text and icons. All pass at the
  tealAccent seed.
- **`ThemeData.fontFamily` is a trap.** It does not override a family already baked into an explicit
  `textTheme`, so the theme silently stayed on Roboto. Caught by the font-family test. The family is
  now applied via `TextTheme.apply` instead. Worth remembering for T16 and T19.
- **Tokens are the source of truth for breakpoints too.** `BuildContextX.isMobile/isTablet/isDesktop`
  had 768 and 1024 hardcoded; they now read `AppBreakpoints`. `AppBreakpoints.maxContentWidth` (640)
  is defined and unused — T19 replaces `ResponsivePadding`'s `width/6` guesswork with it.
- **No `provider` yet.** `ThemeController` reaches `MyApp` by constructor and drives rebuilds through
  `ListenableBuilder`. T6 introduces `MultiProvider` and should fold it in there.
- **T2 handoff closed.** The engine was injecting `<meta name="theme-color" content="rgba(0,0,0,0)">`
  because `SystemUiOverlayStyle.statusBarColor` was transparent — correct for Android edge-to-edge,
  useless for browser chrome. Now branches on `kIsWeb`: the surface colour on web, transparent on
  mobile. Verified — the engine's transparent meta is gone.

**Handoff to T10:** `NotificationTile` renders read notifications with
`onSurface.withAlpha(150)` and their timestamps with `theme.disabledColor`. Both defeat the theme's
contrast guarantees at the widget level. Use `onSurfaceVariant` instead.

---

### Task 4: App shell lifecycle fixes (E2, E3) — **DONE**

**Description:** Two real lifecycle bugs. `SplashPage` schedules its navigation from `build()`, so every
rebuild queues another push, and it uses `push` rather than `pushReplacement`, leaving the splash on the
back stack. `HomePage` builds a fresh `PageController` inside `build()`, leaking every previous one and
risking `jumpToPage` on a detached controller. Convert the splash to a `StatefulWidget` that navigates
once from `initState`, and hoist the `PageController` into `_HomePageState`.

**Acceptance criteria:**
- [x] `SplashPage` is stateful; the navigation is scheduled once in `initState`, guarded by `mounted`,
      and its `Timer` is cancelled in `dispose`.
- [x] Navigating away from the splash uses `pushReplacement`, so system back from the feed exits the app
      instead of returning to the splash.
- [x] `_HomePageState` creates exactly one `PageController` as a `final` field and disposes it.
- [x] Switching tabs by tapping the navigation bar and by swiping the `PageView` both keep the selected
      index in sync, with no console assertions.

**Verification:**
- [x] `flutter test` — 24 tests green, run twice to check for flakiness. `home_page_test.dart` covers
      tap, swipe, non-adjacent jump, 20 consecutive switches, controller disposal, and the breakpoint.
- [x] `flutter analyze` clean.
- [x] Manual: built and served the web app; splash holds once, hands off to the feed, tab switching is
      clean in both directions.

**Dependencies:** T3

**Files touched:**
- `lib/pages/splash_page.dart`, `lib/pages/home_page.dart`
- `lib/common/build_context_extension.dart` (added `pushReplacement`)
- `test/widget/home_page_test.dart`, `test/helpers/known_defects.dart` (new)
- `test/helpers/pump_app.dart` (viewport fix), `test/widget/app_smoke_test.dart`

**Estimated scope:** S (3 files) — **actual: 7 files**

**Notes from implementation:**
- **The T1 viewport helper was broken, and it mattered.** `tester.binding.setSurfaceSize` does not
  reach `MediaQuery`, so every test written so far ran at 800x600 regardless of the size it requested —
  i.e. the *tablet* layout, on a helper constant named `phoneSize`. Switched to `tester.view`. This is
  what exposed E22, and it invalidated the original E21 width claim (both corrected in `plan.md`).
- **E22 found:** the notifications header overflows by 201px at phone width. Real, and severe — the
  "mark all read" button is mostly off-screen on any phone. Assigned to T10.
- Known layout defects are now suppressed *explicitly and traceably*:
  `test/helpers/known_defects.dart` drains `RenderFlex overflowed` exceptions and rethrows anything
  else, and every call site names the defect id. T7b and T10 delete their own suppressions.
- **Splash hold cut from 3s to 1.5s** (`SplashPage.holdDuration`). Nothing loads during it — startup
  work finishes before `runApp` — so three seconds was dead time on top of the pre-boot splash the web
  build already shows. Not in the original acceptance criteria; flagging it as a deliberate change.
- Tapping a non-adjacent destination jumps instead of animating, so 0 → 2 does not build the
  notifications page on the way past. Adjacent moves animate over `AppDuration.medium`.
- `NavigationBar` and `NavigationRail` shed their per-widget colours, label styles, and height — T3's
  component themes own those now, and the duplicates would have drifted. Destinations are built from a
  single list, so the bar and the rail cannot disagree. Added tooltips, which matter because the theme
  hides the labels.
- `pumpAndSettle` on the feed is unreliable: 30 posts build eagerly (E12) and one image left in its
  loading builder keeps an indeterminate spinner running forever. The smoke test uses explicit pumps.
  T7a should make this go away.

---

### Checkpoint A — after T4 — **PASSED**

- [x] `flutter analyze` clean, `flutter test` green (24 tests, run twice for flakiness)
- [x] The app launches to the feed exactly once, and the splash is replaced rather than stacked —
      asserted by `SplashPage` being absent from the tree, offstage included
- [x] Dark mode follows the OS; an explicit choice survives a restart
- [x] No `PageController` assertions after repeated tab switching — covered by a test rather than a
      console glance, plus a test that the controller is actually disposed
- [ ] **Human review before proceeding**

**Carried into Phase 2:** two layout defects are open and explicitly suppressed in tests — E21 (post
action row, fixed in T7b) and E22 (notifications header, fixed in T10). Both have measured widths in
`plan.md`, and both suppressions name their defect id so they cannot be forgotten.

---

## Phase 2 — Data and state

### Task 5: Deterministic, correct data source (E5, E6, E7) — **DONE**

**Description:** The dummy data is generated by scattered `Random()` calls with three off-by-one bugs and
no stable seed, which makes both the data and any test flaky. Consolidate generation into a
`DummyDataSource` driven by a single seeded `Random`, fix the ranges, and give the models the fields the
later features need: a stable `id`, a `createdAt` timestamp on posts and comments, and value equality.

**Acceptance criteria:**
- [x] `Random(seed)` is used once; two runs of the app produce identical users, posts, and comments.
- [x] All five users own at least one post and appear in at least one comment (E7 closed).
- [x] `follow` notifications are generated (E6 closed).
- [x] Comment counts cannot be zero for now (E5 closed) — see the note about handing this back to T8.
- [x] `User`, `Post`, `Comment`, `Story`, `UserStory`, and `UserNotification` carry a stable `id`;
      `Post`, `Comment`, `Story`, and `UserNotification` carry `createdAt`; all override `==` and
      `hashCode` on `id`.
- [x] No model class holds mutable `static` state any more.

**Verification:**
- [x] `flutter test` — 16 new unit tests; 40 green in total.
- [x] `flutter analyze` clean.
- [x] Verified the generated picsum URLs resolve: `https://picsum.photos/seed/post-p1/960/960` → 200,
      104KB, and confirmed during T7a that the seeded images render correctly in the running app —
      distinct avatar per user, distinct photo per post.

      **Correction (made in T7a):** an earlier version of this note claimed the in-app test browser
      blocks external image hosts, based on two runs where every avatar came back blank. That was
      wrong — picsum was simply slow or failing at the time. Images load fine there. The real lesson is
      the opposite one: a slow image host makes E11 (no `errorBuilder` on avatars and the profile
      banner) very visible, which is worth remembering for T7b and T15.

**Dependencies:** T1

**Files touched:**
- `lib/data/dummy_data_source.dart` (new)
- `lib/models/user.dart`, `post.dart`, `comment.dart`, `user_notification.dart`, `story/story.dart`,
  `story/user_story.dart`
- `lib/pages/feed_page.dart`, `home_page.dart`, `notifications_page.dart`, `profile_page.dart`,
  `user_story_page.dart`
- `lib/widgets/comments_bottom_sheet.dart`, `notification_tile.dart`, `user_story_tile.dart`
- `test/unit/dummy_data_source_test.dart` (new)

**Estimated scope:** M (5 files) — **actual: 15 files**

**Notes from implementation:**
- **`faker.internet.userName()` is not deterministic, even with a seeded `Faker`.** It calls
  `List.shuffle()` with no argument, and the no-arg form constructs its own unseeded `Random`. The
  determinism test caught it immediately (`angelo.olson` vs `olson.angelo` from the same seed).
  Usernames are now composed from `person.firstName()` / `lastName()` plus a seeded separator. Audited
  the rest of the package: the only other unseeded call is in the deprecated `image.image()`, which
  this app does not use.
- **Coverage is guaranteed by construction, not by luck.** `_ownerFor(index)` assigns round-robin while
  the index is still inside the user list and randomly after that, so every user owns a post and — via
  a counter that spans all posts — appears in a comment. Notification types are round-robined the same
  way, which is what actually makes `follow` reachable. A test that merely sampled random data would
  pass by accident; these pass by design.
- **Images are seeded per entity.** `loremPicsum(seed: 'post-p7', …)` gives every user, post, and story
  a distinct image that is the same on every run. The old `random: nextInt(5)` drew from five images
  for the whole app, which is why avatars kept repeating.
- **Timestamps are relative to an injected `now`.** `DummyDataSource({int seed, DateTime? now})` lets
  tests pin the clock, so two sources built with the same seed are equal down to their `createdAt`
  values. Posts are ordered newest-first and that ordering is asserted.
- **`UserNotification` stores an `actor`, not a pre-built sentence.** The old model baked Indonesian
  strings into the data layer (part of E13). The wording now lives in `NotificationTile`, in English,
  where T16 can lift it into ARB files without touching the data.
- **`DummyDataSource.instance` is a deliberate stopgap.** Widgets read it directly so the app keeps
  working; T6 replaces those reads with repositories behind `MultiProvider` and should delete the
  singleton.

**Handoff to T8:** comment counts are forced to 1–12 so no post opens a blank sheet. That is hiding a
missing empty state rather than modelling reality. Once T8 ships the empty state, widen the range back
to include zero and relax the `no post has zero comments — E5` test in
`test/unit/dummy_data_source_test.dart`.

---

### Task 6: Repository and provider layer with persistence (E8, E16) — **DONE**

**Description:** Introduce the state layer that the interaction bugs need. `FeedRepository` (likes,
saves), `SocialRepository` (follows), and `NotificationRepository` (read state) are `ChangeNotifier`s
that read and write through `PrefsService` under a versioned key namespace. Wire them at the root with
`MultiProvider`. Widgets stop owning interaction state.

**Acceptance criteria:**
- [x] Toggling a like, a save, a follow, or a read flag persists across an app restart.
- [x] `_ToggleButton` and `NotificationTile` are stateless; both read from and write to a repository.
- [x] Preference keys are namespaced and versioned (`qs.v1.likedPostIds`, and so on); keys from an
      unknown version are discarded on open rather than handed back to the app.
- [x] The repositories import only `flutter/foundation.dart` — no widget imports, verified by grep, and
      all three are tested in plain `test` files.

**Verification:**
- [x] `flutter test` — 68 green, run twice. 22 new: unit tests per repository plus six widget tests that
      drive the real UI.
- [x] `flutter analyze` clean.

**Dependencies:** T3, T5

**Files touched:**
- `lib/repositories/feed_repository.dart`, `social_repository.dart`, `notification_repository.dart`,
  `repositories.dart` (new)
- `lib/app.dart` (MultiProvider), `lib/main.dart`
- `lib/models/post.dart`, `lib/models/user_notification.dart` (fields removed — see notes)
- `lib/widgets/post_card.dart`, `notification_tile.dart`, `widgets.dart`
- `lib/pages/notifications_page.dart`, `profile_page.dart`
- `test/unit/repositories/*_test.dart`, `test/widget/state_persistence_test.dart` (new)
- `test/helpers/pump_app.dart`, `test/widget/app_smoke_test.dart`
- `pubspec.yaml` (`provider`)

**Estimated scope:** M (5 files plus tests) — **actual: 17 files**

**Notes from implementation:**
- **The model fields had to go, not just the widget state.** `Post.isLiked` / `isSaved` and
  `UserNotification.isRead` were deleted outright. Leaving them would have left two answers to the same
  question — the model's and the repository's — which is the shape of the original bug. The counts on
  `Post` are now explicitly "everyone else's", and the repository adds the signed-in user's own like on
  top, so the seed data stays immutable.
- **The widget tests are the ones that prove E16.** A unit test on the repository only shows the
  repository works. `state_persistence_test.dart` taps the real like button, navigates away so the
  button is disposed, comes back, and asserts the like is still there — exactly the sequence that used
  to lose it. Two more assert against stored prefs directly, and one starts from stored state to prove
  the first frame is already correct.
- **`tester.tap` on an overflowed widget silently does nothing.** The "mark all read" test failed with
  0 stored ids because E22 pushes that button off the right edge at phone width, so the tap landed on
  nothing — no error, just no effect. Moved that test to desktop width, where the header fits. Move it
  back to `phoneSize` when T10 fixes E22.
- `NotificationTile`'s unread dot carries `unreadDotKey`, so tests count unread tiles without reaching
  into the tile's internals.
- The profile Follow button is wired and switches to an outlined "Following" state; the follower count
  moves with it. T11 still owns the rest of that page.
- **Not done here, deliberately:** comment likes still keep local state — T8 owns those, and adding a
  fourth repository now would have pre-empted its design. `DummyDataSource.instance` also survives: it
  is immutable seed data, not the mutable state this task was about. T7a and T11 finish that migration
  when they rebuild their pages.
- `pumpApp` now wraps the widget under test in the same `MultiProvider` the app uses, and takes an
  optional `PrefsService` so a test can seed stored state or inspect what the UI wrote.

---

### Checkpoint B — after T6 — **PASSED**

- [x] All five users are visible across the app; `follow` notifications appear — guaranteed by
      construction in the data source, not left to chance
- [x] Like, save, follow, and read state all survive a restart — proved at both levels: a repository
      round-trip, and widget tests that drive the real buttons
- [x] Repository unit tests green (68 tests overall, run twice)
- [ ] **Human review before proceeding**

**Carried into Phase 3:** E21 (post action row, T7b) and E22 (notifications header, T10) are still
open and suppressed in tests. E22 now also forces one widget test to run at desktop width, because the
button it needs to tap is off-screen at phone width.

---

## Phase 3 — Vertical UI slices

### Task 7a: Feed rebuilt on slivers, with refresh and skeletons (E12) — **DONE**

**Description:** Replace the nested `shrinkWrap` lists with a `CustomScrollView`: a `SliverAppBar` for
the header, a sliver for the story row, and a `SliverList.separated` for posts, so posts build lazily.
Add pull-to-refresh, incremental loading as the user reaches the end, and skeleton placeholders instead
of a bare spinner.

**Acceptance criteria:**
- [x] Posts build lazily — **2 of 30 `PostCard`s are constructed** after the first load, measured.
- [x] Pull-to-refresh reloads the feed and shows the refresh indicator.
- [x] Reaching the end of the list appends the next page; a footer spinner shows while it loads, and a
      "You are all caught up" line replaces it at the end.
- [x] Skeleton placeholders occupy the same footprint as a loaded post.
- [x] An empty feed shows a designed empty state, not a blank screen.

**Verification:**
- [x] `flutter test` — 10 new tests; 78 green in total. The laziness assertion is a measurement, not a
      guess: `built=2, total=30`.
- [x] `flutter analyze` clean.
- [x] Built and served the web app; scrolled at phone and desktop widths.

**Dependencies:** T6

**Files touched:**
- `lib/pages/feed_page.dart` (rewritten)
- `lib/widgets/common/skeleton_box.dart`, `common/empty_state.dart`, `feed/post_skeleton.dart` (new)
- `lib/widgets/loading_image_widget.dart` (spinner replaced by a skeleton block)
- `lib/widgets/widgets.dart`, `lib/data/dummy_data_source.dart` (injection seam)
- `test/widget/feed_page_test.dart` (new)

**Estimated scope:** M (4 files) — **actual: 8 files**

**Notes from implementation:**
- **The nested-list structure is gone.** `CustomScrollView` with `SliverToBoxAdapter` for the story rail
  and `SliverList.separated` for posts. Measured on a phone viewport: **2 `PostCard`s built out of 30**,
  where the old `shrinkWrap` list built all 30 on the first frame. E12 closed.
- **Counting built widgets measures laziness, not paging.** My first attempt asserted that the built
  card count grew after scrolling — it does not, and should not: the window slides. Paging is asserted
  through observable behaviour instead (the footer spinner appears, and "You are all caught up" shows
  only after walking every page).
- **`pumpAndSettle` does not advance a pending `Timer`.** A timer schedules no frames, so settling
  returns before the simulated fetch fires. Tests need an explicit `pump(fetchDelay)`. Worth knowing
  for every later task that adds an async load.
- **The skeleton is deliberately still.** A shimmer is an animation that never ends, which makes
  `pumpAndSettle` hang in every test that renders a loading state. T20 can add one behind a
  reduced-motion check.
- **`LoadingImageWidget` lost its spinner** for the same reason, and for a better one: a spinner per
  image on a long feed reads as "something is wrong". It is now a neutral skeleton block. This is what
  finally makes `pumpAndSettle` usable on the feed — the constraint that has been forcing explicit
  pumps since T4.
- **The simulated fetch is cancellable.** `Future.delayed` cannot be cancelled, so tearing the tree down
  mid-fetch failed three existing tests with "A Timer is still pending". Replaced with a `Timer` plus a
  `Completer` that `dispose` cancels and completes. Same class of bug as E2 in the splash.
- **Two injection seams added, both defensible on their own terms:** `FeedPage({DummyDataSource? source})`
  and `DummyDataSource({int postCount})`. The empty state is a real branch, and without a way to produce
  an empty feed it could only ever be asserted by reading the code.
- `FeedPage.fetchDelay` (250ms) stands in for a network round trip. Without it the loading states would
  never be visible, or exercised. It is a constant, in one place, clearly labelled.

---

### Task 7b: Post card redesign and wired interactions (E11, E16, E21) — **DONE**

**Description:** Modernize the card — rounded corners, a consistent spacing rhythm, a cached image with a
fixed aspect ratio so there is no layout shift, a relative timestamp ("2h"), an animated like with
haptic feedback, double-tap-to-like, and a working share action. Likes and saves read from
`FeedRepository`, so counts are correct everywhere the post appears.

**Acceptance criteria:**
- [x] Every image in the card goes through `AppNetworkImage`, which wraps `CachedNetworkImage` with the
      existing loading and error widgets.
- [x] Like and save reflect repository state and stay correct after switching tabs and back.
- [x] Double-tapping the image likes the post and plays a brief heart burst.
- [x] Posts show a relative timestamp derived from `createdAt`.
- [x] Share opens the platform share sheet.
- [x] The tablet and desktop layouts survive a 500-character caption and a 56-character username.
- [x] **E21 closed:** `HomePage` pumps cleanly at 360, 390, 430, 600, 768, 800, 834, 900, 1024, 1200,
      and 1440 — one test per width, asserting `takeException()` is null.
- [x] The E21-driven workaround is gone: `home_page_test.dart` asserts the rail at **tablet** width
      again, not just desktop.

**Verification:**
- [x] `flutter test` — 22 new tests; 101 green in total.
- [x] `flutter analyze` clean.
- [x] Built and served the web app.

**Dependencies:** T7a

**Files touched:**
- `lib/widgets/post_card.dart` (rewritten), `post_button.dart`, `comment_tile.dart`
- `lib/widgets/common/app_network_image.dart`, `lib/common/time_ago.dart` (new)
- `lib/pages/feed_page.dart` (app bar logo), `lib/common/common.dart`, `lib/widgets/widgets.dart`
- `test/widget/post_card_test.dart` (new), `test/helpers/mock_network_images.dart`,
  `test/widget/home_page_test.dart`, `feed_page_test.dart`, `state_persistence_test.dart`
- `pubspec.yaml` (`cached_network_image`, `share_plus`)

**Estimated scope:** M (4 files) — **actual: 14 files**

**Notes from implementation:**
- **E21 had three causes, not one.** Removing `IntrinsicHeight` fixed the tablet band, but the width
  sweep then found two more: the feed's app-bar `Row` (`AppLogo` + icon button) overflowed by 5.5px at
  360, and the post header's title `Row` — username plus timestamp — overflowed by 18px whenever the
  wide card's text column got narrow. A `Row` of two `Text`s needs *both* flexible; the fix is a single
  `Text.rich` with one ellipsis. The logo is now `Flexible` + `FittedBox(scaleDown)`.
  **The original diagnosis was incomplete, and only the parameterised sweep showed that.**
- **The like burst was swallowing the second double-tap.** The heart sits over the image, so the second
  double-tap hit the icon rather than the gesture detector — the test failed with "would not hit test on
  the specified widget". Wrapped in `IgnorePointer`. A decorative overlay should never be hit-testable.
- **`DoubleTapGestureRecognizer` leaves a countdown timer.** Tests have to pump past it or the binding
  reports a pending timer. Same family as the splash and fetch timers.
- **`CachedNetworkImage` cannot run under `flutter_test`** — it reaches the file system through
  `path_provider`, which has no test implementation, so it throws `MissingPluginException` instead of
  falling back. `AppNetworkImage.debugProviderOverride` swaps in an in-memory provider; the shared test
  helper sets it. This is production code that knows about tests, which is worth being uneasy about, but
  the alternative is either no image tests or a fake cache manager in every test file.
- **`AppAvatar` falls back to the owner's initial.** `CircleAvatar(backgroundImage: NetworkImage(...))`
  has no error path at all — a failed load is a coloured disc with no explanation, which is exactly what
  I kept seeing in the browser. Asserted by a test that forces the provider to fail.
- The post image is now a fixed 1:1 `AspectRatio`, so the card reaches its final height before the image
  arrives and nothing below it jumps.
- Added: a "more options" sheet on the header (view profile, share), tooltips on every action, and
  `maxLines`/ellipsis on username and location.

**Handoff to T9, T11, and T15:** four raw network images remain outside the post card —
`profile_page.dart:102` (banner), `user_posts_tab_view.dart:57` (grid), `user_story_avatar.dart:30`,
`user_story_page.dart:77` and `:103`, and `comment_tile.dart:21`. `AppNetworkImage` and `AppAvatar` are
ready for them; T15's `grep -rn "Image.network" lib/` criterion covers the sweep.

---

### Task 8: Comment sheet fixes and redesign (E4, E5) — **DONE**

**Description:** Fix the controller created in `build()`, then make the sheet behave like a real comment
sheet: a draggable scrollable sheet, an empty state, relative timestamps, delete-your-own-comment, and
persisted comment likes.

**Acceptance criteria:**
- [x] The `TextEditingController` lives in the `State`, is disposed, and is explicitly cleared on submit.
- [x] Submitting an empty or whitespace-only comment is a no-op; the text is trimmed.
- [x] A post with no comments shows an empty state instead of a blank sheet.
- [x] The sheet uses `DraggableScrollableSheet` (0.4 to 0.95, opening at 0.7).
- [x] The user's own comments can be deleted, behind a confirmation; other users' have no delete action.
- [x] Comment likes persist through `CommentRepository`.

**Verification:**
- [x] `flutter test` — 15 new tests; 116 green in total.
- [x] `flutter analyze` clean.
- [x] Built and served the web app.

**Dependencies:** T6

**Files touched:**
- `lib/repositories/comment_repository.dart` (new), `repositories.dart`, `lib/app.dart`
- `lib/widgets/comments_bottom_sheet.dart` (rewritten), `comment_tile.dart` (rewritten),
  `post_card.dart`
- `lib/data/dummy_data_source.dart` (comment range)
- `test/widget/comments_sheet_test.dart` (new), `test/unit/dummy_data_source_test.dart`,
  `test/helpers/pump_app.dart`

**Estimated scope:** S (3 files) — **actual: 10 files**

**Notes from implementation:**
- **E4 was two bugs, not one.** The controller built in `build()` was never disposed, and it only
  *appeared* to clear on submit because the old one was thrown away with the frame. Both fixed by owning
  it in the `State`. A test asserts the field is genuinely empty afterwards.
- **The sheet was mutating shared app data.** `_submitComment` appended straight into `post.comments` —
  the same growable list the whole app reads. `CommentRepository` now owns added and deleted comments,
  and a test asserts `post.comments` is untouched after a submit.
- **A modal route builds outside the providers.** `showModalBottomSheet` uses the navigator's context,
  so the sheet could not see `CommentRepository`. It is passed down explicitly with
  `ChangeNotifierProvider.value`. Worth remembering for T14 and T17, which both open modals.
- **`_CommentButton` lost its local state too.** The count comes from the repository, so it updates
  while the sheet is open rather than only after it closes — the old `.then()` refresh was working
  around exactly that.
- The delete action is an icon, not a labelled button: the action row is a row of counts, and a "Delete"
  label read as one of them — and it also made `find.text('Delete')` ambiguous with the confirmation
  dialog, which is how I noticed.
- **T5's handoff is closed.** Comment counts are back to 0–12. Measured on the default seed: **3 of 30
  posts have no comments**, so the new empty state is reachable in the real app rather than only in
  tests. `dummy_data_source_test.dart` now asserts the range instead of forbidding zero, and the comment
  tests pick `posts.firstWhere((p) => p.comments.isNotEmpty)` rather than assuming `posts.first` has
  any.

**Note for T14:** comments the user writes live in memory for the session. Persisting user-authored
content needs serialisation, which is T14's problem for posts — extend it to comments there rather than
inventing a second scheme here.

---

### Task 9: Story ring, seen state, and viewer wrapper (E11) — **DONE**

**Description:** Wrap the `story` package in our own `StoryViewer` so the dependency is isolated, then
give the story row the affordance it is missing: a gradient ring for unseen stories, a muted ring for
seen ones, a "Your story" entry with an add button, and seen state persisted.

**Acceptance criteria:**
- [x] `lib/widgets/story/story_viewer.dart` is the only file importing `package:story` — verified by
      grep over `lib/`.
- [x] Unseen stories show a gradient ring; viewing one mutes it, and that survives a restart.
- [x] The row begins with a "Your story" tile carrying an add badge.
- [x] Story images go through `AppNetworkImage`, with its loading and error states.
- [x] The story header shows a relative timestamp and a working close button.

**Verification:**
- [x] `flutter test` — 10 new tests; 126 green in total, run twice.
- [x] `flutter analyze` clean.
- [x] Built and served the web app.

**Dependencies:** T6

**Files touched:**
- `lib/repositories/story_repository.dart`, `lib/widgets/story/story_viewer.dart` (new)
- `lib/widgets/user_story_avatar.dart`, `user_story_tile.dart` (rewritten)
- `lib/pages/user_story_page.dart` (rewritten), `lib/pages/feed_page.dart`
- `lib/app.dart`, `lib/repositories/repositories.dart`, `lib/widgets/widgets.dart`
- `test/widget/story_tile_test.dart` (new), `test/helpers/pump_app.dart`

**Estimated scope:** M (5 files) — **actual: 11 files**

**Notes from implementation:**
- **Seen state is per owner, not per story.** The ring in the feed is about a person, and dimming it the
  moment their set is opened is what the affordance means. It also keeps storage to one id per user.
  `StoryRepository.ordered()` sorts the rail: you first, then anyone unseen, then the rest.
- **The old ring was a `CircularProgressIndicator(value: 1)`** — it looked identical whether or not
  there was anything new, so the whole affordance said nothing. Now a gradient for unseen and a flat
  outline for seen, asserted by reading the decoration off the widget.
- **`pumpAndSettle` destroys any test of the story viewer.** The indicator auto-advances, so settling
  plays every story of every owner, hits the page limit, and pops the viewer — three tests failed with
  "UserStoryPage not found" and I initially misread it as a navigation bug. Explicit pumps only. The
  helper in the test file says so, because the next person will hit this too.
- **`find.textContaining` does match `Text.rich`**, contrary to what the same three failures suggested;
  the text really was absent because the viewer had already closed itself. Checked directly with a
  probe rather than assuming.
- Marking seen happens in a post-frame callback: it notifies listeners, and doing that from `initState`
  would rebuild widgets mid-build.
- `StoryViewer` exposes seven parameters and hides the package entirely. If `story` breaks on a future
  Flutter release, this one file is the blast radius.

**Handoff to T14:** the "Your story" add badge is drawn but decorative — tapping the tile opens your
story. Route the badge to the compose flow when it exists.

---

### Task 10: Notifications rebuilt on the repository (E8)

**Description:** Remove the duplicated read state, then make the screen genuinely useful: group by day,
filter by type, swipe to mark read, and a real empty state.

**Acceptance criteria:**
- [ ] **E22 closed:** the header no longer overflows at 360 or 390 logical pixels. Today it overflows by
      201px — the title and the "mark all read" button are a fixed `Row` with no flex and a long label.
      Make the title flexible and shorten or collapse the action into an icon button at phone width.
- [ ] Delete the `drainKnownOverflows(..., reason: 'E22 …')` suppressions in
      `test/widget/home_page_test.dart` once it is fixed.
- [ ] `NotificationTile` is stateless; read state comes from `NotificationRepository`.
- [ ] Tapping a notification marks it read and the change survives a tab switch and a restart.
- [ ] "Mark all read" updates every tile and persists.
- [ ] Notifications are grouped under Today / Yesterday / earlier-date headers.
- [ ] Filter chips (All / Likes / Comments / Follows) narrow the list.
- [ ] An unread count badge shows on the navigation destination.
- [ ] Zero notifications shows an empty state.

**Verification:**
- [ ] `flutter test` — widget tests for tap-to-read, mark-all-read, and filtering.
- [ ] Manual: mark one read, switch tabs, come back, restart.

**Dependencies:** T6

**Files likely touched:**
- `lib/pages/notifications_page.dart`
- `lib/widgets/notification_tile.dart`
- `lib/pages/home_page.dart` (badge)
- `test/widget/notifications_page_test.dart` (new)

**Estimated scope:** M (4 files)

---

### Task 11: Profile rebuilt on slivers (E9, E10, E11, E19)

**Description:** The profile has the worst layout bug in the app — a hardcoded grid height computed from
a width its parent has already reduced — plus a `firstWhere` that can throw during construction.
Rebuild it as a `NestedScrollView` with a collapsing `SliverAppBar` banner and a pinned `TabBar`, so the
grid sizes itself. Wire Follow to the repository and give the settings and overflow buttons real
destinations.

**Acceptance criteria:**
- [ ] The posts grid no longer computes its own height; it lays out correctly at 375px, 800px, and
      1440px with no overflow stripes.
- [ ] A user with no story does not crash the page (E10 closed).
- [ ] A user with no posts sees an empty state in the tab.
- [ ] The banner collapses into a compact app bar on scroll, with the username in the collapsed title.
- [ ] Follow reflects and updates `SocialRepository`, and the follower count moves with it.
- [ ] Settings opens the settings page (T17); overflow opens a real menu; both have tooltips.
- [ ] Banner, avatar, and grid images use the cached image widget with error states.

**Verification:**
- [ ] `flutter test` — widget tests: a story-less user renders without throwing; a post-less user shows
      the empty state; follow toggles the button label.
- [ ] Manual: scroll the profile at all three widths in both themes.

**Dependencies:** T6, T7b

**Files likely touched:**
- `lib/pages/profile_page.dart`
- `lib/widgets/user_posts_tab_view.dart`
- `test/widget/profile_page_test.dart` (new)

**Estimated scope:** M (3 files)

---

### Checkpoint C — after T11

- [ ] Every screen has a loading, empty, and error state
- [ ] The feed builds lazily
- [ ] The profile grid is correct at all three widths
- [ ] Widget tests cover feed, comments, notifications, and profile
- [ ] **Human review before proceeding**

---

## Phase 4 — Real-world features

> Ordered by value per unit of effort. Any suffix of this phase can be dropped without breaking what
> came before.

### Task 12: Saved posts collection

**Description:** The save button currently increments a counter and nothing else. Give it a destination:
a Saved page listing everything the user has bookmarked, reachable from the profile and from settings.

**Acceptance criteria:**
- [ ] A Saved page lists saved posts newest-first and survives a restart.
- [ ] Unsaving from the Saved page removes the item with an undo snackbar.
- [ ] An empty state explains how to save a post.
- [ ] Entry points exist on the profile and in settings.

**Verification:**
- [ ] `flutter test` — save two posts, open the page, assert both appear; unsave one, assert it goes.
- [ ] Manual: save, restart, confirm the list is intact.

**Dependencies:** T6, T7b

**Files likely touched:**
- `lib/pages/saved_posts_page.dart` (new)
- `lib/pages/profile_page.dart`
- `test/widget/saved_posts_page_test.dart` (new)

**Estimated scope:** S (3 files)

---

### Task 13: Search and explore

**Description:** There is no way to find anything. Add a search screen over users (username, full name)
and posts (caption, location), with debounced input, recent searches persisted, and an explore grid of
posts as the empty state.

**Acceptance criteria:**
- [ ] Search returns matching users and posts under separate result sections.
- [ ] Input is debounced (roughly 300ms); typing quickly does not re-filter on every keystroke.
- [ ] Recent searches persist and are individually clearable.
- [ ] With no query, an explore grid of posts is shown.
- [ ] Tapping a result opens the profile or the post.
- [ ] Search is reachable from a navigation destination.

**Verification:**
- [ ] `flutter test` — unit tests over the filter function (case-insensitive, partial match, no match);
      a widget test asserting debounce behaviour with a pumped timer.
- [ ] Manual: search for a known username and a known city.

**Dependencies:** T6, T7b

**Files likely touched:**
- `lib/pages/search_page.dart` (new)
- `lib/repositories/search_repository.dart` (new)
- `lib/pages/home_page.dart` (destination)
- `test/unit/search_repository_test.dart`, `test/widget/search_page_test.dart` (new)

**Estimated scope:** M (5 files)

---

### Task 14: Create a post

**Description:** A social app that cannot post is a mockup. Add a compose flow: pick an image from the
gallery or camera (or paste an image URL on web), write a caption, optionally tag a location, preview,
and publish. The post persists locally and appears at the top of the feed and on the profile.

**Acceptance criteria:**
- [ ] Compose is reachable from a prominent action (a FAB on mobile, a rail action on desktop).
- [ ] Image source: gallery and camera on mobile; gallery or an image URL on web, with the camera hidden
      behind `kIsWeb`.
- [ ] Publish is disabled until an image is chosen; the caption is optional.
- [ ] The new post appears immediately at the top of the feed and in the profile grid, and survives a
      restart.
- [ ] The user can delete their own post, with a confirmation dialog.
- [ ] Cancelling with unsaved content prompts before discarding.

**Verification:**
- [ ] `flutter test` — widget tests for the disabled-publish rule and for the discard confirmation.
- [ ] Manual: publish on web with a URL and on Android with a gallery image; restart and confirm both.

**Dependencies:** T6, T7a

**Files likely touched:**
- `lib/pages/create_post_page.dart` (new)
- `lib/repositories/post_repository.dart` (new or extended)
- `lib/pages/feed_page.dart`, `lib/pages/home_page.dart`
- `test/widget/create_post_page_test.dart` (new)

**Estimated scope:** M (5 files)

---

### Task 15: Offline resilience (E11)

**Description:** Make the app degrade gracefully without a network: cached images everywhere, a
connectivity banner, and a feed that serves what it has instead of showing broken frames.

**Acceptance criteria:**
- [ ] Every remote image in the app goes through the cached image widget — no bare `Image.network`
      remains in `lib/`.
- [ ] Going offline shows a dismissible banner; coming back online hides it and refreshes.
- [ ] With the network disabled and a warm cache, the feed still renders images.
- [ ] Failed images show the error widget rather than a blank box or a red screen.

**Verification:**
- [ ] `grep -rn "Image.network" lib/` returns nothing.
- [ ] Manual: load the feed, disable the network in DevTools, reload, confirm cached images and banner.

**Dependencies:** T7b, T9, T11

**Files likely touched:**
- `lib/widgets/common/app_network_image.dart`
- `lib/widgets/common/connectivity_banner.dart` (new)
- `lib/app.dart`
- Any remaining widget still calling `Image.network`

**Estimated scope:** M (4–5 files)

---

### Task 16: Localization, English and Indonesian (E13)

**Description:** The app currently mixes Indonesian and English in the same screen. Set up
`flutter_localizations` with ARB files, extract every user-facing string, and add a language switch that
persists — defaulting to the device locale.

**Acceptance criteria:**
- [ ] `l10n/app_en.arb` and `l10n/app_id.arb` hold every user-facing string; none remain hardcoded
      in `lib/` (verified by grep for quoted UI text in widget files).
- [ ] The app defaults to the device locale and falls back to English.
- [ ] A language switch in settings changes the language immediately and persists.
- [ ] Dates and relative timestamps localize through `intl`.
- [ ] Plurals (`1 comment` / `5 comments`) use ARB plural syntax, not string concatenation.

**Verification:**
- [ ] `flutter test` — a widget test pumps the app under `Locale('id')` and asserts an Indonesian string
      renders.
- [ ] Manual: switch languages and walk every screen looking for untranslated text.

**Dependencies:** T10 (notification strings), T8 (comment strings)

**Files likely touched:**
- `l10n/app_en.arb`, `l10n/app_id.arb`, `l10n.yaml` (new)
- `pubspec.yaml`, `lib/app.dart`
- Every page and widget with a user-facing string

**Estimated scope:** L (many files, but each change is mechanical) — split per screen if it drags

---

### Task 17: Settings page (E19)

**Description:** The settings button on the profile does nothing. Give it a real page: theme mode,
language, a link to saved posts, clear image cache, and an about section.

**Acceptance criteria:**
- [ ] Theme mode (System / Light / Dark) applies immediately and persists.
- [ ] Language selection applies immediately and persists.
- [ ] "Clear image cache" empties the cached-image store and reports how much was freed.
- [ ] An about section shows the app version read from the package info, not a hardcoded string.
- [ ] The page is reachable from the profile settings button, which now carries a tooltip.

**Verification:**
- [ ] `flutter test` — widget test: changing the theme option updates the controller.
- [ ] Manual: change each setting, restart, confirm all held.

**Dependencies:** T3, T16

**Files likely touched:**
- `lib/pages/settings_page.dart` (new)
- `lib/pages/profile_page.dart`
- `test/widget/settings_page_test.dart` (new)

**Estimated scope:** S (3 files)

---

### Task 18: Routing and deep links with `go_router`

**Description:** Navigation is imperative `Navigator.push` calls, so the app has no URLs on web and the
browser back button does not behave. Move to `go_router` with a shell route for the bottom navigation
and path-based deep links, plus the GitHub Pages fallback that makes them work in production.

**Acceptance criteria:**
- [ ] Routes exist for `/`, `/search`, `/notifications`, `/profile/:userId`, `/post/:postId`,
      `/story/:userId`, `/saved`, `/settings`, and `/create`.
- [ ] The bottom navigation and rail are a `StatefulShellRoute`, so tab state survives navigation.
- [ ] On web, the URL updates as the user navigates and the browser back button works.
- [ ] Loading `/profile/<id>` directly in a fresh tab renders that profile.
- [ ] An unknown route shows a designed 404 page, not a grey error screen.
- [ ] `web/404.html` redirects deep links into the app so GitHub Pages serves them.

**Verification:**
- [ ] `flutter test` — router tests asserting each path resolves to the expected page and an unknown
      path resolves to the 404 page.
- [ ] Manual: build, serve, open a deep link in a fresh tab, then use back and forward.

**Dependencies:** T11, T12, T13, T17

**Files likely touched:**
- `lib/router/app_router.dart` (new)
- `lib/app.dart`, `lib/pages/home_page.dart`
- Every `context.push(...)` call site
- `web/404.html` (new)
- `test/unit/app_router_test.dart` (new)

**Estimated scope:** L (6+ files) — split into "router skeleton" and "migrate call sites" if it drags

---

### Checkpoint D — after T18

- [ ] Saved, search, and create all work and survive a restart
- [ ] The app is usable offline
- [ ] Language switch flips every string
- [ ] Deep links load directly and back and forward work
- [ ] **Human review before proceeding**

---

## Phase 5 — Polish

### Task 19: Accessibility and responsive pass (E19)

**Description:** Sweep the whole app for the accessibility gaps left behind: unlabelled icon buttons,
tap targets under 48dp, missing semantics on the story avatars, text that breaks at large scale factors,
and the desktop layout, which currently just adds side padding rather than using the space.

**Acceptance criteria:**
- [ ] Every `IconButton` has a tooltip or a `Semantics` label.
- [ ] Every interactive target is at least 48x48 logical pixels.
- [ ] The app is usable at `textScaleFactor` 2.0 with no overflow on any screen.
- [ ] Story avatars announce the owner and whether the story is unseen.
- [ ] The desktop layout uses a max-width content column plus a secondary pane (suggested users, trends)
      instead of `ResponsivePadding`'s `width/6` guesswork.
- [ ] Keyboard navigation reaches every interactive element on web, with a visible focus indicator.

**Verification:**
- [ ] `flutter test` — a semantics test over the feed asserting labelled actions.
- [ ] Manual: walk the app with a screen reader; set text scale to 2.0; tab through on web.

**Dependencies:** T18

**Files likely touched:**
- `lib/widgets/layout/responsive_padding.dart` (likely replaced by a content-width layout)
- `lib/pages/home_page.dart`, `feed_page.dart`, `profile_page.dart`
- Most widget files (label additions)

**Estimated scope:** M–L — split by screen if it exceeds five files

---

### Task 20: Motion and micro-interactions

**Description:** Add the motion that makes a modern app feel responsive: hero transitions from the feed
image to the post detail, `AnimatedSwitcher` on changing counts, a staggered entry for list items on
first load, and consistent page transitions.

**Acceptance criteria:**
- [ ] Tapping a post image transitions it into the detail view with a hero animation.
- [ ] Like, save, and comment counts animate on change rather than snapping.
- [ ] All durations and curves come from the tokens file, not from literals.
- [ ] All animation respects `MediaQuery.disableAnimations` for reduced-motion users.

**Verification:**
- [ ] `flutter test` — a widget test pumping through the transition asserting no exception mid-flight.
- [ ] Manual: watch each interaction at normal speed and with animations slowed in DevTools.

**Dependencies:** T19

**Files likely touched:**
- `lib/theme/app_tokens.dart`
- `lib/widgets/post_card.dart`
- `lib/router/app_router.dart` (transitions)

**Estimated scope:** S–M (3–4 files)

---

### Task 21: Documentation and screenshots

**Description:** Bring the docs back in line with what the app now is: updated feature list, new
screenshots, the new dependency table, the corrected build command for Git Bash, and a short
architecture note so the next contributor knows where state lives.

**Acceptance criteria:**
- [ ] `README.md` feature list matches the shipped features.
- [ ] Screenshots in `.screenshots/` are regenerated, including a dark-mode shot.
- [ ] The dependency table lists the current dependencies and what each is for.
- [ ] The build section documents the `MSYS_NO_PATHCONV=1` caveat on Git Bash.
- [ ] A short "Architecture" section explains the data source, repositories, and providers.
- [ ] `AGENTS.md` notes the test and analyze commands.

**Verification:**
- [ ] Follow the README from a clean clone and confirm every command works as written.

**Dependencies:** T20

**Files likely touched:**
- `README.md`, `AGENTS.md`, `.screenshots/*`

**Estimated scope:** S (2 files plus assets)

---

### Checkpoint E — Complete

- [ ] Every acceptance criterion above is checked
- [ ] `flutter analyze` clean, `flutter test` green, `flutter build web` succeeds
- [ ] Manual pass at mobile, tablet, and desktop widths in both themes
- [ ] Screenshots and README updated
- [ ] **Ready for the human to commit and push**
