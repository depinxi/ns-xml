<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright © 2011-2012 by Renaud Guillard (dev@nore.fr) -->
<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" xmlns:prg="http://xsd.nore.fr/program" version="1.0">
	<output method="text" encoding="utf-8" />
	<param name="interpreter">
		<text>python</text>
	</param>
	<include href="../../../ns/xsl/languages/base.xsl" />
	<template match="prg:databinding/prg:variable">
		<value-of select="normalize-space(.)" />
	</template>

	<template match="/">
		<text>#!/usr/bin/env </text>
		<value-of select="$interpreter" />
		<text><![CDATA[
import sys
import Program

class UnittestUtil:
	def array_to_string(self, v, begin_str = "", end_str = "", separator_str = " "):
		first = True
		res = ""
		for i in v:	
			if not first:
				res = res + separator_str
			else:
				first = False
			res = res + begin_str + str(i) + end_str
		return res
		
	def argument_to_string(self, v):
		if v == None:
			return ""
		else:
			return str(v)

u = UnittestUtil()

p = Program.Program()
r = p.parse(sys.argv[1:len(sys.argv)])

print "CLI: " + u.array_to_string(sys.argv[1:len(sys.argv)], "\"", "\"", ", ")
print "Value count: " + str(len(r.values))
print "Values: " + u.array_to_string(r.values, "\"", "\"", ", ")
errorCount = len(r.issues["errors"])
print "Error count: " + str(errorCount)
if errorCount > 0:
	for index in range(len(sys.argv)):
		arg = sys.argv[index]
		if arg == "__msg__":
			print u.array_to_string(r.issues["errors"], " - ", "", "\n")
            
if r.subcommand:
	print "Subcommand: " + r.subcommand.name
else:
	print "Subcommand: "
]]></text>
		<!-- Global args -->
		<if test="/prg:program/prg:options">
			<variable name="root" select="/prg:program/prg:options" />
			<apply-templates select="$root//prg:switch | $root//prg:argument | $root//prg:multiargument | .//prg:group" />
		</if>
		<for-each select="/prg:program/prg:subcommands/*">
			<if test="./prg:options">
				<text>if r.subcommand and r.subcommand.name == "</text>
				<apply-templates select="prg:name" />
				<text>":</text>
				<call-template name="code.block">
					<with-param name="content">
						<apply-templates select=".//prg:switch | .//prg:argument | .//prg:multiargument | .//prg:group" />
					</with-param>
				</call-template>
			</if>
		</for-each>
	</template>

	<template name="prg.unittest.py.variablePrefix">
		<param name="node" select="." />
		<choose>
			<when test="$node/self::prg:subcommand">
				<apply-templates select="$node/prg:name" />
				<text>_</text>
			</when>
			<when test="$node/..">
				<call-template name="prg.unittest.py.variablePrefix">
					<with-param name="node" select="$node/.." />
				</call-template>
			</when>
		</choose>
	</template>

	<template name="prg.py.unittest.variableNameTree">
		<param name="node" />
		<param name="leaf" select="true()" />
		<choose>
			<when test="$node/self::prg:subcommand">
				<text>r.subcommand.options.</text>
			</when>
			<when test="$node/self::prg:program">
				<text>r.options.</text>
			</when>
			<when test="$node/../..">
				<call-template name="prg.py.unittest.variableNameTree">
					<with-param name="node" select="$node/../.." />
					<with-param name="leaf" select="false()" />
				</call-template>
			</when>
		</choose>
		<apply-templates select="$node/prg:databinding/prg:variable" />
		<if test="$node/self::prg:group and not($leaf)">
			<text>.options.</text>
		</if>
	</template>

	<template match="//prg:switch">
		<if test="./prg:databinding/prg:variable">
			<text>print "</text>
			<call-template name="prg.unittest.py.variablePrefix" />
			<apply-templates select="./prg:databinding/prg:variable" />
			<text>="</text>
			<text> + str(</text>
			<call-template name="prg.py.unittest.variableNameTree">
				<with-param name="node" select="." />
			</call-template>
			<text>)</text>
			<value-of select="'&#10;'" />
		</if>
	</template>

	<template match="//prg:argument">
		<if test="./prg:databinding/prg:variable">
			<text>print "</text>
			<call-template name="prg.unittest.py.variablePrefix" />
			<apply-templates select="./prg:databinding/prg:variable" />
			<text>="</text>
			<text> + u.argument_to_string(</text>
			<call-template name="prg.py.unittest.variableNameTree">
				<with-param name="node" select="." />
			</call-template>
			<text>)</text>
			<value-of select="'&#10;'" />
		</if>
	</template>

	<template match="//prg:multiargument">
		<if test="./prg:databinding/prg:variable">
			<text>print "</text>
			<call-template name="prg.unittest.py.variablePrefix" />
			<apply-templates select="./prg:databinding/prg:variable" />
			<text>="</text>
			<text> + u.array_to_string(</text>
			<call-template name="prg.py.unittest.variableNameTree">
				<with-param name="node" select="." />
			</call-template>
			<text>)</text>
			<value-of select="'&#10;'" />
		</if>
	</template>

	<template match="//prg:group">
		<if test="./prg:databinding/prg:variable">
			<text>print "</text>
			<call-template name="prg.unittest.py.variablePrefix" />
			<apply-templates select="./prg:databinding/prg:variable" />
			<text>="</text>
			<if test="./@type = 'exclusive'">
				<text> + u.argument_to_string(</text>
				<call-template name="prg.py.unittest.variableNameTree">
					<with-param name="node" select="." />
				</call-template>
				<text>.selected_option_name)</text>
			</if>
			<value-of select="'&#10;'" />
		</if>
	</template>

</stylesheet>
