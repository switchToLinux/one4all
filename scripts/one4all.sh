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

#### 默认选项 #####
default_confirm="no"    # 是否提示确认，no-提示，yes-自动选择yes
PMT=">>>"
if [ "$OUTPUTLOG" = "" ] ; then
    OUTPUTLOG="yes"  # 默认输出日志内容到 stdout
fi

os_type=""          # Linux操作系统分支类型
os_version=""       # Linux系统版本号
os_codename=""      # Linux的Codename
pac_cmd=""          # 包管理命令
pac_cmd_ins=""      # 包管理命令
cpu_arch=""         # CPU架构类型，仅支持x86_64
gui_type=""         # GUI桌面环境类型


curl_cmd="curl -C - "  # 支持断点继续下载

# Define Colors
RED='\e[41m'
NC='\e[0m' # No color
BG='\e[7m' # Highlighting Background color
TC='\e[1m' # Highlighting Text color

########### 文字显示颜色输出函数 ######
function echo_white()  { printf "\033[0;37m$@\033[0m"     ; }
function echo_whiter() { printf "\033[0;37;7m$@\033[0m"   ; }
function echo_red()    { printf "\033[0;31m$@\033[0m"     ; }
function echo_redr()   { printf "\033[0;31;7m$@\033[0m"   ; }
function echo_green()  { printf "\033[0;32m$@\033[0m"     ; }
function echo_greenr() { printf "\033[0;32;7m$@\033[0m"   ; }
function white_line()  { printf "\033[0;37m$@\033[0m\n"   ; }
function whiter_line() { printf "\033[0;37;7m$@\033[0m\n" ; }
function red_line()    { printf "\033[0;31;1m$@\033[0m\n" ; }
function redr_line()   { printf "\033[0;31;7m$@\033[0m\n" ; }
function green_line()  { printf "\033[0;32;1m$@\033[0m\n" ; }
function greenr_line() { printf "\033[0;32;7m$@\033[0m\n" ; }

line_feed="+------------------------------------------------------------+"

item_index=0   # 记录菜单选项序号
item_line_count=2   # 每行显示菜单数量
MLEN=60   # 单行最大长度
ILEN=30   # 单个选项长度

function menu_line() { let rlen="$item_line_count * $ILEN + 1" ; echo -en "|$TC $@ $NC" ; tput hpa $rlen ; echo "|" ; }
function menu_head() { echo $line_feed ;   menu_line "$@" ; echo $line_feed ; }
# 一行可以有 item_line_count 个菜单选项
function menu_item() { let item_index=$item_index+1 ; n=$1 ; shift ; let rlen="$item_index * $ILEN + 1" ; echo -en "|  $BG ${n} $NC $@" ; tput hpa $rlen ; [[ "$item_index" == "$item_line_count" ]] && echo "|" && item_index=0 ; }
# 输出单行长菜单选项,长度有限制
function menu_iteml() { let rlen="$item_line_count * $ILEN + 1" ; n=$1 ; shift ; echo -en "|  $BG ${n} $NC $@" ; tput hpa $rlen ; echo "|" ; }
# 用于输入长信息(非菜单选项),不限制结尾长度
function menu_info() { n=$1 ; shift ; echo -e "|  $BG ${n} $NC $@" ; }
function menu_tail() { [[ "$item_index" != "0" ]] && echo "|" ; echo $line_feed ; item_index=0 ; }

# 日志记录
log_file="/tmp/one4all.log"
function output_msg() { LEVEL="$1" ; shift ; echo -e "$(date +'%Y年%m月%d日%H:%M:%S'):${LEVEL}: $@" ; }
function output_log() { if [ "$OUTPUTLOG" = "yes" ] ; then  output_msg $@ | tee -a $log_file ; else output_msg $@ >> $log_file ; fi }
function loginfo() { output_log "INFO" $@  ; }
function logerr()  { output_log "ERROR" $@ ; }

################################################################
#  文本信息设定

# 欢迎和再见提示信息
WELCOME="^_^你笑起来真好看!像春天的花一样!"
SEE_YOU="^_^出去晒晒太阳吧!多运动才更健康!"



