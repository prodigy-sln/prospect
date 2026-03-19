# Test helper utilities for PowerShell tests — no dependencies
# Usage: . "$PSScriptRoot/helpers.ps1"

$script:TestsRun = 0
$script:TestsPass = 0
$script:TestsFail = 0

function New-TestDir {
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) "prospect-test-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    return $dir
}

function Remove-TestDir([string]$Path) {
    if ($Path -and (Test-Path $Path)) {
        Remove-Item -Recurse -Force $Path -ErrorAction SilentlyContinue
    }
}

function Assert-Eq($Expected, $Actual, [string]$Message = "assert_eq") {
    if ($Expected -ne $Actual) {
        throw "FAIL: $Message`n  expected: '$Expected'`n  actual:   '$Actual'"
    }
}

function Assert-Contains([string]$Haystack, [string]$Needle, [string]$Message = "assert_contains") {
    if ($Haystack -notmatch [regex]::Escape($Needle)) {
        throw "FAIL: $Message`n  expected to contain: '$Needle'`n  in: '$Haystack'"
    }
}

function Assert-NotContains([string]$Haystack, [string]$Needle, [string]$Message = "assert_not_contains") {
    if ($Haystack -match [regex]::Escape($Needle)) {
        throw "FAIL: $Message`n  expected NOT to contain: '$Needle'`n  in: '$Haystack'"
    }
}

function Assert-FileExists([string]$Path, [string]$Message) {
    if (-not (Test-Path $Path -PathType Leaf)) {
        throw "FAIL: ${Message}: file should exist: $Path"
    }
}

function Assert-FileNotExists([string]$Path, [string]$Message) {
    if (Test-Path $Path -PathType Leaf) {
        throw "FAIL: ${Message}: file should NOT exist: $Path"
    }
}

function Assert-DirExists([string]$Path, [string]$Message) {
    if (-not (Test-Path $Path -PathType Container)) {
        throw "FAIL: ${Message}: directory should exist: $Path"
    }
}

function New-MockArtifact([string]$DestDir, [string]$Version = "v1.0.0") {
    $root = Join-Path $DestDir "prospect-$Version"
    $dirs = @(
        ".claude/agents", ".claude/skills/sdd-start",
        ".github/agents", ".github/prompts", ".github/instructions",
        "standards/global", "specs/_templates", "specs/active", "specs/implemented",
        "product"
    )
    foreach ($d in $dirs) { New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null }

    $files = @{
        ".claude/agents/sdd-architect.md" = "# Architect Agent"
        ".claude/skills/sdd-start/SKILL.md" = "---"
        ".github/agents/sdd-start.agent.md" = "# Start Agent"
        ".github/prompts/sdd-start.prompt.md" = "---"
        ".github/instructions/sdd-context.md" = "# Context"
        ".github/copilot-instructions.md" = "# Copilot Instructions"
        "standards/global/code-quality.md" = "# Code Quality"
        "standards/global/testing.md" = "# Testing"
        "standards/global/git-workflow.md" = "# Git Workflow"
        "CLAUDE.md" = "# CLAUDE.md template"
        "specs/_templates/spec.template.md" = "# Spec Template"
        "specs/_templates/tasks.template.md" = "# Tasks Template"
        "product/mission.template.md" = "# Mission Template"
        "product/roadmap.template.md" = "# Roadmap Template"
        "README.md" = "# README"
    }
    foreach ($kv in $files.GetEnumerator()) {
        [System.IO.File]::WriteAllText((Join-Path $root $kv.Key), $kv.Value)
    }
    "" | Set-Content (Join-Path $root "specs/active/.gitkeep")
    "" | Set-Content (Join-Path $root "specs/implemented/.gitkeep")

    return $root
}

function Invoke-Tests {
    $fns = Get-Command -CommandType Function | Where-Object { $_.Name -match '^Test_' }
    if (-not $fns) {
        Write-Host "  (no Test_ functions found)"
        return
    }
    foreach ($fn in $fns) {
        $script:TestsRun++
        $testDir = New-TestDir
        try {
            & $fn.Name -TestDir $testDir
            $script:TestsPass++
            Write-Host "  ✓ $($fn.Name)"
        } catch {
            $script:TestsFail++
            Write-Host "  ✗ $($fn.Name)"
            Write-Host "    $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            Remove-TestDir $testDir
        }
    }
    Write-Host "  ──"
    Write-Host "  $($script:TestsPass)/$($script:TestsRun) passed"
    if ($script:TestsFail -gt 0) { exit 1 }
}
