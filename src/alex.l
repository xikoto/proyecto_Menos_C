/* Subseccion preambulo C */
%{
#include <stdio.h>
#include "header.h"
#include "asin.h"
#define verbose(x) {if(verbosidad) ECHO; return x;}
%}

/* Subseccion de definiciones */
%option yylineno

delimitador [ \t]+
letra [a-zA-Z]
digito [0-9]

%%

{delimitador}	{if( verbosidad ) ECHO;}
"\n" 			{if( verbosidad ) ECHO;}
"//".*"\n"		{if( verbosidad ) ECHO;}
if				{verbose(IF_);}
else			{verbose(ELSE_);}
for		{verbose(FOR_);}
while       {verbose(WHILE_);}
do          {verbose(DO_);}
"&&"		{verbose(AND_);}
"||"		{verbose(OR_);}

int 		{verbose(INT_);}
bool 		{verbose(BOOL_);}
true		{verbose(TRUE_);}
false		{verbose(FALSE_);}
struct		{verbose(STRUCT_);}

read		{verbose(READ_);}
print		{verbose(PRINT_);}

"="		{verbose(ASIG_);}
"+"		{verbose(SUMA_);}
"-"		{verbose(RESTA_);}
"*"		{verbose(MULT_);}
"/"		{verbose(DIV_);}
"++"		{verbose(MASMAS_);}
"--"		{verbose(MENOSMENOS_);}
"!"		{verbose(NO_);}
"=="		{verbose(IGUAL_);}
"!="		{verbose(DESIGUAL_);}
">="		{verbose(MAYORIGUAL_);}
"<="		{verbose(MENORIGUAL_);}
">"		{verbose(MAYOR_);}
"<"		{verbose(MENOR_);}
"("		{verbose(PARENTESISA_);}
")"		{verbose(PARENTESISC_);}
"["		{verbose(CORCHETEA_);}
"]"		{verbose(CORCHETEC_);}
"{"		{verbose(LLAVEA_);}
"}"		{verbose(LLAVEC_);}
";"		{verbose(PUNTOYCOMA_);}
"."		{verbose(PUNTO_);}



{digito}+|{digito}+\.{digito}+	{yylval.cent = (int) atoi(yytext);verbose(CTE_);}

\.{digito}+ {yylval.cent = 0; verbose (CTE_);}

{digito}+\. {
				if(verbosidad) ECHO;
				yytext[strlen(yytext)-1] = 0;
				yylval.cent = (int) atoi(yytext);
				return(CTE_);
			}

{letra}(({letra}|{digito}|\_|\-({letra}|{digito})+))*	{yylval.ident = strdup(yytext); verbose(ID_);}
.           {yyerror("Caracter ilegal"); }


%%
