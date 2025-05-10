#!/usr/bin/env bash
########################################################################
# File Name: prompt_functions.sh
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

# 检测是否已经导入过 #
command -v menu_line >/dev/null 2>&1 && return 0

#### 默认选项 #####
default_confirm="no"    # 是否提示确认，no-提示，yes-自动选择yes
PMT=">>>"
if [ "$OUTPUTLOG" = "" ] ; then
    OUTPUTLOG="yes"  # 默认输出日志内容到 stdout
fi

# Define Colors
RED='\e[41m'
BRB='\e[1;7;31;47m' # Blink Red bold
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

item_index=0        # 记录菜单选项序号
item_line_count=3   # 每行显示菜单数量
ILEN=30             # 单个选项长度
MLEN=$(( (${ILEN}+1) * ${item_line_count}))   # 单行最大长度
print_feed() {
    for i in $(seq 1 $item_line_count) ; do
        printf "+%${ILEN}s" | tr ' ' '-'
    done
    printf "+\n"
}

function menu_line() { echo -en "|  ${BRB} $@ $NC" ; tput hpa $MLEN ; echo "|" ; }
# 居中显示菜单选项
# 函数：center_line
# 用途：居中对齐文本，输出带边框的菜单行
# 参数：
#   $1：要显示的文本
#   $2：可选，指定总宽度（默认使用终端宽度）
function center_line() {
  local text="$1"
  local width="${2:-$MLEN}"  # 默认使用终端宽度

  # 移除 ANSI 颜色代码以计算纯文本长度
  local plain_text
  plain_text=$(echo -n "$text" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')
  local text_len=${#plain_text}

  # 计算左右填充空格
  local total_padding=$((width - text_len))
  local left_padding=$((total_padding / 2))
  local right_padding=$((total_padding - left_padding))

  # 构建输出：| + 左空格 + 文本 + 右空格 + |
  printf "| %*s${BRB}%s${NC}" "$left_padding" "" "$text" ; tput hpa $width ; printf "|\n"
}
function menu_head() { print_feed;   center_line "$@" ; print_feed; }
# 一行可以有 item_line_count 个菜单选项
function menu_item() { let item_index=$item_index+1 ; n=$1 ; shift ; let rlen="$item_index * ($ILEN + 1)" ; echo -en "|  $BG ${n} $NC $@" ; tput hpa $rlen ; [[ "$item_index" == "$item_line_count" ]] && echo "|" && item_index=0 ; }
# 输出单行长菜单选项,长度有限制
function menu_iteml() { n=$1 ; shift ; echo -en "|  $BG ${n} $NC $@" ; tput hpa $MLEN ; echo "|" ; }
# 用于输入长信息(非菜单选项),不限制结尾长度
function menu_info() { n=$1 ; shift ; echo -e "|  $BG ${n} $NC $@" ; }
function menu_tail() { [[ "$item_index" != "0" ]] && echo "|" ; print_feed; item_index=0 ; }

# 日志记录
log_file="/tmp/one4all.log"
function output_msg() { LEVEL="$1" ; shift ; echo -e "$(date +'%Y年%m月%d日%H:%M:%S'):${LEVEL}: $@" ; }
function output_log() { if [ "$OUTPUTLOG" = "yes" ] ; then  output_msg $@ | tee -a $log_file ; else output_msg $@ >> $log_file ; fi }
function loginfo() { output_log "INFO" $@  ; }
function logerr()  { output_log "ERROR" $@ ; }

#### 检测当前终端支持色彩
function check_term() {
	# 指定 TERM ，避免对齐问题(已知某些rxvt-unicode终端版本存在对齐问题)
    if [[ "`tput colors`" -ge "256" ]] ; then
        menu_iteml "终端支持:" "256color"
    else
        export TERM=xterm
        export COLORTERM=truecolor
    fi
    menu_iteml "TERM终端类型:" "$TERM"
    menu_iteml "TERM终端色彩:" "$COLORTERM"
}


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
                pac_cmd_ins="$pac_cmd install "
                ;;
            ubuntu|debian|raspbian)
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
    
    cpu_arch="`uname -m`"
    menu_iteml "Linux发行版:" "$os_type $os_version $cpu_arch"
    menu_iteml "DesktopType:" "${XDG_CURRENT_DESKTOP:-unknown}"
    menu_iteml "PackageManager:" "$pac_cmd"
    if [ -z "$pac_cmd" ] ; then
        return 1
    fi
    if [ "$cpu_arch" != "x86_64" ] ; then
        menu_iteml "warning:" "cpu arch:[$cpu_arch]."
    fi
    return 0
}

################################################################
#  文本信息设定

# 欢迎和再见提示信息
WELCOME="^_^ Welcome! Have a good day!"
SEE_YOU="^_^ Bye! Do not have a good day! Have a great day!"

READ_TIMEOUT=30   # read timeout seconds

########### 运行条件检测 ###########
# 提示确认函数，如果使用 -y 参数默认为Y确认
function prompt() {
    msg="$@"
    if [ "$default_confirm" != "yes" ] ; then
        read -t $READ_TIMEOUT -r -n 1 -e  -p "$msg (y/`echo_greenr N`)" str_answer
        case "$str_answer" in
            y*|Y*)  echo "已确认" ; return 0 ;;
            *)      echo "已取消" ; return 1 ;;
        esac
    else
        echo "$msg (已默认选择 Yes)"
    fi
    return 0
}
# 检查是否有root权限并提示，需要root权限的命令要添加sudo
function check_root() { [[ "`uid -u`" = "0" ]]  && ! prompt "提示:确认在root用户下或者使用sudo运行?" && exit 0 ; }

############ 公用模块 #############################################

## 通用的下载安装命令
## 使用方法: common_install_command  cmd_name cmd_url
function common_install_command() {
    str_cmd="$1"   # 命令名称
    str_url="$2"   # 下载命令的地址
    loginfo "正在执行 common_install_command:参数 cmd=$1 ,url=$2"
    command -v $str_cmd >/dev/null && whiter_line "$str_cmd 命令已经安装了" && return 1
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
    
    echo $str_base | grep -E ".zip" >/dev/null
    [[ "$?" = "0" ]] && echo "zip格式压缩文件" && unzip -o /tmp/$str_base -d $tmp_path &&  echo "解压缩 $str_base 文件到 $tmp_path 目录成功" && return 0

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
    # current_status=`service_is_active $service_name`
    # [[ "$?" != "0" ]] && logerr "服务 $service_name 状态查看错误!" && return 1
    # [[ "$current_status" = "active" ]] && loginfo "当前 $service_name 服务状态: $current_status , 已经启动激活过了,不用重复启动了" && return 0

    sudo systemctl enable --now $service_name
    loginfo "启动 $service_name 服务: ${BG} `service_is_active $service_name` ${NC}"
    systemctl status $service_name
    loginfo "成功执行 service_enable_start"
}

