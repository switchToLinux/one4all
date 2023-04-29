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
PMT=">>>"

os_type=""          # Linux操作系统分支类型
os_version=""       # Linux系统版本号
os_codename=""      # Linux的Codename
pac_cmd=""          # 包管理命令
pac_cmd_ins=""      # 包管理命令
cpu_arch=""         # CPU架构类型，仅支持x86_64

# Define Colors
RED='\e[41m'
NC='\e[0m' # No color
BG='\e[7m' # Highlighting Background color
TC='\e[1m' # Highlighting Text color

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

line_feed="+--------------------------------------------------+"

item_index=0   # 记录菜单选项序号
item_line_count=2   # 每行显示菜单数量
MLEN=80   # 单行最大长度
ILEN=25   # 单个选项长度

function menu_line() { let rlen="$item_line_count * $ILEN + 1" ; echo -en "|$TC $@ $NC" ; tput hpa $rlen ; echo "|" ; }
function menu_head() { echo $line_feed ;   menu_line "$@" ; echo $line_feed ; }
function menu_item() {
    let item_index=$item_index+1
    n=$1
    shift
    let rlen="$item_index * $ILEN + 1"
    echo -en "|  $BG ${n} $NC $@" ; tput hpa $rlen ;
    if [ "$item_index" == "$item_line_count" ] ; then
        echo "|"
        item_index=0
    fi
    
}
function menu_tail() { [[ "$item_index" != "0" ]] && echo "|" ; echo $line_feed ; item_index=0 ; }
function println() { menu_item "$@" ; }


################################################################
#  文本信息设定

# 欢迎和再见提示信息
WELCOME="见到你很高兴！ 开心的一天从这里开始 ^_^"
SEE_YOU="出去晒晒太阳吧! 多运动才能有健康的好身体! ^=^"



########### 运行条件检测 ###########
function prompt() { # 提示确认函数，如果使用 -y 参数默认为Y确认
    msg="$@"
    if [ "$default_confirm" != "yes" ] ; then
        read -r -n 1 -e  -p "$msg (y/N)" str_answer
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
    which curl >/dev/null || sudo $pac_cmd_ins curl     # 检测 curl 命令
    which git >/dev/null || sudo $pac_cmd_ins git       # 检测 git 命令
}
############ 公用模块 #############################################

