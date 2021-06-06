#!/bin/sh
# 该脚本使用方法
# 源码地址：https://github.com/stackhou
# step 1. 在工程根目录新建AutoPacking文件夹，在该文件夹中新建文件autopacking.sh，将该脚本复制到autopacking.sh文件并保存(或者直接复制该文件);
# step 2. 设置该脚本;
# step 2. cd 该脚本目录，运行chmod +x autopacking.sh;
# step 3. 终端运行 sh autopacking.sh;
# step 4. 选择不同选项....
# step 5. Success  🎉 🎉 🎉!
# 注意：可以全文搜索“配置”，看相关注释选择配置，因为不同的项目配置不同，最好有相关的基础知识

# ************************* 需要配置 Start ********************************

# 【配置上传到蒲公英相关信息】(可选)
__PGYER_U_KEY="4xxxxxxxxxxxxxxxb"
__PGYER_API_KEY="3xxxxxxxxxxxxxx5"

# 【配置上传到 Fir】(可选)
__FIR_API_TOKEN="xKKdjdldlodeikK626266skdkkddK"

# 【配置证书】(如果只有一个证书时该项 可选)
__CODE_SIGN_DISTRIBUTION="iPhone Distribution: xxxxxxxxxxxCo., Ltd."
__CODE_SIGN_DEVELOPMENT="iPhone Developer: xxxx xxxx (5xxxxxxxxxx2V)"

# 发布APP Store 账号密码
__IOS_SUBMIT_ACCOUNT="apple id"
__IOS_SUBMIT_PASSWORD="xxxxxx"

# ==================== 公共部分 =====================
# ######### 脚本样式 #############
__TITLE_LEFT_COLOR="\033[36;1m==== "
__TITLE_RIGHT_COLOR=" ====\033[0m"

__OPTION_LEFT_COLOR="\033[33;1m"
__OPTION_RIGHT_COLOR="\033[0m"

__LINE_BREAK_LEFT="\033[32;1m"
__LINE_BREAK_RIGHT="\033[0m"

# 红底白字
__ERROR_MESSAGE_LEFT="\033[41m ! ! ! "
__ERROR_MESSAGE_RIGHT=" ! ! ! \033[0m"

# xcode version
XCODE_BUILD_VERSION=$(xcodebuild -version)
echo "-------------- Xcode版本: $XCODE_BUILD_VERSION -------------------"

# 等待用户输入时间
__WAIT_ELECT_TIME=0.2

# 选择项输入方法 接收3个参数：1、选项标题 2、选项数组 3、选项数组的长度(0~256)
function READ_USER_INPUT() {
  title=$1
  options=$2
  maxValue=$3
  echo "${__TITLE_LEFT_COLOR}${title}${__TITLE_RIGHT_COLOR}"
  for option in ${options[*]}; do
    echo "${__OPTION_LEFT_COLOR}${option}${__OPTION_RIGHT_COLOR}"
  done
  read
  __INPUT=$REPLY
  expr $__INPUT "+" 10 &> /dev/null
  if [[ $? -eq 0 ]]; then
    if [[ $__INPUT -gt 0 && $__INPUT -le $maxValue ]]; then
      return $__INPUT
    else
      echo "${__ERROR_MESSAGE_LEFT}输入越界了，请重新输入${__ERROR_MESSAGE_RIGHT}"
      READ_USER_INPUT $title "${options[*]}" $maxValue
    fi
  else
    echo "${__ERROR_MESSAGE_LEFT}输入有误，请输入0~256之间的数字序号${__ERROR_MESSAGE_RIGHT}"
    READ_USER_INPUT $title "${options[*]}" $maxValue
  fi
}

# 打印信息
function printMessage() {
  pMessage=$1
  echo "${__LINE_BREAK_LEFT}${pMessage}${__LINE_BREAK_RIGHT}"
}

  __BUILD_TARGET="GRGame"
  __SCHEME_NAME="GRGame"
__IS_WORKSPACE_OPTION= 1

