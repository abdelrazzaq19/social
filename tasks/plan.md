# Implementation Plan: Quick Social — UI/UX Modernization, Bug Fixes, and Real-World Features

_Status: awaiting human review. Written 2026-09-07 against `main` (clean tree, Flutter 3.47.2 / Dart 3.13.2)._

## Overview

`quick_social` is a Flutter UI prototype: a feed, Instagram-style stories, notifications, and a profile,
all backed by `faker`-generated dummy data held in `static` fields on the model classes. There is no state
management, no persistence, no routing layer, no localization, and no tests. `flutter analyze` is clean and
`flutter build web` succeeds, so the defects are runtime and logic defects rather than compile errors.

This plan does three things, in dependency order:

1. **Fix the defects** — 20 concrete issues catalogued below, from a leaked `PageController` to an
   off-by-one RNG that makes one of the five seeded users invisible.
2. **Modernize the UI/UX** — a real Material 3 theme with dark mode, sliver-based scrolling, skeleton and
   error states, motion, and an accessibility pass.
3. **Add features that matter in real use** — persistence, saved posts, search, post creation, offline
   image caching, settings, localization, and deep-linkable web URLs.

### Working agreement

- **The human handles all `git commit` and `git push`.** No task in this plan commits, tags, or pushes.
  Each task ends with a working tree the human can review and commit themselves.
- Every task leaves the app buildable and runnable. No task may land a red `flutter analyze`.

## Baseline (verified, not assumed)

| Check | Command | Result |
| --- | --- | --- |
| Static analysis | `flutter analyze` | `No issues found!` |
| Web build | `flutter build web --base-href /quick_social/` | Succeeds, 2 deprecation warnings |
| Runtime | served `build/web`, loaded in a browser | Boots; splash then feed renders at mobile and desktop widths |
| Tests | — | **No `test/` directory exists** |
| Dependencies | `flutter pub outdated` | `google_fonts` 8.2.0 → 8.2.1 |

> On Git Bash, `--base-href /quick_social/` is rewritten into a Windows path and the build aborts. Use
> `MSYS_NO_PATHCONV=1 flutter build web --base-href /quick_social/`, or run the build from PowerShell.

## Defect catalogue

These are the errors the work needs to fix. Each is mapped to the task that closes it.

### Crashes, leaks, and lifecycle

| ID | Defect | Location | Task |
| --- | --- | --- | --- |
| E1 | `web/index.html` still uses the deprecated `FlutterLoader.loadEntrypoint` bootstrap and the deprecated service-worker hook. It warns today; a future Flutter release removes it. | `web/index.html:37,46` | T2 |
| E2 | `SplashPage.build()` calls `splashing(context)`, so every rebuild schedules another delayed navigation, and it uses `push` instead of `pushReplacement` (back returns to the splash screen). | `lib/pages/splash_page.dart:19` | T4 |
| E3 | `HomePage._buildPageView()` allocates a **new** `PageController` on every build. Old controllers are never disposed, and `_pageChanged` can call `jumpToPage` on a controller that is no longer attached. | `lib/pages/home_page.dart:52` | T4 |
| E4 | `CommentsBottomSheet._commentTextField()` creates a `TextEditingController` inside `build()` — never disposed, and the field only appears to clear because the controller is thrown away. | `lib/widgets/comments_bottom_sheet.dart:110` | T8 |
| E10 | `ProfilePage`'s initializer uses `firstWhere` with no `orElse`; the moment a user has no story it throws `StateError` during construction. | `lib/pages/profile_page.dart:9` | T11 |

### Data and logic

| ID | Defect | Location | Task |
| --- | --- | --- | --- |
| E5 | `Comment.generateDummyComments()` uses `Random().nextInt(10)`, which returns 0 about 10% of the time — the comment sheet then opens completely blank with no empty state. | `lib/models/comment.dart:20` | T5, T8 |
| E6 | `NotificationType.values[Random().nextInt(2)]` can never produce `follow`. The `follow` icon and message branch are dead code. | `lib/models/user_notification.dart:26` | T5 |
| E7 | `Random().nextInt(User.dummyUsers.length - 1)` in three places never selects the last user, so `dummyUsers[4]` owns no posts, appears in no comment, and triggers no notification. | `post.dart:34`, `comment.dart:24`, `user_notification.dart:28` | T5 |
| E8 | Notification read state is duplicated: `NotificationTile` keeps its own copy while the page holds the list, and both read from the mutable global `UserNotification.dummyNotifications`. Tapping a tile is silently lost. | `notifications_page.dart:20`, `notification_tile.dart:18` | T6, T10 |
| E16 | Like and save state lives in `_ToggleButtonState`, so it resets whenever the widget is disposed (tab switch, list recycling) and never reaches the `Post` model. `AutomaticKeepAliveClientMixin` is applied to the button rather than the list item, so it achieves nothing. | `lib/widgets/post_card.dart:214` | T6, T7b |

