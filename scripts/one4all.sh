#!/usr/bin/env bash
########################################################################
# File Name: one4all.sh
# Author: Awkee
# mail: next4nextjob@gmail.com
# Created Time: 2023年04月24日 星期一 23时23分23秒
#
# 非强制性约束: 网络下载使用curl命令而不用wget，没有任何歧视含义，仅处于统一要求
#
# 功能简述: 一个 one for all 脚本工具，给Linux的安装、配置过程一个简单的统一
########################################################################
# set -e              # 命令执行失败就中止继续执行
# 环境变量参数:
#   OUTPUTLOG - no 表示只输出日志信息到文件中,不在终端显示，默认为 yes(终端显示)
#

ONECFG=~/.config/one4all
# 导入基础模块 #
# 检测 ${ONECFG}/scripts/all/prompts_functions.sh 是否存在,不存在则git下载
if [[ -f ${ONECFG}/scripts/all/prompts_functions.sh ]] ; then
    source ${ONECFG}/scripts/all/prompts_functions.sh
else 
    git clone https://github.com/switchToLinux/one4all.git ~/.config/one4wall
    source ${ONECFG}/scripts/all/prompts_functions.sh
fi

for fn in `ls $`
############# GUI图形工具安装部分 #################################

function install_davinci() {
    loginfo "开始执行 install_davinci"
    prompt "开始安装达芬奇" || return 1
    menu_head "${RED} 提醒 ${NC}"
    menu_info 1 "由于达芬奇工具需要用户登录才能获取下载链接,暂无法实现自动下载安装."
    menu_info 2 "官网: https://www.blackmagicdesign.com/products/davinciresolve"
    menu_info 3 "注册/登录 账号,选择下载适合自己系统的免费版本"
    menu_info 4 "下载安装,安装好后即可使用啦"
    menu_tail
    loginfo "成功执行 install_davinci"
}
function install_xmind() {
    loginfo "开始执行 install_xmind"
    dn_url="https://dl3.xmind.net/Xmind-for-Linux-x86_64bit-22.11.3656.rpm"
    deb_url="https://www.xmind.app/zen/download/linux_deb/"
    rpm_url="https://www.xmind.app/zen/download/linux_rpm/"
    tmp_file=""
    case "$os_type" in
        ubuntu|debian)  dn_url="$deb_url"  && tmp_file="/tmp/xmind_zen.deb"  ;;
        opensuse*|centos|rhel*) dn_url="$rpm_url" && tmp_file="/tmp/xmind_zen.rpm" ;;
        *) logerr "暂不支持[$os_type]" ; return 1 ;;
    esac
    [[ -f "$tmp_file" ]] || ${curl_cmd} -o $tmp_file -SL $dn_url
    [[ "$?" != "0" ]] && logerr "下载 $tmp_file 失败! 网络出问题了." && return 2
    loginfo "下载 $tmp_file 成功!"
    sudo $pac_cmd_ins $tmp_file
    [[ "$?" != "0" ]] && logerr "安装过程出了点问题" && return 3
    loginfo "Xmind安装完成!到菜单里启动一下试试吧!"
    rm -f "$tmp_file"
    loginfo "成功执行 install_xmind"
}
function install_appimagelauncher() {
    loginfo "开始执行 install_appimagelauncher"
    prompt "开始安装 appimagelauncher" || return 1
    case "$os_type" in
        ubuntu|debian)
            sudo apt install software-properties-common
            sudo add-apt-repository ppa:appimagelauncher-team/stable
            sudo apt update
            sudo apt install appimagelauncher
            ;;
        centos|opensuse*)
            # rpm based
            tmp_path="/tmp/appimage"
            ! common_download_github_latest TheAssassin AppImageLauncher $tmp_path "x86_64.rpm"  && logerr "下载失败啦!" && return 1
            sudo $pac_cmd_ins $tmp_path/appimagelauncher*x86_64.rpm
            ;;
        manjaro|arch*)  sudo ${pac_cmd_ins} appimagelauncher  ;;
        *)  logerr "不支持系统类型[$os_type]" ; return 2 ;;
    esac
    loginfo "成功执行 install_appimagelauncher"
}
function show_menu_gui() {
    menu_head "安装图形工具选项菜单"
    menu_item 1 达芬奇DaVinciResolve18
    menu_item 2 "Xmind(思维导图)"
    menu_item 3 "安装AppImageLauncher"
    menu_tail
    menu_item q 返回上级菜单
    menu_tail
}
function do_install_gui() {
    while true
    do
        show_menu_gui
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) install_davinci      ;;
            2) install_xmind        ;;
            3) install_appimagelauncher ;;
            q|"") return 0          ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
############# GUI环境配置部分 ####################################
function kde_theme_switch() {
    # 主题设置
    declare -a theme_namelist
    idx=1
    menu_head "当前系统安装的主题列表："
    for str_item in `lookandfeeltool -l`
    do
        menu_iteml $idx $str_item
        theme_namelist[$idx]="$str_item"
        let idx=$idx+1
    done
    menu_iteml "q" "返回上一级"
    menu_tail
    while true ; do
        read -r -n 1 -e -p "请选择主题序号:" str_answer
        [[ "$str_answer" != "" ]] && [[ "$str_answer" == "q" ]] && return 1
        [[ "$str_answer" != "" ]] && [[ "$str_answer" -gt "0" ]] && [[ "$str_answer" -lt "$idx" ]] && your_theme="${theme_namelist[$str_answer]}" && break
    done
    loginfo "您选择的主题为:$your_theme"
    lookandfeeltool -a $your_theme
    menu_tail
    menu_iteml "提示" "更多设置请使用${BG}系统设置${NC}"
    menu_tail
}
function config_kde_theme() {
    loginfo "正在执行 config_kde_theme"
    prompt "开始配置KDE主题" || return 1 
    sudo $pac_cmd_ins latte-dock
    tmp_path="/tmp/themes"    # 主题下载目录
    mkdir -p $tmp_path
    git clone https://github.com/numixproject/numix-kde-theme.git $tmp_path/numix-kde-theme && cd $tmp_path/numix-kde-theme && make install && cd -
    loginfo "安装全局主题-[Layan-kde]"
    git clone https://github.com/vinceliuice/Layan-kde.git $tmp_path/Layan-kde && cd $tmp_path/Layan-kde && sh ./install.sh && cd -
    loginfo "安装全局主题-[We10XOS-kde]"
    git clone https://github.com/yeyushengfan258/We10XOS-kde.git $tmp_path/We10XOS-kde && cd $tmp_path/We10XOS-kde && sh ./install.sh && cd -
    
    loginfo "安装全局主题-[WhiteSur-kde]"
    git clone https://github.com/vinceliuice/WhiteSur-kde.git  $tmp_path/WhiteSur-kde && cd $tmp_path/WhiteSur-kde && sh ./install.sh && cd -
    cd $tmp_path/WhiteSur-kde/sddm && sudo sh ./install.sh && cd -
    loginfo "安装Icons主题-[WhiteSur-icon-theme]"
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git  $tmp_path/WhiteSur-icon-theme && cd $tmp_path/WhiteSur-icon-theme && sh ./install.sh && cd -
    loginfo "安装主题-[McMojave-circle]"
    git clone https://github.com/vinceliuice/McMojave-circle.git  $tmp_path/McMojave-circle && cd $tmp_path/McMojave-circle && sh ./install.sh --all && cd -
    loginfo "安装GRUB2主题-[grub2-themes]"
    git clone https://github.com/vinceliuice/grub2-themes.git  $tmp_path/grub2-themes && cd $tmp_path/grub2-themes && sudo ./install.sh -b -t whitesur && cd -

    ! command -v lookandfeeltool >/dev/null && sudo $pac_cmd_ins plasma-workspace plasma5-workspace
    ! command -v lookandfeeltool >/dev/null && logerr "lookandfeeltool 安装失败,请手动设置主题" && return 1
    
    kde_theme_switch
    loginfo "成功执行 config_kde_theme"
}
function config_desktop_theme(){
    loginfo "正在执行 config_desktop_theme 安装配置桌面主题"
    prompt "开始安装桌面主题" || return 1
    menu_head "当前桌面环境检查"
    menu_iteml "桌面环境" $gui_type
    menu_iteml "操作系统" $os_type
    menu_tail
    case "$gui_type" in 
        KDE)
            config_kde_theme
            ;;
        *)
            echo "$os_type 系统类型不支持！"
            ;;
    esac
}

