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
# 检测 ${ONECFG}/scripts/all/prompt_functions.sh 是否存在,不存在则git下载
if [[ -f ${ONECFG}/scripts/all/prompt_functions.sh ]] ; then
    source ${ONECFG}/scripts/all/prompt_functions.sh
else 
    git clone https://github.com/switchToLinux/one4all.git ${ONECFG}
    source ${ONECFG}/scripts/all/prompts_functions.sh
fi

# 导入全部功能模块 #
for fn in `ls ${ONECFG}/scripts/all/main_*.sh` ; do
    source ${fn}
done


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
