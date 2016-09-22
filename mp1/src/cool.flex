/*-- The comments which start with -- are written by myself*/

/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int comment_depth = 0; /*-- for nested comments*/
int null_flag;

%}

%option noyywrap

%x COMMENT
%x STRING

/*
 * Define names for regular expressions here.
 */

DIGIT       [0-9]
LETTER      [a-zA-Z]
NEWLINE     (\r\n)|\n
WHITESPACE  [ \f\r\t\v]

/*-- Key words are defined here
 *--Must be careful: All key words are case insensitive,
 *--but the first letter of true and false must be lowercase
 */

CLASS       (?i:class)
ELSE        (?i:else)
FI          (?i:fi)
IF          (?i:if)
IN          (?i:in)
INHERITS    (?i:inherits)
LET         (?i:let)
LOOP        (?i:loop)
POOL        (?i:pool)
THEN        (?i:then)
WHILE       (?i:while)
CASE        (?i:case)
ESAC        (?i:esac)
NEW         (?i:new)
OF          (?i:of)
ISVOID      (?i:isvoid)
NOT         (?i:not)
TRUE        t(?i:rue)
FALSE       f(?i:alse)

/*-- IDs are defined here */

TYPEID      [A-Z]({DIGIT}|{LETTER}|_)*
OBJECTID    [a-z]({DIGIT}|{LETTER}|_)*
INTEGER     {DIGIT}+

%%

 /*
  * Define regular expressions for the tokens of COOL here. Make sure, you
  * handle correctly special cases, like:
  *   - Nested comments
  *   - String constants: They use C like systax and can contain escape
  *     sequences. Escape sequence \c is accepted for all characters c. Except
  *     for \n \t \b \f, the result is c.
  *   - Keywords: They are case-insensitive except for the values true and
  *     false, which must begin with a lower-case letter.
  *   - Multiple-character operators (like <-): The scanner should produce a
  *     single token for every such operator.
  *   - Line counting: You should keep the global variable curr_lineno updated
  *     with the correct line number
  */
 
 /*-- Must be careful that you must enter a space before writting comments in this area*/
 /*-- The entry of special conditions are defined here, including COMMENT entry and STRING entry
  *-- The operations of COMMENT and STRING are defined in the end of this area
  */

"*)"  {
    yylval.error_msg = "Unmatched *)";
    return ERROR;
}
"(*"  {
    BEGIN(COMMENT);
    comment_depth++; /*-- When you inter the condition COMMENT the depth should be one*/
}
--.*\n    { curr_lineno++; } /*-- The comments which start with --*/ 
\"  {
  string_buf_ptr = string_buf;
  null_flag = 0; 
  BEGIN(STRING); 
}

 /*-- Operators*/

"=>"      { return DARROW; }
"<="      { return LE; }
"<-"      { return ASSIGN; }

"+"        { return '+'; }
"/"        { return '/'; }
"-"        { return '-'; }
"*"        { return '*'; }
"="        { return '='; }
"<"        { return '<'; }
"."        { return '.'; }
"~"        { return '~'; }
","        { return ','; }
";"        { return ';'; }
":"        { return ':'; }
"("        { return '('; }
")"        { return ')'; }
"@"        { return '@'; }
"{"        { return '{'; }
"}"        { return '}'; }

{NEWLINE}   { curr_lineno++; }

 /*-- Keywords*/

{TRUE}  {
    yylval.boolean = true;
    return BOOL_CONST;
}
{FALSE} {
    yylval.boolean = false;
    return BOOL_CONST;
}
{CLASS}     { return CLASS; }
{ELSE}      { return ELSE; }
{FI}        { return FI; }
{IF}        { return IF; }
{IN}        { return IN; }
{INHERITS}  { return INHERITS; }
{ISVOID}    { return ISVOID; }
{LET}       { return LET; }
{LOOP}      { return LOOP; }
{POOL}      { return POOL; }
{THEN}      { return THEN; }
{WHILE}     { return WHILE; }
{CASE}      { return CASE; }
{ESAC}      { return ESAC; }
{NEW}       { return NEW; }
{OF}        { return OF; }
{NOT}       { return NOT; }

 /*-- ID and integer */

