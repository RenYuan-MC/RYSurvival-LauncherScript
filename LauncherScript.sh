#!/bin/bash

main(){
clear

info 请稍后,初始化中...
line=----------------------------------
titl=任渊生存
echo -n -e "\033]0;${titl} 初始化中...\007"

version_reader
config_reader
display_config
eula_checker
port_checker

times=0
if [ "${port_titl}" == "true" ]; then
    titl_port="端口: ${server_port}"
fi

loop

}

loop() {
    refresh_memory
    refresh_title
    refresh_flags

    clear
    
    ${java_path} -Xmx${xmx}M -Xms${xms}M ${flags} ${extra_java} -jar ${core} ${extra_server}

    echo ""
    info ${line}
    info 服务端已经关闭

    if [ "${auto_restart}" != "true" ]; then
        info 将在3秒后关闭窗口
        sleep 3s
        return
    fi

    for ((i=10; i>0; i--)) do
        info 服务端将在${i}秒后重启
        sleep 1s
    done


    loop   
}








# 读取服务端版本信息
version_reader() {
    if [ ! -f "version.properties" ]; then
        error 版本文件丢失，将使用默认的核心名称server.jar
        core=server.jar
        return
    fi
    properties_reader version.properties version
    properties_reader version.properties core -disablewarn
    properties_reader version.properties name
    properties_reader version.properties git
    if [ "${core}" == "" ]; then
       error 核心名称参数丢失，将使用默认的核心名称server.jar
       core=server.jar
    fi
    info ${line}
    info 任渊生存服务端 ${version} [git-${git}]
    info ${line}
}




# 控制台输出方法
info() {
    echo [Info] ${*}
}

warn() {
    echo -e "\e[93m[Warn] ${*}\e[0m"
}

error() {
    echo -e "\e[91m[Error] ${*}\e[0m"
}



# 暂停程序
pause() {
    if [ "$1" != "" ]; then
        echo -n -e "$1"
    fi
    SAVEDSTTY=`stty -g`
    stty -echo
    stty raw
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    echo ""
    stty $SAVEDSTTY
}



