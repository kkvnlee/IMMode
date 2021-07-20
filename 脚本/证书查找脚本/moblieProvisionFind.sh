#!/bin/sh

#  moblieProvisionFind.sh
#  CTMediator
#
#  Created by kevin on 2021/7/20.
#  Copyright © 2021 casa. All rights reserved.

##########################################################
#使用说明：  sh moblieProvisionFind.sh [-d XXX] [-e] -i com.xxx.xxx

#参数说明:      -d 【默认Provisioning Profiles <文件路径>】
#              -i 【查找的Bundle id】
#              -e 【无参数，打印Entitlements信息】
#########################################################

myexit()
{
    if [ $1 - eq 1 ]
    then
    echo "\n ******** ERROR: $1 \n"
    fi
    exit 1
}

ProjectDir="${HOME}/Library/MobileDevice/Provisioning Profiles"
PrintEntitlements="false"

#自定义参数处理
while getopts ":d:i:e" opt
do
    case $opt in
    "d")
    ProjectDir=$OPTARG
    ;;
    "i")
    AppId=$OPTARG
    ;;
    "e")
    PrintEntitlements="true"
    ;;
    "?")
    myexit "[-$OPTARG] 无效参数"
    ;;
    ":")
    myexit "[-$OPTARG] 未传入参数值"
    ;;
    esac
done

if [ ! $AppId ]
then
myexit "AppId invaid, using '-i xxx'"
fi

#参数检查，加引号防止有空格等特殊字符
if [ ! -d "$ProjectDir" ]
then
myexit "$ProjectDir is not exist"
fi


#去到目标目录；加引用防止有空格等特殊字符
cd "$ProjectDir"

echo "\n----------------------------start-------------------------"
for ContentDir in $(find . -name "*.mobileprovision")
do
    ProvisionContent=$(security -qi cms -D -i "$ContentDir" 2> /dev/null)
    grep -q "$AppId" /dev/stdin <<< $ProvisionContent
    if [ $? -eq 0 ]
    then
        ExpriseData=$(/usr/libexec/PlistBuddy -c "print ExpirationDate" /dev/stdin <<< $ProvisionContent)
        UUID=$(/usr/libexec/PlistBuddy -c "print UUID" /dev/stdin <<< $ProvisionContent)
        RealAppId=$(/usr/libexec/PlistBuddy -c "print :Entitlements:application-identifier" /dev/stdin <<< $ProvisionContent)
        Entitlements=$(/usr/libexec/PlistBuddy -c "print :Entitlements" /dev/stdin <<< $ProvisionContent)
        
        if [ $PrintEntitlements == true ]
        then
            echo "\n FInd One-- \n \
            Name: $ContentDir \n \
            Entitlements: $Entitlements \n \
            UUID: $UUID \n \
            ExpriseData: $ExpriseData \n \
            Dir: ${ProjectDir} \n
            "
        else
            echo "\n FInd One-- \n \
            Name: $ContentDir \n \
            RealAppId: $RealAppId \n \
            UUID: $UUID \n \
            ExpriseData: $ExpriseData \n \
            Dir: ${ProjectDir} \n
            "
        fi
    fi
done
echo "\n----------------------------end--------------------------\n"
    
