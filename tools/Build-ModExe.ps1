param(
    [string]$GamePath = "D:\Jogos\Yu-Gi-Oh!\ProjectIgnisMod",
    [string]$MSBuild = "C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\Current\Bin\MSBuild.exe"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Solution = Join-Path $RepoRoot 'EDOPro-Source\build\ygo.sln'
$Output = Join-Path $RepoRoot 'EDOPro-Source\bin\release\ygoprodll.exe'
$Destination = Join-Path $GamePath 'EDOProMod.exe'

if (!(Test-Path -LiteralPath $Solution)) { throw "Missing solution: $Solution" }
if (!(Test-Path -LiteralPath $MSBuild)) { throw "Missing MSBuild: $MSBuild" }

& $MSBuild $Solution /t:ygoprodll /p:Configuration=Release /p:Platform=Win32 /p:PlatformToolset=v145 /p:WholeProgramOptimization=false /p:LinkTimeCodeGeneration=Default /m:1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Copy-Item -LiteralPath $Output -Destination $Destination -Force
Write-Host "Exe copied to: $Destination"
