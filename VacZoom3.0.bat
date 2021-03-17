@echo off
setlocal

set version=2.1

Rem Checking for updates
echo Checking for updates...
set vpath=https://vacwear.com/VacZoom/version.txt
powershell wget %vpath% -OutFile VacZoomVersion.txt
set /p nversion=< VacZoomVersion.txt
del /F /Q VacZoomVersion.txt
if %version%==%nversion% (goto Current) else (goto Update)
pause

Rem Needs to be updated
:Update
echo You are not up to date! File will update automatically, but you need to restart VacZoom
pause
set upath=https://vacwear.com/VacZoom/VacZoom%nversion%.bat
powershell wget %upath% -OutFile VacZoom%nversion%.bat
del /F /Q VacZoom%version%.bat
goto :eos

Rem Current version is up to date
:Current
echo You are up to date!
echo -----
echo Welcome to VacZoom %version%

:Create
Rem Go to the id or link creation process
echo -----
echo You can either join by meeting id and passcode or Zoom link
echo It is preferable to use the meeting id because you do not need to use your browser
set /p temp="Do you use an id or link? "
if /i %temp%==id goto IdCreate
if /i %temp%==link goto LinkCreate

Rem If their choice is not recognized
echo Your choice is not recognized. Please try again.
pause
goto :Create

:IdCreate
Rem Input variables
echo -----
echo For the meeting id and passcode, do not add any spaces
set /p id="Enter meeting id: "
set /p passcode="Enter meeting password: "
echo -----
echo MON,TUE,WED,THU,FRI,SAT,SUN
set /p days="Enter the first three letters of the days you want to autojoin with commas (Ex: MON,WED,FRI): "
echo -----
echo The hours and minutes must include two digits and have a : between them
set /p ztime="Set the Zoom time in 24 hour format (Ex: 07:25 or 17:00): "
echo -----
echo We are going to set a date where you will stop automatically joining your classes
echo It should be in month/day/year format
set /p edate="Set the end date (Ex: 01/15/2021): "
echo -----

Rem Found variables
set argument=--url="zoommtg://zoom.us/join?action=join&confno=%id%&pwd=%passcode%"
set zoompath=%USERPROFILE%\AppData\Roaming\Zoom\bin\Zoom.exe

Rem Creating the task
schtasks /create /sc weekly /tn "VacZoom %id%" /tr %zoompath%" "%argument% /d %days% /st %ztime% /ed %edate% /it /z
Echo Thank you for using VacZoom!
pause
goto :eos

:LinkCreate
Rem Get user input for their preferred browser
echo -----
echo Currently, VacZoom only supports these browsers: Brave
echo Do not include file extentions. For example, use Brave instead of Brave.exe
set /p browser="What browser would you like to use? "
if /i %browser%==brave goto BrowserPath

Rem If their choice is not recognized
echo -----
echo Your choice is not recognized or the browser is currently unsupported. Please try again.
goto :LinkCreate

Rem Determining the browser pathway
:BrowserPath
if /i %browser%==brave set browserpath="%ProgramFiles%\BraveSoftware\Brave-Browser\Application\brave.exe"

Rem Input variables
echo -----
Echo Copy and paste your Zoom link here
set /p link="Enter Zoom link: "
echo -----
echo MON,TUE,WED,THU,FRI,SAT,SUN
set /p days="Enter the first three letters of the days you want to autojoin with commas (Ex: MON,WED,FRI): "
echo -----
echo The hours and minutes must include two digits and have a : between them
set /p ztime="Set the Zoom time in 24 hour format (Ex: 07:25 or 17:00): "
echo -----
echo We are going to set a date where you will stop automatically joining your classes
echo It should be in month/day/year format
set /p edate="Set the end date (Ex: 01/15/2021): "
echo -----

Rem Found variables
set taskscript="cmd /c start %link%"

Rem Creating the task THE ARGUEMENT IS NOT VALID NEEDS TO BE FIXED SOON
schtasks /create /sc weekly /tn "VacZoom %link%" /d %days% /st %ztime% /ed %edate% /it /z /F /tr %taskscript%
Echo Thank you for using VacZoom!
pause
goto :eos

Rem Just in case anything goes wrong
pause
goto :eof