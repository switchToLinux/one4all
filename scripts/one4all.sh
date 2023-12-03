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
REPO_URL=https://github.com/switchToLinux/one4all

#### 检测当前终端支持色彩
function check_term() {
	# 指定 TERM ，避免对齐问题(已知某些rxvt-unicode终端版本存在对齐问题)
    if [[ "$TERM" == *"256color"* ]] ; then
        echo "支持 256color 修改 TERM信息"
    else
        export TERM=xterm
        export COLORTERM=truecolor
    fi
    echo "当前终端类型: $TERM"
    echo "当前终端色彩: $COLORTERM ,但实际终端支持色彩: `tput colors`"
	echo "提示: 8bit 仅支持8种色彩, truecolor/24bit 支持更多色彩"
}


function check_sys() { # 检查系统发行版信息，获取os_type/os_version/pac_cmd/pac_cmd_ins等变量
    if [ -f /etc/os-release ] ; then
        ID=`awk -F= '/^ID=/{print $2}' /etc/os-release|sed 's/\"//g'`
        os_version=`awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release|sed 's/\"//g'`
        os_codename=`awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release|sed 's/\"//g'`
        case "$ID" in
            centos|fedora)  # 仅支持 centos 8 以上，但不加限制，毕竟7用户很少了
                os_type="$ID"
                pac_cmd="dnf"
                pac_cmd_ins="$pac_cmd install -y"
                ;;
            opensuse*)
                os_type="$ID"
                pac_cmd="zypper"
                pac_cmd_ins="$pac_cmd install "
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
    case "$XDG_CURRENT_DESKTOP" in
        KDE|GNOME|XFCE)
            gui_type="$XDG_CURRENT_DESKTOP"
            ;;
        *)
            gui_type=""
            [[ "$$XDG_CURRENT_DESKTOP" == "" ]] && logerr "您当前会话类型为[$XDG_SESSION_TYPE] 非图形界面下运行"
            [[ "$$XDG_CURRENT_DESKTOP" != "" ]] && loginfo "unknown desktop type: $XDG_CURRENT_DESKTOP"
            ;;
    esac
    cpu_arch="`uname -m`"
    loginfo "${BG}系统${NC}:$os_type $os_version $cpu_arch"
    loginfo "${BG}桌面${NC}:$gui_type,${BG}包管理命令${NC}:$pac_cmd"
    if [ -z "$pac_cmd" ] ; then
        return 1
    fi
    if [ "$cpu_arch" != "x86_64" ] ; then
        echo "invalid cpu arch:[$cpu_arch]"
        return 2
    fi
    return 0
}


function check_basic() { # 基础依赖命令检测与安装
    command -v curl >/dev/null || sudo $pac_cmd_ins curl     # 检测 curl 命令
    command -v git >/dev/null  || sudo $pac_cmd_ins git      # 检测 git 命令
    command -v chsh >/dev/null || sudo $pac_cmd_ins util-linux-user   # 检测 chsh 命令(fedora)
}

# 导入基础模块 #
# 检测 ${ONECFG}/scripts/all/prompt_functions.sh 是否存在,不存在则git下载
if [[ ! -f ${ONECFG}/scripts/all/prompt_functions.sh ]] ; then
    git clone ${REPO_URL} ${ONECFG} || exit 1
fi

source ${ONECFG}/scripts/all/prompt_functions.sh

# 导入全部功能模块 #
for fn in `ls ${ONECFG}/scripts/all/main_*.sh` ; do
    source ${fn}
done

function update_repo() {
    [[ ! -d ${ONECFG} ]] && echo "出现错误! ${ONECFG} 目录不能存在！" && return 0
    [[ -d ${ONECFG} ]] && cd ${ONECFG} && git pull && return 0
}

# 主菜单显示 #
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
                update_repo
                loginfo "$0 命令更新完毕! ${BG}退出后请重新执行此命令${NC}."
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
