<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright © 2012 by Renaud Guillard (dev@niao.fr) -->
<!-- Distributed under the terms of the BSD License, see LICENSE -->
<!-- C Source code in customizable XSLT form -->
<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" xmlns:prg="http://xsd.nore.fr/program" version="1.0">
	<import href="parser.generic-names.xsl"/>
	<output method="text" encoding="utf-8"/>
	<param name="prg.c.parser.header.filePath" select="'cmdline.h'"/>
	<variable name="prg.c.parser.genericSource"><![CDATA[
/**************************************************************************************$
 *
 ***************************************************************************************
 * Copyright © 2012 by Renaud Guillard (dev@niao.fr)
 * Distributed under the terms of the BSD License, see LICENSE
 ***************************************************************************************
 */

#include "]]><value-of select="$prg.c.parser.header.filePath"/><![CDATA["
#if defined(__cplusplus)
#	include <cstdio>
#	include <cstdlib>
#	include <cstring>
#	include <cassert>
#	include <cctype>
extern "C"
{
#else
#	include <stdio.h>
#	include <stdlib.h>
#	include <string.h>
#	include <assert.h>
#	include <ctype.h>
#endif

#if defined(_WIN32)
#	include <io.h>
#	if !defined(F_OK)
#		define F_OK 0
#	endif
#	if !defined(X_OK)
#		define X_OK 1
#	endif
#	if !defined(R_OK)
#		define R_OK 2
#	endif
#	if !defined(W_OK)
#		define W_OK 4
#	endif
#else
#	include <unistd.h>
#	include <libgen.h>
#endif

#include <sys/stat.h>

#define NSXML_DBG 0

/* Utility functions *****************************/

int ]]><value-of select="$prg.c.parser.functionName.nsxml_util_asnprintf"/><![CDATA[(char **output, size_t *output_length, const char *format, ...)
{
	size_t printed = 0;
	size_t step = (*output_length > 256) ? *output_length : 256;
	int redo = 0;
	va_list list;
	
	do
	{
		redo = 0;
		va_start(list, format);
		printed += vsnprintf(*output, *output_length, format, list);
		
		if (printed >= *output_length)
		{
			*output_length += step;
			*output = (char *) realloc(*output, sizeof(char) * (*output_length));
			printed = 0;
			redo = 1;
		}
		
		va_end(list);
	}
	while (redo);
	
	return printed;
}

int ]]><value-of select="$prg.c.parser.functionName.nsxml_util_strncpy"/><![CDATA[(char *output, size_t output_length, const char *input, size_t input_length)
{
	size_t len = strlen(input);
	size_t s = input_length;
	
	if (output_length < 1)
	{
		return -1;
	}
	
	if (s > (output_length - 1))
	{
		s = (output_length - 1);
	}
	
	if (s > len)
	{
		s = len;
	}
	
	memcpy(output, input, s);
	output[s] = 0;
	
	return (input_length - s);
}

int ]]><value-of select="$prg.c.parser.functionName.nsxml_util_strcpy"/><![CDATA[(char *output, size_t output_length, const char *input)
{
	return ]]><value-of select="$prg.c.parser.functionName.nsxml_util_strncpy"/><![CDATA[(output, output_length, input, strlen(input));
}

int ]]><value-of select="$prg.c.parser.functionName.nsxml_util_string_starts_with"/><![CDATA[(const char *haystack, const char *needle)
{
	int len = strlen(needle);
	const char *a = haystack;
	const char *b = needle;
	
	while (*a && *b && (*a == *b) && len--)
	{
		++a;
		++b;
	}
	
	return (len == 0);
}

int ]]><value-of select="$prg.c.parser.functionName.nsxml_util_path_access_check"/><![CDATA[(const char *path, int flag)
{
#if defined(_WIN32)
	return (_access(path, flag) == 0);
#else
	return (access(path, flag) == 0);
#endif
}

void ]]><value-of select="$prg.c.parser.functionName.nsxml_util_text_wrap_options_init"/><![CDATA[(struct ]]><value-of select="$prg.c.parser.structName.nsxml_util_text_wrap_options"/><![CDATA[ *options, int tab, int line, int indent_mode, int eol)
{
	int i = 0;
	options->tab_size = tab;
	options->line_length = line;
	options->indent_mode = indent_mode;
	
	if (eol & ]]><value-of select="$prg.c.parser.variableName.nsxml_util_text_wrap_eol_cr"/><![CDATA[)
	{
		options->eol[i] = '\r';
		++i;
	}
	
	if (eol & ]]><value-of select="$prg.c.parser.variableName.nsxml_util_text_wrap_eol_lf"/><![CDATA[)
	{
		options->eol[i] = '\n';
		++i;
	}
	
	options->eol[i] = '\0';
}

void ]]><value-of select="$prg.c.parser.functionName.nsxml_util_text_wrap_fprintf"/><![CDATA[(FILE *stream, const char *text, const struct ]]><value-of select="$prg.c.parser.structName.nsxml_util_text_wrap_options"/><![CDATA[ *options, int level)
{
	int i;
	const char *text_ptr = text;
	char *indent = NULL;
	char *line_buffer = NULL;
	int line_index = 0;
	int line_breakable_index = -1;
	int prefix_length = (level * options->tab_size);
	int first_prefix_length = (options->indent_mode == ]]><value-of select="$prg.c.parser.variableName.nsxml_util_text_wrap_indent_first"/><![CDATA[) ? (prefix_length + options->tab_size) : prefix_length;
	int others_prefix_length = (options->indent_mode == ]]><value-of select="$prg.c.parser.variableName.nsxml_util_text_wrap_indent_others"/><![CDATA[) ? (prefix_length + options->tab_size) : prefix_length;
	int first = 1;
	int max_prefix_length = (first_prefix_length > others_prefix_length) ? first_prefix_length : others_prefix_length;
	
	int line_length = ((options->line_length - first_prefix_length) > 0) ? (options->line_length - first_prefix_length) : 1;
	prefix_length = first_prefix_length;
	
	line_buffer = (char *) malloc(sizeof(char) * (line_length + 1));
	
	indent = (char *) malloc(sizeof(char) * (max_prefix_length + 1));
	
	for (i = 0; i < prefix_length; ++i)
	{
		indent[i] = ' ';
	}
	
	indent[prefix_length] = '\0';
	
	while (text_ptr && (*text_ptr != '\0'))
	{
		if (line_index < line_length)
		{
			if (*text_ptr == '\t')
			{
				line_breakable_index = line_index;
				
				/* replace by spaces */
				for (i = 0; (i < options->tab_size) && (line_index < line_length); ++i, ++line_index)
				{
					line_buffer[line_index] = ' ';
				}
			}
			else if ((*text_ptr == '\r') || (*text_ptr == '\n'))
			{
				/** print current line */
				line_buffer[line_index] = 0;
				fprintf(stream, "%s%s%s", indent, line_buffer, options->eol);
				line_index = 0;
				line_breakable_index = -1;
				
				if ((*text_ptr == '\r') && (*(text_ptr + 1) == '\n'))
				{
					++text_ptr;
				}
				
				if (first)
				{
					first = 0;
					line_length = ((options->line_length - others_prefix_length) > 0) ? (options->line_length - others_prefix_length) : 1;
					prefix_length = others_prefix_length;
					
					for (i = 0; i < prefix_length; ++i)
					{
						indent[i] = ' ';
					}
					
					indent[prefix_length] = '\0';
				}
			}
			else
			{
				if (isspace(*text_ptr))
				{
					line_breakable_index = line_index;
				}
				
				line_buffer[line_index] = *text_ptr;
				++line_index;
			}
		}
		else
		{
			/* print current line until last breakable index */
			if (line_breakable_index <= 0)
			{
				line_buffer[line_index] = 0;
				fprintf(stream, "%s%s%s", indent, line_buffer, options->eol);
				line_index = 0;
			}
			else
			{
				line_buffer[line_breakable_index] = 0;
				fprintf(stream, "%s%s%s", indent, line_buffer, options->eol);
				
				/* move remaining line_buffer text to front */
				if (line_index > line_breakable_index)
				{
					int a = 0;
					int b = line_breakable_index + 1;
					
					while ((b < line_index) && isspace(line_buffer[b]))
					{
						++b;
					}
					
					while (b < line_index)
					{
						line_buffer[a] = line_buffer[b];
						++a;
						++b;
					}
					
					line_index = a;
					line_breakable_index = -1;
				}
			}
			
			if (first)
			{
				first = 0;
				line_length = ((options->line_length - others_prefix_length) > 0) ? (options->line_length - others_prefix_length) : 1;
				prefix_length = others_prefix_length;
				
				for (i = 0; i < prefix_length; ++i)
				{
					indent[i] = ' ';
				}
				
				indent[prefix_length] = '\0';
			}
			
			continue;
		}
		
		++text_ptr;
	}
	
	if (line_index > 0)
	{
		line_buffer[line_index] = '\0';
		fprintf(stream, "%s%s%s", indent, line_buffer, options->eol);
	}
	
	free(line_buffer);
	free(indent);
}

/* Messages **************************************/

]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *nsxml_message_new_ref(]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *ref)
{
	]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *msg = (]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *) malloc(sizeof(]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[));
	msg->type = ref->type;
	msg->message = ref->message;
	msg->next_message = 0;
	return msg;
}

int nsxml_message_count(const ]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *list)
{
	const ]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *msg = list;
	int c = 0;
	
	while (msg)
	{
		++c;
		msg = msg->next_message;
	}
	
	return c;
}

/* Item names *************************************/

struct nsxml_item_name *nsxml_item_names_new(const char *name, ...)
{
	struct nsxml_item_name *item = NULL;
	struct nsxml_item_name *previous = NULL;
	struct nsxml_item_name *next = NULL;
	const char *arg_val = NULL;
	va_list arglist;
	int len;
	
