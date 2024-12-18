#!/usr/bin/env bash
# ####################################
# Copyright © 2012 - 2021 by renaud
# Author: renaud
# Version: 1.0
# 
# Run ns-xml tests
#
# Program help
usage()
{
if [ ! -z "${1}" ]
then
case "${1}" in
php)
cat << EOFSCUSAGE
php: PHP utilities
Usage:
  run-tests php 
  
  Program options:
    -T, --temp: Keep temporary files
      Don't remove temporary files even if test passed
    --help: Display program usage
    --subcommand-names: Display program subcommand names

EOFSCUSAGE
;;
xsh)
cat << EOFSCUSAGE
xsh: XSH function library tests
Usage:
  run-tests xsh [-1 <...>] [-2 <...>] [Tests ...]
  
  Subcommand options:
    -1, --stdout: Standard output for test program  
      Default value: /dev/null
    -2, --stderr: Error output for test program  
      Default value: /dev/null
  
  Program options:
    -T, --temp: Keep temporary files
      Don't remove temporary files even if test passed
    --help: Display program usage
    --subcommand-names: Display program subcommand names
  Positional arguments:
    1. Tests
      List of test names

EOFSCUSAGE
;;
parsers)
cat << EOFSCUSAGE
parsers: Parsers tests
Usage:
  run-tests parsers [-C] [-p <...  [ ... ]>] [-a <...  [ ... ]>] [-t <...  [ ... ]>]
  
  Subcommand options:
    -p, --parsers: Parser to test  
      The argument have to be one of the following:  
        c, php, python or sh
    -a, --apps: Test groups to run
    -t, --tests: Test id(s) to run
    -C, --comments: Add debug comments in generated test programs
  
  Program options:
    -T, --temp: Keep temporary files
      Don't remove temporary files even if test passed
    --help: Display program usage
    --subcommand-names: Display program subcommand names

EOFSCUSAGE
;;
xslt | xsl)
cat << EOFSCUSAGE
xslt: XSLT tests
Usage:
  run-tests xslt [Test names ...]
  
  Program options:
    -T, --temp: Keep temporary files
      Don't remove temporary files even if test passed
    --help: Display program usage
    --subcommand-names: Display program subcommand names
  Positional arguments:
    1. Test names
      Test subset to run.
      Test names should be the path of a .info file located in the tests/xslt 
      directory or its shortname (basename without extension)

EOFSCUSAGE
;;
xsd | schema)
cat << EOFSCUSAGE
xsd: XML schema validation tests
Usage:
  run-tests xsd 
  
  Program options:
    -T, --temp: Keep temporary files
      Don't remove temporary files even if test passed
    --help: Display program usage
    --subcommand-names: Display program subcommand names
  
    Check if the given files should validate (or not) a XML schema definition

EOFSCUSAGE
;;

esac
return 0
fi
cat << 'EOFUSAGE'
run-tests: Run ns-xml tests

Usage: 
  run-tests <subcommand [subcommand option(s)]> [-T] [--help] [--subcommand-names]
  
  With subcommand:
    php: PHP utilities
    xsh: XSH function library tests
      options: [-1 <...>] [-2 <...>]
    parsers: Parsers tests
      options: [-C] [-p <...  [ ... ]>] [-a <...  [ ... ]>] [-t <...  [ ... ]>]
    xslt, xsl: XSLT tests
    xsd, schema: XML schema validation tests
  
  Options:
    -T, --temp: Keep temporary files
      Don't remove temporary files even if test passed
    --help: Display program usage
    --subcommand-names: Display program subcommand names

  This program is used as a part of the git pre-commit hook of this project
    see tools/sh/git/hooks/pre-commit

EOFUSAGE
}

# Program parameter parsing
parser_program_author="renaud"
parser_program_version="1.0"
if [ -r /proc/$$/exe ]
then
	parser_shell="$(readlink /proc/$$/exe | sed "s/.*\/\([a-z]*\)[0-9]*/\1/g")"
else
	parser_shell="$(basename "$(ps -p $$ -o command= | cut -f 1 -d' ')")"
fi

