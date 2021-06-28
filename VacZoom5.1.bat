@echo off
setlocal

Rem Current version number
set version=5.1

Rem Changes the text colors for slightly better readability
color 07

Rem Deleting previous VacZoom file
set oversion=%~1
if not "%oversion%"=="" (del /F /Q VacZoomVersion%oversion%.bat)

Rem Checking if the user is online
Ping www.vacwear.com -n 1 -w 1000
cls
if errorlevel 1 (goto Offline) else (goto Online)

:Offline
echo You are not connected to the internet
echo VacZoom cannot check for updates
goto OfflineStart

:Online
echo You are connected to the internet

Rem Checking for updates
echo Checking for updates...
powershell wget https://vacwear.com/VacZoom/version.txt -OutFile VacZoomVersion.txt
set /p nversion=< VacZoomVersion.txt
del /F /Q VacZoomVersion.txt
if %version%==%nversion% (goto Current) else (goto Update)
pause

Rem Needs to be updated
:Update
echo You are not up to date! File will update automatically
powershell wget https://vacwear.com/VacZoom/VacZoom%nversion%.bat -OutFile VacZoom%nversion%.bat

Rem Call the new version, so you dont need to restart VacZoom
echo -----
call VacZoom%nversion%.bat %version%

Rem Current version is up to date
:Current
echo You are up to date!
:OfflineStart
echo -----
echo Welcome to VacZoom %version%

Rem Create a variable for the Zoom path
set zoompath=%USERPROFILE%\AppData\Roaming\Zoom\bin\Zoom.exe

Rem Determine if the user wants to create or delete a task
:Action
echo -----
set /p temp="Do you want to create a new automation or modify or delete an existing one? (Ex: create, modify, or delete): "
set temp=%temp: =%
if /i "%temp%"=="create" goto :Create
if /i "%temp%"=="modify" goto :Modify
if /i "%temp%"=="delete" goto :Delete

Rem If their choice is not recognized
echo -----
echo Your choice is not recognized. Please try again.
pause
goto :Action

:Create
Rem Input variables
echo -----
set /p id="Enter meeting id: "
set id=%id: =%
echo Passcode will not work if it is two words
set /p passcode="Enter meeting password: "
set passcode=%passcode: =%
echo -----
echo MON,TUE,WED,THU,FRI,SAT,SUN
set /p days="Enter the first three letters of the days you want to autojoin with commas (Ex: MON,WED,FRI): "
echo -----
echo The hours and minutes must include two digits and have a : between them
set /p ztime="Set the Zoom time in 24 hour format (Ex: 07:25 or 17:00): "
set ztime=%ztime: =%

Rem Determine if user wants to have an end date
:EndDate
echo -----
set /p temp="Do you want to set a date to stop autojoining your meetings? (Ex: yes or no): "
set temp=%temp: =%
if /i "%temp%"=="yes" goto CreateEndDate
if /i "%temp%"=="no" goto CreateContinuous

Rem If their choice is not recognized
echo -----
echo Your choice is not recognized. Please try again.
pause
goto :EndDate

Rem User wants an end date
:CreateEndDate
echo -----
echo We are going to set a date where you will stop automatically joining your meetings
echo It should be in month/day/year format
set /p edate="Set the end date (Ex: 01/15/2021): "
set edate=%edate: =%

Rem Created variable for the argument
set argument=--url="zoommtg://zoom.us/join?action=join&confno=%id%&pwd=%passcode%"

Rem Creating the task
schtasks /create /sc weekly /tn "VacZoom %id%" /tr %zoompath%" "%argument% /d %days% /st %ztime% /ed %edate% /it /z
echo Thank you for using VacZoom
pause
goto :eof

Rem User does not want an end date
:CreateContinuous
echo -----

Rem Created variable for the argument
set argument=--url="zoommtg://zoom.us/join?action=join&confno=%id%&pwd=%passcode%"

Rem Creating the task
schtasks /create /sc weekly /tn "VacZoom %id%" /tr %zoompath%" "%argument% /d %days% /st %ztime% /it
echo Thank you for using VacZoom
pause
goto :eof

:Modify
echo -----
Rem Displays all VacZoom tasks
echo Below is a list of all of your currently active VacZoom tasks:
for /f "tokens=1*" %%a in ('schtasks /query /fo list^|findstr /r "TaskName.*VacZoom"') do @echo %%~nxb

echo -----
Rem Input meeting id variable
set /p id="Enter meeting id: "
set id=%id: =%

Rem Determine how the user wants to modify their task
:ModifyAction
echo -----
set /p temp="Do you want to modify the passcode or the time? (Ex: passcode or time): "
set temp=%temp: =%
if /i "%temp%"=="passcode" goto ModifyPasscode
if /i "%temp%"=="time" goto ModifyTime

Rem If their choice is not recognized
echo -----
echo Your choice is not recognized. Please try again.
pause
goto :ModifyAction

Rem Modifying the passcode for the task
:ModifyPasscode
echo -----
echo Passcode will not work if it is two words
set /p passcode="Enter the new meeting password: "
set passcode=%passcode: =%

Rem Created variable for the argument
set argument=--url="zoommtg://zoom.us/join?action=join&confno=%id%&pwd=%passcode%"

Rem Changing the task
echo For security purposes, it will ask you for your user password for verification
echo DO NOT TYPE IN YOUR PASSWORD. Press Enter instead
schtasks /change /tn "VacZoom %id%" /tr %zoompath%" "%argument% /it
echo Thank you for using VacZoom
pause
goto :eof

Rem Modifying the time for the task
:ModifyTime
echo -----
set /p ztime="Set the new Zoom time in 24 hour format (Ex: 07:25 or 17:00): "
set ztime=%ztime: =%

Rem Changing the task
echo For security purposes, it will ask you for your user password for verification
echo DO NOT TYPE IN YOUR PASSWORD. Press Enter instead
schtasks /change /tn "VacZoom %id%" /st %ztime% /it
echo Thank you for using VacZoom
pause
goto :eof

:Delete
echo -----
Rem Displays all VacZoom tasks
echo Below is a list of all of your currently active VacZoom tasks:
for /f "tokens=1*" %%a in ('schtasks /query /fo list^|findstr /r "TaskName.*VacZoom"') do @echo %%~nxb

echo -----
Rem Input variables
set /p id="Enter meeting id: "
set id=%id: =%

Rem Deleting the task
schtasks /delete /tn "VacZoom %id%" /f
echo Thank you for using VacZoom
pause
goto :eof