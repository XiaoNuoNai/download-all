# 一些个人实现的简易脚本
  可能主要为了简化一些部署项目的工作流，让感兴趣的玩家能快速上手体验
  #### 警告:
  本仓库的任何脚本都完全不保证稳定运行 而且对单一平台的依赖度极高 请勿在非隔离个人环境与生产环境内使用
  否则结果可能完全不符合预期 甚至损坏您的设备或系统 
   运行脚本产生的轻度影响 可适当协助解决 产生高于应用层的一切后果皆由用户承担 本仓库概不负责 
    请谨慎使用

## Project#1: ARM安卓设备 一键部署qq聊天机器人框架
  ･ 风险程度:按照场景使用极低

### 必要依赖: 

   ･Android系统

   ･termux

   ･稳定的网络连接
  ## 安装方式
  在终端应用中执行以下代码
 
   注:
     #### 此命令部分不适宜多次执行
 ```bash
clear && termux-setup-storage && echo "先同意一下权限哦" && sleep 10 && echo "现在要更新一下系统˙" &&  pkg update -y && pkg upgrade -y  && echo "现在要安装一个虚拟的系统啦" && pkg install proot-distro -y  && proot-distro install ubuntu && echo "proot-distro login ubuntu" >> ~/.bashrc && proot-distro login ubuntu -- bash -c "echo \"已经进到环境里的系统啦˙ 现在 又要更新一下\" && apt update -y  && apt upgrade -y  && \
clear && echo \"现在要干好多事 
  要编译Python
    要安装uv
     要安装AstrBot
      要安装猫猫框架 需要十几或者几十分钟哦\" && \
echo \"先安装Python 要最长时间的地方 可能十几分钟
  不过是优化过的版本哦~ 跑得更快 更省电˙\" && \
curl -L -O https://raw.githubusercontent.com/Xiaonuonai/download-all/main/setupPython-AstrBot-QQ.sh && \
curl -L https://www.python.org/ftp/python/3.12.12/Python-3.12.12.tar.xz | tar -xJ -C ~/ && \
chmod +x ~/setupPython-AstrBot-QQ.sh && ./setupPython-AstrBot-QQ.sh"
```
### 可多次执行的版本(请先执行上方代码)

  ```bash
clear && pkg update -y && pkg upgrade -y && proot-distro login ubuntu -- bash -c "echo \"已经进到环境里的系统啦˙ 现在 又要更新一下\" && apt update -y  && apt upgrade -y  && \
clear && echo \"又来到这里啦\" && \
curl -L -O https://raw.githubusercontent.com/Xiaonuonai/download-all/main/setupPython-AstrBot-QQ.sh && \
curl -L https://www.python.org/ftp/python/3.12.12/Python-3.12.12.tar.xz | tar -xJ -C ~/ && \
chmod +x ~/setupPython-AstrBot-QQ.sh && ./setupPython-AstrBot-QQ.sh"
  ```
