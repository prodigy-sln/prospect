# PowerShell install flow tests — T020-T021
# Covers FR-1.2, FR-3.1, FR-4.1, FR-4.2, FR-5.4

$ErrorActionPreference = "Stop"
. "$PSScriptRoot/helpers.ps1"

$InstallPs1 = Join-Path $PSScriptRoot "../../install.ps1" | Resolve-Path

# Dot-source install.ps1 to get all functions in-process.
. $InstallPs1 -DryRun

function _run_install([string]$TestDir, [string]$Version) {
    $artifactDir = New-MockArtifact -DestDir $TestDir -Version $Version
    $targetDir = Join-Path $TestDir "target"
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

    Install-Files -SourceDir $artifactDir -TargetDir $targetDir `
        -InstallVersion $Version | Out-Null

    return $targetDir
}

function Test_Fresh_Install_Copies_Files([string]$TestDir) {
    $targetDir = _run_install $TestDir "v1.0.0"

    Assert-FileExists (Join-Path $targetDir "CLAUDE.md") "CLAUDE.md should exist"
    Assert-DirExists (Join-Path $targetDir "standards/global") "standards/global should exist"
    Assert-DirExists (Join-Path $targetDir ".claude/agents") ".claude/agents should exist"
    Assert-DirExists (Join-Path $targetDir ".claude/workflows") ".claude/workflows should exist"
    if (Test-Path (Join-Path $targetDir ".github")) {
        throw "FAIL: .github should NOT be installed — Claude Code is the only toolchain"
    }
}

function Test_Fresh_Install_Creates_Manifest_And_Version([string]$TestDir) {
    $targetDir = _run_install $TestDir "v1.0.0"

    Assert-FileExists (Join-Path $targetDir ".prospect-version") ".prospect-version should exist"
    Assert-FileExists (Join-Path $targetDir ".prospect-manifest.json") ".prospect-manifest.json should exist"

    $version = (Get-Content (Join-Path $targetDir ".prospect-version") -Raw).Trim()
    Assert-Contains $version "v1.0.0" "version file should contain v1.0.0"

    $manifest = Get-Content (Join-Path $targetDir ".prospect-manifest.json") -Raw
    Assert-NotContains $manifest '"toolchains"' "manifest should not carry a toolchains field"
}

function Test_Fresh_Install_Creates_Empty_Directories([string]$TestDir) {
    $targetDir = _run_install $TestDir "v1.0.0"

    Assert-DirExists (Join-Path $targetDir "specs/active") "specs/active should exist"
    Assert-DirExists (Join-Path $targetDir "specs/archive") "specs/archive should exist"
    Assert-DirExists (Join-Path $targetDir "product") "product should exist"
}

function Test_Fresh_Install_Seeds_Registry([string]$TestDir) {
    $targetDir = _run_install $TestDir "v1.0.0"

    Assert-FileExists (Join-Path $targetDir "specs/REGISTRY.md") "specs/REGISTRY.md should be seeded"
}

Invoke-Tests
