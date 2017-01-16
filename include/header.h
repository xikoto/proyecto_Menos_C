/*****************************************************************************/
/**   Ejemplo de un posible fichero de cabeceras ("header.h") donde situar  **/
/** las definiciones de constantes, variables y estructuras para MenosC.17  **/
/** Los alumos deberan adaptarlo al desarrollo de su propio compilador.     **/
/*****************************************************************************/
#ifndef _HEADER_H
#define _HEADER_H
/****************************************************** Constantes generales */
#define TRUE  1
#define FALSE 0

#define TALLA_TIPO_SIMPLE 1
/************************************* Variables externas definidas en el AL */
extern FILE *yyin;
extern int   yylineno;
extern char *yytext;
/********************* Variables externas definidas en el Programa Principal */

extern int verTDS;
extern int dvar;
/*****************************************************************************/
extern int verbosidad;              /* Flag para saber si se desea una traza */
extern int numErrores;              /* Contador del numero de errores        */
typedef struct {
	int referencia;
	int talla;
	} lcampos;

typedef struct {
	int tipo;
	int pos;
	int postincr;
	} aexpr; /*atributos expresion*/


typedef struct {
    int ini;
    int lv;
    int si;
    int aux;
    } bucle_for;

#endif  /* _HEADER_H */
/*****************************************************************************/
