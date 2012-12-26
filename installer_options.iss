#define AppVer "0.0.5"

#define AppName "Dirt Simple USB Surveillance"
; AppId === AppName by default BTW

[Run]
; a checkbox run after install
Filename: {app}\generic_run_rb.bat; Description: Launch {#AppName} after finishing installation; WorkingDir: {app}; Parameters: -Ilib  bin\startup.rb; Flags: runminimized nowait postinstall

[UninstallRun]

[Files]
Source: *; DestDir: {app}; Excludes: releases; Flags: recursesubdirs

[Setup]
AppName={#AppName}
AppVerName={#AppVer}
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
UninstallDisplayName={#AppName} uninstall
OutputBaseFilename=Setup {#AppName} v{#AppVer}
OutputDir=releases

[Icons]
Name: {group}\Run surveillance; Filename: {app}\generic_run_rb.bat; WorkingDir: {app}; Parameters: -Ilib  bin\startup.rb; Flags: runminimized
Name: {group}\Start surveillance without console window; Filename: javaw.exe; WorkingDir: {app}; Parameters: -jar vendor/jruby-complete-1.7.0.jar -Ilib bin\startup.rb --background-start
Name: {group}\Readme; Filename: {app}\README.TXT
; Flags: isreadme once it's prettier :)
Name: {group}\Uninstall {#AppName}; Filename: {uninstallexe}

[Messages]
ConfirmUninstall=Are you sure you want to remove %1 (saved videos will be left on the disk)?
