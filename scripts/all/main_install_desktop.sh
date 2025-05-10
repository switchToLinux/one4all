
#!/usr/bin/env bash

######################################################################
# 文件名: main_install_desktop.sh
# 作者: Awkee
# 创建时间: 2025-05-10
# 描述: 安装及配置桌面环境(DE/DM)相关脚本,比如安装 kde/gnome/i3wm/sway 等 
######################################################################

############# GUI环境配置部分 ####################################
function kde_theme_switch() {
    # 主题设置
    declare -a theme_namelist
    idx=1
    menu_head "当前系统安装的主题列表："
    for str_item in `lookandfeeltool -l`
    do
        menu_iteml $idx $str_item
        theme_namelist[$idx]="$str_item"
        let idx=$idx+1
    done
    menu_iteml "q" "返回上一级"
    menu_tail
    while true ; do
        read -r -n 1 -e -p "请选择主题序号:" str_answer
        [[ "$str_answer" != "" ]] && [[ "$str_answer" == "q" ]] && return 1
        [[ "$str_answer" != "" ]] && [[ "$str_answer" -gt "0" ]] && [[ "$str_answer" -lt "$idx" ]] && your_theme="${theme_namelist[$str_answer]}" && break
    done
    loginfo "您选择的主题为:$your_theme"
    lookandfeeltool -a $your_theme
    menu_tail
    menu_iteml "提示" "更多设置请使用${BG}系统设置${NC}"
    menu_tail
}
function config_kde_theme() {
    loginfo "正在执行 config_kde_theme"
    prompt "开始配置KDE主题" || return 1 
    sudo $pac_cmd_ins latte-dock
    tmp_path="/tmp/themes"    # 主题下载目录
    mkdir -p $tmp_path
    git clone https://github.com/numixproject/numix-kde-theme.git $tmp_path/numix-kde-theme && cd $tmp_path/numix-kde-theme && make install && cd -
    loginfo "安装全局主题-[Layan-kde]"
    git clone https://github.com/vinceliuice/Layan-kde.git $tmp_path/Layan-kde && cd $tmp_path/Layan-kde && sh ./install.sh && cd -
    loginfo "安装全局主题-[We10XOS-kde]"
    git clone https://github.com/yeyushengfan258/We10XOS-kde.git $tmp_path/We10XOS-kde && cd $tmp_path/We10XOS-kde && sh ./install.sh && cd -
    
    loginfo "安装全局主题-[WhiteSur-kde]"
    git clone https://github.com/vinceliuice/WhiteSur-kde.git  $tmp_path/WhiteSur-kde && cd $tmp_path/WhiteSur-kde && sh ./install.sh && cd -
    cd $tmp_path/WhiteSur-kde/sddm && sudo sh ./install.sh && cd -
    loginfo "安装Icons主题-[WhiteSur-icon-theme]"
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git  $tmp_path/WhiteSur-icon-theme && cd $tmp_path/WhiteSur-icon-theme && sh ./install.sh && cd -
    loginfo "安装主题-[McMojave-circle]"
    git clone https://github.com/vinceliuice/McMojave-circle.git  $tmp_path/McMojave-circle && cd $tmp_path/McMojave-circle && sh ./install.sh --all && cd -
    loginfo "安装GRUB2主题-[grub2-themes]"
    git clone https://github.com/vinceliuice/grub2-themes.git  $tmp_path/grub2-themes && cd $tmp_path/grub2-themes && sudo ./install.sh -b -t whitesur && cd -

    ! command -v lookandfeeltool >/dev/null && sudo $pac_cmd_ins plasma-workspace plasma5-workspace
    ! command -v lookandfeeltool >/dev/null && logerr "lookandfeeltool 安装失败,请手动设置主题" && return 1
    
    kde_theme_switch
    loginfo "成功执行 config_kde_theme"
}
function config_desktop_theme(){
    loginfo "正在执行 config_desktop_theme 安装配置桌面主题"
    prompt "开始安装桌面主题" || return 1
    menu_head "当前桌面环境检查"
    menu_iteml "桌面环境" $gui_type
    menu_iteml "操作系统" $os_type
    menu_tail
    case "$gui_type" in 
        KDE)
            config_kde_theme
            ;;
        *)
            echo "$os_type 系统类型不支持！"
            ;;
    esac
}

function config_i3wm() {
    #配置参考: https://i3wm.org/docs/userguide.html
    loginfo "开始执行 config_i3wm"
    command -v i3config >/dev/null 2>&1 || curl -L -o /tmp/i3config https://raw.githubusercontent.com/switchToLinux/dotfiles/main/i3config
    chmod +x /tmp/i3config && sudo mv ./i3config /usr/local/bin
    menu_head "开始使用 i3config 工具配置 i3wm环境"
    i3config
}
function show_menu_desktop() { # 显示子菜单
    menu_head "配置选项菜单"
    menu_item 1 安装桌面主题
    menu_item 2 桌面主题切换
    menu_item 3 配置i3wm
    menu_tail
    menu_item q Quit 返回
    menu_tail
}
function do_desktop_all() {
    while true
    do
        show_menu_desktop
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) config_desktop_theme ;;  # 桌面主题配置
            2) kde_theme_switch     ;;
            3) config_i3wm          ;;

            q|"") return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