## 通用的下载安装命令
## 使用方法: common_install_command  cmd_name cmd_url
function common_install_command() {
    str_cmd="$1"   # 命令名称
    str_url="$2"   # 下载命令的地址
    which $str_cmd >/dev/null && whiter_line "$str_cmd 命令已经安装了" && return 1
    read -p "设置安装位置(默认目录:/usr/local/bin):" str_path
    [[ ! -d "$str_path" ]] && echo "$str_path 目录不存在, 使用默认目录 /usr/local/bin :" && str_path="/usr/local/bin"
    $str_file="$str_path/$str_cmd"
    curl -o /tmp/${str_cmd}.tmp -L $str_url
    [[ "$?" != "0" ]] && echo "${RED}下载失败!分析原因后再试吧.${TC}" && return 1
    mv /tmp/${str_cmd}.tmp $str_file && chmod +x $str_file
    if [ "$?" != "0" ] ; then
        sudo mv /tmp/${str_cmd}.tmp $str_file && sudo chmod +x $str_file
    fi
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
    python_install_path="$HOME/anaconda3"       # Python3 默认安装路径
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
    white_line "检测到当前正在使用 `basename $SHELL` Shell环境,为您自动添加Anaconda3的配置信息"
    conda init `basename $SHELL`
    white_line "Anaconda3 安装完成! 当前默认Python版本为:"
    ${python_install_path}/bin/python3 --version
}
function install_ohmyzsh() {
    
    [[ -r "$HOME/.oh-my-zsh" ]] && whiter_line "已经安装过 ohmyzsh 环境了" && return 0
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    [[ "$?" = "0" ]]  || (redr_line "安装ohmyzsh失败了!! 看看报错信息! 稍后重新安装试试!"  && return 1)

    whiter_line "安装Powerline字体"
    # clone
    font_tmp_dir=/tmp/zsh_fonts
    git clone https://github.com/powerline/fonts.git --depth=1 $font_tmp_dir
    # install
    cd $font_tmp_dir && sh ./install.sh && cd - && rm -rf $font_tmp_dir

    echo -e "设置默认主题为: $BG agnoster $NC" && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' $HOME/.zshrc
    echo -e "设置默认编辑器为 $BG vi $NC:" && echo "set -o vi"  >> $HOME/.zshrc
    echo -e "$BG 安装ohmyzsh成功!$NC 重新登录一次即可生效!"
}
function install_tmux() {  # Terminal终端会话管理工具,类似Screen
    which tmux >/dev/null && ! prompt "已经安装过 tmux ，继续安装?" && return 0
    # basic config with plugin
    config_data="CiPorr7nva7liY3nvIDkuLpDdHJsICsgYQojIHNldCAtZyBwcmVmaXggQy1hCiPop6PpmaRDdHJsK2Ig5LiO5YmN57yA55qE5a+55bqU5YWz57O7CiMgdW5iaW5kIEMtYgoKCiPlsIZyIOiuvue9ruS4uuWKoOi9vemFjee9ruaWh+S7tu+8jOW5tuaYvuekuiJyZWxvYWRlZCEi5L+h5oGvCmJpbmQgciBzb3VyY2UtZmlsZSB+Ly50bXV4LmNvbmYgXDsgZGlzcGxheSAiUmVsb2FkZWQhIgoKCgojdXAKYmluZC1rZXkgayBzZWxlY3QtcGFuZSAtVQojZG93bgpiaW5kLWtleSBqIHNlbGVjdC1wYW5lIC1ECiNsZWZ0CmJpbmQta2V5IGggc2VsZWN0LXBhbmUgLUwKI3JpZ2h0CmJpbmQta2V5IGwgc2VsZWN0LXBhbmUgLVIKCiNzZWxlY3QgbGFzdCB3aW5kb3cKYmluZC1rZXkgQy1sIHNlbGVjdC13aW5kb3cgLWwKCiMjIGznmoTnjrDlnKjnmoTnu4TlkIjplK7vvJogQ3RybCt4IGzmmK/liIfmjaLpnaLmnb/vvIxDdHJsK3ggQ3RybCts5YiH5o2i56qX5Y+j77yMQ3RybCts5riF5bGPCgoj5L2/5b2T5YmNcGFuZSDmnIDlpKfljJYKIyB6b29tIHBhbmUgPC0+IHdpbmRvdwojaHR0cDovL3RtdXguc3ZuLnNvdXJjZWZvcmdlLm5ldC92aWV3dmMvdG11eC90cnVuay9leGFtcGxlcy90bXV4LXpvb20uc2gKIyBiaW5kIF56IHJ1biAidG11eC16b29tIgojIwoKI2NvcHktbW9kZSDlsIblv6vmjbfplK7orr7nva7kuLp2aSDmqKHlvI8Kc2V0dyAtZyBtb2RlLWtleXMgdmkKIyBzZXQgc2hlbGwKc2V0IC1nIGRlZmF1bHQtc2hlbGwgL2Jpbi96c2gKCgoKIyBwcmVmaXggKyBJKOWkp+WGmSkgOiDlronoo4Xmj5Lku7YKIyBwcmVmaXggKyBVKOWkp+WGmSkgOiDmm7TmlrDmj5Lku7YKIyBwcmVmaXggKyBhbHQgKyB1IDog5riF55CG5o+S5Lu2KOS4jeWcqHBsdWdpbiBsaXN05LitKQojIHByZWZpeCArIEN0cmwtcyAtIHNhdmUKIyBwcmVmaXggKyBDdHJsLXIgLSByZXN0b3JlCgojIOS8muivneeuoeeQhuaPkuS7tgoKc2V0IC1nIEBwbHVnaW4gJ3RtdXgtcGx1Z2lucy90cG0nCnNldCAtZyBAcGx1Z2luICd0bXV4LXBsdWdpbnMvdG11eC1yZXN1cnJlY3QnCnNldCAtZyBAcGx1Z2luICd0bXV4LXBsdWdpbnMvdG11eC1jb250aW51dW0nCgpzZXQgLWcgQGNvbnRpbnV1bS1zYXZlLWludGVydmFsICcxNScKc2V0IC1nIEBjb250aW51dW0tcmVzdG9yZSAnb24nCnNldCAtZyBAcmVzdXJyZWN0LWNhcHR1cmUtcGFuZS1jb250ZW50cyAnb24nCiMKIyBPdGhlciBjb25maWcgLi4uCgpydW4gLWIgJ34vLnRtdXgvcGx1Z2lucy90cG0vdHBtJwoK"
    whiter_line "开始安装tmux插件"
    # 配置 tmux
    sudo ${pac_cmd_ins} tmux
    mkdir -p $HOME/.tmux/plugins/
    cd $HOME/.tmux/plugins/
    git clone https://github.com/tmux-plugins/tpm.git
    git clone https://github.com/tmux-plugins/tmux-resurrect.git
    git clone https://github.com/tmux-plugins/tmux-continuum.git

    echo $config_data | base64 -d  > $HOME/.tmux.conf
}