########### 运行条件检测 ###########
function prompt() { # 提示确认函数，如果使用 -y 参数默认为Y确认
    msg="$@"
    if [ "$default_confirm" != "yes" ] ; then
        read -r -n 1 -e  -p "$msg (y/`echo_greenr N`)" str_answer
        case "$str_answer" in
            y*|Y*)  echo "已确认" ; return 0 ;;
            *)      echo "已取消" ; return 1 ;;
        esac
    else
        echo "$msg"
    fi
    return 0
}
# 检查是否有root权限并提示，需要root权限的命令要添加sudo
function check_root() { [[ "`uid -u`" = "0" ]]  && ! prompt "提示:确认在root用户下或者使用sudo运行?" && exit 0 ; }

function check_sys() { # 检查系统发行版信息，获取os_type/os_version/pac_cmd/pac_cmd_ins等变量
    if [ -f /etc/os-release ] ; then
        ID=`awk -F= '/^ID=/{print $2}' /etc/os-release|sed 's/\"//g'`
        os_version=`awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release|sed 's/\"//g'`
        os_codename=`awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release|sed 's/\"//g'`
        case "$ID" in
            centos|fedora)  # 仅支持 centos 8 以上，但不加限制，毕竟7用户很少了
                os_type="$ID"
                pac_cmd="dnf"
                pac_cmd_ins="$pac_cmd install -y"
                ;;
            opensuse*)
                os_type="$ID"
                pac_cmd="zypper"
                pac_cmd_ins="$pac_cmd install -y"
                ;;
            ubuntu|debian)
                os_type="$ID"
                pac_cmd="apt-get"
                pac_cmd_ins="$pac_cmd install -y"
                ;;
            manjaro|arch*)
                os_type="$ID"
                pac_cmd="pacman"
                pac_cmd_ins="$pac_cmd -S --needed --noconfirm "
                ;;
            *)
                os_type="unknown"
                pac_cmd=""
                pac_cmd_ins=""
                ;;
        esac
    fi
    case "$XDG_CURRENT_DESKTOP" in
        KDE|GNOME|XFCE)
            gui_type="$XDG_CURRENT_DESKTOP"
            ;;
        *)
            gui_type=""
            [[ "$$XDG_CURRENT_DESKTOP" == "" ]] && logerr "您当前会话类型为[$XDG_SESSION_TYPE] 非图形界面下运行"
            [[ "$$XDG_CURRENT_DESKTOP" != "" ]] && loginfo "unknown desktop type: $XDG_CURRENT_DESKTOP"
            ;;
    esac
    cpu_arch="`uname -m`"
    loginfo "${BG}操作系统${NC}:$os_type,${BG}版本${NC}:$os_version,${BG}架构${NC}:$cpu_arch,${BG}桌面类型${NC}:$gui_type,${BG}包管理命令${NC}:$pac_cmd"
    if [ -z "$pac_cmd" ] ; then
        return 1
    fi
    if [ "$cpu_arch" != "x86_64" ] ; then
        echo "invalid cpu arch:[$cpu_arch]"
        return 2
    fi
    return 0
}

function check_basic() { # 基础依赖命令检测与安装
    which curl >/dev/null || sudo $pac_cmd_ins curl     # 检测 curl 命令
    which git >/dev/null || sudo $pac_cmd_ins git       # 检测 git 命令
}
############ 公用模块 #############################################

