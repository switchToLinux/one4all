#!/usr/bin/env bash

######################################################################
# 文件名: main_install_vps.sh
# 作者: Awkee
# 创建时间: 2023-12-03
# 描述: 安装配置Linux环境的服务器相关脚本
# 备注: 
#   - 此脚本安装的应用主要为 VPS 服务器配置/软件及其设置等相关功能
#   - 依赖安装 iptables-persistent  ipset
######################################################################

########## VPS相关  #########################################

function vps_install_deps() {
    if [[ -z "$pac_cmd_ins" ]]; then
        echo "Error: pac_cmd_ins is not defined"
        exit 1
    fi
    sudo $pac_cmd_ins iptables ipset
}
function vps_install_fwctl() {
    sudo cp $ONECFG/scripts/server/fwctl /usr/local/bin/
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
function vps_install_certbot() {
    loginfo "开始安装 certbot"
    sudo $pac_cmd_ins certbot
    loginfo "完成安装 certbot"
}
function vps_config_https_server() {
    prompt "开始配置 nginx HTTPS 服务" || return 1
    read -p "请输入域名(xxx.com 或 xx.example.com):" domain
    read -p "请输入获取免费HTTPS证书的邮箱:" email

    local nginx_conf_path="/etc/nginx/sites-available/${domain}"
    local nginx_link_path="/etc/nginx/sites-enabled/${domain}"

    if [ -z "$domain" ] || [ -z "$email" ]; then
        echo "Usage: vps_config_https_server <domain> <email>"
        return 1
    fi

    # 检查是否已安装 Certbot 和 Nginx
    if ! command -v certbot > /dev/null 2>&1 ; then
        echo "开始安装 Certbot..."
        sudo $pac_cmd_ins certbot python3-certbot-nginx
    fi

    if ! command -v nginx &> /dev/null; then
        echo "Nginx is not installed. Installing Nginx..."
        sudo $pac_cmd_ins nginx
    fi
    # 使用Certbot获取SSL证书并自动配置Nginx
    echo "Obtaining SSL certificate for ${domain}..."
    sudo certbot --nginx -d ${domain} --email ${email} --agree-tos --no-eff-email

    # 设置自动续约
    echo "Setting up automatic certificate renewal..."
    sudo systemctl enable certbot.timer
    sudo systemctl start certbot.timer

    echo "HTTPS configuration for ${domain} completed!"
}

function show_menu_nginx() {
    menu_head "配置Nginx选项菜单"
    menu_item 1 安装nginx
    menu_item 2 配置IP信息查询功能
    menu_item 3 安装certbot
    menu_item 4 配置HTTPS服务

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
            3) vps_install_certbot ;;
            q) return 0                 ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}

function vps_install_docker() {
    # 安装 Docker
    case "$os_type" in
    debian|ubuntu)
        sudo  ${pac_cmd_ins} docker.io docker-compose
        ;;
    centos|opensuse|fedora|arch|manjaro)
        sudo ${pac_cmd_ins} docker docker-compose
    sudo usermod -aG docker $USER
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "重新登录系统后可以在当前用户下使用docker"
    ;;
    esac
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
    menu_item 4 安装Docker-Compose

    menu_tail
    menu_item q 返回上级菜单
    menu_tail
}


function do_server_all() { # 配置菜单选择
    while true
    do
        show_menu_vps
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) vps_install_deps ; vps_install_fwctl    ;;
            2) vps_update_timezone  ;;
            3) do_nginx_all         ;;
            4) vps_install_docker   ;;
            q|"") return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
