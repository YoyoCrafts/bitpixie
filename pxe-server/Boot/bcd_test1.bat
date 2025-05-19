@echo off


bcdedit /export BCD_modded


bcdedit /store BCD_modded /set {default} winpe yes


setlocal
:PROMPT
SET /P AREYOUSURE=Do you want to move the file to the SMB server on 10.13.37.100 (Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END


move BCD_modded S:\BCD_TEST1
goto :EOF

:END

echo "BCD_modded file was not moved."

goto :EOF

endlocal

:EOF
pause
