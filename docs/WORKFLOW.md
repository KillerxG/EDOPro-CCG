# Development workflow

This repository is now the source of truth for the CCG Epsilon EDOPro mod.

## Folders

- `EDOPro-Source/`: C++ source for EDOProMod.exe and ocgmod.dll.
- `mod-files/`: Lua, CDB, and config files copied into the playable game folder.
- `installer/`: installer source files. Do not commit generated installer exe files.
- `tools/`: helper scripts for copying and building.

## Test game folder

The playable game folder remains:

```text
D:\Jogos\Yu-Gi-Oh!\ProjectIgnisMod
```

## Apply script/CDB/config changes to the game

Run from PowerShell:

```powershell
cd "D:\GitHub\Upload pro Git\EDOPro-CCG"
.\tools\Apply-ModFilesToGame.ps1
```

Then open `EDOProMod.exe` from the game folder and test.

## Pull manual game changes back into the repo

If a file was edited directly inside the game folder and should become part of the project:

```powershell
cd "D:\GitHub\Upload pro Git\EDOPro-CCG"
.\tools\Pull-CurrentGameModFiles.ps1
```

Review changes in GitHub Desktop before committing.

## Build modified core

```powershell
cd "D:\GitHub\Upload pro Git\EDOPro-CCG"
.\tools\Build-ModCore.ps1
```

The built DLL is copied to:

```text
D:\Jogos\Yu-Gi-Oh!\ProjectIgnisMod\expansions\ocgmod.dll
```

## Build modified exe

```powershell
cd "D:\GitHub\Upload pro Git\EDOPro-CCG"
.\tools\Build-ModExe.ps1
```

The built exe is copied to:

```text
D:\Jogos\Yu-Gi-Oh!\ProjectIgnisMod\EDOProMod.exe
```

## GitHub Desktop routine

1. Pull before starting.
2. Edit files in this repo.
3. Apply/build into the game folder.
4. Test in EDOProMod.
5. Commit if it works.
6. Push to GitHub.