# properties文件读取
properties_reader() {
    local space
    local warn
    local tag
    if [ "${3}" == "-keepspace" ] || [ "${4}" == "-keepspace" ]; then
        space=true
    fi
    if [ "${3}" == "-disablewarn" ] || [ "${4}" == "-disablewarn" ]; then
        warn=false
    fi
    if [ ! -f "${1}" ]; then
        if [ "${warn}" != "false" ]; then
            warn 未检测到文件 ${1} ！
        fi
        return
    fi
    tag=$( grep -P "^\s*[^#]?${2}=.*$" ${1} | cut -d'=' -f2-999 | tr -d '\r')
    if [ "${tag}" == "" ]; then
        if [ "${warn}" != "false" ]; then
            warn 无法获取到 ${1} 的 ${2} 参数！
        fi
        return
    fi
    if [ "${space}" != "true" ]; then
        tag=${tag// /}
    fi
    eval ${2//-/_}=${tag}
}

# 配置文件读取
config_reader() {
    info 正在初始化配置文件系统

    # 早期版本的旧配置文件名称转换
    if [ -f "ConfigProgress.txt" ]; then
        rename ConfigProgress.txt progress.properties
    fi
    if [ -f "config.txt" ]; then
        rename config.txt config.properties
    fi

    # 检测旧配置文件
    properties_reader progress.properties ConfigSet -disablewarn
    if [ "${ConfigSet}" == "true" ]; then
       config_translator
       return
    fi

    # 检测默认配置文件
    if [ ! -f "launcher.properties" ]; then
        config_creater
    fi

    # 读取配置文件
    info 读取配置文件中
    properties_reader launcher.properties port-titl
    properties_reader launcher.properties etil-flags
    properties_reader launcher.properties auto-memory
    properties_reader launcher.properties default-xmx
    properties_reader launcher.properties default-xms
    properties_reader launcher.properties auto-restart
    properties_reader launcher.properties restart-wait
    properties_reader launcher.properties extra-server -keepspace -disablewarn
    properties_reader launcher.properties extra-java -keepspace -disablewarn
    properties_reader launcher.properties java-path -keepspace -disablewarn
    info 读取完毕！
}




# 配置文件创建
config_creater() {
    pause "[Info] 将创建一个新的配置文件,按任意键以继续: "
    port_titl=true
    etil_flags=true
    auto_memory=true 
    default_xmx=4096 
    default_xms=4096 
    auto_restart=true 
    restart_wait=10 
    extra_server=nogui
    ./Java/bin/java -version >/dev/null 2>&1
    if [ "${?}" == "0" ]; then
        java_path=./Java/bin/Java
    else
        java_path=java
    fi
    save_config
    info 创建完毕！
}



# 旧版配置文件转换
config_translator() {
    if [ ! -f "config.properties" ]; then
        warn 未找到正确的旧配置文件
        config_creater
        return
    fi
    if [ -f "launcher.properties" ]; then
        pause "\e[93m[Warn] 检测到launcher.properties已存在，将覆盖原配置文件，按任意键以继续: \e[0m"
    fi

    # 由于现在不会在xms开服前等待,将忽略EarlyLunchWait
    # ServerGUI将转换为extra-server直接添加-nogui参数
    # EarlyLunchWait,SysMem和LogAutoRemove被废弃,但为保留兼容仍做转换
    # 配置映射列表:
    # AutoMemSet -> auto-memory
    # UserRam -> default-xmx
    # MinMem -> default-xms
    # AutoRestart -> auto-restart
    # RestartWait -> restart-wait
    # ServerGUI -> extra-server
    # SysMem -> old.system-memory
    # LogAutoRemove -> old.auto-remove-log
    # EarlyLunchWait -> old.launch-wait

    properties_reader config.properties AutoMemSet -disablewarn
    properties_reader config.properties UserRam -disablewarn
    properties_reader config.properties MinMem -disablewarn
    properties_reader config.properties AutoRestart -disablewarn
    properties_reader config.properties RestartWait -disablewarn
    properties_reader config.properties ServerGUI -disablewarn
    properties_reader config.properties SysMem -disablewarn
    properties_reader config.properties LogAutoRemove -disablewarn
    properties_reader config.properties EarlyLunchWait -disablewarn

    port_titl=true
    etil_flags=true
    auto_memory=${AutoMemSet}
    if [ "${UserRam}" == "" ];then 
        UserRam=4096
    fi
    default_xmx=${UserRam}
    if [ "${MinMem}" == "" ]; then
        MinMem=128
    fi
    default_xms=${MinMem}
    auto_restart=${AutoRestart}
    restart_wait=${RestartWait}
    if [ "${ServerGUI}" == "false" ]; then
        extra_server=nogui 
    fi
    ./Java/bin/java -version >/dev/null 2>&1
    if [ "${?}" == "0" ]; then
        java_path=./Java/bin/java
    else
        java_path=java
    fi
    old_systemset_memory=%SysMem%
    old_auto_remove_log=%LogAutoRemove%
    old_launch_wait=%EarlyLunchWait%

    save_config true

    rm -f progress.properties
    rm -f config.properties

    info 转换完毕！

}



# 保存配置文件
save_config(){
    echo ^# 任渊生存服务端启动器配置文件  >launcher.properties
    echo "" >>launcher.properties
    echo ^# 是否在标题显示服务器端口 >>launcher.properties
    echo port-titlecho=${port_titl} >>launcher.properties
    echo "" >>launcher.properties
    echo ^# 是否启用etil-flags >>launcher.properties
    echo ^# etil-flags基于Aikar-flags,可以小幅度提升性能 >>launcher.properties
    echo etil-flags=${etil_flags} >>launcher.properties
    echo "" >>launcher.properties
    echo ^# 是否自动设置内存 >>launcher.properties
    echo auto-memory=${auto_memory} >>launcher.properties
    echo "" >>launcher.properties
    echo ^# 最小内存和最大内存,如开启自动设置内存,此项不生效 >>launcher.properties
    echo default-xmx=${default_xmx} >>launcher.properties
    echo default-xms=${default_xms} >>launcher.properties
    echo "" >>launcher.properties
    echo ^# 是否自动重启 >>launcher.properties
    echo auto-restart=${auto_restart} >>launcher.properties
    echo ^# 自动重启时的等待时间 >>launcher.properties
    echo restart-wait=${restart_wait} >>launcher.properties
    echo "" >>launcher.properties
    echo ^# 服务器参数 >>launcher.properties
    echo extra-server=${extra_server} >>launcher.properties
    echo ^# JVM参数 >>launcher.properties
    echo extra-java=${extra_java} >>launcher.properties
    echo ^# Java路径 >>launcher.properties
    echo java-path=${java_path} >>launcher.properties
    echo "" >>launcher.properties
    if [ "${1}" == "true" ]; then
       echo ^# 旧版本配置文件废弃参数 >>launcher.properties
       echo old.system-memory=${old_system_memory} >> launcher.properties
       echo old.auto-remove-log=${old_auto_remove_log} >> launcher.properties
       echo old.launch-wait=${old_launch_wait} >> launcher.properties
    fi
    sed -i 's/$/\r/g' launcher.properties
}

display_config() {
    info ${line}
    info 在标题显示端口: ${port_titl}
    info 启用etil-flags: ${etil_flags}
    info 自动分配内存: ${auto_memory}
    info 最大内存: ${default_xmx}
    info 最小内存: ${default_xms}
    info 自动重启: ${auto_restart}
    info 重启等待时间: ${restart_wait}
    info 服务器参数: ${extra_server}
    info JVM参数: ${extra_java}
    info Java路径: ${java_path}
    info ${line}
}



# Eula检查
eula_checker() {
    properties_reader eula.txt eula -disablewarn
    if [ "${eula}" == "true" ]; then
       return
    fi

    warn 在服务端正式运行前，你还要同意Minecraft EULA
    info 查看EULA请前往 https://account.mojang.com/documents/minecraft_eula
    pause 在此处按任意键表示同意Minecraft EULA并启动服务端

    echo eula=true>eula.txt
    info 你同意了Minecraft EULA,服务端即将启动
    info ${line}
    sleep 1s
    
}



# 端口检查
port_checker() {
    properties_reader server.properties server-port -disablewarn
    if [ "${server_port}" == "" ]; then
        port_titl=false
        return
    fi

    # Todo: 查找占用端口的程序
    
}



# 刷新标题
refresh_title() {
    if [ "${auto_restart}" == "true" ]; then
        echo -n -e "\033]0;${titl} ${name} 重启次数: ${times} ${titl_port}\007"
    else
        echo -n -e "\033]0;${titl} ${name} ${titl_port}\007"
    fi
}



# 刷新内存分配
refresh_memory() {
    if [ "${auto-memory}" != "true" ]; then
        xmx=${default_xmx}
        xms=${default_xms}
    fi

    mem_info=$(free | grep "Mem")
    mem_info=${mem_info//  / }
    TotalVisibleMemorySize=$(echo ${mem_info} | cut -d' ' -f2)
    ram=$(( ${TotalVisibleMemorySize} / 1024 ))
    FreePhysicalMemory=$(echo ${mem_info} | cut -d' ' -f4)
    freeram=$(( ${FreePhysicalMemory} / 1024 ))
    info 系统最大内存为：${ram} MB，剩余可用内存为：${freeram} MB

    xmx=$(( ${freeram} - 728 ))
    if [ ${xmx} -lt 1024 ]; then
        warn 剩余可用内存可能不足以开启服务端或者开启后卡顿
        xmx=1024
    elif [ ${xmx} -gt 20480 ]; then
        xmx=20480
    fi
    xms=${xmx}
    info 本次将分配 ${xmx} MB内存
    info ${line}
    sleep 1s
}



# 刷新etil-flags
refresh_flags() {
    if [ "${etil_flags}" == "false" ]; then
        return
    fi

    if [ ${xmx} -lt 12288 ]; then
        flags="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:UseAVX=3 -XX:+UseStringDeduplication -XX:+UseFastUnorderedTimeStamps -XX:+UseAES -XX:+UseAESIntrinsics -XX:UseSSE=4 -XX:+UseFMA -XX:AllocatePrefetchStyle=1 -XX:+UseLoopPredicate -XX:+RangeCheckElimination -XX:+EliminateLocks -XX:+DoEscapeAnalysis -XX:+UseCodeCacheFlushing -XX:+SegmentedCodeCache -XX:+UseFastJNIAccessors -XX:+OptimizeStringConcat -XX:+UseCompressedOops -XX:+UseThreadPriorities -XX:+OmitStackTraceInFastThrow -XX:+TrustFinalNonStaticFields -XX:ThreadPriorityPolicy=1 -XX:+UseInlineCaches -XX:+RewriteBytecodes -XX:+RewriteFrequentPairs -XX:+UseNUMA -XX:-DontCompileHugeMethods -XX:+UseFPUForSpilling -XX:+UseFastStosb -XX:+UseNewLongLShift -XX:+UseVectorCmov -XX:+UseXMMForArrayCopy -XX:+UseXmmI2D -XX:+UseXmmI2F -XX:+UseXmmLoadAndClearUpper -XX:+UseXmmRegToRegMoveAll -Dfile.encoding=UTF-8 -Xlog:async -Djava.security.egd=file:/dev/urandom --add-modules=jdk.incubator.vector"
    else
        flags="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:UseAVX=3 -XX:+UseStringDeduplication -XX:+UseFastUnorderedTimeStamps -XX:+UseAES -XX:+UseAESIntrinsics -XX:UseSSE=4 -XX:+UseFMA -XX:AllocatePrefetchStyle=1 -XX:+UseLoopPredicate -XX:+RangeCheckElimination -XX:+EliminateLocks -XX:+DoEscapeAnalysis -XX:+UseCodeCacheFlushing -XX:+SegmentedCodeCache -XX:+UseFastJNIAccessors -XX:+OptimizeStringConcat -XX:+UseCompressedOops -XX:+UseThreadPriorities -XX:+OmitStackTraceInFastThrow -XX:+TrustFinalNonStaticFields -XX:ThreadPriorityPolicy=1 -XX:+UseInlineCaches -XX:+RewriteBytecodes -XX:+RewriteFrequentPairs -XX:+UseNUMA -XX:-DontCompileHugeMethods -XX:+UseFPUForSpilling -XX:+UseFastStosb -XX:+UseNewLongLShift -XX:+UseVectorCmov -XX:+UseXMMForArrayCopy -XX:+UseXmmI2D -XX:+UseXmmI2F -XX:+UseXmmLoadAndClearUpper -XX:+UseXmmRegToRegMoveAll -Dfile.encoding=UTF-8 -Xlog:async -Djava.security.egd=file:/dev/urandom --add-modules=jdk.incubator.vector"
    fi
}


main