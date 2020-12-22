echo off
echo "***********************************************"
echo "***********Введи имя папки с проектом**********"
echo "***********************************************"
set /p PROJ="ProjName: "

set /p "ch=путь до проекта "C:/Wincc_OA_Proj/%PROJ%/"? [y] " 
IF "%ch%" == "Y" ( goto confirm )
IF "%ch%" == "y" ( goto confirm )
IF "%ch%" == "Д" ( goto confirm )
IF "%ch%" == "д" ( goto confirm )
IF "%ch%" == ""  ( goto confirm )
goto end

:confirm
echo "Регистрация проекта в качестве службы запущена"
WCCILpmon -install -set C:/WinCC_OA_Proj/%PROJ%/config/config 1 -name SSPD-SRV-SVC
echo "Регистрация завершена, остановите проект и запустите его как службу (SSPD-SRV-SVC)"
echo "%userprofile%"
xcopy "links\" "%userprofile%\desktop\" /Y 
echo "Запуск проекта возможен только с ярлыков на рабочем столе"

set /p "ch=Перезагрузить сервер сейчас? [y] " 
IF "%ch%" == "Y" ( goto reboot )
IF "%ch%" == "y" ( goto reboot )
IF "%ch%" == "Д" ( goto reboot )
IF "%ch%" == "д" ( goto reboot )
IF "%ch%" == ""  ( goto reboot )
goto end


:reboot
shutdown /r /t 000 /f
goto end

:end
pause