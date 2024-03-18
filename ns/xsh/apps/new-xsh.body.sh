# Global variables
cwd="$(pwd)"
scriptFilePath="$(ns_realpath "${0}")"
scriptPath="$(dirname "${scriptFilePath}")"
scriptName="$(basename "${scriptFilePath}")"
programSchemaVersion="2.0"

tmpPath="/tmp"
[ ! -z "${TMPDIR}" ] && [ -d "${TMPDIR}" ] && tmpPath="${TMPDIR%/}/"
author=''
if [ ! -z "${USER}" ]; then author="${USER}"
elif [ ! -z "${LOGNAME}" ]; then author="${LOGNAME}"
fi
 
# Check required programs
for x in xmllint xsltproc
do
	if ! which $x 1>/dev/null 2>&1
	then
		echo "${x} program not found"
		exit 1
	fi
done

if ! parse "${@}"
then
	${displayHelp} && usage && exit 0
	${displayVersion} && echo "${parser_program_version}" && exit 0
	
	parse_displayerrors 1>&2 && exit 1
fi

${displayHelp} && usage && exit 0
${displayVersion} && echo "${parser_program_version}" && exit 0

#######################################

[ -d "${nsxmlPath}" ] || nsxmlPath="${scriptPath}/../.."
[ ! -d "${nsxmlPath}" ] && ns_error "ns-xml path path not found"
nsxmlPath="$(ns_realpath "${nsxmlPath}")"

mkdir -p "${outputPath}" || ns_error "Failed to create output path"

outputPath="$(ns_realpath "${outputPath}")"

xshSchemaFile="${nsxmlPath}/ns/xsd/xsh/1.0/xsh.xsd"
xshFile="${outputPath}/${xshName}.xsh"
xmlFile="${outputPath}/${xshName}.xml"
shFile="${outputPath}/${xshName}.body.sh"
tmpFile="${tmpPath}/${xshName}.tmp"

for f in "${xshFile}" "${xmlFile}" "${shFile}"
do
	[ -f "${f}" ] && ns_error 1 "${f} already exists"
done

# XSH file
cat > "${tmpFile}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<xsh:program 
	interpreterType="bash" 
	xmlns:prg="http://xsd.nore.fr/program" 
	xmlns:xsh="http://xsd.nore.fr/xsh" 
	xmlns:xi="http://www.w3.org/2001/XInclude">
	<xsh:info>
		<xi:include href="${xshName}.xml" />
	</xsh:info>
