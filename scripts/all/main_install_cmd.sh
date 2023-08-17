#!/usr/bin/env bash

######################################################################
# 文件名: main_install_cmd.sh
# 作者: Awkee
# 创建时间: 2023-07-20
# 描述: 安装应用脚本
# 备注: 
#   - 此脚本安装的应用为命令行工具
#   - 
######################################################################


ONECFG=~/.config/one4all
# 导入基础模块 #
# 检测 ${ONECFG}/scripts/all/prompts_functions.sh 是否存在,不存在则git下载
if [[ -f ${ONECFG}/scripts/all/prompts_functions.sh ]] ; then
    source ${ONECFG}/scripts/all/prompts_functions.sh
else 
    git clone https://github.com/switchToLinux/one4all.git ${ONECFG}
    source ${ONECFG}/scripts/all/prompts_functions.sh
fi
############# 安装工具部分 #########################################

function install_anaconda() {
    loginfo "正在执行 install_anaconda 开始下载安装Anaconda3环境."
    prompt "开始安装 Anaconda3" || return 1
    conda -V && loginfo "Anaconda3已经安装过了!" && return 1
    tmp_file=/tmp/.anaconda.html
    ${curl_cmd} -o $tmp_file -sSL https://repo.anaconda.com/archive/
    [[ "$?" != "0" ]]  && loginfo "你的网络有问题!无法访问Anaconda网站" && return 1

    anaconda_file=`awk -F'\"' '/Linux-x86_64.sh/{print $2}' $tmp_file |head -1`
    anaconda_size=`grep -A2 'Linux-x86_64.sh' $tmp_file |sed -n 's/\W*<td[^>]*>//g;s/<\/td>//g;2p'`
    anaconda_date=`grep -A3 'Linux-x86_64.sh' $tmp_file |sed -n 's/\W*<td[^>]*>//g;s/<\/td>//g;3p'`
    loginfo "url: $anaconda_file ,size: $anaconda_size ,date: $anaconda_date"
    if [ -f "/tmp/$anaconda_file" ] ; then
        echo -en "${RED}提醒：文件已经下载过了!${NC}"
    fi
    prompt "下载Anaconda3安装包(文件预计 $anaconda_size, date:$anaconda_date)"
    # origin url https://repo.anaconda.com/archive/Anaconda3-2023.03-1-Linux-x86_64.sh
    dn_url="https://mirrors.tuna.tsinghua.edu.cn/anaconda/archive/$anaconda_file"
    [[ "$?" == "0" ]] && ${curl_cmd} -o /tmp/$anaconda_file -L $dn_url
    [[ "$?" != "0" ]] && echo "下载 Anaconda3 安装包失败!稍后再试试" && return 2

    default_python_install_path="$HOME/anaconda3"       # Python3 默认安装路径
    echo "开始安装 Anaconda3..."
    prompt "使用默认安装目录 ${default_python_install_path}:"
    if [ "$?" != "0" ] ; then
        read -p "请输入自定义安装目录:" python_install_path
    else
        python_install_path=$default_python_install_path
    fi
    if [ "$python_install_path" != "" -a  ! -d "$python_install_path" ] ; then
        loginfo "安装路径 $python_install_path 检查正常!"
    else
        [[ -d "$python_install_path" ]] && logerr "目录 $python_install_path 已经存在,确保目录不存在以免错误设置覆盖数据!" && return 2
        loginfo "无效目录[$python_install_path],请重新选择有效安装路径。"
        return 3
    fi
    # 安装前检查磁盘空间
    reserve_size="8196" # 8GB预留
    disk_check_usage `dirname ${python_install_path}` $reserve_size
    [[ "$?" != "0" ]] && return 4

    sh /tmp/$anaconda_file -p ${python_install_path} -b
    . ${python_install_path}/etc/profile.d/conda.sh
    # 检测当前使用的shell是什么bash/zsh等
    loginfo "检测到当前正在使用 `basename $SHELL` Shell环境,为您自动添加Anaconda3的配置信息"
    conda init `basename $SHELL`
    loginfo "Anaconda3 安装完成! 当前默认Python版本为: `${python_install_path}/bin/python3 --version`"
    loginfo "成功执行 install_anaconda ."
}
function install_ohmyzsh() {
    loginfo "正在执行 install_ohmyzsh"
    prompt "开始安装 ohmyzsh" || return 1
    [[ -d "$HOME/.oh-my-zsh" ]] && loginfo "已经安装过 ohmyzsh 环境了" && return 0
    ! command -v zsh && sudo $pac_cmd_ins zsh
    sh -c "RUNZSH=no $(${curl_cmd} -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    [[ "$?" != "0" ]] && redr_line "安装ohmyzsh失败了!! 看看报错信息! 稍后重新安装试试!"  && return 1

    loginfo "开始安装Powerline字体"
    # clone
    font_tmp_dir=/tmp/zsh_fonts
    git clone https://github.com/powerline/fonts.git --depth=1 $font_tmp_dir
    # install
    cd $font_tmp_dir && sh ./install.sh && cd - && rm -rf $font_tmp_dir

    loginfo "设置默认主题为: $BG agnoster $NC(主题列表命令: omz theme list , 设置 random 随机主题也不错 )"
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' $HOME/.zshrc
    loginfo "成功执行 install_ohmyzsh , $BG 安装ohmyzsh成功!$NC 重新登录或打开新Terminal即可生效!"
}
function install_tmux() {  # Terminal终端会话管理工具,类似Screen
    loginfo "正在执行 install_tmux"
    prompt "开始安装 tmux" || return 1
    command -v tmux >/dev/null && ! prompt "已经安装过 tmux ，继续安装?" && return 0
    # basic config with plugin
    config_data="CiPorr7nva7liY3nvIDkuLpDdHJsICsgYQojIHNldCAtZyBwcmVmaXggQy1hCiPop6PpmaRDdHJsK2Ig5LiO5YmN57yA55qE5a+55bqU5YWz57O7CiMgdW5iaW5kIEMtYgoKCiPlsIZyIOiuvue9ruS4uuWKoOi9vemFjee9ruaWh+S7tu+8jOW5tuaYvuekuiJyZWxvYWRlZCEi5L+h5oGvCmJpbmQgciBzb3VyY2UtZmlsZSB+Ly50bXV4LmNvbmYgXDsgZGlzcGxheSAiUmVsb2FkZWQhIgoKCgojdXAKYmluZC1rZXkgayBzZWxlY3QtcGFuZSAtVQojZG93bgpiaW5kLWtleSBqIHNlbGVjdC1wYW5lIC1ECiNsZWZ0CmJpbmQta2V5IGggc2VsZWN0LXBhbmUgLUwKI3JpZ2h0CmJpbmQta2V5IGwgc2VsZWN0LXBhbmUgLVIKCiNzZWxlY3QgbGFzdCB3aW5kb3cKYmluZC1rZXkgQy1sIHNlbGVjdC13aW5kb3cgLWwKCiMjIGznmoTnjrDlnKjnmoTnu4TlkIjplK7vvJogQ3RybCt4IGzmmK/liIfmjaLpnaLmnb/vvIxDdHJsK3ggQ3RybCts5YiH5o2i56qX5Y+j77yMQ3RybCts5riF5bGPCgoj5L2/5b2T5YmNcGFuZSDmnIDlpKfljJYKIyB6b29tIHBhbmUgPC0+IHdpbmRvdwojaHR0cDovL3RtdXguc3ZuLnNvdXJjZWZvcmdlLm5ldC92aWV3dmMvdG11eC90cnVuay9leGFtcGxlcy90bXV4LXpvb20uc2gKIyBiaW5kIF56IHJ1biAidG11eC16b29tIgojIwoKI2NvcHktbW9kZSDlsIblv6vmjbfplK7orr7nva7kuLp2aSDmqKHlvI8Kc2V0dyAtZyBtb2RlLWtleXMgdmkKIyBzZXQgc2hlbGwKc2V0IC1nIGRlZmF1bHQtc2hlbGwgL2Jpbi96c2gKCgoKIyBwcmVmaXggKyBJKOWkp+WGmSkgOiDlronoo4Xmj5Lku7YKIyBwcmVmaXggKyBVKOWkp+WGmSkgOiDmm7TmlrDmj5Lku7YKIyBwcmVmaXggKyBhbHQgKyB1IDog5riF55CG5o+S5Lu2KOS4jeWcqHBsdWdpbiBsaXN05LitKQojIHByZWZpeCArIEN0cmwtcyAtIHNhdmUKIyBwcmVmaXggKyBDdHJsLXIgLSByZXN0b3JlCgojIOS8muivneeuoeeQhuaPkuS7tgoKc2V0IC1nIEBwbHVnaW4gJ3RtdXgtcGx1Z2lucy90cG0nCnNldCAtZyBAcGx1Z2luICd0bXV4LXBsdWdpbnMvdG11eC1yZXN1cnJlY3QnCnNldCAtZyBAcGx1Z2luICd0bXV4LXBsdWdpbnMvdG11eC1jb250aW51dW0nCgpzZXQgLWcgQGNvbnRpbnV1bS1zYXZlLWludGVydmFsICcxNScKc2V0IC1nIEBjb250aW51dW0tcmVzdG9yZSAnb24nCnNldCAtZyBAcmVzdXJyZWN0LWNhcHR1cmUtcGFuZS1jb250ZW50cyAnb24nCiMKIyBPdGhlciBjb25maWcgLi4uCgpydW4gLWIgJ34vLnRtdXgvcGx1Z2lucy90cG0vdHBtJwoK"
    whiter_line "开始安装tmux插件"
    # 配置 tmux
    sudo ${pac_cmd_ins} tmux
    mkdir -p $HOME/.tmux/plugins/
    cd $HOME/.tmux/plugins/
    git clone https://github.com/tmux-plugins/tpm.git
    git clone https://github.com/tmux-plugins/tmux-resurrect.git
    git clone https://github.com/tmux-plugins/tmux-continuum.git

    echo $config_data | base64 -d  > $HOME/.tmux.conf
    loginfo "成功执行 install_tmux"
}
function install_frp() {
    loginfo "正在执行 install_frp"
    command -v frpc && loginfo "frpc 命令已经安装过了" && return 0
    command -v frps && loginfo "frps 命令已经安装过了" && return 0
    prompt "开始安装 frp" || return 1
    tmp_path=/tmp/frp
    common_download_github_latest fatedier frp $tmp_path linux_amd64
    [[ "$?" != "0" ]] && logerr "下载 frp 预编译可执行程序失败! 安装 frp 失败." && return 1
    sudo cp $tmp_path/frp? /usr/local/bin/ && sudo mkdir /etc/frp && sudo cp $tmp_path/frp*.ini /etc/frp/
    ! command -v frps >/dev/null 2>&1 && logerr "安装没成功， frps 命令执行失败." && return 1
    rm -rf $tmp_path
    loginfo "配置提醒: 参考配置说明，安全考虑，请在配置中加入 token 参数更安全"
    loginfo "成功执行 install_frp"
}
function install_ctags() {
    # 源码编译
    loginfo "开始执行 install_ctags"
    [[ -x /usr/bin/ctags ]] && loginfo "ctags 已经安装了" && ctags --version && return 0
    tmp_path="/tmp/universal-ctags"
    git clone https://github.com/universal-ctags/ctags.git $tmp_path
    cd $tmp_path && ./autogen.sh && ./configure --prefix=/usr && make && sudo make install && cd - && rm -rf $tmp_path
    if [ "$?" != "0" ] ; then
        loginfo "可能您缺少编译相关命令工具导致编译失败,安装Github自动编译的版本:"
        common_download_github_latest universal-ctags ctags-nightly-build $tmp_path
        [[ "$?" != "0" ]] && logerr "下载 ctags 预编译可执行程序失败! 安装ctags 失败." && return 1
        sudo cp $tmp_path/uctags*/bin/* /usr/bin/
    fi
    ctags --version
    [[ "$?" != "0" ]] && logerr "安装没成功，ctags 命令执行失败." && return 1
    rm -rf $tmp_path
    loginfo "成功执行 install_ctags"
}
function install_vim() {
    # 配置 vim 
    prompt "开始安装VIM" || return 1
    sudo $pac_cmd_ins  vim
    # 配置 .vimrc 文件base64数据模板
    config_data="IiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiCiIKIiBWSU0g5L2/55So5biu5Yqp77yaCiIgICDlv6vmjbfplK7vvJoKIiAgICAgICBGMSA6IOabtOaWsEYy5omT5byA55qEVGFn5qCH6K6w5YiX6KGoCiIgICAgICAgRjIgOiDmiZPlvIDku6PnoIF0YWfmoIforrDliJfooago546w5a6e5Ye95pWw5oiW6ICF5Y+Y6YeP5qCH6K6wKQoiICAgICAgIEYzIDog5pi+56S65b2T5YmN5paH5Lu255qE55uu5b2V5L+h5oGvCiIgICAgICAgRjUgOiDov5DooYxQeXRob24z5Luj56CBCiIgICAgICAgRjkgOiDpopzoibLmmL7npLrku6PnoIEKIiAgICAgICBGMTA6IOaKmOWPoC/miZPlvIDku6PnoIHlnZcKIiAgIFNwbGl0Vmlld+W/q+aNt+WRveS7pO+8mgoiICAgICAgdHN2IDog5LiK5LiL5YiG5bGP5omT5byA5paH5Lu2CiIgICAgICB0dnMgOiDlt6blj7PliIblsY/miZPlvIDmlofku7YKIiAgIEN0cmwraCA6IOWIh+aNouW3puS+p+WIhuWxjwoiICAgQ3RybCtsIDog5YiH5o2i5Y+z5L6n5YiG5bGPCiIgICBDdHJsK2ogOiDliIfmjaLkuIvkvqfliIblsY8KIiAgIEN0cmwrayA6IOWIh+aNouS4iuS+p+WIhuWxjwoiCiIgICBUYWLpobXlr7zoiKrlv6vmjbfplK46CiIgICAgICAgdG4gOiDkuIvkuIB0YWLpobUKIiAgICAgICB0cCA6IOS4iuS4gHRhYumhtQoiICAgICAgIHRjIDog5YWz6Zet5b2T5YmNdGFi6aG1CiIgICAgICAgdG0gOiDlvZPliY10YWLpobXnp7vliqjmlbDlrZd45qyhKOi0n+aVsOihqOekuuWPjeWQkeenu+WKqCkKIiAgICAgICB0dCA6IOaWsOaJk+W8gHRhYumhtQoiICAgICAgIHRzIDog5L2/55So5b2T5YmNdGFi6aG15paH5Lu25paw5omT5byA5LiA5LiqdGFi6aG1CiIKIiAgIOS7o+eggee8lui+kea3u+WKoOm7mOiupOazqOmHiuWktOmDqOS/oeaBryjmlK/mjIFiYXNo44CBcHl0aG9u44CBY3Bw44CBY+S7o+eggeaWh+S7tikKIgoiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIKCnNldCBub2NvbXBhdGlibGUgICAgICAgICAgICAgICIgcmVxdWlyZWQKZmlsZXR5cGUgcGx1Z2luIG9mZgpmaWxldHlwZSBpbmRlbnQgb24KCgoiIHNldCB0aGUgcnVudGltZSBwYXRoIHRvIGluY2x1ZGUgVnVuZGxlIGFuZCBpbml0aWFsaXplCnNldCBydHArPX4vLnZpbS9idW5kbGUvVnVuZGxlLnZpbQpjYWxsIHZ1bmRsZSNiZWdpbigpCgoiIGFsdGVybmF0aXZlbHksIHBhc3MgYSBwYXRoIHdoZXJlIFZ1bmRsZSBzaG91bGQgaW5zdGFsbCBwbHVnaW5zCiJjYWxsIHZ1bmRsZSNiZWdpbignfi9zb21lL3BhdGgvaGVyZScpCgoiIGxldCBWdW5kbGUgbWFuYWdlIFZ1bmRsZSwgcmVxdWlyZWQKUGx1Z2luICdnbWFyaWsvVnVuZGxlLnZpbScKUGx1Z2luICdUYXNrTGlzdC52aW0nClBsdWdpbiAndmltLXN5bnRhc3RpYy9zeW50YXN0aWMnClBsdWdpbiAnbnZpZS92aW0tZmxha2U4JwpQbHVnaW4gJ2pudXJtaW5lL1plbmJ1cm4nClBsdWdpbiAnYWx0ZXJjYXRpb24vdmltLWNvbG9ycy1zb2xhcml6ZWQnClBsdWdpbiAnamlzdHIvdmltLW5lcmR0cmVlLXRhYnMnClBsdWdpbiAnc2Nyb29sb29zZS9uZXJkdHJlZScKUGx1Z2luICd0cG9wZS92aW0tZnVnaXRpdmUnICJHaXQgSW50ZWdyYXRpb24KUGx1Z2luICd2aW0tc2NyaXB0cy9pbmRlbnRweXRob24udmltJwpQbHVnaW4gJ0xva2FsdG9nL3Bvd2VybGluZScsIHsncnRwJzogJ3Bvd2VybGluZS9iaW5kaW5ncy92aW0vJ30KUGx1Z2luICd0YWJwYWdlY29sb3JzY2hlbWUnClBsdWdpbiAndGFnbGlzdC52aW0nClBsdWdpbiAndGFnbGlzdC1wbHVzJwpQbHVnaW4gJ29sbHlrZWwvdi12aW0nClBsdWdpbiAnUHl0aG9uLW1vZGUta2xlbicKUGx1Z2luICdydXN0LWxhbmcvcnVzdC52aW0nCiJQbHVnaW4gJ3dha2F0aW1lL3ZpbS13YWthdGltZScKCgoiIGFkZCBhbGwgeW91ciBwbHVnaW5zIGhlcmUgKG5vdGUgb2xkZXIgdmVyc2lvbnMgb2YgVnVuZGxlCiIgdXNlZCBCdW5kbGUgaW5zdGVhZCBvZiBQbHVnaW4pCgoiQnVuZGxlICdWYWxsb3JpYy9Zb3VDb21wbGV0ZU1lJwoKCgoiIEFsbCBvZiB5b3VyIFBsdWdpbnMgbXVzdCBiZSBhZGRlZCBiZWZvcmUgdGhlIGZvbGxvd2luZyBsaW5lCmNhbGwgdnVuZGxlI2VuZCgpICAgICAgICAgICAgIiByZXF1aXJlZAoKCnNldCBlbmNvZGluZz11dGYtOAoKc2V0IGZlbmNzPXV0Zi04LHVjcy1ib20sc2hpZnQtamlzLGdiMTgwMzAsZ2JrLGdiMjMxMixjcDkzNgoKc2V0IHRlcm1lbmNvZGluZz11dGYtOAoKc2V0IGZpbGVlbmNvZGluZ3M9dWNzLWJvbSx1dGYtOCxjcDkzNgoKc2V0IGZpbGVlbmNvZGluZz11dGYtOAoKCnNldCBzcGxpdGJlbG93CnNldCBzcGxpdHJpZ2h0Cgoic3BsaXQgbmF2aWdhdGlvbnMKbm5vcmVtYXAgPEMtSj4gPEMtVz48Qy1KPgpubm9yZW1hcCA8Qy1LPiA8Qy1XPjxDLUs+Cm5ub3JlbWFwIDxDLUw+IDxDLVc+PEMtTD4Kbm5vcmVtYXAgPEMtSD4gPEMtVz48Qy1IPgoKCiIgIyMgZGVmaW5lIGxhbmd1YWdlIGNvbmZpZ3VyYXRpb24gCgoiIyJWIGxhbmd1YWdlIGNvbmZpZ3VyZQoiI2xldCBnOnZfaGlnaGxpZ2h0X2FycmF5X3doaXRlc3BhY2VfZXJyb3IgPSAwCiIjbGV0IGc6dl9oaWdobGlnaHRfY2hhbl93aGl0ZXNwYWNlX2Vycm9yID0gMAoiI2xldCBnOnZfaGlnaGxpZ2h0X3NwYWNlX3RhYl9lcnJvciA9IDAKIiNsZXQgZzp2X2hpZ2hsaWdodF90cmFpbGluZ193aGl0ZXNwYWNlX2Vycm9yID0gMAoiI2xldCBnOnZfaGlnaGxpZ2h0X2Z1bmN0aW9uX2NhbGxzID0gMAoiI2xldCBnOnZfaGlnaGxpZ2h0X2ZpZWxkcyA9IDAKCgoiIyBtYXJrZG93biBmb2xkaW5nICMKImxldCBnOnZpbV9tYXJrZG93bl9mb2xkaW5nX3N0eWxlX3B5dGhvbmljID0gMQoibGV0IGc6dmltX21hcmtkb3duX2ZvbGRpbmdfbGV2ZWwgPSAyCiJsZXQgZzp2aW1fbWFya2Rvd25fb3ZlcnJpZGVfZm9sZHRleHQgPSAwCiJsZXQgZzp2aW1fbWFya2Rvd25fdG9jX2F1dG9maXQgPSAxCgoKIiBQeXRob27or63ms5Xpq5jkuq4gCmxldCBweXRob25faGlnaGxpZ2h0X2FsbD0xCnN5bnRheCBvbgoKaWYgaGFzKCdndWlfcnVubmluZycpCiAgc2V0IGJhY2tncm91bmQ9ZGFyawogIGNvbG9yc2NoZW1lIHNvbGFyaXplZAplbHNlCiAgY29sb3JzY2hlbWUgemVuYnVybgplbmRpZgoKY2FsbCB0b2dnbGViZyNtYXAoIjxGOT4iKQoKIiBFbmFibGUgZm9sZGluZwpzZXQgZm9sZG1ldGhvZD1tYW51YWwKc2V0IGZvbGRuZXN0bWF4PTEwCnNldCBub2ZvbGRlbmFibGUKc2V0IGZvbGRsZXZlbD05OQpzZXQgZm9sZGNvbHVtbj0zCm1hcCA8RjEwPiA6c2V0IGZvbGRtZXRob2Q9bWFudWFsPENSPnphCgpzZXQgbWFnaWMKc2V0IGNvbmZpcm0Kc2V0IG5vYmFja3VwCnNldCBub3N3YXBmaWxlCgoiIOS9v+WbnuagvOmUru+8iGJhY2tzcGFjZe+8ieato+W4uOWkhOeQhmluZGVudCwgZW9sLCBzdGFydOetiQpzZXQgYmFja3NwYWNlPTIKIiDlhYHorrhiYWNrc3BhY2XlkozlhYnmoIfplK7ot6jotorooYzovrnnlYwKc2V0IHdoaWNod3JhcCs9PCw+LGgsbAoKc2V0IG1vdXNlPXYKc2V0IHNlbGVjdGlvbj1leGNsdXNpdmUKc2V0IHNlbGVjdG1vZGU9bW91c2Usa2V5CgoKIiDlkb3ku6TooYzvvIjlnKjnirbmgIHooYzkuIvvvInnmoTpq5jluqbvvIzpu5jorqTkuLox77yM6L+Z6YeM5pivMgpzZXQgY21kaGVpZ2h0PTIKCgoiIOeci+WIsOaKmOWPoOS7o+eggeeahOaWh+aho+Wtl+espuS4sgoibGV0IGc6U2ltcHlsRm9sZF9kb2NzdHJpbmdfcHJldmlldz0xCgoiIOiHquWKqOihpeWFqApsZXQgZzp5Y21fYXV0b2Nsb3NlX3ByZXZpZXdfd2luZG93X2FmdGVyX2NvbXBsZXRpb249MQptYXAgPGxlYWRlcj5nICA6WWNtQ29tcGxldGVyIEdvVG9EZWZpbml0aW9uRWxzZURlY2xhcmF0aW9uPENSPgoKCiIgdGFicyBhbmQgc3BhY2VzIGhhbmRsaW5nCnNldCBleHBhbmR0YWIKc2V0IHRhYnN0b3A9NApzZXQgc29mdHRhYnN0b3A9NApzZXQgc2hpZnR3aWR0aD00CgpzZXQgbnUgIiDmmL7npLrooYzlj7cgCgpzZXQgc3RhdHVzbGluZT0lRiVtJXIlaCV3XCBbRk9STUFUPSV7JmZmfV1cIFtUWVBFPSVZXVwgW1BPUz0lbCwldl1bJXAlJV1cICV7c3RyZnRpbWUoXCIlZC8lbS8leVwgLVwgJUg6JU1cIil9ICAgIueKtuaAgeihjOaYvuekuueahOWGheWuuQpzZXQgbGFzdHN0YXR1cz0yICAgICIg5ZCv5Yqo5pi+56S654q25oCB6KGMKDEpLOaAu+aYr+aYvuekuueKtuaAgeihjCgyKQoKCiIgYnVmZmVyCiIgYnVmZmVyIHNwbGl0dmlldwptYXAgdHN2IDpzdiAKIiBzcGxpdCB2ZXJ0aWNhbGx5Cm1hcCB0dnMgOnZzIAoKIiB0YWIgbmF2aWdhdGlvbiBtYXBwaW5ncwptYXAgdG4gOnRhYm48Q1I+Cm1hcCB0cCA6dGFicDxDUj4KbWFwIHRjIDp0YWJjbG9zZTxDUj4gCm1hcCB0bSA6dGFibSAKbWFwIHR0IDp0YWJuZXcgCm1hcCB0cyA6dGFiIHNwbGl0PENSPgoKImltYXAgPEMtUmlnaHQ+IDxFU0M+OnRhYm48Q1I+CiJpbWFwIDxDLUxlZnQ+ICA8RVNDPjp0YWJwPENSPgoKCmxldCBnOm1pbmlCdWZFeHBsTWFwV2luZG93TmF2VmltID0gMQpsZXQgZzptaW5pQnVmRXhwbE1hcFdpbmRvd05hdkFycm93cyA9IDEKbGV0IGc6bWluaUJ1ZkV4cGxNYXBDVGFiU3dpdGNoQnVmcyA9IDEKbGV0IGc6bWluaUJ1ZkV4cGxNb2RTZWxUYXJnZXQgPSAxCgoiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiCiIgQ1RhZ3PnmoTorr7lrpoKIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIgpsZXQgVGxpc3RfU29ydF9UeXBlID0gIm5hbWUiICAgICIg5oyJ54Wn5ZCN56ew5o6S5bqPCmxldCBUbGlzdF9Vc2VfUmlnaHRfV2luZG93ID0gMSAgIiDlnKjlj7PkvqfmmL7npLrnqpflj6MKbGV0IFRsaXN0X0NvbXBhcnRfRm9ybWF0ID0gMSAgICAiIOWOi+e8qeaWueW8jwpsZXQgVGxpc3RfRXhpc3RfT25seVdpbmRvdyA9IDEgICIg5aaC5p6c5Y+q5pyJ5LiA5LiqYnVmZmVy77yMa2lsbOeql+WPo+S5n2tpbGzmjolidWZmZXIKbGV0IFRsaXN0X0ZpbGVfRm9sZF9BdXRvX0Nsb3NlID0gMCAgIiDkuI3opoHlhbPpl63lhbbku5bmlofku7bnmoR0YWdzCmxldCBUbGlzdF9FbmFibGVfRm9sZF9Db2x1bW4gPSAwICAgICIg5LiN6KaB5pi+56S65oqY5Y+g5qCRCgphdXRvY21kIEZpbGVUeXBlIGphdmEgc2V0IHRhZ3MrPS4vdGFncwphdXRvY21kIEZpbGVUeXBlIGgsY3BwLGNjLGMsZ28gc2V0IHRhZ3MrPS4vdGFncwpsZXQgVGxpc3RfU2hvd19PbmVfRmlsZT0xICAgICAgICAgICAgIuS4jeWQjOaXtuaYvuekuuWkmuS4quaWh+S7tueahHRhZ++8jOWPquaYvuekuuW9k+WJjeaWh+S7tueahAoKIuiuvue9rnRhZ3MKc2V0IHRhZ3M9dGFncwoKIum7mOiupOaJk+W8gFRhZ2xpc3QKbGV0IFRsaXN0X0F1dG9fT3Blbj0wCiIgc2hvdyBwZW5kaW5nIFRhZyBsaXN0Cm1hcCA8RjI+IDpUbGlzdFRvZ2dsZTxDUj4KbWFwIDxGMT4gOlRsaXN0VXBkYXRlPENSPgoKIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiCiIgVGFnIGxpc3QgKGN0YWdzKQoiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIgpsZXQgVGxpc3RfQ3RhZ3NfQ21kID0gJy91c3IvYmluL2N0YWdzJwpsZXQgVGxpc3RfU2hvd19PbmVfRmlsZSA9IDEgIuS4jeWQjOaXtuaYvuekuuWkmuS4quaWh+S7tueahHRhZ++8jOWPquaYvuekuuW9k+WJjeaWh+S7tueahApsZXQgVGxpc3RfRXhpdF9Pbmx5V2luZG93ID0gMSAi5aaC5p6cdGFnbGlzdOeql+WPo+aYr+acgOWQjuS4gOS4queql+WPo++8jOWImemAgOWHunZpbQpsZXQgVGxpc3RfVXNlX1JpZ2h0X1dpbmRvdyA9IDEgIuWcqOWPs+S+p+eql+WPo+S4reaYvuekunRhZ2xpc3Tnqpflj6MKCgoiIOWcqOiiq+WIhuWJsueahOeql+WPo+mXtOaYvuekuuepuueZve+8jOS+v+S6jumYheivuwpzZXQgZmlsbGNoYXJzPXZlcnQ6XCAsc3RsOlwgLHN0bG5jOlwKCiIg6auY5Lqu5pi+56S65Yy56YWN55qE5ous5Y+3CnNldCBzaG93bWF0Y2gKCiIg5aKe5by65qih5byP5Lit55qE5ZG95Luk6KGM6Ieq5Yqo5a6M5oiQ5pON5L2cCnNldCB3aWxkbWVudQoKIuS7o+eggeihpeWFqAoKc2V0IGNvbXBsZXRlb3B0PXByZXZpZXcsbWVudQoKIiDorr7nva7lvZPmlofku7booqvmlLnliqjml7boh6rliqjovb3lhaUKInNldCBhdXRvcmVhZAoKCiIgTkVSRFRyZWUgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gCgoiIHRvZ2dsZSBuZXJkdHJlZSBkaXNwbGF5Cm1hcCA8RjM+IDpORVJEVHJlZVRvZ2dsZTxDUj4KIiBvcGVuIG5lcmR0cmVlIHdpdGggdGhlIGN1cnJlbnQgZmlsZSBzZWxlY3RlZApubWFwICx0IDpORVJEVHJlZUZpbmQ8Q1I+CiIgZG9uO3Qgc2hvdyB0aGVzZSBmaWxlIHR5cGVzCmxldCBORVJEVHJlZUlnbm9yZSA9IFsnXC5weWMkJywgJ1wucHlvJCddCgoKImxldCBnOnBvd2VybGluZV9weWNtZCA9ICdweTMnCiJsZXQgZzpweW1vZGVfcnVuID0gMQoibGV0IGc6cHltb2RlX3B5dGhvbiA9ICdweXRob24zJwoibGV0IGc6cHltb2RlX3J1bl9iaW5kID0gJzxGNT4nCgoibGV0IGc6cHltb2RlX2xpbnRfaWdub3JlID0gIkU1MDEiCiJsZXQgZzpweW1vZGVfbGludF9zZWxlY3QgPSAiVzAwMTEsVzQzMCIKImxldCBnOnB5bW9kZV9saW50X3NvcnQgPSBbJ0UnLCAnQycsICdJJ10KCiJTaG93IGVycm9yIG1lc3NhZ2UgaWYgY3Vyc29yIHBsYWNlZCBhdCB0aGUgZXJyb3IgbGluZSAgKidnOnB5bW9kZV9saW50X21lc3NhZ2UnKgoibGV0IGc6cHltb2RlX2xpbnRfbWVzc2FnZSA9IDEKIiBkZWZhdWx0IGNvZGUgY2hlY2tlcnMgWydweWZsYWtlcycsICdwZXA4JywgJ21jY2FiZSddCiJsZXQgZzpweW1vZGVfbGludF9jaGVja2VycyA9IFsncGVwOCddCgoiIOiHquWKqOS/neWtmOinhuWbvgphdSBCdWZXaW5MZWF2ZSAqLiogc2lsZW50IG1rdmlldwphdSBCdWZXcml0ZVBvc3QgKi4qIHNpbGVudCBta3ZpZXcKYXUgQnVmV2luRW50ZXIgKi4qIHNpbGVudCBsb2FkdmlldwoK"
    echo $config_data | base64 -d > $HOME/.vimrc

    prompt "开始配置Vundle插件管理器"
    if [ "$?" = "0" ] ; then
        mkdir -p $HOME/.vim/bundle/
        git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
        prompt "开始安装VIM插件"
        vim +PluginInstall +qall
    fi
    install_ctags
}
function install_yq() {
    loginfo "正在执行 install_yq"
    command -v yq && loginfo "已经安装过 yq 工具了!" && return 0
    prompt "开始安装 yq" || return 1
    dn_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
    tmp_file="/tmp/yq"
    ${curl_cmd} -o ${tmp_file} -sSL $dn_url && chmod +x ${tmp_file}
    sudo mv ${tmp_file} /usr/local/bin
    yq -V
    loginfo "成功执行 install_yq"
}
function install_jq() {
    loginfo "正在执行 install_jq"
    command -v jq && loginfo "已经安装过 jq 工具了!" && return 0
    prompt "开始安装 jq" || return 1
    dn_url="https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64"
    tmp_file="/tmp/jq"
    ${curl_cmd} -o ${tmp_file} -sSL $dn_url && chmod +x ${tmp_file}
    sudo mv ${tmp_file} /usr/local/bin
    jq -V
    loginfo "成功执行 install_jq"
}

function show_menu_install() {
    menu_head "安装选项菜单"
    menu_item 1 Anaconda3
    menu_item 2 ohmyzsh
    menu_item 3 tmux
    menu_item 4 vim
    menu_item 5 frpc/frps
    menu_item 6 yq
    menu_item 7 jq
    menu_tail
    menu_item q 返回上级菜单
    menu_tail
}
function do_install_all() { # 安装菜单选择
    while true
    do
        show_menu_install
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) install_anaconda     ;;
            2) install_ohmyzsh      ;;
            3) install_tmux         ;;
            4) install_vim          ;;
            5) install_frp          ;;
            6) install_yq           ;;
            7) install_jq           ;;
            q|"") return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}

