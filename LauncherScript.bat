@echo off
chcp 963
cd /d "%~dp0"
cls

setlocal EnableDelayedExpansion

call :info 请稍后,初始化中...
set line=----------------------------------
set titl=任渊生存
title %titl% 初始化中...

:: 初始化彩色字体
for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "DEL=%%a"

call :VersionReader
call :ConfigReader
call :DisplayConfig
call :EulaChecker
call :PortChecker

set /a times=0
if "%port-titl%" equ "true" set titl-port=端口: %server-port%



:Loop

call :RefreshMemory
call :RefreshTitle
call :RefreshFlags

cls

%java-path:/=\% -Xmx%xmx%M -Xms%xms%M %flags% %extra-java% -jar %core% %extra-server%

echo.
call :Info %line%
call :Info 服务端已经关闭

if "%auto-restart%" neq "true" (
    call :Info 将在3秒后关闭窗口
    ping -n 4 -w 500 127.0.0.1 >nul 
    goto exit
)

for /l %%a in (%restart-wait%,-1,1) do (
    call :Info 服务端将在%%a秒后重启
    ping -n 2 -w 500 127.0.0.1 >nul
)

call :Info 服务端重启中
set /a times+=1

call :Info %line%

goto Loop












:: 读取服务端版本信息
:VersionReader
if not exist version.properties (
    call :Error 版本文件丢失，将使用默认的核心名称server.jar 
    set core=server.jar
    goto exit
)
call :PropertiesReader version.properties version
call :PropertiesReader version.properties core -disablewarn
call :PropertiesReader version.properties name
call :PropertiesReader version.properties git
if "%core%" equ "" call :Error 核心名称参数丢失，将使用默认的核心名称server.jar & set core=server.jar
call :Info %line%
call :Info 任渊生存服务端 %version% [git-%git%]
call :Info %line%
goto exit



:: 控制台输出方法
:Info
echo [Info] %*
goto exit



:Warn
call :colortext 0e "[Warn] %~1" & echo.
goto exit



:Error
call :colortext 0c "[Error] %~1" & echo.
goto exit



:: 输出彩色字体
:ColorText
<nul set /p ".=%DEL%" > "%~2"
findstr /v /a:%1 /R "^$" "%~2" nul
del "%~2" > nul 2>&1
goto exit



:: properties文件读取
:PropertiesReader
if "%~3" equ "-keepspace" (set space=true) & if "%~4" equ "-keepspace" (set space=true)
if "%~3" equ "-disablewarn" (set warn=false) & if "%~4" equ "-disablewarn" set (warn=false)
if not exist %~1 ( if "%warn%" neq "false" call :Warn "未检测到文件 %~1 ！" ) & goto exit
for /f "tokens=1,* delims==" %%a in ('findstr "%~2=" "%~1"') do set tag=%%b
if "%tag%" equ "" ( if "%warn%" neq "false" call :Warn "无法获取到 %~1 的 %~2 参数！" ) & goto exit
if "%space%" neq "true" set tag=%tag: =%
set %~2=%tag%
:: 释放变量
set tag=
set warn=
set space=
goto exit



:: 配置文件读取
:ConfigReader
call :Info 正在初始化配置文件系统

:: 早期版本的旧配置文件名称转换
if exist ConfigProgress.txt ren ConfigProgress.txt progress.properties
if exist config.txt ren config.txt config.properties

:: 检测旧配置文件
call :PropertiesReader progress.properties ConfigSet -disablewarn
if "%ConfigSet%" equ "true" goto :ConfigTranslator

:: 检测默认配置文件
if not exist launcher.properties call :ConfigCreater

:: 读取配置文件
call :Info 读取配置文件中
call :PropertiesReader launcher.properties port-titl
call :PropertiesReader launcher.properties etil-flags
call :PropertiesReader launcher.properties auto-memory
call :PropertiesReader launcher.properties default-xmx
call :PropertiesReader launcher.properties default-xms
call :PropertiesReader launcher.properties auto-restart
call :PropertiesReader launcher.properties restart-wait
call :PropertiesReader launcher.properties extra-server -keepspace -disablewarn
call :PropertiesReader launcher.properties extra-java -keepspace -disablewarn
call :PropertiesReader launcher.properties java-path -keepspace -disablewarn
call :Info 读取完毕！
goto exit



:: 配置文件创建
:ConfigCreater
call :info 将创建一个新的配置文件,按任意键以继续
pause >nul
set port-titl=true
set etil-flags=true
set auto-memory=true 
set default-xmx=4096 
set default-xms=4096 
set auto-restart=true 
set restart-wait=10 
set extra-server=nogui 
.\Java\bin\java -version >nul 2>&1
if %errorlevel% equ 0 ( set java-path=./Java/bin/java ) else ( set java-path=java )
call :SaveConfig
call :Info 创建完毕！
goto exit



