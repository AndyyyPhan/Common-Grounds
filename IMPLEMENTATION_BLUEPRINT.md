# Common — Implementation Blueprint

## Scope

Build the approved Common experience in Flutter without changing the product’s safety rules or visual system during implementation.

## Existing foundations to reuse

- Flutter app shell and four-tab navigation
- Firebase Auth, Firestore, Cloud Functions, and Cloud Messaging
- User profiles, interest lists, waves, mutual matches, conversations, and messages
- Proximity matching and user-selected search radius

## Navigation migration

| Current | Approved |
| --- | --- |
| Home | Discover |
| Waves | Activity |
| Messages | Inbox |
| Profile | Profile |

Activity replaces the separate received/sent/matched tab structure with one intentional timeline. Inbox remains mutual conversations only.

## UI implementation order

1. Theme tokens and reusable components: warm surfaces, typography, chips, compact pills, avatars, rows, empty states, and bottom navigation.
2. Discover screen and public profile.
3. Wave sheet and sent state.
4. Activity timeline.
5. Inbox and conversation styling.
6. Personal Profile, Interest selector, and location onboarding.

## Locked design decisions

- The approved visual baseline is the warm, editorial **dark** Discover experience using Eren as the fictional profile. Light mode will be designed as a true counterpart later, not as a substitute for the dark direction.
- Use restrained terracotta only for high-intent actions and status. The app must never return to the former blaring green treatment.
- Keep actions compact and proportional. Do not use oversized or full-width action boxes for Wave, Not now, Add a note, or the first-message prompt unless a full-width action is necessary for a focused onboarding or safety decision.
- Discover is photo-led and calm: one strong person card, coarse distance, a common-ground explanation, interest chips, a compact Wave hello pill, and a text-level Profile action.
- The fictional reference person is named **Eren**. Use that name in design previews and demo states.
- Interest selection must offer a broad, structured taxonomy comparable in breadth to modern social apps. It should be category-led, searchable, multi-select, and autosave; do not put a bottom “Save interests” button on the selection screen.
- Place Blocked people inside **Privacy & Safety**, not as a top-level Profile setting.
- Preserve the user’s current behavioral model while restyling. Do not introduce swiping, public locations, intent labels, or broader discovery eligibility without an explicit product decision.

## Current implementation status

Phase 1 is complete in the Flutter app:

- `mobile/lib/core/theme/app_colors.dart` now defines Common’s terracotta and warm-neutral light/dark palette.
- `mobile/lib/core/theme/app_theme.dart` reduces generic elevation and allows compact buttons rather than forcing full-width controls.
- `mobile/lib/core/widgets/app_card.dart` provides correctly clipped card touch feedback.
- `mobile/lib/app_shell.dart` now uses the approved Discover, Activity, Inbox, and Profile tab language, with brand-colored unread badges.

The next implementation task is to redesign the actual Flutter Discover screen and its public profile entry point around the approved Eren reference. Do not change matching, location, wave, or messaging behavior during that screen pass.

## Data and safety work

- Add an explicit discoverable/presence state and a short expiry timestamp.
- A profile is matchable only when presence is active and fresh.
- Keep exact coordinates server-side or otherwise inaccessible to other users; expose only derived distance bands.
- Replace flat distance ranking with the approved distance-aware compatibility threshold.
- Enforce daily wave limits server-side.
- Add block, hide, report, and unmatch data models and apply blocks to discovery, Activity, and messaging.
- Route notification taps to the relevant Activity or Inbox destination.

## Known current gaps

- Discover contains placeholder nearby/active counts.
- Location latitude and longitude are stored in the profile data path and need stricter access boundaries.
- Notification navigation currently logs rather than changing tabs.
- The current Waves page uses separate received, sent, and matched tabs instead of the approved timeline.

## Verification

Test on iPhone at every milestone: onboarding, denied location, presence off, no matches, nearby match, sent wave, mutual wave, unread chat, report/block, and light/dark themes.
