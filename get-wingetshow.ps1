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
    [string]$argname
)
$argname = "pptservice"

Set-StrictMode -Version 3

# Is winget installed?
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "Winget is not installed"
    exit 1
}

Write-Verbose "Getting list of programs that match '$argname'"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$list = winget search $argname
if ($list -match "No package found") {
    write-error "No package matching $argname was found"
    exit 2
} 
if ($list.Count -gt 1) {
    Write-Verbose "More than one match for '$argname'"
    $nameidx = $list[4].IndexOf("Name")
    $ididx = $list[4].IndexOf("Id")
    $versionidx = $list[4].IndexOf("Version")
    $matchidx = $list[4].IndexOf("Match")
    $sourceidx = $list[4].IndexOf("Source")
    $a = @()
    $found = ""
    for ($i = 6; $i -lt $list.Count; $i++) {
        if ($sourceidx -gt $list[$i].Length) {
            Write-Verbose "Problematic line: "
            Write-Verbose $list[$i]
            continue
        }
        elseif ($matchidx -eq -1) {
            $name = $list[$i].Substring($nameidx, $ididx - $nameidx - 1)
            $chinesecharcount = ($name -replace '[^\p{IsCJKUnifiedIdeographs}]', '').Length
            if ($chinesecharcount -gt 0) {
                Write-Verbose $list[$i]
                Write-Verbose $chinesecharcount
                $id = $list[$i].Substring($ididx-$chinesecharcount, $versionidx - $ididx - $chinesecharcount - 1)
                $Version = $list[$i].Substring($versionidx-$chinesecharcount, $sourceidx - $versionidx - $chinesecharcount- 1)
                $Match = ""
                $Source = $list[$i].Substring($sourceidx-$chinesecharcount)    
            }
            else {
                $id = $list[$i].Substring($ididx, $versionidx - $ididx - 1)
                $Version = $list[$i].Substring($versionidx, $sourceidx - $versionidx - 1)
                $Match = ""
                $Source = $list[$i].Substring($sourceidx)    
            }
        }
        else {
            $name = $list[$i].Substring($nameidx, $ididx - $nameidx - 1)
            $id = $list[$i].Substring($ididx, $versionidx - $ididx - 1)
            $Version = $list[$i].Substring($versionidx, $matchidx - $versionidx - 1)
            $Match = $list[$i].Substring($matchidx, $sourceidx - $matchidx - 1)
            $Source = $list[$i].Substring($sourceidx)
        }

        if ($id -eq $argname) {
            Write-Verbose "'$argname' is a perfect id match for '$name'"
            $found = $id
            break
        }

        $obj = [PSCustomObject]@{
            Name    = $name
            ID      = $id
            Version = $version
            Match   = $Match
            Source  = $Source
        }
        $a += $obj
    }
    if (-not $found) {
        return $a
    }
}

Write-Verbose "Getting content using winget for {$argname}"
$content = winget show $argname

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
