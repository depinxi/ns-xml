<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright © 2018 - 2021 by Renaud Guillard (dev@nore.fr) -->
<!-- Distributed under the terms of the MIT License, see LICENSE -->

<!-- Create C parser result definitions -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:prg="http://xsd.nore.fr/program">
	<xsl:import href="parser.base.xsl" />
	<xsl:import href="parser.generic-names.xsl" />
	<xsl:import href="parser.names.xsl" />
	<!-- Declare an option result variable depending on the type of option -->
	<xsl:template name="prg.c.parser.optionResultDeclaration">
		<!-- Option node -->
		<xsl:param name="optionNode" select="." />
		<xsl:variable name="structName">
			<xsl:text>nsxml_</xsl:text>
			<xsl:call-template name="prg.c.parser.itemTypeName">
				<xsl:with-param name="itemNode" select="$optionNode" />
			</xsl:call-template>
			<xsl:text>_option_result</xsl:text>
		</xsl:variable>
		<xsl:call-template name="c.structVariableDeclaration">
			<xsl:with-param name="name" select="$structName" />
			<xsl:with-param name="variableName">
				<xsl:apply-templates select="$optionNode/prg:databinding/prg:variable" />
			</xsl:with-param>
			<xsl:with-param name="variableNameStyle" select="'none'" />
			<!-- TEMP -->
			<xsl:with-param name="nameStyle" select="'none'" />
		</xsl:call-template>
	</xsl:template>

	<!-- Declare all option result variables from a root item (subcommand or program) -->
	<xsl:template name="prg.c.parser.optionResultsDeclaration">
		<xsl:param name="rootNode" select="." />
		<xsl:variable name="rootOptionsNode" select="$rootNode/prg:options" />
		<xsl:for-each select="$rootOptionsNode//*[prg:databinding/prg:variable]">
			<xsl:call-template name="prg.c.parser.optionResultDeclaration" />
			<xsl:value-of select="$str.endl" />
		</xsl:for-each>
	</xsl:template>

	<xsl:variable name="prg.c.parser.subcommandResultStructBaseName" select="'subcommand_result'" />
	<!-- struct type name of a subcommand result struct -->
	<xsl:template name="prg.c.parser.subcommandResultStructName">
		<xsl:param name="subcommandNode" select="." />
		<xsl:value-of select="$prg.c.parser.prefix" />
		<xsl:text>_</xsl:text>
		<xsl:call-template name="c.validIdentifierName">
			<xsl:with-param name="name">
				<xsl:apply-templates select="$subcommandNode/prg:name" />
			</xsl:with-param>
		</xsl:call-template>
		<xsl:text>_</xsl:text>
		<xsl:value-of select="$prg.c.parser.subcommandResultStructBaseName" />
	</xsl:template>

	<xsl:template name="prg.c.parser.subcommandResultDefinition">
		<xsl:param name="subcommandNode" select="." />
		<xsl:variable name="structName">
			<xsl:call-template name="prg.c.parser.subcommandResultStructName">
				<xsl:with-param name="subcommandNode" select="$subcommandNode" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:call-template name="c.structDefinition">
			<xsl:with-param name="name" select="$structName" />
			<xsl:with-param name="variableName">
				<xsl:call-template name="c.validIdentifierName">
					<xsl:with-param name="name">
						<xsl:apply-templates select="$subcommandNode/prg:name" />
					</xsl:with-param>
				</xsl:call-template>
			</xsl:with-param>
			<xsl:with-param name="content">
				<xsl:call-template name="c.inlineComment">
					<xsl:with-param name="content" select="'Subcommand options'" />
				</xsl:call-template>
				<xsl:value-of select="$str.endl" />
				<xsl:call-template name="prg.c.parser.optionResultsDeclaration">
					<xsl:with-param name="rootNode" select="$subcommandNode" />
				</xsl:call-template>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:value-of select="$str.endl" />
	</xsl:template>

	<!-- Define the main program result type -->
	<xsl:template name="prg.c.parser.programResultDefinition">
		<!-- Program node -->
		<xsl:param name="programNode" select="." />
		<xsl:variable name="structName">
			<xsl:value-of select="$prg.c.parser.structName.program_result" />
		</xsl:variable>
		<xsl:call-template name="c.structDefinition">
			<xsl:with-param name="name" select="concat('_', $structName)" />
			<xsl:with-param name="content">
				<!-- Base -->
				<!-- Parser messages -->
				<xsl:call-template name="c.inlineComment">
					<xsl:with-param name="content" select="'Messages - Sorted by severity'" />
				</xsl:call-template>
				<xsl:value-of select="$str.endl" />
				<xsl:value-of select="$prg.c.parser.structName.nsxml_message" />
				<xsl:text> *messages[</xsl:text>
				<xsl:value-of select="$prg.c.parser.variableName.nsxml_message_type_count" />
				<xsl:text>];</xsl:text>
				<xsl:value-of select="$str.endl" />
				<xsl:call-template name="c.inlineComment">
					<xsl:with-param name="content" select="'Messages - Sorted by apparition'" />
				</xsl:call-template>
				<xsl:value-of select="$str.endl" />
				<xsl:value-of select="$prg.c.parser.structName.nsxml_message" />
				<xsl:text> *first_message;</xsl:text>
				<xsl:value-of select="$str.endl" />
				<!-- Positional arguments (Values) -->
				<xsl:value-of select="$str.endl" />
				<xsl:call-template name="c.inlineComment">
					<xsl:with-param name="content" select="'Subcommand'" />
				</xsl:call-template>
				<xsl:value-of select="$str.endl" />
				<xsl:call-template name="c.variableDeclaration">
					<xsl:with-param name="type" select="'const char'" />
					<xsl:with-param name="pointer" select="1" />
					<xsl:with-param name="name" select="'subcommand_name'" />
					<xsl:with-param name="nameStyle" select="'none'" />
				</xsl:call-template>
				<xsl:value-of select="$str.endl" />
				<xsl:call-template name="c.inlineComment">
					<xsl:with-param name="content" select="'Positional arguments'" />
				</xsl:call-template>
				<xsl:value-of select="$str.endl" />
				<xsl:call-template name="c.variableDeclaration">
					<xsl:with-param name="type" select="'size_t'" />
					<xsl:with-param name="nameStyle" select="'none'" />
					<xsl:with-param name="name" select="'value_count'" />
					<xsl:with-param name="variableNameStyle" select="'none'" />
				</xsl:call-template>
				<xsl:value-of select="$str.endl" />
				<xsl:call-template name="c.variableDeclaration">
					<xsl:with-param name="type" select="$prg.c.parser.structName.nsxml_value" />
					<xsl:with-param name="nameStyle" select="'none'" />
					<xsl:with-param name="name" select="'values'" />
					<xsl:with-param name="pointer" select="1" />
				</xsl:call-template>
				<xsl:value-of select="$str.endl" />
				<!-- Dynamic part -->
				<!-- Global options (if any) -->
				<xsl:if test="$programNode/prg:options">
					<xsl:call-template name="c.inlineComment">
						<xsl:with-param name="content" select="'Global options'" />
					</xsl:call-template>
					<xsl:value-of select="$str.endl" />
					<xsl:call-template name="c.structDefinition">
						<xsl:with-param name="variableName" select="'options'" />
						<xsl:with-param name="content">
							<xsl:call-template name="prg.c.parser.optionResultsDeclaration">
								<xsl:with-param name="rootNode" select="$programNode" />
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:if>
				<!-- Subcommands (if any) -->
				<xsl:if test="$programNode/prg:subcommands[prg:subcommand/prg:options]">
					<xsl:value-of select="$str.endl" />
					<xsl:call-template name="c.inlineComment">
						<xsl:with-param name="content" select="'Subcommands'" />
					</xsl:call-template>
					<xsl:value-of select="$str.endl" />
					<xsl:call-template name="c.structDefinition">
						<xsl:with-param name="variableName" select="'subcommands'" />
						<xsl:with-param name="variableNameStyle" select="'none'" />
						<xsl:with-param name="content">
							<xsl:for-each select="$programNode/prg:subcommands/prg:subcommand[prg:options]">
								<xsl:call-template name="prg.c.parser.subcommandResultDefinition" />
								<xsl:value-of select="$str.endl" />
							</xsl:for-each>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:if>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:value-of select="$str.endl" />
		<xsl:text>typedef struct </xsl:text>
		<xsl:value-of select="concat('_', $structName)" />
		<xsl:text> </xsl:text>
		<xsl:value-of select="$structName" />
		<xsl:text>;</xsl:text>
	</xsl:template>

	<!-- Program result life cycle functions -->
	<xsl:template name="prg.c.parser.programResultFreeFunctionDeclaration">
		<xsl:param name="programNode" select="." />
		<xsl:call-template name="c.functionDeclaration">
			<xsl:with-param name="name" select="$prg.c.parser.functionName.program_result_free" />
			<xsl:with-param name="parameters">
				<xsl:value-of select="$prg.c.parser.structName.program_result" />
				<xsl:text> *result</xsl:text>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="prg.c.parser.programResultFreeFunctionDefinition">
		<xsl:param name="programNode" select="." />
		<xsl:call-template name="c.functionDefinition">
			<xsl:with-param name="name" select="$prg.c.parser.functionName.program_result_free" />
			<xsl:with-param name="parameters">
				<xsl:value-of select="$prg.c.parser.structName.program_result" />
				<xsl:text> *result</xsl:text>
			</xsl:with-param>
			<xsl:with-param name="content">
				<xsl:text>nsxml_program_result_cleanup(result);</xsl:text>
				<xsl:value-of select="$str.endl" />
				<xsl:call-template name="prg.c.parser.option_resultFunctionCall">
					<xsl:with-param name="programNode" select="$programNode" />
					<xsl:with-param name="functionName" select="'nsxml_option_result_cleanup'" />
					<xsl:with-param name="cast" select="false()" />
				</xsl:call-template>
				<xsl:text>free(result);</xsl:text>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<!-- Result messages helper functions -->
	<xsl:template name="prg.c.parser.programResultErrorCountFunctionDeclaration">
		<xsl:param name="programNode" select="." />
		<xsl:call-template name="c.functionDeclaration">
			<xsl:with-param name="name" select="$prg.c.parser.functionName.program_result_error_count" />
			<xsl:with-param name="returnType" select="'size_t'" />
			<xsl:with-param name="parameters">
				<xsl:value-of select="$prg.c.parser.structName.program_result" />
				<xsl:text> *result</xsl:text>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="prg.c.parser.programResultErrorCountFunctionDefinition">
		<xsl:param name="programNode" select="." />
		<xsl:call-template name="c.functionDefinition">
			<xsl:with-param name="name" select="$prg.c.parser.functionName.program_result_error_count" />
			<xsl:with-param name="returnType" select="'size_t'" />
			<xsl:with-param name="parameters">
				<xsl:value-of select="$prg.c.parser.structName.program_result" />
				<xsl:text> *result</xsl:text>
			</xsl:with-param>
			<xsl:with-param name="content">
				<xsl:text>return (nsxml_message_count(result-&gt;messages[</xsl:text>
				<xsl:value-of select="$prg.c.parser.variableName.nsxml_message_type_error" />
				<xsl:text>]) + nsxml_message_count(result-&gt;messages[</xsl:text>
				<xsl:value-of select="$prg.c.parser.variableName.nsxml_message_type_fatal_error" />
				<xsl:text>]));</xsl:text>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="prg.c.parser.programResultGetMessageFunctionName">
		<xsl:param name="type" />
		<xsl:call-template name="prg.c.parser.functionName">
			<xsl:with-param name="name">
				<xsl:choose>
					<xsl:when test="$type = 'fatal_error'">
						<xsl:value-of select="concat(concat($prg.c.parser.prefix, '_result_get_'), $type)" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat(concat(concat($prg.c.parser.prefix, '_result_get_'), $type), 's')" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="prg.c.parser.programResultGetMessageFunctionDeclaration">
		<xsl:param name="type" />
		<xsl:call-template name="c.functionDeclaration">
			<xsl:with-param name="name">
				<xsl:call-template name="prg.c.parser.programResultGetMessageFunctionName">
					<xsl:with-param name="type" select="$type" />
				</xsl:call-template>
			</xsl:with-param>
			<xsl:with-param name="returnType" select="concat($prg.c.parser.structName.nsxml_message, ' *')" />
			<xsl:with-param name="parameters">
				<xsl:value-of select="$prg.c.parser.structName.program_result" />
				<xsl:text> *result</xsl:text>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="prg.c.parser.programResultGetMessageFunctionDefinition">
		<xsl:param name="type" />
		<xsl:call-template name="c.functionDefinition">
			<xsl:with-param name="name">
				<xsl:call-template name="prg.c.parser.programResultGetMessageFunctionName">
					<xsl:with-param name="type" select="$type" />
				</xsl:call-template>
			</xsl:with-param>
			<xsl:with-param name="returnType" select="concat($prg.c.parser.structName.nsxml_message, ' *')" />
			<xsl:with-param name="parameters">
				<xsl:value-of select="$prg.c.parser.structName.program_result" />
				<xsl:text> *result</xsl:text>
			</xsl:with-param>
			<xsl:with-param name="content">
				<xsl:text>return result-&gt;messages[</xsl:text>
				<xsl:choose>
					<xsl:when test="$type = 'warning'">
						<xsl:value-of select="$prg.c.parser.variableName.nsxml_message_type_warning" />
					</xsl:when>
					<xsl:when test="$type = 'error'">
						<xsl:value-of select="$prg.c.parser.variableName.nsxml_message_type_error" />
					</xsl:when>
					<xsl:when test="$type = 'fatal_error'">
						<xsl:value-of select="$prg.c.parser.variableName.nsxml_message_type_fatal_error" />
					</xsl:when>
				</xsl:choose>
				<xsl:text>];</xsl:text>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:variable name="prg.c.parser.programResultDisplayErrorsFunctionSignature">
		<xsl:call-template name="c.functionSignature">
			<xsl:with-param name="returnType" select="'void'" />
			<xsl:with-param name="name">
				<xsl:value-of select="$prg.c.parser.functionName.program_result_display_errors" />
			</xsl:with-param>
			<xsl:with-param name="parameters">
				<xsl:text>FILE *stream, </xsl:text>
				<xsl:value-of select="$prg.c.parser.structName.program_result" />
				<xsl:text> *result, const char *line_prefix</xsl:text>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:variable>
	<xsl:template name="prg.c.parser.programResultDisplayErrorsFunctionDeclaration">
		<xsl:call-template name="c.functionDeclaration">
			<xsl:with-param name="signature" select="$prg.c.parser.programResultDisplayErrorsFunctionSignature" />
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="prg.c.parser.programResultDisplayErrorsFunctionDefinition">
		<xsl:call-template name="c.functionDefinition">
			<xsl:with-param name="signature" select="$prg.c.parser.programResultDisplayErrorsFunctionSignature" />
			<xsl:with-param name="content">
				<xsl:value-of select="$prg.c.parser.structName.nsxml_message" />
				<xsl:text> *m = result-&gt;messages[</xsl:text>
				<xsl:value-of select="$prg.c.parser.variableName.nsxml_message_type_error" />
				<xsl:text>];</xsl:text>
				<xsl:value-of select="$str.endl" />
				<xsl:text>int use_prefix = 1;</xsl:text>
				<xsl:value-of select="$str.endl" />
				<xsl:call-template name="c.while">
					<xsl:with-param name="condition" select="'m'" />
					<xsl:with-param name="do">
						<xsl:text>size_t len = (m-&gt;message) ? strlen(m-&gt;message) : 0;</xsl:text>
						<xsl:value-of select="$str.endl" />
						<xsl:call-template name="c.if">
							<xsl:with-param name="condition" select="'len'" />
							<xsl:with-param name="then">
								<xsl:text>fprintf(stream, "%s%s", ((use_prefix &amp;&amp; line_prefix) ? line_prefix : ""), m-&gt;message);</xsl:text>
								<xsl:value-of select="$str.endl" />
								<xsl:text>use_prefix = (len &amp;&amp; (m-&gt;message[len - 1] == '\n'));</xsl:text>
							</xsl:with-param>
						</xsl:call-template>
						<xsl:value-of select="$str.endl" />
						<xsl:text>m = m-&gt;next_message;</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
				<xsl:value-of select="$str.endl" />
				<xsl:call-template name="c.if">
					<xsl:with-param name="condition" select="'!use_prefix'" />
					<xsl:with-param name="then">
						<xsl:text>fprintf(stream, "%s", "\n");</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
				<xsl:value-of select="$str.endl" />
				<xsl:text>m = result-&gt;messages[</xsl:text>
				<xsl:value-of select="$prg.c.parser.variableName.nsxml_message_type_fatal_error" />
				<xsl:text>];</xsl:text>
				<xsl:value-of select="$str.endl" />
				<xsl:call-template name="c.if">
					<xsl:with-param name="condition" select="'m'" />
					<xsl:with-param name="then">
						<xsl:text>size_t len = (m-&gt;message) ? strlen(m-&gt;message) : 0;</xsl:text>
						<xsl:value-of select="$str.endl" />
						<xsl:text>fprintf(stream, "%s%s", ((line_prefix) ? line_prefix : ""), m-&gt;message);</xsl:text>
						<xsl:value-of select="$str.endl" />
						<xsl:call-template name="c.if">
							<xsl:with-param name="condition">
								<xsl:text>m-&gt;message[len - 1] != '\n'</xsl:text>
							</xsl:with-param>
							<xsl:with-param name="then">
								<xsl:text>fprintf(stream, "%s", "\n");</xsl:text>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

</xsl:stylesheet>
