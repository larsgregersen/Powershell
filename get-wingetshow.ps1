<#
Use the Microsoft.WinGet.Client PowerShell module:

This module provides cmdlets to interact with Winget. You can install and use it as follows:
  Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery -Force
  Import-Module Microsoft.WinGet.Client
  Get-Command -Module Microsoft.WinGet.Client
  Get-WinGetPackage # Lists installed packages
  Update-WinGetPackage
  Get-WinGetVersion
  Install-WinGetPackage
  Find-WinGetPackage

  Get-InstalledModule Microsoft.WinGet.Client

https://www.powershellgallery.com/packages/Microsoft.WinGet.Client

https://powershellisfun.com/2024/11/28/using-the-powershell-winget-module/

https://github.com/mgajda83/PSWinGet/blob/main/Find-WinGetPackage.ps1
#>

# Support for -Debug and -Verbose
[CmdletBinding()]
param(
    [string]$argname,
    [switch]$releasenotes = $false
)
#$argname = 'dngrep'

Set-StrictMode -Version 3

function read-showcontent($lines) {
    Write-Verbose "Extracting data"
    Write-Verbose $lines.Count

    $properties = [ordered]@{}
    $currentProperty = $null

    foreach ($line in $lines) {
        if ($line -match "Release Date: (.*)") {
            $properties['Release Date'] = $matches[1]
        }
        
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
    return $customObject
}


# Is winget installed?
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "Winget is not installed"
    exit 1
}

Write-Verbose "Getting list of programs that match '$argname'"
#[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$list = Find-WinGetPackage $argname

if ($null -eq $list) {
    Write-Error "Package '$argname' not found"
    exit 2    
}

if ($list -isnot [array]) {
    # Exactly one match
    Write-Verbose "One packages found"
    Write-Verbose "Getting content using winget for $($list.id)"
    $content = winget show $list.id
    write-verbose $content.GetType().FullName
    # Useful fields: Version, Publisher, Publisher Url, Author, Description, Release Notes Url
    $data = read-showcontent($content)
    if ($releasenotes) {
        $data | format-list -Property Publisher, homepage, Version, 'Release Date', Description, 'Release Notes Url', 'release notes'
    }
    else {
        $data | format-list -Property Publisher, homepage, Version, 'Release Date', Description
    }
}
else {
    # Multiple packages found
    Write-Verbose "Multiple packages found"
    $list | ft -wrap -AutoSize
    $installedpackage = Get-WinGetPackage $argname
    if ($null -ne $installedpackage) {
        write-output "Installed package: $($installedpackage.id) ($($installedpackage.InstalledVersion))"
    }
}
