@echo off

:: ������ʼ��׼��
cd /d "%~dp0"
cls

call :info ���Ժ�,��ʼ����...

set titl=��Ԩ����
title %titl%

set line=----------------------------------

:: ��ʼ����ɫ����
setlocal EnableDelayedExpansion
for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "DEL=%%a"

call :VersionReader
call :ConfigReader
call :DisplayConfig
set startup-parameter=%java-path% -Xmx%default-xmx%M -Xms%default-xms%M %extra-java% -jar %core% %extra-server%
pause >nul
goto exit










:: ��ȡ����˰汾��Ϣ
:VersionReader
if not exist version.properties (
    call :Error �汾�ļ���ʧ����ʹ��Ĭ�ϵĺ�������server.jar 
    set core=server.jar
    goto exit
)
call :PropertiesReader version.properties version
call :PropertiesReader version.properties core -disablewarn
call :PropertiesReader version.properties name
call :PropertiesReader version.properties git
if "%core%" equ "" call :Error �������Ʋ�����ʧ����ʹ��Ĭ�ϵĺ�������server.jar & set core=server.jar
goto exit







:: ����̨�������
:Info
echo [Info] %*
goto exit



:Warning
call :colortext 0e "[Warning] %~1" & echo.
goto exit



:Error
call :colortext 0c "[Error] %~1" & echo.
goto exit



:: �����ɫ����
:ColorText
<nul set /p ".=%DEL%" > "%~2"
findstr /v /a:%1 /R "^$" "%~2" nul
del "%~2" > nul 2>&1
goto exit



:: properties�ļ���ȡ
:PropertiesReader
if "%~3" equ "-keepspace" (set space=true) && if "%~4" equ "-keepspace" (set space=true)
if "%~3" equ "-disablewarn" (set warn=false) && if "%~4" equ "-disablewarn" set (warn=false)
if not exist %~1 ( if "%warn%" neq "false" call :Warning "δ��⵽�ļ� %~1 ��" ) & goto exit
for /f "tokens=1,* delims==" %%a in ('findstr "%~2=" "%~1"') do set tag=%%b
if "%tag%" equ "" ( if "%warn%" neq "false" call :Warning "�޷���ȡ�� %~1 �� %~2 ������" ) & goto exit
if "%space%" neq "true" set tag=%tag: =%
set %~2=%tag%
set tag=
goto exit



:: �����ļ���ȡ
:ConfigReader
call :Info ���ڳ�ʼ�������ļ�ϵͳ

:: ���ڰ汾�ľ������ļ�����ת��
if exist ConfigProgress.txt ren ConfigProgress.txt progress.properties
if exist config.txt ren config.txt config.properties

:: ���������ļ�
call :PropertiesReader progress.properties ConfigSet -disablewarn
if "%ConfigSet%" equ "true" goto :ConfigTranslator

:: ���Ĭ�������ļ�
if not exist launcher.properties goto :ConfigCreater

:: ��ȡ�����ļ�
call :Info ��ȡ�����ļ���
call :PropertiesReader launcher.properties port-titl
call :PropertiesReader launcher.properties auto-memory
call :PropertiesReader launcher.properties default-xmx
call :PropertiesReader launcher.properties default-xms
call :PropertiesReader launcher.properties auto-restart
call :PropertiesReader launcher.properties restart-wait
call :PropertiesReader launcher.properties extra-server -keepspace -disablewarn
call :PropertiesReader launcher.properties extra-java -keepspace -disablewarn
call :PropertiesReader launcher.properties java-path -keepspace -disablewarn
call :Info ��ȡ��ϣ�
goto exit



:: �����ļ�����
:ConfigCreater
call :info ������һ���µ������ļ�,��������Լ���
pause >nul
set port-titl=true 
set auto-memory=true 
set default-xmx=4096 
set default-xms=4096 
set auto-restart=true 
set restart-wait=10 
set extra-server=nogui 
set extra-java=--add-modules=jdk.incubator.vector 
.\Java\bin\java.exe -version >nul 2>&1
if %errorlevel% equ 0 ( set java-path=.\Java\bin\java.exe ) else ( set java-path=java )
call :SaveConfig
call :Info ������ϣ�
goto exit



:: �ɰ������ļ�ת��
:ConfigTranslator
if not exist config.properties call :Warning δ�ҵ���ȷ�ľ������ļ� && goto ConfigCreater
call :info ����ת���ɰ������ļ�
if exist launcher.properties call :Warning ��⵽launcher.properties�Ѵ��ڣ�������ԭ�����ļ�����������Լ��� && pause >nul

