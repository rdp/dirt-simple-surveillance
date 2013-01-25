#define AppVer "v0.0.11"

#define AppName "Dirt Simple Surveillance"
; AppId === AppName by default BTW

[Run]
; a checkbox run optional after install, disabled since it has a console...
; Filename: vendor/jruby-complete-1.7.0.jar; Description: Launch {#AppName} after finishing installation; WorkingDir: {app}; Parameters: -Ilib bin\startup.rb --background-start; Flags: nowait postinstall

[UninstallRun]

[Files]
Source: *; DestDir: {app}; Excludes: releases, dirt-simple-usb-surveillance\vendor\simple_gui_creator\spec; Flags: recursesubdirs
Source: README.TXT; DestDir: {app}; Flags: isreadme

[Setup]
AppName={#AppName}
AppVerName={#AppVer}
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
UninstallDisplayName={#AppName} uninstall
OutputBaseFilename=Setup {#AppName} {#AppVer}
OutputDir=releases

[Icons]
; extra space hopes to make it appear at the top...
Name: "{group}\Run {#AppName} "; Filename: javaw.exe; WorkingDir: {app}; Parameters: -splash:vendor/webcam-clipart-loading.png  -jar vendor/jruby-complete-1.7.0.jar -Ilib bin\startup.rb; IconFilename: {app}/vendor/webcam-clipart.ico
Name: {group}\advanced\Run surveillance start minimized; Filename: javaw.exe; WorkingDir: {app}; Parameters: -jar vendor/jruby-complete-1.7.0.jar -Ilib bin\startup.rb --background-start; IconFilename: {app}/vendor/webcam-clipart.ico
Name: {group}\advanced\Run surveillance with a debug window; Filename: {app}\generic_run_rb.bat; WorkingDir: {app}; Parameters: -Ilib  bin\startup.rb; Flags: runminimized; IconFilename: {app}/vendor/webcam-clipart.ico
Name: {group}\advanced\Readme; Filename: {app}\readme.txt
Name: {group}\advanced\ChangeLog; Filename: {app}\ChangeLog.txt
Name: {group}\advanced\Uninstall; Filename: {uninstallexe}
Name: {commondesktop}\{#AppName}; Filename: javaw.exe; WorkingDir: {app}; Parameters: -splash:vendor/webcam-clipart-loading.png -jar vendor/jruby-complete-1.7.0.jar -Ilib bin\startup.rb; IconFilename: {app}/vendor/webcam-clipart.ico

[Messages]
ConfirmUninstall=Are you sure you want to remove %1 (any recorded videos will still be left on the disk)?
FinishedLabel=Done installing [name].  Go start it from your start button -> programs menu, and add some cameras!
UninstalledAll=%1 was successfully removed from your computer. Recorded videos have been left on disk and will need to be deleted manually (if so desired).