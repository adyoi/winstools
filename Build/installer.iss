; winstools - Inno Setup installer script
; Build:  ISCC.exe installer.iss /DAppVersion=1.0.0 /DAppShortVersion=1.0
; Output: Build\<AppShortVersion>\winstools-installer.exe

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef AppShortVersion
  #define AppShortVersion "1.0"
#endif

#define AppName "Windows Super Tools"
#define AppExeName "winstools.exe"
#define AppPublisher "PT (Perorangan) Adidaya Karya Utama"

[Setup]
AppId={{9F4C2A1E-5B7D-4E3A-9C2B-8A1D6F3E0C77}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\Winstools
DefaultGroupName=Winstools
OutputDir=..\Build\{#AppShortVersion}
OutputBaseFilename=winstools-installer
SetupIconFile=..\Icons\window.ico
UninstallDisplayIcon={app}\winstools.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "{#AppShortVersion}\winstools.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#AppShortVersion}\Modules\*"; DestDir: "{app}\Modules"; Flags: recursesubdirs createallsubdirs
Source: "{#AppShortVersion}\Tools\*"; DestDir: "{app}\Tools"; Flags: recursesubdirs createallsubdirs
Source: "{#AppShortVersion}\Icons\*"; DestDir: "{app}\Icons"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent
