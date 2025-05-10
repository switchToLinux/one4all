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



########## 开发环境 install_develop ##########################

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
    # origin url example https://repo.anaconda.com/archive/Anaconda3-2023.03-1-Linux-x86_64.sh
    dn_url="https://mirrors.tuna.tsinghua.edu.cn/anaconda/archive/$anaconda_file"
    default_dn_url="https://repo.anaconda.com/archive/$anaconda_file"
    
    prompt "是否使用国内安装源(国内主机推荐选择是):"
    [[ "$?" == "0" ]] && dn_url="$default_dn_url"

    ${curl_cmd} -o /tmp/$anaconda_file -L $dn_url
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

function select_elastic_version() {
    # 可选择的ES版本列表 #
    ES_VERSION_LIST="9.0.1\n8.7.1\n8.11.1\ncustom"
    
    choice=$(echo -e "$ES_VERSION_LIST"  | fzf)
    case "$choice" in
        custom)  # 自定义选择版本号(可能会失败)
            read -p "请输入自定义的Elastic版本号" ES_VERSION
        ;;
        *)
            ES_VERSION="$choice"
        ;;
    esac
}
function install_elasticsearch() {

    prompt "开始安装 Elasticsearch..." || return 1

    cur_username=`whoami`
    prompt "是否确认在当前用户($cur_username)下安装Elasticsearch" || return 1

    select_elastic_version

    es_url="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz"
    install_path="${1:-.}"       # 默认安装路径
    install_name="elasticsearch-${ES_VERSION}"

    read -p "请输入安装目录(默认安装位置：${install_path}):" str_path
    [[ "$str_path" != "" ]] || install_path=$str_path
    [[ ! -d "$install_path" ]] && ! mkdir $install_path && loginfo "目录创建失败!" && return 1
    es_path="${install_path}/${install_name}/"
    [[ -d "$es_path" ]] && loginfo "已经安装过了!" && return 1

    tmp_dir="/tmp"
    filename="`basename $es_url`"
    curl -C - -o ${tmp_dir}/$filename ${es_url}
    [[ "$?" != "0" ]] && loginfo "下载 ${filename} 失败!" && return 1
    
    tar axvf ${tmp_dir}/${filename} -C $install_path  &&  loginfo "解压缩 $filename 文件到 $install_path 目录成功"
    cd $es_path && cd ../
    [[ "$?" != "0" ]] && echo "安装失败! 安装目录: $es_path" && return 1
    loginfo "成功安装目录: $es_path"
    link_name="es"
    [[ -L "./${link_name}" ]]  && unlink ./${link_name}
    ln -sf  ${install_name} ${link_name}
    es_home="${install_path}/${link_name}"
    echo "使用前请设置 环境变量(添加到 ~/.bashrc 文件)或者保存到自己编写的启动脚本中: "
    echo "export ES_HOME=${es_home}"
    echo "export ES_JAVA_OPTS=\"-Xms512m -Xmx512m\""
    echo "运行命令:   \$ES_HOME/bin/elasticsearch -d -p /tmp/myes.pid"
    echo "停止命令:   pkill -F /tmp/myes.pid"
    echo "配置文件:   \$ES_HOME/config/elasticsearch.yml"
    echo "安装 Elasticsearch 完成!"
}
function install_kibana() {

    select_elastic_version

    es_url="https://artifacts.elastic.co/downloads/kibana/kibana-${ES_VERSION}-linux-x86_64.tar.gz"

    install_path="${1:-.}"       # 默认安装路径
    install_name="kibana-${ES_VERSION}"
    prompt "开始安装 Kibana...(默认安装位置为： ${install_path})"
    if [ "$?" != "0" ] ; then
        read -p "请输入安装目录:" install_path
    fi
    es_path="${install_path}/${install_name}/"
    [[ ! -d "$install_path" ]] && ! mkdir $install_path && loginfo "目录创建失败!" && return 1
    [[ -d "$es_path" ]] && loginfo "已经安装过了!" && return 1

    tmp_dir="/tmp"
    filename="`basename $es_url`"
    curl -C - -o ${tmp_dir}/$filename ${es_url}
    [[ "$?" != "0" ]] && loginfo "下载 ${filename} 失败" && return 1
    
    tar axvf ${tmp_dir}/${filename} -C $install_path  &&  loginfo "解压缩 $filename 文件到 $install_path 目录成功"
    cd $es_path && cd ../
    [[ "$?" != "0" ]] && echo "安装失败! 安装目录: $es_path" && return 1
    loginfo "成功安装目录: $es_path"

    link_name="kibana"
    [[ -L "./${link_name}" ]]  && unlink ./${link_name}
    ln -sf  ${install_name} ${link_name}
    es_home="${install_path}/${link_name}"
    loginfo "使用前请设置 环境变量(添加到 ~/.bashrc 文件): "
    loginfo " export KIBANA_HOME=$es_home"
    loginfo "运行命令:   \$KIBANA_HOME/bin/kibana"
    loginfo "配置文件:   \$KIBANA_HOME/config/kibana.yml"
    loginfo "安装 Kibana 完成!"
}

