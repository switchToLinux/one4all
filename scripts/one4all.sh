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

export ONECFG=~/.config/one4all
REPO_URL=https://github.com/switchToLinux/one4all

export os_type=""          # Linux操作系统分支类型
export os_version=""       # Linux系统版本号
export os_codename=""      # Linux的Codename
export pac_cmd=""          # 包管理命令
export pac_cmd_ins=""      # 包管理命令
export cpu_arch=""         # CPU架构类型，仅支持x86_64
export gui_type=""         # GUI桌面环境类型


curl_cmd="curl -C - "  # 支持断点继续下载

function check_basic() { # 基础依赖命令检测与安装
    command -v curl >/dev/null || sudo $pac_cmd_ins curl     # 检测 curl 命令
    command -v git >/dev/null  || sudo $pac_cmd_ins git      # 检测 git 命令
    command -v fzf >/dev/null  || sudo $pac_cmd_ins fzf     # 检测 fzf 命令 用于提供选项确认
    command -v chsh >/dev/null || sudo $pac_cmd_ins util-linux-user   # 检测 chsh 命令(fedora)
}


function update_repo() {
    [[ ! -d ${ONECFG} ]] && echo "出现错误! ${ONECFG} 目录不能存在！" && return 0
    [[ -d ${ONECFG} ]] && cd ${ONECFG} && git pull && return 0
}

# 主菜单显示 #
function show_menu_main() {
    menu_head "安装选项菜单"
    menu_item 1 install basic
    menu_item 2 install gui apps
    menu_item 3 install develop tools
    menu_tail
    menu_item c config environment
    menu_item d config desktop
    menu_tail

    menu_item f config firewall
    menu_item v vps server
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

            f) do_firewall_all  ;;  # 防火墙配置
            v) do_server_all    ;;  # 服务器配置
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

check_basic     # 基础依赖命令检测与安装

######### 传递变量给子脚本 ##########
export pac_cmd_ins

# 导入基础模块 #
# 检测 ${ONECFG}/scripts/all/prompt_functions.sh 是否存在,不存在则git下载
if [[ ! -f ${ONECFG}/scripts/all/prompt_functions.sh ]] ; then
    git clone ${REPO_URL} ${ONECFG} || exit 1
fi

source ${ONECFG}/scripts/all/prompt_functions.sh

menu_head "$WELCOME"

check_term
check_sys
[[ "$os_type" == "" || "$os_type" == "unknown" ]] && exit 0


# 导入全部功能模块 #
for fn in `ls ${ONECFG}/scripts/all/main_*.sh` ; do
    menu_iteml "Loading Script:" " `basename ${fn}`"
    source ${fn}
done

start_main
menu_head "${SEE_YOU}"