:: 旧版配置文件转换
:ConfigTranslator
if not exist config.properties call :Warn 未找到正确的旧配置文件 & goto ConfigCreater
call :info 正在转换旧版配置文件
if exist launcher.properties call :Warn 检测到launcher.properties已存在，将覆盖原配置文件，按任意键以继续 & pause >nul

:: 由于现在不会在开服前等待,将忽略EarlyLunchWait
:: ServerGUI将转换为extra-server直接添加-nogui参数
:: EarlyLunchWait,SysMem和LogAutoRemove被废弃,但为保留兼容仍做转换
:: 配置映射列表:
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
set etil-flags=true
set auto-memory=%AutoMemSet%
if "%UserRam%" equ "" set UserRam=4096
set default-xmx=%UserRam%
if "%MinMem%" equ "" set MinMem=128
set default-xms=%MinMem%
set auto-restart=%AutoRestart%
set restart-wait=%RestartWait%
if "%ServerGUI%" equ "false" set extra-server=nogui 
.\Java\bin\java -version >nul 2>&1
if %errorlevel% equ 0 ( set java-path=./Java/bin/java ) else ( set java-path=java )
set old.system-memory=%SysMem%
set old.auto-remove-log=%LogAutoRemove%
set old.launch-wait=%EarlyLunchWait%

call :SaveConfig true

del progress.properties /f/q
del config.properties /f/q

call :Info 转换完毕！

goto exit



:: 保存配置文件
:SaveConfig
echo # 任渊生存服务端启动器配置文件 >launcher.properties
echo. >>launcher.properties
echo # 是否在标题显示服务器端口 >>launcher.properties
echo port-titl=%port-titl% >>launcher.properties
echo. >>launcher.properties
echo # 是否启用etil-flags >>launcher.properties
echo # etil-flags基于Aikar-flags,可以小幅度提升性能 >>launcher.properties
echo etil-flags=%etil-flags% >>launcher.properties
echo. >>launcher.properties
echo # 是否自动设置内存 >>launcher.properties
echo auto-memory=%auto-memory% >>launcher.properties
echo. >>launcher.properties
echo # 最小内存和最大内存,如开启自动设置内存,此项不生效 >>launcher.properties
echo default-xmx=%default-xmx% >>launcher.properties
echo default-xms=%default-xms% >>launcher.properties
echo. >>launcher.properties
echo # 是否自动重启 >>launcher.properties
echo auto-restart=%auto-restart% >>launcher.properties
echo # 自动重启时的等待时间 >>launcher.properties
echo restart-wait=%restart-wait% >>launcher.properties
echo. >>launcher.properties
echo # 服务器参数 >>launcher.properties
echo extra-server=%extra-server% >>launcher.properties
echo # JVM参数 >>launcher.properties
echo extra-java=%extra-java% >>launcher.properties
echo # Java路径 >>launcher.properties
echo java-path=%java-path% >>launcher.properties
echo. >>launcher.properties
if "%~1" neq "true" goto exit
echo # 旧版本配置文件废弃参数 >>launcher.properties
echo old.system-memory=%old.system-memory% >> launcher.properties
echo old.auto-remove-log=%old.auto-remove-log% >> launcher.properties
echo old.launch-wait=%old.launch-wait% >> launcher.properties
goto exit



:DisplayConfig
call :Info %line%
call :Info 在标题显示端口: %port-titl%
call :Info 启用etil-flags: %etil-flags%
call :Info 自动分配内存: %auto-memory%
call :Info 最大内存: %default-xmx%
call :Info 最小内存: %default-xms%
call :Info 自动重启: %auto-restart%
call :Info 重启等待时间: %restart-wait%
call :Info 服务器参数: %extra-server%
call :Info JVM参数: %extra-java%
call :Info Java路径: %java-path%
call :Info %line%
goto exit



:: Eula检查
:EulaChecker
call :PropertiesReader eula.txt eula -disablewarn
if "%eula%" equ "true" goto exit

call :Warn "在服务端正式运行前，你还要同意Minecraft EULA"
call :Info 查看EULA请前往 https://account.mojang.com/documents/minecraft_eula
call :Info 在此处按任意键表示同意Minecraft EULA并启动服务端

pause >nul
echo eula=true>eula.txt
call :Info 你同意了Minecraft EULA,服务端即将启动
call :Info %line%
ping -n 2 -w 500 127.0.0.1 >nul

goto exit


:: 端口检查
:PortChecker
call :PropertiesReader server.properties server-port -disablewarn
if "%server-port%" equ "" (
    set port-titl=false
    goto exit
)