:: �������ڲ����ڿ���ǰ�ȴ�,������EarlyLunchWait
:: ServerGUI��ת��Ϊextra-serverֱ�����-nogui����
:: EarlyLunchWait,SysMem��LogAutoRemove������,��Ϊ������������ת��
:: ����ӳ���б�:
:: AutoMemSet -> auto-memory
:: UserRam -> default-xmx
:: MinMem -> default-xms
:: AutoRestart -> auto-restart
:: RestartWait -> restart-wait
:: ServerGUI -> extra-server
:: SysMem -> old.system-memory
:: LogAutoRemove -> old.auto-remove-log
:: EarlyLunchWait -> old.launch-wait

call :PropertiesReader config.properties AutoMemSet -disablewarn
call :PropertiesReader config.properties UserRam -disablewarn
call :PropertiesReader config.properties MinMem -disablewarn
call :PropertiesReader config.properties AutoRestart -disablewarn
call :PropertiesReader config.properties RestartWait -disablewarn
call :PropertiesReader config.properties ServerGUI -disablewarn
call :PropertiesReader config.properties SysMem -disablewarn
call :PropertiesReader config.properties LogAutoRemove -disablewarn
call :PropertiesReader config.properties EarlyLunchWait -disablewarn

set port-titl=true
set auto-memory=%AutoMemSet%
if "%UserRam%" equ "" set UserRam=4096
set default-xmx=%UserRam%
if "%MinMem%" equ "" set MinMem=128
set default-xms=%MinMem%
set auto-restart=%AutoRestart%
set restart-wait=%RestartWait%
if "%ServerGUI%" equ "false" set extra-server=nogui 
set extra-java=--add-modules=jdk.incubator.vector
.\Java\bin\java.exe -version >nul 2>&1
if %errorlevel% equ 0 ( set java-path=.\Java\bin\java.exe ) else ( set java-path=java )
set old.system-memory=%SysMem%
set old.auto-remove-log=%LogAutoRemove%
set old.launch-wait=%EarlyLunchWait%

call :SaveConfig true

del progress.properties /f/q
del config.properties /f/q

call :Info ת����ϣ�

goto exit



:: ���������ļ�
:SaveConfig
echo # ��Ԩ�������������������ļ� >launcher.properties
echo. >>launcher.properties
echo # �Ƿ��ڱ�����ʾ�������˿� >>launcher.properties
echo port-titl=%port-titl% >>launcher.properties
echo. >>launcher.properties
echo # �Ƿ��Զ������ڴ� >>launcher.properties
echo auto-memory=%auto-memory% >>launcher.properties
echo. >>launcher.properties
echo # ��С�ڴ������ڴ�,�翪���Զ������ڴ�,�����Ч >>launcher.properties
echo default-xmx=%default-xmx% >>launcher.properties
echo default-xms=%default-xms% >>launcher.properties
echo. >>launcher.properties
echo # �Ƿ��Զ����� >>launcher.properties
echo auto-restart=%auto-restart% >>launcher.properties
echo # �Զ�����ʱ�ĵȴ�ʱ�� >>launcher.properties
echo restart-wait=%restart-wait% >>launcher.properties
echo. >>launcher.properties
echo # ���������� >>launcher.properties
echo extra-server=%extra-server% >>launcher.properties
echo # JVM���� >>launcher.properties
echo extra-java=%extra-java% >>launcher.properties
echo # Java·�� >>launcher.properties
echo java-path=%java-path% >>launcher.properties
echo. >>launcher.properties
if "%~1" neq "true" goto exit
echo # �ɰ汾�����ļ��������� >>launcher.properties
echo old.system-memory=%old.system-memory% >> launcher.properties
echo old.auto-remove-log=%old.auto-remove-log% >> launcher.properties
echo old.launch-wait=%old.launch-wait% >> launcher.properties
goto exit

:DisplayConfig
call :Info %line%
call :Info �ڱ�����ʾ�˿�: %port-titl%
call :Info �Զ������ڴ�: %auto-memory%
call :Info ����ڴ�: %default-xmx%
call :Info ��С�ڴ�: %default-xms%
call :Info �Զ�����: %auto-restart%
call :Info �����ȴ�ʱ��: %restart-wait%
call :Info ����������: %extra-server%
call :Info JVM����: %extra-java%
call :Info Java·��: %java-path%
call :Info %line%

goto exit


:: �˳���ʶ,�벻Ҫ�ڴ��·���Ӵ���
:exit