#!/bin/bash

# 显示彩色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 显示选项菜单
echo -e "${YELLOW}请选择构建选项:${NC}"
echo "1) 构建Android和iOS发布版本（真机使用）"
echo "2) 构建Android发布版和iOS模拟器版本"
echo "3) 仅构建Android发布版本"
echo "4) 仅构建iOS发布版本（真机使用）"
echo "5) 仅构建iOS模拟器版本"
echo "6) 构建iOS IPA格式（需要开发者证书）"
echo "7) 构建Android真机debug版本"
echo "8) 构建iOS真机debug版本"
read -p "请输入选项 (1-8): " option

echo -e "${YELLOW}开始清理旧的构建文件...${NC}"
flutter clean

# 根据用户选择执行不同的构建
case $option in
  1)
    # 构建Android和iOS发布版本
    echo -e "${YELLOW}开始构建Android版本...${NC}"
    flutter build apk --release
    ANDROID_RESULT=$?

    echo -e "${YELLOW}开始构建iOS发布版本...${NC}"
    flutter build ios --release --no-codesign
    IOS_RESULT=$?
    ;;
  2)
    # 构建Android发布版和iOS模拟器版本
    echo -e "${YELLOW}开始构建Android版本...${NC}"
    flutter build apk --release
    ANDROID_RESULT=$?

    echo -e "${YELLOW}开始构建iOS模拟器版本...${NC}"
    flutter build ios --debug --simulator
    IOS_RESULT=$?
    ;;
  3)
    # 仅构建Android发布版本
    echo -e "${YELLOW}开始构建Android版本...${NC}"
    flutter build apk --release
    ANDROID_RESULT=$?
    IOS_RESULT=0
    ;;
  4)
    # 仅构建iOS发布版本
    echo -e "${YELLOW}开始构建iOS发布版本...${NC}"
    flutter build ios --release --no-codesign
    IOS_RESULT=$?
    ANDROID_RESULT=0
    ;;
  5)
    # 仅构建iOS模拟器版本
    echo -e "${YELLOW}开始构建iOS模拟器版本...${NC}"
    flutter build ios --debug --simulator
    IOS_RESULT=$?
    ANDROID_RESULT=0
    ;;
  6)
    # 构建iOS IPA版本
    echo -e "${YELLOW}开始构建iOS IPA版本...${NC}"
    echo -e "${YELLOW}注意：此选项需要有效的Apple开发者证书配置${NC}"
    
    # 检查是否已配置开发团队
    TEAM_ID=$(grep -A 5 "DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj | grep -o "DEVELOPMENT_TEAM = \".*\";" | head -1)
    
    if [ -z "$TEAM_ID" ]; then
      echo -e "${RED}未检测到开发团队配置！${NC}"
      echo -e "请按照以下步骤配置:"
      echo -e "1. 打开Xcode项目: ${YELLOW}open ios/Runner.xcworkspace${NC}"
      echo -e "2. 选择Runner项目和目标"
      echo -e "3. 在'Signing & Capabilities'中选择您的开发团队"
      echo -e "4. 确保您已登录Apple ID并有有效的开发者账号"
      echo -e "5. 配置完成后再次运行此选项"
      
      read -p "是否现在打开Xcode配置？(y/n): " open_xcode
      if [ "$open_xcode" = "y" ] || [ "$open_xcode" = "Y" ]; then
        open ios/Runner.xcworkspace
      fi
      
      IOS_RESULT=1
      ANDROID_RESULT=0
    else
      flutter build ipa --release
      IOS_RESULT=$?
      ANDROID_RESULT=0
    fi
    ;;
  7)
    # 构建Android真机debug版本
    echo -e "${YELLOW}开始构建Android真机debug版本...${NC}"
    flutter build apk --debug
    ANDROID_RESULT=$?
    IOS_RESULT=0
    ;;
  8)
    # 构建iOS真机debug版本
    echo -e "${YELLOW}开始构建iOS真机debug版本...${NC}"
    echo -e "${YELLOW}注意: 需要在Xcode中配置开发团队（免费Apple ID也可以使用）${NC}"
    
    # 检查是否已配置开发团队
    TEAM_ID=$(grep -A 5 "DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj | grep -o "DEVELOPMENT_TEAM = \".*\";" | head -1)
    
    if [ -z "$TEAM_ID" ]; then
      echo -e "${RED}未检测到开发团队配置！${NC}"
      echo -e "即使使用debug版本，iOS真机部署也需要签名配置:"
      echo -e "1. 打开Xcode项目: ${YELLOW}open ios/Runner.xcworkspace${NC}"
      echo -e "2. 选择Runner项目和目标"
      echo -e "3. 在'Signing & Capabilities'中选择您的开发团队(可使用免费Apple ID)"
      echo -e "4. 确保您已登录Apple ID"
      
      read -p "是否现在打开Xcode配置？(y/n): " open_xcode
      if [ "$open_xcode" = "y" ] || [ "$open_xcode" = "Y" ]; then
        open ios/Runner.xcworkspace
      fi
      
      IOS_RESULT=1
      ANDROID_RESULT=0
    else
      flutter build ios --debug
      IOS_RESULT=$?
      ANDROID_RESULT=0
    fi
    ;;
  *)
    echo -e "无效选项，退出构建"
    exit 1
    ;;
