echo off
echo "***********************************************"
echo "***********����� ��� ����� � �஥�⮬**********"
echo "***********************************************"
set /p PROJ="ProjName: "

set /p "ch=���� �� �஥�� "C:/Wincc_OA_Proj/%PROJ%/"? [y] " 
IF "%ch%" == "Y" ( goto confirm )
IF "%ch%" == "y" ( goto confirm )
IF "%ch%" == "�" ( goto confirm )
IF "%ch%" == "�" ( goto confirm )
IF "%ch%" == ""  ( goto confirm )
goto end

:confirm
echo "��������� �஥�� � ����⢥ �㦡� ����饭�"
WCCILpmon -install -set C:/WinCC_OA_Proj/%PROJ%/config/config 1 -name SSPD-SRV-SVC
echo "��������� �����襭�, ��⠭���� �஥�� � ������� ��� ��� �㦡� (SSPD-SRV-SVC)"
echo "%userprofile%"
xcopy "links\" "%userprofile%\desktop\" /Y 
echo "����� �஥�� �������� ⮫쪮 � ��몮� �� ࠡ�祬 �⮫�"

set /p "ch=��१���㧨�� �ࢥ� ᥩ��? [y] " 
IF "%ch%" == "Y" ( goto reboot )
IF "%ch%" == "y" ( goto reboot )
IF "%ch%" == "�" ( goto reboot )
IF "%ch%" == "�" ( goto reboot )
IF "%ch%" == ""  ( goto reboot )
goto end


:reboot
shutdown /r /t 000 /f
goto end

:end
pause