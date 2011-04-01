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

# ��ȡ������ѡ���ֵ
#
# option_name - ��Ҫ��ȡѡ��ȡֵ��ѡ������ƣ���Ŀ��ѡ�������
# params      - Ҫ�����������в��� (default: "")
#               ѡ��Ҫ������������֮ǰ
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
# ���ָ��ѡ���ֵ������0��ʾ����ɹ�������ֵ��ʾ����ʧ��
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

# ��sqlplus��ִ��ָ����SQL����SQL�ű�
#
# logon      - ����oracleʹ�õ����Ӵ���
#              ���磺
#                  erating/uosdev@uosdev.lk ��
# content    - ��Ҫִ�еĵ���SQL����SQL�ű���·����
#              **ע��**
#              ��֧��ִ�е���SQL���
#              ���ִ������Ϊ������䣬Ҫ����β��';'��
#              �����Ҫִ�е��ǽű�����Ҫ��·��ǰ��'@'����
# spool_file - �����������浽���ļ���
#               ��ѡ�������粻��Ҫ����ִ��������򲻴��˲�����
#
# Examples
#
#   excute_in_sqlplus "erating/uosdev@uosdev.lk" "select sysdate from dual"
#   # �� erating@uosdev.lk �û��£�ִ����䣺select sysdate from dual ��
#
#   excute_in_sqlplus "erating/uosdev@uosdev.lk" "select * from user_objects" "my_objects.spool"
#   # �� erating@uosdev.lk �û��£�ִ����� "select * from user_objects" ������
#   # ���������浽��ǰ·���µ� my_objects.spool �ļ��С�
#
#   excute_in_sqlplus "erating/uosdev@uosdev.lk" "@test.sql" "test.spool"
#   # �� erating@uosdev.lk �û��£�ִ�нű� test.sql ������
#   # ���������浽��ǰ·���µ� test.spool �ļ��С�
#
# ����sqlplus��ִ�н����
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

# �г�ָ��Schema�µ����б�
#
# logon       - ����oracleʹ�õ����Ӵ���
#               ���磺
#                   erating/uosdev@uosdev.lk ��
# output_file - �����������浽���ļ���
#               ��ѡ�������粻��Ҫ����ִ��������򲻴��˲�����
#               ��ʱ�����ֱ����ʾ�ڱ�׼���
#
# Examples
#
#   list_all_tables "erating/uosdev@uosdev.lk"
#   # �� erating@uosdev.lk �û��µ����б�
#
#   list_all_tables "erating/uosdev@uosdev.lk" "all_tables.txt"
#   # �� erating@uosdev.lk �û��µ����б��������� all_tables.txt �ļ��С�
#
# ����sqlplus��ִ�н����
list_all_tables()
{
    local logon=${1:-"test/uosdev@uosdev.lk"}
    local output_file=${2:-$DEFAULT_OUTPUT}

    local sql_to_be_excuted="select object_name from user_objects where object_type = 'TABLE' order by object_name, created;"

    excute_in_sqlplus "${logon}" "${sql_to_be_excuted}" > "$output_file"

    return $?
}

# ����ɾ������table��SQL���
#
# logon       - ����oracleʹ�õ����Ӵ���
#               ���磺
#                   erating/uosdev@uosdev.lk ��
# output_file - �����������浽���ļ���
#
# Examples
#
#   generate_sqls_drop_all_tables 'erating/uosdev@uosdev.lk' 'drop_all_tables_for_erating.sql'
#   # ����ɾ��erating�û�������table��SQL��䣬�����䱣����"drop_all_tables_for_erating.sql"�ļ��С�
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
