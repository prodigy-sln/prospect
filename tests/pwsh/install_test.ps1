# PowerShell install flow tests — T020-T021
# Covers FR-1.2, FR-3.1, FR-4.1, FR-4.2, FR-5.4

$ErrorActionPreference = "Stop"
. "$PSScriptRoot/helpers.ps1"

$InstallPs1 = Join-Path $PSScriptRoot "../../install.ps1" | Resolve-Path

# Dot-source install.ps1 to get all functions in-process.
. $InstallPs1 -DryRun

function _run_install([string]$TestDir, [string]$Version, [string]$Toolchain) {
    $artifactDir = New-MockArtifact -DestDir $TestDir -Version $Version
    $targetDir = Join-Path $TestDir "target"
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

    Install-Files -SourceDir $artifactDir -TargetDir $targetDir `
        -InstallVersion $Version -Toolchain $Toolchain | Out-Null

    return $targetDir
}

function Test_Fresh_Install_Copies_Files([string]$TestDir) {
    $targetDir = _run_install $TestDir "v1.0.0" "all"

    Assert-FileExists (Join-Path $targetDir "CLAUDE.md") "CLAUDE.md should exist"
    Assert-DirExists (Join-Path $targetDir "standards/global") "standards/global should exist"
    Assert-DirExists (Join-Path $targetDir ".claude/agents") ".claude/agents should exist"
    Assert-DirExists (Join-Path $targetDir ".github/agents") ".github/agents should exist"
}

function Test_Fresh_Install_Creates_Manifest_And_Version([string]$TestDir) {
    $targetDir = _run_install $TestDir "v1.0.0" "all"

    Assert-FileExists (Join-Path $targetDir ".prospect-version") ".prospect-version should exist"
    Assert-FileExists (Join-Path $targetDir ".prospect-manifest.json") ".prospect-manifest.json should exist"

    $version = (Get-Content (Join-Path $targetDir ".prospect-version") -Raw).Trim()
    Assert-Contains $version "v1.0.0" "version file should contain v1.0.0"
}

function Test_Fresh_Install_Creates_Empty_Directories([string]$TestDir) {
    $targetDir = _run_install $TestDir "v1.0.0" "all"

    Assert-DirExists (Join-Path $targetDir "specs/active") "specs/active should exist"
    Assert-DirExists (Join-Path $targetDir "specs/implemented") "specs/implemented should exist"
    Assert-DirExists (Join-Path $targetDir "product") "product should exist"
}

function Test_Toolchain_Claude_Only([string]$TestDir) {
    $targetDir = _run_install $TestDir "v1.0.0" "claude"

    Assert-DirExists (Join-Path $targetDir ".claude") ".claude should exist"
    Assert-FileExists (Join-Path $targetDir "CLAUDE.md") "CLAUDE.md should exist"
    if (Test-Path (Join-Path $targetDir ".github/agents")) {
        throw "FAIL: .github/agents should NOT exist for claude-only install"
    }
}

function Test_Toolchain_Copilot_Only([string]$TestDir) {
    $targetDir = _run_install $TestDir "v1.0.0" "copilot"

    Assert-DirExists (Join-Path $targetDir ".github") ".github should exist"
    if (Test-Path (Join-Path $targetDir ".claude")) {
        throw "FAIL: .claude should NOT exist for copilot-only install"
    }
}

Invoke-Tests
