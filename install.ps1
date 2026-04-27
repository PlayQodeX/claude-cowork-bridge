# claude-cowork-bridge installer (PowerShell)
#
# Idempotent: copies the skill, seeds inbox/instructions only if they don't
# already exist. Safe to re-run.
#
# Two modes of invocation:
#   1. Piped:  irm https://raw.githubusercontent.com/PlayQodeX/claude-cowork-bridge/main/install.ps1 | iex
#   2. Local:  cd claude-cowork-bridge ; .\install.ps1

$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/PlayQodeX/claude-cowork-bridge.git'
$ClaudeDir = Join-Path $HOME '.claude'
$SkillsDir = Join-Path $ClaudeDir 'skills'
$CoworkSkillDir = Join-Path $SkillsDir 'cowork'
$InboxFile = Join-Path $ClaudeDir 'cowork-inbox.md'
$InstructionsFile = Join-Path $ClaudeDir 'cowork-project-instructions.md'

# Resolve source directory. If invoked via irm|iex, $MyInvocation.MyCommand.Path
# is null and the local skill files are not present; clone to a temp dir.
$ScriptPath = $MyInvocation.MyCommand.Path
$LocalSrc = $null
if ($ScriptPath) { $LocalSrc = Split-Path -Parent $ScriptPath }

$CleanupTmpDir = $null
if ($LocalSrc -and (Test-Path (Join-Path $LocalSrc 'skills/cowork/SKILL.md'))) {
    $SrcDir = $LocalSrc
} else {
    $SrcDir = Join-Path $env:TEMP "claude-cowork-bridge-$([System.IO.Path]::GetRandomFileName().Replace('.',''))"
    $CleanupTmpDir = $SrcDir
    Write-Host "Fetching claude-cowork-bridge into $SrcDir..."
    git clone --depth 1 $RepoUrl $SrcDir 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "git clone failed. Ensure git is installed and on PATH."
    }
}

try {
    Write-Host "Installing claude-cowork-bridge into $ClaudeDir"

    if (-not (Test-Path $SkillsDir))      { New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null }
    if (-not (Test-Path $CoworkSkillDir)) { New-Item -ItemType Directory -Path $CoworkSkillDir -Force | Out-Null }

    Write-Host "  - Skill -> $CoworkSkillDir\SKILL.md"
    Copy-Item -Path (Join-Path $SrcDir 'skills/cowork/SKILL.md') -Destination (Join-Path $CoworkSkillDir 'SKILL.md') -Force

    if (-not (Test-Path $InboxFile)) {
        Write-Host "  - Inbox seed -> $InboxFile"
        Copy-Item -Path (Join-Path $SrcDir 'templates/cowork-inbox.md') -Destination $InboxFile
    } else {
        Write-Host "  - Inbox already exists at $InboxFile — leaving untouched"
    }

    if (-not (Test-Path $InstructionsFile)) {
        Write-Host "  - Cowork-side instructions -> $InstructionsFile"
        Copy-Item -Path (Join-Path $SrcDir 'templates/cowork-project-instructions.md') -Destination $InstructionsFile
    } else {
        Write-Host "  - Cowork-side instructions already exist at $InstructionsFile — leaving untouched"
    }

    Write-Host ""
    Write-Host "Done. Open Claude Code and run '/cowork' to verify the skill is registered."
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Open $InboxFile and read the header."
    Write-Host "  2. (Optional) Open $InstructionsFile and configure your upstream Claude conversation Project."
    Write-Host "  3. (Optional) Create $ClaudeDir\cowork-config.json — see docs/configuration.md."
    Write-Host "  4. Paste a real finding below the '---' in the inbox and run '/cowork' in Claude Code."
} finally {
    if ($CleanupTmpDir -and (Test-Path $CleanupTmpDir)) {
        Remove-Item -Recurse -Force $CleanupTmpDir
    }
}