{TYPEID}  {
    yylval.symbol = idtable.add_string (yytext);
    return TYPEID;
}
{OBJECTID}  {
    yylval.symbol = idtable.add_string (yytext);
    return OBJECTID;
}
{INTEGER} {
    yylval.symbol = inttable.add_string (yytext);
    return INT_CONST;
}

{WHITESPACE} { ; } /*-- Ignore whitespace*/

 /*--Other words are illegal*/

.  {
  yylval.error_msg = yytext;
  return ERROR;
}

<COMMENT>"*)" {
  comment_depth--;
  if ( comment_depth == 0 )
    BEGIN(INITIAL);
} /*-- Because the comments of COOL are nested, you can only exit the COMMENT condition when depth equals 0*/
<COMMENT>"(*" { comment_depth++; }
<COMMENT>{NEWLINE}  { curr_lineno++; } /*-- Because we don't use the line counter in flex, we must refresh the line counter manually in all conditions*/
<COMMENT><<EOF>>  {
    BEGIN(INITIAL); /*-- Return initial mode to avoid endless loop*/
    yylval.error_msg = "EOF in comment";
    return ERROR;
}
<COMMENT>.  { ; } /*-- Ignore other words*/

<STRING>"\0"     {
  if ( null_flag == 0 )
  {
    null_flag = 1; 
    yylval.error_msg = "String contains null character.";
    return ERROR;
  }
} /*-- NULL character can't appear in the string as the manual refers*/
<STRING><<EOF>> {
  BEGIN(INITIAL);
  yylval.error_msg = "EOF in string constant";
  return ERROR;
}
<STRING>\" {
  BEGIN(INITIAL);
  if ( string_buf_ptr - string_buf >= MAX_STR_CONST )
  {
    yylval.error_msg = "String constant too long";
    return ERROR;
  } /*-- Check the buf to test whether it is full or not*/
  else if ( null_flag == 0 )
  {
    *string_buf_ptr = '\0';
    yylval.symbol = stringtable.add_string (string_buf);
    return STR_CONST;
  } /*-- If not then manually add '\0' in the string. The max size of string should be MAX_STR_CONST - 1*/
}

 /*-- Use four mode to check for letters rather than use if/else*/
<STRING>\\b  {
  if ( string_buf_ptr - string_buf < MAX_STR_CONST )
    *string_buf_ptr++ = '\b'; 
}
<STRING>\\t  {
  if ( string_buf_ptr - string_buf < MAX_STR_CONST )
    *string_buf_ptr++ = '\t'; 
}
<STRING>\\n  {
  if ( string_buf_ptr - string_buf < MAX_STR_CONST )
    *string_buf_ptr++ = '\n'; 
}
<STRING>\\f  {
  if ( string_buf_ptr - string_buf < MAX_STR_CONST )
    *string_buf_ptr++ = '\f'; 
}
 /*-- Other words should be written directly into the buf*/
<STRING>\\. { 
  if ( string_buf_ptr - string_buf < MAX_STR_CONST )
    *string_buf_ptr++ = yytext[1]; 
}
<STRING>.   {
  if ( string_buf_ptr - string_buf < MAX_STR_CONST )
    *string_buf_ptr++ = yytext[0];
}
 /*-- Be careful that the escaped '\n' should also be written into buf*/
<STRING>\\\n  { 
  curr_lineno++;
  if ( string_buf_ptr - string_buf < MAX_STR_CONST )
    *string_buf_ptr++ = '\n';
  }
<STRING>\n  {
  BEGIN(INITIAL);
  curr_lineno++;
  yylval.error_msg = "Unterminated string constant";
  return ERROR;
}

%%
