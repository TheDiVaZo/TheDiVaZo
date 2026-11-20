
## Activity

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="git-info-combine/heatmap-dark.svg">
  <img alt="Daily activity from configured Git services combined with manually exported local commits" src="git-info-combine/heatmap-light.svg">
</picture>

API activity and local commits are different measures. Each square adds the daily units reported by the configured sources; colored segments show each source's share for that day. The legend names the sources actually included. Local commits use the configured time zone, while API calendars retain their own dates.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="git-info-combine/stats-dark.svg">
  <img alt="Available Git statistics across configured sources" src="git-info-combine/stats-light.svg">
</picture>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="git-info-combine/languages-dark.svg">
  <img alt="Top eight repository languages from sources that report language statistics" src="git-info-combine/languages-light.svg">
</picture>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="git-info-combine/hosts-dark.svg">
  <img alt="Activity and available metrics split by source" src="git-info-combine/hosts-light.svg">
</picture>

Unavailable metrics are marked on the cards. Repository language shares describe project composition; WakaTime below measures coding time.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="git-info-combine/wakatime-dark.svg">
  <img alt="Coding time for up to eight languages over the last thirty days" src="git-info-combine/wakatime-light.svg">
</picture>

[How this graph is updated](CONTRIBUTIONS.md)