	if (name)
	{
		len = strlen(name);
		item = (struct nsxml_item_name *) malloc(sizeof(struct nsxml_item_name));
		item->name = (char *) malloc(len + 1);
		item->next_name = NULL;
		]]><value-of select="$prg.c.parser.functionName.nsxml_util_strncpy"/><![CDATA[(item->name, len + 1, name, len);
		previous = item;
		
		va_start(arglist, name);
		arg_val = va_arg(arglist, const char *);
		
		while (arg_val != NULL)
		{
			len = strlen(arg_val);
			next = (struct nsxml_item_name *) malloc(sizeof(struct nsxml_item_name));
			next->name = (char *) malloc(len + 1);
			next->next_name = NULL;
			]]><value-of select="$prg.c.parser.functionName.nsxml_util_strncpy"/><![CDATA[(next->name, len + 1, arg_val, len);
			previous->next_name = next;
			
			previous = next;
			arg_val = va_arg(arglist, const char *);
		}
		
		va_end(arglist);
	}
	
	return item;
}

void nsxml_item_name_free(struct nsxml_item_name *item_start)
{
	struct nsxml_item_name *item = NULL;
	struct nsxml_item_name *next = NULL;
	item = item_start;
	
	while (item != NULL)
	{
		next = item->next_name;
		free(item->name);
		free(item);
		item = next;
	}
}

int nsxml_item_name_snprintf(const struct nsxml_item_name *names, char **output, size_t *output_length, const char *prefix_text)
{
	size_t text_buffer_length = 0;
	int value_count = 0;
	const struct nsxml_item_name *v = names;
	
	while (v)
	{
		++value_count;
		text_buffer_length += strlen(v->name);
		v = v->next_name;
	}
	
	text_buffer_length += ((value_count - 2) * 2) /* ', ' */
						  + (value_count * 2) /* quetes around strings */
						  + 4 /* ' or ' */
						  + 2; /* \n and \0 */
						  
	if (prefix_text)
	{
		text_buffer_length += strlen(prefix_text);
	}
	
	if (text_buffer_length > *output_length)
	{
		*output = (char *) realloc(*output, text_buffer_length);
		*output_length = text_buffer_length;
	}
	
	{
		char *t = *output;
		int tr = text_buffer_length;
		int tc = 0;
		int i = 0;
		
		if (prefix_text)
		{
			tc = snprintf(t, tr, "%s", prefix_text);
			t += tc;
			tr -= tc;
			v = names;
		}
		
		while (v)
		{
			if (i == 0)
			{
				tc = snprintf(t, tr, "'%s'", v->name);
			}
			else if (i + 1 == value_count)
			{
				tc = snprintf(t, tr, " or '%s'", v->name);
			}
			else
			{
				tc = snprintf(t, tr, ", '%s'", v->name);
			}
			
			t += tc;
			tr -= tc;
			++i;
			v = v->next_name;
		}
	}
	
	return text_buffer_length;
}

/* Validators *************************************/

void nsxml_value_validator_init(struct nsxml_value_validator *validator, nsxml_value_validator_validation_callback *callback, nsxml_value_validator_cleanup_callback *cleanup, nsxml_value_validator_usage_callback *usage_cb, int flags)
{
	validator->cleanup_callback = cleanup;
	validator->validation_callback = callback;
	validator->usage_callback = usage_cb;
	validator->flags = flags;
	validator->next_validator = NULL;
}

void nsxml_value_validator_add(struct nsxml_value_validator **list, struct nsxml_value_validator *validator)
{
	if (*list == NULL)
	{
		*list = validator;
	}
	else
	{
		struct nsxml_value_validator *v = *list;
		
		while (v->next_validator != NULL)
		{
			v = v->next_validator;
		}
		
		v->next_validator = validator;
	}
	
	validator->next_validator = NULL;
}

void nsxml_value_validator_free(struct nsxml_value_validator *validator)
{
	struct nsxml_value_validator *v = validator;
	struct nsxml_value_validator *next = NULL;
	
	while (v)
	{
		next = v->next_validator;
		
		if (v->cleanup_callback)
		{
			(*v->cleanup_callback)(v);
		}
		
		free(v);
		v = next;
	}
}

int nsxml_value_validator_validate_path(struct nsxml_value_validator *self, struct nsxml_parser_state *state, struct nsxml_program_result *result, struct nsxml_option_name_binding *option, const char *value)
{
	nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "path validation %d\n", self->flags);
	
	if (self->flags & nsxml_value_validator_path_exists)
	{
		if (!]]><value-of select="$prg.c.parser.functionName.nsxml_util_path_access_check"/><![CDATA[(value, R_OK))
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "%s Can't be accessed\n", value);
			return 0;
		}
		
		if ((self->flags & nsxml_value_validator_path_writable) && !]]><value-of select="$prg.c.parser.functionName.nsxml_util_path_access_check"/><![CDATA[(value, W_OK))
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "%s is not writable\n", value);
			return 0;
		}
		
		if ((self->flags & nsxml_value_validator_path_executable) && !]]><value-of select="$prg.c.parser.functionName.nsxml_util_path_access_check"/><![CDATA[(value, X_OK))
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "%s is not executable\n", value);
			return 0;
		}
	}
	
	{
		int types = (self->flags & nsxml_value_validator_path_type_all);
		struct stat statBuffer;
		
		if ((types != 0) && (types != nsxml_value_validator_path_type_all))
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "path type checks %d\n", types);
			
			stat(value, &statBuffer);
			
			if ((types & nsxml_value_validator_path_type_folder) && S_ISDIR(statBuffer.st_mode))
			{
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Is directory\n");
				return 1;
			}
			
			else if ((types & nsxml_value_validator_path_type_symlink) && S_ISLNK(statBuffer.st_mode))
			{
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Is symlink\n");
				return 1;
			}
			
			else if ((types & nsxml_value_validator_path_type_file) && S_ISREG(statBuffer.st_mode))
			{
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Is regular file\n");
				return 1;
			}
			
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "None of specified types\n");
			return 0;
		}
	}
	
	return 1;
}

int nsxml_value_validator_usage_path(struct nsxml_value_validator *self, const struct nsxml_option_info *info, char **output, size_t *output_length)
{
	int f;
	char text_buffer[256]; /* enough for everything */
	char *t = text_buffer;
	size_t tc = 0;
	size_t tr = 255;
	int path_type_count = nsxml_usage_path_type_count(self->flags);
	int path_access_count = nsxml_usage_path_access_count(self->flags);
	
	if (path_type_count > 0)
	{
		int i = 0;
		tc = snprintf(t, tr, "%s", "Expected path type: ");
		tr -= tc;
		t += tc;
		
		for (f = nsxml_value_validator_path_type_file; f <= nsxml_value_validator_path_type_symlink; f = (f << 1))
		{
			if (self->flags & f)
			{
				if (i == 0)
				{
					if (path_type_count == 1)
					{
						tc = snprintf(t, tr, "%s\n", nsxml_usage_path_type_string(f));
					}
					else
					{
						tc = snprintf(t, tr, "%s", nsxml_usage_path_type_string(f));
					}
				}
				else if ((i + 1) == path_type_count)
				{
					tc = snprintf(t, tr, " or %s\n", nsxml_usage_path_type_string(f));
				}
				else
				{
					tc += snprintf(t, tr, ", %s", nsxml_usage_path_type_string(f));
				}
				
				++i;
				tr -= tc;
				t += tc;
			}
		}
	}
	
	if (path_access_count > 0)
	{
		int i = 0;
		tc = snprintf(t, tr, "%s", "Path argument must be ");
		tr -= tc;
		t += tc;
		
		for (f = nsxml_value_validator_path_readable; f <= nsxml_value_validator_path_executable; f = (f << 1))
		{
			if (self->flags & f)
			{
				if (i == 0)
				{
					if (path_access_count == 1)
					{
						tc = snprintf(t, tr, "%s\n", nsxml_usage_path_access_string(f));
					}
					else
					{
						tc = snprintf(t, tr, "%s", nsxml_usage_path_access_string(f));
					}
				}
				else if ((i + 1) == path_access_count)
				{
					tc = snprintf(t, tr, " and %s\n", nsxml_usage_path_access_string(f));
				}
				else
				{
					tc += snprintf(t, tr, ", %s", nsxml_usage_path_access_string(f));
				}
				
				++i;
				tr -= tc;
				t += tc;
			}
		}
	}
	
	if ((path_access_count + path_type_count) > 0)
	{
		return ]]><value-of select="$prg.c.parser.functionName.nsxml_util_asnprintf"/><![CDATA[(output, output_length, "%s", text_buffer);
	}
	
	return 0;
}

int nsxml_value_validator_validate_number(struct nsxml_value_validator *self, struct nsxml_parser_state *state, struct nsxml_program_result *result, struct nsxml_option_name_binding *option, const char *value)
{
	struct nsxml_value_validator_number *validator = (struct nsxml_value_validator_number *) self;
	float f;
	int res;
	char *tmp = (char *) malloc(sizeof(char) * strlen(value) + 1);
	tmp[0] = '\0';
	
	nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "number validation %d [%f, %f]\n", self->flags, validator->min_value, validator->max_value);
	res = sscanf(value, "%f%s", &f, tmp);
	nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, " - res = %d (%f %s)\n", res, f, tmp);
	free(tmp);
	
	if (res != 1)
	{
		return 0;
	}
	
	if ((self->flags & nsxml_value_validator_checkmin) && (f < validator->min_value))
	{
		return 0;
	}
	
	if ((self->flags & nsxml_value_validator_checkmax) && (f > validator->max_value))
	{
		return 0;
	}
	
	return 1;
}

int nsxml_value_validator_usage_number(struct nsxml_value_validator *self, const struct nsxml_option_info *info, char **output, size_t *output_length)
{
	struct nsxml_value_validator_number *v = (struct nsxml_value_validator_number *) self;
	int min_and_max = (nsxml_value_validator_checkmin | nsxml_value_validator_checkmax);
	int printed = 0;
	
	if ((self->flags & min_and_max) == min_and_max)
	{
		printed = ]]><value-of select="$prg.c.parser.functionName.nsxml_util_asnprintf"/><![CDATA[(output, output_length, "Argument value must be between %.2f and %.2f", v->min_value, v->max_value);
	}
	else if (self->flags & nsxml_value_validator_checkmin)
	{
		printed = ]]><value-of select="$prg.c.parser.functionName.nsxml_util_asnprintf"/><![CDATA[(output, output_length, "Argument value must be lesser or equal to %.2f", v->min_value);
	}
	else if (self->flags & nsxml_value_validator_checkmax)
	{
		printed = ]]><value-of select="$prg.c.parser.functionName.nsxml_util_asnprintf"/><![CDATA[(output, output_length, "Argument value must be greater or equal to %.2f", v->max_value);
	}
	
	return printed;
}