parser_input=("${@}")
parser_itemcount=${#parser_input[*]}
parser_startindex=0
parser_index=0
parser_subindex=0
parser_item=''
parser_option=''
parser_optiontail=''
parser_subcommand=''
parser_subcommand_expected=true
parser_subcommand_names=(php \
	xsh \
	parsers \
	xslt \
	xsl \
	xsd \
	schema)
PARSER_OK=0
PARSER_ERROR=1
PARSER_SC_OK=0
PARSER_SC_ERROR=1
PARSER_SC_UNKNOWN=2
PARSER_SC_SKIP=3
[ "${parser_shell}" = 'zsh' ] && parser_startindex=1
parser_itemcount=$(expr ${parser_startindex} + ${parser_itemcount})
parser_index=${parser_startindex}



parsers_debugComments=false
keepTemporaryFiles=false
displayHelp=false
displaySubcommandNames=false
xsh_stdout=
xsh_stderr=

parse_addwarning()
{
	local message="${1}"
	local m="[${parser_option}:${parser_index}:${parser_subindex}] ${message}"
	parser_warnings[$(expr ${#parser_warnings[*]} + ${parser_startindex})]="${m}"
}
parse_adderror()
{
	local message="${1}"
	local m="[${parser_option}:${parser_index}:${parser_subindex}] ${message}"
	parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]="${m}"
}
parse_addfatalerror()
{
	local message="${1}"
	local m="[${parser_option}:${parser_index}:${parser_subindex}] ${message}"
	parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]="${m}"
	parser_aborted=true
}

parse_displayerrors()
{
	for error in "${parser_errors[@]}"
	do
		echo -e "\t- ${error}"
	done
}


parse_pathaccesscheck()
{
	local file="${1}"
	[ ! -a "${file}" ] && return 0
	
	local accessString="${2}"
	while [ ! -z "${accessString}" ]
	do
		[ -${accessString:0:1} ${file} ] || return 1;
		accessString=${accessString:1}
	done
	return 0
}
parse_addrequiredoption()
{
	local id="${1}"
	local tail="${2}"
	local o=
	for o in "${parser_required[@]}"
	do
		local idPart="$(echo "${o}" | cut -f 1 -d":")"
		[ "${id}" = "${idPart}" ] && return 0
	done
	parser_required[$(expr ${#parser_required[*]} + ${parser_startindex})]="${id}:${tail}"
}
parse_setoptionpresence()
{
	parse_isoptionpresent "${1}" && return 0
	
	case "${1}" in
	
	esac
	case "${1}" in
	
	esac
	parser_present[$(expr ${#parser_present[*]} + ${parser_startindex})]="${1}"
	return 0
}
parse_isoptionpresent()
{
	local _e_found=false
	local _e=
	for _e in "${parser_present[@]}"
	do
		if [ "${_e}" = "${1}" ]
		then
			_e_found=true; break
		fi
	done
	if ${_e_found}
	then
		return 0
	else
		return 1
	fi
}
parse_checkrequired()
{
	[ ${#parser_required[*]} -eq 0 ] && return 0
	local c=0
	for o in "${parser_required[@]}"
	do
		local idPart="$(echo "${o}" | cut -f 1 -d":")"
		local _e_found=false
		local _e=
		for _e in "${parser_present[@]}"
		do
			if [ "${_e}" = "${idPart}" ]
			then
				_e_found=true; break
			fi
		done
		if ! (${_e_found})
		then
			local displayPart="$(echo "${o}" | cut -f 2 -d":")"
			parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]="Missing required option ${displayPart}"
			c=$(expr ${c} + 1)
		fi
	done
	return ${c}
}
parse_setdefaultoptions()
{
	local parser_set_default=false
	
	parser_set_default=true
	parse_isoptionpresent SC_2_xsh_1_stdout && parser_set_default=false
	if ${parser_set_default}
	then
		xsh_stdout='/dev/null'
		parse_setoptionpresence SC_2_xsh_1_stdout
	fi
	
	
	parser_set_default=true
	parse_isoptionpresent SC_2_xsh_2_stderr && parser_set_default=false
	if ${parser_set_default}
	then
		xsh_stderr='/dev/null'
		parse_setoptionpresence SC_2_xsh_2_stderr
	fi
	
	case "${parser_subcommand}" in
	php)
		local parser_set_default=false
		
		;;
	xsh)
		local parser_set_default=false
		
		parser_set_default=true
		parse_isoptionpresent SC_2_xsh_1_stdout && parser_set_default=false
		if ${parser_set_default}
		then
			xsh_stdout='/dev/null'
			parse_setoptionpresence SC_2_xsh_1_stdout
		fi
		
		
		parser_set_default=true
		parse_isoptionpresent SC_2_xsh_2_stderr && parser_set_default=false
		if ${parser_set_default}
		then
			xsh_stderr='/dev/null'
			parse_setoptionpresence SC_2_xsh_2_stderr
		fi
		
		
		;;
	parsers)
		local parser_set_default=false
		
		;;
	xslt | xsl)
		local parser_set_default=false
		
		;;
	xsd | schema)
		local parser_set_default=false
		
		;;
	
	esac
}
parse_checkminmax()
{
	local errorCount=0
	return ${errorCount}
}
parse_numberlesserequalcheck()
{
	local hasBC=false
	which bc 1>/dev/null 2>&1 && hasBC=true
	if ${hasBC}
	then
		[ "$(echo "${1} <= ${2}" | bc)" = "0" ] && return 1
	else
		local a_int="$(echo "${1}" | cut -f 1 -d".")"
		local a_dec="$(echo "${1}" | cut -f 2 -d".")"
		[ "${a_dec}" = "${1}" ] && a_dec="0"
		local b_int="$(echo "${2}" | cut -f 1 -d".")"
		local b_dec="$(echo "${2}" | cut -f 2 -d".")"
		[ "${b_dec}" = "${2}" ] && b_dec="0"
		[ ${a_int} -lt ${b_int} ] && return 0
		[ ${a_int} -gt ${b_int} ] && return 1
		([ ${a_int} -ge 0 ] && [ ${a_dec} -gt ${b_dec} ]) && return 1
		([ ${a_int} -lt 0 ] && [ ${b_dec} -gt ${a_dec} ]) && return 1
	fi
	return 0
}
parse_enumcheck()
{
	local ref="${1}"
	shift 1
	while [ $# -gt 0 ]
	do
		[ "${ref}" = "${1}" ] && return 0
		shift
	done
	return 1
}
parse_addvalue()
{
	local position=${#parser_values[*]}
	local value=
	if [ $# -gt 0 ] && [ ! -z "${1}" ]; then value="${1}"; else return ${PARSER_ERROR}; fi
	shift
	if [ -z "${parser_subcommand}" ]
	then
		${parser_isfirstpositionalargument} && parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]='Program does not accept positional arguments'
		
		parser_isfirstpositionalargument=false
		return ${PARSER_ERROR}
	else
		case "${parser_subcommand}" in
		php)
			${parser_isfirstpositionalargument} && parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]='Subcommand php does not accept positional arguments'
			
			parser_isfirstpositionalargument=false
			return ${PARSER_ERROR}
			;;
		xsh)
			case "${position}" in
			*)
				;;
			
			esac
			;;
		parsers)
			${parser_isfirstpositionalargument} && parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]='Subcommand parsers does not accept positional arguments'
			
			parser_isfirstpositionalargument=false
			return ${PARSER_ERROR}
			;;
		xslt)
			case "${position}" in
			*)
				;;
			
			esac
			;;
		xsd)
			${parser_isfirstpositionalargument} && parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]='Subcommand xsd does not accept positional arguments'
			
			parser_isfirstpositionalargument=false
			return ${PARSER_ERROR}
			;;
		*)
			return ${PARSER_ERROR}
			;;
		
		esac
	fi
	parser_values[$(expr ${#parser_values[*]} + ${parser_startindex})]="${value}"
}
parse_process_subcommand_option()
{
	parser_item="${parser_input[${parser_index}]}"
	if [ -z "${parser_item}" ] || [ "${parser_item:0:1}" != "-" ] || [ "${parser_item}" = '--' ]
	then
		return ${PARSER_SC_SKIP}
	fi
	
	case "${parser_subcommand}" in
	xsh)
		if [ "${parser_item:0:2}" = '--' ] 
		then
			parser_option="${parser_item:2}"
			parser_optionhastail=false
			if echo "${parser_option}" | grep '=' 1>/dev/null 2>&1
			then
				parser_optionhastail=true
				parser_optiontail="$(echo "${parser_option}" | cut -f 2- -d"=")"
				parser_option="$(echo "${parser_option}" | cut -f 1 -d"=")"
			fi
			
			case "${parser_option}" in
			stdout)
				if ${parser_optionhastail}
				then
					parser_item=${parser_optiontail}
				else
					parser_index=$(expr ${parser_index} + 1)
					if [ ${parser_index} -ge ${parser_itemcount} ]
					then
						parse_adderror "End of input reached - Argument expected"
						return ${PARSER_SC_ERROR}
					fi
					
					parser_item="${parser_input[${parser_index}]}"
					if [ "${parser_item}" = '--' ]
					then
						parse_adderror "End of option marker found - Argument expected"
						parser_index=$(expr ${parser_index} - 1)
						return ${PARSER_SC_ERROR}
					fi
				fi
				
				parser_subindex=0
				parser_optiontail=''
				parser_optionhastail=false
				[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
				! parse_setoptionpresence SC_2_xsh_1_stdout && return ${PARSER_SC_ERROR}
				
				xsh_stdout="${parser_item}"
				
				;;
			stderr)
				if ${parser_optionhastail}
				then
					parser_item=${parser_optiontail}
				else
					parser_index=$(expr ${parser_index} + 1)
					if [ ${parser_index} -ge ${parser_itemcount} ]
					then
						parse_adderror "End of input reached - Argument expected"
						return ${PARSER_SC_ERROR}
					fi
					
					parser_item="${parser_input[${parser_index}]}"
					if [ "${parser_item}" = '--' ]
					then
						parse_adderror "End of option marker found - Argument expected"
						parser_index=$(expr ${parser_index} - 1)
						return ${PARSER_SC_ERROR}
					fi
				fi
				
				parser_subindex=0
				parser_optiontail=''
				parser_optionhastail=false
				[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
				! parse_setoptionpresence SC_2_xsh_2_stderr && return ${PARSER_SC_ERROR}
				
				xsh_stderr="${parser_item}"
				
				;;
			*)
				return ${PARSER_SC_SKIP}
				;;
			
			esac
		elif [ "${parser_item:0:1}" = "-" ] && [ ${#parser_item} -gt 1 ]
		then
			parser_optiontail="${parser_item:$(expr ${parser_subindex} + 2)}"
			parser_option="${parser_item:$(expr ${parser_subindex} + 1):1}"
			if [ -z "${parser_option}" ]
			then
				parser_subindex=0
				return ${PARSER_SC_OK}
			fi
			
			case "${parser_option}" in
			'1')
				if [ ! -z "${parser_optiontail}" ]
				then
					parser_item=${parser_optiontail}
				else
					parser_index=$(expr ${parser_index} + 1)
					if [ ${parser_index} -ge ${parser_itemcount} ]
					then
						parse_adderror "End of input reached - Argument expected"
						return ${PARSER_SC_ERROR}
					fi
					
					parser_item="${parser_input[${parser_index}]}"
					if [ "${parser_item}" = '--' ]
					then
						parse_adderror "End of option marker found - Argument expected"
						parser_index=$(expr ${parser_index} - 1)
						return ${PARSER_SC_ERROR}
					fi
				fi
				
				parser_subindex=0
				parser_optiontail=''
				parser_optionhastail=false
				[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
				! parse_setoptionpresence SC_2_xsh_1_stdout && return ${PARSER_SC_ERROR}
				
				xsh_stdout="${parser_item}"
				
				;;
			'2')
				if [ ! -z "${parser_optiontail}" ]
				then
					parser_item=${parser_optiontail}
				else
					parser_index=$(expr ${parser_index} + 1)
					if [ ${parser_index} -ge ${parser_itemcount} ]
					then
						parse_adderror "End of input reached - Argument expected"
						return ${PARSER_SC_ERROR}
					fi
					
					parser_item="${parser_input[${parser_index}]}"
					if [ "${parser_item}" = '--' ]
					then
						parse_adderror "End of option marker found - Argument expected"
						parser_index=$(expr ${parser_index} - 1)
						return ${PARSER_SC_ERROR}
					fi
				fi
				
				parser_subindex=0
				parser_optiontail=''
				parser_optionhastail=false
				[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
				! parse_setoptionpresence SC_2_xsh_2_stderr && return ${PARSER_SC_ERROR}
				
				xsh_stderr="${parser_item}"
				
				;;
			*)
				return ${PARSER_SC_SKIP}
				;;
			
			esac
		fi
		;;
	parsers)
		if [ "${parser_item:0:2}" = '--' ] 
		then
			parser_option="${parser_item:2}"
			parser_optionhastail=false
			if echo "${parser_option}" | grep '=' 1>/dev/null 2>&1
			then
				parser_optionhastail=true
				parser_optiontail="$(echo "${parser_option}" | cut -f 2- -d"=")"
				parser_option="$(echo "${parser_option}" | cut -f 1 -d"=")"
			fi
			
			case "${parser_option}" in
			parsers)
				parser_item=''
				${parser_optionhastail} && parser_item=${parser_optiontail}
				
				parser_subindex=0
				parser_optiontail=''
				parser_optionhastail=false
				[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
				local parser_ma_values=
				local parser_ma_local_count=0
				local parser_ma_total_count=${#parsers_parsers[*]}
				unset parser_ma_values
				if [ ! -z "${parser_item}" ]
				then
					if ! ([ "${parser_item}" = 'c' ] || [ "${parser_item}" = 'php' ] || [ "${parser_item}" = 'python' ] || [ "${parser_item}" = 'sh' ])
					then
						parse_adderror "Invalid value for option \"${parser_option}\""
						
						return ${PARSER_SC_ERROR}
					fi
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
				fi
				
				local parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				while [ ! -z "${parser_nextitem}" ] && [ "${parser_nextitem}" != '--' ] && [ ${parser_index} -lt ${parser_itemcount} ]
				do
					if [ ${parser_ma_local_count} -gt 0 ] && [ "${parser_nextitem:0:1}" = "-" ]
					then
						break
					fi
					
					parser_index=$(expr ${parser_index} + 1)
					parser_item="${parser_input[${parser_index}]}"
					[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
					if ! ([ "${parser_item}" = 'c' ] || [ "${parser_item}" = 'php' ] || [ "${parser_item}" = 'python' ] || [ "${parser_item}" = 'sh' ])
					then
						parse_adderror "Invalid value for option \"${parser_option}\""
						
						return ${PARSER_SC_ERROR}
					fi
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
					parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				done
				if [ ${parser_ma_local_count} -eq 0 ]
				then
					parse_adderror "At least one argument expected for option \"${parser_option}\""
					return ${PARSER_SC_ERROR}
				fi
				! parse_setoptionpresence SC_3_parsers_1_parsers && return ${PARSER_SC_ERROR}
				
				for ((i=$(expr 0 + ${parser_startindex});${i}<$(expr ${#parser_ma_values[*]} + ${parser_startindex});i++))
				do
					parsers_parsers[${#parsers_parsers[*]}]="${parser_ma_values[${i}]}"
				done
				
				;;
			apps)
				parser_item=''
				${parser_optionhastail} && parser_item=${parser_optiontail}
				
				parser_subindex=0
				parser_optiontail=''
				parser_optionhastail=false
				[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
				local parser_ma_values=
				local parser_ma_local_count=0
				local parser_ma_total_count=${#parsers_apps[*]}
				unset parser_ma_values
				if [ ! -z "${parser_item}" ]
				then
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
				fi
				
				local parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				while [ ! -z "${parser_nextitem}" ] && [ "${parser_nextitem}" != '--' ] && [ ${parser_index} -lt ${parser_itemcount} ]
				do
					if [ ${parser_ma_local_count} -gt 0 ] && [ "${parser_nextitem:0:1}" = "-" ]
					then
						break
					fi
					
					parser_index=$(expr ${parser_index} + 1)
					parser_item="${parser_input[${parser_index}]}"
					[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
					parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				done
				if [ ${parser_ma_local_count} -eq 0 ]
				then
					parse_adderror "At least one argument expected for option \"${parser_option}\""
					return ${PARSER_SC_ERROR}
				fi
				! parse_setoptionpresence SC_3_parsers_2_apps && return ${PARSER_SC_ERROR}
				
				for ((i=$(expr 0 + ${parser_startindex});${i}<$(expr ${#parser_ma_values[*]} + ${parser_startindex});i++))
				do
					parsers_apps[${#parsers_apps[*]}]="${parser_ma_values[${i}]}"
				done
				
				;;
			tests)
				parser_item=''
				${parser_optionhastail} && parser_item=${parser_optiontail}
				
				parser_subindex=0
				parser_optiontail=''
				parser_optionhastail=false
				[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
				local parser_ma_values=
				local parser_ma_local_count=0
				local parser_ma_total_count=${#parsers_tests[*]}
				unset parser_ma_values
				if [ ! -z "${parser_item}" ]
				then
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
				fi
				
				local parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				while [ ! -z "${parser_nextitem}" ] && [ "${parser_nextitem}" != '--' ] && [ ${parser_index} -lt ${parser_itemcount} ]
				do
					if [ ${parser_ma_local_count} -gt 0 ] && [ "${parser_nextitem:0:1}" = "-" ]
					then
						break
					fi
					
					parser_index=$(expr ${parser_index} + 1)
					parser_item="${parser_input[${parser_index}]}"
					[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
					parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				done
				if [ ${parser_ma_local_count} -eq 0 ]
				then
					parse_adderror "At least one argument expected for option \"${parser_option}\""
					return ${PARSER_SC_ERROR}
				fi
				! parse_setoptionpresence SC_3_parsers_3_tests && return ${PARSER_SC_ERROR}
				
				for ((i=$(expr 0 + ${parser_startindex});${i}<$(expr ${#parser_ma_values[*]} + ${parser_startindex});i++))
				do
					parsers_tests[${#parsers_tests[*]}]="${parser_ma_values[${i}]}"
				done
				
				;;
			comments)
				! parse_setoptionpresence SC_3_parsers_4_comments && return ${PARSER_SC_ERROR}
				
				if ${parser_optionhastail} && [ ! -z "${parser_optiontail}" ]
				then
					parse_adderror "Option --${parser_option} does not allow an argument"
					parser_optiontail=''
					return ${PARSER_SC_ERROR}
				fi
				parsers_debugComments=true
				
				;;
			*)
				return ${PARSER_SC_SKIP}
				;;
			
			esac
		elif [ "${parser_item:0:1}" = "-" ] && [ ${#parser_item} -gt 1 ]
		then
			parser_optiontail="${parser_item:$(expr ${parser_subindex} + 2)}"
			parser_option="${parser_item:$(expr ${parser_subindex} + 1):1}"
			if [ -z "${parser_option}" ]
			then
				parser_subindex=0
				return ${PARSER_SC_OK}
			fi
			
			case "${parser_option}" in
			'p')
				parser_item=''
				${parser_optionhastail} && parser_item=${parser_optiontail}
				
				parser_subindex=0
				parser_optiontail=''
				parser_optionhastail=false
				[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
				local parser_ma_values=
				local parser_ma_local_count=0
				local parser_ma_total_count=${#parsers_parsers[*]}
				unset parser_ma_values
				if [ ! -z "${parser_item}" ]
				then
					if ! ([ "${parser_item}" = 'c' ] || [ "${parser_item}" = 'php' ] || [ "${parser_item}" = 'python' ] || [ "${parser_item}" = 'sh' ])
					then
						parse_adderror "Invalid value for option \"${parser_option}\""
						
						return ${PARSER_SC_ERROR}
					fi
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
				fi
				
				local parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				while [ ! -z "${parser_nextitem}" ] && [ "${parser_nextitem}" != '--' ] && [ ${parser_index} -lt ${parser_itemcount} ]
				do
					if [ ${parser_ma_local_count} -gt 0 ] && [ "${parser_nextitem:0:1}" = "-" ]
					then
						break
					fi
					
					parser_index=$(expr ${parser_index} + 1)
					parser_item="${parser_input[${parser_index}]}"
					[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
					if ! ([ "${parser_item}" = 'c' ] || [ "${parser_item}" = 'php' ] || [ "${parser_item}" = 'python' ] || [ "${parser_item}" = 'sh' ])
					then
						parse_adderror "Invalid value for option \"${parser_option}\""
						
						return ${PARSER_SC_ERROR}
					fi
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
					parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				done
				if [ ${parser_ma_local_count} -eq 0 ]
				then
					parse_adderror "At least one argument expected for option \"${parser_option}\""
					return ${PARSER_SC_ERROR}
				fi
				! parse_setoptionpresence SC_3_parsers_1_parsers && return ${PARSER_SC_ERROR}
				
				for ((i=$(expr 0 + ${parser_startindex});${i}<$(expr ${#parser_ma_values[*]} + ${parser_startindex});i++))
				do
					parsers_parsers[${#parsers_parsers[*]}]="${parser_ma_values[${i}]}"
				done
				
				;;
			'a')
				parser_item=''
				${parser_optionhastail} && parser_item=${parser_optiontail}
				
				parser_subindex=0
				parser_optiontail=''
				parser_optionhastail=false
				[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
				local parser_ma_values=
				local parser_ma_local_count=0
				local parser_ma_total_count=${#parsers_apps[*]}
				unset parser_ma_values
				if [ ! -z "${parser_item}" ]
				then
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
				fi
				
				local parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				while [ ! -z "${parser_nextitem}" ] && [ "${parser_nextitem}" != '--' ] && [ ${parser_index} -lt ${parser_itemcount} ]
				do
					if [ ${parser_ma_local_count} -gt 0 ] && [ "${parser_nextitem:0:1}" = "-" ]
					then
						break
					fi
					
					parser_index=$(expr ${parser_index} + 1)
					parser_item="${parser_input[${parser_index}]}"
					[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
					parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				done
				if [ ${parser_ma_local_count} -eq 0 ]
				then
					parse_adderror "At least one argument expected for option \"${parser_option}\""
					return ${PARSER_SC_ERROR}
				fi
				! parse_setoptionpresence SC_3_parsers_2_apps && return ${PARSER_SC_ERROR}
				
				for ((i=$(expr 0 + ${parser_startindex});${i}<$(expr ${#parser_ma_values[*]} + ${parser_startindex});i++))
				do
					parsers_apps[${#parsers_apps[*]}]="${parser_ma_values[${i}]}"
				done
				
				;;
			't')
				parser_item=''
				${parser_optionhastail} && parser_item=${parser_optiontail}
				
				parser_subindex=0
				parser_optiontail=''
				parser_optionhastail=false
				[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
				local parser_ma_values=
				local parser_ma_local_count=0
				local parser_ma_total_count=${#parsers_tests[*]}
				unset parser_ma_values
				if [ ! -z "${parser_item}" ]
				then
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
				fi
				
				local parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				while [ ! -z "${parser_nextitem}" ] && [ "${parser_nextitem}" != '--' ] && [ ${parser_index} -lt ${parser_itemcount} ]
				do
					if [ ${parser_ma_local_count} -gt 0 ] && [ "${parser_nextitem:0:1}" = "-" ]
					then
						break
					fi
					
					parser_index=$(expr ${parser_index} + 1)
					parser_item="${parser_input[${parser_index}]}"
					[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
					parser_ma_values[$(expr ${#parser_ma_values[*]} + ${parser_startindex})]="${parser_item}"
					parser_ma_total_count=$(expr ${parser_ma_total_count} + 1)
					parser_ma_local_count=$(expr ${parser_ma_local_count} + 1)
					parser_nextitem="${parser_input[$(expr ${parser_index} + 1)]}"
				done
				if [ ${parser_ma_local_count} -eq 0 ]
				then
					parse_adderror "At least one argument expected for option \"${parser_option}\""
					return ${PARSER_SC_ERROR}
				fi
				! parse_setoptionpresence SC_3_parsers_3_tests && return ${PARSER_SC_ERROR}
				
				for ((i=$(expr 0 + ${parser_startindex});${i}<$(expr ${#parser_ma_values[*]} + ${parser_startindex});i++))
				do
					parsers_tests[${#parsers_tests[*]}]="${parser_ma_values[${i}]}"
				done
				
				;;
			'C')
				! parse_setoptionpresence SC_3_parsers_4_comments && return ${PARSER_SC_ERROR}
				
				parsers_debugComments=true
				
				;;
			*)
				return ${PARSER_SC_SKIP}
				;;
			
			esac
		fi
		;;
	*)
		return ${PARSER_SC_SKIP}
		;;
	
	esac
	return ${PARSER_SC_OK}
}
parse_process_option()
{
	if [ ! -z "${parser_subcommand}" ] && [ "${parser_item}" != '--' ]
	then
		parse_process_subcommand_option && return ${PARSER_OK}
		[ ${parser_index} -ge ${parser_itemcount} ] && return ${PARSER_OK}
	fi
	
	parser_item="${parser_input[${parser_index}]}"
	
	[ -z "${parser_item}" ] && return ${PARSER_OK}
	
	if [ "${parser_item}" = '--' ]
	then
		for ((a=$(expr ${parser_index} + 1);${a}<=$(expr ${parser_itemcount} - 1);a++))
		do
			parse_addvalue "${parser_input[${a}]}"
		done
		parser_index=${parser_itemcount}
		return ${PARSER_OK}
	elif [ "${parser_item}" = "-" ]
	then
		return ${PARSER_OK}
	elif [ "${parser_item:0:2}" = "\-" ]
	then
		parse_addvalue "${parser_item:1}"
	elif [ "${parser_item:0:2}" = '--' ] 
	then
		parser_option="${parser_item:2}"
		parser_optionhastail=false
		if echo "${parser_option}" | grep '=' 1>/dev/null 2>&1
		then
			parser_optionhastail=true
			parser_optiontail="$(echo "${parser_option}" | cut -f 2- -d"=")"
			parser_option="$(echo "${parser_option}" | cut -f 1 -d"=")"
		fi
		
		case "${parser_option}" in
		temp)
			! parse_setoptionpresence G_1_temp && return ${PARSER_ERROR}
			
			if ${parser_optionhastail} && [ ! -z "${parser_optiontail}" ]
			then
				parse_adderror "Option --${parser_option} does not allow an argument"
				parser_optiontail=''
				return ${PARSER_ERROR}
			fi
			keepTemporaryFiles=true
			
			;;
		help)
			! parse_setoptionpresence G_2_help && return ${PARSER_ERROR}
			
			if ${parser_optionhastail} && [ ! -z "${parser_optiontail}" ]
			then
				parse_adderror "Option --${parser_option} does not allow an argument"
				parser_optiontail=''
				return ${PARSER_ERROR}
			fi
			displayHelp=true
			
			;;
		subcommand-names)
			! parse_setoptionpresence G_3_subcommand_names && return ${PARSER_ERROR}
			
			if ${parser_optionhastail} && [ ! -z "${parser_optiontail}" ]
			then
				parse_adderror "Option --${parser_option} does not allow an argument"
				parser_optiontail=''
				return ${PARSER_ERROR}
			fi
			displaySubcommandNames=true
			
			;;
		*)
			parse_addfatalerror "Unknown option \"${parser_option}\""
			return ${PARSER_ERROR}
			;;
		
		esac
	elif [ "${parser_item:0:1}" = "-" ] && [ ${#parser_item} -gt 1 ]
	then
		parser_optiontail="${parser_item:$(expr ${parser_subindex} + 2)}"
		parser_option="${parser_item:$(expr ${parser_subindex} + 1):1}"
		if [ -z "${parser_option}" ]
		then
			parser_subindex=0
			return ${PARSER_SC_OK}
		fi
		
		case "${parser_option}" in
		'T')
			! parse_setoptionpresence G_1_temp && return ${PARSER_ERROR}
			
			keepTemporaryFiles=true
			
			;;
		*)
			parse_addfatalerror "Unknown option \"${parser_option}\""
			return ${PARSER_ERROR}
			;;
		
		esac
	elif ${parser_subcommand_expected} && [ -z "${parser_subcommand}" ] && [ ${#parser_values[*]} -eq 0 ]
	then
		case "${parser_item}" in
		php)
			parser_subcommand="php"
			
			;;
		xsh)
			parser_subcommand="xsh"
			
			;;
		parsers)
			parser_subcommand="parsers"
			
			;;
		xslt | xsl)
			parser_subcommand="xslt"
			
			;;
		xsd | schema)
			parser_subcommand="xsd"
			
			;;
		*)
			parse_addvalue "${parser_item}"
			;;
		
		esac
	else
		parse_addvalue "${parser_item}"
	fi
	return ${PARSER_OK}
}
parse()
{
	parser_aborted=false
	parser_isfirstpositionalargument=true
	while [ ${parser_index} -lt ${parser_itemcount} ] && ! ${parser_aborted}
	do
		parse_process_option
		if [ -z "${parser_optiontail}" ]
		then
			parser_index=$(expr ${parser_index} + 1)
			parser_subindex=0
		else
			parser_subindex=$(expr ${parser_subindex} + 1)
		fi
	done
	
	if ! ${parser_aborted}
	then
		parse_setdefaultoptions
		parse_checkrequired
		parse_checkminmax
	fi
	
	
	
	
	
	local parser_errorcount=${#parser_errors[*]}
	return ${parser_errorcount}
}

ns_print_error()
{
	ns_print_colored_message "${NSXML_ERROR_COLOR}" "${@}" 1>&2
}
ns_error()
{
	local errno=
	if [ $# -gt 0 ]
	then
		errno=${1}
		shift
	else
		errno=1
	fi
	local message="${@}"
	if [ -z "${errno##*[!0-9]*}" ]
	then
		message="${errno} ${message}"
		errno=1
	fi
	ns_print_error "${message}"
	exit ${errno}
}
ns_isdir()
{
	local inputPath=
	if [ $# -gt 0 ]
	then
		inputPath="${1}"
		shift
	fi
	[ ! -z "${inputPath}" ] && [ -d "${inputPath}" ]
}
ns_issymlink()
{
	local inputPath=
	if [ $# -gt 0 ]
	then
		inputPath="${1}"
		shift
	fi
	[ ! -z "${inputPath}" ] && [ -L "${inputPath}" ]
}
ns_realpath()
{
	local __ns_realpath_in=
	if [ $# -gt 0 ]
	then
		__ns_realpath_in="${1}"
		shift
	fi
	local __ns_realpath_rl=
	local __ns_realpath_cwd="$(pwd)"
	[ -d "${__ns_realpath_in}" ] && cd "${__ns_realpath_in}" && __ns_realpath_in="."
	while [ -h "${__ns_realpath_in}" ]
	do
		__ns_realpath_rl="$(readlink "${__ns_realpath_in}")"
		if [ "${__ns_realpath_rl#/}" = "${__ns_realpath_rl}" ]
		then
			__ns_realpath_in="$(dirname "${__ns_realpath_in}")/${__ns_realpath_rl}"
		else
			__ns_realpath_in="${__ns_realpath_rl}"
		fi
	done
	
	if [ -d "${__ns_realpath_in}" ]
	then
		__ns_realpath_in="$(cd -P "$(dirname "${__ns_realpath_in}")" && pwd)"
	else
		__ns_realpath_in="$(cd -P "$(dirname "${__ns_realpath_in}")" && pwd)/$(basename "${__ns_realpath_in}")"
	fi
	
	cd "${__ns_realpath_cwd}" 1>/dev/null 2>&1
	echo "${__ns_realpath_in}"
}
ns_relativepath()
{
	local from=
	if [ $# -gt 0 ]
	then
		from="${1}"
		shift
	fi
	local base=
	if [ $# -gt 0 ]
	then
		base="${1}"
		shift
	else
		base="."
	fi
	[ -r "${from}" ] || return 1
	[ -r "${base}" ] || return 2
	[ ! -d "${base}" ] && base="$(dirname "${base}")"  
	[ -d "${base}" ] || return 3
	from="$(ns_realpath "${from}")"
	base="$(ns_realpath "${base}")"
	c=0
	sub="${base}"
	newsub=''
	while [ "${from:0:${#sub}}" != "${sub}" ]
	do
		newsub="$(dirname "${sub}")"
		[ "${newsub}" == "${sub}" ] && return 4
		sub="${newsub}"
		c="$(expr ${c} + 1)"
	done
	res='.'
	for ((i=0;${i}<${c};i++))
	do
		res="${res}/.."
	done
	[ "${sub}" != '/' ] \
		&& res="${res}${from#${sub}}" \
		|| res="${res}${from}"
	res="${res#./}"
	[ -z "${res}" ] && res='.'
	echo "${res}"
}
ns_mktemp()
{
	local __ns_mktemp_template=
	if [ $# -gt 0 ]
	then
		__ns_mktemp_template="${1}"
		shift
	else
		__ns_mktemp_template="$(date +%s)-XXXX"
	fi
	local __ns_mktemp_xcount=
	if which 'mktemp' 1>/dev/null 2>&1
	then
		# Auto-fix template
		__ns_mktemp_xcount=0
		which 'grep' 1>/dev/null 2>&1 \
		&& which 'wc' 1>/dev/null 2>&1 \
		&& __ns_mktemp_xcount=$(grep -o X <<< "${__ns_mktemp_template}" | wc -c)
		while [ ${__ns_mktemp_xcount} -lt 3 ]
		do
			__ns_mktemp_template="${__ns_mktemp_template}X"
			__ns_mktemp_xcount=$(expr ${__ns_mktemp_xcount} + 1)
		done
		mktemp -t "${__ns_mktemp_template}" 2>/dev/null
	else
	local __ns_mktemp_root=
	# Fallback to a manual solution
		for __ns_mktemp_root in "${TMPDIR}" "${TMP}" '/var/tmp' '/tmp'
		do
			[ -d "${__ns_mktemp_root}" ] && break
		done
		[ -d "${__ns_mktemp_root}" ] || return 1
	local __ns_mktemp="/${__ns_mktemp_root}/${__ns_mktemp_template}.$(date +%s)-${RANDOM}"
	touch "${__ns_mktemp}" 1>/dev/null 2>&1 && echo "${__ns_mktemp}"
	fi
}
ns_mktempdir()
{
	local __ns_mktemp_template=
	if [ $# -gt 0 ]
	then
		__ns_mktemp_template="${1}"
		shift
	else
		__ns_mktemp_template="$(date +%s)-XXXX"
	fi
	local __ns_mktemp_xcount=
	if which 'mktemp' 1>/dev/null 2>&1
	then
		# Auto-fix template
		__ns_mktemp_xcount=0
		which 'grep' 1>/dev/null 2>&1 \
		&& which 'wc' 1>/dev/null 2>&1 \
		&& __ns_mktemp_xcount=$(grep -o X <<< "${__ns_mktemp_template}" | wc -c)
		
		while [ ${__ns_mktemp_xcount} -lt 3 ]
		do
			__ns_mktemp_template="${__ns_mktemp_template}X"
			__ns_mktemp_xcount=$(expr ${__ns_mktemp_xcount} + 1)
		done
		mktemp -d -t "${__ns_mktemp_template}" 2>/dev/null
	else
	local __ns_mktemp_root=
	# Fallback to a manual solution
		for __ns_mktemp_root in "${TMPDIR}" "${TMP}" '/var/tmp' '/tmp'
		do
			[ -d "${__ns_mktemp_root}" ] && break
		done
		[ -d "${__ns_mktemp_root}" ] || return 1
	local __ns_mktempdir="/${__ns_mktemp_root}/${__ns_mktemp_template}.$(date +%s)-${RANDOM}"
	mkdir -p "${__ns_mktempdir}" 1>/dev/null 2>&1 && echo "${__ns_mktempdir}"
	fi
}
ns_which()
{
	local result=1
	if [ "$(uname -s)" = 'Darwin' ]
	then
		which "${@}" && result=0
	else
	local silent="false"
	local args=
	while [ ${#} -gt 0 ]
		do
			if [ "${1}" = '-s' ]
			then 
				silent=true
			else
				[ -z "${args}" ] \
					&& args="${1}" \
					|| args=("${args[@]}" "${1}")
			fi
			shift
		done
		
		if ${silent}
		then
			which "${args[@]}" 1>/dev/null 2>&1 && result=0
		else
			which "${args[@]}" && result=0
		fi
	fi
	return ${result}
}
scriptFilePath="$(ns_realpath "${0}")"
scriptPath="$(dirname "${scriptFilePath}")"
scriptName="$(basename "${scriptFilePath}")"
rootPath="$(ns_realpath "${scriptPath}/../..")"
cwd="$(pwd)"

if ! parse "${@}"
then
	${displayHelp} \
		&& usage "${parser_subcommand}"&& exit 0

	${displaySubcommandNames} \
		&& for n in "${parser_subcommand_names[@]}"; do echo "${n}"; done \
		&& exit 0
	
	parse_displayerrors
	exit 1
fi

${displayHelp} && usage "${parser_subcommand}" && exit 0
${displaySubcommandNames} \
	&& for n in "${parser_subcommand_names[@]}"; do echo "${n}"; done \
	&& exit 0

projectPath="$(ns_realpath "${scriptPath}/../..")"
logFile="${projectPath}/${scriptName}.log"
rm -f "${logFile}"

NORMAL_COLOR==''
ERROR_COLOR=''
SUCCESS_COLOR=''

# http://stackoverflow.com/questions/4332478/read-the-current-text-color-in-a-xterm/4332530#4332530
NORMAL_COLOR="$(tput -Txterm-basic sgr0)"
ERROR_COLOR="$(tput -Txterm-basic setaf 1)"
SUCCESS_COLOR="$(tput -Txterm-basic setaf 2)"

log()
{
	echo "${@}" >> "${logFile}"
}

check_zsh()
{
	zshVersion="$(zsh --version | cut -f 2 -d" ")"
	zshM="$(echo "${zshVersion}" | cut -f 1 -d.)"
	zshm="$(echo "${zshVersion}" | cut -f 2 -d.)"
	zshp="$(echo "${zshVersion}" | cut -f 3 -d.)"
	[ ${zshM} -lt 4 ] && return 1;
	[ ${zshM} -eq 4 ] && [ ${zshm} -lt 3 ] && return 1;
	[ ${zshM} -eq 4 ] && [ ${zshm} -eq 3 ] && [ ${zshp} -lt 13 ] && return 1;
	
	return 0
}

[ -z "${TRAVIS}" ] && TRAVIS=false
platform="$(uname -s)"

if [ "${parser_subcommand}" = 'parsers' ]
then
	parsers=("${parsers_parsers[@]}")
	apps=("${parsers_apps[@]}")
	tests=("${parsers_tests[@]}")
			
	parserTestsPathBase="${projectPath}/tests/parsers"
	tmpShellStylesheet="$(ns_mktemp "shell-xsl")"
	programSchemaVersion="2.0"
	xshStylesheet="${projectPath}/ns/xsl/program/${programSchemaVersion}/xsh.xsl"
	
	
	for major in 2 3
	do
		for minor in 0 1 2 3 4 5 6 7 8 9
		do
			p="python${major}.${minor}"
			if ns_which -s "${p}"
			then
				log "Enable Python ${major}.${minor}"
				pythonInterpreters=("${pythonInterpreters[@]}" "${p}")
			fi
		done
	done
	
	# Supported shells
	shells=(bash zsh ksh)
	for s in ${shells[@]}
	do
		if ns_which -s ${s}
		then
			check_func="check_${s}"
			if [ "$(type -t "${check_func}")" != 'function' ] || ${check_func}
			then
				log "Enable ${s} $(${s} --version 2>&1 | head -n 1 | xargs echo)"
				available_shells[${#available_shells[@]}]=${s}
			fi
		fi
	done
	
	# C compilers
	if [ ! -z "${CC}" ] && ns_which -s "${CC}"
	then
		cc=${CC}
	else
		for c in cc gcc clang
		do
			if ns_which -s ${c}
			then
				cc=${c}
				log "Enable C compiler (${cc})"
				break
			fi
		done
	fi
	
	if [ -z "${CFLAGS}" ]
	then
		cflags=(-Wall -pedantic -Wextra -Wconversion -g -O0 -DNSXML_ASSERT)
	else
		cflags=(${CFLAGS})
	fi

	sharedLibraryCFlags='-shared'
	[ "${platform}" = 'Darwin' ] \
		&& sharedLibraryCflags='-dynamiclib'
	cflags=("${cflags[@]}" \
	-fvisibility=hidden \
		-Werror)
	
	# Test groups
	if [ ${#apps[@]} -eq 0 ]
	then
		while read d
		do
			selectedApps=("${selectedApps[@]}" "$(basename "${d}")")
		done << EOF
		$(find "${parserTestsPathBase}/apps" -mindepth 1 -maxdepth 1 -type d | sort)
EOF
	else
		for app in "${apps[@]}"
		do
			d="${parserTestsPathBase}/apps/${app}"
			if [ -d "${d}" ]
			then
				selectedApps=("${selectedApps[@]}" "${app}")
			fi
		done
	fi
	
	# Parsers to test
	testSh=false
	testPython=false
	testC=false
	testValgrind=false
	testPHP=false
	
	if [ ${#parsers[@]} -eq 0 ]
	then
		# Autodetect available parsers
		if [ ${#available_shells[@]} -gt 0 ]
		then
			parsers=("${parsers[@]}" sh)
			testSh=true
		fi
		
		if [ "${#pythonInterpreters[@]}" -gt 0 ]
		then
			parsers=("${parsers[@]}" python)
			testPython=true
		fi
		
		if ns_which -s ${cc}
		then
			parsers=("${parsers[@]}" c)
			testC=true
			if ns_which -s valgrind
			then
				testValgrind=true
			fi
		fi
		
		if ns_which -s php
		then
			parsers=("${parsers[@]}" php)
			testPHP=true
		fi
	else
		for parser in "${parsers[@]}"
		do
			if [ "${parser}" = 'sh' ] && [ ${#available_shells[@]} -gt 0 ]
			then
				testSh=true
			elif [ "${parser}" = 'python' ] && [ ${#pythonInterpreters[@]} -gt 0 ]
			then
				testPython=true
			elif [ "${parser}" = 'c' ] && ns_which -s ${cc}
			then
				testC=true
				if ns_which -s valgrind
				then
					testValgrind=true
				fi
			elif [ "${parser}" = 'php' ] && ns_which -s php
			then
				testPHP=true
			fi
		done 
	fi
	
	resultLineFormat="%20.20s |"
	if ${testSh}
	then
		parserNames=("${parserNames[@]}" "${available_shells[@]}")
		
		for s in "${available_shells[@]}"
		do
			resultLineFormat="${resultLineFormat} %-7s |"	
		done
	fi
	
	if ${testPython}
	then
		#parserNames=("${parserNames[@]}" 'Python')	
		#resultLineFormat="${resultLineFormat} %-7s |"
		
		for p in "${pythonInterpreters[@]}"
		do
			pyVersion="$(echo "${p}" | sed "s,python\(.*\),\\1,g")"
			parserNames=("${parserNames[@]}" "py ${pyVersion}")
			resultLineFormat="${resultLineFormat} %-7s |"
		done
		
		log 'Update Python parser XSLT' 
		"${scriptPath}/update-python-parser.sh"
	fi
	
	if ${testC}
	then
		parserNames=("${parserNames[@]}" "C/${cc}")
		if ${testValgrind}
		then
			parserNames=("${parserNames[@]}" "C/Valgrind")
		fi
			
		log 'Update C parser XSLT'
		"${scriptPath}/update-c-parser.sh"
		resultLineFormat="${resultLineFormat} %-7s |"
		
		# Valgrind
		if ${testValgrind}
		then
			resultLineFormat="${resultLineFormat} %-10s |"
		
			testValgrind=true
			valgrindArgs=("--tool=memcheck" "--leak-check=full" "--undef-value-errors=yes" "--xml=yes")
			if [ "${platform}" = 'Darwin' ]
			then
				valgrindArgs=("${valgrindArgs[@]}" \
					"--dsymutil=yes" \
					"--suppressions=\"${rootPath}/resources/valgrind/Darwin.supp\""
					)
			fi
			
			valgrindOutputXslFile="$(ns_mktemp "valgrind-xsl")"
			cat > "${valgrindOutputXslFile}" << EOF
	<stylesheet version="1.0" xmlns="http://www.w3.org/1999/XSL/Transform" xmlns:prg="http://xsd.nore.fr/program">
	<output method="text" encoding="utf-8" />
	    <template match="/">
	    	<value-of select="count(//error)" />
	    </template>
	</stylesheet>
EOF
		fi
	fi
	
	if ${testPHP}
	then
		parserNames=("${parserNames[@]}" 'PHP')
			
		log 'Update PHP parser XSLT'
		"${scriptPath}/update-php-parser.sh"
		resultLineFormat="${resultLineFormat} %-7s |"
	fi
	
	# Result column
	resultLineFormat="${resultLineFormat} %7s\n"
	
	echo "Apps: ${selectedApps[@]}"
	echo "Parsers: ${parserNames[@]}"
	
	if ${testC}
	then
		echo 'C flags:' "${cflags[@]}"
		cParserLibraryName='parser-lib'
		cParserLibraryExtension='so'
		[ "${platform}" = 'Darwin' ] \
			&& cParserLibraryExtension='dylib'
		
		cParserSourcePath="${parserTestsPathBase}/derived/src"
		mkdir -p "${cParserSourcePath}" \
			|| ns_error 'Failed to create C parser source path'
		
		cParserDerivedPath="${parserTestsPathBase}/derived/lib"
		mkdir -p "${cParserDerivedPath}" \
			|| ns_error 'Failed to create C parser derived path'
			
		log 'Create C parser base library'
		"${projectPath}/ns/sh/build-c.sh" \
			--base \
			--overwrite \
			--output "${cParserSourcePath}" \
			--file-base "${cParserLibraryName}" \
			|| ns_error 'Failed to create C parser library files'
			
			
			
			log 'Build C parser base library'
			libraryFileArguments=(\
				"${cParserSourcePath}/${cParserLibraryName}.c")
			[ "${platform}" != 'Darwin' ] \
				&& libraryFileArguments=(\
					-c \
					"${libraryFileArguments[@]}")
			${cc} \
				"${cflags[@]}" \
				-o "${cParserDerivedPath}/lib${cParserLibraryName}.${cParserLibraryExtension}" \
				${sharedLibraryCflags} \
				"${libraryFileArguments[@]}" \
			|| ns_error 'Failed to build C parser base library'
	fi
	
	# Testing ...
	for app in "${selectedApps[@]}"
	do
		d="${parserTestsPathBase}/apps/${app}"
		
		groupTestBasePath="${d}/tests"
		
		unset groupTests
		
		# Populate group tests
		if [ ${#tests[@]} -eq 0 ]
		then
			while read t
			do
				[ -z "${t}" ] && continue
				groupTests[${#groupTests[@]}]="$(basename "${t}")"
			done << EOF
			$(find "${groupTestBasePath}" -mindepth 1 -maxdepth 1 -type f -name "*.cli" | sort)
EOF
		else
			for test in "${tests[@]}"
			do
				tn="${groupTestBasePath}/${test}.cli"
				if [ -f "${tn}" ]
				then 
					groupTests=("${groupTests[@]}" "${test}.cli")
				fi
			done
		fi
		
		if [ ${#groupTests[@]} -eq 0 ]
		then
			continue
		fi
			
		echo "${app} (${#groupTests[@]} tests)"
		printf "${resultLineFormat}" "Test" "${parserNames[@]}" 'RESULT'
		
		# Per group initializations
		xmlDescription="${d}/xml/program.xml"
		tmpScriptBasename="${d}/program"
		
		if ${testSh}
		then
			xshFile="${tmpScriptBasename}-xsh.xsh"
			xshBodyFile="${tmpScriptBasename}-xsh.body.sh"
			log "Generate ${app} XSH file (${xshBodyFile} => ${xshFile})"
			cat > "${xshFile}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<xsh:program xmlns:prg="http://xsd.nore.fr/program" xmlns:xsh="http://xsd.nore.fr/xsh" xmlns:xi="http://www.w3.org/2001/XInclude">
<xsh:info>
	<xi:include href="xml/program.xml" />
</xsh:info>
<xsh:functions>
	<xi:include href="../../lib/functions.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function)" />
</xsh:functions>
<xsh:code>
<xi:include href="./$(basename "${xshBodyFile}")" parse="text" />
</xsh:code>
</xsh:program>
EOF
			xsltproc --xinclude -o "${xshBodyFile}" "${parserTestsPathBase}/lib/sh-unittestprogram.xsl" "${xmlDescription}" || ns_error "Failed to create ${xshBodyFile}"  
			
			for s in ${available_shells[@]}
			do
				shScript="${tmpScriptBasename}.${s}"
				shScripts[${#shScripts[@]}]="${shScript}"
				buildShScriptArgs=(\
					-i ${s} \
					-p \
					-x "${xmlDescription}" \
					-s "${xshFile}" \
					-o "${shScript}"\
				)
				
				${parsers_debugComments} \
					&& buildShScriptArgs=(\
						"${buildShScriptArgs[@]}" \
						--debug-comments \
					)
				
				log "Generating ${app} ${s} program (${buildShScriptArgs[@]})"
				"${projectPath}/ns/sh/build-shellscript.sh" \
					"${buildShScriptArgs[@]}" \
				|| ns_error "Failed to create ${shScript}" 
				chmod 755 "${shScript}"
			done
			
			${keepTemporaryFiles} || rm -f "${xshBodyFile}"
		fi
		
		if ${testPython}
		then
			# Create python module
			pyParser="${d}/Parser.py"
			pyInfo="${d}/ProgramInfo.py"
			pyProgramBase="${tmpScriptBasename}-exe-"
			
			log 'Create Python parser module'
			"${projectPath}/ns/sh/build-python.sh" -b \
				-x "${xmlDescription}" \
				-c 'TestProgramInfo' \
				-o "${pyParser}" || ns_error "Failed to generated python module"
				
			log 'Create Python program info module'
			"${projectPath}/ns/sh/build-python.sh" \
				-i 'Parser' \
				-x "${xmlDescription}" \
				-c 'TestProgramInfo' \
				-o "${pyInfo}" || ns_error "Failed to generated Python program info module"
				
			log 'Generate python scripts'
			unset pyPrograms
			for p in "${pythonInterpreters[@]}"
			do
				pyProgram="${pyProgramBase}${p}.py"
				pyPrograms=("${pyPrograms[@]}" "${pyProgram}")
				xsltproc --xinclude -o "${pyProgram}" \
				--stringparam interpreter \
				${p} "${parserTestsPathBase}/lib/python-unittestprogram.xsl" "${xmlDescription}" || ns_error "Failed to create ${pyProgram}"
				chmod 755 "${pyProgram}"
			done
		fi
		
		if ${testC}
		then
			cParserBase="${tmpScriptBasename}-parser"
			cProgram="${tmpScriptBasename}-exe"
			xsltproc --xinclude -o "${cProgram}.c" \
				"${parserTestsPathBase}/lib/c-unittestprogram.xsl" \
				"${xmlDescription}" || ns_error "Failed to create ${cProgram} source"
			
			log 'Create C program parser'
			"${projectPath}/ns/sh/build-c.sh" \
				--overwrite \
				--include "${cParserSourcePath}/parser-lib.h" \
				-x "${xmlDescription}" \
				--output "$(dirname "${tmpScriptBasename}")" \
				--file-base "$(basename "${cParserBase}")" \
				--prefix 'app' || ns_error 'Failed to generated C parser'
				
			log 'Build C program'
			${cc} "${cflags[@]}" \
				-I"${cParserSourcePath}" \
				-L"${cParserDerivedPath}" \
				-l"${cParserLibraryName}" \
				-o "${cProgram}" \
				"${cProgram}.c" "${cParserBase}.c" \
			|| ns_error 'Failed to build C program'
		fi
		
		if ${testPHP}
		then
			phpLibrary="${tmpScriptBasename}-lib.php"
			phpProgram="${tmpScriptBasename}-exe.php"
			log 'Create PHP program info'
			"${projectPath}/ns/sh/build-php.sh" -e \
				-x "${xmlDescription}" \
				-c 'TestProgramInfo' \
				-o "${phpLibrary}" || ns_error "Failed to generated PHP module"
				
			log 'Create program'
			xsltproc --xinclude -o "${phpProgram}" \
				"${parserTestsPathBase}/lib/php-unittestprogram.xsl" \
				"${xmlDescription}" || ns_error "Failed to create ${phpProgram}"
			chmod 755 "${phpProgram}"
		fi
			
		log 'Run test(s)'
		for test in "${groupTests[@]}"
		do
			t="${groupTestBasePath}/${test}"
			base="${t%.cli}"
			testnumber="$(basename "${base}")"
			result="${base}.result"
			expected="${base}.expected"
			# Create a temporary script
			tmpShellScript="${tmpScriptBasename}-test-${app}-${testnumber}.sh"
			cat > "${tmpShellScript}" << EOFSH
	#!/usr/bin/env bash
EOFSH
			cli="$(cat "${t}")"
			if ${testSh} && [ ! -f "${base}.no-sh" ]
			then
				cat >> "${tmpShellScript}" << EOFSH
	$(
	shi=0
	for s in ${available_shells[@]}
	do
		shScript="${shScripts[${shi}]}"
		echo "\"${shScript}\" "${cli[@]}" > \"${result}-${s}\" 2>>\"${logFile}\""
		shi=$(expr ${shi} + 1)
	done)
EOFSH
			fi
			if ${testPython} && [ ! -f "${base}.no-python" ]
			then
				pi=0
				for p in "${pythonInterpreters[@]}"
				do
					pyProgram="${pyPrograms[${pi}]}"
					cat >> "${tmpShellScript}" << EOFSH
	"${pyProgram}" ${cli} > "${result}-${p}"  2>>"${logFile}"
EOFSH
					pi=$(expr "${pi}" + 1)
				done
			fi
			
			if ${testC} && [ ! -f "${base}.no-c" ]
			then
				cat >> "${tmpShellScript}" << EOFSH
	"${cProgram}" ${cli} > "${result}-c"  2>>"${logFile}"
EOFSH
				if ${testValgrind}
				then
					valgrindXmlFile="${base}.result-valgrind.xml"
					cat >> "${tmpShellScript}" << EOSH
	valgrind ${valgrindArgs[@]} --xml-file="${valgrindXmlFile}" "${cProgram}" ${cli} 1>/dev/null 2>&1
EOSH
									
				fi
			fi
			
			if ${testPHP} && [ ! -f "${base}.no-php" ]
			then
				cat >> "${tmpShellScript}" << EOFSH
	"${phpProgram}" ${cli} > "${result}-php"  2>>"${logFile}"
EOFSH
			fi
			
			log " ---- ${app}/${testnumber} ---- "
			
			# Run parsers
			chmod 755 "${tmpShellScript}"	
			"${tmpShellScript}" 2>> "${logFile}"
			
			# Analyze results
			
			resultLine=
			resultLine[0]="    ${testnumber}"
			
			passed=true
			if [ -f "${expected}" ]
			then
				i=0
				if ${testSh}
				then
					if [ -f "${base}.no-sh" ]
					then
						for s in ${available_shells[@]}
						do
							resultLine[${#resultLine[@]}]='skipped'
						done
					else
						for s in ${available_shells[@]}
						do
							if [ ! -f "${result}-${s}" ] || ! diff "${expected}" "${result}-${s}" >> "${logFile}"
							then
								passed=false
								resultLine[${#resultLine[@]}]='FAILED'
							else
								resultLine[${#resultLine[@]}]='passed'
								${keepTemporaryFiles} || rm -f "${result}-${s}"
							fi
							i=$(expr ${i} + 1)
						done
					fi
				fi
				
				if ${testPython}
				then
					if [ -f "${base}.no-python" ]
					then
						for p in "${pythonInterpreters[@]}"
						do
							resultLine[${#resultLine[@]}]='skipped'
						done
					else
						for p in "${pythonInterpreters[@]}"
						do
							if [ ! -f "${result}-${p}" ] || ! diff "${expected}" "${result}-${p}" >> "${logFile}"
							then
								passed=false
								resultLine[${#resultLine[@]}]='FAILED'
							else
								resultLine[${#resultLine[@]}]='passed'
								${keepTemporaryFiles} || rm -f "${result}-${p}"
							fi
						done
					fi
				fi
				
				if ${testC}
				then
					if [ -f "${base}.no-c" ]
					then
						resultLine[${#resultLine[@]}]='skipped'
						${testValgrind} && resultLine[${#resultLine[@]}]='skipped'
					else
						if [ ! -f "${result}-c" ] || ! diff "${expected}" "${result}-c" >> "${logFile}"
						then
							passed=false
							resultLine[${#resultLine[@]}]='FAILED'
							${testValgrind} && resultLine[${#resultLine[@]}]='skipped'
						else
							resultLine[${#resultLine[@]}]='passed'
							${keepTemporaryFiles} || rm -f "${result}-c"
						
							# Valgrind
							if ${testValgrind}
							then
								if [ -f "${valgrindXmlFile}" ] 
								then
									res=$(xsltproc "${valgrindOutputXslFile}" "${valgrindXmlFile}")
									if [ ! -z "${res}" ] && [ ${res} -eq 0 ]
									then
										resultLine[${#resultLine[@]}]='passed'
										${keepTemporaryFiles} || rm -f "${valgrindXmlFile}"
										${keepTemporaryFiles} || rm -f "${valgrindShellFile}"
									else
										passed=false
										resultLine[${#resultLine[@]}]='LEAK'
									fi
								else
									passed=false
									resultLine[${#resultLine[@]}]='CALLERROR'
								fi
							fi
						fi
					fi
				fi
				
				if ${testPHP}
				then
					if [ -f "${base}.no-php" ]
					then
						resultLine[${#resultLine[@]}]='skipped'
					else
						if [ ! -f "${result}-php" ] || ! diff "${expected}" "${result}-php" >> "${logFile}"
						then
							passed=false
							resultLine[${#resultLine[@]}]='FAILED'
						else
							resultLine[${#resultLine[@]}]='passed'
							${keepTemporaryFiles} || rm -f "${result}-php"
						fi
					fi
				fi
			else
				# Test does not have a 'expected' result yet
				passed=true
				
				if ${testSh}
				then
					for s in ${available_shells[@]}
					do
						resultLine[${#resultLine[@]}]='IGNORED'
					done
				fi
				
				${testPython} && resultLine[${#resultLine[@]}]='IGNORED'
				${testC} && resultLine[${#resultLine[@]}]='IGNORED'
				${testValgrind} && resultLine[${#resultLine[@]}]='IGNORED'
				${testPHP} && resultLine[${#resultLine[@]}]='IGNORED'
				
				# Copy one of the result as the 'expected' file
				if ${testC}
				then
					cp "${result}-c" "${expected}"
				elif ${testPython}
				then
					for p in "${pythonInterpreters[@]}"
					do
						[ -f "${result}-${p}" ] && cp "${result}-${p}" "${expected}" && break
					done
				elif ${testPHP}
				then
					cp "${result}-php" "${expected}"
				elif ${testSb}
				then
					for s in ${available_shells[@]}
					do
						[ -f "${result}-${s}" ] && cp "${result}-${s}" "${expected}" && break	
					done
				fi
			fi
					
			if ${passed}
			then
				resultLine[${#resultLine[@]}]='passed'
				${keepTemporaryFiles} || rm -f "${tmpShellScript}"
			else
				resultLine[${#resultLine[@]}]='FAILED'
			fi
			
			# NB: printf doesn't like tput. So we do a post transformation
			printf "${resultLineFormat}" "${resultLine[@]}" \
				| sed "s,passed,${SUCCESS_COLOR}passed${NORMAL_COLOR},g" \
				| sed "s,FAILED,${ERROR_COLOR}FAILED${NORMAL_COLOR},g"
			unset resultLine
		done
		
		# Remove per-group temporary files if no error
		
		if ${testSh}
		then
			si=0
			hasErrors=false
			for s in ${available_shells[@]}
			do
				if [ $(find "${d}/tests" -name "*.result-${s}" | wc -l) -eq 0 ]
				then
					${keepTemporaryFiles} || rm -f "${shScripts[${si}]}"
				else
					hasErrors=true
				fi
				si=$(expr ${si} + 1)
			done
			if ! ${hasErrors}
			then
				${keepTemporaryFiles} || rm -f "${xshFile}"
			fi
			unset shScripts
		fi
		
		if ${testPython}
		then
			pi=${parser_startindex}
			hasErrors=false
			for p in "${pythonInterpreters[@]}"
			do
				if [ $(find "${d}/tests" -name "*.result-${p}" | wc -l) -eq 0 ]
				then
					${keepTemporaryFiles} || rm -f "${pyPrograms[${pi}]}"
				else
					hasErrors=true
				fi
				
				# Python cache files are always removed
				rm -f "${pyPrograms[${pi}]}c"
				rm -fr "${d}/__pycache__"
				
				pi=$(expr ${pi} + 1)
			done
			
			if ! ${hasErrors}
			then
				${keepTemporaryFiles} || rm -f "${pyInfo}"
				${keepTemporaryFiles} || rm -f "${pyParser}"
			fi
			
			rm -f "${pyInfo}c"
			rm -f "${pyParser}c"
					
			unset pyPrograms
		fi
		
		if ${testC}
		then
			if [ $(find "${d}/tests" -name "*.result-c" | wc -l) -eq 0 ]
			then
				${keepTemporaryFiles} || rm -f "${cProgram}"
				${keepTemporaryFiles} || rm -f "${cProgram}.c"
				${keepTemporaryFiles} || rm -f "${cParserBase}.h"
				${keepTemporaryFiles} || rm -f "${cParserBase}.c"
				# Mac OS X
				${keepTemporaryFiles} || rm -fr "${cProgram}.dSYM"
			fi
		fi
		
		if ${testPHP}
		then
			if [ $(find "${d}/tests" -name "*.result-php" | wc -l) -eq 0 ]
			then
				${keepTemporaryFiles} || rm -f "${phpProgram}"
				${keepTemporaryFiles} || rm -f "${phpLibrary}"
			fi
		fi
	done
	
	${testC} && 
if ${testC} && ! ${keepTemporaryFiles}
then
	${testValgrind} && rm -f "${valgrindOutputXslFile}"
	rm -fr "${cParserSourcePath}"
	rm -fr "${cParserDerivedPath}" 
fi	
	
	count=0
	while read result
	do
		expected="$(sed -E 's,(.*)\..*$,\1,g' <<< "${result}").expected"
		[ -f "${expected}" ] || continue		
		if ! diff -q "${result}" "${expected}" 1>/dev/null 2>&1 
		then
			count=$(expr ${count} + 1)
			if ${TRAVIS}
			then
				echo "-- ${result} -----------------------"
				cat "${result}"
			fi
		fi 
	done << EOF
$(find "${parserTestsPathBase}" -name "*.result-*")
EOF
	if ${TRAVIS} && [ ${count} -gt 0 ]
	then
		echo '-- LOG ---------------'
		cat "${logFile}"	
	fi

	exit ${count}
elif [ "${parser_subcommand}" = 'php' ]
then
	if ! ns_which -s php
	then
		ns_warn "warning: No PHP interpreter found"
		exit 0
	fi
	
	phpunitPath="${projectPath}/vendor/bin/phpunit"
	phpunitBootstrapPath="${projectPath}/vendor/autoload.php"
	if [ ! -x "${phpunitPath}" ]
	then
		if ns_which -s composer
		then
			cd "${projectPath}" \
			&& composer install
		fi
	fi
	
	if [ ! -x "${phpunitPath}" ]
	then
		ns_warn 'warning: phpunit not found'
		exit 0
	fi
	
	phpTestsPathBase="${projectPath}/tests/php"
	phpTestResult=0
	unset phpFailedTestResultFiles
	phpFailedTestResultFiles=()
	testResultFormat="%-40.40s | %-8s\n"
	
	printf "${testResultFormat}" 'TEST' 'RESULT'
	
	while read testFile
	do
		testName="$(basename "${testFile}" Test.php)"
		resultFile="${testFile%php}result"
		
		if "${phpunitPath}" \
			--bootstrap "${phpunitBootstrapPath}" \
			"${testFile}" \
			>"${resultFile}"
		then
			testResultString="${SUCCESS_COLOR}passed${NORMAL_COLOR}"
			${keepTemporaryFiles} || rm -f "${resultFile}"
		else
			testResultString="${ERROR_COLOR}PAILED${NORMAL_COLOR}"
			phpTestResult=$(expr ${phpTestResult} + 1)
			phpFailedTestResultFiles=(\
				"${phpFailedTestResultFiles[@]}" \
				"${resultFile}" \
			)
		fi
		
		printf "${testResultFormat}" "${testName}" "${testResultString}"
		
	done << EOF
$(find "${phpTestsPathBase}" -name '*Test.php')
EOF

[ ${phpTestResult} -eq 0 ] \
&& testResultString="${SUCCESS_COLOR}passed${NORMAL_COLOR}" \
|| testResultString="${ERROR_COLOR}PAILED${NORMAL_COLOR}"

	printf "${testResultFormat}" "$(printf '%.0s-' {1..40})" "${testResultString}"

	if [ ${phpTestResult} -gt 0 ]
	then
		cat "${phpFailedTestResultFiles[@]}"
	fi

	exit ${phpTestResult}

elif [ "${parser_subcommand}" = 'xsh' ]
then
	xshTestsPathBase="${projectPath}/tests/xsh"
	xshTestProgramStylesheet="${xshTestsPathBase}/testprogram.xsl"
	xshTestResult=0
	c=${#parser_values[@]}
	testResultFormat="%-40.40s | %-8s\n"
	[ -f "${xsh_stdout}" ] && rm -f "${xsh_stdout}"
	[ -f "${xsh_stderr}" ] && rm -f "${xsh_stderr}"
	while read test
	do
		xshTestBase="$(basename "${test}")"
		xshTestBase="${xshTestBase%.xsh}"
		if [ ${c} -gt 0 ]
		then
			xshTestFound=false
			for t in "${parser_values[@]}"
			do
				[ "${t}" = "${xshTestBase}" ] && xshTestFound=true && break 
			done 
			${xshTestFound} || continue
		fi
		
		printf "${testResultFormat}" "${xshTestBase}" 'RESULT'
	
		xshTestProgram="$(dirname "${test}")/${xshTestBase}.run"
		testResult=false	
		xsltproc --output "${xshTestProgram}" \
				--xinclude \
				--stringparam out "${xsh_stdout}" \
				--stringparam err "${xsh_stderr}" \
				"${xshTestProgramStylesheet}" "${test}" \
		&& chmod 755 "${xshTestProgram}" \
		&& "${xshTestProgram}" \
		&& testResult=true
		
		testResultString="${ERROR_COLOR}PAILED${NORMAL_COLOR}"
		
		${testResult} \
		&& testResultString="${SUCCESS_COLOR}passed${NORMAL_COLOR}" \
		|| xshTestResult=$(expr ${xshTestResult} + 1)
		
		printf "${testResultFormat}" "$(printf '%.0s-' {1..40})" "${testResultString}"
		${keepTemporaryFiles} || rm -f "${xshTestProgram}"	  
	done << EOF
	$(find "${xshTestsPathBase}" -name '*.xsh') 
EOF
	exit ${xshTestResult}
elif [ "${parser_subcommand}" = 'xsd' ]
then
	xsdTestPathBase="${rootPath}/tests/xsd"
	xsdPathBase="${projectPath}/ns/xsd"
	xsdTextResultFormat="%-15.15s | %-20.20s | %-10s | %-8s | %-.15s\n"
	printf "${xsdTextResultFormat}" 'schema' 'test' 'validation' 'expected' 'RESULT'
	xsdTestsResult=0
	while read f
	do
		b="$(basename "${f}" .xml)"
		n="${b%.failed}"
		n="${n%.passed}"
		expected='passed'
		echo "${b}" | egrep -q ".*.failed$" \
			&& expected='failed' 
			
		d="$(dirname "${f}")"
		xsdPath="${xsdPathBase}${d#${xsdTestPathBase}}.xsd"
		
		result='failed'
		xmllint --noout --xinclude --schema "${xsdPath}" "${f}" 1>"${f}.result" 2>&1 \
			&& result='passed'
		
		testResult='passed'
		[ "${result}" != "${expected}" ] \
			&& xsdTestsResult="$(expr "${xsdTestsResult}" + 1)" \
			&& testResult='failed'
		
		printf "${xsdTextResultFormat}" "${d#${xsdTestPathBase}/}" "${n}" "${result}" "${expected}" "${testResult}" \
			| sed "s,passed,${SUCCESS_COLOR}passed${NORMAL_COLOR},g" \
			| sed "s,failed,${ERROR_COLOR}FAILED${NORMAL_COLOR},g"
			
		if [ "${testResult}" = "${expected}" ] && ! ${keepTemporaryFiles}
		then
			rm -f "${f}.result"
		fi 
	done << EOF
$(find "${xsdTestPathBase}" -type f -name '*.xml')
EOF
	exit ${xsdTestsResult}
elif [ "${parser_subcommand}" = 'xslt' ]
then
	xsltTestsResult=0
	xsltTestPathBase="${rootPath}/tests/xslt"
	unset testList
	if [ ${#parser_values[@]} -gt 0 ]
	then
		for v in "${parser_values[@]}"
		do
			if [ -f "${v}" ] && [ "${v%.info}" != "${v}" ]
			then
				testList=("${testList[@]}" "${v}")
			elif [ -f "${xsltTestPathBase}/${v}.info" ]
			then
				testList=("${testList[@]}" "${xsltTestPathBase}/${v}.info")
			else
				ns_error "Invalid xslt test '${v}'"
			fi
		done
	else
		while read f
		do
			testList=("${testList[@]}" "${f}")
		done << EOF
$(find "${xsltTestPathBase}" -name '*.info')
EOF
	fi

	resultFormat='%-30.30s | %-7s | %-9s | %-6s |\n'
	printf "${resultFormat}" 'Test' 'schema' 'transform' 'RESULT'
		
	for f in "${testList[@]}"
	do
		#n="$(basename "${f}" .info)"
		n="${f#${xsltTestPathBase}/}"
		n="${n%.info}"
		schemaResult='skipped'
		transformResult='failed'
		testResult='passed'
		
		[ -f "${f%.info}.xsl" ] \
			&& transform="${f%.info}.xsl" \
			&& transform="${transform#${rootPath}/}" \
			|| transform="$(grep -E '^transform' "${f}" | cut -f 2 -d':' | xargs echo)"
		[ -f "${f%.info}.xsd" ] \
			&& schema="${f%.info}.xsd" \
			|| schema="$(grep -E '^schema' "${f}" | cut -f 2 -d':' | xargs echo)"
		
		xml="${f%.info}.xml"
		expected="${f%.info}.expected"
		result="${f%.info}.transformresult"
		
		[ -z "${transform}" ] && ns_error "${n}: No XSLT file specified"
		transform="${rootPath}/${transform}"
		[ ! -f "${transform}" ] && ns_error "${n}: Invalid XSLT file '${transform}'"
		
		[ -f "${xml}" ] || ns_error "${n}: XML file not found"
		
		if [ ! -z "${schema}" ]
		then
			schema="${rootPath}/${schema}"
			[ ! -f "${schema}" ] && ns_error "${n}: Invalid schema file '${schema}'"
		
			schemaResult='failed'
			
			xmllint --xinclude --noout \
				--schema "${schema}" \
				"${xml}" \
				2>"${f%.info}.schemaresult" \
			&& schemaResult='passed'
		fi
		
		if [ -f "${expected}" ]
		then
			xsltproc --xinclude --output "${result}" "${transform}" "${xml}"
			diff -q "${result}" "${expected}" 1>/dev/null 2>&1 && transformResult='passed'
		else
			xsltproc --xinclude --output "${expected}" "${transform}" "${xml}"
			transformResult='skipped'
		fi
		
		if [ "${schemaResult}" = 'failed' ] || [ "${transformResult}" = 'failed' ]
		then
			xsltTestsResult=$(expr ${xsltTestsResult} + 1)
			testResult='failed'
		fi
		
		printf "${resultFormat}" "${n}" "${schemaResult}" "${transformResult}" "${testResult}" \
			| sed "s,passed,${SUCCESS_COLOR}passed${NORMAL_COLOR},g" \
			| sed "s,failed,${ERROR_COLOR}FAILED${NORMAL_COLOR},g"
		
	done

	if [ ${xsltTestsResult} -eq 0 ]
	then
		find "${xsltTestPathBase}" -name '*.transformresult' -exec rm -f "{}" \;
		find "${xsltTestPathBase}" -name '*.schemaresult' -exec rm -f "{}" \;
	fi
	
	exit ${xsltTestsResult}
fi

exit 0
