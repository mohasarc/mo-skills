---
name: loom-watch
description: Watch a Loom video — pull its transcript and screen frames so the agent can understand what was said and shown. Use whenever the user shares a Loom URL (`loom.com/share/...` or `loom.com/embed/...`) or asks you to watch, review, or extract info from a Loom recording.
---

# loom-watch

The agent cannot watch video or hear audio. This skill converts a Loom recording
into things it *can* read: a timestamped transcript and screen frames aligned to
what was being said at each moment.

## Invoke

```
scripts/loom-watch <loom-url> [--fresh]
```

Output lands in `tmp/<video-id>/`, cached by video ID. A second run on the same
URL reuses the cache; `--fresh` forces re-extraction (use it only if the video
was re-recorded under the same ID).

Produces:
- `transcript.vtt` — Loom's own caption track, with timestamps
- `frames/` — PNG screen frames
- `manifest.md` — the index: every caption cue and scene change linked to its
  frame, ordered by time

## Consumption protocol

This matters — follow it, do not improvise.

1. Run the script.
2. Read `manifest.md` and `transcript.vtt` first. These are plain text, cheap,
   and scale to any video length. They give you the full narration and the
   structure.
3. Then read frames **selectively**. The manifest deliberately lists many frames
   — it errs toward granularity. You decide which ones you actually need to
   *see* (a frame showing code, an error, a specific UI state, a
   `_(visual change, no narration)_` row near a deictic "like this" / "like
   that"). On a short video you might read most; on a long one, a handful.
4. Never blanket-read every frame into context. The manifest is the product;
   the frames are a resource you draw from.

## Reading frames closely

Frames are saved at full video resolution (often ~1600px+ wide). When you `Read`
a frame it gets downscaled for display, so small text — DevTools panels, code,
terminal output — is unreadable at first glance. **Do not guess from the
transcript when a frame holds the answer.** Crop the region you care about and
upscale it first:

```
ffmpeg -i frames/fNNN.png -vf "crop=W:H:X:Y,scale=iw*2:ih*2" /tmp/crop.png
```

Then `Read` the crop. A blurry frame is a reason to zoom, not a reason to infer.

Cross-check every deictic transcript cue ("this height", "the content in here",
"that prop") against the frame: identify the *exact* element selected or edited
on screen. The narrator's "this" rarely means the file you already have open —
confirm which DOM node / file / line is actually in focus before acting on it.

## How extraction works

1. Transcript: GraphQL `FetchVideoTranscript` → a signed `.vtt` URL → fetched.
2. The video is downloaded and **one frame is extracted per caption cue**, at
   the cue's start timestamp. Cues are sub-sentence fragments, so this is a
   fine-grained spine — every spoken fragment has an aligned frame.
3. **Scene detection runs over the whole video** (not just silent gaps): the
   load-bearing changes ("watch, I do it like this") happen mid-narration, so a
   frame is taken at every scene change. A burst of changes within 1.5s (an
   animation) collapses to one frame.
4. Near-identical consecutive frames are dropped; a cue whose frame was dropped
   points at the previous kept frame, marked `_(dup)_`.
5. The MP4 is deleted after extraction — `transcript.vtt`, `frames/`, and
   `manifest.md` are kept.

## Gotchas

- **Public / unlisted links only.** Private videos behind workspace SSO or a
  password can't be reached. The script fails with a specific message; tell the
  user to set the video to "anyone with the link".
- **Dedup is a janitor, not a curator.** It only removes near-exact consecutive
  repeats. A global perceptual hash cannot distinguish a meaningful small change
  (a popup, a typed line) from no change — so the script does not try. Curating
  for "what matters" is your job, done by reading the manifest. Do not assume
  every frame on disk is visually distinct, and do not assume the script
  filtered out the unimportant ones.
- **Undocumented endpoints.** Loom's transcript (`FetchVideoTranscript`) and
  video (`transcoded-url`) endpoints are not public API. If the script fails at
  step `[1/6]` or `[2/6]` with a parse error, Loom likely changed the shape —
  the queries in `scripts/loom-watch` need updating.
- **Scene-frame timestamps** can repeat in the manifest (two changes within the
  same second); the frame files are still distinct.
- Exit codes: `2` usage/bad URL, `3` transcript endpoint, `4` VTT,
  `5` video URL, `6` ffmpeg or download.
