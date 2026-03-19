#Requires -Version 5.1
# install.ps1 — Prospect install/update script (PowerShell)
# Implements: FR-1.2 (PowerShell install), FR-1.3 (identical results to install.sh)
# Compatible with PowerShell 5.1+ and PowerShell 7+.
#
# Usage:
#   irm https://raw.githubusercontent.com/prodigy-sln/prospect/main/install.ps1 | iex
#   .\install.ps1 [-Claude] [-Copilot] [-All] [-Help] [-Version <tag>]
#
# Test injection:
#   Set $env:PROSPECT_ARTIFACT_PATH to a local .tar.gz path to bypass download.

[CmdletBinding()]
param(
    [switch]$Claude,
    [switch]$Copilot,
    [switch]$All,
    [switch]$Help,
    [switch]$DryRun,
    [string]$Version = "",
    [string]$TargetDir = ""
)

# ── Constants ──────────────────────────────────────────────────────────────────

$PROSPECT_REPO_URL = if ($env:PROSPECT_REPO_URL) { $env:PROSPECT_REPO_URL } `
    else { "https://github.com/prodigy-sln/prospect" }

# ── Usage ──────────────────────────────────────────────────────────────────────

function Show-Usage {
    Write-Host @"
usage: install.ps1 [OPTIONS] [-Version <tag>]

Install or update the Prospect SDD framework in the current directory.

OPTIONS:
  -Claude     Install Claude Code toolchain only
  -Copilot    Install VS Code Copilot toolchain only
  -All        Install both toolchains (default)
  -Help       Print this help message and exit

VERSION:
  Optional semver tag via -Version, e.g. -Version v1.2.3.
  Defaults to the latest release.

EXAMPLES:
  .\install.ps1
  .\install.ps1 -Version v1.2.0
  .\install.ps1 -Claude
  .\install.ps1 -Version v1.2.0 -Claude
"@
}

# ── Version resolution ─────────────────────────────────────────────────────────

# Invoke-FetchLatestVersionTag
# Queries the GitHub API for the latest Prospect release tag.
# Tests override $env:PROSPECT_ARTIFACT_PATH to avoid network calls.
function Invoke-FetchLatestVersionTag {
    $apiUrl = "https://api.github.com/repos/prodigy-sln/prospect/releases/latest"
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -ErrorAction Stop
        return $response.tag_name
    }
    catch {
        Write-Error "Error: failed to fetch latest version from GitHub API: $_"
        return $null
    }
}

# Resolve-Version [version]
# "latest" or empty -> fetch via API.
# vX.Y.Z -> return as-is.
# Anything else -> error.
function Resolve-Version {
    param([string]$Requested = "latest")

    if ([string]::IsNullOrEmpty($Requested) -or $Requested -eq "latest") {
        $tag = Invoke-FetchLatestVersionTag
        if (-not $tag) {
            Write-Error "Error: failed to fetch latest version from GitHub API. Check your network connection and try again."
            return $null
        }
        return $tag
    }

    if ($Requested -match '^v\d+\.\d+\.\d+$') {
        return $Requested
    }

    Write-Error "Error: invalid version format '$Requested'. Expected vX.Y.Z (e.g. v1.2.3) or 'latest'."
    return $null
}

# ── Download & extract ─────────────────────────────────────────────────────────

# Invoke-DownloadRelease <version> <destDir>
# Downloads the release tarball for <version> and extracts contents to <destDir>.
# If $env:PROSPECT_ARTIFACT_PATH is set, copies from that local path instead
# of downloading (test injection point).
function Invoke-DownloadRelease {
    param(
        [string]$ReleaseVersion,
        [string]$DestDir
    )

    try {
        # Determine the archive extension — use .zip when PROSPECT_ARTIFACT_PATH
        # points at a zip file (test injection), otherwise default to .tar.gz.
        $artifactPath = $env:PROSPECT_ARTIFACT_PATH
        $ext = if ($artifactPath -and $artifactPath -like "*.zip") { ".zip" } else { ".tar.gz" }
        $tmpTarball = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString() + $ext

        # Test injection: bypass HTTP download when PROSPECT_ARTIFACT_PATH is set.
        if ($artifactPath) {
            if (-not (Test-Path $artifactPath)) {
                Write-Error "Error: PROSPECT_ARTIFACT_PATH '$artifactPath' not found."
                return $false
            }
            Copy-Item -LiteralPath $artifactPath -Destination $tmpTarball -Force
        }
        else {
            $url = "$PROSPECT_REPO_URL/releases/download/$ReleaseVersion/prospect-$ReleaseVersion.tar.gz"
            try {
                Invoke-WebRequest -Uri $url -OutFile $tmpTarball -UseBasicParsing -ErrorAction Stop
            }
            catch {
                Write-Error "Error: failed to download release $ReleaseVersion from $url : $_"
                return $false
            }
        }

        # Extract the archive.
        # Prefer Expand-Archive for .zip; fall back to tar for .tar.gz.
        $tmpExtract = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
        New-Item -ItemType Directory -Path $tmpExtract -Force | Out-Null

        try {
            if ($tmpTarball -like "*.zip") {
                try {
                    Expand-Archive -LiteralPath $tmpTarball -DestinationPath $tmpExtract -Force -ErrorAction Stop
                }
                catch {
                    Write-Error "Error: downloaded file is not a valid archive for version $ReleaseVersion : $_"
                    return $false
                }
            }
            else {
                $tarResult = & tar -xzf $tmpTarball -C $tmpExtract 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Error: downloaded file is not a valid archive for version $ReleaseVersion"
                    return $false
                }
            }
        }
        finally {
            Remove-Item -LiteralPath $tmpTarball -Force -ErrorAction SilentlyContinue
        }

        # Move extracted contents into DestDir.
        $extractedRoot = Join-Path $tmpExtract "prospect-$ReleaseVersion"
        $sourceRoot = if (Test-Path $extractedRoot) { $extractedRoot } else { $tmpExtract }

        # Copy all items (including hidden) from sourceRoot to DestDir.
        Get-ChildItem -Path $sourceRoot -Force | ForEach-Object {
            $dest = Join-Path $DestDir $_.Name
            Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
        }

        Remove-Item -LiteralPath $tmpExtract -Recurse -Force -ErrorAction SilentlyContinue
        return $true
    }
    catch {
        Remove-Item -LiteralPath $tmpTarball -Force -ErrorAction SilentlyContinue
        Write-Error "Error: unexpected failure during download: $_"
        return $false
    }
}

# ── Toolchain selection ────────────────────────────────────────────────────────

# Select-Toolchain <targetDir> <cliToolchain>
# Priority:
#   1. CLI flag ($cliToolchain non-empty) -> use it
#   2. Existing manifest -> derive from toolchains array
#   3. Interactive stdin (terminal) -> prompt user
#   4. Non-interactive default -> "all"
function Select-Toolchain {
    param(
        [string]$TargetDir,
        [string]$CliToolchain = ""
    )

    # 1. CLI flag wins unconditionally.
    if ($CliToolchain) {
        return $CliToolchain
    }

    # 2. Manifest-based default.
    $manifest = Join-Path $TargetDir ".prospect-manifest.json"
    if (Test-Path $manifest) {
        $content = Get-Content -LiteralPath $manifest -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $hasClaude  = $content -match '"claude"'
            $hasCopilot = $content -match '"copilot"'
            if ($hasClaude -and $hasCopilot) { return "all" }
            elseif ($hasClaude)              { return "claude" }
            elseif ($hasCopilot)             { return "copilot" }
        }
    }

    # 3. Interactive prompt (only when stdin is a terminal and not piped).
    $isInteractive = [Environment]::UserInteractive -and [Console]::IsInputRedirected -eq $false
    if ($isInteractive) {
        Write-Host "Select toolchain to install:" -ForegroundColor Cyan
        Write-Host "  1) claude"
        Write-Host "  2) copilot"
        Write-Host "  3) all (default)"
        $choice = Read-Host "Choice [3]"
        switch ($choice.Trim()) {
            "1" { return "claude" }
            "2" { return "copilot" }
            default { return "all" }
        }
    }

    # 4. Non-interactive default.
    return "all"
}

# ── File categorization ────────────────────────────────────────────────────────

# Get-FileCategory <relativePath>
# Returns: "framework" | "customizable" | "user-content" | "template"
function Get-FileCategory {
    param([string]$RelativePath)

    # Normalise to forward slashes for consistent matching.
    $p = $RelativePath -replace '\\', '/'

    # Template files.
    if ($p -eq "product/mission.template.md" -or $p -eq "product/roadmap.template.md") {
        return "template"
    }

    # Framework-managed files.
    if ($p -match '^\.claude/(agents|skills)/' -or
        $p -match '^\.github/(agents|prompts|instructions)/' -or
        $p -match '^specs/_templates/') {
        return "framework"
    }

    # User-customizable files.
    if ($p -match '^standards/global/[^/]+\.md$' -or
        $p -eq "CLAUDE.md" -or
        $p -eq ".github/copilot-instructions.md") {
        return "customizable"
    }

    # User-created content.
    if ($p -match '^specs/(active|implemented)/' -or
        $p -eq "product/mission.md" -or
        $p -eq "product/roadmap.md") {
        return "user-content"
    }

    # Default: framework-managed.
    return "framework"
}

# ── SHA-256 checksum ───────────────────────────────────────────────────────────

# Get-Sha256 <filePath>
# Returns the SHA-256 hex digest (lowercase) of the file at <filePath>.
function Get-Sha256 {
    param([string]$FilePath)
    $hash = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash
    return $hash.ToLower()
}

# ── Manifest read/write ────────────────────────────────────────────────────────

# Write-Manifest <targetDir> <version> <toolchains> <installedFiles[]>
# Creates .prospect-manifest.json in targetDir (FR-4.2).
function Write-Manifest {
    param(
        [string]$TargetDir,
        [string]$ManifestVersion,
        [string]$Toolchains,
        [string[]]$InstalledFiles
    )

    # Build toolchains JSON array.
    $tcList = ($Toolchains -replace ',', ' ') -split '\s+' | Where-Object { $_ }
    $tcJson = ($tcList | ForEach-Object { "`"$_`"" }) -join ','

    # Build files JSON object with per-file checksums.
    $fileEntries = @()
    foreach ($rel in $InstalledFiles) {
        $fullPath = Join-Path $TargetDir $rel
        if (Test-Path -LiteralPath $fullPath) {
            $checksum = Get-Sha256 -FilePath $fullPath
            $escaped = $rel -replace '\\', '/'
            $fileEntries += "`"$escaped`":`"$checksum`""
        }
    }
    $filesJson = $fileEntries -join ','

    $json = "{`"version`":`"$ManifestVersion`",`"toolchains`":[$tcJson],`"files`":{$filesJson}}"
    $manifestPath = Join-Path $TargetDir ".prospect-manifest.json"

    # Write with UTF-8 without BOM for cross-platform compatibility.
    [System.IO.File]::WriteAllText($manifestPath, $json, [System.Text.UTF8Encoding]::new($false))
}

# Read-ManifestVersion <targetDir>
# Returns the version string from the manifest, or empty string if absent.
function Read-ManifestVersion {
    param([string]$TargetDir)
    $manifest = Join-Path $TargetDir ".prospect-manifest.json"
    if (-not (Test-Path $manifest)) { return "" }

    $content = Get-Content -LiteralPath $manifest -Raw -ErrorAction SilentlyContinue
    if ($content -match '"version":"([^"]+)"') {
        return $Matches[1]
    }
    return ""
}

# Read-ManifestChecksum <targetDir> <relativePath>
# Returns the stored SHA-256 for relativePath from the manifest, or empty string.
function Read-ManifestChecksum {
    param(
        [string]$TargetDir,
        [string]$RelativePath
    )
    $manifest = Join-Path $TargetDir ".prospect-manifest.json"
    if (-not (Test-Path $manifest)) { return "" }

    $content = Get-Content -LiteralPath $manifest -Raw -ErrorAction SilentlyContinue
    # Normalise path separator for JSON key matching.
    $key = ($RelativePath -replace '\\', '/') -replace '([.\/\[\]*^$])', '\$1'
    if ($content -match "`"$key`":`"([^`"]+)`"") {
        return $Matches[1]
    }
    return ""
}