function install_logstash() {

    select_elastic_version

    es_url="https://artifacts.elastic.co/downloads/logstash/logstash-${ES_VERSION}-linux-x86_64.tar.gz"

    install_path="${1:-.}"       # 默认安装路径
    install_name="logstash-${ES_VERSION}"
    prompt "开始安装 logstash...(默认安装位置为： ${install_path})"
    if [ "$?" != "0" ] ; then
        read -p "请输入安装目录:" install_path
    fi
    es_path="${install_path}/${install_name}/"
    [[ ! -d "$install_path" ]] && ! mkdir $install_path && loginfo "目录创建失败!" && return 1
    [[ -d "$es_path" ]] && loginfo "已经安装过了!" && return 1

    tmp_dir="/tmp"
    filename="`basename $es_url`"
    curl -C - -o ${tmp_dir}/$filename ${es_url}
    [[ "$?" != "0" ]] && loginfo "下载 ${filename} 失败" && return 1
    
    tar axvf ${tmp_dir}/${filename} -C $install_path  &&  loginfo "解压缩 $filename 文件到 $install_path 目录成功"
    cd $es_path && cd ../
    [[ "$?" != "0" ]] && echo "安装失败! 安装目录: $es_path" && return 1
    loginfo "成功安装目录: $es_path"
    
    link_name="logstash"
    [[ -L "./${link_name}" ]]  && unlink ./${link_name}
    ln -sf  ${install_name} ${link_name}
    es_home="${install_path}/${link_name}"
    loginfo "使用前请设置 环境变量(添加到 ~/.bashrc 文件): "
    loginfo " export LOGSTASH_HOME=$es_home"
    loginfo "运行命令:   \$LOGSTASH_HOME/bin/logstash -f xxx.conf"
    loginfo "配置文件:   \$LOGSTASH_HOME/config"
    loginfo "安装 Logstash 完成!"
}

function install_nodejs() {
    nodejs_type="${1:-LTS}"   # nodejs 类型 LTS 或 latest最新版
    loginfo "正在执行 install_nodejs"
    command -v node && loginfo "已经安装了 nodejs 环境 :`node -v`" read -p "是否重新安装(y/n)?" str_choice  && [[ "$str_choice" != "y" && "$str_choice" != "Y" ]] && return 0
    prompt "开始安装 nodejs环境" || return 1
    read -p "设置安装位置(比如 /devel/nodejs 目录):" str_outpath
    [[ -d "$str_outpath" ]]  || return 2

    read -p "选择安装版本(16-23/latest,回车默认latest)" nodejs_ver
    ver_url="https://nodejs.org/download/release/latest-v${nodejs_ver}.x/"
    [[ "$nodejs_ver" == "" || "$nodejs_ver" == "latest" ]] && ver_url="https://nodejs.org/download/release/latest"
    tarfile=`${curl_cmd} -L $ver_url  | grep "linux-x64.tar.xz"|awk -F"href=\"" '{ print $2 }' | awk -F"\"" '{print $1}'`
    [[ "$tarfile" == "" ]] && loginfo "没找到 v${nodejs_ver} 版本 nodejs" && return 3

    dn_url="https://nodejs.org/$tarfile"
    loginfo "dn_url: $dn_url"
    tmp_path=/tmp
    dn_filename=$(basename $tarfile)
    outfile="`echo $dn_filename | sed 's/.tar.xz//g'`"
    tmp_file="$tmp_path/$dn_filename"
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
    command -v go && loginfo "已经安装了 go语言开发环境 :`go version`"
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
    menu_head "Menu 选项菜单"
    menu_item 1 install anaconda3
    menu_item 2 install Node.js
    menu_item 3 install GoLang
    menu_item 4 install Elasticsearch
    menu_item 5 install Kibana
    menu_item 6 install Logstash
    menu_item 7 install Stable-diffusion-webui
    menu_tail
    menu_item q Quit 返回
    menu_tail
}
function do_develop_all() {
    while true
    do
        show_menu_develop
        read -r -n 1 -e  -p "`echo_greenr 请选择:` ${PMT} " str_answer
        case "$str_answer" in
            1) install_anaconda     ;;
            2) install_nodejs       ;;
            3) install_golang       ;;
            4) install_elasticsearch ;;
            5) install_kibana  ;;
            6) install_logstash ;;
            7) install_sdwebui   ;;

            q|"") return 0             ;;  # 返回上级菜单
            *) redr_line "没这个选择[$str_answer],搞错了再来." ;;
        esac
    done
}
