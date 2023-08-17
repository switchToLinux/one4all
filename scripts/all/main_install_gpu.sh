#!/usr/bin/env bash

######################################################################
# 文件名: main_install_gpu.sh
# 作者: Awkee
# 创建时间: 2023-07-20
# 描述: 安装配置Linux环境的显卡驱动相关脚本
# 备注: 
#   - 此脚本安装的应用主要为Linux环境配置显卡相关(Nvidia/AMDGPU Driver)
#   - 
######################################################################

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