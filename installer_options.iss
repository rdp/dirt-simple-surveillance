#define AppVer "0.0.1"

#define AppName "Dirt Simple USB Surveillance"
; AppId === AppName by default BTW

[Run]

[UninstallRun]

; TODO delete files?

[Files]
Source: *; DestDir: {app}; Flags: recursesubdirs

[Setup]
AppName={#AppName}
AppVerName={#AppVer}
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
UninstallDisplayName={#AppName} uninstall
OutputBaseFilename=Setup {#AppName} v{#AppVer}
OutputDir=releases

[Icons]
Name: {group}\Start surveillance; Filename: {app}\generic_run_rb.bat; WorkingDir: {app}; Parameters: -Ilib  bin\startup.rb; Flags: runminimized
Name: {group}\Readme; Filename: {app}\README.TXT
Name: {group}\Uninstall {#AppName}; Filename: {uninstallexe}