function config_i3wm() {
    #配置参考: https://i3wm.org/docs/userguide.html
    loginfo "开始执行 config_i3wm"
    command -v i3config >/dev/null 2>&1 || curl -L -o /tmp/i3config https://raw.githubusercontent.com/switchToLinux/dotfiles/main/i3config
    chmod +x /tmp/i3config && sudo mv ./i3config /usr/local/bin
    menu_head "开始使用 i3config 工具配置 i3wm环境"
    i3config
}
function show_menu_desktop() { # 显示子菜单
    menu_head "配置选项菜单"
    menu_item 1 安装桌面主题
    menu_item 2 桌面主题切换
    menu_item 3 配置i3wm
    menu_tail
    menu_item q 返回上级菜单
    menu_tail
}
function do_desktop_all() {
    while true
    do
        show_menu_desktop
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) config_desktop_theme ;;  # 桌面主题配置
            2) kde_theme_switch     ;;
            3) config_i3wm          ;;

            q|"") return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}

############# 基础环境配置部分 ####################################
function config_langpack() {  # 中文语言支持 zh_CN.UTF-8
    local_charset="zh_CN.UTF-8" # 字符集名称
    charset_name="zh_CN.utf8"   # Linux系统使用的是没有-的写法(只是写法差别)
    prompt "开始配置中文语言支持 $local_charset" || return 1 
    loginfo "正在执行 config_langpack ,支持 $local_charset 字符集"
    locale -a | grep -Ei "$local_charset|$charset_name" >/dev/null
    if [ "$?" != "0" ] ; then
        case "$os_type" in
            debian|ubuntu*)
                command -v locale-gen >/dev/null
                if [ "$?" = "0" ] ; then
                    sudo locale-gen $local_charset
                else
                    sudo dpkg-reconfigure locale
                fi
                ;;
            centos|almalinux)
                sudo $pac_cmd_ins glibc-common langpacks-zh_CN ;;
            *)
                redr_line "不支持的系统类型!暂时无法设置中文支持"
                return 1
        esac
    else
        whiter_line "本系统已经安装 $local_charset 字符集"
        if locale | grep -i "$charset_name" >/dev/null ; then
            green_line "您的系统已经设置了 $charset_name 中文字符集."
            return 0
        fi
    fi
    shprofile="$HOME/.`basename $SHELL`rc"  # 设置当前SHELL环境配置
    local_name=`locale -a | grep -Ei "$local_charset|$charset_name"`
    [[ -f "$shprofile" ]] && echo export LC_ALL="$local_name" >> ${shprofile}
    echo "在当前SHELL环境下执行  export LC_ALL=$local_name  立即生效."
    loginfo "成功执行 config_langpack ."
}
function config_sshd() { # 开启SSH服务
    loginfo "正在执行 config_sshd"
    prompt "开始启动SSHD服务" || return 1
    case "$os_type" in
        manjaro|opensuse*|ubuntu|debian|almalinux|centos)
            service_enable_start "sshd"
            ;;
        *)
            redr_line "未知的系统类型! os_type:$os_type"
            ;;
    esac
    loginfo "成功执行 config_sshd"
}
function config_source() { # 配置软件源为国内源(清华大学源速度更快，支持IPv6)
    loginfo "正在执行 config_source"
    prompt "开始配置软件源为国内(清华大学源)" || return 1
    case "$os_type" in
        centos)
            if [ "${os_version:0:1}" -lt "8" ] ; then
                redr_line "${os_type} 版本[$os_version] 低于 8,不支持了"
                return 0
            fi
            sudo sed -e 's|^mirrorlist=|#mirrorlist=|g' \
                -e 's|^#baseurl=http://mirror.centos.org/$contentdir|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos|g' \
                -i.bak \
                /etc/yum.repos.d/CentOS-*.repo
            sudo yum makecache
            ;;
        opensuse-leap)
            sudo zypper mr -da  # 禁用官方软件源
            sudo zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/oss/' mirror-oss
            sudo zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/non-oss/' mirror-non-oss
            sudo zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/oss/' mirror-update
            sudo zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/non-oss/' mirror-update-non-oss
            # Leap 15.3 用户还需添加 sle 和 backports 源
            # Leap 15.3 注：若在安装时没有启用在线软件源，sle 源和 backports 源将在系统首次更新后引入，请确保系统在更新后仅启用了六个所需软件源。可使用 zypper lr 检查软件源状态，并使用 zypper mr -d 禁用多余的软件源。
            sudo zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/sle/' mirror-sle-update
            sudo zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/backports/' mirror-backports-update
            sudo zypper ref     # 刷新软件源缓存
            ;;
        opensuse-tumbleweed)
            sudo zypper mr -da  # 禁用官方软件源
            sudo zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/tumbleweed/repo/oss/' mirror-oss
            sudo zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/tumbleweed/repo/non-oss/' mirror-non-oss
            sudo zypper ref     # 刷新软件源缓存
            ;;
        ubuntu)
            # 清华源编码为Base64编码(jammy-22.04版本模板)
            source_data="IyDpu5jorqTms6jph4rkuobmupDnoIHplZzlg4/ku6Xmj5Dpq5ggYXB0IHVwZGF0ZSDpgJ/luqbvvIzlpoLmnInpnIDopoHlj6/oh6rooYzlj5bmtojms6jph4oKZGViIGh0dHBzOi8vbWlycm9ycy50dW5hLnRzaW5naHVhLmVkdS5jbi91YnVudHUvIGphbW15IG1haW4gcmVzdHJpY3RlZCB1bml2ZXJzZSBtdWx0aXZlcnNlCiMgZGViLXNyYyBodHRwczovL21pcnJvcnMudHVuYS50c2luZ2h1YS5lZHUuY24vdWJ1bnR1LyBqYW1teSBtYWluIHJlc3RyaWN0ZWQgdW5pdmVyc2UgbXVsdGl2ZXJzZQpkZWIgaHR0cHM6Ly9taXJyb3JzLnR1bmEudHNpbmdodWEuZWR1LmNuL3VidW50dS8gamFtbXktdXBkYXRlcyBtYWluIHJlc3RyaWN0ZWQgdW5pdmVyc2UgbXVsdGl2ZXJzZQojIGRlYi1zcmMgaHR0cHM6Ly9taXJyb3JzLnR1bmEudHNpbmdodWEuZWR1LmNuL3VidW50dS8gamFtbXktdXBkYXRlcyBtYWluIHJlc3RyaWN0ZWQgdW5pdmVyc2UgbXVsdGl2ZXJzZQpkZWIgaHR0cHM6Ly9taXJyb3JzLnR1bmEudHNpbmdodWEuZWR1LmNuL3VidW50dS8gamFtbXktYmFja3BvcnRzIG1haW4gcmVzdHJpY3RlZCB1bml2ZXJzZSBtdWx0aXZlcnNlCiMgZGViLXNyYyBodHRwczovL21pcnJvcnMudHVuYS50c2luZ2h1YS5lZHUuY24vdWJ1bnR1LyBqYW1teS1iYWNrcG9ydHMgbWFpbiByZXN0cmljdGVkIHVuaXZlcnNlIG11bHRpdmVyc2UKCiMgZGViIGh0dHBzOi8vbWlycm9ycy50dW5hLnRzaW5naHVhLmVkdS5jbi91YnVudHUvIGphbW15LXNlY3VyaXR5IG1haW4gcmVzdHJpY3RlZCB1bml2ZXJzZSBtdWx0aXZlcnNlCiMgIyBkZWItc3JjIGh0dHBzOi8vbWlycm9ycy50dW5hLnRzaW5naHVhLmVkdS5jbi91YnVudHUvIGphbW15LXNlY3VyaXR5IG1haW4gcmVzdHJpY3RlZCB1bml2ZXJzZSBtdWx0aXZlcnNlCgpkZWIgaHR0cDovL3NlY3VyaXR5LnVidW50dS5jb20vdWJ1bnR1LyBqYW1teS1zZWN1cml0eSBtYWluIHJlc3RyaWN0ZWQgdW5pdmVyc2UgbXVsdGl2ZXJzZQojIGRlYi1zcmMgaHR0cDovL3NlY3VyaXR5LnVidW50dS5jb20vdWJ1bnR1LyBqYW1teS1zZWN1cml0eSBtYWluIHJlc3RyaWN0ZWQgdW5pdmVyc2UgbXVsdGl2ZXJzZQoKIyDpooTlj5HluIPova/ku7bmupDvvIzkuI3lu7rorq7lkK/nlKgKIyBkZWIgaHR0cHM6Ly9taXJyb3JzLnR1bmEudHNpbmdodWEuZWR1LmNuL3VidW50dS8gamFtbXktcHJvcG9zZWQgbWFpbiByZXN0cmljdGVkIHVuaXZlcnNlIG11bHRpdmVyc2UKIyAjIGRlYi1zcmMgaHR0cHM6Ly9taXJyb3JzLnR1bmEudHNpbmdodWEuZWR1LmNuL3VidW50dS8gamFtbXktcHJvcG9zZWQgbWFpbiByZXN0cmljdGVkIHVuaXZlcnNlIG11bHRpdmVyc2UKCg=="
            source_file="/etc/apt/sources.list"
            if [ -f "${source_file}.`date +%Y%m%d`" ] ; then
                echo "${source_file}.`date +%Y%m%d` 文件已经存在!"
            else
                echo "备份 ${source_file} 文件!"
                sudo mv $source_file ${source_file}.`date +%Y%m%d`
            fi
            sudo sh -c "echo $source_data | base64 -d > $source_file"
            if [ "$os_codename" != "jammy" ] ; then
                sudo sed -i "s/jammy/$os_codename/g" $source_file
            fi
            # 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释            
            ;;
        debian)
            # based on debian 12 bookworm
            source_data="IyDpu5jorqTms6jph4rkuobmupDnoIHplZzlg4/ku6Xmj5Dpq5ggYXB0IHVwZGF0ZSDpgJ/luqbvvIzlpoLmnInpnIDopoHlj6/oh6rooYzlj5bmtojms6jph4oKZGViIGh0dHBzOi8vbWlycm9ycy50dW5hLnRzaW5naHVhLmVkdS5jbi9kZWJpYW4vIGJvb2t3b3JtIG1haW4gY29udHJpYiBub24tZnJlZSBub24tZnJlZS1maXJtd2FyZQojIGRlYi1zcmMgaHR0cHM6Ly9taXJyb3JzLnR1bmEudHNpbmdodWEuZWR1LmNuL2RlYmlhbi8gYm9va3dvcm0gbWFpbiBjb250cmliIG5vbi1mcmVlIG5vbi1mcmVlLWZpcm13YXJlCgpkZWIgaHR0cHM6Ly9taXJyb3JzLnR1bmEudHNpbmdodWEuZWR1LmNuL2RlYmlhbi8gYm9va3dvcm0tdXBkYXRlcyBtYWluIGNvbnRyaWIgbm9uLWZyZWUgbm9uLWZyZWUtZmlybXdhcmUKIyBkZWItc3JjIGh0dHBzOi8vbWlycm9ycy50dW5hLnRzaW5naHVhLmVkdS5jbi9kZWJpYW4vIGJvb2t3b3JtLXVwZGF0ZXMgbWFpbiBjb250cmliIG5vbi1mcmVlIG5vbi1mcmVlLWZpcm13YXJlCgpkZWIgaHR0cHM6Ly9taXJyb3JzLnR1bmEudHNpbmdodWEuZWR1LmNuL2RlYmlhbi8gYm9va3dvcm0tYmFja3BvcnRzIG1haW4gY29udHJpYiBub24tZnJlZSBub24tZnJlZS1maXJtd2FyZQojIGRlYi1zcmMgaHR0cHM6Ly9taXJyb3JzLnR1bmEudHNpbmdodWEuZWR1LmNuL2RlYmlhbi8gYm9va3dvcm0tYmFja3BvcnRzIG1haW4gY29udHJpYiBub24tZnJlZSBub24tZnJlZS1maXJtd2FyZQoKIyBkZWIgaHR0cHM6Ly9taXJyb3JzLnR1bmEudHNpbmdodWEuZWR1LmNuL2RlYmlhbi1zZWN1cml0eSBib29rd29ybS1zZWN1cml0eSBtYWluIGNvbnRyaWIgbm9uLWZyZWUgbm9uLWZyZWUtZmlybXdhcmUKIyAjIGRlYi1zcmMgaHR0cHM6Ly9taXJyb3JzLnR1bmEudHNpbmdodWEuZWR1LmNuL2RlYmlhbi1zZWN1cml0eSBib29rd29ybS1zZWN1cml0eSBtYWluIGNvbnRyaWIgbm9uLWZyZWUgbm9uLWZyZWUtZmlybXdhcmUKCmRlYiBodHRwczovL3NlY3VyaXR5LmRlYmlhbi5vcmcvZGViaWFuLXNlY3VyaXR5IGJvb2t3b3JtLXNlY3VyaXR5IG1haW4gY29udHJpYiBub24tZnJlZSBub24tZnJlZS1maXJtd2FyZQojIGRlYi1zcmMgaHR0cHM6Ly9zZWN1cml0eS5kZWJpYW4ub3JnL2RlYmlhbi1zZWN1cml0eSBib29rd29ybS1zZWN1cml0eSBtYWluIGNvbnRyaWIgbm9uLWZyZWUgbm9uLWZyZWUtZmlybXdhcmUKCg=="
            source_file="/etc/apt/sources.list"
            if [ -f "${source_file}.`date +%Y%m%d`" ] ; then
                echo "${source_file}.`date +%Y%m%d` 文件已经存在!"
            else
                echo "备份 ${source_file} 文件!"
                sudo mv $source_file ${source_file}.`date +%Y%m%d`
            fi
            # Unstable version return
            [[ "$os_codename" == "sid" ]]  &&  sudo sh -c "echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free non-free-firmware' > $source_file" && return 0

            # Stable version and Testing preview version
            sudo sh -c "echo $source_data | base64 -d > $source_file"
            if [ "$os_codename" != "bookworm" ] ; then
                sudo sed -i "s/bookworm/$os_codename/g" $source_file
            fi
            [[ "$os_codename" == "bullseye" ]]  && sudo sed -i "s/ non-free-firmware//g" $source_file
            ;;
        manjaro)
            # 自动测试并选择延迟最低的镜像源地址(通过-c参数选择国家)
            # sudo pacman-mirrors -g -c China
            # 手动根据提示选择镜像源地址
            sudo pacman-mirrors -i -c China -m rank
            # 更新软件源本地缓存
            sudo pacman -Syy
            ;;
        *)
            redr_line "不支持的系统类型!暂时无法支持!"
            return 1
    esac
    loginfo "成功执行 config_source"
}
function config_user() {  # 添加管理员用户
    loginfo "正在执行 config_user"
    prompt "开始配置新用户" || return 1
    read -p "`echo_green 输入用户名称:`" user_name
    [[ "$user_name" = "" ]] && echo "您没有输入的用户名字!" && exit 1

    if [ "$user_pass" = "" ] ; then
        stty -echo
        read -p "请输入 $user_name 用户密码:" user_pass
        echo
        read -p "再次输入 $user_name 用户密码(二次确认):" user_2pass
        echo
        stty echo
        [[ "$user_pass" = "" || "${user_2pass}" = "" ]] && echo "您没有输入的用户密码!" && exit 2
        [[ "$user_pass" != "${user_2pass}" ]] && echo "两次输入密码不一致!" && exit 3
    fi

    default_shell="/usr/bin/zsh"
    [[ ! -x "$default_shell" ]] && default_shell="/bin/bash"  # 没有zsh就使用 bash
    sudo useradd $user_name --home-dir /home/$user_name -c "add by one4all tool" -s $default_shell -p "$user_pass" -g "users"
    sudo mkdir -p /home/$user_name
    sudo chown -R ${user_name}.users /home/$user_name
    #修改用户权限,使用sudo不用输入密码
    read -p "使用sudo命令时是否希望输入密码?(y/n,默认n)" str_answer
    if [ "$str_answer" = "y" -o "$str_answer" = "Y" ] ; then
        echo "您选择了使用sudo时需要 `red 输入密码`(操作更安全)"
    else
        echo "一看您跟我一样，就是个偷懒的人!选择使用sudo时`echo_green 不输入密码`."
        sudo sh -c "echo '$user_name ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/$user_name"
    fi

    read -p "是否为 `red $user_name` 用户设置SSH免密码登录?(y/n,默认n)" str_answer
    [[ "$str_answer" = "n" || "$str_answer" = "N" ]] && echo "您选择了`red 使用密码SSH登录方式`(千万别弄丢了密码!)" && return 1
    echo "一看您跟我一样，就是个偷懒的人! 您选择使用`echo_green SSH免密码认证登录方式`(再也不用输入密码登录了)."

    read -p "输入您的RSA公钥内容(Linux下 `echo_green ~/.ssh/id_rsa.pub` 文件,一行内容):" str_ssh_pub_key
    echo "第一步: 为 $user_name 用户下生成默认的 ssh-rsa 密钥对(无特殊用途,为了生成~/.ssh目录,如果已经有，选择不覆盖即可)!"
    sudo su - $user_name -c 'ssh-keygen -C "$HOST/$USER" -f ~/.ssh/id_rsa -b 2048 -t rsa -q -N ""'
    echo "第二步: 添加刚输入的公钥内容到 `echo_green /home/$user_name/.ssh/authorized_keys` 文件中:"
    auth_file="/home/$user_name/.ssh/authorized_keys"
    [[ "$str_ssh_pub_key" != "" && "${str_ssh_pub_key:0:7}" = "ssh-rsa" ]] \
    && sudo su - $user_name -c  "echo '$str_ssh_pub_key' >> $auth_file && chmod 0600 $auth_file" \
    && echo "`echo_green 恭喜您` 已经添加公钥成功!"
    loginfo "成功执行 config_user"
}
function config_sudo_nopass() { # 为当前用户配置使用 sudo时不需要输入密码
    grep "NOPASSWD" /etc/sudoers.d/$USER >/dev/null 2>&1 || sudo sh -c "echo '$USER ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/$USER"
}
function config_machine_id() {  # 生成 machine_id 唯一信息(从模板克隆主机时会有相同id情况，导致网络分配识别等问题)
    loginfo "正在执行 config_machine_id"
    prompt "确定重新生成 machine_id(`echo_redr 会影响购买激活的软件`)" || return 1
    white_line "开始生成新的 machine_id :"
    id_file=/etc/machine-id
    loginfo "记录上一次的 machine-id : `cat $id_file`"
    sudo rm -f $id_file
    sudo dbus-uuidgen --ensure=$id_file
    echo "生成 machine_id: `cat $id_file`"
    loginfo "成功执行 config_machine_id, 新的machine-id : `cat $id_file`"
}
function config_hostid() { # 生成 hostid 唯一信息(根据网卡ip生成)
    loginfo "正在执行 config_hostid, 当前 hostid=`hostid`"
    myipv4=`ip a s | awk '/inet / && /global/{ print $2 }'|sed 's/\/.*//g'`
    prompt "请确认是否重新生成hostid" || return 1
    echo -e "当前全局的IPv4地址: ${BG}${myipv4}${NC} ,开始生成 /etc/hostid"
    ip1=`echo ${myipv4} | cut -d. -f1 | xargs printf "%x"`
    ip2=`echo ${myipv4} | cut -d. -f2 | xargs printf "%x"`
    ip3=`echo ${myipv4} | cut -d. -f3 | xargs printf "%x"`
    ip4=`echo ${myipv4} | cut -d. -f4 | xargs printf "%x"`
    # 注意hostid写入的顺序
    sudo sh -c "printf '\x${ip3}\x${ip4}\x${ip1}\x${ip2}' > /etc/hostid"
    echo -e "生成后的hostid : $TC`hostid`$NC"
    loginfo "成功执行 config_hostid, 新hostid=$TC`hostid`$NC"
}

function config_powerline_fonts() {
    loginfo "开始安装 Powerline Font"
    tmp_path=/tmp/fonts
    git clone https://github.com/powerline/fonts.git --depth=1 $tmp_path
    cd $tmp_path && ./install.sh && cd - && rm -rf $tmp_path
    loginfo "完成安装 Powerline Font"
}

function show_menu_config() { # 显示 config 子菜单
    menu_head "配置选项菜单"
    menu_item 1 支持zh_CN.utf-8     # ":支持中文字符集 zh_CN.UTF-8"
    menu_item 2 软件源              # ":更改软件源为国内源(默认清华大学源,支持ipv6且速度快)"
    menu_item 3 启动sshd服务
    menu_item 4 创建用户
    menu_item 5 生成hostid
    menu_item 6 生成machineid
    menu_item 7 配置PowerlineFonts
    menu_item 8 配置sudo无密码确认
    menu_tail
    menu_item q 返回上级菜单
    menu_tail
}
function do_config_all() { # 配置菜单选择
    while true
    do
        show_menu_config
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) config_langpack      ;;
            2) config_source        ;;
            3) config_sshd          ;;
            4) config_user          ;;
            5) config_hostid        ;;
            6) config_machine_id    ;;
            7) config_powerline_fonts ;;
            8) config_sudo_nopass   ;;
            q|"") return 0          ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
