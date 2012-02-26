__build_xulapp_getoptionname()
{
	local arg="${1}"
	if [ "${arg}" = "--" ]
	then
		# End of options marker
		return 0
	fi
	if [ "${arg:0:2}" = "--" ]
	then
		# It's a long option
		echo "${arg:2}"
		return 0
	fi
	if [ "${arg:0:1}" = "-" ] && [ ${#arg} -gt 1 ]
	then
		# It's a short option (or a combination of)
		local index="$(expr ${#arg} - 1)"
		echo "${arg:${index}}"
		return 0
	fi
}

__build_xulapp_getfindpermoptions()
{
	local access="${1}"
	local res=""
	while [ ! -z "${access}" ]
	do
		res="${res} -perm /u=${access:0:1},g=${access:0:1},o==${access:0:1}"
		access="${access:1}"
	done
	echo "${res}"
}

__build_xulapp_appendfsitems()
{
	local current="${1}"
	shift
	local currentLength="${#current}"
	local d
	local b
	local isHomeShortcut=false
	[ "${current:0:1}" == "~" ] && current="${HOME}${current:1}" && isHomeShortcut=true
	if [ "${current:$(expr ${currentLength} - 1)}" == "/" ]
	then
		d="${current%/}"
		b=""
	else
		d="$(dirname "${current}")"
		b="$(basename "${current}")"
	fi
	
	local findCommand="find \"${d}\" -mindepth 1 -maxdepth 1 -name \"${b}*\" -a \\( ${@} \\)"
	local files="$(eval ${findCommand} | while read file; do printf "%q\n" "${file#./}"; done)"
	local IFS=$'\n'
	local temporaryRepliesArray=(${files})
	for ((i=0;${i}<${#temporaryRepliesArray[*]};i++))
	do
		local p="${temporaryRepliesArray[$i]}"
		[ "${d}" != "." ] && p="${d}/$(basename "${p}")"
		[ -d "${p}" ] && p="${p%/}/"
		temporaryRepliesArray[$i]="${p}"
	done
	for ((i=0;${i}<${#temporaryRepliesArray[*]};i++))
	do
		COMPREPLY[${#COMPREPLY[*]}]="${temporaryRepliesArray[${i}]}"
	done
}


__build_xulapp_bashcompletion()
{
	#Context
	COMPREPLY=()
	local current="${COMP_WORDS[COMP_CWORD]}"
	local previous="${COMP_WORDS[COMP_CWORD-1]}"
	local first="${COMP_WORDS[1]}"
	local globalargs="--help --output --xml-description --shell --command --target-platform --target --update --window-width --window-height --debug --init-script --resources --ns-xml-path --ns-xml-path-relative --ns-xml-add -h -o -x -t -u"
	local args="${globalargs}"
	
	
	# Option proposal
	if [[ ${current} == -* ]]
	then
		COMPREPLY=( $(compgen -W "${args}" -- ${current}) )
		for ((i=0;$i<${#COMPREPLY[*]};i++)); do COMPREPLY[${i}]="${COMPREPLY[${i}]} ";done
		return 0
	fi
	
	# Option argument proposal
	local option="$(__build_xulapp_getoptionname ${previous})"
	if [ ! -z "${option}" ]
	then
		case "${option}" in
		"output" | "o")
			__build_xulapp_appendfsitems "${current}" -type d 
			if [ ${#COMPREPLY[*]} -gt 0 ]
			then
				return 0
			fi
			
			;;
		"xml-description" | "x")
			__build_xulapp_appendfsitems "${current}" -type f 
			if [ ${#COMPREPLY[*]} -gt 0 ]
			then
				return 0
			fi
			
			;;
		"shell" | "s")
			__build_xulapp_appendfsitems "${current}" -type f 
			if [ ${#COMPREPLY[*]} -gt 0 ]
			then
				return 0
			fi
			
			;;
		"command" | "c")
			local temporaryRepliesArray=( $(compgen -fd -- "${current}") )
			for ((i=0;${i}<${#temporaryRepliesArray[*]};i++))
			do
				[ -d "${temporaryRepliesArray[$i]}" ] && temporaryRepliesArray[$i]="${temporaryRepliesArray[$i]%/}/"
			done
			for ((i=0;${i}<${#temporaryRepliesArray[*]};i++))
			do
				COMPREPLY[${#COMPREPLY[*]}]="${temporaryRepliesArray[${i}]}"
			done
			if [ ${#COMPREPLY[*]} -gt 0 ]
			then
				return 0
			fi
			
			;;
		"target-platform" | "target" | "t")
			COMPREPLY=()
			for e in "host" "linux" "macosx"
			do
				local res="$(compgen -W "${e}" -- "${current}")"
				if [ ! -z "${res}" ]
				then
					COMPREPLY[${#COMPREPLY[*]}]="\"${e}\" "
				fi
			done
			if [ ${#COMPREPLY[*]} -gt 0 ]
			then
				return 0
			fi
			
			;;
		"window-width" | "W")
			local temporaryRepliesArray=( $(compgen -fd -- "${current}") )
			for ((i=0;${i}<${#temporaryRepliesArray[*]};i++))
			do
				[ -d "${temporaryRepliesArray[$i]}" ] && temporaryRepliesArray[$i]="${temporaryRepliesArray[$i]%/}/"
			done
			for ((i=0;${i}<${#temporaryRepliesArray[*]};i++))
			do
				COMPREPLY[${#COMPREPLY[*]}]="${temporaryRepliesArray[${i}]}"
			done
			if [ ${#COMPREPLY[*]} -gt 0 ]
			then
				return 0
			fi
			
			;;
		"window-height" | "H")
			local temporaryRepliesArray=( $(compgen -fd -- "${current}") )
			for ((i=0;${i}<${#temporaryRepliesArray[*]};i++))
			do
				[ -d "${temporaryRepliesArray[$i]}" ] && temporaryRepliesArray[$i]="${temporaryRepliesArray[$i]%/}/"
			done
			for ((i=0;${i}<${#temporaryRepliesArray[*]};i++))
			do
				COMPREPLY[${#COMPREPLY[*]}]="${temporaryRepliesArray[${i}]}"
			done
			if [ ${#COMPREPLY[*]} -gt 0 ]
			then
				return 0
			fi
			
			;;
		"init-script" | "j")
			__build_xulapp_appendfsitems "${current}" -type f 
			if [ ${#COMPREPLY[*]} -gt 0 ]
			then
				return 0
			fi
			
			;;
		"ns-xml-path")
			__build_xulapp_appendfsitems "${current}" -type d 
			if [ ${#COMPREPLY[*]} -gt 0 ]
			then
				return 0
			fi
			
			;;
		
		esac
	fi
	
	# Last hope: files and folders
	COMPREPLY=( $(compgen -fd -- "${current}") )
	for ((i=0;${i}<${#COMPREPLY[*]};i++))
	do
		[ -d "${COMPREPLY[$i]}" ] && COMPREPLY[$i]="${COMPREPLY[$i]%/}/"
	done
	return 0
}
complete -o nospace -F __build_xulapp_bashcompletion build-xulapp.sh