int nsxml_value_validator_validate_enum(struct nsxml_value_validator *self, struct nsxml_parser_state *state, struct nsxml_program_result *result, struct nsxml_option_name_binding *option, const char *value)
{
	const struct nsxml_value_validator_enum *e = (const struct nsxml_value_validator_enum *) self;
	struct nsxml_item_name *v;
	
	if (!(self->flags & nsxml_value_validator_enum_strict))
	{
		return 1;
	}
	
	v = e->values;
	
	while (v)
	{
		if (strcmp(v->name, value) == 0)
		{
			return 1;
		}
		
		v = v->next_name;
	}
	
	{
		size_t output_length = 64;
		char *output = (char *) malloc(sizeof(char) * output_length);
		nsxml_item_name_snprintf(e->values, &output, &output_length, "Expect: ");
		
		if (option)
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_error"/><![CDATA[, "Invalid value for option %s. %s\n", state->active_option_cli_name, output);
		}
		else
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_error"/><![CDATA[, "Invalid value for positional argument %s\n", output);
		}
		
		free(output);
	}
	
	return 0;
}

void nsxml_value_validator_cleanup_enum(struct nsxml_value_validator *self)
{
	struct nsxml_value_validator_enum *e = (struct nsxml_value_validator_enum *) self;
	nsxml_item_name_free(e->values);
	e->values = NULL;
}

int nsxml_value_validator_usage_enum(struct nsxml_value_validator *self, const struct nsxml_option_info *info, char **output, size_t *output_length)
{
	const struct nsxml_value_validator_enum *e = (const struct nsxml_value_validator_enum *) self;
	static const char *kPrefixedText[2] =
	{ "Possible values: ", "Expected values: " };
	int prefix_index = 0;
	
	if (self->flags & nsxml_value_validator_enum_strict)
	{
		prefix_index = 1;
	}
	
	return nsxml_item_name_snprintf(e->values, output, output_length, kPrefixedText[prefix_index]);
}

/* Item info **************************************/

void nsxml_item_info_init(struct nsxml_item_info *info, int type, const char *abstract, const char *details)
{
	info->item_type = type;
	
	if (abstract)
	{
		info->abstract = strdup(abstract);
	}
	else
	{
		info->abstract = NULL;
	}
	
	if (details)
	{
		info->details = strdup(details);
	}
	else
	{
		info->details = NULL;
	}
}

void nsxml_item_info_cleanup(struct nsxml_item_info *item_info)
{
	free(item_info->abstract);
	free(item_info->details);
}

void nsxml_option_info_name_display(FILE *stream, const char *name)
{
	if (strlen(name) > 1)
	{
		fprintf(stream, "--%s", name);
	}
	else
	{
		fprintf(stream, "-%s", name);
	}
}

void nsxml_option_info_names_display(FILE *stream, const struct nsxml_option_info *option_info, const char *separator, const char *end_separator)
{
	struct nsxml_item_name *n = option_info->names;
	int first = 1;
	
	while (n)
	{
		if (first)
		{
			first = 0;
		}
		else if (n->next_name && separator)
		{
			fprintf(stream, "%s", separator);
		}
		else if ((n->next_name == NULL) && end_separator)
		{
			fprintf(stream, "%s", end_separator);
		}
		
		nsxml_option_info_name_display(stream, n->name);
		
		n = n->next_name;
	}
}

void nsxml_option_info_init(struct nsxml_option_info *info, int type, int flags, const char *var_name, struct nsxml_item_name *names, struct nsxml_group_option_info *parent)
{
	info->option_type = type;
	info->option_flags = flags;
	
	if (var_name && (strlen(var_name) > 0))
	{
		info->var_name = strdup(var_name);
	}
	else
	{
		info->var_name = NULL;
	}
	
	info->names = names;
	info->parent = parent;
	info->validators = NULL;
}

void nsxml_option_info_cleanup(struct nsxml_option_info *option_info)
{
	nsxml_item_name_free(option_info->names);
	free(option_info->var_name);
	option_info->names = NULL;
	nsxml_value_validator_free(option_info->validators);
	nsxml_item_info_cleanup((struct nsxml_item_info *) option_info);
}

void nsxml_positional_argument_info_init(struct nsxml_positional_argument_info *info, int flags, int arg_type, int max_arg)
{
	info->positional_argument_flags = flags;
	info->argument_type = arg_type;
	info->max_argument = max_arg;
	info->validators = NULL;
}

void nsxml_positional_argument_info_cleanup(struct nsxml_positional_argument_info *info)
{
	nsxml_item_info_cleanup(&info->item_info);
	nsxml_value_validator_free(info->validators);
}

void nsxml_switch_option_info_free(struct nsxml_switch_option_info *switch_option_info)
{
	nsxml_option_info_cleanup((struct nsxml_option_info *) switch_option_info);
	free(switch_option_info);
}

void nsxml_argument_option_info_free(struct nsxml_argument_option_info *argumentoption_info)
{
	nsxml_option_info_cleanup((struct nsxml_option_info *) argumentoption_info);
	free(argumentoption_info->default_value);
	free(argumentoption_info);
}

void nsxml_multiargument_option_info_free(struct nsxml_multiargument_option_info *multiargumentoption_info)
{
	nsxml_option_info_cleanup((struct nsxml_option_info *) multiargumentoption_info);
	free(multiargumentoption_info);
}

void nsxml_group_option_info_free(struct nsxml_group_option_info *group_option_info)
{
	nsxml_option_info_cleanup((struct nsxml_option_info *) group_option_info);
	free(group_option_info->option_info_refs);
	free(group_option_info);
}

void nsxml_rootitem_info_cleanup(struct nsxml_rootitem_info *rootitem_info)
{
	int i;
	struct nsxml_option_info *o;
	
	for (i = 0; i < rootitem_info->option_info_count; ++i)
	{
		o = rootitem_info->option_infos[i];
		
		switch (o->option_type)
		{
			case nsxml_option_type_switch:
			{
				nsxml_switch_option_info_free((struct nsxml_switch_option_info *) o);
			}
			break;
			
			case nsxml_option_type_argument:
			{
				nsxml_argument_option_info_free((struct nsxml_argument_option_info *) o);
			}
			break;
			
			case nsxml_option_type_multiargument:
			{
				nsxml_multiargument_option_info_free((struct nsxml_multiargument_option_info *) o);
			}
			break;
			
			case nsxml_option_type_group:
			{
				nsxml_group_option_info_free((struct nsxml_group_option_info *) o);
			}
			break;
		}
	}
	
	free(rootitem_info->option_infos);
	
	for (i = 0; i < rootitem_info->positional_argument_info_count; ++i)
	{
		nsxml_positional_argument_info_cleanup(&rootitem_info->positional_argument_infos[i]);
	}
	
	free(rootitem_info->positional_argument_infos);
	
	nsxml_item_info_cleanup(&rootitem_info->item_info);
	
	rootitem_info->option_infos = NULL;
}

void nsxml_subcommand_info_cleanup(struct nsxml_subcommand_info *subcommand_info)
{
	nsxml_rootitem_info_cleanup((struct nsxml_rootitem_info *)(subcommand_info));
	nsxml_item_name_free(subcommand_info->names);
	subcommand_info->names = NULL;
}

void nsxml_program_info_cleanup(struct nsxml_program_info *info)
{
	int i;
	nsxml_rootitem_info_cleanup((struct nsxml_rootitem_info *)(info));
	
	for (i = 0; i < info->subcommand_info_count; ++i)
	{
		nsxml_subcommand_info_cleanup(&(info->subcommand_infos[i]));
	}
	
	free(info->subcommand_infos);
	info->subcommand_infos = NULL;
}

void nsxml_program_info_free(struct nsxml_program_info *info)
{
	nsxml_program_info_cleanup(info);
	free(info);
}

/* Option argument or positional argument value ***/

]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *nsxml_value_new(int type, const char *argv)
{
	]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *value = (]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *) malloc(sizeof(]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[));
	nsxml_value_init(value);
	value->type = type;
	nsxml_value_set(value, type, argv);
	return value;
}

void nsxml_value_init(]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *value)
{
	value->type = ]]><value-of select="$prg.c.parser.variableName.nsxml_value_type_unset"/><![CDATA[;
	value->string_value = NULL;
	value->next_value = NULL;
	value->int_value = 0;
	value->float_value = 0.F;
}

void nsxml_value_set(]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *item, int value_type, const char *value)
{
	if (value_type > ]]><value-of select="$prg.c.parser.variableName.nsxml_value_type_null"/><![CDATA[)
	{
		item->string_value = value;
	}
	
	if (value_type == ]]><value-of select="$prg.c.parser.variableName.nsxml_value_type_int"/><![CDATA[)
	{
		if (value)
		{
			item->int_value = (int)(atof(value) + 0.5F);
		}
		else
		{
			item->int_value = 0;
		}
		
		item->float_value = item->int_value;
	}
	
	if (value_type == ]]><value-of select="$prg.c.parser.variableName.nsxml_value_type_float"/><![CDATA[)
	{
		if (value)
		{
			item->float_value = atof(value);
		}
		else
		{
			item->float_value = 0.F;
		}
		
		item->int_value = (int)(item->float_value + 0.5F);
	}
}

void nsxml_value_append(]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ **list, int value_type, const char *value)
{
	if ((*list) == NULL)
	{
		*list = nsxml_value_new(value_type, value);
	}
	else
	{
		]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *item = *list;
		
		while (item->next_value)
		{
			item = item->next_value;
		}
		
		item->next_value = nsxml_value_new(value_type, value);
	}
	
#if 0
	
	if (count == 0)
	{
		nsxml_value_set(list, value_type, value);
	}
	else
	{
		]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *item = list;
		
		while (--count)
		{
			item = item->next_value;
		}
		
		item->next_value = nsxml_value_new(value_type, value);
	}
	
#endif
}