########## 显卡相关  #########################################

function download_nvidia_driver() {
    loginfo "正在执行 download_nvidia_driver"
    prompt "开始下载 N卡驱动" || return 1
    command -v jq >/dev/null || sudo $pac_cmd_ins jq
    ! command -v jq >/dev/null && logerr "缺少 jq 工具!" && return 1
    loginfo "您已经安装了 jq 命令: `command -v jq`"
    tmp_json=/tmp/tmp.nvidia.menu.json
    # 下载链接(以 NVIDIA GeForce GTX 1660 SUPER 显卡为例,驱动兼容大部分 GeForce系列)
    dn_url='https://gfwsl.geforce.cn/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=112&pfid=910&osID=12&languageCode=2052&beta=null&isWHQL=0&dltype=-1&dch=0&upCRD=null&qnf=0&sort1=0&numberOfResults=10'
    # 检查文件最后修改时间是否为 15天内 , 是就不重复下载，否则就下载新的json文件
    old_json_file=`find $tmp_json  -type f -mtime -15 2>/dev/null`
    if [ "$old_json_file" = "" ] ; then
        ${curl_cmd} -o $tmp_json $dn_url \
            -H 'authority: gfwsl.geforce.cn' \
            -H 'accept: */*' \
            -H 'accept-language: zh-CN,zh;q=0.9,en;q=0.8,zh-TW;q=0.7' \
            -H 'cache-control: no-cache' \
            -H 'dnt: 1' \
            -H 'origin: https://www.nvidia.cn' \
            -H 'pragma: no-cache' \
            -H 'referer: https://www.nvidia.cn/' \
            -H 'sec-ch-ua: "Google Chrome";v="111", "Not(A:Brand";v="8", "Chromium";v="111"' \
            -H 'sec-ch-ua-mobile: ?0' \
            -H 'sec-ch-ua-platform: "Linux"' \
            -H 'sec-fetch-dest: empty' \
            -H 'sec-fetch-mode: cors' \
            -H 'sec-fetch-site: cross-site' \
            -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36' \
            --compressed
        [[ "$?" != "0" ]] && logerr "获取驱动列表失败!" && return 1
    fi
    file_url=`cat $tmp_json |jq |awk '/DownloadURL/{ print $2 }' | sed -n 's/[",]//g; 1p'`
    file_size=`cat $tmp_json |jq |awk '/DownloadURL/{ print $2 }' | sed -n 's/[",]//g; 2p'`
    loginfo "下载地址: $file_url , 文件大小: $file_size MB"
    tmp_file="/tmp/`basename $file_url`"

    if [ -f "$tmp_file" ] ; then
        echo -e "${RED}提醒： ${tmp_file} 文件已经下载过了!${NC}"
    fi
    prompt "下载Nvidia驱动安装包(文件大小: $file_size )" && ! ${curl_cmd} -o $tmp_file -SL $file_url && logerr "下载Nvidia驱动失败! 检查网络后再试试吧" && return 2

    loginfo "Nvidia驱动保存位置: $tmp_file ."
    menu_head "${RED}提示: 驱动安装方法:${NC}"
    menu_info 1 "设置终端启动 systemctl set-default multi-user"
    menu_info 2 "重启"
    menu_info 3 "登录root用户终端,开始安装 sh $tmp_file"
    menu_info 4 "恢复GUI启动 systemctl set-default graphical"
    menu_info 5 "重启,安装完毕!"
    menu_tail
    loginfo "成功执行 download_nvidia_driver"
}
function show_menu2_cuda() {
    menu_head "选项菜单"
    menu_item 1 "CUDA12.1.1"
    menu_item 2 "CUDA11.8.0"
    menu_item 3 "CUDA11.3.1"
    menu_tail
    menu_item q 返回上级菜单
    menu_tail
}
function download_cuda_toolkit() {
    loginfo "正在执行 download_cuda_toolkit"
    prompt "开始下载 CUDA toolkit" || return 1
    # 为了放置此下载方式被限制，暂时提供固定版本下载链接(按需要人工更新)
    while true; do
        show_menu2_cuda
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) dn_url="https://developer.download.nvidia.com/compute/cuda/12.1.1/local_installers/cuda_12.1.1_530.30.02_linux.run"   ;;
            2) dn_url="https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run"   ;;
            3) dn_url="https://developer.download.nvidia.com/compute/cuda/11.3.1/local_installers/cuda_11.3.1_465.19.01_linux.run"   ;;

            q|"") return 0              ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
        [[ "$dn_url" != "" ]] && break
    done
    tmp_file="/tmp/`basename $dn_url`"
    old_file=`find $tmp_file  -type f -mtime -15 2>/dev/null`
    if [ "$old_file" = "" ] ; then
        ${curl_cmd} -o $tmp_file $dn_url
        [[ "$?" != "0" ]] && logerr "获取驱动列表失败!" && return 1
        loginfo "下载文件 $tmp_file 成功!"
    else
        loginfo "$tmp_file 文件已经下载过了"
    fi
    menu_head "${RED}安装提醒${NC}" "安装方法与显卡驱动安装过程一致,${RED}重启至终端下安装${NC}."
    loginfo "成功执行 download_cuda_toolkit"
}
function show_menu_graphics() {
    menu_head "选项菜单"
    menu_item 1 下载N卡GeForce系列驱动
    menu_item 2 "下载N卡CUDA安装包"
    menu_tail
    menu_item q 返回上级菜单
    menu_tail
}
function do_graphics_all() {
    while true; do
        show_menu_graphics
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) download_nvidia_driver   ;;
            2) download_cuda_toolkit    ;;

            q|"") return 0              ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
########## 开发环境 install_develop ##########################
function install_sdwebui() {
    loginfo "开始执行 install_sdwebui, 安装源: https://github.com/AUTOMATIC1111/stable-diffusion-webui"
    menu_head "stable-diffusion-webui ${BG}安装前提${NC}"
    menu_iteml Python3 "(推荐 3.10 以上)"
    menu_iteml 显存要求 4GB以上,入门推荐GTX1660S
    menu_tail
    menu_head "运行环境检查结果:"
    menu_iteml "Python3" `python3 --version`
    if command -v nvidia-smi > /dev/null; then
        menu_iteml "Nvidia型号" `nvidia-smi -q | awk -F: '/Product Name/{print $2 }'`
        menu_iteml "Nvidia显存" `nvidia-smi -q | grep -A4 'FB Memory Usage' | awk '/Total/{print $3 }'` "MB"
    fi
    menu_tail
    id_like=`awk -F= '/^ID_LIKE/{ print $2 }' /etc/os-release|sed 's/\"//g'`
    command -v python3 >/dev/null || sudo ${pac_cmd_ins} python3 wget git && loginfo "自动安装python3环境完成." && [[ "$id_like" = "debian" ]] &&  sudo ${pac_cmd_ins} python3-venv
    
    pyver="`python3 --version| cut -d. -f2`"
    [[ "$pyver" -lt "10" ]] && logerr "当前Python3版本过低,建议使用Python 3.10以上" && return 1

    prompt "开始安装 stable-diffusion-webui" || return 1
    default_path="$HOME/stable-diffusion-webui"
    read -p "设置安装目录(默认：`echo_greenr ${default_path}`) ${PMT} " install_path
    if [ "$install_path" = "" ] ; then
        loginfo "已选择默认安装目录:${default_path}"
        install_path=$default_path
    fi
    if [ ! -d "$install_path" ] ; then
        [[ ! -d "`dirname $install_path`" ]] && logerr "$install_path 上级目录不存在,请检查后重新设置" && return 1
        loginfo "安装路径 $install_path 检查正常!"
    else
        logerr "目录 $install_path 已经存在,确保目录不存在以免错误设置覆盖数据!" && return 2
    fi
    # 安装前检查磁盘空间
    reserve_size="10240" # 10GB预留(训练模型文件占用更多空间),可以分离模型目录与安装环境
    disk_check_usage `dirname ${install_path}` $reserve_size
    [[ "$?" != "0" ]] && return 4

    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git $install_path
    [[ "$?" != "0" ]] && logerr "下载代码出错了" && return 5
    
    cd $install_path
    # export COMMANDLINE_ARGS="--xformers --lowvram --no-half-vae --no-half --device-id 0 --api --cors-allow-origins=* --allow-code"
    loginfo "设置 启动参数(低显存,加载时间略长)"
    echo 'export COMMANDLINE_ARGS=${COMMANDLINE_ARGS} --xformers --lowvram --no-half-vae --no-half' >> ./webui-user.sh
    ./webui.sh
    loginfo "成功执行 install_sdwebui"
}

