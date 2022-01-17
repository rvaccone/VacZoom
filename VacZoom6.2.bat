@echo off
setlocal

Rem Current version number
set version=6.2

Rem Changes the text colors for slightly better readability
color 07

Rem Deleting previous VacZoom file
set oversion=%~1
if not "%oversion%"=="" (del /F /Q VacZoomVersion%oversion%.bat)

Rem Checking if the user is online
Ping www.vacwear.com -n 1 -w 1000
cls
if errorlevel 1 (goto :Offline) else (goto :Online)

:Offline
echo You are not connected to the internet
echo VacZoom cannot check for updates
goto :OfflineStart

:Online
echo You are connected to the internet

Rem Checking for updates
echo Checking for updates...
powershell wget https://vacwear.com/VacZoom/version.txt -OutFile VacZoomVersion.txt
set /p nversion=< VacZoomVersion.txt
del /F /Q VacZoomVersion.txt
if %version%==%nversion% (goto :Current) else (goto :Update)
pause

Rem Needs to be updated
:Update
echo You are not up to date! File will update automatically
powershell wget https://vacwear.com/VacZoom/VacZoom%nversion%.bat -OutFile VacZoom%nversion%.bat

Rem Call the new version, so you dont need to restart VacZoom
cls
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
set "temp=%temp:~,1%"
if /i "%temp%"=="c" goto :Create
if /i "%temp%"=="m" goto :Modify
if /i "%temp%"=="d" goto :Delete

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
echo -----
echo Passcode will not work if it is two words
set /p passcode="Enter meeting password: "
set passcode=%passcode: =%
echo -----
echo MON,TUE,WED,THU,FRI,SAT,SUN
set /p days="Enter the first three letters of the days you want to autojoin with commas (Ex: MON,WED,FRI): "
echo -----
echo The hours and minutes must include two digits and have a : between them
set /p ztime="Set the Zoom meeting time (Ex: 7:25am or 5:00pm): "
set ztime=%ztime: =%

Rem Correct time if the user uses only one digit for hours or minutes
set "hours=%ztime:~,2%"
set "minutes=%ztime:~-4,-2%"
if not x%hours::=%==x%hours% set hours=%hours:~,1%
if not x%minutes::=%==x%minutes% set minutes=0%minutes:~-1%
set /a UnadjustedHours=((%hours%-1)%%12)+1
set /a UnadjustedMinutes=(%minutes%)%%60

Rem Modify the time for special hour cases
if not x%hours:12=%==x%hours% (if not x%ztime:am=%==x%ztime% (set hours=00))
if not x%hours:12=%==x%hours% (if not x%ztime:pm=%==x%ztime% (set hours=12))
if not x%hours:12=%==x%hours% (goto :HourSpecialCases)

Rem Modify to 24 hour format if there is a pm
if not x%ztime:pm=%==x%ztime% set /a hours=(%hours%+12)%%24
if %hours% leq 9 (set hours=0%hours:~-1%)
:HourSpecialCases

Rem Correct time if the user adds too many minutes
set /a minutes=(%minutes%)%%60
if %minutes% leq 9 (set minutes=0%minutes:~-1%)

Rem Finalizing the automation time
set ztime=%hours%:%minutes%

Rem Determine if user wants to have an end date
:EndDate
echo -----
set /p temp="Do you want to set a date to stop autojoining your meetings? (Ex: yes or no): "
set temp=%temp: =%
set "temp=%temp:~,1%"
if /i "%temp%"=="y" goto :CreateEndDate
if /i "%temp%"=="n" goto :CreateContinuous

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
schtasks /create /sc weekly /tn "VacZoom %id%" /tr %zoompath%" "%argument% /d %days% /st %ztime% /ed %edate% /it /z || goto :FailedRun

:AutoLeaveAction
Rem Determine if user wants to automatically leave their meeting
echo -----
echo Auto leaving your meeting will terminate any active Zoom meeting
set /p temp="Do you want to automatically leave your meeting? (Ex: yes or no): "
set temp=%temp: =%
set "temp=%temp:~,1%"
if /i "%temp%"=="y" goto :CreateLeave
if /i "%temp%"=="n" goto :End

Rem If their choice is not recognized
echo -----
echo Your choice is not recognized. Please try again.
pause
goto :AutoLeaveAction

Rem User does not want an end date
:CreateContinuous
echo -----

Rem Created variable for the argument
set argument=--url="zoommtg://zoom.us/join?action=join&confno=%id%&pwd=%passcode%"

Rem Creating the task
schtasks /create /sc weekly /tn "VacZoom %id%" /tr %zoompath%" "%argument% /d %days% /st %ztime% /it || goto :FailedRun

Rem Determine if user wants to automatically leave their meeting
goto :AutoLeaveAction

:CreateLeave
Rem Getting the minutes and hours from the designed time
echo -----
set /a "hours=%UnadjustedHours%"
set /a "minutes=%UnadjustedMinutes%"

Rem Input time information
set /p MeetingLength="How long is your meeting in minutes (Ex: 60): "

Rem Calculating the new time
set /a MeetingLength=%MeetingLength: =%
set /a TotalHours=%MeetingLength%/60
set /a TotalMinutes=%MeetingLength%-((%MeetingLength%/60)*60)
set /a NewMinutes=%minutes%+%TotalMinutes%
if %NewMinutes% gtr 60 (goto :NextHour) else (goto :WithinHour)

