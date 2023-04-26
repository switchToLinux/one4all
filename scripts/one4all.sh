#!/bin/bash
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

#### 默认选项 #####
default_confirm="no"    # 是否提示确认，no-提示，yes-自动选择yes
python_install_path="$HOME/anaconda3"       # Python3 默认安装路径
PMT=">>>"

os_type=""          # Linux操作系统分支类型
os_version=""       # Linux系统版本号
os_codename=""      # Linux的Codename
pac_cmd=""          # 包管理命令
pac_cmd_ins=""      # 包管理命令
cpu_arch=""         # CPU架构类型，仅支持x86_64


########### 文字显示颜色输出函数 ######
function echo_white()  { printf "\033[0;37m$@\033[0m"     ; }
function echo_whiter() { printf "\033[0;37;7m$@\033[0m"   ; }
function echo_red()    { printf "\033[0;31m$@\033[0m"     ; }
function echo_redr()   { printf "\033[0;31;7m$@\033[0m"   ; }
function echo_green()  { printf "\033[0;32m$@\033[0m"     ; }
function echo_greenr() { printf "\033[0;32;7m$@\033[0m"   ; }
function white_line()  { printf "\033[0;37m$@\033[0m\n"   ; }
function whiter_line() { printf "\033[0;37;7m$@\033[0m\n" ; }
function red_line()    { printf "\033[0;31;1m$@\033[0m\n" ; }
function redr_line()   { printf "\033[0;31;7m$@\033[0m\n" ; }
function green_line()  { printf "\033[0;32;1m$@\033[0m\n" ; }
function greenr_line() { printf "\033[0;32;7m$@\033[0m\n" ; }
function blankln() { white_line "<-------------------------------------------------------------------------->\n" ; }
function menu_item() { white_line "    $@" ; }
function println() { blankln ; menu_item "$@" ; }



########### 运行条件检测 ###########
function prompt() { # 提示确认函数，如果使用 -y 参数默认为Y确认
    msg="$@"
    if [ "$default_confirm" != "yes" ] ; then
        read -p "$msg (y/N)\c" str_answer
        if [ "$str_answer" = "y" -o "$str_answer" = "Y" ] ; then
            echo "已确认"
            return 0
        else
            echo "已取消"
            return 1
        fi
    else
        echo "$msg"
    fi
    return 0
}
# 检查是否有root权限并提示，需要root权限的命令要添加sudo
function check_root() { [[ "`uid -u`" = "0" ]]  && ! prompt "提示:确认在root用户下或者使用sudo运行?" && exit 0 ; }

function check_sys() { # 检查系统发行版信息，获取os_type/os_version/pac_cmd/pac_cmd_ins等变量
    if [ -f /etc/os-release ] ; then
        ID=`awk -F'\"' '/^ID=/{print $2}' /etc/os-release`
        os_version=`awk -F'\"' '/^VERSION_ID=/{print $2}' /etc/os-release`
        os_codename=`awk -F'\"' '/^VERSION_CODENAME=/{print $2}' /etc/os-release`
        case "$ID" in
            centos)  # 仅支持 centos 8 以上，但不加限制，毕竟7用户很少了
                os_type="$ID"
                pac_cmd="yum"
                pac_cmd_ins="$pac_cmd install -y"
                ;;
            opensuse*)
                os_type="suse"
                pac_cmd="zypper"
                pac_cmd_ins="$pac_cmd install -y"
                ;;
            ubuntu|debian)
                os_type="$ID"
                pac_cmd="apt-get"
                pac_cmd_ins="$pac_cmd install -y"
                ;;
            manjaro|arch*)
                os_type="$ID"
                pac_cmd="pacman"
                pac_cmd_ins="$pac_cmd -S --needed --noconfirm "
                ;;
            *)
                os_type="unknown"
                pac_cmd=""
                pac_cmd_ins=""
                ;;
        esac
    fi
    if [ -z "$pac_cmd" ] ; then
        return 1
    fi
    cpu_arch="`uname -m`"
    if [ "$cpu_arch" != "x86_64" ] ; then
        echo "invalid cpu arch:[$cpu_arch]"
        return 2
    fi
    return 0
}

function check_basic() { # 基础依赖命令检测与安装
    which curl >/dev/null || sudo $pac_cmd_ins curl    # 检测 curl 命令
}

############# 安装工具部分 #########################################