function install_elasticsearch() {
    es_url="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.7.1-linux-x86_64.tar.gz"
    es_sha512="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.7.1-linux-x86_64.tar.gz.sha512"
    install_path="${1:-.}"       # 默认安装路径
    prompt "开始安装 Elasticsearch..." || return 1

    read -p "请输入安装目录(默认安装位置：${install_path}):" str_path
    [[ "$str_path" != "" ]] || install_path=$str_path
    [[ ! -d "$install_path" ]] && ! mkdir $install_path && loginfo "目录创建失败!" && return 1
    es_path="${install_path}/elasticsearch-8.7.1/"
    [[ -d "$es_path" ]] && loginfo "已经安装过了!" && return 1

    tmp_dir="/tmp"
    filename="`basename $es_url`"
    curl -C - -o ${tmp_dir}/$filename ${es_url}
    filesha512="`basename $es_sha512`"
    curl -o ${tmp_dir}/${filesha512} ${es_sha512} && shasum -a 512 -c ${filesha512}
    [[ "$?" != "0" ]] && loginfo " sha512 签名验证失败" && return 1
    
    tar axvf ${tmp_dir}/${filename} -C $install_path  &&  loginfo "解压缩 $filename 文件到 $install_path 目录成功"
    cd $es_path
    [[ "$?" != "0" ]] && echo "安装失败! 安装目录: $es_path" && return 1
    loginfo "成功安装目录: $es_path"
    loginfo "使用前请设置 环境变量(添加到 ~/.bashrc 文件): "
    loginfo " export ES_HOME=$es_path "
    loginfo " export ES_JAVA_OPTS=\"-Xms512m -Xmx512m\""
    loginfo "运行命令:   \$ES_HOME/bin/elasticsearch -d -p /tmp/myes.pid"
    loginfo "停止命令:   pkill -F /tmp/myes.pid"
    loginfo "配置文件:   \$ES_HOME/config/elasticsearch.yml"
    loginfo "配置 /etc/sysctl.conf"
    # 配置 简单的配置
    es_yml_file="$ES_HOME/config/elasticsearch.yml"
    loginfo "配置 $es_yml_file"
    cp -p $es_yml_file "${es_yml_file}.bak"
    es_yml_data="bm9kZS5uYW1lOiAibm9kZTEwIgpwYXRoOgogIGRhdGE6IC9lczAxL2RhdGEKICBsb2dzOiAvZXMwMS9sb2cKICByZXBvOiAvYmFrMDEvcmVwbwoKbmV0d29yay5ob3N0OiAwLjAuMC4wCmh0dHAucG9ydDogOTIwMAoKYWN0aW9uLmRlc3RydWN0aXZlX3JlcXVpcmVzX25hbWU6IHRydWUKYm9vdHN0cmFwLm1lbW9yeV9sb2NrOiB0cnVlCmluZGljZXMuZmllbGRkYXRhLmNhY2hlLnNpemU6ICAxMCUKCiMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBCRUdJTiBTRUNVUklUWSBBVVRPIENPTkZJR1VSQVRJT04gLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KIwojIFRoZSBmb2xsb3dpbmcgc2V0dGluZ3MsIFRMUyBjZXJ0aWZpY2F0ZXMsIGFuZCBrZXlzIGhhdmUgYmVlbiBhdXRvbWF0aWNhbGx5ICAgICAgCiMgZ2VuZXJhdGVkIHRvIGNvbmZpZ3VyZSBFbGFzdGljc2VhcmNoIHNlY3VyaXR5IGZlYXR1cmVzIG9uIDE3LTA5LTIwMjIgMjM6MzM6MDgKIwojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIEVuYWJsZSBzZWN1cml0eSBmZWF0dXJlcwp4cGFjay5zZWN1cml0eS5lbmFibGVkOiBmYWxzZQoKeHBhY2suc2VjdXJpdHkuZW5yb2xsbWVudC5lbmFibGVkOiBmYWxzZQoKIyBFbmFibGUgZW5jcnlwdGlvbiBmb3IgSFRUUCBBUEkgY2xpZW50IGNvbm5lY3Rpb25zLCBzdWNoIGFzIEtpYmFuYSwgTG9nc3Rhc2gsIGFuZCBBZ2VudHMKeHBhY2suc2VjdXJpdHkuaHR0cC5zc2w6CiAgZW5hYmxlZDogdHJ1ZQogIGtleXN0b3JlLnBhdGg6IGNlcnRzL2h0dHAucDEyCgojIEVuYWJsZSBlbmNyeXB0aW9uIGFuZCBtdXR1YWwgYXV0aGVudGljYXRpb24gYmV0d2VlbiBjbHVzdGVyIG5vZGVzCnhwYWNrLnNlY3VyaXR5LnRyYW5zcG9ydC5zc2w6CiAgZW5hYmxlZDogdHJ1ZQogIHZlcmlmaWNhdGlvbl9tb2RlOiBjZXJ0aWZpY2F0ZQogIGtleXN0b3JlLnBhdGg6IGNlcnRzL3RyYW5zcG9ydC5wMTIKICB0cnVzdHN0b3JlLnBhdGg6IGNlcnRzL3RyYW5zcG9ydC5wMTIKIyBDcmVhdGUgYSBuZXcgY2x1c3RlciB3aXRoIHRoZSBjdXJyZW50IG5vZGUgb25seQojIEFkZGl0aW9uYWwgbm9kZXMgY2FuIHN0aWxsIGpvaW4gdGhlIGNsdXN0ZXIgbGF0ZXIKY2x1c3Rlci5pbml0aWFsX21hc3Rlcl9ub2RlczogWyJub2RlMTAiXQoKIy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIEVORCBTRUNVUklUWSBBVVRPIENPTkZJR1VSQVRJT04gLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoK"
    echo -n "$es_yml_data" | base64 -d  > ${es_yml_file}
    
    loginfo "配置 /etc/sysctl.conf"
    sysctl_data="CmZzLmlub3RpZnkubWF4X3VzZXJfaW5zdGFuY2VzPTIwNDgKZnMuaW5vdGlmeS5tYXhfdXNlcl93YXRjaGVzPTE1NTM1MAp2bS5tYXhfbWFwX2NvdW50PTQ2MjE0NAp2bS5taW5fZnJlZV9rYnl0ZXM9NTQ4NTc2CnZtLm92ZXJjb21taXRfbWVtb3J5ID0gMQo="
    sudo sh -c "echo -n $sysctl_data | base64 -d >> /etc/sysctl.conf"
    # 用户limit配置
    uname=`whoami`
    limit_file=/etc/security/limits.d/${uname}.conf
    loginfo "配置 $limit_file"
    sudo sh -c "echo $uname soft memlock unlimited >> ${limit_file}"
    sudo sh -c "echo $uname hard memlock unlimited >> ${limit_file}"
    loginfo "配置 Elasticsearch 完成!"
}
function install_kibana() {
    es_url="https://artifacts.elastic.co/downloads/kibana/kibana-8.7.1-linux-x86_64.tar.gz"
    es_sha512="https://artifacts.elastic.co/downloads/kibana/kibana-8.7.1-linux-x86_64.tar.gz.sha512"

    install_path="${1:-.}"       # 默认安装路径
    prompt "开始安装 Kibana...(默认安装位置为： ${install_path})"
    if [ "$?" != "0" ] ; then
        read -p "请输入安装目录:" install_path
    fi
    es_path="${install_path}/kibana-8.7.1/"
    [[ ! -d "$install_path" ]] && ! mkdir $install_path && loginfo "目录创建失败!" && return 1
    [[ -d "$es_path" ]] && loginfo "已经安装过了!" && return 1

    tmp_dir="/tmp"
    filename="`basename $es_url`"
    curl -C - -o ${tmp_dir}/$filename ${es_url}
    filesha512="`basename $es_sha512`"
    curl -o ${tmp_dir}/${filesha512} ${es_sha512} && shasum -a 512 -c ${filesha512}
    [[ "$?" != "0" ]] && loginfo " sha512 签名验证失败" && return 1
    
    tar axvf ${tmp_dir}/${filename} -C $install_path  &&  loginfo "解压缩 $filename 文件到 $install_path 目录成功"
    cd $es_path
    [[ "$?" != "0" ]] && echo "安装失败! 安装目录: $es_path" && return 1
    loginfo "成功安装目录: $es_path"
    loginfo "使用前请设置 环境变量(添加到 ~/.bashrc 文件): "
    loginfo " export KIBANA_HOME=$es_path "
    loginfo "运行命令:   \$KIBANA_HOME/bin/kibana"
    loginfo "配置文件:   \$KIBANA_HOME/config/kibana.yml"
    loginfo "配置 Elasticsearch 完成!"
}
function install_nodejs() {
    nodejs_type="${1:-LTS}"   # nodejs 类型 LTS 或 latest最新版
    loginfo "正在执行 install_nodejs"
    command -v node && loginfo "已经安装了 nodejs 环境 :`node -v`" && return 0
    prompt "开始安装 nodejs环境" || return 1
    read -p "设置安装位置(比如 /devel 目录,自动创建子目录nodejs):" str_outpath
    [[ -d "$str_outpath" ]]  || return 2

    read -p "选择安装版本(16/18/20/latest,回车默认latest)" nodejs_ver
    ver_url="https://nodejs.org/download/release/latest-v${nodejs_ver}.x/"
    [[ "$nodejs_ver" == "" || "$nodejs_ver" == "latest" ]] && ver_url="https://nodejs.org/download/release/latest"
    [[ "$nodejs_ver" == "" || "$nodejs_ver" == "latest" ]] || [[ "$nodejs_ver" -gt "0" || "$nodejs_ver" -lt "100" ]] || return 3
    tarfile=`${curl_cmd} -L $ver_url  | grep "linux-x64.tar.xz"|awk -F"href=\"" '{ print $2 }' | awk -F"\"" '{print $1}'`
    [[ "$tarfile" == "" ]] && loginfo "没找到 v${nodejs_ver} 版本 nodejs" && return 3

    dn_url="$ver_url/$tarfile"
    tmp_path=/tmp
    outfile="`echo $tarfile | sed 's/.tar.xz//g'`"
    tmp_file="$tmp_path/$tarfile"
    ${curl_cmd} -o $tmp_file -L $dn_url || return 1
    tar axvf $tmp_file -C ${str_outpath}
    # 创建软链接
    dst_dir="node_v${nodejs_ver}"
    [[ -e "${str_outpath}/${dst_dir}" ]] || ( cd ${str_outpath} && ln -sf ${outfile} ${dst_dir} && cd - )
    env_path="${str_outpath}/${dst_dir}/bin:\$PATH"
    loginfo "手工设置环境变量:  export PATH=$env_path"
    for rcfile in ~/.zshrc ~/.bashrc
    do
        if [ -f "$rcfile" ] ; then
            grep "${str_outpath}/${dst_dir}/bin" $rcfile || echo "export PATH=$env_path" >> $rcfile
        fi
    done
    loginfo "成功执行 install_nodejs"
}

