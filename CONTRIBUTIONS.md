# Updating profile activity

The scheduled workflow combines GitHub activity, optional GitLab accounts and the reviewed JSON files in `contributions/manual`. Corporate repositories are read only by the local exporter; GitHub Actions never connects to them. The initial SVG files show only the locally exported EXBO source. Once the workflow credentials are configured, its next successful run adds the automatic sources.

Before publishing corporate statistics, obtain the appropriate permission. Review the daily counts and source labels: aggregate activity can itself be sensitive. JSON and SVG files intentionally contain public source labels, dates and counts, without commit messages, hashes, author emails, repository paths or internal URLs.

## One-time local setup

Keep this profile checkout and the existing `git-info-combine` checkout as sibling directories. Install Git, Bun and the fork's dependencies once. No installation, fetch or network request is performed during export.

The local `.contributions.local.json` is ignored by Git. It contains the EXBO source, its three private repository folders and `Europe/Moscow`. Author addresses default to each repository's `git config user.email`; set `author-emails` locally if your historical commits use other addresses. Email matching is exact and case-sensitive. Never force-add this config to Git.

## After work

From a PowerShell prompt in this profile checkout:

```powershell
.\update-contributions.ps1
```

To also create a local commit containing only the exported JSON:

```powershell
.\update-contributions.ps1 -Commit
```

Neither command pushes. The script supports Windows PowerShell 5.1 and newer. Optional `-ConfigPath` and `-ToolDirectory` override the ignored config location and sibling tool checkout. The output stays in this profile's `contributions/manual`.

The report gives each public source name, repository count, unique commit count and date range. Re-exporting identical history does not rewrite the files. With `-Commit`, unchanged data creates no commit; unrelated staged files remain staged and uncommitted. The commit uses the public GitHub identity `TheDiVaZo <TheDiVaZo@users.noreply.github.com>` without changing your Git configuration. Resolve staged changes or conflicts in the manual directory before using `-Commit`.

Inspect the JSON diff, then publish explicitly when ready:

```powershell
git diff -- contributions/manual
git log -1 --stat
git push origin main
```

If you ran without `-Commit`, commit the reviewed JSON yourself before pushing.

## Counting rules

The exporter uses locally available branches, remote-tracking refs and HEAD. It counts matching authors' commits, including merges, by **committer** date in the configured time zone. A SHA counts once per source, even if present in several branches or mirrored repositories. Stashes, reflogs and commits reachable only through tags are excluded. No fetch, lazy object download or repository modification is performed.

Missing, shallow or unreadable repositories fail the export before replacing any JSON. A valid empty repository is supported. Files are replaced atomically one at a time after all repositories have been read; a disk/write failure is reported and prevents a commit. Unrelated JSON is never removed. If you change a source ID or split EXBO into several sources, review and remove the old aggregate JSON explicitly, otherwise both old and new sources would be counted.

Local commits and API contributions have different definitions. API date aggregates cannot be accurately converted to the local export's time zone. Published aggregates contain no SHA, so duplicate activity between a manual source and an automatic API source cannot be detected; avoid configuring the same work in both.

## GitHub Actions setup

The workflow runs daily at 03:00 UTC, on reviewed manual JSON changes on `main`, and via **Run workflow**. Generated images live in `git-info-combine/`; their own commits do not match the workflow's push filters.

In this repository's **Settings → Secrets and variables → Actions**, configure:

- `GIC_GITHUB_TOKEN`: a personal access token belonging to the profile owner. Follow the fork README's permissions for the private/organisation activity you want included; the default workflow token is not a substitute for profile-wide collection.
- Optional `GIC_GITLAB_SOURCES`: the fork's existing JSON array of GitLab accounts, each with `id`, `url`, `token`, `label`, `color` and optional `mirrors`. These are automatic API sources, separate from the local EXBO export. Do not add corporate local-repository credentials here.

An unavailable automatic source or invalid manual JSON fails the run without replacing previous output. A missing manual directory is harmless when automatic sources are configured. No token is needed for a local manual-only render.

The workflow pins the fork to an exact commit. For initial publication, push the fork first, configure the profile secret, then push this profile and run the workflow. When updating the fork later, deliberately update the pinned SHA.

The README uses `heatmap-light.svg` and `heatmap-dark.svg`. The summed mode stays green; change `heatmap-mode` to `hosts` in the workflow for colored source segments. SVG cell titles include date, totals and source-specific units; open the SVG directly to inspect them, since per-cell hover is not guaranteed when GitHub embeds an SVG as an image.
