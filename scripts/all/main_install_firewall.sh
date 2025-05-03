#!/usr/bin/env bash
################################
# 防火墙配置脚本工具
################################
# 保存ipset数据
ipset_file=/etc/ipset_all.txt
ipset_new=/etc/ipset_new.txt

# 保存iptables规则(不同的系统默认存放路径并不同，本脚本独立保存到/etc目录)
iptables_file=/etc/iptables_fwctl
ip6tables_file=/etc/ip6tables_fwctl


################################################################################
# 功能函数
################################################################################

init_wlist() {
    echo "初始化 whitelist 黑名单:"
    sudo ipset -! destroy whitelist
    sudo ipset create whitelist hash:net family inet hashsize 1024 maxelem 65536
    ipset create whitelist hash:net family inet hashsize 1024 maxelem 65536 >> ${ipset_new}
}

init_blist() {
    echo "初始化blacklist黑名单:"
    sudo ipset -! destroy blacklist
    sudo ipset create blacklist hash:net family inet hashsize 1024 maxelem 65536
    ipset create blacklist hash:net family inet hashsize 1024 maxelem 65536 >> ${ipset_new}
}

change_city_ip() {
    while true ; do
        read -p "输入希望添加的IP段省份名称(回车默认:全国):" str_prov
        if [ "$str_prov" = "" -o "$str_prov" = "全国" -o "$str_prov" = "国内" ] ; then
            str_prov="中国"
        fi
        ip_url=$(curl -L https://raw.githubusercontent.com/metowolf/iplist/master/docs/cncity.md 2>/dev/null | awk -F '|' '$2~/吉林省/{ print $3 }')
        if [ "$?" != "0" ] ; then
            echo "没找到输入地区IP数据!请换个省份或地区试试!"
        else
            break
        fi
    done
    tmp_file="/tmp/iplist.txt"
    curl -L $ip_url -o $tmp_file
    if [ "$?" != "0" ] ; then
        echo "ERROR: 获取IP数据失败! "
        return 1
    fi
    echo "地区:${str_prov} , IP段数量: $(wc -l $tmp_file)"
    rm -f ${ipset_new}
    init_wlist
    init_blist
    cat $tmp_file  | awk '{printf("add whitelist %s\n", $1);}' >> ${ipset_new}
    # 保留黑名单列表
    sudo ipset save blacklist | grep -v create >> ${ipset_new}
    sudo ipset -! restore < ${ipset_new}
    rm -f ${tmp_file} ${ipset_new}
    echo "IP黑白名单配置完成"
}

firewall_status() {
    echo "白名单IP列表规则:"
    sudo ipset list whitelist
    echo "=============================="
    echo "黑名单IP列表规则:"
    sudo ipset list blacklist
    echo "=============================="
    echo "防火墙IPv4规则:"
    sudo iptables -S
    echo "防火墙IPv6规则:"
    sudo ip6tables -S
    echo "=============================="
    echo "ipset   文件路径: ${ipset_file}"
    echo "iptables文件路径: ${iptables_file}"
    echo "ip6tables文件路径: ${ip6tables_file}"
    echo "=============================="
}

firewall_backup() {
    # 导出防火墙配置规则
    echo "备份 ipset 列表"
    sudo ipset save whitelist > ${ipset_file}.`date +%Y%m%d`
    sudo ipset save blacklist >> ${ipset_file}.`date +%Y%m%d`

    # 导出iptables规则
    echo "备份 iptables 规则"
    iptables-save -f ${iptables_file}.`date +%Y%m%d`
    ip6tables-save -f ${ip6tables_file}.`date +%Y%m%d`

    echo "================================================"
    echo "ipset 规则备份文件: ${ipset_file}.`date +%Y%m%d`"
    echo "iptables 规则备份文件: ${iptables_file}.`date +%Y%m%d`"
    echo "ip6tables 规则备份文件: ${ip6tables_file}.`date +%Y%m%d`"
    echo "================================================"
    echo
}

firewall_save() {
    # 导出防火墙配置规则
    echo "备份 ipset 列表"
    sudo ipset save whitelist > $ipset_file
    sudo ipset save blacklist >> $ipset_file

    # 导出iptables规则
    echo "备份 iptables 规则"
    iptables-save -f ${iptables_file}
    ip6tables-save -f ${ip6tables_file}

    echo "================================================"
    echo "ipset 规则文件: ${ipset_file}"
    echo "iptables 规则文件: ${iptables_file}"
    echo "ip6tables 规则文件: ${ip6tables_file}"
    echo "================================================"
    echo
}

firewall_restore() {
    # 恢复防火墙配置规则
    echo "恢复 ipset 列表"
    sudo ipset -! restore < $ipset_file

    echo "恢复 iptables 防火墙规则"
    iptables-restore $iptables_file
    ip6tables-restore $ip6tables_file
}


firewall_init() {
    # 初始化防火墙配置规则
    firewall_status
    read -p "确定初始化防火墙规则?(回车继续,Ctrl+C取消)" str_answer
    sudo iptables -F
    
    echo "开始初始化ipset,添加国内IP段!"
    change_city_ip
    echo "初始化ipset结束!"

    echo "开始创建iptables防火墙:"

    # echo "关闭 firewalld 服务, 使用 iptables 服务(可能您没使用)"
    systemctl disable --now firewalld.serverce  >/dev/null 2>&1

    echo "安装iptables-service服务"
    if command -v yum >/dev/null ; then
        sudo yum install -y ipset iptables-services
    elif command -v apt >/dev/null ; then
        sudo apt update
        sudo apt remove ufw
        sudo apt install -y ipset iptables iptables-persistent
    elif command -v pacman >/dev/null ; then
        sudo pacman -Sy --needed ipset iptables
    fi

    echo "配置 iptables 防火墙规则:"
    # 允许服务器本机对外访问:允许内部向外发消息
    sudo iptables -I OUTPUT -j ACCEPT
    # 接收内部地址消息
    sudo iptables -A INPUT -s 127.0.0.1 -j ACCEPT

    # 丢弃所有黑名单列表请求数据包
    sudo iptables -A INPUT -m set --match-set blacklist src -p udp -j DROP
    sudo iptables -A INPUT -m set --match-set blacklist src -p tcp -j DROP

    # 放行已建立连接的相关数据
    sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # 开放端口列表示例(一次添加多个端口)
    sudo iptables -A INPUT -p tcp -m multiport --dports 22,443 -j ACCEPT
    # 开放白名单可访问的端口示例
    sudo iptables -A INPUT -p tcp -m set --match-set whitelist src -m multiport --dports 80,443 -j ACCEPT

    # 丢弃所有ICMP协议(不让ping)
    sudo iptables -A FORWARD -p icmp -j DROP
    # 保底规则:丢弃所有(不需要)的请求数据
    sudo iptables -A INPUT -j DROP
    
    echo "完成防火墙初始化配置"
    firewall_save
}

open_port() {
    # 开放TCP端口(任何用户都可以访问，常用于开放HTTP/HTTPS服务)
    port=$1
    sudo iptables -I INPUT -p tcp --dport ${port} -j ACCEPT
}

close_port() {
    # 关闭TCP端口(不再允许用户访问)，针对 open_port添加规则
    sudo iptables -S| grep "dport ${port} "| awk '{ gsub("-A", "-D"); print "iptables "$0 }' | bash
}

add_port() {
    port=$1
    sudo iptables -I INPUT -m set --match-set whitelist src -p tcp --dport ${port} -j ACCEPT
}

add_ip() {
    white_ip=$1
    sudo iptables -I INPUT -s ${white_ip} -j ACCEPT
}

del_port() {
    port=$1
    sudo iptables -S| grep "dport ${port} "| awk '{ gsub("-A", "-D"); print "iptables "$0 }' | bash
}

add_wip() {
    aip="$1"
    sudo ipset add whitelist $aip
}

del_wip() {
    aip="$1"
    sudo ipset del whitelist $aip
}

add_bip() {
    aip="$1"
    sudo ipset add blacklist $aip
}

del_bip() {
    aip="$1"
    sudo ipset del blacklist $aip
}

# 主菜单显示 #
function show_menu_firewall() {
    menu_head "选项菜单"
    menu_item 1 防火墙状态查看
    menu_item 2 防火墙配置保存
    menu_item 3 防火墙配置恢复
    menu_item 4 更换地区白名单
    menu_item 5 增加放行IPv4地址
    menu_item 6 增加放行端口
    menu_item 7 白名单增加IPv4地址
    menu_item 8 白名单增加端口
    menu_tail

    menu_item i 防火墙初始化
    menu_item q 退出
    menu_tail
}

function do_firewall_all(){
    while true
    do
        show_menu_firewall
        read -r -n 1 -e  -p "`echo_greenr 请选择:`${PMT} " str_answer
        case "$str_answer" in
            1) firewall_status   ;;
            2) firewall_save     ;;
            3) firewall_restore  ;;
            4) change_city_ip    ;;
            5) add_ip            ;;
            6) open_port         ;;
            7) add_wip           ;;
            8) add_port          ;;

            i) firewall_init     ;;
            q|"") return 0       ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}