### Layout, performance, and presentation

| ID | Defect | Location | Task |
| --- | --- | --- | --- |
| E9 | `UserPostsTabView` computes a fixed grid height from `context.width`, but its ancestor `ResponsivePadding` removes `width/6` (desktop) or `width/8` (tablet). The height is therefore wrong at every breakpoint above mobile. Zero posts yields a 16px stub with no empty state. | `lib/widgets/user_posts_tab_view.dart:28` | T11 |
| E11 | `Image.network` with no `errorBuilder` or `loadingBuilder` in the profile grid, the profile banner, and every `CircleAvatar`. Offline or on a 404 these render blank and throw exceptions into the console. | `user_posts_tab_view.dart:52`, `profile_page.dart:100`, `post_card.dart:35`, `comment_tile.dart:22`, `user_story_avatar.dart:31` | T7b, T9, T11, T15 |
| E12 | `FeedPage` nests a `shrinkWrap: true` `ListView.separated` inside a `ListView`, so all 30 posts and their network images are built eagerly on the first frame. | `lib/pages/feed_page.dart:35` | T7a |
| E21 | **Found by the T1 harness.** `PostButton`'s `Row` throws `RenderFlex overflowed`. Measured across a width sweep of `HomePage`: **overflows at 360 (by 4.3px), and at 768, 800, 834, 900, and 1024 (by 19px); fine at 390, 430, 600, 1200, and 1440.** So it hits small Android phones and the whole tablet-to-small-desktop band. Above the mobile breakpoint the cause is `_tabletCard` wrapping a `Row` of two `Expanded` children in `IntrinsicHeight` — under intrinsic sizing the action row gets a width unrelated to the space available. `PostButton` compounds it everywhere by giving its `Text` no flex. Invisible in release builds (no debug stripes), but the labels are genuinely clipped. | `lib/widgets/post_card.dart:75` (`IntrinsicHeight`), `lib/widgets/post_button.dart:24` | T7b |
| E22 | **Found by the T4 tests.** The notifications header is a `spaceBetween` `Row` holding a `headlineSmall` title and a `TextButton.icon` with a long label, neither flexible. At 390px it overflows by **201 pixels** — the "mark all read" action is largely off-screen on every phone. Went unnoticed because the T1 viewport helper silently rendered every test at 800x600 (see the T1 note in `todo.md`), and because the browser check never opened that tab. | `lib/pages/notifications_page.dart:43` | T10 |
| E14 | Only a light theme is defined. No `darkTheme`, no `themeMode`, so the app ignores the OS dark-mode setting entirely. | `lib/app.dart:14` | T3 |
| E15 | `google_fonts` downloads DM Sans over the network on first launch — a flash of fallback text, and no custom font at all offline. | `lib/app.dart:16` | T3 |

### Content, accessibility, and project hygiene

| ID | Defect | Location | Task |
| --- | --- | --- | --- |
| E13 | UI strings mix Indonesian and English: `'Notifikasi'`, `'Tandai telah dibaca'`, `'Tulis sesuatu'`, and `'... menyukai postingan anda'` sit alongside `Home`, `Followers`, and `Comments`. | `notifications_page.dart`, `comments_bottom_sheet.dart`, `user_notification.dart` | T16 |
| E17 | No tests exist, and CI (`.github/workflows/deploy.yml`) runs neither `flutter analyze` nor `flutter test` before deploying to GitHub Pages. | `.github/workflows/deploy.yml` | T1 |
| E18 | Web metadata is still the Flutter template: title `quick_social`, description "A new Flutter project.", theme colour `#0175C2`, and `orientation: portrait-primary` — which contradicts the app's own responsive desktop layout. | `web/index.html`, `web/manifest.json` | T2 |
| E19 | Dead and unlabelled controls: the send icon, `more_vert`, the settings button, Follow, and Message all have empty `onPressed`. No tooltips, and no `Semantics` labels on story avatars. | `feed_page.dart:64`, `post_card.dart:44`, `profile_page.dart:71`, `profile_page.dart:191` | T11, T17, T19 |
| E20 | `pubspec.yaml` description is still "A new Flutter project."; `google_fonts` is one patch release behind. | `pubspec.yaml:2` | T1 |

