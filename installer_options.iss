#define AppVer "0.0.7pre"

#define AppName "Dirt Simple USB Surveillance"
; AppId === AppName by default BTW

[Run]
; a checkbox run optional after install
Filename: vendor/jruby-complete-1.7.0.jar; Description: Launch {#AppName} after finishing installation; WorkingDir: {app}; Parameters: -Ilib bin\startup.rb --background-start; Flags: nowait postinstall

[UninstallRun]

[Files]
Source: *; DestDir: {app}; Excludes: releases; Flags: recursesubdirs
Source: README.TXT; DestDir: {app}; Flags: isreadme

[Setup]
AppName={#AppName}
AppVerName={#AppVer}
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
UninstallDisplayName={#AppName} uninstall
OutputBaseFilename=Setup {#AppName} v{#AppVer}
OutputDir=releases

[Icons]
Name: {group}\Run surveillance; Filename: javaw.exe; WorkingDir: {app}; Parameters: -jar vendor/jruby-complete-1.7.0.jar -Ilib bin\startup.rb; IconFilename: {app}/vendor/webcam-clipart.ico
Name: {group}\Run surveillance minimized; Filename: javaw.exe; WorkingDir: {app}; Parameters: -jar vendor/jruby-complete-1.7.0.jar -Ilib bin\startup.rb --background-start; IconFilename: {app}/vendor/webcam-clipart.ico
Name: {group}\Run surveillance with debug window; Filename: {app}\generic_run_rb.bat; WorkingDir: {app}; Parameters: -Ilib  bin\startup.rb; Flags: runminimized; IconFilename: {app}/vendor/webcam-clipart.ico
Name: {group}\Run surveillance; Filename: javaw.exe; WorkingDir: {app}; Parameters: -jar vendor/jruby-complete-1.7.0.jar -Ilib bin\startup.rb --background-start; IconFilename: {app}/vendor/webcam-clipart.ico
Name: {group}\Readme; Filename: {app}\README.TXT
Name: {group}\Uninstall {#AppName}; Filename: {uninstallexe}

[Messages]
ConfirmUninstall=Are you sure you want to remove %1 (any saved videos will still be left on the disk)?
