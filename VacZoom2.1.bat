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

Rem Found variables
set argument=--url="zoommtg://zoom.us/join?action=join&confno=%id%&pwd=%passcode%"
set zoompath=%USERPROFILE%\AppData\Roaming\Zoom\bin\Zoom.exe

Rem Creating the task
schtasks /create /sc weekly /tn "VacZoom %id%" /tr %zoompath%" "%argument% /d %days% /st %ztime% /ed %edate% /it /z
Echo Thank you for using VacZoom
pause
goto :eos