; Can Meydani Windows kurulum betigi (Inno Setup 6).
; Derleme: ISCC.exe tools\installer\can-meydani.iss
#define AppVersion "0.6.1"
#define SrcDir "..\..\apps\client\build\windows\x64\runner\Release"

[Setup]
AppId={{49F75D9E-B19B-4FEB-871D-58BD5B052D81}
AppName=Can Meydanı
AppVersion={#AppVersion}
AppPublisher=canmeydani.com.tr
AppPublisherURL=https://canmeydani.com.tr/
AppSupportURL=https://canmeydani.com.tr/
DefaultDirName={autopf}\Can Meydani
DefaultGroupName=Can Meydanı
OutputDir=..\..\dist
OutputBaseFilename=CanMeydani-Kurulum-0.6.1
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
WizardStyle=modern
DisableProgramGroupPage=yes
UninstallDisplayName=Can Meydanı
VersionInfoDescription=Can Meydani kurulumu
VersionInfoProductName=Can Meydanı

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SrcDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Can Meydanı"; Filename: "{app}\can-meydani.exe"
Name: "{autodesktop}\Can Meydanı"; Filename: "{app}\can-meydani.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\can-meydani.exe"; Description: "{cm:LaunchProgram,Can Meydanı}"; Flags: nowait postinstall skipifsilent