## 通用的下载安装命令
## 使用方法: common_install_command  cmd_name cmd_url
function common_install_command() {
    str_cmd="$1"   # 命令名称
    str_url="$2"   # 下载命令的地址
    loginfo "正在执行 common_install_command:参数 cmd=$1 ,url=$2"
    which $str_cmd >/dev/null && whiter_line "$str_cmd 命令已经安装了" && return 1
    read -p "设置安装位置(默认目录:/usr/local/bin):" str_path
    [[ ! -d "$str_path" ]] && loginfo "$str_path 目录不存在, 使用默认目录 /usr/local/bin :" && str_path="/usr/local/bin"
    $str_file="$str_path/$str_cmd"
    ${curl_cmd} -o /tmp/${str_cmd}.tmp -L $str_url
    [[ "$?" != "0" ]] && logerr "${RED}下载失败!分析原因后再试吧.${TC}" && return 1
    mv /tmp/${str_cmd}.tmp $str_file && chmod +x $str_file
    # 权限问题失败
    [[ "$?" != "0" ]] && sudo mv /tmp/${str_cmd}.tmp $str_file && sudo chmod +x $str_file
    loginfo "成功安装 $str_cmd 安装路径: $str_file"
}
# 下载 github latest 文件
function common_download_github_latest() {
    owner="$1"
    repo="$2"
    tmp_path="$3"  # 存放目录
    filter="${4:-linux-x86_64}"
    loginfo "开始执行 common_download_github_latest, 参数[$@]"
    [[ "$#" -lt "3" ]] && logerr "参数数量错误,至少三个参数 owner repo tmp_path" && return 1
    mkdir -p "${tmp_path}"
    url=`${curl_cmd} -sSL https://api.github.com/repos/${owner}/${repo}/releases/latest | grep "$filter" |awk -F \" '/browser_download_url/{print $(NF-1)}'|head -1`
    str_base="`basename $url`"  # 压缩文件名(内部是文件或文件夹),因此安装规则无法标准化，只进行解压缩到 tmp_path 之后交给调用者操作    
    ${curl_cmd} -o /tmp/${str_base} -L ${url}
    [[ "$?" != "0" ]] && logerr "下载Github latest包出错了, 解决网络问题再试试吧" && return 1
    
    echo $str_base | grep -E "tar.gz|.tgz|.gz|tar.bz2|.bz2|tar.xz|.xz" >/dev/null
    [[ "$?" != "0" ]] && mv /tmp/$str_base $tmp_path && loginfo "非压缩文件包[$str_base], 直接存放 $tmp_path " && return 0
    
    tar axvf /tmp/$str_base -C $tmp_path  &&  loginfo "解压缩 $str_base 文件到 $tmp_path 目录成功"
    [[ "$?" != "0" ]] && logerr "解压失败! 是否下载文件已损坏或者压缩格式不正确?" && return 3
    loginfo "成功执行 common_download_github_latest"
}
# 磁盘空间检测： disk_check_usage path reserve_size
function disk_check_usage() {
    loginfo "正在执行 disk_check_usage : 参数 [$@]"
    [[ "$#" != "2" ]] && echo -e "${RED}参数数量[ $# != 2 ]错误${NC}, disk_check_usage $@" && return 1
    str_path="$1"          # 目录,用于识别磁盘分区
    reserve_size="$2"     # 单位MB, 需要预留的最小磁盘大小
    [[ ! -d "${str_path}" ]] && echo -e "${RED}检查的目录 ${str_path} 不存在!${NC}" && return 2
    
    # 剩余磁盘空间-512M(预留512MB,避免磁盘占满)
    remain_size=`df -m $str_path | awk '/dev/{ print $4-512 }'`
    [[ "$reserve_size" -gt "$remain_size" ]]  && logerr "剩余空间不足 $remain_size MB ,需要预留空间为 $reserve_size MB" && return 3

    loginfo "磁盘空间符合要求,剩余空间 $remain_size MB ,需要预留空间为 $reserve_size MB"
    return 0
}

function service_is_active() { service_name="$1" ; systemctl is-active $service_name && return 0 ; }
function service_is_enabled() { service_name="$1" ; systemctl is-enabled $service_name && return 0 ; }
function service_enable_start() {
    service_name="$1"
    loginfo "正在执行 service_enable_start,参数[$@]"
    current_status=`service_is_active $service_name`
    [[ "$?" != "0" ]] && logerr "服务 $service_name 状态查看错误!" && return 1
    [[ "$current_status" = "active" ]] && loginfo "当前 $service_name 服务状态: $current_status , 已经启动激活过了,不用重复启动了" && return 0
    
    sudo systemctl enable --now $service_name
    loginfo "启动 $service_name 服务: ${BG} `service_is_active $service_name` ${NC}"
    systemctl status $service_name
    loginfo "成功执行 service_enable_start"
}


############# 安装工具部分 #########################################

