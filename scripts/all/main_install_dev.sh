#!/usr/bin/env bash

######################################################################
# 文件名: main_install_dev.sh
# 作者: Awkee
# 创建时间: 2023-07-20
# 描述: 安装配置Linux环境开发环境
# 备注: 
#   - 此脚本安装的应用主要为Linux开发环境(编程语言环境、AI工具等的搭建)
#   - 
######################################################################

# Elastic Stack Version

ES_VERSION="8.7.1"

########## 开发环境 install_develop ##########################
function install_sdwebui() {
    loginfo "开始执行 install_sdwebui, 安装源: https://github.com/AUTOMATIC1111/stable-diffusion-webui"
    menu_head "stable-diffusion-webui ${BG}安装前提${NC}"
    menu_iteml Python3 "(推荐 3.10 以上)"
    menu_iteml 显存要求 4GB以上,入门推荐GTX1660S
    menu_tail
    menu_head "运行环境检查结果:"
    menu_iteml "Python3" `python3 --version`
    if command -v nvidia-smi > /dev/null; then
        menu_iteml "Nvidia型号" `nvidia-smi -q | awk -F: '/Product Name/{print $2 }'`
        menu_iteml "Nvidia显存" `nvidia-smi -q | grep -A4 'FB Memory Usage' | awk '/Total/{print $3 }'` "MB"
    fi
    menu_tail
    id_like=`awk -F= '/^ID_LIKE/{ print $2 }' /etc/os-release|sed 's/\"//g'`
    command -v python3 >/dev/null || sudo ${pac_cmd_ins} python3 wget git && loginfo "自动安装python3环境完成." && [[ "$id_like" = "debian" ]] &&  sudo ${pac_cmd_ins} python3-venv
    
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

function install_elasticsearch() {

    prompt "开始安装 Elasticsearch..." || return 1

    cur_username=`whoami`
    prompt "是否确认在当前用户($cur_username)下安装Elasticsearch" || return 1
    
    es_url="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz"
    install_path="${1:-.}"       # 默认安装路径

    read -p "请输入安装目录(默认安装位置：${install_path}):" str_path
    [[ "$str_path" != "" ]] || install_path=$str_path
    [[ ! -d "$install_path" ]] && ! mkdir $install_path && loginfo "目录创建失败!" && return 1
    es_path="${install_path}/elasticsearch-${ES_VERSION}/"
    [[ -d "$es_path" ]] && loginfo "已经安装过了!" && return 1

    tmp_dir="/tmp"
    filename="`basename $es_url`"
    curl -C - -o ${tmp_dir}/$filename ${es_url}
    [[ "$?" != "0" ]] && loginfo "下载 ${filename} 失败!" && return 1
    
    tar axvf ${tmp_dir}/${filename} -C $install_path  &&  loginfo "解压缩 $filename 文件到 $install_path 目录成功"
    cd $es_path
    [[ "$?" != "0" ]] && echo "安装失败! 安装目录: $es_path" && return 1
    loginfo "成功安装目录: $es_path"
    echo "使用前请设置 环境变量(添加到 ~/.bashrc 文件)或者保存到自己编写的启动脚本中: "
    echo "export ES_HOME=$es_path "
    echo "export ES_JAVA_OPTS=\"-Xms512m -Xmx512m\""
    echo "运行命令:   \$ES_HOME/bin/elasticsearch -d -p /tmp/myes.pid"
    echo "停止命令:   pkill -F /tmp/myes.pid"
    echo "配置文件:   \$ES_HOME/config/elasticsearch.yml"
    echo "安装 Elasticsearch 完成!"
}
function install_kibana() {
    es_url="https://artifacts.elastic.co/downloads/kibana/kibana-${ES_VERSION}-linux-x86_64.tar.gz"

    install_path="${1:-.}"       # 默认安装路径
    prompt "开始安装 Kibana...(默认安装位置为： ${install_path})"
    if [ "$?" != "0" ] ; then
        read -p "请输入安装目录:" install_path
    fi
    es_path="${install_path}/kibana-${ES_VERSION}/"
    [[ ! -d "$install_path" ]] && ! mkdir $install_path && loginfo "目录创建失败!" && return 1
    [[ -d "$es_path" ]] && loginfo "已经安装过了!" && return 1

    tmp_dir="/tmp"
    filename="`basename $es_url`"
    curl -C - -o ${tmp_dir}/$filename ${es_url}
    [[ "$?" != "0" ]] && loginfo "下载 ${filename} 失败" && return 1
    
    tar axvf ${tmp_dir}/${filename} -C $install_path  &&  loginfo "解压缩 $filename 文件到 $install_path 目录成功"
    cd $es_path && cd ../ && unlink kibana && ln -sf kibana-${ES_VERSION} kibana
    [[ "$?" != "0" ]] && echo "安装失败! 安装目录: $es_path" && return 1
    loginfo "成功安装目录: $es_path"
    loginfo "使用前请设置 环境变量(添加到 ~/.bashrc 文件): "
    loginfo " export KIBANA_HOME=$es_path "
    loginfo "运行命令:   \$KIBANA_HOME/bin/kibana"
    loginfo "配置文件:   \$KIBANA_HOME/config/kibana.yml"
    loginfo "安装 Kibana 完成!"
}

function install_logstash() {
    es_url="https://artifacts.elastic.co/downloads/logstash/logstash-${ES_VERSION}-linux-x86_64.tar.gz"

    install_path="${1:-.}"       # 默认安装路径
    prompt "开始安装 logstash...(默认安装位置为： ${install_path})"
    if [ "$?" != "0" ] ; then
        read -p "请输入安装目录:" install_path
    fi
    es_path="${install_path}/logstash-${ES_VERSION}/"
    [[ ! -d "$install_path" ]] && ! mkdir $install_path && loginfo "目录创建失败!" && return 1
    [[ -d "$es_path" ]] && loginfo "已经安装过了!" && return 1

    tmp_dir="/tmp"
    filename="`basename $es_url`"
    curl -C - -o ${tmp_dir}/$filename ${es_url}
    [[ "$?" != "0" ]] && loginfo "下载 ${filename} 失败" && return 1
    
    tar axvf ${tmp_dir}/${filename} -C $install_path  &&  loginfo "解压缩 $filename 文件到 $install_path 目录成功"
    cd $es_path && cd ../ && unlink logstash && ln -sf logstash-${ES_VERSION} logstash
    [[ "$?" != "0" ]] && echo "安装失败! 安装目录: $es_path" && return 1
    loginfo "成功安装目录: $es_path"
    loginfo "使用前请设置 环境变量(添加到 ~/.bashrc 文件): "
    loginfo " export LOGSTASH_HOME=$es_path "
    loginfo "运行命令:   \$LOGSTASH_HOME/bin/logstash -f xxx.conf"
    loginfo "配置文件:   \$LOGSTASH_HOME/config"
    loginfo "安装 Logstash 完成!"
}
function install_nodejs() {
    nodejs_type="${1:-LTS}"   # nodejs 类型 LTS 或 latest最新版
    loginfo "正在执行 install_nodejs"
    command -v node && loginfo "已经安装了 nodejs 环境 :`node -v`" && return 0
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
    command -v go && loginfo "已经安装了 go语言开发环境 :`go version`" && return 0
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
    menu_item 4 安装Elasticsearch
    menu_item 5 安装Kibana
    menu_item 6 安装Logstash
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
            4) install_elasticsearch ;;
            5) install_kibana  ;;
            6) install_logstash ;;

            q|"") return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