void nsxml_value_cleanup(]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *single_value)
{
	single_value->type = ]]><value-of select="$prg.c.parser.variableName.nsxml_value_type_unset"/><![CDATA[;
	single_value->string_value = NULL;
	single_value->int_value = 0;
	single_value->float_value = 0.F;
	single_value->next_value = NULL;
}

void nsxml_value_free(]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *list)
{
	]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *next = NULL;
	
	while (list)
	{
		next = list->next_value;
		free(list);
		list = next;
	}
	
#if 0
	]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *value = 0;
	]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *next = 0;
	
	start_value->type = ]]><value-of select="$prg.c.parser.variableName.nsxml_value_type_unset"/><![CDATA[;
	start_value->string_value = NULL;
	start_value->int_value = 0;
	start_value->float_value = 0;
	
	value = start_value->next_value;
	
	while (value)
	{
		next = value->next_value;
		free(value);
		value = next;
	}
	
	start_value->next_value = NULL;
#endif
}

int nsxml_argument_type_to_value_type(int argument_type)
{
	switch (argument_type)
	{
		case nsxml_argument_type_number:
		{
			return ]]><value-of select="$prg.c.parser.variableName.nsxml_value_type_float"/><![CDATA[;
		}
		break;
		
		case nsxml_argument_type_string:
		case nsxml_argument_type_path:
		case nsxml_argument_type_mixed:
		case nsxml_argument_type_hostname:
		case nsxml_argument_type_existingcommand:
		default:
			return ]]><value-of select="$prg.c.parser.variableName.nsxml_value_type_string"/><![CDATA[;
	}
}

/* Parser internal state **************************/

struct nsxml_parser_state *nsxml_parser_state_new(const struct nsxml_program_info *info, int argc, const char **argv, int start_index)
{
	struct nsxml_parser_state *state = (struct nsxml_parser_state *) malloc(sizeof(struct nsxml_parser_state));
	
	/** Program info */
	state->program_info_ref = info;
	state->option_name_binding_group_count = 0;
	state->option_name_binding_counts = NULL;
	state->option_name_bindings = NULL;
	
	state->subcommand_name_binding_count = 0;
	state->subcommand_name_bindings = NULL;
	
	/** user input */
	state->argc = argc;
	state->argv = argv;
	
	/** Parser state */
	state->arg_index = start_index;
	state->state_flags = 0;
	state->subcommand_index = 0;
	
	state->active_option = NULL;
	state->active_option_cli_name[0] = '\0';
	state->active_option_argc = 0;
	state->active_option_argv = NULL;
	
	if (argc > 0)
	{
		state->active_option_argv = (const char **) malloc(sizeof(char *) * state->argc);
	}
	
	state->anonymous_option_result_count = 0;
	state->anonymous_option_results = NULL;
	
	state->value_count = 0;
	state->values = NULL;
	
	return state;
}

void nsxml_parser_state_allocate_name_bindings(struct nsxml_parser_state *state, int option_name_binding_group_count, int *option_name_binding_counts)
{
	int i, j;
	state->option_name_binding_group_count = option_name_binding_group_count;
	state->option_name_binding_counts = (int *) malloc(sizeof(int) * option_name_binding_group_count);
	state->option_name_bindings = (struct nsxml_option_name_binding **) malloc(sizeof(struct nsxml_option_name_binding *) * option_name_binding_group_count);
	
	for (i = 0; i < option_name_binding_group_count; ++i)
	{
		state->option_name_binding_counts[i] = option_name_binding_counts[i];
		
		if (option_name_binding_counts[i] == 0)
		{
			state->option_name_bindings[i] = NULL;
		}
		else
		{
			state->option_name_bindings[i] = (struct nsxml_option_name_binding *) malloc(sizeof(struct nsxml_option_name_binding) * option_name_binding_counts[i]);
			
			for (j = 0; j < option_name_binding_counts[i]; ++j)
			{
				state->option_name_bindings[i][j].name_ref = NULL;
				state->option_name_bindings[i][j].info_ref = NULL;
				state->option_name_bindings[i][j].result_ref = NULL;
			}
		}
	}
}

void nsxml_parser_state_free(struct nsxml_parser_state *state)
{
	int g;
	int o;
	
	for (g = 0; g < state->option_name_binding_group_count; ++g)
	{
		for (o = 0; o < state->option_name_binding_counts[g]; ++o)
		{
			free(state->option_name_bindings[g][o].parent_tree_refs);
		}
		
		free(state->option_name_bindings[g]);
	}
	
	free(state->option_name_binding_counts);
	free(state->option_name_bindings);
	free(state->active_option_argv);
	free(state->subcommand_name_bindings);
	
	if (state->anonymous_option_result_count > 0)
	{
		for (o = 0; o < state->anonymous_option_result_count; ++o)
		{
			nsxml_option_result_cleanup(state->anonymous_option_results[o]);
			free(state->anonymous_option_results[o]);
		}
		
		free(state->anonymous_option_results);
	}
	
	nsxml_value_free(state->values);
	state->value_count = 0;
	state->values = NULL;
	
	free(state);
}

/* Parser results *********************************/

void nsxml_program_result_init(struct nsxml_program_result *result)
{
	int i;
	
	result->first_message = NULL;
	
	for (i = 0; i < ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_count"/><![CDATA[; ++i)
	{
		result->messages[i] = NULL;
	}
	
	result->subcommand_name = NULL;
	result->value_count = 0;
	result->values = NULL;
}

void nsxml_program_result_cleanup(struct nsxml_program_result *result)
{
	int i;
	]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *msg = 0;
	]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *next = 0;
	
	msg = result->first_message;
	
	while (msg != 0)
	{
		next = msg->next_message;
		free(msg);
		msg = next;
	}
	
	for (i = 0; i < ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_count"/><![CDATA[; ++i)
	{
		msg = result->messages[i];
		
		while (msg != 0)
		{
			next = msg->next_message;
			free(msg->message);
			free(msg);
			msg = next;
		}
		
		result->messages[i] = 0;
	}
	
	nsxml_value_free(result->values);
	result->value_count = 0;
	result->values = NULL;
}

void nsxml_program_result_free(struct nsxml_program_result *result)
{
	nsxml_program_result_cleanup(result);
	free(result);
}

void nsxml_program_result_add_message(struct nsxml_program_result *result, int type, const char *text)
{
	nsxml_program_result_add_messagef(result, type, "%s", text);
}

void nsxml_program_result_add_messagef(struct nsxml_program_result *result, int type, const char *format, ...)
{
	]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *msg = NULL;
	size_t message_size = (strlen(format) * 2) + 1;
	int redo = 0;
	size_t printed = 0;
	]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *msg2;
	]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *parent;
	va_list list;
#if NSXML_DBG
	va_list dbg;
#endif
	
	if ((type < 0) || (type >= ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_count"/><![CDATA[))
	{
		return;
	}
	
#if NSXML_DBG
	printf("%d: ", type);
	va_start(dbg, format);
	vprintf(format, dbg);
	va_end(dbg);
#endif
	
	msg = (]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *) malloc(sizeof(]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[));
	msg->message = (char *) malloc(sizeof(char) * message_size + 1);
	
	do
	{
		redo = 0;
		va_start(list, format);
		printed = vsnprintf(msg->message, message_size, format, list);
		va_end(list);
		
		if (printed > message_size)
		{
			message_size = printed;
			msg->message = (char *) realloc(msg->message, sizeof(char) * message_size + 1);
			redo = 1;
		}
	}
	while (redo);
	
	msg->type = type;
	msg->next_message = 0;
	
	msg2 = nsxml_message_new_ref(msg);
	parent = 0;
	
	parent = result->messages[type];
	
	if (parent)
	{
		while (parent->next_message)
		{
			parent = parent->next_message;
		}
		
		parent->next_message = msg;
	}
	else
	{
		result->messages[type] = msg;
	}
	
	parent = result->first_message;
	
	if (parent == 0)
	{
		result->first_message = msg2;
	}
	else
	{
		while (parent->next_message)
		{
			parent = parent->next_message;
		}
		
		parent->next_message = msg2;
	}
}