esac

echo -e "${YELLOW}构建结果：${NC}"

if [ $ANDROID_RESULT -eq 0 ] && [ "$option" != "4" ] && [ "$option" != "5" ] && [ "$option" != "6" ] && [ "$option" != "8" ]; then
  if [ "$option" = "7" ]; then
    echo -e "${GREEN}Android真机debug版本构建成功!${NC} APK位置: build/app/outputs/flutter-apk/app-debug.apk"
    echo -e "您可以使用ADB安装到设备:"
    echo -e "adb install build/app/outputs/flutter-apk/app-debug.apk"
  else
    echo -e "${GREEN}Android构建成功!${NC} APK位置: build/app/outputs/flutter-apk/app-release.apk"
  fi
elif [ "$option" != "4" ] && [ "$option" != "5" ] && [ "$option" != "6" ] && [ "$option" != "8" ]; then
  echo -e "${RED}Android构建失败，错误码: $ANDROID_RESULT${NC}"
fi

if [ $IOS_RESULT -eq 0 ] && [ "$option" != "3" ] && [ "$option" != "7" ]; then
  if [ "$option" = "2" ] || [ "$option" = "5" ]; then
    echo -e "${GREEN}iOS模拟器版本构建成功!${NC} 应用位置: build/ios/iphonesimulator"
    echo -e "您可以使用以下命令安装到模拟器:"
    echo -e "xcrun simctl install booted build/ios/iphonesimulator/Runner.app"
  elif [ "$option" = "6" ]; then
    echo -e "${GREEN}iOS IPA构建成功!${NC} 文件位置: build/ios/ipa"
    echo -e "您可以使用此IPA文件上传到App Store或安装到测试设备"
  elif [ "$option" = "8" ]; then
    echo -e "${GREEN}iOS真机debug版本构建成功!${NC} 应用位置: build/ios/iphoneos"
    echo -e "请在Xcode中运行应用到设备:"
    echo -e "打开 ${YELLOW}ios/Runner.xcworkspace${NC} 并点击运行按钮"
  else
    echo -e "${GREEN}iOS构建成功!${NC} 应用位置: build/ios/iphoneos"
    echo -e "注意：iOS应用需要在Xcode中签名后才能发布"
  fi
elif [ "$option" != "3" ] && [ "$option" != "7" ]; then
  if [ "$option" = "6" ]; then
    echo -e "${RED}iOS IPA构建失败${NC}"
    echo -e "构建IPA需要有效的Apple开发者证书，请确保您已经配置Xcode项目:"
    echo -e "1. 使用命令 ${YELLOW}open ios/Runner.xcworkspace${NC} 打开项目"
    echo -e "2. 在Signing & Capabilities中设置开发团队"
    echo -e "3. 确保您的Apple ID有效且已配置开发者账号"
  elif [ "$option" = "8" ]; then
    echo -e "${RED}iOS真机debug版本构建失败${NC}"
    echo -e "即使是debug版本，iOS真机部署也需要证书:"
    echo -e "1. 使用命令 ${YELLOW}open ios/Runner.xcworkspace${NC} 打开项目"
    echo -e "2. 在Signing & Capabilities中设置开发团队(可使用免费Apple ID)"
    echo -e "  注意：免费账号构建的应用在设备上只能使用7天"
  else
    echo -e "${RED}iOS构建失败，错误码: $IOS_RESULT${NC}"
  fi
fi

echo -e "\n构建完成！" 