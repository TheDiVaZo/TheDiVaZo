[CmdletBinding()]
param(
    [switch]$Commit,
    [string]$ConfigPath,
    [string]$ToolDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:failureMessage = 'Contribution update failed. Check configuration, local repositories and tool availability.'

function Stop-Update {
    param([string]$Message)
    $script:failureMessage = $Message
    throw $Message
}

function Invoke-LocalProcess {
    param([string]$Executable, [string[]]$Arguments)
    $quoted = foreach ($argument in $Arguments) {
        $escaped = [regex]::Replace($argument, '(\\*)"', '$1$1\"')
        $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
        '"' + $escaped + '"'
    }
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $Executable
    $info.Arguments = $quoted -join ' '
    $info.WorkingDirectory = $PSScriptRoot
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $info.StandardErrorEncoding = New-Object System.Text.UTF8Encoding($false)
    $info.EnvironmentVariables['GIT_TERMINAL_PROMPT'] = '0'
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $info
    try {
        [void]$process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        [pscustomobject]@{
            ExitCode = $process.ExitCode
            Stdout = $stdout.GetAwaiter().GetResult()
            Stderr = $stderr.GetAwaiter().GetResult()
        }
    }
    finally { $process.Dispose() }
}

function Invoke-ProfileGit {
    param([string[]]$Arguments, [int[]]$AllowedExitCodes = @(0))
    $result = Invoke-LocalProcess -Executable 'git' -Arguments (@('-C', $PSScriptRoot) + $Arguments)
    if ($AllowedExitCodes -notcontains $result.ExitCode) {
        Stop-Update 'A profile Git operation failed. Check repository access and Git author configuration.'
    }
    $result
}

try {
    if (-not $ConfigPath) { $ConfigPath = Join-Path $PSScriptRoot '.contributions.local.json' }
    if (-not $ToolDirectory) { $ToolDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'git-info-combine' }
    $entrypoint = Join-Path $ToolDirectory 'packages/exporter/src/index.ts'
    $outputDirectory = Join-Path $PSScriptRoot 'contributions/manual'
    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) { Stop-Update 'Local contribution configuration is missing.' }
    if (-not (Test-Path -LiteralPath $entrypoint -PathType Leaf)) { Stop-Update 'The sibling git-info-combine exporter is missing. Check ToolDirectory.' }
    $bun = Get-Command bun -ErrorAction SilentlyContinue
    if (-not $bun) { Stop-Update 'Bun is required. Install it and install the fork dependencies once before running offline.' }

    if ($Commit) {
        $root = Invoke-ProfileGit -Arguments @('rev-parse', '--show-toplevel')
        if ([System.IO.Path]::GetFullPath($root.Stdout.Trim()) -ne [System.IO.Path]::GetFullPath($PSScriptRoot)) {
            Stop-Update 'The script must be located in the profile repository root.'
        }
        $conflicts = Invoke-ProfileGit -Arguments @('ls-files', '--unmerged', '--', 'contributions/manual')
        if ($conflicts.Stdout.Trim()) { Stop-Update 'Resolve conflicts in contributions/manual before exporting with -Commit.' }
        $staged = Invoke-ProfileGit -Arguments @('diff', '--cached', '--quiet', '--', 'contributions/manual') -AllowedExitCodes @(0, 1)
        if ($staged.ExitCode -eq 1) { Stop-Update 'Review staged changes in contributions/manual before exporting with -Commit.' }
    }

    $export = Invoke-LocalProcess -Executable $bun.Source -Arguments @($entrypoint, '--config', $ConfigPath, '--output-dir', $outputDirectory, '--json-summary')
    if ($export.ExitCode -ne 0) {
        # The exporter's error messages contain only config field names and repository numbers.
        $safeError = $export.Stderr.Trim()
        if ($safeError -match '^Export failed: [^\r\n]+$') { Stop-Update $safeError }
        Stop-Update 'Local export failed. No commit was created; check configuration and local repository availability.'
    }
    $summary = $export.Stdout | ConvertFrom-Json
    $files = @()
    foreach ($source in $summary.sources) {
        if ($source.file -notmatch '^[a-z0-9][a-z0-9_-]*\.json$') { Stop-Update 'The exporter returned an invalid output filename.' }
        $files += 'contributions/manual/' + $source.file
        $range = if ($source.firstDate) { $source.firstDate + ' to ' + $source.lastDate } else { 'no commits' }
        Write-Host ('{0}: {1} repositories, {2} commits, {3}' -f $source.name, $source.repositories, $source.commits, $range)
    }
    if ($files.Count -eq 0) { Stop-Update 'The exporter returned no sources.' }
    if ($Commit) {
        [void](Invoke-ProfileGit -Arguments (@('add', '--') + $files))
        $changed = Invoke-ProfileGit -Arguments (@('diff', '--cached', '--quiet', '--') + $files) -AllowedExitCodes @(0, 1)
        if ($changed.ExitCode -eq 0) { Write-Host 'Manual contribution data is unchanged; no commit created.' }
        else {
            [void](Invoke-ProfileGit -Arguments (@('-c', 'user.name=TheDiVaZo', '-c', 'user.email=TheDiVaZo@users.noreply.github.com', 'commit', '--quiet', '--only', '-m', 'chore: update manual contribution data', '--') + $files))
            Write-Host 'Created a local commit containing only the exported JSON files.'
        }
    }
    Write-Host 'Nothing was pushed. Review the exported data before publishing.'
}
catch {
    [Console]::Error.WriteLine($script:failureMessage)
    exit 1
}