function install_anaconda() {
    loginfo "正在执行 install_anaconda 开始下载安装Anaconda3环境."
    prompt "开始安装 Anaconda3" || return 1
    which anaconda >/dev/null 2>&1 && loginfo "Anaconda3已经安装过了!" && return 1
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
    [[ "$?" == "0" ]] && ${curl_cmd} -o /tmp/$anaconda_file -L https://repo.anaconda.com/archive/$anaconda_file

    default_python_install_path="$HOME/anaconda3"       # Python3 默认安装路径
    prompt "开始安装 Anaconda3...(默认安装位置为： ${default_python_install_path})"
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
    sh -c "RUNZSH=no $(${curl_cmd} -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    [[ "$?" = "0" ]]  || (redr_line "安装ohmyzsh失败了!! 看看报错信息! 稍后重新安装试试!"  && return 1)

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
    which tmux >/dev/null && ! prompt "已经安装过 tmux ，继续安装?" && return 0
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
    which frpc && loginfo "frpc 命令已经安装过了" && return 0
    which frps && loginfo "frps 命令已经安装过了" && return 0
    prompt "开始安装 frp" || return 1
    tmp_path=/tmp/frp
    common_download_github_latest fatedier frp $tmp_path linux_amd64
    [[ "$?" != "0" ]] && logerr "下载 frp 预编译可执行程序失败! 安装 frp 失败." && return 1
    sudo cp $tmp_path/frp? /usr/local/bin/ && sudo mkdir /etc/frp && sudo cp $tmp_path/frp*.ini /etc/frp/
    frps -h || ( logerr "安装没成功， frps 命令执行失败." && return 1 )
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
    which yq && loginfo "已经安装过 yq 工具了!" && return 0
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
    which jq && loginfo "已经安装过 jq 工具了!" && return 0
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
            common_download_github_latest TheAssassin AppImageLauncher $tmp_path "x86_64.rpm"  || ( logerr "下载失败啦!" && return 1 )
            sudo $pac_cmd_ins $tmp_path/appimagelauncher*x86_64.rpm
            ;;
        manjaro|arch*)  sudo ${pac_cmd_ins} appimagelauncher  ;;
        *)  logerr "不支持系统类型[$os_type]" ; return 2 ;;
    esac
    loginfo "成功执行 install_appimagelauncher"
}
function show_menu_gui() {
    menu_head "安装图形工具选项菜单"
    menu_item 1 达芬奇DaVinciResolve18
    menu_item 2 "Xmind(思维导图)"
    menu_item 3 "安装AppImageLauncher"
    menu_tail
    menu_item q 返回上级菜单
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
            q|"") return 0          ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
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

    ! which lookandfeeltool >/dev/null && sudo $pac_cmd_ins plasma-workspace plasma5-workspace
    ! which lookandfeeltool >/dev/null && logerr "lookandfeeltool 安装失败,请手动设置主题" && return 1
    
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

