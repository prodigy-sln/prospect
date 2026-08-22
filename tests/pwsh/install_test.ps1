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

function Test_Conflict_Does_Not_Record_User_Checksum([string]$TestDir) {
    $targetDir = _run_install $TestDir "v1.0.0"

    $rel = ".claude/agents/sdd-architect.md"
    [System.IO.File]::WriteAllText((Join-Path $targetDir $rel), "# My custom architect agent")

    $sourceV2 = New-MockArtifact -DestDir (Join-Path $TestDir "v2") -Version "v2.0.0"
    [System.IO.File]::WriteAllText((Join-Path $sourceV2 $rel), "# Architect Agent v2 content")
    Set-MockManifest -ArtifactRoot $sourceV2 -Version "v2.0.0"

    Install-Files -SourceDir $sourceV2 -TargetDir $targetDir -InstallVersion "v2.0.0" | Out-Null

    $recorded = Read-ManifestChecksum -TargetDir $targetDir -RelativePath $rel
    $userSum = Get-Sha256 -FilePath (Join-Path $targetDir $rel)
    $shippedSum = Get-Sha256 -FilePath (Join-Path $sourceV2 $rel)

    if ($recorded -eq $userSum) {
        throw "FAIL: manifest recorded the user's modified file as the tracked baseline"
    }
    Assert-Eq $shippedSum $recorded "manifest must record the shipped v2 checksum for a conflicted file"

    # The user's file survives a further update while the conflict is unmerged.
    $sourceV3 = New-MockArtifact -DestDir (Join-Path $TestDir "v3") -Version "v3.0.0"
    [System.IO.File]::WriteAllText((Join-Path $sourceV3 $rel), "# Architect Agent v3 content")
    Set-MockManifest -ArtifactRoot $sourceV3 -Version "v3.0.0"
    Install-Files -SourceDir $sourceV3 -TargetDir $targetDir -InstallVersion "v3.0.0" | Out-Null

    $content = Get-Content (Join-Path $targetDir $rel) -Raw
    Assert-Contains $content "My custom architect agent" "the second update must not overwrite the unmerged file"
}

function Test_Install_Scripts_And_Readme_Not_Installed([string]$TestDir) {
    $artifactDir = New-MockArtifact -DestDir $TestDir -Version "v1.0.0"
    $targetDir = Join-Path $TestDir "target"
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $targetDir "README.md"), "# My project")

    Install-Files -SourceDir $artifactDir -TargetDir $targetDir -InstallVersion "v1.0.0" | Out-Null

    Assert-Contains (Get-Content (Join-Path $targetDir "README.md") -Raw) "My project" `
        "the project's README.md must not be replaced by the framework README"
    Assert-FileNotExists (Join-Path $targetDir "install.sh") "install.sh must not be installed"
    Assert-FileNotExists (Join-Path $targetDir "install.ps1") "install.ps1 must not be installed"

    $manifest = Get-Content (Join-Path $targetDir ".prospect-manifest.json") -Raw
    Assert-NotContains $manifest '"install.sh"' "install.sh must not be tracked in the manifest"
    Assert-NotContains $manifest '"README.md"' "README.md must not be tracked in the manifest"
}

function Test_Fresh_Install_Does_Not_Clobber_Existing_File([string]$TestDir) {
    $artifactDir = New-MockArtifact -DestDir $TestDir -Version "v1.0.0"
    $targetDir = Join-Path $TestDir "target"
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $targetDir "CLAUDE.md"), "# Existing project instructions")

    Install-Files -SourceDir $artifactDir -TargetDir $targetDir -InstallVersion "v1.0.0" | Out-Null

    Assert-Contains (Get-Content (Join-Path $targetDir "CLAUDE.md") -Raw) "Existing project instructions" `
        "a pre-existing CLAUDE.md must survive a fresh install"
    Assert-FileExists (Join-Path $targetDir "CLAUDE.md.prospect-incoming") `
        "the framework CLAUDE.md must be offered as .prospect-incoming"
}

function Test_Merge_Proposal_Prints_Command_When_Non_Interactive([string]$TestDir) {
    function Test-Interactive { return $false }

    # Write-Host emits on the information stream; 6>&1 captures it.
    $output = (Invoke-ProposeMerge -TargetDir $TestDir 6>&1 | Out-String)

    Assert-Contains $output 'claude "' "must print the claude command"
    Assert-Contains $output ".prospect-incoming" "the printed prompt must reference the incoming files"
}

Invoke-Tests