## Architecture decisions

1. **State management: `provider` with `ChangeNotifier` repositories.**
   The app currently has none, and every interactive control keeps private `setState` state that cannot
   survive a rebuild. `provider` is the smallest step that fixes this whole class of bug; it matches the
   codebase's plain-Flutter idiom and needs no code generation. It is already resolved transitively, so
   this is a near-free addition. Riverpod is defensible but imposes a larger refactor and a new mental
   model on a 1,900-line codebase.

2. **Persistence: `shared_preferences`, behind a repository interface.**
   Likes, saves, follows, read notifications, theme mode, language, and user-created posts all persist
   locally. Widgets never touch `SharedPreferences` directly — they talk to a repository, so a real
   backend can be swapped in later without touching the UI.

3. **Keep `faker` as the seed source, but generate once, deterministically.**
   Replace ad-hoc `Random()` calls with a single seeded `Random`, and move generation into a
   `DummyDataSource`. The same data then appears on every run, which is what makes widget tests possible,
   and the off-by-one selection bugs get fixed in one place instead of three.

4. **Images: `cached_network_image`.**
   Caching, placeholder, and error widgets in one dependency; closes E11 and the offline gap directly.
   The existing `LoadingImageWidget` and `ErrorImageWidget` become its placeholder and error builders
   rather than being deleted.

5. **Bundle DM Sans as an asset instead of fetching it.**
   Removes the network dependency in `app.dart`, kills the flash of fallback text, and makes the app
   render correctly offline. `google_fonts` is dropped once the font is bundled.

6. **Routing: `go_router` with deep-linkable paths.**
   The app deploys to GitHub Pages; a working browser back button and shareable URLs for a profile or a
   post are user-facing value, not architecture for its own sake. GitHub Pages needs a `404.html`
   fallback for path-based URLs — covered in T18.

7. **Localization: `flutter_localizations` and ARB files, `en` and `id`.**
   The mixed-language strings are not cosmetic; they are a half-finished localization. Doing it properly
   settles E13 and adds a language switch.

8. **Isolate the `story` package behind our own widget.**
   `story: ^1.1.0` is a small, infrequently updated dependency sitting on the critical path of a whole
   feature. Wrapping it in `lib/widgets/story/story_viewer.dart` makes a future breakage a one-file fix.

## Dependency graph

```
T1 test harness + CI gate ─┐
                           │
T2 web bootstrap/metadata ─┤
                           │
T3 design tokens + M3 light/dark + bundled font + PrefsService
   │
   ├── T4 app shell fixes (splash, PageController, navigation)
   │
   └── T5 data source: seeded, deterministic, bug-free
          │
          └── T6 repositories + provider + persistence
                 │
     ┌───────────┼────────────┬──────────────┬──────────────┐
     │           │            │              │              │
 T7a/T7b feed  T8 comments  T9 stories  T10 notifications  T11 profile
     │           │            │              │              │
     └───────────┴─────┬──────┴──────────────┴──────────────┘
                       │
     ┌──────┬──────────┼──────────┬─────────┬─────────┐
  T12 saved T13 search T14 create T15 offline T16 i18n T17 settings
                       │
                  T18 go_router / deep links
                       │
             T19 a11y ─ T20 motion ─ T21 docs
```

Foundations first (T1–T6), then one complete vertical path per task (T7–T11), then features (T12–T18),
then polish (T19–T21).

## Phases and checkpoints

Full task detail — acceptance criteria, verification, files touched, size — lives in `tasks/todo.md`.
This section is the shape of the work.

### Phase 0 — Guardrails (T1–T2)

Nothing else is safe to change until a regression is detectable. Add the test harness and make CI run
`flutter analyze` and `flutter test` before it deploys. Fix the web bootstrap and metadata while the code
is still untouched, so any later runtime problem is unambiguously ours.

### Phase 1 — Foundation (T3–T4)

The theme and the app shell: design tokens, Material 3 light **and** dark schemes, a bundled font, a
persisted theme mode, and the three lifecycle bugs in the splash screen and `HomePage`. After this the
app looks modern in both themes and stops leaking controllers.

### Checkpoint A — after T4

- [ ] `flutter analyze` clean, `flutter test` green
- [ ] The app launches to the feed exactly once; back from the feed exits rather than returning to the splash
- [ ] Toggling OS dark mode changes the app theme, and an explicit choice survives a restart
- [ ] No `PageController` assertions in the debug console after switching tabs 20 times
- [ ] **Human review before proceeding**

### Phase 2 — Data and state (T5–T6)

