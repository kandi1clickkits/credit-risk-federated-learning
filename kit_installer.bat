@echo off
setlocal ENABLEDELAYEDEXPANSION
CALL :start_spinner
ECHO======================================================================================
ECHO		Kandi kit installation process has begun
ECHO  ==============================================================
ECHO 	This kit installer works only on Windows OS
ECHO 	Based on your network speed, the installation may take a while
ECHO======================================================================================
SET KIT_NAME=credit-risk-federated-learning
SET WORKING_DIR=C:\kandikits\!KIT_NAME!\!KIT_NAME!
REM update below path if required
REM SET PY_VERSION=3.8.10
SET PY_VERSION=3.9.8
SET MAJOR_VERSION=%PY_VERSION:~0,1%
SET MINOR_VERSION=%PY_VERSION:~2,1%
SET PATCH_VERSION=%PY_VERSION:~4,2%
SET PY_MM_VERSION=%MAJOR_VERSION%.%MINOR_VERSION%
SET PY_LOCATION=C:\kandikits\python\%PY_VERSION%
SET PY_DOWNLOAD_URL=https://www.python.org/ftp/python/3.9.8/python-3.9.8-amd64.exe
REM SET PY_DOWNLOAD_URL=https://www.python.org/ftp/python/3.8.10/python-%PY_VERSION%-embed-amd64.zip
REM SET PY_DOWNLOAD_URL=https://www.python.org/ftp/python/3.6.4/python-3.6.4-amd64.exe

SET REPO_DOWNLOAD_URL=https://github.com/kandi1clickkits/credit-risk-federated-learning/releases/download/v1.0.0/credit-risk-federated-learning.zip
SET REPO_DEPENDENCIES_URL=https://github.com/kandi1clickkits/credit-risk-federated-learning/raw/main/requirements.txt
SET REPO_NAME=credit-risk-federated-learning.zip
SET EXTRACTED_REPO_DIR=credit-risk-federated-learning
SET NOTEBOOK_NAME=credit-risk-federated-learning.ipynb
SET MS_VC_REDIST_URL=https://aka.ms/vs/17/release/vs_BuildTools.exe
SET GET_PIP_LOCATION=https://bootstrap.pypa.io/get-pip.py
SET ERROR_MSG=ERROR:There was an error while installing the kit
SET LOG_REDIRECT_LOCATION=!WORKING_DIR!\log.txt 2>&1
IF EXIST "!WORKING_DIR!\log.txt" (
    DEL !WORKING_DIR!\log.txt
)
IF EXIST !WORKING_DIR!\ (
    CALL :LOG "!WORKING_DIR! already exists"
) ELSE (
    mkdir !WORKING_DIR!
)
REM CD /D !WORKING_DIR!
CD /D !WORKING_DIR!
SET STARTTIME=%TIME%
CALL :LOG "START TIME : %TIME%"
TITLE Installing %KIT_NAME% kit 5%% xxxxx_______________________________________________________________________________________________
CALL :Install_ms_vc_redist
IF ERRORLEVEL 1 (
	CALL :Show_Error_And_Exit
)
CALL :Main
CALL :exit_spinner
ECHO "%KIT_NAME% kit installed at location : !WORKING_DIR!"
SET ENDTIME=%TIME%
CALL :LOG "END TIME : %TIME%"
SET /P CONFIRM=Would you like to run the kit (Y/N)?
IF /I "%CONFIRM%" NEQ "Y" (
	ECHO To run the kit, follow further instructions of the kit in kandi
) ELSE (
	ECHO kit starting...
	TITLE %KIT_NAME% Kit
	ECHO TO QUIT PRESS CTRL+C
	python -m jupyter notebook "%EXTRACTED_REPO_DIR%\%NOTEBOOK_NAME%" >> !WORKING_DIR!\log.txt 2>&1
)
PAUSE
EXIT /B %ERRORLEVEL%