int nsxml_program_result_message_count(const struct nsxml_program_result *result, int messagetype_min, int messagetype_max)
{
	int i = messagetype_min;
	int mx = (messagetype_max >= messagetype_min) ? messagetype_max : ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_fatal_error"/><![CDATA[;
	int c = 0;
	]]><value-of select="$prg.c.parser.structName.nsxml_message"/><![CDATA[ *m;
	
	for (; i <= mx; ++i)
	{
		m = result->messages[i];
		
		while (m)
		{
			++c;
			m = m->next_message;
		}
	}
	
	return c;
}

void nsxml_switch_option_result_init(struct nsxml_switch_option_result *option)
{
	option->is_set = 0;
	option->result_type = nsxml_result_type_switch;
}

void nsxml_argument_option_result_init(struct nsxml_argument_option_result *option)
{
	option->is_set = 0;
	option->result_type = nsxml_result_type_argument;
	nsxml_value_init(&option->argument);
}

void nsxml_multiargument_option_result_init(struct nsxml_multiargument_option_result *option)
{
	option->is_set = 0;
	option->result_type = nsxml_result_type_multiargument;
	option->argument_count = 0;
	option->arguments = NULL;
}

void nsxml_group_option_result_init(struct nsxml_group_option_result *option)
{
	option->is_set = 0;
	option->result_type = nsxml_result_type_group;
	option->selected_option = NULL;
	option->selected_option_name = NULL;
}

void nsxml_option_result_cleanup(struct nsxml_option_result *option)
{
	if (!option)
	{
		return;
	}
	
	switch (option->result_type)
	{
		case nsxml_result_type_switch:
		{
		
		}
		break;
		
		case nsxml_result_type_argument:
		{
			struct nsxml_argument_option_result *a = (struct nsxml_argument_option_result *)(option);
			nsxml_value_cleanup(&a->argument);
		}
		break;
		
		case nsxml_result_type_multiargument:
		{
			struct nsxml_multiargument_option_result *ma = (struct nsxml_multiargument_option_result *)(option);
			nsxml_value_free(ma->arguments);
			ma->arguments = NULL;
			ma->argument_count = 0;
		}
		break;
		
		case nsxml_result_type_group:
		{
			/*
			 * Not really needed ^^
			 struct nsxml_group_option_result * g = (struct nsxml_group_option_result *)(option);
			 g->selected_option = NULL;
			 g->selected_option_name = NULL;
			 */
		}
		break;
	}
}

/* Usage Functions *******************************/

const char *nsxml_usage_get_first_short_name(struct nsxml_option_info *option_info)
{
	const struct nsxml_item_name *name = option_info->names;
	
	for (; name; name = name->next_name)
	{
		if (strlen(name->name) == 1)
		{
			return name->name;
		}
	}
	
	return NULL;
}

const char *nsxml_usage_get_first_long_name(struct nsxml_option_info *option_info)
{
	const struct nsxml_item_name *name = option_info->names;
	
	for (; name; name = name->next_name)
	{
		if (strlen(name->name) > 1)
		{
			return name->name;
		}
	}
	
	return NULL;
}

const char *nsxml_usage_option_argument_type_string(int argument_type)
{
	switch (argument_type)
	{
		case nsxml_argument_type_existingcommand:
			return ("command");
			
		case nsxml_argument_type_hostname:
			return ("hostname");
			
		case nsxml_argument_type_number:
			return ("number");
			
		case nsxml_argument_type_path:
			return ("path");
			
		case nsxml_argument_type_string:
			return ("string");
	}
	
	return ("?");
}

int nsxml_usage_path_type_count(int fs_type)
{
	int c = 0;
	
	if ((fs_type & nsxml_value_validator_path_type_all) == nsxml_value_validator_path_type_all)
	{
		return 0;
	}
	
	if ((fs_type & nsxml_value_validator_path_type_file) == nsxml_value_validator_path_type_file)
	{
		++c;
	}
	
	if ((fs_type & nsxml_value_validator_path_type_folder) == nsxml_value_validator_path_type_folder)
	{
		++c;
	}
	
	if ((fs_type & nsxml_value_validator_path_type_symlink) == nsxml_value_validator_path_type_symlink)
	{
		++c;
	}
	
	return c;
}

const char *nsxml_usage_path_type_string(int fs_type)
{
	if ((fs_type & nsxml_value_validator_path_type_file) == nsxml_value_validator_path_type_file)
	{
		return ("file");
	}
	
	if ((fs_type & nsxml_value_validator_path_type_folder) == nsxml_value_validator_path_type_folder)
	{
		return ("folder");
	}
	
	if ((fs_type & nsxml_value_validator_path_type_symlink) == nsxml_value_validator_path_type_symlink)
	{
		return ("symbolic link");
	}
	
	return ("?");
}

int nsxml_usage_path_access_count(int fs_access)
{
	int c = 0;
	
	if (fs_access & nsxml_value_validator_path_readable)
	{
		++c;
	}
	
	if (fs_access & nsxml_value_validator_path_writable)
	{
		++c;
	}
	
	if (fs_access & nsxml_value_validator_path_executable)
	{
		++c;
	}
	
	return c;
}

const char *nsxml_usage_path_access_string(int fs_access)
{
	if (fs_access & nsxml_value_validator_path_readable)
	{
		return ("readable");
	}
	
	if (fs_access & nsxml_value_validator_path_writable)
	{
		return ("writable");
	}
	
	if (fs_access & nsxml_value_validator_path_executable)
	{
		return ("executable");
	}
	
	return ("?");
}

void nsxml_usage_option_argument_type(FILE *stream, int argument_type, int short_name)
{
	if (short_name == 1)
	{
		fprintf(stream, " <");
	}
	else
	{
		fprintf(stream, "=");
	}
	
	switch (argument_type)
	{
		case nsxml_argument_type_existingcommand:
			fprintf(stream, "command");
			break;
			
		case nsxml_argument_type_hostname:
			fprintf(stream, "hostname");
			break;
			
		case nsxml_argument_type_number:
			fprintf(stream, "number");
			break;
			
		case nsxml_argument_type_path:
			fprintf(stream, "path");
			break;
			
		case nsxml_argument_type_string:
			fprintf(stream, "string");
			break;
			
		default:
			fprintf(stream, "...");
			break;
	}
	
	if (short_name == 1)
	{
		fprintf(stream, ">");
	}
}

void nsxml_usage_option_inline_details(FILE *stream, struct nsxml_option_info *info, int short_name)
{
	if (info->option_type == nsxml_option_type_argument)
	{
		nsxml_usage_option_argument_type(stream, ((struct nsxml_argument_option_info *)(info))->argument_type, short_name);
	}
	else if (info->option_type == nsxml_option_type_multiargument)
	{
	
	}
}

void nsxml_usage_option_root_short(FILE *stream, struct nsxml_rootitem_info *info, int index, int *visited, const struct ]]><value-of select="$prg.c.parser.structName.nsxml_util_text_wrap_options"/><![CDATA[ *wrap)
{
	int is_first = 1;
	int i;
	int c = info->option_info_count;
	const char *n;
	struct nsxml_group_option_info *parent = NULL;
	
	if (index >= 0)
	{
		parent = (struct nsxml_group_option_info *) info->option_infos[index];
	}
	
	/* First pass, switch options with short names */
	if (!(parent && (parent->group_type == nsxml_group_option_exclusive)))
	{
		for (i = 0; i < c; ++i)
		{
			struct nsxml_option_info *o = info->option_infos[i];
			
			if ((visited[i] == 0) && (o->parent == parent) && (o->option_type == nsxml_option_type_switch))
			{
				const char *n = nsxml_usage_get_first_short_name(o);
				
				if (n)
				{
					visited[i] = 1;
					
					if (is_first == 1)
					{
						fprintf(stream, "-%s", n);
						is_first = 0;
					}
					else
					{
						fprintf(stream, "%s", n);
					}
				}
			}
		}
	}
	
	/* Other */
	for (i = 0; i < c; ++i)
	{
		struct nsxml_option_info *o = info->option_infos[i];
		
		if ((visited[i] == 0) && (o->parent == parent))
		{
			if (is_first == 0)
			{
				if (parent && (parent->group_type == nsxml_group_option_exclusive))
				{
					fprintf(stream, " | ");
				}
				else
				{
					fprintf(stream, " ");
				}
			}
			
			is_first = 0;
			visited[i] = 1;
			n = nsxml_usage_get_first_short_name(o);
			
			if (n)
			{
				fprintf(stream, "-%s", n);
				nsxml_usage_option_inline_details(stream, o, 1);
			}
			else if ((n = nsxml_usage_get_first_long_name(o)) != NULL)
			{
				fprintf(stream, "--%s", n);
				nsxml_usage_option_inline_details(stream, o, 0);
			}
			else if (o->option_type == nsxml_option_type_group)
			{
				fprintf(stream, "(");
				nsxml_usage_option_root_short(stream, info, i, visited, wrap);
				fprintf(stream, ")");
			}
		}
	}
	
}

void nsxml_usage_option_detailed(FILE *stream, const struct nsxml_option_info *info, int format, const struct ]]><value-of select="$prg.c.parser.structName.nsxml_util_text_wrap_options"/><![CDATA[ *wrap, int level, char **text_buffer_ptr, size_t *text_buffer_length_ptr)
{
	int i;
	/* Option names */
	int names_length = 0;
	int name_count = 0;
	size_t abstract_length = 0;
	const struct nsxml_item_name *n = info->names;
	struct nsxml_value_validator *v;
	char *text_ptr;
	
	while (n)
	{
		if (n->name)
		{
			names_length += strlen(n->name);
			names_length += (strlen(n->name) > 1) ? 2 : 1;
			++name_count;
		}
		
		n = n->next_name;
	}
	
	abstract_length = names_length + name_count; /* names + spaces */
	
	if (info->item_info.abstract)
	{
		abstract_length += strlen(info->item_info.abstract) + 2; /* names + ": " + abstract */
	}
	
	++abstract_length;
	
	if (abstract_length > *text_buffer_length_ptr)
	{
		*text_buffer_ptr = (char *) realloc(*text_buffer_ptr, abstract_length);
		*text_buffer_length_ptr = abstract_length;
	}
	
	text_ptr = *text_buffer_ptr;
	
	if (names_length > 0)
	{
		int c = 0;
		int t = 0;
		n = info->names;
		
		while (n)
		{
			if (n->name)
			{
				if (t == 0)
				{
					c = snprintf(text_ptr, *text_buffer_length_ptr - t, "%s%s", ((strlen(n->name) > 1) ? "--" : "-"), n->name);
					
				}
				else
				{
					c = snprintf(text_ptr, *text_buffer_length_ptr - t, " %s%s", ((strlen(n->name) > 1) ? "--" : "-"), n->name);
				}
				
				t += c;
				text_ptr += c;
			}
			
			n = n->next_name;
		}
		
		if (info->item_info.abstract)
		{
			text_ptr += snprintf(text_ptr, *text_buffer_length_ptr - t, ": %s\n", info->item_info.abstract);
		}
	}
	else if (info->item_info.abstract)
	{
		text_ptr += snprintf(text_ptr, *text_buffer_length_ptr, "%s\n", info->item_info.abstract);
	}
	
	*text_ptr = '\0';
	
	]]><value-of select="$prg.c.parser.functionName.nsxml_util_text_wrap_fprintf"/><![CDATA[(stream, *text_buffer_ptr, wrap, level);
	
	if (info->item_info.details && (format & ]]><value-of select="$prg.c.parser.variableName.nsxml_usage_format_details"/><![CDATA[) == ]]><value-of select="$prg.c.parser.variableName.nsxml_usage_format_details"/><![CDATA[)
	{
		]]><value-of select="$prg.c.parser.functionName.nsxml_util_text_wrap_fprintf"/><![CDATA[(stream, info->item_info.details, wrap, level + 1);
	}
	
	if (info->option_type == nsxml_option_type_argument)
	{
		const struct nsxml_argument_option_info *a = (const struct nsxml_argument_option_info *) info;
		
		if (a->argument_type > nsxml_argument_type_mixed)
		{
			]]><value-of select="$prg.c.parser.functionName.nsxml_util_asnprintf"/><![CDATA[(text_buffer_ptr, text_buffer_length_ptr, "Argument type: %s\n", nsxml_usage_option_argument_type_string(a->argument_type));
			]]><value-of select="$prg.c.parser.functionName.nsxml_util_text_wrap_fprintf"/><![CDATA[(stream, *text_buffer_ptr, wrap, level + 1);
		}
	}
	
	if (info->option_type == nsxml_option_type_multiargument)
	{
		const struct nsxml_multiargument_option_info *m = (const struct nsxml_multiargument_option_info *) info;
		
		if (m->argument_type > nsxml_argument_type_mixed)
		{
			]]><value-of select="$prg.c.parser.functionName.nsxml_util_asnprintf"/><![CDATA[(text_buffer_ptr, text_buffer_length_ptr, "Arguments type: %s\n", nsxml_usage_option_argument_type_string(m->argument_type));
			]]><value-of select="$prg.c.parser.functionName.nsxml_util_text_wrap_fprintf"/><![CDATA[(stream, *text_buffer_ptr, wrap, level + 1);
		}
		
		if (m->min_argument > 1)
		{
			]]><value-of select="$prg.c.parser.functionName.nsxml_util_asnprintf"/><![CDATA[(text_buffer_ptr, text_buffer_length_ptr, "Minimum number of arguments: %d\n", m->min_argument);
			]]><value-of select="$prg.c.parser.functionName.nsxml_util_text_wrap_fprintf"/><![CDATA[(stream, *text_buffer_ptr, wrap, level + 1);
		}
		
		if (m->max_argument > 1)
		{
			]]><value-of select="$prg.c.parser.functionName.nsxml_util_asnprintf"/><![CDATA[(text_buffer_ptr, text_buffer_length_ptr, "Maximum number of arguments: %d\n", m->max_argument);
			]]><value-of select="$prg.c.parser.functionName.nsxml_util_text_wrap_fprintf"/><![CDATA[(stream, *text_buffer_ptr, wrap, level + 1);
		}
	}
	
	v = info->validators;
	
	while (v)
	{
		if (v->usage_callback)
		{
			if ((*v->usage_callback)(v, info, text_buffer_ptr, text_buffer_length_ptr) > 0)
			{
				]]><value-of select="$prg.c.parser.functionName.nsxml_util_text_wrap_fprintf"/><![CDATA[(stream, *text_buffer_ptr, wrap, level + 1);
			}
		}
		
		v = v->next_validator;
	}
	
	if (info->option_type == nsxml_option_type_group)
	{
		const struct nsxml_group_option_info *g = (const struct nsxml_group_option_info *) info;
		
		for (i = 0; i < g->option_info_count; ++i)
		{
			nsxml_usage_option_detailed(stream, g->option_info_refs[i], format, wrap, level + 1, text_buffer_ptr, text_buffer_length_ptr);
		}
	}
}

void nsxml_usage_option_root_detailed(FILE *stream, struct nsxml_rootitem_info *info, int format, const struct ]]><value-of select="$prg.c.parser.structName.nsxml_util_text_wrap_options"/><![CDATA[ *wrap)
{
	int i;
	size_t text_buffer_length = 1024;
	char *text_buffer = (char *) malloc(sizeof(char) * text_buffer_length);
	
	for (i = 0; i < info->option_info_count; ++i)
	{
		const struct nsxml_option_info *o = info->option_infos[i];
		
		if (!o->parent)
		{
			nsxml_usage_option_detailed(stream, o, format, wrap, 1, &text_buffer, &text_buffer_length);
		}
	}
	
	free(text_buffer);
}

void nsxml_usage(FILE *stream, struct nsxml_program_info *info, struct nsxml_program_result *result, int format, const struct ]]><value-of select="$prg.c.parser.structName.nsxml_util_text_wrap_options"/><![CDATA[ *user_wrap)
{
	int i;
	int c = info->rootitem_info.option_info_count;
	int *visited = (int *) malloc(sizeof(int) * c);
	struct nsxml_subcommand_info *scinfo = NULL;
	const struct ]]><value-of select="$prg.c.parser.structName.nsxml_util_text_wrap_options"/><![CDATA[ *wrap;
	
	struct ]]><value-of select="$prg.c.parser.structName.nsxml_util_text_wrap_options"/><![CDATA[ default_wrap;
	]]><value-of select="$prg.c.parser.functionName.nsxml_util_text_wrap_options_init"/><![CDATA[(&default_wrap, 2, 80, ]]><value-of select="$prg.c.parser.variableName.nsxml_util_text_wrap_indent_others"/><![CDATA[, ]]><value-of select="$prg.c.parser.variableName.nsxml_util_text_wrap_eol_lf"/><![CDATA[);
	wrap = user_wrap;
	
	if (!user_wrap)
	{
		wrap = &default_wrap;
	}
	
	for (i = 0; i < c; ++i)
	{
		visited[i] = 0;
	}
	
	fprintf(stream, "usage: %s ", info->name);
	
	if (result && result->subcommand_name)
	{
		for (i = 0; i < info->subcommand_info_count; ++i)
		{
			if (strcmp(result->subcommand_name, info->subcommand_infos[i].names->name) == 0)
			{
				scinfo = &info->subcommand_infos[i];
				break;
			}
		}
	}
	
	if (scinfo)
	{
		fprintf(stdout, " %s ", result->subcommand_name);
		nsxml_usage_option_root_short(stream, &scinfo->rootitem_info, -1, visited, wrap);
	}
	else
	{
		nsxml_usage_option_root_short(stream, &info->rootitem_info, -1, visited, wrap);
	}
	
	if ((format & ]]><value-of select="$prg.c.parser.variableName.nsxml_usage_format_abstract"/><![CDATA[) == ]]><value-of select="$prg.c.parser.variableName.nsxml_usage_format_abstract"/><![CDATA[)
	{
		fprintf(stream, "%s\n", "\nwith");
		
		if (scinfo)
		{
			nsxml_usage_option_root_detailed(stream, &scinfo->rootitem_info, format, wrap);
		}
		else
		{
			nsxml_usage_option_root_detailed(stream, &info->rootitem_info, format, wrap);
		}
	}
	
	free(visited);
	fprintf(stream, "%s\n", "");
}

/* Parser Functions ******************************/

struct nsxml_option_name_binding *nsxml_parse_find_option_at(struct nsxml_parser_state *state, struct nsxml_program_result *result, const char *name, int group_index)
{
	int o;
	
	for (o = 0; o < state->option_name_binding_counts[group_index]; ++o)
	{
		if (strcmp(state->option_name_bindings[group_index][o].name_ref, name) == 0)
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Found name %s\n", name);
			return &state->option_name_bindings[group_index][o];
		}
	}
	
	return NULL;
}