:: 查找占用端口的程序
set /a times=0 
for /f "tokens=1,2,5" %%i in (' netstat -ano ^| findstr "%server-port%" ') do (
    if "%%i" equ "TCP" for /f %%a in (' echo %%j ^| findstr "%server-port%" ') do if "%%k" neq "0" ( 
        if "!times!" equ "0" (
            call :Warn 服务器端口可能被占用，将会导致服务器无法正常开启！
            call :Info 以下是占用端口的进程PID和对应端口IP:
        )
        call :Info 进程PID: %%k ,占用端口IP: %%a
        set /a times+=1
    )
)
if "%times%" neq "0" (
    call :Info 将在5秒后继续启动服务器
    call :Info %line% 
    ping -n 6 -w 500 127.0.0.1 >nul 
)
set times=
goto exit




:: 刷新标题
:RefreshTitle
if "%auto-restart%" equ "true" (
    title %titl% %name% 重启次数: %times% %titl-port%
) else (
    title %titl% %name% %titl-port%
)
goto exit




:: 刷新内存分配
:RefreshMemory
if "%auto-memory%" neq "true" (
    set xmx=%default-xmx%
    set xms=%default-xms%
    goto exit
)

for /f "delims=" %%a in ('wmic os get TotalVisibleMemorySize /value^|find "="') do set %%a
set /a t1=%TotalVisibleMemorySize%,t2=1024
set /a ram=%t1%/%t2%
for /f "delims=" %%b in ('wmic os get FreePhysicalMemory /value^|find "="') do set %%b
set /a t3=%FreePhysicalMemory%
set /a freeram=%t3%/%t2%
call :Info 系统最大内存为：%ram% MB，剩余可用内存为：%freeram% MB

set /a xmx=%freeram%-728
if %xmx% lss 1024 (
    call :Warn 剩余可用内存可能不足以开启服务端或者开启后卡顿
    set xmx=1024
) else if %xmx% gtr 20480 set xmx=20480
set xms=%xmx%
call :Info 本次将分配 %xmx% MB内存
call :Info %line%
ping -n 2 -w 500 127.0.0.1 >nul 

goto exit


:: 刷新etil-flags
:RefreshFlags
if "%etil-flags%" equ "false" goto exit

if %xmx% lss 12288 (
    set flags=-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:UseAVX=3 -XX:+UseStringDeduplication -XX:+UseFastUnorderedTimeStamps -XX:+UseAES -XX:+UseAESIntrinsics -XX:UseSSE=4 -XX:+UseFMA -XX:AllocatePrefetchStyle=1 -XX:+UseLoopPredicate -XX:+RangeCheckElimination -XX:+EliminateLocks -XX:+DoEscapeAnalysis -XX:+UseCodeCacheFlushing -XX:+SegmentedCodeCache -XX:+UseFastJNIAccessors -XX:+OptimizeStringConcat -XX:+UseCompressedOops -XX:+UseThreadPriorities -XX:+OmitStackTraceInFastThrow -XX:+TrustFinalNonStaticFields -XX:ThreadPriorityPolicy=1 -XX:+UseInlineCaches -XX:+RewriteBytecodes -XX:+RewriteFrequentPairs -XX:+UseNUMA -XX:-DontCompileHugeMethods -XX:+UseFPUForSpilling -XX:+UseFastStosb -XX:+UseNewLongLShift -XX:+UseVectorCmov -XX:+UseXMMForArrayCopy -XX:+UseXmmI2D -XX:+UseXmmI2F -XX:+UseXmmLoadAndClearUpper -XX:+UseXmmRegToRegMoveAll -Dfile.encoding=UTF-8 -Xlog:async -Djava.security.egd=file:/dev/urandom --add-modules=jdk.incubator.vector
) else (
    set flags=-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:UseAVX=3 -XX:+UseStringDeduplication -XX:+UseFastUnorderedTimeStamps -XX:+UseAES -XX:+UseAESIntrinsics -XX:UseSSE=4 -XX:+UseFMA -XX:AllocatePrefetchStyle=1 -XX:+UseLoopPredicate -XX:+RangeCheckElimination -XX:+EliminateLocks -XX:+DoEscapeAnalysis -XX:+UseCodeCacheFlushing -XX:+SegmentedCodeCache -XX:+UseFastJNIAccessors -XX:+OptimizeStringConcat -XX:+UseCompressedOops -XX:+UseThreadPriorities -XX:+OmitStackTraceInFastThrow -XX:+TrustFinalNonStaticFields -XX:ThreadPriorityPolicy=1 -XX:+UseInlineCaches -XX:+RewriteBytecodes -XX:+RewriteFrequentPairs -XX:+UseNUMA -XX:-DontCompileHugeMethods -XX:+UseFPUForSpilling -XX:+UseFastStosb -XX:+UseNewLongLShift -XX:+UseVectorCmov -XX:+UseXMMForArrayCopy -XX:+UseXmmI2D -XX:+UseXmmI2F -XX:+UseXmmLoadAndClearUpper -XX:+UseXmmRegToRegMoveAll -Dfile.encoding=UTF-8 -Xlog:async -Djava.security.egd=file:/dev/urandom --add-modules=jdk.incubator.vector
)

goto exit


:: 退出标识,请不要在此下方添加代码
:exit