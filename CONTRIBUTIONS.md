# Updating profile activity

The scheduled workflow combines GitHub activity, optional GitLab/Forgejo servers and the reviewed JSON files in `contributions/manual`. Corporate repositories are read only by the local exporter; GitHub Actions never connects to them. The initial SVG files show only the locally exported EXBO source. Once the workflow credentials are configured, its next successful run adds the automatic sources.

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
- `GIC_WAKATIME_TOKEN`: the personal WakaTime OAuth token used by the `wakatime-api-key` input. The card shows coding time for up to eight languages over the last thirty days; it does not add time to the Git heatmap. Without this secret, the Action skips the WakaTime card.
- Optional `GIC_SOURCES`: a JSON array of automatic servers, each with `id`, `url`, `token`, `label`, `color`, optional `provider` (`gitlab` or `forgejo`) and provider-specific `options`. Provider detection runs when `provider` is omitted. Use a GitLab personal token with `read_api` and `read_user`, or a Forgejo personal token with `read:user`.
- Legacy `GIC_GITLAB_SOURCES` remains a fallback only while `GIC_SOURCES` is empty. Once the shared secret is set, it must contain **all** desired GitLab and Forgejo servers; the legacy list is no longer used. These API sources are separate from EXBO. Do not add credentials for the local corporate repositories here.

For example, the value of `GIC_SOURCES` can be:

```json
[
  { "id": "work", "url": "https://gitlab.example.com", "token": "<TOKEN_1>", "label": "Work", "color": "#fc6d26" },
  { "id": "personal", "url": "https://forgejo.example.org", "token": "<TOKEN_2>", "label": "Personal", "color": "#fb923c" }
]
```

Use installation base URLs, not API or repository URLs. To migrate an existing GitLab list, retain its fields, move any `mirrors` array into `options.mirrors`, and add other servers to the same list. A Forgejo server previously put in the legacy GitLab secret must be moved into this shared secret. Add `"provider": "forgejo"` or `"provider": "gitlab"` to bypass detection when necessary. The provider's token must belong to the account whose activity you want shown. Save the secret, then run **Actions > Profile activity > Run workflow**.

Forgejo reports calendar events in UTC; it does not report exact authored-commit totals through this integration. Its first fetch is limited to the server calendar window (371 rolling days, excluding the oldest partial day). Later runs preserve older snapshots in the cache and replace the recent window, so unchanged data is not counted again. Do not delete the cache if that archived history matters. Labels are public; addresses and tokens belong only in the secret.

An unavailable automatic source or invalid manual JSON fails the run without replacing previous output. A missing manual directory is harmless when automatic sources are configured. No token is needed for a local manual-only render.

The workflow pins the fork to an exact commit. For initial publication, push the fork first, configure the profile secret, then push this profile and run the workflow. When updating the fork later, deliberately update the pinned SHA.

The README displays five separate cards, each with light and dark variants: `heatmap`, `stats`, `languages`, `hosts` and `wakatime`. No combined layout is enabled. The heatmap covers the last year; Git statistics use the history available to each source, while WakaTime covers the last thirty days.

The languages card shows up to eight repository languages, weighted by repository composition. WakaTime shows actual coding time by language, also up to eight languages. These percentages measure different things. Forgejo supplies calendar activity and EXBO supplies local commit counts; unsupported statistics remain marked as unavailable, and mixed totals identify incomplete coverage.

The heatmap uses `heatmap-mode: hosts`: each day's square is split into colored segments proportional to source activity. GitHub is green; other sources use their configured colors. Set `heatmap-mode: single` for a green summed grid. SVG cell titles include date, totals and source-specific units; open the SVG directly to inspect them, since per-cell hover is not guaranteed when GitHub embeds an SVG as an image.