:Main
where /q python
IF ERRORLEVEL 1 (
	CALL :LOG "Python was not found in the PATH"
	CALL :Install_python_and_modules
	IF ERRORLEVEL 1 (
	   SET ERROR_MSG=ERROR: While installing python !PY_VERSION! in !PY_LOCATION!
		CALL :Show_Error_And_Exit
	) ELSE (
		CALL :Download_repo
		IF ERRORLEVEL 1 (
			SET ERROR_MSG=ERROR: While downloading repository
			CALL :Show_Error_And_Exit
		)
	) 
) ELSE (
	for /f %%i in ('python -c "import sys; print((str(sys.version_info[0]) + '.' + str(sys.version_info[1])))"') do set DETECTED_PYTHON_MM_VERSION=%%i
	CALL :LOG "The detected version of python is !DETECTED_PYTHON_MM_VERSION!"
	SET IS_PYTHON_EXISTS=false
	IF EXIST "!PY_LOCATION!\python.exe" (
		SET IS_PYTHON_EXISTS=true
		SET PATH=!PY_LOCATION!;!PATH!
	) ELSE (
		IF !DETECTED_PYTHON_MM_VERSION! NEQ !PY_MM_VERSION! (
			CALL :LOG "Python version !PY_MM_VERSION! not detected at system level"
			SET IS_PYTHON_EXISTS=false
		) ELSE (
			IF !DETECTED_PYTHON_MM_VERSION! EQU !PY_MM_VERSION! (
				CALL :LOG "Python version !PY_MM_VERSION! detected at system level"
				SET IS_PYTHON_EXISTS=true
			) ELSE (
				SET IS_PYTHON_EXISTS=false
			)
		)
	)
   
	IF !IS_PYTHON_EXISTS! NEQ true (
		CALL :LOG "python !PY_VERSION! will be installed since the required version of python does not exist"
		CALL :Install_python_and_modules
		IF ERRORLEVEL 1 (
		   SET ERROR_MSG=ERROR: While installing python !PY_VERSION! in !PY_LOCATION!
		   CALL :Show_Error_And_Exit
		) ELSE (
			CALL :Download_repo
			IF ERRORLEVEL 1 (
			   SET ERROR_MSG=ERROR: While downloading repository
			   CALL :Show_Error_And_Exit
		  )
		)
	) ELSE (
		   TITLE Installing %KIT_NAME% kit 40%% xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx____________________________________________________________
		   timeout 1  >nul
		   for /f %%A in ('copy /Z "%~dpf0" nul') do set "CR=%%A"
			<nul set/p"=->!CR!"
		   ECHO 2. A valid python is detected at system level hence skipping python installation
			CALL :LOG "A valid python is detected at system level and hence installing dependent modules ..."
			CALL :Install_dependencies
			IF ERRORLEVEL 1 (
			   SET ERROR_MSG=ERROR: While installing python !PY_VERSION! in !PY_LOCATION!
		      CALL :Show_Error_And_Exit
			) ELSE (
				CALL :Download_repo
				IF ERRORLEVEL 1 (
			       SET ERROR_MSG=ERROR: While downloading repository
			       CALL :Show_Error_And_Exit
		      )
			)
	)
)
EXIT /B 0

:Download_repo
IF EXIST !WORKING_DIR!\%EXTRACTED_REPO_DIR%\ (
    CALL :LOG "%REPO_NAME% already downloaded"
	 timeout 1  >nul
	 for /f %%A in ('copy /Z "%~dpf0" nul') do set "CR=%%A"
	 <nul set/p"=->!CR!"
	 ECHO 4. Repo already downloaded
	 TITLE Installing %KIT_NAME% kit 100%% xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
) ELSE (
    bitsadmin /transfer repo_download_job /download /priority foreground %REPO_DOWNLOAD_URL% "!WORKING_DIR!\%REPO_NAME%" >> !WORKING_DIR!\log.txt 2>&1
	 CALL :LOG "Repo downloaded successfully"
	 TITLE Installing %KIT_NAME% kit 80%% xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx____________________
    timeout 1  >nul
	for /f %%A in ('copy /Z "%~dpf0" nul') do set "CR=%%A"
	<nul set/p"=->!CR!"
	ECHO 4. Repo installed
    CALL :LOG "Extracting the repo ..."
    tar -xvf %REPO_NAME% >> !WORKING_DIR!\log.txt 2>&1
    TITLE Installing %KIT_NAME% kit 90%% xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx__________
    TITLE Installing %KIT_NAME% kit 100%% xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    timeout 1  >nul
	for /f %%A in ('copy /Z "%~dpf0" nul') do set "CR=%%A"
	<nul set/p"=->!CR!"
	ECHO 5. Repo extracted
)
EXIT /B 0	