struct nsxml_option_name_binding *nsxml_parse_find_option(struct nsxml_parser_state *state, struct nsxml_program_result *result, const char *name)
{
	struct nsxml_option_name_binding *option = NULL;
	
	if (state->subcommand_index > 0)
	{
		option = nsxml_parse_find_option_at(state, result, name, state->subcommand_index);
	}
	
	if (option == NULL)
	{
		option = nsxml_parse_find_option_at(state, result, name, 0);
	}
	
	return option;
}

int nsxml_parse_argument_validates(struct nsxml_parser_state *state, struct nsxml_program_result *result, const char *value)
{
	struct nsxml_value_validator *validator = state->active_option->info_ref->validators;
	
	while (validator)
	{
		if (validator->validation_callback)
		{
			if ((*validator->validation_callback)(validator, state, result, state->active_option, value) == 0)
			{
				return 0;
			}
		}
		
		validator = validator->next_validator;
	}
	
	return 1;
}

int nsxml_parse_positional_argument_validates(struct nsxml_parser_state *state, struct nsxml_program_result *result, const struct nsxml_positional_argument_info *info, const char *value)
{
	struct nsxml_value_validator *validator = info->validators;
	
	while (validator)
	{
		if (validator->validation_callback)
		{
			if ((*validator->validation_callback)(validator, state, result, NULL, value) == 0)
			{
				return 0;
			}
		}
		
		validator = validator->next_validator;
	}
	
	return 1;
}

int nsxml_parse_option_expected(struct nsxml_parser_state *state, struct nsxml_program_result *result, const struct nsxml_option_name_binding *option)
{
	int a;
	
	if (option->level > 0)
	{
		const struct nsxml_group_option_info *parent_info = option->info_ref->parent;
		const struct nsxml_option_result *previous_ancestor = (const struct nsxml_option_result *)(option->result_ref);
		
		for (a = 0; a < option->level; ++a)
		{
			const struct nsxml_group_option_result *ancestor_res = option->parent_tree_refs[a];
			
			if ((parent_info->group_type == nsxml_group_option_exclusive) && (ancestor_res->is_set > 0) && (ancestor_res->selected_option != previous_ancestor))
			{
				const char *option_name = option->info_ref->names->name;
				const char *ancestor_name = (parent_info->option_info.names) ? parent_info->option_info.names->name : NULL;
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "option %s is unexpected due to exclusive rule of group at level %d (%s)\n", ((option_name) ? option_name : "?"), a, ((ancestor_name) ? ancestor_name : parent_info->option_info.item_info.abstract));
				return 0;
			}
			
			previous_ancestor = (const struct nsxml_option_result *) ancestor_res;
			parent_info = parent_info->option_info.parent;
		}
	}
	
	return 1;
}

void nsxml_parse_mark_option(struct nsxml_parser_state *state, struct nsxml_program_result *result, struct nsxml_option_name_binding *option, int is_set)
{
	int p;
	const struct nsxml_option_info *info = option->info_ref;
	const struct nsxml_group_option_info *parent_info = info->parent;
	struct nsxml_option_result *res = option->result_ref;
	struct nsxml_option_result *child_res;
	const char *name;
	
	if (info->option_type == nsxml_option_type_group)
	{
		/**
		 * @note This should not happens
		 */
		assert(0);
		
		res->is_set += (is_set) ? 1 : -1;
		
		if (is_set == 0)
		{
			((struct nsxml_group_option_result *) res)->selected_option = NULL;
		}
	}
	else
	{
		res->is_set = (is_set) ? 1 : 0;
	}
	
	nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Mark option %s: %d (%d)\n", option->info_ref->names->name, is_set, res->is_set);
	
	child_res = res;
	
	for (p = 0; p < option->level; ++p)
	{
		struct nsxml_group_option_result *parent_res = option->parent_tree_refs[p];
		parent_res->is_set += (is_set) ? 1 : -1;
		
		if (parent_info->group_type == nsxml_group_option_exclusive)
		{
			parent_res->selected_option = (is_set) ? child_res : NULL;
			parent_res->selected_option_name = info->var_name;
		}
		
		info = &parent_info->option_info;
		
		name = (info->var_name) ? info->var_name : ((info->names && info->names->name) ? info->names->name : info->item_info.abstract);
		nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Mark parent option %s: %d (%d)\n", ((name) ? name : "?"), is_set, parent_res->is_set);
		
		if (parent_res->is_set == 0)
		{
			parent_res->selected_option = NULL;
		}
		
		parent_info = parent_info->option_info.parent;
	}
}

