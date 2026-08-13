param(
    [string]$GamePath = "D:\Jogos\Yu-Gi-Oh!\ProjectIgnisMod"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

function Copy-One($Source, $Destination) {
    if (!(Test-Path -LiteralPath $Source)) {
        Write-Warning "Missing: $Source"
        return
    }
    $dir = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "Copied: $Source -> $Destination"
}

function Copy-DirFiles($SourceDir, $DestinationDir) {
    if (!(Test-Path -LiteralPath $SourceDir)) {
        Write-Warning "Missing directory: $SourceDir"
        return
    }
    New-Item -ItemType Directory -Force -Path $DestinationDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $SourceDir '*') -Destination $DestinationDir -Recurse -Force
    Write-Host "Copied directory: $SourceDir -> $DestinationDir"
}

Copy-DirFiles (Join-Path $GamePath 'script\Custom') (Join-Path $RepoRoot 'mod-files\script\Custom')
Copy-One (Join-Path $GamePath 'repositories\ccg-brasil\script\c161000000.lua') (Join-Path $RepoRoot 'mod-files\script\ccg-brasil\c161000000.lua')
Copy-One (Join-Path $GamePath 'repositories\ccg-brasil\script\proc_divine_hierarchy_mod.lua') (Join-Path $RepoRoot 'mod-files\script\ccg-brasil\proc_divine_hierarchy_mod.lua')
Copy-One (Join-Path $GamePath 'expansions\Mod.cdb') (Join-Path $RepoRoot 'mod-files\expansions\Mod.cdb')
Copy-One (Join-Path $GamePath 'config\configs.json') (Join-Path $RepoRoot 'mod-files\config\configs.json')
Copy-One (Join-Path $GamePath 'config\user_configs.json') (Join-Path $RepoRoot 'mod-files\config\user_configs.json')

Write-Host "Done. Review changes in GitHub Desktop before committing."
