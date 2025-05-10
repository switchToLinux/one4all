#!/usr/bin/env bash

######################################################################
# 文件名: main_install_gui.sh
# 作者: Awkee
# 创建时间: 2023-07-20
# 描述: 安装应用脚本
# 备注: 
#   - 此脚本安装的应用为图形界面软件工具
#   - 
######################################################################

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
    menu_item 4 "CUDA11.2.2"
    menu_item 5 "CUDA11.2.0"
    menu_item 6 "CUDA10.2.0"
    menu_item 7 "CUDA10.1.2"
    menu_tail
    menu_item q Quit 返回
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
            4) dn_url="https://developer.download.nvidia.com/compute/cuda/11.2.2/local_installers/cuda_11.2.2_460.32.03_linux.run"   ;;
            5) dn_url="https://developer.download.nvidia.com/compute/cuda/11.2.0/local_installers/cuda_11.2.0_460.27.04_linux.run"   ;;
            6) dn_url="https://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_linux.run"   ;;
            7) dn_url="https://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.243_418.87.00_linux.run"   ;;

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

function show_menu_gui() {
    menu_head "安装图形工具选项菜单"
    menu_item 1 达芬奇DaVinciResolve18
    menu_item 2 "Xmind(思维导图)"
    menu_item 3 "安装AppImageLauncher"
    menu_item 4 "设置双屏分辨率-dset"
    menu_item 5 "下载Nvidia驱动"
    menu_item 6 "下载CUDA toolkit"

    menu_tail
    menu_item q Quit 返回
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
            4) $ONECFG/scripts/gui/dset  ;;
            q|"") return 0          ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