:Install_python_and_modules
CALL :LOG "Downloading python %PY_VERSION% ... "
REM curl -o python-%PY_VERSION%-amd64.exe %PY_DOWNLOAD_URL%
REM bitsadmin /transfer python_download_job /download %PY_DOWNLOAD_URL% "%cd%\python-%PY_VERSION%-amd64.exe"
MKDIR "!WORKING_DIR!\%PY_VERSION%" >> !WORKING_DIR!\log.txt 2>&1
REM bitsadmin /transfer python_download_job /download %PY_DOWNLOAD_URL% "!WORKING_DIR!\%PY_VERSION%\python-%PY_VERSION%-embed-amd64.zip"
curl --output "!WORKING_DIR!\%PY_VERSION%\python-%PY_VERSION%-embed-amd64.zip" %PY_DOWNLOAD_URL% >> !WORKING_DIR!\log.txt 2>&1
IF ERRORLEVEL 1 (
    EXIT /B 1
)
CALL :LOG "Installing python %PY_VERSION% ..."
REM python-%PY_VERSION%-amd64.exe /quiet InstallAllUsers=0 PrependPath=0 Include_test=0 TargetDir=%PY_LOCATION%
CD "!WORKING_DIR!\%PY_VERSION%"
tar -xvf "python-%PY_VERSION%-embed-amd64.zip" >> !WORKING_DIR!\log.txt 2>&1
IF ERRORLEVEL 1 (
	SET ERROR_MSG=ERROR: While extracting python-%PY_VERSION%-embed-amd64.zip
	CALL :Show_Error_And_Exit
)
DEL "python-%PY_VERSION%-embed-amd64.zip" >> !WORKING_DIR!\log.txt 2>&1
CD "%cd%\.."
REM SET MAJOR_VERSION=%PY_VERSION:~0,1%
REM SET MINOR_VERSION=%PY_VERSION:~2,1%
REM SET PATCH_VERSION=%PY_VERSION:~4,2%
MOVE "!WORKING_DIR!\%PY_VERSION%\python%MAJOR_VERSION%%MINOR_VERSION%._pth" "!WORKING_DIR!\%PY_VERSION%\python%MAJOR_VERSION%%MINOR_VERSION%.pth" >> !WORKING_DIR!\log.txt 2>&1
mkdir "!WORKING_DIR!\%PY_VERSION%\DLLs" >> !WORKING_DIR!\log.txt 2>&1
mkdir "%PY_LOCATION%" >> !WORKING_DIR!\log.txt 2>&1
MOVE "!WORKING_DIR!\%PY_VERSION%\*.*" "%PY_LOCATION%" >> !WORKING_DIR!\log.txt 2>&1
curl -o !WORKING_DIR!\get-pip.py %GET_PIP_LOCATION% >> !WORKING_DIR!\log.txt 2>&1
%PY_LOCATION%/python !WORKING_DIR!\get-pip.py >> !WORKING_DIR!\log.txt 2>&1
IF ERRORLEVEL 1 (
   EXIT /B 1
) ELSE (
	SET PATH=!PY_LOCATION!;!PATH!
	CALL :LOG "Python installed in path : !PY_LOCATION!"
	CALL :LOG "Path after python installation : !PATH!"
	for /f %%i in ('python -c "import sys; print((str(sys.version_info[0]) + '.' + str(sys.version_info[1])))"') do CALL :LOG "Path after custom installation %%i"
	IF ERRORLEVEL 1 ( 
			SET ERROR_MSG=ERROR: There was an error while installing python!
			CALL :Show_Error_And_Exit
			EXIT /B 1
	) ELSE (
		TITLE Installing %KIT_NAME% kit 40%% xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx____________________________________________________________
		timeout 1  >nul
		for /f %%A in ('copy /Z "%~dpf0" nul') do set "CR=%%A"
		<nul set/p"=->!CR!"
		ECHO 2. python version !PY_VERSION! installed
		CALL :Install_dependencies
		IF ERRORLEVEL 1 (
			EXIT /B 1
		) ELSE (
			EXIT /B 0
		)
	)	
)

:Install_ms_vc_redist
IF EXIST "!WORKING_DIR!\vs_BuildTools.exe" (
    CALL :LOG "Microsoft Visual C++ Redistributable already downloaded"
) ELSE (
    CALL :LOG "Downloading Microsoft Visual C++ Redistributable ..." 
    bitsadmin /transfer vc_redist_download_job /download /priority foreground %MS_VC_REDIST_URL% "!WORKING_DIR!\vs_BuildTools.exe" >> !WORKING_DIR!\log.txt 2>&1
)
REM curl -o vs_BuildTools.exe %MS_VC_REDIST_URL%
REM bitsadmin /transfer vc_redist_download_job /download %MS_VC_REDIST_URL% "%cd%\vs_BuildTools.exe"
CALL :LOG "Installing Microsoft Visual C++ Redistributable ..."
!WORKING_DIR!\vs_buildtools.exe --quiet --norestart --add Microsoft.VisualStudio.Component.VC.CoreBuildTools --add Microsoft.VisualStudio.Component.VC.CoreIde --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.TestTools.BuildTools --add Microsoft.VisualStudio.Component.Windows10SDK.19041
IF ERRORLEVEL 1 (
		SET ERROR_MSG=ERROR: There was an error while installing Microsoft Visual C++ Redistributable
		CALL :Show_Error_And_Exit
		EXIT /B 1
) ELSE (
	CALL :LOG "Microsoft Visual C++ Redistributable has been installed"
	TITLE Installing %KIT_NAME% kit 10%% xxxxxxxxxx__________________________________________________________________________________________
	timeout 1  >nul
	for /f %%A in ('copy /Z "%~dpf0" nul') do set "CR=%%A"
	<nul set/p"=->!CR!"
	ECHO 1. Microsoft Visual C++ Redistributable installed
)
EXIT /B 0


