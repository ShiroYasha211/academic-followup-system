#define MyAppName "Moeen Attendance Display"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Mohammed Alhemyari"
#define MyAppExeName "MoeenAttendanceDisplay.exe"
#define VcRedistExeName "vc_redist.x64.exe"
[Setup]
AppId={{212A5121-FDF5-4392-84C0-9EEFE324D348}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Moeen Attendance Display
DefaultGroupName=Moeen Attendance Display
DisableProgramGroupPage=yes
OutputDir=..\..\release
OutputBaseFilename=Moeen-Attendance-Display-Setup-v{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#MyAppExeName}
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName}
CloseApplications=yes
RestartIfNeededByRun=no
[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
[Tasks]
Name: "desktopicon"; Description: "إنشاء اختصار على سطح المكتب"; GroupDescription: "اختصارات إضافية:"
[Files]
Source: "prerequisites\{#VcRedistExeName}"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: VCRedistNeedsInstall
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{group}\Moeen Attendance Display"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\Moeen Attendance Display"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
[Code]
function VCRedistNeedsInstall: Boolean;
var
  Installed: Cardinal;
  Major: Cardinal;
  Minor: Cardinal;
begin
  Result := True;

  if not Is64BitInstallMode then
    Exit;

  if not RegQueryDWordValue(
    HKLM64,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    'Installed',
    Installed
  ) then
    Exit;

  if Installed <> 1 then
    Exit;

  if not RegQueryDWordValue(
    HKLM64,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    'Major',
    Major
  ) then
    Exit;

  if not RegQueryDWordValue(
    HKLM64,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    'Minor',
    Minor
  ) then
    Exit;

  Result := (Major < 14) or ((Major = 14) and (Minor < 20));
end;

[Run]
Filename: "{tmp}\{#VcRedistExeName}"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Microsoft Visual C++ Runtime..."; Flags: waituntilterminated; Check: VCRedistNeedsInstall
Filename: "{app}\{#MyAppExeName}"; Description: "تشغيل Moeen Attendance Display"; Flags: nowait postinstall skipifsilent
