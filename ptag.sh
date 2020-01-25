#!/usr/bin/env bash

function err {
    echo "[ ptag ] ERROR: $@"
    exit 1
}

function file_has_tag {
    f="$1"
    t="$2"

    grep -- "!!!PTAG ${t}" "${f}"  2>&1 > /dev/null
}

function tag_file {
    f="$1"
    t="$2"

    echo "!!!PTAG ${t}" >> "${f}"
}

function untag_file {
    f="$1"
    t="$2"

    sed -i "/!!!PTAG ${t}/d" "${f}"
}

function tag {
    f="$1"
    t="$2"

    if ! [ -f "${f}" ]; then
        err "no such file: '${f}'"
    fi

    if [ "${t}" == "" ]; then
        err "missing tag"
    fi

    if file_has_tag "${f}" "${t}"; then
        err "'${f}' is already tagged with '${t}'"
    else
        tag_file "${f}" "${t}"
    fi
}

function untag {
    f="$1"
    t="$2"

    if ! [ -f "${f}" ]; then
        err "no such file: '${f}'"
    fi

    if [ "${t}" == "" ]; then
        err "missing tag"
    fi

    if ! file_has_tag "${f}" "${t}"; then
        err "'${f}' is not tagged with '${t}'"
    else
        untag_file "${f}" "${t}"
    fi
}

function search_file {
    f="$1"
    awk_prg="$2"
    n_tags="$3"

    n=$(awk "${awk_prg}" "${f}")
    if [ "$n" == "${n_tags}" ]; then
        printf "${f}\n"
    fi
}

function search {
    awk_prg=""
    for tag in "$@"; do
        awk_prg+="/!!!PTAG ${tag}/ || "
    done

    awk_prg+="0 { n++ } END { print n; }"

    xargs_template="f=\"\$1\"
n=\$(awk '${awk_prg}' \"\${f}\")
if [ \"\$n\" == \"$#\" ]; then
    echo \"\${f}\"
fi"
    echo "${xargs_template}" > /tmp/ptag_script.sh

    find . -type f -name '*.pdf' -print0 | xargs -0 -P8 -I {} bash /tmp/ptag_script.sh {}
}

function list {
    f="$1"

    if ! [ -f "${f}" ]; then
        err "no such file: '${f}'"
    fi

    grep -a "!!!PTAG" "${f}" | awk '{ print $2; }'
}

function usage {
    echo "usage: ptag command arguments..."
    echo "COMMANDS:"
    echo "    tag FILE TAG"
    echo "        Apply TAG to FILE."
    echo "    untag FILE TAG"
    echo "        Remove TAG from FILE."
    echo "    search TAGS..."
    echo "        List all files that have every tag in TAGS."
    echo "    list FILE"
    echo "        List all tags applied to FILE."
    echo "    help"
    echo "        Show this helpful information."
}

function help {
    usage
}

cmd=$1

shift

case ${cmd} in
    "tag")
        tag "$@"
        ;;

    "untag")
        untag "$@"
        ;;

    "search")
        search "$@"
        ;;

    "list")
        list "$@"
        ;;

    "help")
        help
        ;;

    *)
        usage
        exit 1
        ;;
esac
