#!/bin/bash

source exit_code.sh

readonly DEFAULT_LOGON="username/password@tns"
readonly DEFAULT_SCRIPT_FILE="test.sql"
readonly DEFAULT_OUTPUT="/dev/stdout"

puts_with_heading_and_ending()
{
    local command="$1"
    local heading="$2"
    local ending="$3"

    local default_command="echo No Command"
    local default_heading="Begin"
    local default_ending="End"

    echo "--------------------------------- ${heading:-$default_heading}"
    eval "${command:-$default_command}"
    echo "--------------------------------- ${ending:-$default_ending}"
}

# 获取命令行选项的值
#
# option_name - 需要获取选项取值的选项的名称，即目标选项的名称
# params      - 要解析的命令行参数 (default: "")
#               选项要放在其他参数之前
#
# Examples
#
#   get_option_value logon "--logon=erating/uosdev@uosdev.lk --output_file=output.log"
#   # => "erating/uosdev@uosdev.lk"
#
#   get_option_value output_file "--logon=erating/uosdev@uosdev.lk --output_file=output.log"
#   # => "output.log"
#
#   get_option_value host "$@"
#   # "$@" is "--host=127.0.0.1 --port=3000"
#   # => "127.0.0.1"
#
# 输出指定选项的值，返回0表示处理成功，其它值表示处理失败
get_option_value()
{
    local ARGS=1
    if [ $# -lt "$ARGS" ] ; then
        exit $E_BADARGS
    fi

    local option_name="${1:-option_name_not_found}"
    shift;
    local params="$*"

    set -- `getopt -s bash -a -q -u -o "hv" -l "${option_name}:" -- "$params"`
    while [ -n "$1" ] ; do
        if [ "x$1" = "x--" ] ; then
            break
        fi

        case "$1" in
            "--$option_name") shift; echo $1; break ;;
            *               ) : ;;
        esac

        shift
    done

    return 0
}

get_option_value_into()
{
    local ARGS=2
    if [ $# -lt "$ARGS" ] ; then
        exit $E_BADARGS
    fi

    local param_name="${1:-param_name_not_found}"
    local option_name="${2:-option_name_not_found}"
    shift; shift
    local params="$*"

    eval "$param_name=$(get_option_value $option_name $params)"

    return $?
}

# 在sqlplus内执行指定的SQL语句或SQL脚本
#
# logon      - 连接oracle使用的连接串。
#              例如：
#                  erating/uosdev@uosdev.lk 。
# content    - 需要执行的单条SQL语句或SQL脚本的路径。
#              **注意**
#              仅支持执行单条SQL语句
#              如果执行内容为单条语句，要加行尾的';'号
#              如果需要执行的是脚本，需要在路径前加'@'符号
# spool_file - 将输出结果保存到此文件。
#               可选参数，如不需要保存执行输出，则不传此参数。
#
# Examples
#
#   excute_in_sqlplus "erating/uosdev@uosdev.lk" "select sysdate from dual"
#   # 在 erating@uosdev.lk 用户下，执行语句：select sysdate from dual 。
#
#   excute_in_sqlplus "erating/uosdev@uosdev.lk" "select * from user_objects" "my_objects.spool"
#   # 在 erating@uosdev.lk 用户下，执行语句 "select * from user_objects" ，并将
#   # 输出结果保存到但前路径下的 my_objects.spool 文件中。
#
#   excute_in_sqlplus "erating/uosdev@uosdev.lk" "@test.sql" "test.spool"
#   # 在 erating@uosdev.lk 用户下，执行脚本 test.sql ，并将
#   # 输出结果保存到但前路径下的 test.spool 文件中。
#
# 返回sqlplus的执行结果。
excute_in_sqlplus()
{
    local logon="${1:-$DEFAULT_LOGON}"
    local content="${2:-$DEFAULT_SCRIPT_FILE}"
    local spool_file="${3}"

    local spool_begin=""
    local spool_end=""

    if [[ "x${spool_file}" != "x" ]] ; then
        spool_begin="spool ${spool_file}"
        spool_end="spool off"
    fi

    sqlplus -S "${logon}" << !
        set echo off
        set heading off
        set feedback off
        set newp none
        set colsep ' '

        set sqlblanklines off

        set linesize 1024
        set pagesize 0
        set numwidth 20

        set termout off

        set trimout on
        set trimspool on

        ${spool_begin}

        ${content}

        ${spool_end}

        exit;
!
}

# how to return string from a function

# erating db:list all
# erating db:list tables
# erating db:list table XXX

# 列出指定Schema下的所有表
#
# logon       - 连接oracle使用的连接串。
#               例如：
#                   erating/uosdev@uosdev.lk 。
# output_file - 将输出结果保存到此文件。
#               可选参数，如不需要保存执行输出，则不传此参数。
#               此时，结果直接显示在标准输出
#
# Examples
#
#   list_all_tables "erating/uosdev@uosdev.lk"
#   # 在 erating@uosdev.lk 用户下的所有表
#
#   list_all_tables "erating/uosdev@uosdev.lk" "all_tables.txt"
#   # 在 erating@uosdev.lk 用户下的所有表，并保存在 all_tables.txt 文件中。
#
# 返回sqlplus的执行结果。
list_all_tables()
{
    local logon=${1:-"test/uosdev@uosdev.lk"}
    local output_file=${2:-$DEFAULT_OUTPUT}

    local sql_to_be_excuted="select object_name from user_objects where object_type = 'TABLE' order by object_name, created;"

    excute_in_sqlplus "${logon}" "${sql_to_be_excuted}" > "$output_file"

    return $?
}

# 生成删除所有table的SQL语句
#
# logon       - 连接oracle使用的连接串。
#               例如：
#                   erating/uosdev@uosdev.lk 。
# output_file - 将输出结果保存到此文件。
#
# Examples
#
#   generate_sqls_drop_all_tables 'erating/uosdev@uosdev.lk' 'drop_all_tables_for_erating.sql'
#   # 生成删除erating用户下所有table的SQL语句，并将其保存在"drop_all_tables_for_erating.sql"文件中。
generate_sqls_drop_all_tables()
{
    local logon=${1:-"test/uosdev@uosdev.lk"}
    local output_file=${2:-$DEFAULT_OUTPUT}

    local sql_to_be_excuted="select 'drop table ' || object_name || ' cascade constraints;' from user_objects where object_type = 'TABLE' order by created;"

    excute_in_sqlplus "${logon}" "${sql_to_be_excuted}" > "$output_file"
    excute_in_sqlplus "test/uosdev@uosdev.lk" \
                      "select 'drop table ' || object_name || ' cascade constraints;' from user_objects where object_type = 'TABLE' order by created;" \
                      "drop_all_tables.sql" > /dev/null
}

drop_all_tables()
{
    generate_sqls_drop_all_tables
    excute_in_sqlplus "erating_t02/uosdev@uosdev.lk" "@drop_all_tables.sql"
}
