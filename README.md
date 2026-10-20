# Portfolio

One file: `index.html`. Layout, both themes, the sky, the animations and the custom cursor
are all inside it. No framework, no build step, no `npm install`.

**The sky** is driven by one value — how far down the page you are.

- **Dark** = night. The moon walks the full lunar cycle: new → waxing crescent → first quarter
  → waxing gibbous → full, across an arc from the left horizon to the right. Five parallax
  star layers, four star colours, diffraction spikes on the brightest, drifting meteors.
- **Light** = day. The sun arcs the same path, sunrise → morning → midday → golden hour →
  evening, and the sky gradient warms with it. Daylight gets its own palette — slate and gold
  dust motes plus drifting clouds, because white stars are invisible on a pale sky.

A caption under the body names the current phase or time of day (wide screens only).
Moving the pointer leaves a trail of sparks — cool white at night, warm gold by day. The
cursor is a four-point sparkle, the same shape as the spikes on the brightest stars.

On screens under 780px the section links collapse into a menu button in the nav, so Projects
and Contact stay reachable on a phone.

Fonts: Parisienne (script — your name, the logo, section headings), Space Grotesk (card
titles), Inter (body), JetBrains Mono (labels). From Google Fonts with system fallbacks so
the page stays readable before they land.

The script is deliberately limited to display text. Calligraphy at 15px is hard to read, and
on a portfolio for technical roles that costs more than the style gains. If you want it
wider, `--script` is one variable — but read a paragraph of it on your phone first.

## Publishing

1. github.com/new → name it `KrIShnA-768.github.io` → Public → Create
2. "uploading an existing file" → drag everything from this folder → Commit
3. Settings → Pages → Deploy from a branch → `main` → `/ (root)` → Save
4. Two minutes later: **https://KrIShnA-768.github.io**

Full detail, custom domains and the AWS version later: `DEPLOY.md`.

## Things you might want to change

| What | Where in `index.html` |
|---|---|
| Your résumé | drop `resume.pdf` in this folder; the button detects it automatically |
| Script font | `--script` near the top of `<style>`; swap Parisienne in the Google Fonts link |
| Add your email | search `mailto` — there's a commented block explaining how |
| Project repo link | search `Once the repo is public` — uncomment and set the URL |
| Accent colour | `--accent`, once per theme, near the top of `<style>` |
| Cursor shape | `--cur` / `--cur-i` — inline SVG sparkles, one pair per theme |
| Default theme | `<html lang="en" data-theme="dark">` — change to `light` |
| Star count | `var total = Math.min(Math.round((W * H) / 2600), 900)` |
| Meteor frequency | `nextMeteor = ... rand(1.6, 4.5)` — seconds between meteors |
| Spark trail | `emitSpark()` and the `sinceSpark > 0.022` gate in `tick()` |
| Moon / sun path | `bodyPos()` — the arc; `bodyR` in `buildBody()` — the size |
| Phase names | `MOON_NAMES` and `DAY_NAMES` |
| Sky particle colours | `SKY_PAL.dark` / `SKY_PAL.light` — tints, weights, alpha |
| Cloud density | the `for (var c = 0; c < 5; c++)` loop in `build()` |
| Menu breakpoint | `@media (max-width: 780px)` and the matching check in the menu script |

### On the AI section

The Toolkit has an **AI-assisted workflow** group (Claude, Claude Code, IaC scaffolding, log
triage, runbook drafting), and the About section says you pair with Claude but still own and
review what ships.

That last clause is doing real work. Listing AI tools is normal now and reads as current
rather than as a shortcut — but only when it's clear you understand the output. Keep the
"I own and review everything that ships" wording, and be ready to explain any line of your
Terraform in an interview, because you will be asked.

### Honesty check

Both projects are badged **In progress** and **Planned**, because they are. Change the badges
when they're real — an interviewer who opens a repo you called finished and finds TODOs has
learned something you didn't mean to teach.

## What's in here

```
index.html      the site
404.html        not-found page
robots.txt      allows indexing
sitemap.xml     for search engines
DEPLOY.md       publishing, custom domain, and the AWS migration later
.github/        optional deploy workflow (not needed for the 4 steps above)
terraform/      S3 + CloudFront version, for week 10 of the roadmap
```

## Checked before shipping

- Moon phase measured against scroll position by counting lit pixels: 0% → 25% → 47% → 78%
  → 100%, with the phase names landing where they should (first quarter at half lit).
- Light mode cycles sunrise → morning → midday → golden hour → evening, sky colour tracking.
- 61fps on desktop with the pointer moving and sparks active; 61fps at 375px.
- No horizontal scroll at 375px; phase caption hidden below 1100px so it can't land on text.
- Custom cursor applies on body and interactive elements, and is handed back on touch devices.
- Menu opens, jumps to the right section (scroll 0 → 2330, heading clear of the nav) and closes
  itself; panel is fully opaque so body copy cannot bleed through it.
- Light-mode particles and clouds confirmed visible against the pale sky.
- Résumé button probes for `resume.pdf` and falls back to LinkedIn when it is missing, so it
  is never a dead link. Confirmed: with no PDF present it reads "Résumé on LinkedIn" and
  swaps the download icon for an external-link arrow.
- Honours `prefers-reduced-motion`: still sky, no meteors, no sparks, no slide-ins.

## Local preview

```bash
python3 -m http.server 8787
```
