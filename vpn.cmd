@echo off
set CL=powershell.exe -windowStyle hidden -command
rem ��� �⫠��� ����� �᪮�����஢��� ᫥������ �����
rem set CL=powershell.exe -NoExit -command
set SC=D:\��筠�\0scripts\ps\Async\test-IP-Async-job8\test-ip-job-v8.ps1
set FC=-FileCFG D:\��筠�\0scripts\ps\Async\test-IP-Async-job8\vpn.cfg
set VER=-Version 1
rem ��� �⫠��� ����� �᪮�����஢��� ᫥������ �����. ��ᬮ���� ��ନ஢����� ��ப�
rem echo start %CL% "& {%SC% %TA% %TAS% %CP% %CB% %DS% %TO% %EMF% -MailTo %EMT% %smtpS% %IR% %NSEM% -Password %PWD% %LGN% %NUS% %D% %FL% %LFN% %LA%}" > c:\temp\test-ip\cmd.log

start %CL% "& {%SC% %FC% %VER%}"