function show_menu_install() {
    menu_head "安装选项菜单"
    menu_item 1 Anaconda3
    menu_item 2 ohmyzsh
    menu_item 3 tmux
    menu_item q 返回上级菜单
    menu_tail
}
function do_install_all() { # 安装菜单选择
    while true
    do
        show_menu_install
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) install_anaconda     ;;
            2) install_ohmyzsh      ;;
            3) install_tmux         ;;
            q) return 0             ;;  # 返回上级菜单
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
function config_user() {  # 添加管理员用户
    read -p "`echo_green 输入用户名称:`" user_name
    [[ "$user_name" = "" ]] && echo "您没有输入的用户名字!" && exit 1

    if [ "$user_pass" = "" ] ; then
        stty -echo
        read -p "`echo_green 输入 $user_name 用户密码:`" user_pass
        echo
        read -p "`red 再次输入$user_name用户密码`(二次确认):" user_2pass
        stty echo
        [[ "$user_pass" = "" || "${user_2pass}" = "" ]] && echo "您没有输入的用户密码!" && exit 2
        [[ "$user_pass" != "${user_2pass}" ]] && echo "两次输入密码不一致!" && exit 3
    fi

    default_shell="/usr/bin/zsh"
    [[ ! -f "$default_shell" ]] && default_shell="/bin/bash"  # 没有zsh就使用 bash
    sudo useradd $user_name --home-dir /home/$user_name -c "add by one4all tool" -s $default_shell -p "$user_pass" -g "users"
    #修改用户权限,使用sudo不用输入密码
    read -p "使用sudo命令时是否希望输入密码?(y/n,默认n)" str_answer
    if [ "$str_answer" = "y" -o "$str_answer" = "Y" ] ; then
        echo "您选择了使用sudo时需要 `red 输入密码`(操作更安全)"
    else
        echo "一看您跟我一样，就是个偷懒的人!选择使用sudo时`echo_green 不输入密码`."
        sudo sh -c "echo '$user_name ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
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
}
function config_machine_id() {  # 生成 machine_id 唯一信息(从模板克隆主机时会有相同id情况，导致网络分配识别等问题)
    prompt "确定重新生成 machine_id(${BG}会影响购买激活的软件${NC})"
    if [ "$?" != "0" ] ; then
        echo "已经取消 machine_id 生成任务"
        return 0
    fi
    white_line "开始生成新的 machine_id :"
    id_file=/etc/machine-id
    sudo rm -f $id_file
    sudo dbus-uuidgen --ensure=$id_file
    echo "生成 machine_id: `cat $id_file`"
}
function config_hostid() { # 生成 hostid 唯一信息(根据网卡ip生成)
    myipv4=`ip a s | awk '/inet / && /global/{ print $2 }'|sed 's/\/.*//g'`
    echo -e "当前全局的IPv4地址: ${BG}${myipv4}${NC} ,开始生成 /etc/hostid"
    ip1=`echo ${myipv4} | cut -d. -f1 | xargs printf "%x"`
    ip2=`echo ${myipv4} | cut -d. -f2 | xargs printf "%x"`
    ip3=`echo ${myipv4} | cut -d. -f3 | xargs printf "%x"`
    ip4=`echo ${myipv4} | cut -d. -f4 | xargs printf "%x"`
    # 注意hostid写入的顺序
    sudo sh -c "printf '\x${ip3}\x${ip4}\x${ip1}\x${ip2}' > /etc/hostid"
    echo -e "生成后的hostid : $TC`hostid`$NC"
}


function show_menu_config() { # 显示 config 子菜单
    menu_head "配置选项菜单"
    menu_item 1 支持zh_CN.utf-8     # ":支持中文字符集 zh_CN.UTF-8"
    menu_item 2 软件源              # ":更改软件源为国内源(默认清华大学源,支持ipv6且速度快)"
    menu_item 3 启动sshd服务
    menu_item 4 创建用户
    menu_item 5 生成hostid
    menu_item 6 生成machineid
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
            q) return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
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
    menu_head "主选项菜单"
    menu_item 1 install 安装操作
    menu_item 2 config  配置操作
    menu_item q 退出
    menu_tail
}
function start_main(){
    menu_tail
    menu_head "$TC $WELCOME $NC"
    while true
    do
        show_menu_main
        read -r -n 1 -e  -p "`echo_greenr 请选择:`${PMT} " str_answer
        case "$str_answer" in
            1) do_install_all   ;;
            2) do_config_all    ;;
            q) return 0         ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}


####### Main process #################################

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

menu_head "$TC ${SEE_YOU} $NC"
menu_tail
