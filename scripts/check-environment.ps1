
# JwLibraryForLinux
# Windows development environment validation
# Compatible with Windows PowerShell 5.1+

$ErrorActionPreference = "Continue"

$script:Passed = 0
$script:Warnings = 0
$script:Failed = 0

function Write-Check {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Details = ""
    )

    switch ($Status) {
        "OK" {
            $script:Passed++
            $color = "Green"
            $symbol = "[OK]"
        }
        "WARN" {
            $script:Warnings++
            $color = "Yellow"
            $symbol = "[WARN]"
        }
        "FAIL" {
            $script:Failed++
            $color = "Red"
            $symbol = "[FAIL]"
        }
    }

    Write-Host ("{0,-8} {1}" -f $symbol, $Name) -ForegroundColor $color

    if ($Details) {
        Write-Host ("         {0}" -f $Details) -ForegroundColor Gray
    }
}

function Get-ToolVersion {
    param(
        [string]$Command,
        [string[]]$Arguments = @("--version")
    )

    try {
        $result = & $Command @Arguments 2>&1 |
            Select-Object -First 1

        return "$result".Trim()
    }
    catch {
        return $null
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " JwLibraryForLinux - Environment Check" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --------------------------------------------
# Operating system
# --------------------------------------------

$os = Get-CimInstance Win32_OperatingSystem
$architecture = $env:PROCESSOR_ARCHITECTURE

if ($os.Caption -match "Windows") {
    Write-Check "Operating System" "OK" "$($os.Caption)"
}
else {
    Write-Check "Operating System" "FAIL" "Windows was not detected."
}

if ($architecture -eq "AMD64") {
    Write-Check "Architecture" "OK" "x64"
}
else {
    Write-Check "Architecture" "WARN" "$architecture detected. x64 is recommended."
}

# --------------------------------------------
# Git
# --------------------------------------------

$git = Get-ToolVersion "git"

if ($git) {
    Write-Check "Git" "OK" $git
}
else {
    Write-Check "Git" "FAIL" "Install Git for Windows."
}

# --------------------------------------------
# CMake
# --------------------------------------------

$cmake = Get-ToolVersion "cmake"

if ($cmake) {
    Write-Check "CMake" "OK" $cmake
}
else {
    Write-Check "CMake" "FAIL" "Install CMake."
}

# --------------------------------------------
# Ninja
# --------------------------------------------

$ninja = Get-ToolVersion "ninja"

if ($ninja) {
    Write-Check "Ninja" "OK" $ninja
}
else {
    Write-Check "Ninja" "FAIL" "Install Ninja."
}

# --------------------------------------------
# C++ compilers
# --------------------------------------------

$msvc = Get-Command "cl.exe" -ErrorAction SilentlyContinue
$gcc = Get-Command "g++.exe" -ErrorAction SilentlyContinue
$clang = Get-Command "clang++.exe" -ErrorAction SilentlyContinue

$compilerFound = $false

if ($msvc) {
    $version = Get-ToolVersion "cl.exe" @()

    Write-Check "MSVC" "OK" "Compiler available in current terminal."
    $compilerFound = $true
}
else {
    # Check whether Visual Studio Build Tools are installed.
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

    if (Test-Path $vswhere) {
        $vsInstallations = & $vswhere -products "*" -property installationPath

        if ($vsInstallations) {
            Write-Check "MSVC" "WARN" "Visual Studio detected, but cl.exe is not available in this terminal."
        }
        else {
            Write-Check "MSVC" "WARN" "Visual Studio installation not detected."
        }
    }
    else {
        Write-Check "MSVC" "WARN" "MSVC Build Tools not detected."
    }
}

if ($gcc) {
    $version = Get-ToolVersion "g++.exe"

    Write-Check "GCC" "OK" $version
    $compilerFound = $true
}
else {
    Write-Check "GCC" "WARN" "g++.exe not found."
}

if ($clang) {
    $version = Get-ToolVersion "clang++.exe"

    Write-Check "Clang" "OK" $version
    $compilerFound = $true
}
else {
    Write-Check "Clang" "WARN" "clang++.exe not found."
}

if (-not $compilerFound) {
    Write-Check "C++ Compiler" "FAIL" "No supported C++ compiler found."
}
else {
    Write-Check "C++ Compiler" "OK" "At least one compiler is available."
}

# --------------------------------------------
# Optional tools
# --------------------------------------------

$python = Get-ToolVersion "python" @("--version")

if ($python) {
    Write-Check "Python" "OK" $python
}
else {
    Write-Check "Python" "WARN" "Python not found. Some build dependencies may require it."
}

# --------------------------------------------
# Summary
# --------------------------------------------

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Validation Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Write-Host "Passed:   $script:Passed" -ForegroundColor Green
Write-Host "Warnings: $script:Warnings" -ForegroundColor Yellow
Write-Host "Failed:   $script:Failed" -ForegroundColor Red

Write-Host ""

if ($script:Failed -gt 0) {
    Write-Host "Environment is NOT ready." -ForegroundColor Red
    exit 1
}

if (-not $msvc) {
    Write-Host "Environment has a compiler, but MSVC is recommended for our Windows build." -ForegroundColor Yellow
    Write-Host "Use Developer PowerShell for Visual Studio 2022 when available." -ForegroundColor Yellow
}
else {
    Write-Host "Environment is ready for the next configuration step." -ForegroundColor Green
}

Write-Host ""
exit 0
