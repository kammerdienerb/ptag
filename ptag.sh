#!/usr/bin/env bash

function err {
    echo "[ ptag ] ERROR: $@"
    exit 1
}

function file_has_tag {
    f="$1"
    t="$2"

    tail -n 250 "${f}" | grep -E -- "!!!PTAG ${t}\$" 2>&1 > /dev/null
}

function tag_file {
    f="$1"
    t="$2"

    echo "!!!PTAG ${t}" >> "${f}"
}

function untag_file {
    f="$1"
    t="$2"

    sed -i "/!!!PTAG ${t}\$/d" "${f}"
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

function search {
    awk_prg=""
    for tag in "$@"; do
        awk_prg+="/!!!PTAG ${tag}\$/ || "
    done

    awk_prg+="0 { n++ } END { print n; }"

    xargs_template="f=\"\$1\"
n=\$(tail -n 250 \"\${f}\" | env LC_ALL='C' awk '${awk_prg}')
if [ \"\$n\" == \"$#\" ]; then
    echo \"\${f}\"
fi"
    echo "${xargs_template}" > /tmp/ptag_script.sh

    find . -type f -name '*.pdf' -print0 | xargs -0 -P8 -I {} bash /tmp/ptag_script.sh {}
}

function list {
    f="$1"

    if [ "x${1}x" == "xx" ]; then
        find . -type f -name "*.pdf" -print0 | xargs -0 -P8 -I {} bash -c "tail -n 250 \"{}\" | grep -a \"!!!PTAG\" | cut -d\" \" -f 2-" | sort -u
    else
        if ! [ -f "${f}" ]; then
            err "no such file: '${f}'"
        fi

        tail -n 250 "${f}" | grep -a "!!!PTAG" | cut -d" " -f 2-
    fi
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
    echo "    list [FILE]"
    echo "        If FILE if it is provided, list all tags applied"
    echo "        to that file. Otherwise list tags from all files."
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
