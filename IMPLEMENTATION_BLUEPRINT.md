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
