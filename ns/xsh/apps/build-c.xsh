<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright © 2018 - 2021 by Renaud Guillard (dev@nore.fr) -->
<!-- Distributed under the terms of the MIT License, see LICENSE -->
<xsh:program interpreterType="bash" xmlns:prg="http://xsd.nore.fr/program" xmlns:xsh="http://xsd.nore.fr/xsh" xmlns:xi="http://www.w3.org/2001/XInclude">
	<xsh:info>
		<xi:include href="build-c.xml" />
	</xsh:info>
	<xsh:functions>
		<xi:include href="../lib/base/base.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function)" />
		<xi:include href="../lib/filesystem/filesystem.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function[@name = 'ns_realpath'])" />
		<xi:include href="../lib/filesystem/filesystem.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function[@name = 'ns_mktemp'])" />
		<xi:include href="../lib/filesystem/filesystem.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function[@name = 'ns_mktempdir'])" />
		<xi:include href="functions.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function)" />
		<xsh:function name="buildcPopulateXsltprocParams">
			<xsh:body><![CDATA[
# Shared xsltproc options
buildcXsltprocParams=(--xinclude)

# Prefix
if [ ! -z "${prefix}" ]
then
	buildcXsltprocParams=("${buildcXsltprocParams[@]}" \
		--stringparam "prg.c.parser.prefix" "${prefix}")
fi

if [ "${structNameStyle}" != "none" ]
then
	buildcXsltprocParams=("${buildcXsltprocParams[@]}" \
		"--stringparam" "prg.c.parser.structNamingStyle" "${structNameStyle}")
fi

if [ "${functionNameStyle}" != "none" ]
then
	buildcXsltprocParams=("${buildcXsltprocParams[@]}" \
		"--stringparam" "prg.c.parser.functionNamingStyle" "${functionNameStyle}")
fi

if [ "${variableNameStyle}" != "none" ]
then
	buildcXsltprocParams=("${buildcXsltprocParams[@]}" \
	"--stringparam" "prg.c.parser.variableNamingStyle" "${variableNameStyle}")
fi
		]]></xsh:body>
		</xsh:function>
		<xsh:function name="buildcGenerateBase">
			<xsh:body>
				<xsh:local name="fileBase">${outputFileBase}</xsh:local>
				<xsh:local name="tpl" />
		<![CDATA[
# Check required templates
for x in parser.generic-header parser.generic-source
do
	tpl="${buildcXsltPath}/${x}.xsl"
	[ -r "${tpl}" ] || ns_error 2 "Missing XSLT template $(basename "${tpl}")" 
done

[ "${fileBase}" = '<auto>' ] && fileBase='cmdline-base'
	
]]><xsh:local name="outputFileBasePath">${outputPath}/${fileBase}</xsh:local><![CDATA[
if ! ${outputOverwrite}
then
	# Check existing files
	for e in h c
	do
		[ -f "${outputFileBasePath}.${e}" ] && ns_error 2 "${fileBase}.${e} already exists. Use --overwrite"
	done
fi

buildcPopulateXsltprocParams

dummyProgramDefinitionFile="$(ns_mktemp "$(basename "${0}")")"

cat > "${dummyProgramDefinitionFile}" << EOF]]></xsh:body><xsh:body indent="no"><![CDATA[
<?xml version="1.0" encoding="utf-8"?>
<prg:program xmlns:prg="http://xsd.nore.fr/program" xmlns:xi="http://www.w3.org/2001/XInclude" version="'${programSchemaVersion}'">
	<prg:name>generic</prg:name>
</prg:program>
EOF]]></xsh:body>
			<xsh:body><![CDATA[
# Header
xsltproc "${buildcXsltprocParams[@]}" \
	--output "${outputFileBasePath}.h" \
	"${buildcXsltPath}/parser.generic-header.xsl" \
	"${dummyProgramDefinitionFile}" \
|| ns_error 2 "Failed to generate header file ${outputFileBasePath}.h" 

# Source
xsltproc "${buildcXsltprocParams[@]}" \
	--output "${outputFileBasePath}.c" \
	--stringparam "prg.c.parser.header.filePath" "${fileBase}.h" \
	"${buildcXsltPath}/parser.generic-source.xsl" \
	"${dummyProgramDefinitionFile}" \
|| ns_error 2 "Failed to generate source file ${outputFileBasePath}.c"
]]></xsh:body>
		</xsh:function>
		<xsh:function name="buildcGenerate">
			<xsh:body>
				<xsh:local name="tpl" />
				<xsh:local name="fileBase">${outputFileBase}</xsh:local>
		<![CDATA[
# Check required templates
for x in parser.header parser.source
do
	tpl="${buildcXsltPath}/${x}.xsl"
	[ -r "${tpl}" ] || ns_error 2 "Missing XSLT template $(basename "${tpl}")" 
done

[ "${fileBase}" = '<auto>' ] && fileBase='cmdline'
]]><xsh:local name="outputFileBasePath">${outputPath}/${fileBase}</xsh:local><![CDATA[	

if ! ${outputOverwrite}
then
	# Check existing files
	for e in h c
	do
		[ -f "${outputFileBasePath}.${e}" ] && ns_error 2 "${fileBase}.${e} already exists. Use --overwrite"
	done
fi

buildcPopulateXsltprocParams
if ! ${generateEmbedded}
then
	# generateInclude
	buildcXsltprocParams=("${buildcXsltprocParams[@]}" \
	"--stringparam"	"prg.c.parser.nsxmlHeaderPath" "${generateInclude}")
fi

# Header
xsltproc "${buildcXsltprocParams[@]}" \
	--output "${outputFileBasePath}.h" \
	"${buildcXsltPath}/parser.header.xsl" \
	"${xmlProgramDescriptionPath}" \
|| ns_error 2 "Failed to generate header file ${outputFileBasePath}.h" 

xsltproc "${buildcXsltprocParams[@]}" \
	--output "${outputFileBasePath}.c" \
	--stringparam "prg.c.parser.header.filePath" "${fileBase}.h" \
	"${buildcXsltPath}/parser.source.xsl" \
	"${xmlProgramDescriptionPath}" \
|| ns_error 2 "Failed to generate source file ${outputFileBasePath}.c" 
]]></xsh:body>
		</xsh:function>
	</xsh:functions>
	<xsh:code>
		<!-- Include shell script code -->
		<xi:include href="build-c.body.sh" parse="text" />
	</xsh:code>
</xsh:program>
