#define SourceDir "D:\Jogos\Yu-Gi-Oh!\InstallerStage\Yu-Gi-Oh! CCG Epsilon"
#define OutputDir "D:\Jogos\Yu-Gi-Oh!"

[Setup]
AppId={{E4F5046C-11D0-4B9E-8B32-CC6E2F35E001}
AppName=Yu-Gi-Oh! CCG Epsilon
AppVersion=0.1.0
AppPublisher=CCG Epsilon
DefaultDirName={localappdata}\Programs\Yu-Gi-Oh! CCG Epsilon
DefaultGroupName=Yu-Gi-Oh! CCG Epsilon
DisableDirPage=no
DisableProgramGroupPage=yes
UsePreviousAppDir=no
PrivilegesRequired=lowest
ArchitecturesAllowed=x86 x64
ArchitecturesInstallIn64BitMode=
OutputDir={#OutputDir}
OutputBaseFilename=YuGiOhCCGEpsilon_Setup_Inno
SetupIconFile=D:\GitHub\RPG-YGO-Epsilon\Arquivos de Programação\edopro-mod-installer\EDOProMod.ico
UninstallDisplayIcon={app}\EDOProMod.exe
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes
InternalCompressLevel=ultra64
DiskSpanning=no
DisableWelcomePage=no
CloseApplications=no
RestartApplications=no

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Yu-Gi-Oh! CCG Epsilon"; Filename: "{app}\EDOProMod.exe"; WorkingDir: "{app}"; IconFilename: "{app}\EDOProMod.exe"
Name: "{group}\Uninstall Yu-Gi-Oh! CCG Epsilon"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Yu-Gi-Oh! CCG Epsilon"; Filename: "{app}\EDOProMod.exe"; WorkingDir: "{app}"; IconFilename: "{app}\EDOProMod.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\EDOProMod.exe"; Description: "{cm:LaunchProgram,Yu-Gi-Oh! CCG Epsilon}"; Flags: nowait postinstall skipifsilent