:Install_dependencies
CALL :LOG "Installing dependent modules ..."
bitsadmin /transfer dependency_download_job /download /priority foreground %REPO_DEPENDENCIES_URL% "!WORKING_DIR!\requirements.txt" >> !WORKING_DIR!\log.txt 2>&1
CALL :LOG "!PATH!"
python -m pip install virtualenv >> !WORKING_DIR!\log.txt 2>&1
python -m virtualenv federated-kit-env >> !WORKING_DIR!\log.txt 2>&1
REM python -m venv kkit
pushd .
cd .\federated-kit-env\Scripts
CALL :LOG "%cd%"
CALL .\activate.bat
popd
CALL :LOG "%cd%"
python -m pip install --upgrade pip setuptools wheel >> !WORKING_DIR!\log.txt 2>&1
python -m pip install -r requirements.txt >> !WORKING_DIR!\log.txt 2>&1
TITLE Installing %KIT_NAME% kit 60%% xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx________________________________________
timeout 1  >nul
for /f %%A in ('copy /Z "%~dpf0" nul') do set "CR=%%A"
<nul set/p"=->!CR!"
ECHO 3. Dependencies installed
EXIT /B 0

:Show_Error_And_Exit
ECHO !ERROR_MSG!
CALL :exit_spinner
CALL :exit_spinner
CALL :LOG "!ERROR_MSG!"
ECHO Please look at the log at !WORKING_DIR!\log.txt for more details
PAUSE
ECHO Exiting..
EXIT

:LOG
ECHO %~1 >> !WORKING_DIR!\log.txt 2>&1

::spinner
exit /b
:start_spinner
if defined __spin__ goto spin
set "__spin__=1"
for %%i in (v2Forced vtEnabled cursorHide cursorShow colorYellow colorGreen colorRed colorReset) do set "%%i="

for /f "tokens=3" %%i in ('2^>nul reg query "HKCU\Console" /v "ForceV2"') do set /a "v2Forced=%%i"
if "!v2Forced!" neq "0" for /f "tokens=2 delims=[]" %%i in ('ver') do for /f "tokens=2-4 delims=. " %%j in ("%%i") do (
  if %%j gtr 10 (
    set "vtEnabled=1"
  ) else if %%j equ 10 (
    if %%k gtr 0 (set "vtEnabled=1") else if %%l geq 10586 set "vtEnabled=1"
  )
)
if defined vtEnabled (
  for /f %%i in ('echo prompt $e^|cmd') do set "esc=%%i"
  set "cursorHide=!esc![?25l" &set "cursorShow=!esc![?25h"&set "colorYellow=!esc![33m" &set "colorGreen=!esc![32m" &set "colorRed=!esc![31m" &set "colorReset=!esc![m"
)

for /f %%i in ('copy /z "%~f0" nul') do set "cr=%%i"
for /f %%i in ('echo prompt $h^|cmd') do set "bs=%%i"
>"%temp%\spinner.~tmp" type nul
start /b cmd /c ""%~fs0" spin"
exit /b

:exit_spinner
del "%temp%\spinner.~tmp"
set "__spin__="
>nul ping -n 1 localhost
echo(!cr!  - - -!colorGreen!        Completed        !colorYellow!- - -  !colorReset!!cursorShow!
echo(
exit /b

:spin
echo(!cursorHide!!colorYellow!
for /l %%i in () do for %%j in ("\ | / -" "| / - \" "/ - \ |" "- \ | /") do for /f "tokens=1-4" %%k in (%%j) do (
  <nul set /p "=!bs!!cr!  %%k "
  >nul ping -n 1 localhost
  if not exist "%temp%\spinner.~tmp" exit
)