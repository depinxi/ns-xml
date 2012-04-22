<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright © 2011 by Renaud Guillard (dev@niao.fr) -->
<sh:program xmlns:prg="http://xsd.nore.fr/program" 
xmlns:sh="http://xsd.nore.fr/bash" 
xmlns:xi="http://www.w3.org/2001/XInclude">
<sh:info>
	<xi:include href="build-shellscript.xml" />
</sh:info>
<sh:functions>
	<xi:include href="../lib/filesystem/filesystem.xml" xpointer="xmlns(sh=http://xsd.nore.fr/bash)xpointer(//sh:function[@name = 'ns_realpath'])" />
	<xi:include href="functions.xml" xpointer="xmlns(sh=http://xsd.nore.fr/bash)xpointer(//sh:function)" />
</sh:functions>
<sh:code><![CDATA[
# Global variables
scriptFilePath="$(ns_realpath "${0}")"
scriptPath="$(dirname "${scriptFilePath}")"
nsPath="$(ns_realpath "${scriptPath}/../..")/ns"
rootPath="$(ns_realpath "${scriptPath}/../..")"
programVersion="2.0"
 
# Check required programs
for x in xmllint xsltproc egrep cut expr head tail
do
	if ! which $x 1>/dev/null 2>&1
	then
		echo "${x} program not found"
		exit 1
	fi
done

if ! parse "${@}"
then
	if ${displayHelp}
	then
		usage
		exit 0
	fi
	
	parse_displayerrors
	exit 1
fi
if ${displayHelp}
then
	usage
	exit 0
fi

chunk_check_nsxml_ns_path || error 1 "Invalid ns-xml ns folder (${nsPath})"

# Check required XSLT files
xshXslTemplatePath="${nsPath}/xsl/program/${programVersion}/xsh.xsl"
if [ ! -f "${xshXslTemplatePath}" ]
then
	echo "Missing XSLT stylesheet file \"${xshXslTemplatePath}\""
	exit 2
fi

# Validate xml program description (if given)
if [ -f "${xmlProgramDescriptionPath}" ]
then
	# Finding schema version
	programVersion="$(xsltproc "${nsPath}/xsl/program/get-version.xsl" "${xmlProgramDescriptionPath}")"
	echo "Program schema version ${programVersion}"
	
	if [ ! -f "${nsPath}/xsd/program/${programVersion}/program.xsd" ]
	then
		echo "Invalid program schema version"
		exit 3
	fi

	if ! ${skipValidation} && ! xmllint --xinclude --noout --schema "${nsPath}/xsd/program/${programVersion}/program.xsd" "${xmlProgramDescriptionPath}" 1>/dev/null
	then
		echo "program schema error - abort"
		exit 4
	fi
fi

# Validate against bash schema
if ! ${skipValidation}
then
	if ! xmllint --xinclude --noout --schema "${nsPath}/xsd/bash.xsd" "${xmlShellFileDescriptionPath}"
	then
		echo "bash schema error - abort"
		exit 5
	fi
fi

# Process xsh file
debugParam=""
if ${debugMode}
then
	debugParam="--stringparam prg.debug \"true()\""
fi

prefixParam=""
if ${prefixSubcommandBoundVariableName}
then
	prefixParam="--stringparam prg.sh.parser.prefixSubcommandOptionVariable \"true()\""
fi

if ! xsltproc --xinclude -o "${outputScriptFilePath}" ${prefixParam} ${debugParam} "${xshXslTemplatePath}" "${xmlShellFileDescriptionPath}"
then
	echo "Fail to process xsh file \"${xmlShellFileDescriptionPath}\""
	exit 6
fi

chmod 755 "${outputScriptFilePath}"
]]></sh:code>
</sh:program>