@rem echo Loading... we have splash for this message instead

@setlocal
@rem disable any local rubyopt settings, just in case...
@set RUBYOPT=

@rem have 32 bit java available on 64 bit machines. Yikes java, yikes.
@set PATH=%WINDIR%\syswow64;%PATH%
@rem add in JAVA_HOME just for fun/in case
@set PATH=%PATH%;%JAVA_HOME%\bin
@call java -version > NUL 2>&1 || echo you need to install java JRE first please install it from java.com then run again && java -version && pause && GOTO INSTALL_JAVA

@rem success path
@java -splash:vendor/webcam-clipart.png -jar vendor/jruby-complete-1.7.0.jar %*

@GOTO DONE

:INSTALL_JAVA
start http://java.com

:DONE