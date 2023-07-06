<h1 align="center">
  <img src="https://raw.githubusercontent.com/switchToLinux/one4all/main/images/oneforall.jpg" alt="one4all script" width="200">
  <br>a Linux "one for all" script tools to install/config what you want to <br>
</h1>

# one4all script
> a Linux "one for all" script tools to install/config what you want to.

本项目的设计初衷为将所有Linux发行版的安装/配置操作集成到一个脚本工具中，简化Linux系统的软件安装、环境配置过程。

以后的Linux上只需要一个脚本工具搞定所有安装工作，具体的细节被封装起来自动化完成，不再需要查找安装介绍和命令的复制粘贴（导致发生问题的关键）。

## 如何使用

使用`all`(所有脚本功能集成在一个脚本中):
```bash
curl -o all https://raw.githubusercontent.com/switchToLinux/one4all/main/scripts/one4all.sh
wget -O all https://raw.githubusercontent.com/switchToLinux/one4all/main/scripts/one4all.sh

chmod +x all
sudo mv all /usr/local/bin/
all

```

使用`one`(一个脚本，按需下载需要脚本):
```bash
curl -o one https://raw.githubusercontent.com/switchToLinux/one4all/main/scripts/all4one.sh
wget -O one https://raw.githubusercontent.com/switchToLinux/one4all/main/scripts/all4one.sh

chmod +x one
sudo mv one /usr/local/bin/
one

```
## 可以做什么

- 安装基础命令工具，菜单选择就可以完成，放弃了敲命令的愉悦感吧。
- 安装第三方应用，比如游戏平台Steam、音乐播放器YesPlayMusic、视频播放器vlc/mpv、视频剪辑工具Kdenlive/达芬奇、思维导图工具Xmind、书籍管理软件Calibre等。
- 配置开发环境，将环境部署工作标准化、自动化。
- 配置桌面环境，KDE/GNOME/XFCE/I3WM等等桌面环境的主题/布局快速配置。
- 更多...

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

- `all`: 一种个性能力“`one for all`”(有种我为人人的奉献精神含义，主角个性)，本项目的`one4all.sh`脚本的含义是“一个脚本集成所有功能，适用于所有Linux发行版”，因此脚本代码量会越来越庞大，即所谓`负重前行`就是充当`英雄`的压力与动力。
- `one`: 一个个性能力名称“`all for one`”(有种人人为我的拿来主义含义，反派个性)，在本项目的`all4one.sh`脚本即将所有功能拆分单独脚本，最后统一由`all4one.sh`脚本调用执行，这样的`all4one.sh`更轻量级，代码量可以减少很多。


## 参考

manjaro 系统中`Toolbox`的`bmenu`命令效果与本命令类似。

---
> 能力有限，如有任何不足，欢迎指出并给出解决方法，学习是一种动力，开源是一种乐趣。