function compile_i3wm() {
    prompt "开始源码编译安装最新版 i3wm(需要安装依赖包和编译工具等)" || return 1
    loginfo "开始编译 i3"
    case "$os_type" in
        fedora|cenos)
            sudo $pac_cmd_ins libxcb-devel xcb-util-keysyms-devel xcb-util-devel \
            xcb-util-wm-devel xcb-util-xrm-devel yajl-devel libXrandr-devel \
            startup-notification-devel libev-devel xcb-util-cursor-devel \
            libXinerama-devel libxkbcommon-devel libxkbcommon-x11-devel pcre-devel \
            pango-devel git gcc automake meson ninja-build
            ;;
        ubuntu)
            sudo $pac_cmd_ins libxcb1-dev libxcb-keysyms1-dev libpango1.0-dev \
            libxcb-util0-dev libxcb-icccm4-dev libyajl-dev \
            libstartup-notification0-dev libxcb-randr0-dev \
            libev-dev libxcb-cursor-dev libxcb-xinerama0-dev \
            libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev \
            autoconf libxcb-xrm0 libxcb-xrm-dev automake libxcb-shape0-dev meson ninja-build
            ;;
        debian)
            sudo $pac_cmd_ins dh-autoreconf libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev \
            xcb libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev libxcb-xkb-dev libxcb-cursor-dev \
            libxkbcommon-dev libxcb-xinerama0-dev libxkbcommon-x11-dev libstartup-notification0-dev \
            libxcb-randr0-dev libxcb-xrm0 libxcb-xrm-dev libxcb-shape0 \
            libxcb-shape0-dev meson ninja-build
            ;;
        *)
            loginfo "不支持此系统[$os_type]"
            return 1
        ;;
    esac

    tmp_path="/tmp/i3"
    git clone https://github.com/i3/i3.git $tmp_path
    cd $tmp_path && mkdir build && cd build && meson ../ && ninja  && sudo ninja install
    [[ "$?" != "0" ]] && loginfo "编译出现错误" && return 1
    loginfo "完成 编译安装 i3wm"
}
function install_i3wm() {
    loginfo "开始执行 install_i3wm"
    which i3 && loginfo "已经安装过 i3wm: `i3 -v`" && return 0
    # 先尝试安装预编译包
    case "$os_type" in
        centos|fedora)
            sudo $pac_cmd_ins i3 i3-ipc i3status i3lock dmenu terminator --exclude=rxvt-unicode
            ;;
        manjaro)
            sudo $pac_cmd_ins i3 i3-lock i3status
            ;;
        *)
            compile_i3wm
            ;;
    esac
    loginfo "成功执行 install_i3wm"
}
function config_i3wm() {
    #配置参考: https://i3wm.org/docs/userguide.html
    loginfo "开始执行 config_i3wm"
    which i3
    [[ "$?" != "0" ]] && loginfo "您没安装过 i3wm" && return 0
    sudo $pac_cmd_ins feh iw lm-sensors xautolock lxpolkit picom dunst
    loginfo "安装 Powerline Font"
    tmp_path=/tmp/fonts
    git clone https://github.com/powerline/fonts.git --depth=1 $tmp_path
    cd $tmp_path && ./install.sh && cd - && rm -rf $tmp_path
    loginfo "生成默认的配置 ~/.i3/config"
    mkdir ~/.i3
    ${curl_cmd} -o ~/.i3/config -L https://raw.githubusercontent.com/dikiaap/dotfiles/master/.i3/config
    prompt "安装 polybar(底部状态栏) " && sudo $pac_cmd_ins polybar
    prompt "安装 i3blocks (底部状态栏)" && sudo $pac_cmd_ins i3blocks
    prompt "克隆 i3blocks-contrib 所有脚本" && git clone https://github.com/vivien/i3blocks-contrib ~/.config/i3blocks && cd !$ && cp config.example config
    loginfo "生成默认的 ~/.config/i3blocks/config 配置文件"
    loginfo "i3blocks配置参考文档: https://vivien.github.io/i3blocks/"
    prompt "安装 Rofi" && sudo $pac_cmd_ins rofi
    if ! which rofi >/dev/null ; then #安装预编译版本失败,源码编译
        tmp_path="/tmp/rofi"
        git clone --recursive https://github.com/DaveDavenport/rofi.git  $tmp_path
        [[ "$?" == "0" ]] && cd $tmp_path &&  mkdir build && cd build && make && sudo make install
        [[ "$?" != "0" ]] && loginfo "安装 Rofi 失败!请自行检查错误原因再重新尝试执行 : cd $tmp_path &&  mkdir build && cd build && make && sudo make install"
    else
        loginfo "成功安装 rofi"
    fi
    rofi-theme-selector    # 选择主题

    loginfo "安装 xfce4-terminal(支持透明度设置) , 可自选终端 alacritty"
    sudo $pac_cmd_ins xfce4-terminal

    loginfo "默认的背景图片目录: ~/.wallpapers/"
    loginfo "完成执行 config_i3wm"

}
function show_menu_desktop() { # 显示子菜单
    menu_head "配置选项菜单"
    menu_item 1 安装桌面主题
    menu_item 2 桌面主题切换
    menu_item 3 安装i3wm-源码编译
    menu_item 4 配置i3wm-基础配置
    menu_tail
    menu_item q 返回上级菜单
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
            3) install_i3wm         ;;
            4) config_i3wm          ;;

            q|"") return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}

