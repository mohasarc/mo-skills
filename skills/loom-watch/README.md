# loom-watch

Agent skill for turning a Loom video into something the agent can read: a
timestamped transcript plus screen frames aligned to what was said.

## Setup

None. The skill uses Loom's public transcript and video endpoints — no API key,
no account. It needs `ffmpeg` and `python3` on `PATH` (both standard on dev
machines; `brew install ffmpeg` if missing).

## What it does

Given a public Loom share URL, `scripts/loom-watch`:

1. Pulls Loom's own transcript (timestamped `.vtt`).
2. Downloads the video, extracts one frame per caption cue at its start
   timestamp.
3. Runs scene detection over the whole video and takes a frame at every change,
   so mid-sentence screen changes are captured too.
4. Drops near-duplicate frames.
5. Writes a `manifest.md` linking every cue and scene change to its frame.

Output lands in `tmp/<video-id>/`, cached so re-runs are instant.

## Limitation

Public / unlisted links only. Private videos behind workspace SSO or a password
need auth this skill does not perform — set the video to "anyone with the link".
