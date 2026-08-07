@IF "%__echo%" == "1" echo on
@SETLOCAL enableextensions

@SET MAVEN_BATCH_ECHO=off
@SET MAVEN_BATCH_PAUSE=off

@IF NOT "%MAVEN_BATCH_ECHO%" == "on"  echo off

@SET ERROR_CODE=0

@SET "MAVEN_PROJECTBASEDIR=%~dp0"
@IF "%MAVEN_PROJECTBASEDIR:~-1%"=="\" SET "MAVEN_PROJECTBASEDIR=%MAVEN_PROJECTBASEDIR:~0,-1%"

@SET "WRAPPER_JAR=%MAVEN_PROJECTBASEDIR%\.mvn\wrapper\maven-wrapper.jar"
@SET "WRAPPER_PROPERTIES=%MAVEN_PROJECTBASEDIR%\.mvn\wrapper\maven-wrapper.properties"

@IF EXIST "%WRAPPER_JAR%" goto run

@IF NOT EXIST "%MAVEN_PROJECTBASEDIR%\.mvn\wrapper" mkdir "%MAVEN_PROJECTBASEDIR%\.mvn\wrapper"

@powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $w = '%WRAPPER_JAR%'; (New-Object Net.WebClient).DownloadFile('https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.2.0/maven-wrapper-3.2.0.jar', $w)"

:run
@IF NOT DEFINED JAVA_HOME (
  @SET "JAVACMD=java"
) ELSE (
  @SET "JAVACMD=%JAVA_HOME%\bin\java.exe"
)

"%JAVACMD%" %MAVEN_OPTS% -classpath "%WRAPPER_JAR%" "-Dmaven.home=%MAVEN_PROJECTBASEDIR%" "-Dmaven.multiModuleProjectDirectory=%MAVEN_PROJECTBASEDIR%" org.apache.maven.wrapper.MavenWrapperMain %*

@IF %ERRORLEVEL% NEQ 0 SET ERROR_CODE=%ERRORLEVEL%

@exit /B %ERROR_CODE%