The seeded data source (fixing E5, E6, E7) and the repository and provider layer with persistence. This
is the highest-risk pair — it touches every model and every interactive widget — so it goes early, before
the UI work builds on the old shapes.

### Checkpoint B — after T6

- [ ] All five seeded users own posts and appear in comments and notifications
- [ ] `follow` notifications appear in the list
- [ ] Like a post, kill the app, reopen: the like is still there
- [ ] Repository unit tests cover like, save, follow, and read toggling plus persistence round-trips
- [ ] **Human review before proceeding**

### Phase 3 — Vertical UI slices (T7–T11)

One screen at a time, each a complete path from repository to pixels: feed, comments, stories,
notifications, profile. Each slice ships its own loading, empty, and error states.

### Checkpoint C — after T11

- [ ] Every screen has a designed loading, empty, and error state
- [ ] The feed builds lazily — verified with a build-count probe or the DevTools timeline
- [ ] The profile grid lays out correctly at 375px, 800px, and 1440px with no overflow stripes
- [ ] Widget tests cover the feed, the comment sheet, notifications, and the profile
- [ ] **Human review before proceeding**

### Phase 4 — Real-world features (T12–T18)

Ordered by value per unit of effort. T12–T14 are the ones a real user would notice missing; T15–T18 are
the ones that make it feel like a shipped app rather than a demo.

### Checkpoint D — after T18

- [ ] Saved posts, search, and post creation all work and survive a restart
- [ ] The app is usable with the network disabled: cached images, and a clear offline banner
- [ ] The language switch flips every string; no hardcoded UI text remains
- [ ] `/profile/<id>` and `/post/<id>` load directly in the browser and the back button works
- [ ] **Human review before proceeding**

### Phase 5 — Polish (T19–T21)

Accessibility, motion, and documentation. Deliberately last: polishing a surface that is still changing
is wasted work.

### Checkpoint E — Complete

- [ ] Every acceptance criterion in `tasks/todo.md` is checked
- [ ] `flutter analyze` clean, `flutter test` green, `flutter build web` succeeds
- [ ] Manual pass at mobile, tablet, and desktop widths in both themes
- [ ] Screenshots and README updated
- [ ] Ready for the human to commit and push

## Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| The state-layer refactor (T6) touches nearly every widget and could regress working UI | High | Land it before the UI slices, not after; T1's widget tests are the safety net; keep the repository API tiny (toggle plus read) |
| `story: ^1.1.0` is a small third-party package that may break on a future Flutter release | Medium | T9 wraps it in our own `StoryViewer`, so a breakage becomes a one-file change or a swap for a hand-rolled viewer |
| `image_picker` behaves differently on web (no camera, blob URLs) than on mobile | Medium | T14 gates the camera source behind `kIsWeb` and falls back to gallery or file input; accept an image URL as a third path |
| GitHub Pages returns 404 for deep-linked paths under `go_router` | Medium | T18 adds a `404.html` that redirects into the app, and falls back to the hash URL strategy if that proves fragile |
| Bundling DM Sans increases the web payload | Low | Ship only the weights actually used (400/500/700), subset to Latin, and measure before and after |
| Persisted data shape changes between tasks and stale preferences break the app | Low | Version the preferences key namespace (`qs.v1.*`) and discard unknown versions on read |
| 21 tasks is a lot for one pass | Medium | Phases 0–3 are the committed core; the Phase 4 features are individually optional and ordered so that any suffix can be dropped |

## Decisions taken (2026-09-07)

1. **State management: `provider`.** Confirmed. `ChangeNotifier` repositories, no code generation.
2. **Feature scope: all of Phase 4 (T12–T18).** Saved posts, search, create post, offline resilience,
   localization, settings, and `go_router` deep links are all in scope. The full 21-task plan stands.
3. **New dependencies approved by implication:** `provider`, `shared_preferences`,
   `cached_network_image`, `go_router`, `share_plus`, `image_picker`, `intl`, `connectivity_plus`.
   `google_fonts` is removed in T3 when DM Sans is bundled.

## Open questions for the human

1. **Brand** — keep `Colors.tealAccent` as the Material 3 seed, or pick a different brand colour for the
   modernized look? _Assumption if unanswered: keep tealAccent, but tune it to a deeper teal so the
   light-theme contrast passes AA (the current accent is very pale against white)._
2. **Platforms** — `android/`, `ios/`, `linux/`, `macos/`, `windows/`, and `web/` all exist. Are web and
   Android the real targets, or should desktop be verified too? This changes how much T19 has to cover.
   _Assumption if unanswered: web and Android are verified; desktop is built but not manually tested._