function install_golang() {
    loginfo "开始执行 install_golang"
    command -v go && loginfo "已经安装了 go语言开发环境 :`go version`" && return 0
    prompt "开始安装 go语言开发环境" || return 1
    read -p "设置安装位置(比如 /devel 目录,自动创建子目录go):" str_outpath
    [[ -d "$str_outpath" ]]  || return 2

    ver_url="https://go.dev/dl/?mode=json"
    tarfile=`${curl_cmd} $ver_url | grep linux-amd64.tar.gz|head -1| awk -F"\"" '{ print $4 }'`

    dn_url="https://go.dev/dl/$tarfile"
    tmp_path=/tmp
    outfile="`echo $tarfile | sed 's/.tar.gz//g'`"
    tmp_file="$tmp_path/$tarfile"
    ${curl_cmd} -o $tmp_file -L $dn_url || return 1
    tar axvf $tmp_file -C ${str_outpath}
    # 创建软链接
    dst_dir="go"
    [[ -e "${str_outpath}/${dst_dir}" ]] || ( cd ${str_outpath} && ln -sf ${outfile} ${dst_dir} && cd - )
    read -p "设置GOPATH(Go代码开发路径): " str_gopath
    env_path="${str_outpath}/${dst_dir}/bin:\$PATH"
    if [ "$str_gopath" != "" ] ; then
        [[ -d "$str_gopath" ]] && loginfo " GOPATH=$str_gopath 已经存在了" && return 1
        mkdir $str_gopath
        [[ "$?" != "0" ]] && loginfo "$str_gopath 目录创建失败!" && return 2
        env_path="$str_gopath/bin:${str_outpath}/${dst_dir}/bin:\$PATH"
    fi
    for rcfile in ~/.zshrc ~/.bashrc
    do
        if [ -f "$rcfile" ] ; then
            grep "${str_outpath}/${dst_dir}/bin" $rcfile || echo "export PATH=$env_path" >> $rcfile
            mkdir -p ~/.config/go
            echo "GOPATH=$str_gopath" > ~/.config/go/env
        fi
    done
    loginfo "成功执行 install_golang"
}
function show_menu_develop() {
    menu_head "选项菜单"
    menu_item 1 stable-diffusion-webui
    menu_item 2 Node.js-JavaScript
    menu_item 3 GoLang
    menu_item 4 安装Elasticsearch
    menu_item 5 安装Kibana
    menu_tail
    menu_item q 返回上级菜单
    menu_tail
}
function do_develop_all() {
    while true
    do
        show_menu_develop
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) install_sdwebui      ;;
            2) install_nodejs       ;;
            3) install_golang       ;;
            4) install_elasticsearch ;;
            5) install_kibana  ;;

            q|"") return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