Rem If the combined minutes exceed an hour
:NextHour
set /a NewMinutes=%NewMinutes%-60
set /a TotalHours=%TotalHours%+1

Rem Minutes are less than an hour
:WithinHour
set /a NewHours=(%hours%+%TotalHours%)%%24

Rem Checking if the minutes are less than one digit
if %NewMinutes% gtr 9 (goto :MinutesTwoDigit)
set NewMinutes=0%NewMinutes%
:MinutesTwoDigit

Rem Checking if the hours are less than one digit
if %NewHours% gtr 9 (goto :HoursTwoDigit)
set NewHours=0%NewHours%
:HoursTwoDigit

Rem Setting the new time
set NewTime=%NewHours%:%NewMinutes%

Rem Creating the leave task
set LeaveCommand="taskkill /f /im Zoom.exe"
schtasks /create /sc weekly /tn "VacLeave %id%" /tr %LeaveCommand% /d %days% /st %NewTime% /it || goto :FailedRun

Rem Going to the end of the file
goto :End

:Modify
echo -----
Rem Displays all VacZoom tasks
echo Below is a list of all of your currently active VacZoom tasks:
for /f "tokens=1*" %%a in ('schtasks /query /fo list^|findstr /r "TaskName.*VacZoom"') do @echo %%~nxb

Rem Checking if empty
set query=""
for /f "tokens=1*" %%a in ('schtasks /query /fo list^|findstr /r "TaskName.*VacZoom"') do set query="%query%+%%~nxb"
if %query%=="" (
    echo -----
    echo No Active Tasks
    echo Ending program...
    echo -----
    goto :End)

echo -----
Rem Input meeting id variable
set /p id="Enter meeting id: "
set id=%id: =%

Rem Determine how the user wants to modify their task
:ModifyAction
echo -----
set /p temp="Do you want to modify the passcode or the time? (Ex: passcode or time): "
set temp=%temp: =%
set "temp=%temp:~,1%"
if /i "%temp%"=="p" goto :ModifyPasscode
if /i "%temp%"=="t" goto :ModifyTime

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
echo -----
echo For security purposes, it will ask you for your user password for verification
echo No password is required. Press Enter instead
schtasks /change /tn "VacZoom %id%" /tr %zoompath%" "%argument% /it || goto :FailedRun

Rem Going to the end of the file
goto :End

Rem Modifying the time for the task
:ModifyTime
echo -----
echo The hours and minutes must include two digits and have a : between them
set /p ztime="Set the Zoom meeting time (Ex: 7:25am or 5:00pm): "
set ztime=%ztime: =%

Rem Correct time if the user uses only one digit for hours or minutes
set "hours=%ztime:~,2%"
set "minutes=%ztime:~-4,-2%"
if not x%hours::=%==x%hours% set hours=%hours:~,1%
if not x%minutes::=%==x%minutes% set minutes=0%minutes:~-1%

Rem Modify the time for special hour cases
if not x%hours:12=%==x%hours% (if not x%ztime:am=%==x%ztime% (set hours=00))
if not x%hours:12=%==x%hours% (if not x%ztime:pm=%==x%ztime% (set hours=12))
if not x%hours:12=%==x%hours% (goto :HourSpecialCases)

Rem Modify to 24 hour format if there is a pm
if not x%ztime:pm=%==x%ztime% set /a hours=(%hours%+12)%%24
if %hours% leq 9 (set hours=0%hours:~-1%)
:HourSpecialCases

Rem Correct time if the user adds too many minutes
set /a minutes=(%minutes%)%%60
if %minutes% leq 9 (set minutes=0%minutes:~-1%)

Rem Finalizing the automation time
set ztime=%hours%:%minutes%

Rem Changing the task
echo -----
echo For security purposes, it will ask you for your user password for verification
echo No password is required. Press Enter instead
schtasks /change /tn "VacZoom %id%" /st %ztime% /it || goto :FailedRun

Rem Going to the end of the file
goto :End

:Delete
echo -----
Rem Displays all VacZoom tasks
echo Below is a list of all of your currently active VacZoom tasks:
for /f "tokens=1*" %%a in ('schtasks /query /fo list^|findstr /r "TaskName.*VacZoom"') do @echo %%~nxb

Rem Checking if empty
set query=""
for /f "tokens=1*" %%a in ('schtasks /query /fo list^|findstr /r "TaskName.*VacZoom"') do set query="%query%+%%~nxb"
if %query%=="" (
    echo -----
    echo No Active Tasks
    echo Ending program...
    echo -----
    goto :End)

echo -----
Rem Input variables
set /p id="Enter meeting id: "
set id=%id: =%

Rem Deleting the task
schtasks /delete /tn "VacZoom %id%" /f || goto :FailedRun
schtasks /query /TN "VacLeave %id%" >NUL 2>&1 || goto :End
schtasks /delete /tn "VacLeave %id%" /f

Rem Going to the end of the file
goto :End

Rem Something failed
:FailedRun
echo -----
echo Something went wrong! Restarting...
timeout 1 >nul
pause
cls
call VacZoom%version%.bat

Rem End of the file
:End
echo -----
echo Thank you for using VacZoom %version%
timeout 1 >nul
pause
goto :eof