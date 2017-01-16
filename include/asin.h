/* A Bison parser, made by GNU Bison 3.0.4.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_ASIN_H_INCLUDED
# define YY_YY_ASIN_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    SUMA_ = 258,
    RESTA_ = 259,
    MASMAS_ = 260,
    MENOSMENOS_ = 261,
    MULT_ = 262,
    DIV_ = 263,
    NO_ = 264,
    MAYOR_ = 265,
    MENOR_ = 266,
    MAYORIGUAL_ = 267,
    MENORIGUAL_ = 268,
    IGUAL_ = 269,
    DESIGUAL_ = 270,
    AND_ = 271,
    OR_ = 272,
    PARENTESISA_ = 273,
    PARENTESISC_ = 274,
    CORCHETEA_ = 275,
    CORCHETEC_ = 276,
    LLAVEA_ = 277,
    LLAVEC_ = 278,
    PUNTOYCOMA_ = 279,
    STRUCT_ = 280,
    INT_ = 281,
    BOOL_ = 282,
    READ_ = 283,
    PRINT_ = 284,
    IF_ = 285,
    ELSE_ = 286,
    FOR_ = 287,
    WHILE_ = 288,
    DO_ = 289,
    TRUE_ = 290,
    FALSE_ = 291,
    ASIG_ = 292,
    PUNTO_ = 293,
    SALTOLINEA_ = 294,
    COMENTARIO_ = 295,
    CTE_ = 296,
    ID_ = 297
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED

union YYSTYPE
{
#line 13 "./src/asin.y" /* yacc.c:1909  */

    char *ident; /*valor identificador*/
    int cent;    /*constante numerica entera*/
    int aux;     /*para calculos parciales*/
    lcampos campos;
    aexpr expr;
    bucle_for bucl;

#line 106 "asin.h" /* yacc.c:1909  */
};

typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_ASIN_H_INCLUDED  */
