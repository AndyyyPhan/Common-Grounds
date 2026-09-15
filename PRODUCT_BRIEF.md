# Common — Product Brief

## Purpose

Common helps adults make genuine local friendships with people they might otherwise pass by every day. It is designed for people ages 18–35 who are building a life in a city or college community and want an easier, safer path to meeting like-minded people.

Common is friendship-first. A friendship may naturally become something else, but Common does not position, rank, or market people for dating or professional networking.

## Core promise

> People who could make your day better are nearby.

The product’s value comes from pairing meaningful common ground with real physical proximity. Neither condition alone is enough.

## Discovery rule

A person is eligible to appear in Discover only when all of the following are true:

1. They are actively discoverable in the app.
2. They fall within the viewer’s selected search radius.
3. They share enough meaningful interests with the viewer.
4. Their combined proximity and compatibility score meets the discovery threshold.

The system must not show people who share interests but are not nearby, or people who are nearby but have insufficient common ground.

## Distance-aware matching

Distance should increase the standard for compatibility. The exact values remain tunable, but the intended model is:

| Approximate distance | Compatibility requirement |
| --- | --- |
| Under 0.1 mi | Strong enough match; early target around 80% |
| 0.1–0.3 mi | Higher compatibility requirement |
| 0.3–0.5 mi | Very strong compatibility requirement |
| 0.5–1.0 mi, if enabled | Exceptional match only |

The initial preferred maximum radius is 0.5 miles. A 1-mile option remains open for later testing.

## Presence and location privacy

- A person is discoverable only while they are actively using Common.
- Discoverability expires shortly after the app is backgrounded or closed; stale location must not remain eligible for matching.
- A person can turn their discoverability off at any time.
- Precise coordinates and venue location are never visible to another user.
- Users see only a coarse proximity band, such as “under 0.3 mi,” “under 0.5 mi,” or “under 1 mi.”
- Any optional place context must be explicitly self-declared, never inferred from device location.
- An evening safety default should end presence automatically and require a deliberate re-enable. The final time, duration, and wording are open decisions.

## Public profile

Before a wave, a profile can show:

- First name
- Age
- Optional photo
- Short bio
- Interests
- Shared-interest and compatibility context
- Coarse proximity information

Do not show exact location, contact information, last-seen status, employer, school, shared-friend counts, verification details, or any private account data by default.

## Connection model

- People can send a limited number of waves per day; the current starting point is three.
- Messaging opens immediately after a mutual wave.
- An optional note or prompt may support the first conversation, but must remain low-pressure.
- Version one is one-to-one only.
- Day-one safety controls: block, report, hide, and unmatch.

## Trust and account access

- Development can support email/password for efficient testing.
- The expected production direction is phone-number verification.
- Optional identity, school, or workplace verification can be explored later as a private trust signal.
- Trust and moderation should protect all users without requiring gender disclosure or publicly revealing verification information.

## Navigation

1. **Discover** — nearby people with meaningful common ground
2. **Activity** — received waves, mutual connections, and intentionally relevant updates
3. **Inbox** — mutual conversations only
4. **Profile** — identity, interests, discoverability, radius, privacy, and safety settings

## Visual direction

- Editorial, warm, photo-forward, and calm
- White-first light mode with a matching dark mode
- Restrained terracotta accent with warm neutral surfaces
- Spacious hierarchy and compact, reversible actions
- No swiping, loud engagement mechanics, generic dashboard cards, or oversized action buttons
- The approved Discover mockup using Eren is the visual reference point

## Success criteria for version one

Primary metric: meaningful conversations started after a mutual wave.

Supporting metrics:

- Daily active users
- Mutual waves
- Safe account retention and low abuse/report rates

## Open decisions

- Exact maximum radius and distance/compatibility thresholds
- Whether to add an “intent” state in a later version
- Evening presence policy, timing, and notification behavior
- Final wave limit and any future paid-plan boundaries
- Verification requirements at production launch
- Group discovery beyond version one

## Current design sequence

1. Public discovery profile for Eren
2. Wave and wave-sent states
3. Activity
4. Inbox and conversation
5. Personal profile, discoverability, and safety controls
6. Onboarding and location permission flow
