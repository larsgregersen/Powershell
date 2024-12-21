<#
.SYNOPSIS
    Get a list of program that should be upgraded using winget
.DESCRIPTION
    Calls "winget upgrade" and return a list of programs that have a 
    version number 0.1 larger than the currently installed version
.OUTPUTS
    A list of programs as customobjects. The keys are Name, ID, Installed, Version
.EXAMPLE
    ./get-wingetupgrades.ps1
    The script doesn't take any arguments
.EXAMPLE
    .\get-wingetupgrades.ps1 | where Installed -gt 10
    Filter the output. Only show entries that has a version number larger than 10
.EXAMPLE
    .\get-wingetupgrades.ps1 | select ID, Installed | Format-Table -AutoSize    
.NOTES
    Version 1.1: 2024-12-12
.LINK
    https://learn.microsoft.com/en-us/windows/package-manager/winget/
#>

# Support for -Debug and -Verbose
[CmdletBinding()]
param(

)

Set-StrictMode -Version 3

# Is winget installed?
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "Winget is not installed"
    exit 1
}

# Run the winget upgrade command and capture its output
Write-Verbose "Getting list of programs"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$c = winget upgrade
Write-Verbose "Comparing versions..."

# Split the output into an array where each element is a line of output
$lines = $c -split "`r`n" | Where-Object { $_ -ne "" }

$a = @()

$headeridx = -1
for ($i = 0; $i -lt [math]::min(10,$lines.Count); $i++) {
    if ($lines[$i] -match "Available") {
        $headeridx = $i
        break
    }
}
if ($headeridx -eq -1) {
    write-error "Could not find the header"
    exit 1
}

$ididx = $lines[$headeridx].IndexOf("Id")
$versionidx = $lines[$headeridx].IndexOf("Version")
$availableidx = $lines[$headeridx].IndexOf("Available")
$sourceidx = $lines[$headeridx].IndexOf("Source")
if ($ididx -eq -1) {
    write-error "Could not find the Id column"
    exit 2
}

$flag = $false
foreach ($line in $lines) {
    if ($line -match "----") {
        $flag = $true
        continue
    }
    if ($flag -eq $false) {
        continue
    }
    if ($line.Length -lt 100) {
        continue
    }
    if ($line -match "package\(s\) have version numbers that cannot be determined") {
        continue
    }
    
    Write-Debug $line
    $name = $line.Substring(0, $ididx-1).Trim()
    $id = $line.Substring($ididx, $versionidx-$ididx-1).Trim()            
    $v1 = $line.Substring($versionidx, $availableidx-$versionidx-1).Trim()
    $v2 = $line.Substring($availableidx, $sourceidx-$availableidx-1).Trim()

    if ($v1.Length -gt 3) {
        if ($v1.StartsWith("< ")) {
            $v1 = $v1.Substring(2);
        }
        $v1 = $v1 -replace " \((\d+)\)", '.$1'
        $v2 = $v2 -replace " \((\d+)\)", '.$1'
        $v1v = New-Object -TypeName System.Version -ArgumentList $v1
        $v2v = New-Object -TypeName System.Version -ArgumentList $v2

        if ($v2v.Major -gt $v1v.Major -or $v2v.Minor -ge $v1v.Minor + 1) {
            $obj = [PSCustomObject]@{
                Name     = $name
                ID       = $id
                Installed = $v1
                Version = $v2
            }
            $a += $obj
        }
    }
}

if ($a.Count -eq 0) {
    Write-Verbose "There are no major updates"
}

return $a