void nsxml_parse_unset_active_option(struct nsxml_parser_state *state, struct nsxml_program_result *result)
{
	int mark_set = 0;
	size_t a;
	
	if (state->active_option == NULL)
	{
		return;
	}
	
	nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Unset option %s\n", state->active_option_cli_name);
	
	if (state->state_flags & nsxml_parser_state_option_unexpected)
	{
		nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_error"/><![CDATA[, "Unexpected option %s\n", state->active_option_cli_name);
	}
	
	if (state->active_option->info_ref->option_type == nsxml_option_type_switch)
	{
		mark_set = 1;
		
		if (state->active_option_argc > 0)
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_warning"/><![CDATA[, "Ignore option argument '%s' for switch %s\n", state->active_option_argv[0], state->active_option_cli_name);
		}
	}
	
	if (state->active_option->info_ref->option_type == nsxml_option_type_argument)
	{
		struct nsxml_argument_option_result *res = (struct nsxml_argument_option_result *) state->active_option->result_ref;
		struct nsxml_argument_option_info *ainfo = (struct nsxml_argument_option_info *) state->active_option->info_ref;
		
		if (state->active_option_argc > 0)
		{
			if (!(state->state_flags & nsxml_parser_state_option_unexpected) && nsxml_parse_argument_validates(state, result, state->active_option_argv[0]))
			{
				mark_set = 1;
				nsxml_value_set(&res->argument, nsxml_argument_type_to_value_type(ainfo->argument_type), state->active_option_argv[0]);
			}
			else
			{
				nsxml_value_set(&res->argument, ]]><value-of select="$prg.c.parser.variableName.nsxml_value_type_null"/><![CDATA[, NULL);
			}
		}
		else
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_error"/><![CDATA[, "Missing argument for option %s\n", state->active_option_cli_name);
		}
	}
	else if (state->active_option->info_ref->option_type == nsxml_option_type_multiargument)
	{
		struct nsxml_multiargument_option_result *res = (struct nsxml_multiargument_option_result *) state->active_option->result_ref;
		struct nsxml_multiargument_option_info *ainfo = (struct nsxml_multiargument_option_info *) state->active_option->info_ref;
		
		if (state->active_option_argc > 0)
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Assigning %d arguments to result\n", state->active_option_argc);
			
			for (a = 0; a < state->active_option_argc; ++a)
			{
				if ((ainfo->max_argument > 0) && (res->argument_count >= ainfo->max_argument))
				{
					break;
				}
				
				if (!(state->state_flags & nsxml_parser_state_option_unexpected) && nsxml_parse_argument_validates(state, result, state->active_option_argv[a]))
				{
					mark_set = 1;
					nsxml_value_append(&res->arguments, nsxml_argument_type_to_value_type(ainfo->argument_type), state->active_option_argv[a]);
				}
				else
				{
					/**
					 * Temporary add a dummy arg
					 */
					nsxml_value_append(&res->arguments, ]]><value-of select="$prg.c.parser.variableName.nsxml_value_type_null"/><![CDATA[, NULL);
				}
				
				++res->argument_count;
			}
		}
		else
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_error"/><![CDATA[, "Missing argument for option %s\n", state->active_option_cli_name);
		}
	}
	
	if (!(state->state_flags & nsxml_parser_state_option_unexpected) && mark_set && state->active_option->result_ref)
	{
		nsxml_parse_mark_option(state, result, state->active_option, 1);
	}
	
	state->active_option_argc = 0;
	state->active_option = NULL;
	state->active_option_cli_name[0] = '\0';
	state->active_option_name = NULL;
	state->state_flags &= ~(nsxml_parser_state_option_unexpected);
}

int nsxml_parse_active_option_accepts_argument(struct nsxml_parser_state *state, struct nsxml_program_result *result)
{
	if (state->active_option->info_ref->option_type == nsxml_option_type_switch)
	{
		nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Switch never accepts arguments");
		return 0;
	}
	
	if (state->active_option->info_ref->option_type == nsxml_option_type_multiargument)
	{
		struct nsxml_multiargument_option_info *info = (struct nsxml_multiargument_option_info *) state->active_option->info_ref;
		struct nsxml_multiargument_option_result *res = (struct nsxml_multiargument_option_result *) state->active_option->result_ref;
		
		if ((info->max_argument > 0) && res)
		{
			if ((state->active_option_argc + res->argument_count) >= info->max_argument)
			{
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Multi argument reach its max %d + %d >= %d\n", state->active_option_argc, res->argument_count, info->max_argument);
				return 0;
			}
		}
	}
	else if (state->active_option->info_ref->option_type == nsxml_option_type_argument)
	{
		if (state->active_option_argc > 0)
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "SingleArgument option got its arguments\n");
			return 0;
		}
	}
	
	return 1;
}

void nsxml_parse_append_option_argument(struct nsxml_parser_state *state, struct nsxml_program_result *result, const char *value)
{
	nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Append '%s' as argument %d of option %s\n", value, state->active_option_argc, state->active_option_cli_name);
	state->active_option_argv[state->active_option_argc] = value;
	++state->active_option_argc;
}

void nsxml_parse_process_positional_argument(struct nsxml_parser_state *state, struct nsxml_program_result *result, const char *value)
{
	int s;
	nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "treat %s as subcommand or positional argument\n", value);
	nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, " EOO: %d, sc index: %d, value count: %d\n", (state->state_flags & nsxml_parser_state_endofoptions), state->subcommand_index, state->value_count);
	
	if (!(state->state_flags & nsxml_parser_state_endofoptions) && (state->subcommand_index == 0) && (state->value_count == 0))
	{
		nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Search for a subcommand name (%d names)\n", (int) state->subcommand_name_binding_count);
		
		for (s = 0; s < state->subcommand_name_binding_count; ++s)
		{
			if (strcmp(state->subcommand_name_bindings[s].name_ref, value) == 0)
			{
				state->subcommand_index = state->subcommand_name_bindings[s].subcommand_index;
				result->subcommand_name = state->subcommand_name_bindings[s].info_ref->names->name;
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Found subcommand %d %s -> %s\n", s, value, state->subcommand_name_bindings[s].info_ref->names->name);
				return;
			}
		}
	}
	
	nsxml_value_append(&state->values, ]]><value-of select="$prg.c.parser.variableName.nsxml_value_type_string"/><![CDATA[, value);
	++state->value_count;
}

int nsxml_parse_option_postprocess(struct nsxml_parser_state *state, struct nsxml_program_result *result)
{
	int g;
	int o;
	int mark_change_count = 0;
	
	/**
	 * Post check min_argument in multi-argument
	 * Cleanup values for unset options
	 */
	for (g = 0; g < state->option_name_binding_group_count; ++g)
	{
		const struct nsxml_option_info *info = NULL;
		
		for (o = 0; o < state->option_name_binding_counts[g]; ++o)
		{
			struct nsxml_option_name_binding *binding = &state->option_name_bindings[g][o];
			const struct nsxml_option_info *i = binding->info_ref;
			
			if (i == info) /* same option, different names */
			{
				continue;
			}
			
			info = i;
			
			if (i->option_type == nsxml_option_type_argument)
			{
				struct nsxml_argument_option_result *res = (struct nsxml_argument_option_result *) binding->result_ref;
				
				if (res->is_set == 0)
				{
					struct nsxml_argument_option_info *ainfo = (struct nsxml_argument_option_info *) i;
					
					if (ainfo->default_value && nsxml_parse_option_expected(state, result, binding))
					{
						/**
						 * @todo Validate the default value ?
						 */
						nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Set default value '%s' for option %s%s\n", ainfo->default_value, (strlen(i->names->name) > 1) ? "--" : "-", i->names->name);
						nsxml_value_set(&res->argument, nsxml_argument_type_to_value_type(ainfo->argument_type), ainfo->default_value);
						nsxml_parse_mark_option(state, result, binding, 1);
						++mark_change_count;
					}
					else
					{
						nsxml_value_cleanup(&res->argument);
					}
				}
			}
			else if (i->option_type == nsxml_option_type_multiargument)
			{
				struct nsxml_multiargument_option_info *mi = (struct nsxml_multiargument_option_info *) i;
				struct nsxml_multiargument_option_result *res = (struct nsxml_multiargument_option_result *) binding->result_ref;
				
				if ((res->is_set == 1) && ((mi->min_argument > 0) && (res->argument_count < mi->min_argument)))
				{
					nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_error"/><![CDATA[, "At least %d arguments are required for %s%s option, got %d\n", mi->min_argument, (strlen(i->names->name) > 1) ? "--" : "-", i->names->name, res->argument_count);
					res->is_set = 0;
					++mark_change_count;
				}
				
				if (res->is_set == 0)
				{
					res->argument_count = 0;
					nsxml_value_free(res->arguments);
					res->arguments = NULL;
					res->argument_count = 0;
				}
			}
		}
	}
	
	return mark_change_count;
}