############# 基础环境配置部分 ####################################
function config_langpack() {  # 中文语言支持 zh_CN.UTF-8
    local_charset="zh_CN.UTF-8" # 字符集名称
    charset_name="zh_CN.utf8"   # Linux系统使用的是没有-的写法(只是写法差别)
    prompt "开始配置中文语言支持 $local_charset" || return 1 
    loginfo "正在执行 config_langpack ,支持 $local_charset 字符集"
    locale -a | grep -Ei "$local_charset|$charset_name" >/dev/null
    if [ "$?" != "0" ] ; then
        case "$os_type" in
            debian|ubuntu*)
                which locale-gen >/dev/null
                if [ "$?" = "0" ] ; then
                    sudo locale-gen $local_charset
                else
                    sudo dpkg-reconfigure locale
                fi
                ;;
            centos|almalinux)
                sudo $pac_cmd_ins glibc-common langpacks-zh_CN ;;
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
            code_name=`awk -`VERSION_CODENAME
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
        manjaro)
            # 自动测试并选择延迟最低的镜像源地址(通过-c参数选择国家)
            # sudo pacman-mirrors -g -c China
            # 手动根据提示选择镜像源地址
            sudo pacman-mirrors -i -c China -m rank
            # 更新软件源本地缓存
            sudo pacman -Syy
            ;;
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
        read -p "`echo_green 输入 $user_name 用户密码:`" user_pass
        echo
        read -p "`red 再次输入$user_name用户密码`(二次确认):" user_2pass
        stty echo
        [[ "$user_pass" = "" || "${user_2pass}" = "" ]] && echo "您没有输入的用户密码!" && exit 2
        [[ "$user_pass" != "${user_2pass}" ]] && echo "两次输入密码不一致!" && exit 3
    fi

    default_shell="/usr/bin/zsh"
    [[ ! -f "$default_shell" ]] && default_shell="/bin/bash"  # 没有zsh就使用 bash
    sudo useradd $user_name --home-dir /home/$user_name -c "add by one4all tool" -s $default_shell -p "$user_pass" -g "users"
    #修改用户权限,使用sudo不用输入密码
    read -p "使用sudo命令时是否希望输入密码?(y/n,默认n)" str_answer
    if [ "$str_answer" = "y" -o "$str_answer" = "Y" ] ; then
        echo "您选择了使用sudo时需要 `red 输入密码`(操作更安全)"
    else
        echo "一看您跟我一样，就是个偷懒的人!选择使用sudo时`echo_green 不输入密码`."
        sudo sh -c "echo '$user_name ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
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
            q|"") return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
########## 显卡相关  #########################################

