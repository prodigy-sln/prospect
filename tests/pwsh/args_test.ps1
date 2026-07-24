# PowerShell argument parsing tests — T019
# Covers FR-1.2, FR-1.4

$ErrorActionPreference = "Stop"
. "$PSScriptRoot/helpers.ps1"

$InstallPs1 = Join-Path $PSScriptRoot "../../install.ps1" | Resolve-Path

function Test_Args_Help_Flag_Prints_Usage([string]$TestDir) {
    $output = & pwsh -NoProfile -File $InstallPs1 -Help 2>&1 | Out-String
    Assert-Contains $output "usage" "-Help should print usage"
}

function Test_Args_Version_Accepted([string]$TestDir) {
    $output = & pwsh -NoProfile -File $InstallPs1 -Version "v1.0.0" -DryRun 2>&1 | Out-String
    Assert-Contains $output "VERSION=v1.0.0" "-Version should be passed through"
}

function Test_Args_Defaults_No_Args([string]$TestDir) {
    $output = & pwsh -NoProfile -File $InstallPs1 -DryRun 2>&1 | Out-String
    Assert-Contains $output "VERSION=" "no -Version = empty version (defaults to latest later)"
}

# The removed toolchain switches must no longer bind. PowerShell rejects an
# unknown parameter with a non-zero exit and a parameter-binding error.
function Test_Args_Removed_Toolchain_Switch_Rejected([string]$TestDir) {
    $output = & pwsh -NoProfile -File $InstallPs1 -Claude -DryRun 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        throw "FAIL: -Claude should no longer be a valid switch (exit was 0)"
    }
}

Invoke-Tests