# 4.# AdHoc, AppStore, Enterprise, Development
__PACK_TYPES=("1.AppStore" "2.Development" "3.ReleaseTestOffcial")
READ_USER_INPUT "请选择打包环境类型(输入序号，直接回车): " "${__PACK_TYPES[*]}" ${#__PACK_TYPES[*]}

__PACK_TYPE=$?

if [[ $__PACK_TYPE -eq 1 ]]; then
  __BUILD_CONFIGURATION="Release"
  __BUILD_IPA_NAME="游信"
elif [[ $__PACK_TYPE -eq 2 ]]; then
  __BUILD_CONFIGURATION="ReleaseTest"
    __BUILD_IPA_NAME="游信(公测服)"
elif [[ $__PACK_TYPE -eq 3 ]]; then
  __BUILD_CONFIGURATION="ReleaseTestOfficial"
    __BUILD_IPA_NAME="游信(正式服)"
fi

if [[ $__PACK_TYPE -eq 1 ]]; then
  __EXPORT_OPTIONS_PLIST_PATH="./AutoPacking/Plist/AppStoreExportOptionsPlist.plist"
  __BUILD_METHOD_NAME="AppStore"
elif [[ $__PACK_TYPE -eq 2 ]]; then
  __EXPORT_OPTIONS_PLIST_PATH="./AutoPacking/Plist/DevelopmentExportOptions.plist"
  __BUILD_METHOD_NAME="Development"
elif [[ $__PACK_TYPE -eq 3 ]]; then
  __EXPORT_OPTIONS_PLIST_PATH="./AutoPacking/Plist/OfficialExportOptions.plist"
  __BUILD_METHOD_NAME="Development"
fi

__UPLOAD_IPA_OPTION= 1
__IS_AUTO_OPENT_FILE_OPTION=1


__IS_NOW_STAR_PACKING=1
if [[ $__IS_NOW_STAR_PACKING -eq 1 ]]; then
  printMessage "已开始打包"
elif [[ $__IS_NOW_STAR_PACKING -eq 2 ]]; then
  printMessage "您退出了自动打包脚本"
  exit 1
fi

# ===============================自动打包部分=============================
# 打包计时
__CONSUME_TIME=0
# 回退到工程目录
cd ../
__PROGECT_PATH=`pwd`

# 获取项目名称
__PROJECT_NAME=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`

# 已经指定Target的Info.plist文件路径 【配置Info.plist的名称】
__CURRENT_INFO_PLIST_NAME="GRGame-Info.plist"
# 获取 Info.plist 路径  【配置Info.plist的路径】
__CURRENT_INFO_PLIST_PATH="${__PROJECT_NAME}/${__CURRENT_INFO_PLIST_NAME}"
# 获取版本号
__BUNDLE_VERSION=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ${__CURRENT_INFO_PLIST_PATH}`
# 获取编译版本号
__BUNDLE_BUILD_VERSION=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ${__CURRENT_INFO_PLIST_PATH}`


# Xcode11 以上版本
if [[ $XCODE_BUILD_VERSION =~ "Xcode 11" || $XCODE_BUILD_VERSION =~ "Xcode11" ]]; then
  __BUNDLE_VERSION_TAG="MARKETING_VERSION"
  __BUNDLE_BUILD_VERSION_TAG="CURRENT_PROJECT_VERSION"
  __PROJECT_ROOT_PATH=`find . -name *.xcodeproj`
  __PBXPROJ_PATH="$__PROJECT_ROOT_PATH/project.pbxproj"
  __BUNDLE_VERSION_11=$(grep "${__BUNDLE_VERSION_TAG}" $__PBXPROJ_PATH | head -1 | awk -F '=' '{print $2}' | awk -F ';' '{print $1}' | sed s/[[:space:]]//g)
  __BUNDLE_BUILD_VERSION_11=$(grep "${__BUNDLE_BUILD_VERSION_TAG}" $__PBXPROJ_PATH | head -1 | awk -F '=' '{print $2}' | awk -F ';' '{print $1}' | sed s/[[:space:]]//g)

  if [[ -n "$__BUNDLE_VERSION_11" ]]; then
    __BUNDLE_VERSION="$__BUNDLE_VERSION_11";
  fi

  if [[ -n "$__BUNDLE_BUILD_VERSION_11" ]]; then
    __BUNDLE_BUILD_VERSION="$__BUNDLE_BUILD_VERSION_11";
  fi
fi

# 编译生成文件目录
__EXPORT_PATH="./build"

# 指定输出文件目录不存在则创建
if test -d "${__EXPORT_PATH}" ; then
rm -rf ${__EXPORT_PATH}
else
mkdir -pv ${__EXPORT_PATH}
fi

# 归档文件路径
__EXPORT_ARCHIVE_PATH="${__EXPORT_PATH}/${__SCHEME_NAME}.xcarchive"
# ipa 导出路径
__EXPORT_IPA_PATH="${__EXPORT_PATH}"
# 获取时间 如:201706011145
__CURRENT_DATE="$(date +%Y%m%d_%H%M%S)"

function print_packing_message() {

  printMessage "打包类型 = ${__BUILD_CONFIGURATION}"
  printMessage "打包导出Plist路径 = ${__EXPORT_OPTIONS_PLIST_PATH}"
  printMessage "工程目录 = ${__PROGECT_PATH}"
  printMessage "当前Info.plist路径 = ${__CURRENT_INFO_PLIST_PATH}"
}

print_packing_message

  # pod install --verbose --no-repo-update
    # step 1. Clean
    xcodebuild clean  -workspace ${__PROJECT_NAME}.xcworkspace \
    -scheme ${__SCHEME_NAME} \
    -configuration ${__BUILD_CONFIGURATION}

    # step 2. Archive
    xcodebuild archive  -workspace ${__PROJECT_NAME}.xcworkspace \
    -scheme ${__SCHEME_NAME} \
    -configuration ${__BUILD_CONFIGURATION} \
    -archivePath ${__EXPORT_ARCHIVE_PATH} \
    CFBundleVersion=${__BUNDLE_BUILD_VERSION} \
    -destination generic/platform=ios \
    #CODE_SIGN_IDENTITY="${__CODE_SIGN_DISTRIBUTION}"


# 检查是否构建成功
# xcarchive 实际是一个文件夹不是一个文件所以使用 -d 判断
if test -d "${__EXPORT_ARCHIVE_PATH}" ; then
  printMessage "项目构建成功 🚀 🚀 🚀"
else
  printMessage "项目构建失败 😢 😢 😢"
  exit 1
fi

printMessage "开始导出ipa文件"

xcodebuild -exportArchive -archivePath ${__EXPORT_ARCHIVE_PATH} \
-exportPath ${__EXPORT_IPA_PATH} \
-destination generic/platform=ios \
-exportOptionsPlist ${__EXPORT_OPTIONS_PLIST_PATH} \
-allowProvisioningUpdates

# 检查文件是否存在
if test -f "${__EXPORT_IPA_PATH}/${__BUILD_IPA_NAME}.ipa" ; then

  printMessage "导出 ${__BUILD_IPA_NAME}.ipa 包成功 🎉 🎉 🎉"

  if [[ $__UPLOAD_IPA_OPTION -eq 1 ]]; then
    printMessage "您选择了不上传到内测网站"
  elif [[ $__UPLOAD_IPA_OPTION -eq 2 ]]; then

    curl -F "file=@${__EXPORT_IPA_PATH}/${__BUILD_IPA_NAME}.ipa" \
    -F "uKey=$__PGYER_U_KEY" \
    -F "_api_key=$__PGYER_API_KEY" \
    "http://www.pgyer.com/apiv1/app/upload"

    printMessage "上传 ${__BUILD_IPA_NAME}.ipa 包 到 pgyer 成功 🎉 🎉 🎉"

  elif [[ $__UPLOAD_IPA_OPTION -eq 3 ]]; then

    fir login -T ${__FIR_API_TOKEN}
    fir publish "${__EXPORT_IPA_PATH}/${__BUILD_IPA_NAME}.ipa"

    printMessage "上传 ${__BUILD_IPA_NAME}.ipa 包 到 fir 成功 🎉 🎉 🎉"

  elif [[ $__UPLOAD_IPA_OPTION -eq 4 ]]; then

    fir login -T ${__FIR_API_TOKEN}
    fir publish "${__EXPORT_IPA_PATH}/${__BUILD_IPA_NAME}.ipa"

    printMessage "上传 ${__BUILD_IPA_NAME}.ipa 包 到 fir 成功 🎉 🎉 🎉"

    curl -F "file=@{${__EXPORT_IPA_PATH}/${__BUILD_IPA_NAME}.ipa}" \
    -F "uKey=$__PGYER_U_KEY" \
    -F "_api_key=$__PGYER_API_KEY" \
    "http://www.pgyer.com/apiv1/app/upload"

    printMessage "上传 ${__BUILD_IPA_NAME}.ipa 包 到 pgyer 成功 🎉 🎉 🎉"

  fi

  # 自动打开文件夹
  if [[ $__IS_AUTO_OPENT_FILE_OPTION -eq 1 ]]; then
    open ${__EXPORT_IPA_PATH}
  fi

else
  printMessage "导出 ${__BUILD_IPA_NAME}.ipa 包失败 😢 😢 😢"
  exit 1
fi

# 输出打包总用时
printMessage "使用YJShell脚本打包总耗时: ${SECONDS}s"

appleid="nicexunni@icloud.com"
appleIDPWD="gvmy-bzsz-scpn-npsb"

if [[ $__PACK_TYPE -eq 1 ]]; then
#上传App Store
echo '/+++++++ 上传App Store +++++++/'
#验证并上传到App Store1

altoolPath="/Applications/Xcode.app/Contents/Applications/Application\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
xcrun altool --validate-app -f ${__EXPORT_IPA_PATH}/$__BUILD_IPA_NAME.ipa -u "${appleid}" -p "${appleIDPWD}" -t ios --output-format xml
xcrun altool --upload-app -f ${__EXPORT_IPA_PATH}/$__BUILD_IPA_NAME.ipa -u  "${appleid}" -p "${appleIDPWD}" -t ios --output-format xml

append_path="已上传到App Store"
# 修改存放ipa包文件夹路径，添加后缀，以便区分上传平台
mv $__EXPORT_IPA_PATH $__EXPORT_IPA_PATH$append_path
echo '/+++++++ 成功上传到App Store +++++++/'
fi