function download_nvidia_driver() {
    loginfo "正在执行 download_nvidia_driver"
    prompt "开始下载 N卡驱动" || return 1
    which jq >/dev/null || sudo $pac_cmd_ins jq
    ! which jq >/dev/null && logerr "缺少 jq 工具!" && return 1
    loginfo "您已经安装了 jq 命令: `which jq`"
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
    prompt "下载Nvidia驱动安装包(文件大小: $file_size )" && ( ! ${curl_cmd} -o $tmp_file -SL $file_url && logerr "下载Nvidia驱动失败! 检查网络后再试试吧" && return 2)

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
########## 开发环境 install_develop ##########################
function install_sdwebui() {
    loginfo "开始执行 install_sdwebui, 安装源: https://github.com/AUTOMATIC1111/stable-diffusion-webui"
    menu_head "stable-diffusion-webui ${BG}安装前提${NC}"
    menu_iteml Python3 "(推荐 3.10 以上)"
    menu_iteml 显存要求 4GB以上,入门推荐GTX1660S
    menu_tail
    menu_head "运行环境检查结果:"
    menu_iteml "Python3" `python3 --version`
    if which nvidia-smi > /dev/null; then
        menu_iteml "Nvidia型号" `nvidia-smi -q | awk -F: '/Product Name/{print $2 }'`
        menu_iteml "Nvidia显存" `nvidia-smi -q | grep -A4 'FB Memory Usage' | awk '/Total/{print $3 }'` "MB"
    fi
    menu_tail
    id_like=`awk -F= '/^ID_LIKE/{ print $2 }' /etc/os-release|sed 's/\"//g'`
    which python3 >/dev/null || sudo ${pac_cmd_ins} python3 wget git && loginfo "自动安装python3环境完成." && [[ "$id_like" = "debian" ]] &&  sudo ${pac_cmd_ins} python3-venv
    
    pyver="`python3 --version| cut -d. -f2`"
    [[ "$pyver" -lt "10" ]] && logerr "当前Python3版本过低,建议使用Python 3.10以上" && return 1

    prompt "开始安装 stable-diffusion-webui" || return 1
    default_path="$HOME/stable-diffusion-webui"
    read -p "设置安装目录(默认：`echo_greenr ${default_path}`) ${PMT} " install_path
    if [ "$install_path" = "" ] ; then
        loginfo "已选择默认安装目录:${default_path}"
        install_path=$default_path
    fi
    if [ ! -d "$install_path" ] ; then
        [[ ! -d "`dirname $install_path`" ]] && logerr "$install_path 上级目录不存在,请检查后重新设置" && return 1
        loginfo "安装路径 $install_path 检查正常!"
    else
        logerr "目录 $install_path 已经存在,确保目录不存在以免错误设置覆盖数据!" && return 2
    fi
    # 安装前检查磁盘空间
    reserve_size="10240" # 10GB预留(训练模型文件占用更多空间),可以分离模型目录与安装环境
    disk_check_usage `dirname ${install_path}` $reserve_size
    [[ "$?" != "0" ]] && return 4

    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git $install_path
    [[ "$?" != "0" ]] && logerr "下载代码出错了" && return 5
    
    cd $install_path
    # export COMMANDLINE_ARGS="--xformers --lowvram --no-half-vae --no-half --device-id 0 --api --cors-allow-origins=* --allow-code"
    loginfo "设置 启动参数(低显存,加载时间略长)"
    echo 'export COMMANDLINE_ARGS=${COMMANDLINE_ARGS} --xformers --lowvram --no-half-vae --no-half' >> ./webui-user.sh
    ./webui.sh
    loginfo "成功执行 install_sdwebui"
}

function install_nodejs() {
    nodejs_type="${1:-LTS}"   # nodejs 类型 LTS 或 latest最新版
    loginfo "正在执行 install_nodejs"
    which node && loginfo "已经安装了 nodejs 环境 :`node -v`" && return 0
    prompt "开始安装 nodejs环境" || return 1
    read -p "设置安装位置(比如 /devel 目录,自动创建子目录nodejs):" str_outpath
    [[ -d "$str_outpath" ]]  || return 2

    read -p "选择安装版本(16/18/20/latest,回车默认latest)" nodejs_ver
    ver_url="https://nodejs.org/download/release/latest-v${nodejs_ver}.x/"
    [[ "$nodejs_ver" == "" || "$nodejs_ver" == "latest" ]] && ver_url="https://nodejs.org/download/release/latest"
    [[ "$nodejs_ver" == "" || "$nodejs_ver" == "latest" ]] || [[ "$nodejs_ver" -gt "0" || "$nodejs_ver" -lt "100" ]] || return 3
    tarfile=`${curl_cmd} -L $ver_url  | grep "linux-x64.tar.xz"|awk -F"href=\"" '{ print $2 }' | awk -F"\"" '{print $1}'`
    [[ "$tarfile" == "" ]] && loginfo "没找到 v${nodejs_ver} 版本 nodejs" && return 3

    dn_url="$ver_url/$tarfile"
    tmp_path=/tmp
    outfile="`echo $tarfile | sed 's/.tar.xz//g'`"
    tmp_file="$tmp_path/$tarfile"
    ${curl_cmd} -o $tmp_file -L $dn_url || return 1
    tar axvf $tmp_file -C ${str_outpath}
    # 创建软链接
    dst_dir="node_v${nodejs_ver}"
    [[ -e "${str_outpath}/${dst_dir}" ]] || ( cd ${str_outpath} && ln -sf ${outfile} ${dst_dir} && cd - )
    env_path="${str_outpath}/${dst_dir}/bin:\$PATH"
    loginfo "手工设置环境变量:  export PATH=$env_path"
    for rcfile in ~/.zshrc ~/.bashrc
    do
        if [ -f "$rcfile" ] ; then
            grep "${str_outpath}/${dst_dir}/bin" $rcfile || echo "export PATH=$env_path" >> $rcfile
        fi
    done
    loginfo "成功执行 install_nodejs"
}

function install_golang() {
    loginfo "开始执行 install_golang"
    which go && loginfo "已经安装了 go语言开发环境 :`go version`" && return 0
    prompt "开始安装 go语言开发环境" || return 1
    read -p "设置安装位置(比如 /devel 目录,自动创建子目录go):" str_outpath
    [[ -d "$str_outpath" ]]  || return 2

    ver_url="https://go.dev/dl/?mode=json"
    tarfile=`${curl_cmd} $ver_url | grep linux-amd64.tar.gz|head -1| awk -F"\"" '{ print $4 }'`

    dn_url="https://go.dev/dl/$tarfile"
    tmp_path=/tmp
    outfile="`echo $tarfile | sed 's/.tar.gz//g'`"
    tmp_file="$tmp_path/$tarfile"
    ${curl_cmd} -o $tmp_file -L $dn_url || return 1
    tar axvf $tmp_file -C ${str_outpath}
    # 创建软链接
    dst_dir="go"
    [[ -e "${str_outpath}/${dst_dir}" ]] || ( cd ${str_outpath} && ln -sf ${outfile} ${dst_dir} && cd - )
    read -p "设置GOPATH(Go代码开发路径): " str_gopath
    env_path="${str_outpath}/${dst_dir}/bin:\$PATH"
    if [ "$str_gopath" != "" ] ; then
        [[ -d "$str_gopath" ]] && loginfo " GOPATH=$str_gopath 已经存在了" && return 1
        mkdir $str_gopath
        [[ "$?" != "0" ]] && loginfo "$str_gopath 目录创建失败!" && return 2
        env_path="$str_gopath/bin:${str_outpath}/${dst_dir}/bin:\$PATH"
    fi
    for rcfile in ~/.zshrc ~/.bashrc
    do
        if [ -f "$rcfile" ] ; then
            grep "${str_outpath}/${dst_dir}/bin" $rcfile || echo "export PATH=$env_path" >> $rcfile
            mkdir -p ~/.config/go
            echo "GOPATH=$str_gopath" > ~/.config/go/env
        fi
    done
    loginfo "成功执行 install_golang"
}
function show_menu_develop() {
    menu_head "选项菜单"
    menu_item 1 stable-diffusion-webui
    menu_item 2 Node.js-JavaScript
    menu_item 3 GoLang
    menu_tail
    menu_item q 返回上级菜单
    menu_tail
}
function do_develop_all() {
    while true
    do
        show_menu_develop
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) install_sdwebui      ;;
            2) install_nodejs       ;;
            3) install_golang       ;;

            q|"") return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
function show_menu_main() {
    menu_head "安装选项菜单"
    menu_item 1 安装命令工具
    menu_item 2 安装图形界面工具
    menu_item 3 安装编程开发环境
    menu_tail
    menu_item c 配置终端环境
    menu_item d 配置桌面主题
    menu_item g 安装显卡相关
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

            u)
                install_path="$0"
                tmp_path="/tmp/tmp.one4all.sh"
                echo "安装位置: $tmp_path"
                update_url="https://raw.githubusercontent.com/switchToLinux/one4all/main/scripts/one4all.sh"
                ${curl_cmd} -o $tmp_path -SL $update_url
                [[ "$?" != "0" ]] && logerr "抱歉！ $install_path 命令更新失败了!" && return 1
                mv $install_path ${install_path}.bak && mv $tmp_path $install_path && chmod +x $install_path
                loginfo "$install_path 命令更新完毕! ${BG}退出后请重新执行此命令${NC}."
                exit 0
            ;;
            q|"") return 0         ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}

####### Main process #################################
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
