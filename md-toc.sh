#!/usr/bin/env bash

# Usage: ./md-toc.sh [max heading level] [min heading level] < input.md

_TOC_SPACING=4
_VERSION="{{VERSION}}"

# ----------------------------------------------------------------------------
# Show script usage
# Outputs:
#   Write usage information to stdout
# ----------------------------------------------------------------------------
show_help() {
    cat <<EOF
Generate table of contents of markdown content from given file or stdin.

Usage: ${0##*/} [OPTIONS]... MAX_HEADING_LEVEL MIN_HEADING_LEVEL [FILE|STDIN]

Arguments:
  MAX_HEADING_LEVEL  Maximum heading level to include in the table of contents
  MIN_HEADING_LEVEL  Minimum heading level to include in the table of contents
  FILE               File to read markdown content from. If not provided, 
                     content will be read from stdin.

Options:
  -h, --help            Display this help and exit
  -v, --version         Output version information and exit
  -i, --inline          Inline substitution of the given file. 
                        This will replace the line that has only '[[:ToC:]]' 
                        in it with the generated table of contents.
  -I, --indent=count    Number of spaces to indent the table of contents
                        (default is 4)
EOF
}

# ----------------------------------------------------------------------------
# Generate table of contents
#
# Globals:
#   _TOC_SPACING
#
# Arguments:
#   maximum heading level to include in the table of contents
#   minimum heading level to include in the table of contents
#
# Outputs:
#   Write jable of contents to stdout
# ----------------------------------------------------------------------------
gen_toc() {
    if [[ ${#} -ne 3 ]]; then
        echo -e "[ERROR] Function ${FUNCNAME[0]} usage error" 1>&2
        return 1
    fi

    local _max_level=${1}
    local _min_level=${2}
    local _input=${3}
    local _toc_remove_count=$((_TOC_SPACING * _max_level))

    grep -E "^#{${_max_level:-1},${_min_level:-2}} " <${_input} |
        sed 's/`//g' |
        sed 's/"//g' |
        sed "s/'//g" |
        sed -E 's/(#+) (.+)/\1:\2:\2/g' |
        awk -F ":" -v n="${_TOC_SPACING}" 'BEGIN {
            rep = ""
            for (i = 0; i < n; i++) {
                rep = rep " "
            }
            }
            {
                gsub(/#/,rep,$1)
                sub(/ $/,"",$2)
                sub(/ $/,"",$3)
                gsub(/[ ]/,"-",$3)
                print $1 "- [" $2 "](#" tolower($3) ")"
            }' |
        sed -E "s/^ {${_toc_remove_count}}//"
}

main() {
    local _inline=false
    local _toc_indent=4

    while :; do
        case ${1} in
        --help | -h)
            show_help
            exit
            ;;
        --version | -v)
            echo "Version: ${_VERSION}"
            exit
            ;;
        --inline | -i)
            _inline=true
            ;;
        --indent | -I)
			if [[ "${2}" ]]; then
				_TOC_SPACING=${2}
				shift
			else
				echo -e "[ERROR] '--indent' requires a non-empty option argument." 1>&2
				exit 1
			fi
			;;
		--indent=?*)
			_TOC_SPACING=${1#*=} # Delete everything up to "=" and assign the remainder
			;;
		--indent=)
			echo -e "[ERROR] '--indent' requires a non-empty option argument." 1>&2
			exit 1
			;;
        -?*)
            echo -e "[WARN] Unknown option (ignored): ${1}" 1>&2
            exit 1
            ;;
        *) # Default case: no more options
            break ;;
        esac

        shift
    done

    if [[ ${#} -ne 2 && ${#} -ne 3 ]]; then
        echo -e "[ERROR] Invalid number of arguments" 1>&2
        show_help
        exit 1
    fi

    if [[ ${_inline} == "true" ]]; then
        if [[ ${#} -ne 3 ]]; then
            echo -e "[ERROR] no input file specified" 1>&2
            exit 2
        fi
    fi

    local _max_heading_level=${1}
    local _min_heading_level=${2}
    if [[ ${#} -eq 3 ]]; then
        _file=${3}
        # file validation
        if [[ ! -f ${_file} ]]; then
            echo -e "[ERROR] File not found: ${_file}" 1>&2
            exit 2
        fi
    else
        _file=/dev/stdin
    fi

    # Check max and min heading levels are numbers
    if [[ ! ${_max_heading_level} =~ ^-?[0-9]+$ || ! ${_min_heading_level} =~ ^-?[0-9]+$ ]]; then
        echo -e "[ERROR] Heading level should be number between 1 and 6" 1>&2
        exit 2
    fi

    # Check max and min heading levels are in valid range
    if [[ ${_max_heading_level} -lt 1 || ${_max_heading_level} -gt 6 ]]; then
        echo -e "[ERROR] Max heading level should be between 1 and 6" 1>&2
        exit 2
    fi
    if [[ ${_min_heading_level} -lt 1 || ${_min_heading_level} -gt 6 ]]; then
        echo -e "[ERROR] Min heading level should be between 1 and 6" 1>&2
        exit 2
    fi
    if [[ ${_max_heading_level} -gt ${_min_heading_level} ]]; then
        echo -e "[ERROR] Max heading level should be less than or equal to min heading level" 1>&2
        exit 2
    fi

    _output=$(gen_toc ${_max_heading_level} ${_min_heading_level} ${_file})
    if [[ ${?} -ne 0 ]]; then
        echo -e "[ERROR] Failed to generate table of contents" 1>&2
        exit 3
    fi

    if [[ ${_inline} == "true" ]]; then
        _tmp_file=$(mktemp)
        echo "${_output}" >${_tmp_file}
        sed -i "/^[[:space:]]*\[\[:ToC:\]\][[:space:]]*$/ {
            r ${_tmp_file}
            d
        }" ${_file}
        rm ${_tmp_file}
    else
        echo "${_output}"
    fi
}

main "${@}"