function install_anaconda() {
    which anaconda >/dev/null
    if [ "$?" = "0" ] ; then
            echo "Anaconda3 is already installed!"
            return 0
    fi
    # install anaconda python environment
    anaconda_file=`curl -L https://repo.anaconda.com/archive/ | awk -F'\"' '/Linux-x86_64.sh/{print $2}'|head -1`
    
    if [ -f "/tmp/$anaconda_file" ] ; then
        redr_line "文件已经下载过了, 是否重新下载?"
    fi
    prompt "开始下载 Anaconda3... :[/tmp/$anaconda_file], file size : 500MB+"
    if [ "$?" = "0" ] ; then
        curl -o /tmp/$anaconda_file -L https://repo.anaconda.com/archive/$anaconda_file
    fi
    prompt "开始安装 Anaconda3...(默认安装位置为： ${python_install_path})"
    if [ "$?" != "0"] ; then
        read -p "请输入自定义安装目录:" tmp_input
        if [ "$tmp_input" != "" -a  -r `basename $tmp_input` ] ; then
            python_install_path=$tmp_input
        else
            echo "无效目录[$tmp_input]，已经使用默认目录[$python_install_path]安装"
            return 1
        fi
    fi
    sh /tmp/$anaconda_file -p ${python_install_path} -b
    . ${python_install_path}/etc/profile.d/conda.sh
    # 检测当前使用的shell是什么bash/zsh等
    conda init `basename $SHELL`
}
function install_ohmyzsh() {
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    [[ "$?" = "0" ]]  || (redr_line "安装ohmyzsh失败了!! 看看报错信息! 稍后重新安装试试!"  && return 1)
    echo "设置默认主题为: `green agnoster`" && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' $HOME/.zshrc
    echo "设置默认编辑器为 `green vi`:" && echo "set -o vi"  >> $HOME/.zshrc
    echo "`echo_greenr 安装ohmyzsh成功!`重新登录一次即可生效!"
}
function show_menu_install() {
    println "安装选项菜单:"
    menu_item "1. Anaconda3: 安装Anaconda3 Python环境(最新版)"
    menu_item "2. ohmyzsh: 一个令人漂亮的、开源的框架，用于管理 Zsh配置。"
    menu_item "q. 返回上级菜单"
    blankln
}
function do_install_all() { # 安装菜单选择
    while :
    do
        show_menu_install
        read -p "`echo_greenr 请选择:${PMT}`" str_answer
        case "$str_answer" in
            1) install_anaconda  ;;
            2) install_ohmyzsh   ;;
            q) return 0          ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}


############# 基础环境配置部分 ####################################
function config_langpack() {  # 中文语言支持 zh_CN.UTF-8
    
    local_charset="zh_CN.UTF-8" # 字符集名称
    charset_name="zh_CN.utf8"   # Linux系统使用的是没有-的写法(只是写法差别)
    greenr_line "中文语言支持 $local_charset"

    locale -a | grep -Ei "$local_charset|$charset_name" >/dev/null
    if [ "$?" != "0" ] ; then
        case "$os_type" in
            debian|ubuntu*)
                which locale-gen >/dev/null
                if [ "$?" = "0" ] ; then
                    sudo locale-gen $local_charset
                else
                    sudo dpkg-reconfigure locale ;;
                fi
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
    # 修改系统默认字符集(可选)
    # sudo localectl set-locale LANG=$local_name
}
function config_sshd() { # 开启SSH服务
    case "$os_type" in
        manjaro|opensuse*|ubuntu|debian|almalinux|centos)
            sudo systemctl enable --now sshd   ;;
        *)
            redr_line "未知的系统类型!"
            ;;
    esac
}
function config_source() { # 配置软件源为国内源(清华大学源速度更快，支持IPv6)
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
            code_name=`awk -`VERSION_CODENAME
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
}





function show_menu_config() { # 显示 config 子菜单
    println "配置选项菜单:"
    menu_item "1. langpack :支持中文字符集 zh_CN.UTF-8"
    menu_item "2. source   :更改软件源为国内源(默认清华大学源,支持ipv6且速度快)"
    menu_item "3. sshd     :启动 SSH 登录服务"
    menu_item "q. 返回上级菜单"
    blankln
}
function do_config_all() { # 配置菜单选择
    while :
    do
        show_menu_config
        read -p "`echo_greenr 请选择:${PMT}`" str_answer
        case "$str_answer" in
            1) config_langpack  ;;
            2) config_source    ;;
            3) config_sshd      ;;
            q) return 0         ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}


function config_demo() {
    case "$os_type" in
        centos)
            ;;
        opensuse*)
            ;;
        ubuntu|debian)
            ;;
        manjaro|arch*)
            ;;
        *)
            redr_line "不支持的系统类型!暂时无法支持!"
            return 1
    esac
}


function usage(){
    # 使用帮助信息
    echo "Usage:"
    echo "    `basename $0` [-y] [command]   跨平台快速配置工具"
    echo
    echo "Params:"
    echo "   -y : 使用默认yes确认一切，不需要人工交互确认，默认情况下是确认安装的每一个环节"
    echo "support command:"
    echo "    anaconda3     : 安装Anaconda3的Python环境"
    echo "    ohmyzsh       : 安装 ohmyzsh 环境(如果没安装zsh会自动安装)"
    echo
    echo "配置相关命令:"
    echo "    lang          : 配置中文字符集 zh_CN.UTF-8 的支持"
}


function show_menu_main() {
    println "主选项菜单:"
    menu_item "1. install 安装操作"
    menu_item "2. config  配置操作"
    menu_item "q. 退出"
    blankln
}
function start_main(){
    while :
    do
        show_menu_main
        read -p "`echo_greenr 请选择:${PMT}`" str_answer
        case "$str_answer" in
            1) do_install_all  ;;
            2) do_config_all   ;;
            q) return 0          ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}


############ 开始执行入口 ######
# 参数设置：暂时关闭
# while getopts hyb:c: arg_val
# do
#     case "$arg_val" in
#         y)
#             default_confirm="yes"
#             ;;
#         *)
#             usage
#             exit 0
#             ;;
#     esac
# done
# shift $OPTIDX


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

println "欢迎继续使用!"
