#!/bin/sh

#  parserCrashLog.sh
#  CTMediator
#
#  Created by kevin on 2021/7/20.
#  Copyright © 2021 casa. All rights reserved.


#对崩溃日志进行符号化解析
##############################
# dsym文件：同版本的dsym文件
# crashlog文件：需要改名为 *@1.txt
##############################

g_exportFileName=“”
checkExistFileAndFixFileName()
{
    subfixCount=0
    subfixCountAdd=$(expr &subfixCount + 1)
    
    while([ -e "$g_exportFileName" ])
    do
        if [ ${subfixCount} -eq 0 ]
        then
            g_exportFileName=${g_exportFileName//Crash./Crash-${subfixCountAdd}.}
        else
            g_exportFileName=${g_exportFileName//Crash-${subfixCount}./Crash-${subfixCountAdd}.}
        fi
        ((subfixCount++))
        ((subfixCountAdd++))
    done
}

echo "start"
#查找最新的txt文件
unsymbolicatefilename=`ls -rt *@*.txt | tail -1`
#重命名*Crash.txt
g_exportFileName=${unsymbolicatefilename//@[a-z0-9]*./Crash.}

echo $g_exportFileName
#检查是否有重名文件存在，有则使用*Crash-number.txt
checkExistFileAndFixFileName
echo "unsymbolicated file: $unsymbolicatefilename"

appName=`find . -name '*.dSYM' | head -1`
appName=${appName:2}
echo "symbolicate with dSYM file: $appName"
appName=${appName//.dSYM/}

echo "exporting symbolicated file: $g_exportFileName"
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

symcrashFilePath=/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash
if [ -e $symcrashFilePath ]
then
    $symcrashFilePath $unsymbolicatefilename $appName > $g_exportFileName
    echo "symbolicate finished"
else
    echo "error, symcrashFile not exist!"
fi



        
