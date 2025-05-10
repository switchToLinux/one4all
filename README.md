<h1 align="center">
  <img src="https://raw.githubusercontent.com/switchToLinux/one4all/main/images/oneforall.jpg" alt="one4all script" width="200">
  <br>a Linux "one for all" script tools to install/config what you want to <br>
</h1>

# one4all
> 本项目是一个Linux脚本工具，支持但不限于安装/配置各种软件和环境。

## 本项目的设计初衷

适配大部分流行的Linux发行版操作工具集，安装/配置操作集成到一个脚本工具中，通过菜单选择简化Linux系统的软件安装、环境配置过程，让任何人都可以使用Linux桌面系统。

## 支持的Linux发行版
> 本项目脚本只支持Linux发行版，不支持Windows和MacOS。

- Arch系列
- Debian系列
- Fedora系列
- Debian系列


## 如何使用

下载`one`脚本并执行，选择你想要安装的功能，脚本会自动安装/配置:
summary 默认展开，点击可折叠。
<details open>
  <summary>使用curl下载</summary>

  ```bash

  # 下载one脚本-长链接
  # curl -o one https://raw.githubusercontent.com/switchToLinux/one4all/main/scripts/all4one.sh
  # wget -O one https://raw.githubusercontent.com/switchToLinux/one4all/main/scripts/all4one.sh

  # 下载one脚本-短链接
  curl -o one bit.ly/__one
  # wget -O one bit.ly/__one

  # 赋予执行权限并移动到/usr/local/bin目录下
  chmod +x one
  sudo mv one /usr/local/bin/

  # 执行one脚本
  one

  ```

</details>

---

<details>
  <summary>使用wget下载</summary>

  ```bash

  # 下载one脚本-长链接
  # wget -O one https://raw.githubusercontent.com/switchToLinux/one4all/main/scripts/all4one.sh

  # 下载one脚本-短链接
  wget -O one bit.ly/__one

  # 赋予执行权限并移动到/usr/local/bin目录下
  chmod +x one
  sudo mv one /usr/local/bin/

  # 执行one脚本
  one

  ```

</details>


## one4all.sh可以做什么

- 安装基础命令工具，菜单选择就可以完成，放弃了敲命令的愉悦感吧。
- 安装第三方应用，比如游戏平台Steam、音乐播放器YesPlayMusic、视频播放器vlc/mpv、视频剪辑工具Kdenlive/达芬奇、思维导图工具Xmind、书籍管理软件Calibre等。
- 配置开发环境，将环境部署工作标准化、自动化。
- 配置桌面环境，KDE/GNOME/XFCE/I3WM等等桌面环境的主题/布局快速配置。
- 更多等待你的自定义...

## 怎么做到的

虽然Linux发行版很多，操作各有不同，但都有固定的规则，将这些规则固化到脚本中，让一个脚本解决这些安装/配置问题吧。

> 任何人都可以使用Linux 娱乐、上网、软件开发。


## 你能做什么

- 使用它是你对本项目的最大支持。
- 有开发能力可以给这个脚本的不足提交PR修复。
- 分享给身边的人，帮使用Linux的用户少走弯路。
- 阅读脚本内容，学习脚本知识。

## 关于项目脚本
> 很多名词源自《我的英雄学院》中的个性能力，感觉比较适合脚本功能描述。

- `one`: 一种能力“`one for all`”(有种我为人人的奉献精神含义，主角个性)，本项目的`one4all.sh`脚本的含义是“一个脚本集成所有功能，适用于所有Linux发行版”，为了让脚本功能相对独立，将不同菜单功能拆分成独立的脚本实现，统一由 `one4all.sh`脚本调度。


## 灵感来源

manjaro 系统中`Toolbox`的`bmenu`命令效果与本命令类似。

---
> 能力有限，如有任何不足，欢迎指出并给出解决方法，学习是一种动力，开源是一种乐趣。