# ── Version file ───────────────────────────────────────────────────────────────

# Write-VersionFile <targetDir> <version>
function Write-VersionFile {
    param(
        [string]$TargetDir,
        [string]$InstallVersion
    )
    $versionPath = Join-Path $TargetDir ".prospect-version"
    [System.IO.File]::WriteAllText($versionPath, "$InstallVersion`n", [System.Text.UTF8Encoding]::new($false))
}

# ── Toolchain filter helper ────────────────────────────────────────────────────

# Test-IncludeByToolchain <relativePath> <toolchain>
# Returns $true if the file should be included for the selected toolchain.
function Test-IncludeByToolchain {
    param(
        [string]$RelativePath,
        [string]$Toolchain
    )
    $p = $RelativePath -replace '\\', '/'

    if ($Toolchain -eq "claude") {
        if ($p -match '^\.github/') { return $false }
    }
    elseif ($Toolchain -eq "copilot") {
        if ($p -match '^\.claude/') { return $false }
        if ($p -eq "CLAUDE.md")     { return $false }
    }
    return $true
}

# ── Install orchestration ──────────────────────────────────────────────────────

# Install-Files <sourceDir> <targetDir> <version> <toolchain>
# Orchestrates the full install/update flow (FR-3.1 – FR-7.3).
function Install-Files {
    param(
        [string]$SourceDir,
        [string]$TargetDir,
        [string]$InstallVersion,
        [string]$Toolchain
    )

    # FR-7.1: Warn if not a git repo, but continue.
    $gitDir = Join-Path $TargetDir ".git"
    if (-not (Test-Path $gitDir)) {
        Write-Warning "Warning: $TargetDir is not a git repository. It is recommended to run Prospect inside a git repo."
    }

    $manifestPath = Join-Path $TargetDir ".prospect-manifest.json"
    $manifestExists = Test-Path $manifestPath

    # FR-7.3: Idempotency — if same version and no file changes, exit early.
    if ($manifestExists) {
        $currentVersion = Read-ManifestVersion -TargetDir $TargetDir
        if ($currentVersion -eq $InstallVersion) {
            $anyDiff = $false
            Get-ChildItem -Path $SourceDir -Recurse -File -Force | ForEach-Object {
                if ($anyDiff) { return }
                $rel = $_.FullName.Substring($SourceDir.Length).TrimStart('\', '/')
                $rel = $rel -replace '\\', '/'

                if ($_.Name -eq ".gitkeep") { return }
                if (-not (Test-IncludeByToolchain -RelativePath $rel -Toolchain $Toolchain)) { return }

                $category = Get-FileCategory -RelativePath $rel
                if ($category -eq "user-content") { return }

                $targetFile = Join-Path $TargetDir $rel
                if (-not (Test-Path -LiteralPath $targetFile)) {
                    $anyDiff = $true
                    return
                }
                $srcHash    = Get-Sha256 -FilePath $_.FullName
                $targetHash = Get-Sha256 -FilePath $targetFile
                if ($srcHash -ne $targetHash) {
                    $anyDiff = $true
                }
            }
            if (-not $anyDiff) {
                Write-Host "Already up to date ($InstallVersion)."
                return $true
            }
        }
    }

    # Track outcomes.
    $installedFiles = [System.Collections.Generic.List[string]]::new()
    $skippedFiles   = [System.Collections.Generic.List[string]]::new()
    $conflictFiles  = [System.Collections.Generic.List[string]]::new()

    # FR-5.4: Ensure required directories exist.
    @("specs/active", "specs/implemented", "product") | ForEach-Object {
        $dir = Join-Path $TargetDir $_
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    # Walk all files in SourceDir.
    Get-ChildItem -Path $SourceDir -Recurse -File -Force | ForEach-Object {
        $srcFile = $_
        $rel = $srcFile.FullName.Substring($SourceDir.Length).TrimStart('\', '/')
        $rel = $rel -replace '\\', '/'

        # Skip .gitkeep placeholder files.
        if ($srcFile.Name -eq ".gitkeep") { return }

        # Apply toolchain filter (FR-2.2, FR-2.3).
        if (-not (Test-IncludeByToolchain -RelativePath $rel -Toolchain $Toolchain)) { return }

        $category   = Get-FileCategory -RelativePath $rel
        $targetFile = Join-Path $TargetDir $rel

        # FR-5.3: user-content — never touch if file already exists.
        if ($category -eq "user-content") {
            if (Test-Path -LiteralPath $targetFile) {
                $skippedFiles.Add($rel)
            }
            return
        }

        # FR-3.5: copilot-instructions.md pre-existing without manifest entry.
        if ($rel -eq ".github/copilot-instructions.md" -and
            (Test-Path -LiteralPath $targetFile) -and (-not $manifestExists)) {
            $manifestSum = Read-ManifestChecksum -TargetDir $TargetDir -RelativePath $rel
            if ([string]::IsNullOrEmpty($manifestSum)) {
                Write-Host "Note: .github/copilot-instructions.md already exists with existing content. Please merge manually with the Prospect version." -ForegroundColor Yellow
                $skippedFiles.Add($rel)
                return
            }
        }

        # Ensure parent directory exists.
        $parentDir = Split-Path -Path $targetFile -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        if (-not $manifestExists) {
            # FR-3.1: Fresh install — copy everything.
            Copy-Item -LiteralPath $srcFile.FullName -Destination $targetFile -Force
            $installedFiles.Add($rel)
        }
        else {
            # FR-3.2 / FR-3.3: Update — checksum-based conflict detection.
            $manifestSum = Read-ManifestChecksum -TargetDir $TargetDir -RelativePath $rel

            if (-not (Test-Path -LiteralPath $targetFile)) {
                # New file in this version — just copy.
                Copy-Item -LiteralPath $srcFile.FullName -Destination $targetFile -Force
                $installedFiles.Add($rel)
            }
            elseif ([string]::IsNullOrEmpty($manifestSum)) {
                # Not previously tracked — copy.
                Copy-Item -LiteralPath $srcFile.FullName -Destination $targetFile -Force
                $installedFiles.Add($rel)
            }
            else {
                $currentSum = Get-Sha256 -FilePath $targetFile

                if ($currentSum -eq $manifestSum) {
                    # FR-3.2: Unmodified — overwrite silently.
                    Copy-Item -LiteralPath $srcFile.FullName -Destination $targetFile -Force
                    $installedFiles.Add($rel)
                }
                else {
                    # FR-3.3: User-modified — write as .prospect-incoming.
                    Copy-Item -LiteralPath $srcFile.FullName -Destination "$targetFile.prospect-incoming" -Force
                    $conflictFiles.Add($rel)
                }
            }
        }
    }

    # Build complete list of manifest files.
    $manifestFiles = [System.Collections.Generic.List[string]]::new()
    $installedFiles | ForEach-Object { $manifestFiles.Add($_) }

    if ($manifestExists) {
        $conflictFiles | ForEach-Object { $manifestFiles.Add($_) }

        # Re-include previously tracked files not touched in this run.
        $prevContent = Get-Content -LiteralPath $manifestPath -Raw -ErrorAction SilentlyContinue
        if ($prevContent) {
            $regex = [System.Text.RegularExpressions.Regex]::new('"([^"]+)":"[^"]+"')
            $matches = $regex.Matches($prevContent)
            foreach ($m in $matches) {
                $prevFile = $m.Groups[1].Value
                # Skip JSON keys that are metadata, not file paths.
                if ($prevFile -eq "version" -or $prevFile -eq "toolchains") { continue }
                if ($manifestFiles.Contains($prevFile)) { continue }
                $fullPath = Join-Path $TargetDir $prevFile
                if (Test-Path -LiteralPath $fullPath) {
                    $manifestFiles.Add($prevFile)
                }
            }
        }
    }

    # Write manifest and version file (FR-4.1, FR-4.2).
    Write-Manifest -TargetDir $TargetDir -ManifestVersion $InstallVersion `
        -Toolchains $Toolchain -InstalledFiles $manifestFiles.ToArray()
    Write-VersionFile -TargetDir $TargetDir -InstallVersion $InstallVersion

    # FR-3.4: Print summary.
    Write-Host "Prospect $InstallVersion installed (toolchain: $Toolchain)."
    if ($installedFiles.Count -gt 0) {
        Write-Host "  Installed: $($installedFiles.Count) file(s)."
    }
    if ($skippedFiles.Count -gt 0) {
        Write-Host "  Skipped (user content): $($skippedFiles.Count) file(s)."
    }
    if ($conflictFiles.Count -gt 0) {
        Write-Host "  Conflicts detected — $($conflictFiles.Count) file(s) saved as .prospect-incoming:"
        $conflictFiles | ForEach-Object {
            $fullConflictPath = Join-Path $TargetDir "$_.prospect-incoming"
            Write-Host "    $fullConflictPath"
        }
        Write-Host "  Review and merge the .prospect-incoming files to complete the update."
    }

    return $true
}

# ── Main ───────────────────────────────────────────────────────────────────────

function Main {
    if ($Help) {
        Show-Usage
        exit 0
    }

    # Determine CLI toolchain override.
    $cliToolchain = ""
    if ($Claude -and $Copilot) { $cliToolchain = "all" }
    elseif ($Claude)           { $cliToolchain = "claude" }
    elseif ($Copilot)          { $cliToolchain = "copilot" }
    elseif ($All)              { $cliToolchain = "all" }

    # Allow tests to verify parsing without triggering network/install.
    if ($DryRun) {
        Write-Host "TOOLCHAIN=$cliToolchain VERSION=$Version"
        return
    }

    # Resolve version.
    $resolvedVersion = if ($Version) { $Version } else { "latest" }
    $resolvedVersion = Resolve-Version -Requested $resolvedVersion
    if (-not $resolvedVersion) {
        exit 1
    }

    # Determine target directory.
    $effectiveTargetDir = if ($TargetDir) { $TargetDir } else { (Get-Location).Path }

    # Resolve toolchain.
    $toolchain = Select-Toolchain -TargetDir $effectiveTargetDir -CliToolchain $cliToolchain

    # Download and extract release to temp directory.
    $tmpDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    try {
        $ok = Invoke-DownloadRelease -ReleaseVersion $resolvedVersion -DestDir $tmpDir
        if (-not $ok) {
            exit 1
        }

        # Determine source root (may be prospect-<version>/ subdirectory).
        $sourceDir = Join-Path $tmpDir "prospect-$resolvedVersion"
        if (-not (Test-Path $sourceDir)) {
            $sourceDir = $tmpDir
        }

        $result = Install-Files -SourceDir $sourceDir -TargetDir $effectiveTargetDir `
            -InstallVersion $resolvedVersion -Toolchain $toolchain
        if (-not $result) {
            exit 1
        }
    }
    finally {
        if (Test-Path $tmpDir) {
            Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Entry point ────────────────────────────────────────────────────────────────
# Only run Main when executed directly (not dot-sourced).
# $MyInvocation.InvocationName check covers both `pwsh -File` and direct invocation.
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
