# Build dist/mod_AC_<version>.zip from the current tree.
# Version is read from scripts/!mods_preload/mod_AC.nut (AC.Version SemVer string).
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force | Out-Null

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$Entry = Join-Path $Root "scripts\!mods_preload\mod_AC.nut"
if (-not (Test-Path $Entry)) {
    throw "Entry not found: $Entry"
}

$Text = Get-Content -LiteralPath $Entry -Raw -Encoding UTF8
if ($Text -notmatch 'Version\s*=\s*"([^"]+)"') {
    throw "Could not parse Version from $Entry"
}
$Version = $Matches[1]
$ZipName = "mod_AC_$Version.zip"
$DistDir = Join-Path $Root "dist"
$ZipPath = Join-Path $DistDir $ZipName

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

# Remove previous build of this version and the legacy unversioned name.
@(
    $ZipPath,
    (Join-Path $DistDir "mod_AC.zip")
) | ForEach-Object {
    if (Test-Path -LiteralPath $_) {
        Remove-Item -LiteralPath $_ -Force
    }
}

$Paths = @("scripts", "gfx", "ui", "mod_AC") | ForEach-Object { Join-Path $Root $_ }
foreach ($p in $Paths) {
    if (-not (Test-Path -LiteralPath $p)) {
        throw "Missing package path: $p"
    }
}

Compress-Archive -Path $Paths -DestinationPath $ZipPath -Force

$Item = Get-Item -LiteralPath $ZipPath
Write-Host "Built $($Item.FullName) ($($Item.Length) bytes)"
Write-Output $Item.FullName