function show_menu_main() {
    menu_head "安装选项菜单"
    menu_item 1 安装命令工具
    menu_item 2 安装图形界面工具
    menu_item 3 安装编程开发环境
    menu_tail
    menu_item c 配置终端环境
    menu_item d 配置桌面主题
    menu_item g 安装显卡相关
    menu_tail
    menu_item u "${TC}U${NC}pdate更新"
    menu_item q 退出
    menu_tail
}
function start_main(){
    while true
    do
        show_menu_main
        read -r -n 1 -e  -p "`echo_greenr 请选择:`${PMT} " str_answer
        case "$str_answer" in
            1) do_install_all   ;;  # 终端命令安装
            2) do_install_gui   ;;  # 图形工具相关安装
            3) do_develop_all   ;;  # 开发编程相关安装配置

            c) do_config_all    ;;  # 终端环境配置
            d) do_desktop_all   ;;  # 桌面环境配置工作(主题/图标等)
            g) do_graphics_all  ;;  # 显卡相关安装配置

            u)
                install_path="$0"
                tmp_path="/tmp/tmp.one4all.sh"
                echo "安装位置: $tmp_path"
                update_url="https://raw.githubusercontent.com/switchToLinux/one4all/main/scripts/one4all.sh"
                ${curl_cmd} -o $tmp_path -SL $update_url
                [[ "$?" != "0" ]] && logerr "抱歉！ $install_path 命令更新失败了!" && return 1
                mv $install_path ${install_path}.bak && mv $tmp_path $install_path && chmod +x $install_path
                loginfo "$install_path 命令更新完毕! ${BG}退出后请重新执行此命令${NC}."
                exit 0
            ;;
            q|"") return 0         ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}

####### Main process #################################
check_term
menu_head "$WELCOME"
check_sys       # 检查系统信息
check_basic     # 基础依赖命令检测与安装

if [ "$#" -ge 0 ]; then  # 无参数情况:进入菜单选择
    start_main
else  # 命令执行模式(执行后退出)
    command="$1"
    case "$command" in
        ana*)
            install_anaconda ;;
        ohmyzsh)
            install_ohmyzsh ;;
        lang)
            config_langpack ;;
    esac
fi

menu_head "${SEE_YOU}"