int nsxml_parse_positional_argument_process(struct nsxml_parser_state *state, struct nsxml_program_result *result)
{
	int i;
	const struct nsxml_rootitem_info *root = &state->program_info_ref->rootitem_info;
	const struct nsxml_positional_argument_info *pai = NULL;
	const ]]><value-of select="$prg.c.parser.structName.nsxml_value"/><![CDATA[ *v = state->values;
	int valid_positional_argument = 0;
	int pa_index = 0;
	int pai_index = 0;
	int current_pai_value_count = 0;
	
	if (state->subcommand_index > 0)
	{
		root = &state->program_info_ref->subcommand_infos[state->subcommand_index - 1].rootitem_info;
	}
	
	nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Positional arguments processing (%d values / %d PA infos)\n", state->value_count, root->positional_argument_info_count);
	
	if ((root->positional_argument_info_count == 0) && (state->value_count > 0))
	{
		if (state->subcommand_index > 0)
		{
			nsxml_program_result_add_message(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_error"/><![CDATA[, "Subcommand does not accept positional arguments\n");
		}
		else
		{
			nsxml_program_result_add_message(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_error"/><![CDATA[, "Program does not accept positional arguments\n");
		}
		
		return valid_positional_argument;
	}
	
	while (v && (pai_index < root->positional_argument_info_count))
	{
		nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Process positional argument %d (%d of PAI %d)\n", pa_index, current_pai_value_count, pai_index);
		pai = &root->positional_argument_infos[pai_index];
		++current_pai_value_count;
		
		/**
		 * @todo validates
		 */
		if (nsxml_parse_positional_argument_validates(state, result, pai, v->string_value))
		{
			/*
			 * @todo detach/move rather than new copy
			 */
			nsxml_value_append(&result->values, v->type, v->string_value);
			result->value_count++;
			++valid_positional_argument;
			++current_pai_value_count;
		}
		
		if ((pai->max_argument > 0) && (current_pai_value_count >= pai->max_argument))
		{
			current_pai_value_count = 0;
			++pai_index;
		}
		
		v = v->next_value;
		++pa_index;
	}
	
	if (v)
	{
		/**
		 * @todo warning or error ?
		 */
		nsxml_program_result_add_message(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_error"/><![CDATA[, "Too many positional arguments\n");
	}
	else if (pai_index < root->positional_argument_info_count)
	{
		/**
		 * @note not yet supported by schema
		 */
		for (i = pai_index; i < root->positional_argument_info_count; ++i)
		{
			if (root->positional_argument_infos[i].positional_argument_flags & nsxml_positional_argument_required)
			{
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_error"/><![CDATA[, "Required positional argument %d is missing\n", i);
			}
		}
	}
	
	return valid_positional_argument;
}

void nsxml_parse_core(struct nsxml_parser_state *state, struct nsxml_program_result *result)
{
	int a;
	int g;
	int o;
	
	state->active_option_argc = 0;
	state->active_option = NULL;
	state->active_option_cli_name[0] = '\0';
	
	for (a = state->arg_index; a < state->argc; ++a)
	{
		state->state_flags &= ~nsxml_parser_state_stayoncurrentitem;
		nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Processing '%s'\n", state->argv[a]);
		
		if (state->active_option)
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Check current option\n");
			
			if (nsxml_parse_active_option_accepts_argument(state, result) == 0)
			{
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "No more arguments accepted\n");
				nsxml_parse_unset_active_option(state, result);
			}
		}
		
		if (state->state_flags & nsxml_parser_state_endofoptions)
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "EOO\n");
			nsxml_parse_process_positional_argument(state, result, state->argv[a]);
		}
		else if (strcmp(state->argv[a], "--") == 0)
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "EOO marker\n");
			
			state->state_flags |= nsxml_parser_state_endofoptions;
			nsxml_parse_unset_active_option(state, result);
		}
		else if (strcmp(state->argv[a], "-") == 0)
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "EOA marker\n");
			
			if (state->active_option)
			{
				if (state->active_option->info_ref->option_type == nsxml_option_type_multiargument)
				{
					if (state->active_option_argc == 0)
					{
						nsxml_program_result_add_message(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_warning"/><![CDATA[, "Ignoring end-of-argument marker\n");
						nsxml_parse_append_option_argument(state, result, state->argv[a]);
					}
					else
					{
						nsxml_parse_unset_active_option(state, result);
					}
				}
				else if (state->active_option->info_ref->option_type == nsxml_option_type_argument) /* and accepts arguments which should be true */
				{
					nsxml_parse_append_option_argument(state, result, state->argv[a]);
				}
				
				/* 'switch' case should not happens */
			}
			else
			{
				nsxml_parse_process_positional_argument(state, result, state->argv[a]);
			}
		}
		else if (]]><value-of select="$prg.c.parser.functionName.nsxml_util_string_starts_with"/><![CDATA[(state->argv[a], "\\-"))
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Protected value\n");
			
			if (state->active_option)
			{
				nsxml_parse_append_option_argument(state, result, (state->argv[a] + 1));
			}
			else
			{
				nsxml_parse_process_positional_argument(state, result, (state->argv[a] + 1));
			}
		}
		else if (state->active_option && state->active_option_argc == 0)
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Always add first argument\n");
			nsxml_parse_append_option_argument(state, result, state->argv[a]);
		}
		else if (]]><value-of select="$prg.c.parser.functionName.nsxml_util_string_starts_with"/><![CDATA[(state->argv[a], "--"))
		{
			const char *tail = strstr(state->argv[a], "=");
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Long option\n");
			
			if (state->active_option)
			{
				nsxml_parse_unset_active_option(state, result);
			}
			
			if (tail)
			{
				size_t tail_length = strlen(tail);
				size_t arg_length = strlen(state->argv[a]);
				]]><value-of select="$prg.c.parser.functionName.nsxml_util_strncpy"/><![CDATA[(state->active_option_cli_name, NSXML_OPTION_NAME_BUFFER_LENGTH, state->argv[a], (arg_length - tail_length));
				++tail;
				
				if (*tail == '\0')
				{
					tail = NULL;
				}
			}
			else
			{
				]]><value-of select="$prg.c.parser.functionName.nsxml_util_strncpy"/><![CDATA[(state->active_option_cli_name, NSXML_OPTION_NAME_BUFFER_LENGTH, state->argv[a], strlen(state->argv[a]));
			}
			
			state->active_option_name = state->active_option_cli_name + 2;
			
			state->active_option = nsxml_parse_find_option(state, result, state->active_option_name);
			
			if (state->active_option)
			{
				if (nsxml_parse_option_expected(state, result, state->active_option) == 0)
				{
					state->state_flags |= nsxml_parser_state_option_unexpected;
				}
				
				if (tail)
				{
					nsxml_parse_append_option_argument(state, result, tail);
				}
			}
			else
			{
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_fatal_error"/><![CDATA[, "Unknown option %s\n", state->active_option_cli_name);
				state->state_flags |= nsxml_parser_state_abort;
				state->active_option_cli_name[0] = '\0';
				state->active_option_name = NULL;
				break;
			}
		}
		else if (]]><value-of select="$prg.c.parser.functionName.nsxml_util_string_starts_with"/><![CDATA[(state->argv[a], "-"))
		{
			const char *current_option = (state->argv[a] + 1);
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Short option\n");
			
			if (state->active_option)
			{
				nsxml_parse_unset_active_option(state, result);
			}
			
			while (current_option && (*current_option != '\0'))
			{
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Sub parsing -%c\n", *current_option);
				
				if (state->active_option)
				{
					nsxml_parse_unset_active_option(state, result);
				}
				
				state->active_option_cli_name[0] = '-';
				state->active_option_cli_name[1] = *current_option;
				state->active_option_cli_name[2] = '\0';
				state->active_option_name = state->active_option_cli_name + 1;
				state->active_option = nsxml_parse_find_option(state, result, state->active_option_name);
				
				if (state->active_option)
				{
					if (nsxml_parse_option_expected(state, result, state->active_option) == 0)
					{
						state->state_flags |= nsxml_parser_state_option_unexpected;
					}
					
					if (((state->active_option->info_ref->option_type == nsxml_option_type_argument) || (state->active_option->info_ref->option_type == nsxml_option_type_multiargument)) && (*(current_option + 1) != '\0'))
					{
						nsxml_parse_append_option_argument(state, result, current_option + 1);
						break;
					}
				}
				else
				{
					nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_fatal_error"/><![CDATA[, "Unknown option %s\n", state->active_option_cli_name);
					state->state_flags |= nsxml_parser_state_abort;
					state->active_option_cli_name[0] = '\0';
					state->active_option_name = NULL;
					break;
				}
				
				if (state->state_flags & nsxml_parser_state_abort)
				{
					break;
				}
				
				++current_option;
			}
		}
		else if (state->active_option)
		{
			nsxml_parse_append_option_argument(state, result, state->argv[a]);
		}
		else
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Other\n");
			nsxml_parse_process_positional_argument(state, result, state->argv[a]);
		}
		
		if (state->state_flags & nsxml_parser_state_abort)
		{
			break;
		}
		
		if (!(state->state_flags & nsxml_parser_state_stayoncurrentitem))
		{
			++state->arg_index;
		}
	}
	
	if (state->active_option)
	{
		nsxml_parse_unset_active_option(state, result);
	}
	
	/**
	 * Post processing options
	 */
	{
		int change_count = 0;
		int pass = 0;
		
		do
		{
			nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Post process pass %d\n", pass);
			change_count = nsxml_parse_option_postprocess(state, result);
			
			if (change_count > 0)
			{
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_debug"/><![CDATA[, "Post process pass %d produces %d changes\n", pass, change_count);
			}
			
			++pass;
		}
		
		while (change_count > 0);
	}
	
	/* Required option checks */
	for (g = 0; g < state->option_name_binding_group_count; ++g)
	{
		for (o = 0; o < state->option_name_binding_counts[g]; ++o)
		{
			struct nsxml_option_name_binding *binding = &state->option_name_bindings[g][o];
			const struct nsxml_option_info *i = binding->info_ref;
			
			if ((i->option_flags & nsxml_option_flag_required) && (binding->result_ref->is_set == 0))
			{
				nsxml_program_result_add_messagef(result, ]]><value-of select="$prg.c.parser.variableName.nsxml_message_type_error"/><![CDATA[, "Missing required option %s%s\n", (strlen(i->names->name) > 1) ? "--" : "-", i->names->name);
			}
		}
	}
	
	nsxml_parse_positional_argument_process(state, result);
}

#if defined(__cplusplus)
} /* extern "C" */
#endif
]]></variable>
	<template match="//prg:program">
		<value-of select="$prg.c.parser.genericSource"/>
	</template>

</stylesheet>