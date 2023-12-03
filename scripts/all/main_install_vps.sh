#!/usr/bin/env bash

######################################################################
# 文件名: main_install_vps.sh
# 作者: Awkee
# 创建时间: 2023-12-03
# 描述: 安装配置Linux环境的服务器相关脚本
# 备注: 
#   - 此脚本安装的应用主要为 VPS 服务器配置/软件及其设置等相关功能
#   - 
######################################################################

########## VPS相关  #########################################
function vps_install_fwctl() {
    sudo cp $ONECFG/server/fwctl /usr/local/bin/
    [[ "$?" = "0" ]] && echo "验证 fwctl 命令:" && fwctl
}

function vps_update_timezone(){
    echo "更新时区为上海地区UTC+0800"
    current_timezone=`timedatectl show |awk -F'=' '/^Timezone/{ print $2 }'`
    [[ "$current_timezone" == "Asia/Shanghai" ]] && echo "已经设置过了!" && return 0
    sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}
function vps_config_nginx_install(){
    loginfo "开始安装nginx"
    sudo $pac_cmd_ins nginx
    loginfo "完成安装nginx"
}

function vps_config_nginx_ipinfo() {
    # 配置nginx提供IP检测功能
    ipinfo_data="cmVhbF9pcF9oZWFkZXIgWC1Gb3J3YXJkZWQtRm9yOwpyZWFsX2lwX3JlY3Vyc2l2ZSAgb247CgpyZXdyaXRlIF4vaXAgIC9pcCBicmVhazsKcmV3cml0ZSBeL215aXAgIC9teWlwIGJyZWFrOwpyZXdyaXRlIF4vanNvbmlwICAvanNvbmlwIGJyZWFrOwoKbG9jYXRpb24gL215aXAgewogICAgIyDov5Tlm57lrqLmiLfnq69JUOWcsOWdgOajgOa1iyAgICByZXR1cm4gMjAwICIkcmVtb3RlX2FkZHIiOwp9CmxvY2F0aW9uIC9pcCB7CiAgICAjIOWuouaIt+err0lQ5Zyw5Z2A5qOA5rWLICAgIHJldHVybiAyMDAgInJlYWxfaXA6ICRyZW1vdGVfYWRkciBYLUZvcndhcmRlZC1Gb3I6ICRwcm94eV9hZGRfeF9mb3J3YXJkZWRfZm9yXG4iOwp9CmxvY2F0aW9uIC9qc29uaXAgewogICAgIyDlrqLmiLfnq69JUOWcsOWdgOajgOa1iyAgICBkZWZhdWx0X3R5cGUgYXBwbGljYXRpb24vanNvbjsKICAgIHJldHVybiAyMDAgICd7ICJzdGF0dXMiOiAwLCAiaXAiOiAiJHJlbW90ZV9hZGRyIiAsICJyZWFsX2lwIjogIiRwcm94eV9hZGRfeF9mb3J3YXJkZWRfZm9yIiB9JzsKfQoK"
    ipfile="/etc/nginx/conf.d/ipinfo.conf"
    sudo sh -c "echo -n $ipinfo_data |base64 -d > $ipfile"

    # 最后检测配置正确性并重新加载配置
    nginx -t || return 1
    [[ `systemctl is-active nginx` == "active" ]] && sudo systemctl reload nginx
}
function show_menu_nginx() {
    menu_head "配置Nginx选项菜单"
    menu_item 1 安装nginx
    menu_item 2 配置IP信息查询功能

    menu_tail
    menu_item q 返回上级菜单
    menu_tail
}

function do_nginx_all() { # 配置菜单选择
    while true
    do
        show_menu_nginx
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) vps_config_nginx_install ;;
            2) vps_config_nginx_ipinfo  ;;
            q) return 0                 ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}

function vps_install_vpsctl() {
    common_install_command vpsctl https://git.io/vpsctl
    [[ "$?" = "0" ]] && echo "验证 vpsctl 命令:" && vpsctl help
}
function show_menu_vps() {
    menu_head "配置选项菜单"
    menu_item 1 fwctl防火墙管理
    menu_item 2 "更新时区+0800"
    menu_item 3 配置nginx

    menu_tail
    menu_item q 返回上级菜单
    menu_tail
}

function do_vps_all() { # 配置菜单选择
    while true
    do
        show_menu_vps
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) vps_install_fwctl    ;;
            2) vps_update_timezone  ;;
            3) do_nginx_all         ;;
            q) return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
