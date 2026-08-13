param(
    [string]$GamePath = "D:\Jogos\Yu-Gi-Oh!\ProjectIgnisMod",
    [string]$MSBuild = "C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\Current\Bin\MSBuild.exe"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Project = Join-Path $RepoRoot 'EDOPro-Source\build\ocgcoreshared.vcxproj'
$Output = Join-Path $RepoRoot 'EDOPro-Source\bin\release\ocgcore.dll'
$Destination = Join-Path $GamePath 'expansions\ocgmod.dll'

if (!(Test-Path -LiteralPath $Project)) { throw "Missing project: $Project" }
if (!(Test-Path -LiteralPath $MSBuild)) { throw "Missing MSBuild: $MSBuild" }

& $MSBuild $Project /t:Rebuild /p:Configuration=Release /p:Platform=Win32 /p:PlatformToolset=v145 /p:WholeProgramOptimization=false /p:LinkTimeCodeGeneration=Default /m:1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Copy-Item -LiteralPath $Output -Destination $Destination -Force
Write-Host "Core copied to: $Destination"
