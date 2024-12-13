<#
Found Just [Casey.Just]
Version: 1.37.0
Publisher: Casey Rodarmor
Publisher Url: https://github.com/casey
Publisher Support Url: https://github.com/casey/just/issues
Author: Casey Rodarmor
Description: just is a handy way to save and run project-specific commands. Commands, called recipes, are stored in a file called justfile with syntax inspired by make
Homepage: https://github.com/casey/just
License: CC0-1.0
License Url: https://github.com/casey/just/blob/HEAD/LICENSE
Release Notes:
  Added
  - Add style() function (#2462 by casey)
  - Terminal escape sequence constants (#2461 by casey)
  - Add && and || operators (#2444 by casey)
  Changed
  - Make recipe doc attribute override comment (#2470 by casey)
  - Don't export constants (#2449 by casey)
  - Allow duplicate imports (#2437 by casey)
  - Publish single SHA256SUM file with releases (#2417 by casey)
  - Mark recipes with private attribute as private in JSON dump (#2415 by casey)
  - Forbid invalid attributes on assignments (#2412 by casey)
  Misc
  - Update softprops/action-gh-release (#2471 by app/dependabot)
  - Add -g to rust-just install instructions (#2459 by gnpaone)
  - Change doc backtick color to cyan (#2469 by casey)
  - Note that set shell is not used for [script] recipes (#2468 by iloveitaly)
  - Replace derivative with derive-where (#2465 by laniakea64)
  - Highlight backticks in docs when listing recipes (#2423 by neunenak)
  - Update setup-just version in README (#2456 by Julian)
  - Fix shell function example in readme (#2454 by casey)
  - Update softprops/action-gh-release (#2450 by app/dependabot)
  - Use justfile instead of mf on invalid examples in readme (#2447 by casey)
  - Add advice on printing complex strings (#2446 by casey)
  - Document using functions in variable assignments (#2431 by offby1)
  - Use prettier string comparison in tests (#2435 by neunenak)
  - Note shell(...) as an alternative to backticks (#2430 by offby1)
  - Update nix package links (#2441 by yunusey)
  - Update README.中文.md (#2424 by Jannchie)
  - Add Recipe::subsequents (#2428 by casey)
  - Add subsequents to grammar (#2427 by casey)
  - Document checking releases hashes  (#2418 by casey)
  - Show how to access positional arguments with powershell (#2405 by casey)
  - Use -CommandWithArgs instead of -cwa (#2404 by casey)
  - Document -cwa flag for PowerShell positional arguments (#2403 by casey)
  - Use unwrap_or when creating relative path in loader (#2400 by casey)
Release Notes Url: https://github.com/casey/just/releases/tag/1.37.0
Installer:
  Installer Type: portable (zip)
  Installer Url: https://github.com/casey/just/releases/download/1.37.0/just-1.37.0-x86_64-pc-windows-msvc.zip
  Installer SHA256: fc62b5dc04e103de15e04caeeb0398d286129353ff24302dd5e4da1fbd7badac
  Release Date: 2024-11-20
  Offline Distribution Supported: true
#>

<#
Use the Microsoft.WinGet.Client PowerShell module:
This module provides cmdlets to interact with Winget. You can install and use it as follows:
powershell
  Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery -Force
  Import-Module Microsoft.WinGet.Client
  Get-WinGetPackage

https://powershellisfun.com/2024/11/28/using-the-powershell-winget-module/

https://github.com/mgajda83/PSWinGet/blob/main/Find-WinGetPackage.ps1
#>

# Support for -Debug and -Verbose
[CmdletBinding()]
param(
    [string]$name
)

Set-StrictMode -Version 3

# Is winget installed?
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "Winget is not installed"
    exit 1
}

$name = "dngrep"
Write-Verbose "Getting content using winget"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$content = winget show $name
#$content = Get-Content -Path "show_just.txt" -Raw

if ($content -match "No package found") {
    Write-Error "No package found"
    exit 2
}
if ($content -match "Multiple packages found") {
    Write-Error "Multiple packages found"
    exit 3
}

Write-Verbose "Extracting data"
$lines = $content -split "`n"

$properties = [ordered]@{}
$currentProperty = $null

foreach ($line in $lines) {
    if ($line -match "^(\w[^:]+):(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $currentProperty = $key
        if ($value) {
            $properties[$key] = $value
        }
    }
    elseif ($line.Trim() -and $currentProperty) {
        if ($properties[$currentProperty]) {
            $properties[$currentProperty] += "`n" + $line.Trim()
        }
        else {
            $properties[$currentProperty] = $line.Trim()
        }
    }
}

$customObject = [PSCustomObject]$properties

$customObject
