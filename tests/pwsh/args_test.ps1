# PowerShell argument parsing tests — T019
# Covers FR-1.2, FR-1.4, FR-2.5

$ErrorActionPreference = "Stop"
. "$PSScriptRoot/helpers.ps1"

$InstallPs1 = Join-Path $PSScriptRoot "../../install.ps1" | Resolve-Path

function Test_Args_Help_Flag_Prints_Usage([string]$TestDir) {
    $output = & pwsh -NoProfile -File $InstallPs1 -Help 2>&1 | Out-String
    Assert-Contains $output "usage" "-Help should print usage"
}

function Test_Args_Claude_Flag_Accepted([string]$TestDir) {
    $output = & pwsh -NoProfile -File $InstallPs1 -Claude -DryRun 2>&1 | Out-String
    Assert-Contains $output "TOOLCHAIN=claude" "-Claude should set toolchain to claude"
}

function Test_Args_Copilot_Flag_Accepted([string]$TestDir) {
    $output = & pwsh -NoProfile -File $InstallPs1 -Copilot -DryRun 2>&1 | Out-String
    Assert-Contains $output "TOOLCHAIN=copilot" "-Copilot should set toolchain to copilot"
}

function Test_Args_All_Flag_Accepted([string]$TestDir) {
    $output = & pwsh -NoProfile -File $InstallPs1 -All -DryRun 2>&1 | Out-String
    Assert-Contains $output "TOOLCHAIN=all" "-All should set toolchain to all"
}

function Test_Args_Version_Accepted([string]$TestDir) {
    $output = & pwsh -NoProfile -File $InstallPs1 -Version "v1.0.0" -DryRun 2>&1 | Out-String
    Assert-Contains $output "VERSION=v1.0.0" "-Version should be passed through"
}

function Test_Args_Defaults_No_Args([string]$TestDir) {
    $output = & pwsh -NoProfile -File $InstallPs1 -DryRun 2>&1 | Out-String
    Assert-Contains $output "TOOLCHAIN=" "no flags = empty toolchain (defaults later)"
}

Invoke-Tests
