#!/usr/bin/env bash

######################################################################
# 文件名: main_install_env.sh
# 作者: Awkee
# 创建时间: 2023-07-20
# 描述: 安装配置Linux环境脚本
# 备注: 
#   - 此脚本安装的应用主要为Linux环境配置相关(支持中文字符集、添加用户等)
#   - 
######################################################################

############# 基础环境配置部分 ####################################
function config_langpack() {  # 中文语言支持 zh_CN.UTF-8
    local_charset="zh_CN.UTF-8" # 字符集名称
    charset_name="zh_CN.utf8"   # Linux系统使用的是没有-的写法(只是写法差别)
    prompt "开始配置中文语言支持 $local_charset" || return 1 
    loginfo "正在执行 config_langpack ,支持 $local_charset 字符集"
    locale -a | grep -Ei "$local_charset|$charset_name" >/dev/null
    if [ "$?" != "0" ] ; then
        case "$os_type" in
            debian|ubuntu*|kali)
                sudo $pac_cmd_ins libc-bin language-pack-zh-hans
                command -v locale-gen >/dev/null || sudo dpkg-reconfigure locale
                ;;
            centos|almalinux|fedora)
                sudo $pac_cmd_ins glibc langpacks-zh_CN.noarch
                ;;
            opensuse*)
                sudo $pac_cmd_ins glibc-common wqy-zenhei-fonts
                ;;
            arch|manjaro)
                sudo $pac_cmd_ins glibc wqy-zenhei
                ;;
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
    sudo locale-gen $local_charset
    shprofile="$HOME/.`basename $SHELL`rc"  # 设置当前SHELL环境配置
    local_name=`locale -a | grep -Ei "$local_charset|$charset_name"`
    [[ -f "$shprofile" ]] && echo export LC_ALL="$local_name" >> ${shprofile}
    echo "在当前SHELL环境下执行  export LC_ALL=$local_name  立即生效."
    loginfo "成功执行 config_langpack ."
}
function config_sshd() { # 开启SSH服务
    loginfo "正在执行 config_sshd"
    prompt "开始启动SSHD服务" || return 1
    case "$os_type" in
        manjaro|opensuse*|ubuntu|debian|almalinux|centos)
            service_enable_start "sshd"
            ;;
        *)
            redr_line "未知的系统类型! os_type:$os_type"
            ;;
    esac
    loginfo "成功执行 config_sshd"
}
function config_source() { # 配置软件源为国内源(清华大学源速度更快，支持IPv6)
    loginfo "正在执行 config_source"
    prompt "开始配置软件源为国内(清华大学源)" || return 1
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
        kali)
            sudo sed -i "s@http://http.kali.org/kali@https://mirrors.tuna.tsinghua.edu.cn/kali@g" /etc/apt/sources.list
            ;;
        manjaro)
            # 自动测试并选择延迟最低的镜像源地址(通过-c参数选择国家)
            # sudo pacman-mirrors -g -c China
            # 手动根据提示选择镜像源地址
            sudo pacman-mirrors -i -c China -m rank
            # 更新软件源本地缓存
            sudo pacman -Syyu
            ;;
        arch)
            mirror_file="/etc/pacman.d/mirrorlist"
            sudo cp $mirror_file ${mirror_file}.bak
            sudo sh -c 'echo "Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch" > $mirror_file'
            sudo pacman -Syyu
        *)
            redr_line "不支持的系统类型!暂时无法支持!"
            return 1
    esac
    loginfo "成功执行 config_source"
}
function config_user() {  # 添加管理员用户
    loginfo "正在执行 config_user"
    prompt "开始配置新用户" || return 1
    read -p "`echo_green 输入用户名称:`" user_name
    [[ "$user_name" = "" ]] && echo "您没有输入的用户名字!" && exit 1

    if [ "$user_pass" = "" ] ; then
        stty -echo
        read -p "请输入 $user_name 用户密码:" user_pass
        echo
        read -p "再次输入 $user_name 用户密码(二次确认):" user_2pass
        echo
        stty echo
        [[ "$user_pass" = "" || "${user_2pass}" = "" ]] && echo "您没有输入的用户密码!" && exit 2
        [[ "$user_pass" != "${user_2pass}" ]] && echo "两次输入密码不一致!" && exit 3
    fi

    default_shell="/usr/bin/zsh"
    [[ ! -x "$default_shell" ]] && default_shell="/bin/bash"  # 没有zsh就使用 bash
    sudo useradd $user_name --home-dir /home/$user_name -c "add by one4all tool" -s $default_shell -p "$user_pass" -g "users"
    sudo mkdir -p /home/$user_name
    sudo chown -R ${user_name}.users /home/$user_name
    #修改用户权限,使用sudo不用输入密码
    read -p "使用sudo命令时是否希望输入密码?(y/n,默认n)" str_answer
    if [ "$str_answer" = "y" -o "$str_answer" = "Y" ] ; then
        echo "您选择了使用sudo时需要 `red 输入密码`(操作更安全)"
    else
        echo "一看您跟我一样，就是个偷懒的人!选择使用sudo时`echo_green 不输入密码`."
        sudo sh -c "echo '$user_name ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/$user_name"
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
    loginfo "成功执行 config_user"
}
function config_sudo_nopass() { # 为当前用户配置使用 sudo时不需要输入密码
    grep "NOPASSWD" /etc/sudoers.d/$USER >/dev/null 2>&1 || sudo sh -c "echo '$USER ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/$USER"
}
function config_machine_id() {  # 生成 machine_id 唯一信息(从模板克隆主机时会有相同id情况，导致网络分配识别等问题)
    loginfo "正在执行 config_machine_id"
    prompt "确定重新生成 machine_id(`echo_redr 会影响购买激活的软件`)" || return 1
    white_line "开始生成新的 machine_id :"
    id_file=/etc/machine-id
    loginfo "记录上一次的 machine-id : `cat $id_file`"
    sudo rm -f $id_file
    sudo dbus-uuidgen --ensure=$id_file
    echo "生成 machine_id: `cat $id_file`"
    loginfo "成功执行 config_machine_id, 新的machine-id : `cat $id_file`"
}
function config_hostid() { # 生成 hostid 唯一信息(根据网卡ip生成)
    loginfo "正在执行 config_hostid, 当前 hostid=`hostid`"
    myipv4=`ip a s | awk '/inet / && /global/{ print $2 }'|sed 's/\/.*//g'`
    prompt "请确认是否重新生成hostid" || return 1
    echo -e "当前全局的IPv4地址: ${BG}${myipv4}${NC} ,开始生成 /etc/hostid"
    ip1=`echo ${myipv4} | cut -d. -f1 | xargs printf "%x"`
    ip2=`echo ${myipv4} | cut -d. -f2 | xargs printf "%x"`
    ip3=`echo ${myipv4} | cut -d. -f3 | xargs printf "%x"`
    ip4=`echo ${myipv4} | cut -d. -f4 | xargs printf "%x"`
    # 注意hostid写入的顺序
    sudo sh -c "printf '\x${ip3}\x${ip4}\x${ip1}\x${ip2}' > /etc/hostid"
    echo -e "生成后的hostid : $TC`hostid`$NC"
    loginfo "成功执行 config_hostid, 新hostid=$TC`hostid`$NC"
}

function config_powerline_fonts() {
    loginfo "开始安装 Powerline Font"
    tmp_path=/tmp/fonts
    git clone https://github.com/powerline/fonts.git --depth=1 $tmp_path
    cd $tmp_path && ./install.sh && cd - && rm -rf $tmp_path
    loginfo "完成安装 Powerline Font"
}

function show_menu_config() { # 显示 config 子菜单
    menu_head "配置选项菜单"
    menu_item 1 支持zh_CN.utf-8     # ":支持中文字符集 zh_CN.UTF-8"
    menu_item 2 软件源              # ":更改软件源为国内源(默认清华大学源,支持ipv6且速度快)"
    menu_item 3 启动sshd服务
    menu_item 4 创建用户
    menu_item 5 生成hostid
    menu_item 6 生成machineid
    menu_item 7 配置PowerlineFonts
    menu_item 8 配置sudo无密码确认
    menu_tail
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
            7) config_powerline_fonts ;;
            8) config_sudo_nopass   ;;
            q|"") return 0          ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}