EOF
if [ ${#programContentFunctions[*]} -gt 0 ]
then
	echo '	<xsh:functions>' >> "${tmpFile}"
	for resource in "${programContentFunctions[@]}"
	do
		cd "${cwd}"
		resourcePath=''
		if [ -r "${resource}" ]
		then
			xmllint --noout \
				--schema "${xshSchemaFile}" \
				"${resource}" \
				1>/dev/null 2>&1 \
			|| ns_error "Invalid XSH file ${resource}"

			resourcePath="$(ns_realpath "${resource}")"
		else
			resourcePath="${nsxmlPath}/ns/xsh/lib/${resource}.xsh"
		fi
		
		[ -f "${resourcePath}" ] \
			|| ns_error "Function file not found: ${resourcePath}" 

		if ${programContentEmbed}
		then
			xmllint --xpath \
				"//*[local-name() = 'function' and namespace-uri() = 'http://xsd.nore.fr/xsh']" \
				"${resourcePath}" \
				>> "${tmpFile}"
		else
			relativePath="$(ns_relativepath "${resourcePath}" "${outputPath}")"
			echo "		<xi:include href="\"${relativePath}"\" xpointer=\"xmlns(xsh=http://xsd.nore.fr/xsh) xpointer(//xsh:function)\" />" >> "${tmpFile}"
		fi
	done 
	echo '	</xsh:functions>' >> "${tmpFile}"		
fi

cat >> "${tmpFile}" << EOF
	<xsh:code>
		<!-- Include shell script code -->
		<xi:include href="${xshName}.body.sh" parse="text" />
	</xsh:code>
</xsh:program>
EOF

xmllint --format --output "${xshFile}" "${tmpFile}"

# XML file
cat > "${tmpFile}" << EOF
<?xml version="1.0" encoding="utf-8"?>
<prg:program xmlns:prg="http://xsd.nore.fr/program" version="2.0" xmlns:xi="http://www.w3.org/2001/XInclude">
	<prg:name>${xshName}</prg:name>
	<prg:author>${author}</prg:author>
	<prg:version>1.0.0</prg:version>
	<prg:copyright>Copyright © $(date +%Y) by ${author}</prg:copyright>
	<prg:documentation>
		<prg:abstract>${xshName} short description</prg:abstract>
	</prg:documentation>
EOF
if [ ${#programContentOptions[*]} -gt 0 ]
then
	echo '	<prg:options>' >> "${tmpFile}"
	for o in "${programContentOptions[@]}"
	do
		resourcePath="${nsxmlPath}/ns/xsh/lib/options/options.xml"
		optionIdentifier=''
		optionType='prg:switch'
		case "${o}" in
			help)
				optionIdentifier='prg.option.displayHelp'
				;;
			subcommand-names)
				optionIdentifier='prg.option.displaySubcommandNames'
				;;
			version)
				optionIdentifier='prg.option.displayVersion'
				;;
		esac
		
		if ${programContentEmbed}
		then
			xmllint --xpath \
				"//*[local-name() = '${optionType#prg:}' and @id = '${optionIdentifier}' and namespace-uri() = 'http://xsd.nore.fr/program']" \
				"${resourcePath}" \
				>> "${tmpFile}"
		else
			resourcePath="$(ns_relativepath "${resourcePath}" "${outputPath}")"
			echo "<xi:include href=\"${resourcePath}\" xpointer=\"xmlns(prg=http://xsd.nore.fr/program) xpointer(//${optionType}[@id = '${optionIdentifier}'])\" />" \
				>> "${tmpFile}"
		fi
	done
	 
	echo '	</prg:options>' >> "${tmpFile}"
fi

echo '</prg:program>' >> "${tmpFile}"

xmllint --format --output "${xmlFile}" "${tmpFile}"

## SH body

touch "${shFile}"

cat > "${shFile}" << EOF
# Global variables
EOF
if ns_array_contains filesystem/filesystem "${programContentFunctions[@]}"
then
	cat >> "${shFile}" << EOF
scriptFilePath="\$(ns_realpath "\${0}")"
EOF
else
	cat >> "${shFile}" << EOF
scriptFilePath="\${0}"
EOF
fi

cat >> "${shFile}" << EOF
scriptPath="\$(dirname "\${scriptFilePath}")"
scriptName="\$(basename "\${scriptFilePath}")"

# Option parsing
if ! parse "\${@}"
then
EOF
if ns_array_contains help "${programContentOptions[@]}"
then
	cat >> "${shFile}" << EOF
	\${displayHelp} && usage "\${parser_subcommand}" && exit 0
EOF
fi
if ns_array_contains 'subcommand-names' "${programContentOptions[@]}"
then
	cat >> "${shFile}" << EOF
	\${displaySubcommandNames} \\
		&& for n in "\${parser_subcommand_names[@]}"; do echo "\${n}"; done \\
		&& exit 0
EOF
fi
if ns_array_contains version "${programContentOptions[@]}"
then
	cat >> "${shFile}" << EOF
	\${displayVersion} && echo "\${parser_program_version}" && exit 0
EOF
fi
cat >> "${shFile}" << EOF
	parse_displayerrors 1>&2
	exit 1
fi
EOF
if ns_array_contains help "${programContentOptions[@]}"
then
	cat >> "${shFile}" << EOF
\${displayHelp} && usage "\${parser_subcommand}" && exit 0
EOF
fi

if ns_array_contains 'subcommand-names' "${programContentOptions[@]}"
then
	cat >> "${shFile}" << EOF
\${displaySubcommandNames} \\
	&& for n in "\${parser_subcommand_names[@]}"; do echo "\${n}"; done \\
	&& exit 0 
EOF
fi
if ns_array_contains version "${programContentOptions[@]}"
then
	cat >> "${shFile}" << EOF
\${displayVersion} && echo "\${parser_program_version}" && exit 0
EOF
fi

cat >> "${shFile}" << EOF
# Main code

EOF
