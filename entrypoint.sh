#!/usr/bin/env bash

##
# See https://github.com/orgs/community/discussions/106666 for multi-line outputs

#
# See https://github.com/bash-utilities/failure for updates of following function
#


# Bash Trap Failure, a submodule for other Bash scripts tracked by Git
# Copyright (C) 2023  S0AndS0
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation; version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


## Outputs Front-Mater formatted failures for functions not returning 0
## Use the following line after sourcing this file to set failure trap
##    trap 'failure "LINENO" "BASH_LINENO" "${?}"' ERR
failure(){
	local -n _lineno="${1:-LINENO}"
	local -n _bash_lineno="${2:-BASH_LINENO}"
	local _code="${3:-0}"

	## Workaround for read EOF combo tripping traps
	if ! ((_code)); then
		return "${_code}"
	fi

	local -a _output_array=()
	_output_array+=(
		'---'
		"lines_history: [${_lineno} ${_bash_lineno[*]}]"
		"function_trace: [${FUNCNAME[*]}]"
		"exit_code: ${_code}"
	)

	if [[ "${#BASH_SOURCE[@]}" -gt '1' ]]; then
		_output_array+=('source_trace:')
		for _item in "${BASH_SOURCE[@]}"; do
			_output_array+=("  - ${_item}")
		done
	else
		_output_array+=("source_trace: [${BASH_SOURCE[*]}]")
	fi

	_output_array+=('---')
	printf '%s\n' "${_output_array[@]}" >&2
	exit "${_code}"
}
trap 'failure "LINENO" "BASH_LINENO" "${?}"' ERR
set -Ee -o functrace


_source_directory="${INPUT_SOURCE_DIRECTORY:?Undefined source directory}"
_find_regex="${INPUT_FIND_REGEX:?Undefined find -regex value}"
_find_regextype="${INPUT_FIND_REGEXTYPE:?Undefined find -regextype value}"

_destination_name_prefix="${INPUT_DESTINATION_NAME_PREFIX:-}"
_destination_name_suffix="${INPUT_DESTINATION_NAME_SUFFIX:-}"
_destination_clobber="${INPUT_DESTINATION_CLOBBER:-0}"
_cwebp_opts="${INPUT_CWEBP_OPTS}"

_exec_cwebp="${INPUT_EXEC_CWEBP:?Undefined exec name/path for Image Cwebp}"

_found=()
_wrote=()
_failed=()

if ((VERBOSE)); then
	printf >&2 '_find_regex -> %s\n' "${_find_regex}"
	printf >&2 '_find_regextype -> %s\n' "${_find_regextype}"
	printf >&2 '_cwebp_opts -> %s\n' "${_cwebp_opts}"
	printf >&2 '_source_directory -> %s\n' "${_source_directory}"
fi

_command_find=(find "${_source_directory}" -type f)
if (( ${#_find_regex} )); then
	_command_magick+=(-regex "${_find_regex}")
fi
if (( ${#_find_regextype} )); then
	_command_magick+=(-regextype "${_find_regextype}")
fi
_command_find+=(-print0)

while read -rd '' _source_path; do
	_found+=("${_source_path}")

	_source_dirname="$(dirname "${_source_path}")"
	_source_basename="$(basename "${_source_path}")"
	_source_name="${_source_basename%.*}"
	_destination_path="${_source_dirname}/${_destination_name_prefix}${_source_name}${_destination_name_suffix}.webp"

	if [[ "${_source_path}" == "${_destination_path}" ]]; then
		continue
	elif [[ -f "${_destination_path}" ]] && ! ((_destination_clobber)); then
		continue
	fi

	# shellcheck disable=SC2206
	_command_cwebp=("${_exec_cwebp}" -o "${_destination_path}" ${_cwebp_opts} -- "${_destination_path}")

	if ((VERBOSE)); then
		printf >&2 '_source_dirname -> %s\n' "${_source_dirname}"
		printf >&2 '_source_basename -> %s\n' "${_source_basename}"
		printf >&2 '_source_name -> %s\n' "${_source_name}"
		printf >&2 '_destination_path -> %s\n' "${_destination_path}"

		if (( ${#_cwebp_opts} )); then
			printf >&2 '%s -o "%s" %s -- "%s"\n' "${_exec_cwebp}" "${_destination_path}" "${_cwebp_opts}" "${_destination_path}"
		else
			printf >&2 '%s -o "%s" -- "%s"\n' "${_exec_cwebp}" "${_destination_path}" "${_destination_path}"
		fi
	fi

	if "${_command_cwebp[@]}"; then
		_wrote+=("${_destination_path}")
	else
		_failed+=("${_destination_path}")
	fi
done < <("${_command_find[@]}")

if (( ${#_found[@]} )); then
	tee -a 1>/dev/null "${GITHUB_OUTPUT:?Undefined GitHub Output environment variable}" <<EOL
found<<EOF
$(printf '%s\n' "${_found[@]}")
EOF
EOL
fi

if (( ${#_wrote[@]} )); then
	tee -a 1>/dev/null "${GITHUB_OUTPUT:?Undefined GitHub Output environment variable}" <<EOL
wrote<<EOF
$(printf '%s\n' "${_wrote[@]}")
EOF
EOL
fi

if (( ${#_failed[@]} )); then
	tee -a 1>/dev/null "${GITHUB_OUTPUT:?Undefined GitHub Output environment variable}" <<EOL
failed<<EOF
$(printf '%s\n' "${_failed[@]}")
EOF
EOL
fi

# vim: noexpandtab
