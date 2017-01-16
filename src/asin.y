/* DECLARACIONES EN C */
/***********/
%{
#include <stdio.h>
#include "header.h"
#include "libtds.h"
#include "libgci.h"
      %}

    /*DECLARACIONES EN BISON*/
    /***************************/

    %union {
    char *ident; /*valor identificador*/
    int cent;    /*constante numerica entera*/
    int aux;     /*para calculos parciales*/
    lcampos campos;
    aexpr expr;
    bucle_for bucl;
}

%token SUMA_ RESTA_ MASMAS_ MENOSMENOS_ MULT_ DIV_ NO_ MAYOR_ MENOR_
%token MAYORIGUAL_ MENORIGUAL_ IGUAL_ DESIGUAL_ AND_ OR_ PARENTESISA_
%token PARENTESISC_ CORCHETEA_ CORCHETEC_ LLAVEA_ LLAVEC_ PUNTOYCOMA_ STRUCT_
%token INT_ BOOL_ READ_ PRINT_ IF_ ELSE_ FOR_ WHILE_ DO_ TRUE_ FALSE_ ASIG_ PUNTO_ SALTOLINEA_ COMENTARIO_
/*****/
%token <cent> CTE_
%token <ident> ID_
/********************/
%type <cent> tipoSimple
%type <expr> expresion
%type <campos> listaCampos /*declarar un struct en el header!*/
%type <expr> expresionSufija
%type <expr> expresionUnaria
%type <expr> expresionMultiplicativa
%type <expr> expresionOpcional
%type <expr> expresionAditiva
%type <expr> expresionRelacional
%type <expr> expresionIgualdad
%type <expr> operadorUnario
%type <aux> operadorLogico
%type <aux> operadorIgualdad
%type <aux> operadorRelacional
%type <aux> operadorAditivo
%type <aux> operadorMultiplicativo
%type <aux> operadorIncremento
%type <aux> instruccionAsignacion



%%
    /********/
    /*ESPECIFICACION SINTACTICA*/
    /***********/
programa :
  { dvar=0; si=0; }

  LLAVEA_ secuenciaSentencias LLAVEC_

  {
    emite(FIN, crArgNul(), crArgNul(), crArgNul());
	  if (verTDS) mostrarTDS();
  }
  ;

secuenciaSentencias : sentencia | secuenciaSentencias sentencia;
sentencia : declaracion | instruccion;

declaracion : tipoSimple ID_ PUNTOYCOMA_

{
    if (!insertarTDS($2, $1, dvar, -1))
    yyerror("Identificador repetido");
    else
    dvar += TALLA_TIPO_SIMPLE;
}

| tipoSimple ID_ CORCHETEA_ CTE_ CORCHETEC_ PUNTOYCOMA_

{
    int numelem = $4;
    int refe;
    if (numelem <= 0)
    {
    yyerror("Talla inapropiada del array");
    numelem = 0;
    }
    refe = insertaTDArray($1, numelem);
    if (!insertarTDS($2, T_ARRAY, dvar, refe))
    yyerror("Identificador repetido");
    else
    dvar += numelem * TALLA_TIPO_SIMPLE;
}

| STRUCT_ LLAVEA_ listaCampos LLAVEC_ ID_ PUNTOYCOMA_
{
    if (!insertarTDS($5, T_RECORD, dvar, $3.referencia))
    yyerror("Identificador repetido");
    else
    dvar += $3.talla;
};

tipoSimple : INT_ { $$ = T_ENTERO; }
| BOOL_ { $$ = T_LOGICO; };

listaCampos : tipoSimple ID_ PUNTOYCOMA_
{
    $$.referencia = insertaCampo(-1, $2, $1, 0);
    $$.talla = TALLA_TIPO_SIMPLE;
}
| listaCampos tipoSimple ID_ PUNTOYCOMA_
{
    int ref = insertaCampo($1.referencia, $3, $2, $1.talla);
    if (ref!=-1){
        $$.referencia = ref;
        $$.talla = $1.talla + TALLA_TIPO_SIMPLE;
    }
   else
        yyerror("Identificador repetido");

};
instruccion : LLAVEA_ listaInstrucciones LLAVEC_ |
          instruccionAsignacion |
          instruccionEntradaSalida |
          instruccionSeleccion |
          instruccionIteracion;

listaInstrucciones : | listaInstrucciones instruccion;

instruccionAsignacion : ID_ ASIG_ expresion PUNTOYCOMA_
  {

      if ($3.tipo != T_ERROR){
          SIMB sim = obtenerTDS($1);
          if (sim.tipo == T_ERROR)
              yyerror("Identificador no declarado (instruccionAsignacion)");
          else if (!(sim.tipo == $3.tipo == T_ENTERO || sim.tipo == $3.tipo == T_LOGICO)){
               yyerror("Tipo erroneo");
                  /*debo poner algo a error?*/
          }
               /*================ GCI ==========================*/
               $$ = sim.desp;
              emite(EASIG, crArgPos($3.pos), crArgNul(), crArgPos($$));
              if ($3.postincr){
                emite($3.postincr-1, crArgPos($3.pos), crArgEnt(1), crArgPos($3.pos));
              }
      }
  }

| ID_ CORCHETEA_ expresion CORCHETEC_ ASIG_ expresion PUNTOYCOMA_
{
    /*Para no arrastrar los errores*/
    if (!($3.tipo == T_ERROR || $6.tipo == T_ERROR)){
        SIMB sim = obtenerTDS($1);
        if (sim.tipo == T_ERROR)
            yyerror("Identificador no declarado (Array)");
            /*la primera expresion debe ser entera, y la segunda es como
            si se tratara de la asignacion simple de antes*/
        else{
            if ($3.tipo != T_ENTERO)
                yyerror("El indice del array debe ser un entero");
            if(sim.ref != -1){
                DIM dim = obtenerInfoArray(sim.ref);
                if (dim.telem != $6.tipo)
                    yyerror("El tipo de la expresion no coincide con el tipo del array");
            }else{
                yyerror("La variable no es un array.");
            }
        }
        int calc = creaVarTemp();
        emite(ESUM, crArgEnt(sim.desp), crArgPos($3.pos), crArgPos(calc)); /*calcule desp array*/
        emite(EVA, crArgPos(sim.desp), crArgPos(calc), crArgPos($6.pos)); /*guarde en desp array la expr segona*/
        if ($6.postincr){
          emite($6.postincr-1, crArgPos($6.pos), crArgEnt(1), crArgPos($6.pos));
        }
    }else{
        /*$$.tipo = T_ERROR;*/
    }
}
| ID_ PUNTO_ ID_ ASIG_ expresion PUNTOYCOMA_
{

    /*ACI NECESSITE EL BUSCAR CAMPO*/
    /*Para no arrastrar los errores*/
    if ($5.tipo != T_ERROR){
        SIMB sim = obtenerTDS($1);
        if (sim.tipo == T_ERROR)
            yyerror("Identificador no declarado (Struct)");
        /*referencia del registro, nombre del campo*/
        else{
            REG reg = obtenerInfoCampo(sim.ref, $3);
            if (reg.tipo == T_ERROR)
                yyerror("Campo de registro no declarado");
            else if (reg.tipo != $5.tipo)
                yyerror("Los tipos del campo y la expresion no coinciden");

                /* =================  GCI =================================*/
                int posTemp = sim.desp + reg.desp ;
                emite(EASIG, crArgPos($5.pos), crArgNul(), crArgPos(posTemp));
                if ($5.postincr){
                  emite($5.postincr-1, crArgPos($5.pos), crArgEnt(1), crArgPos($5.pos));
                }
            }/*else*/


    } /*if grande para no arrastrar errores*/
} /*bloque*/
;

instruccionEntradaSalida : READ_ PARENTESISA_ ID_ PARENTESISC_ PUNTOYCOMA_{
                   SIMB sim = obtenerTDS($3);
                   if(sim.tipo != T_ENTERO){
                       yyerror("La variable debe ser entera.");
                   }
                   emite(EREAD, crArgNul(), crArgNul(), crArgPos(sim.desp));
               } |
               PRINT_ PARENTESISA_ expresion PARENTESISC_ PUNTOYCOMA_
              {
                  if ($3.tipo != T_ERROR) {
                      if ($3.tipo != T_ENTERO)
                        yyerror("La instruccion print necesita un entero");
                      emite(EWRITE, crArgNul(), crArgNul(), crArgPos($3.pos));
                      if ($3.postincr){
                        emite($3.postincr-1, crArgPos($3.pos), crArgEnt(1), crArgPos($3.pos));
                      }
                  }

              };
/*hemos separado la instruccion por el GCI*/
instruccionSeleccion : IF_ PARENTESISA_ expresion PARENTESISC_
{
    if ($3.tipo != T_ERROR)
        if ($3.tipo != T_LOGICO)
            yyerror("La expresion debe ser de tipo logico");
    $<aux>$ = creaLans(si);
    emite(EIGUAL, crArgPos($3.pos), crArgEnt(0), crArgNul());
 }
    instruccion
    {
        /*$$.fin = creaLans(si);*/
        $<aux>$ = creaLans(si);
        emite(GOTOS, crArgNul(), crArgNul(), crArgNul()); /* tercer argumento no sabemos*/
        /*completaLans($$.si, si);*/
        completaLans($<aux>5, crArgEnt(si));
    }
    ELSE_ instruccion
    {
      /*  completaLans($$.fin, si);*/
      completaLans($<aux>7, crArgEnt(si));
    };

/*GCI*/
instruccionIteracion : FOR_ PARENTESISA_ expresionOpcional PUNTOYCOMA_
{
    /*$$.ini = si;*/
    $<aux>$ = si;
}
 expresion PUNTOYCOMA_
{

    if ($6.tipo != T_LOGICO) {
        yyerror(" La condicion del FOR no es un T_LOGICO");
    }
    else if ($3.tipo == T_ERROR || $6.tipo == T_ERROR) {
        /* No sabemos lo que hay que poner  cuando es T_ERROR */
        yyerror("Argumentos 1 y/o 3 de tipo error.");
    }
    $<bucl>$.lv = creaLans(si);
    emite(EIGUAL, crArgPos($6.pos), crArgEnt(1), crArgNul());
    $<bucl>$.si = creaLans(si);
    emite(GOTOS, crArgNul(), crArgNul(), crArgNul());
    $<bucl>$.aux = si;

}
 expresionOpcional PARENTESISC_
    {
        /*emite(GOTOS, crArgNul(), crArgNul(), crArgEtq($$.ini));*/
        /*completaLans($$.lv, si);*/
        emite(GOTOS, crArgNul(), crArgNul(), crArgEtq($<aux>5));
        completaLans($<bucl>8.lv, crArgEnt(si));
    }
 instruccion
     {
        /*emite(GOTOS, crArgNul(), crArgNul(), crArgEtq($$.aux));
        completaLans($$.si, si);*/
        emite(GOTOS, crArgNul(), crArgNul(), crArgEtq($<bucl>8.aux));
        completaLans($<bucl>8.si, crArgEnt(si));
    }
    
| WHILE_ PARENTESISA_ 
{
    $<aux>$ = si;
}
expresion PARENTESISC_
{
    if ($4.tipo != T_LOGICO) {
        yyerror(" La condicion del WHILE no es un T_LOGICO");
    }
    $<bucl>$.lv = creaLans(si);
    emite(EIGUAL, crArgPos($4.pos), crArgEnt(0), crArgNul());
}
instruccion
{
    emite(GOTOS, crArgNul(), crArgNul(), crArgEtq($<aux>3));
    completaLans($<bucl>6.lv, crArgEnt(si));
}


| DO_ 
{
    $<aux>$ = si;
}
instruccion WHILE_ PARENTESISA_ expresion PARENTESISC_ PUNTOYCOMA_
{
    emite(EIGUAL, crArgPos($6.pos), crArgEnt(1), crArgEtq($<aux>2));
}

    
;

expresionOpcional : expresion
{
    $$.tipo = $1.tipo;
    $$.pos = $1.pos;
    if ($1.postincr){
      emite($1.postincr-1, crArgPos($1.pos), crArgEnt(1), crArgPos($1.pos));
    }

}
| ID_ ASIG_ expresion
{
    if ($3.tipo != T_ERROR){
        SIMB sim = obtenerTDS($1);
        if (sim.tipo == T_ERROR || sim.tipo != $3.tipo){
            $$.tipo = T_ERROR;
            yyerror("Identificador no declarado o de tipo incorrector");
        }else{

            emite(EASIG, crArgPos($3.pos), crArgNul(), crArgPos(sim.desp));
            $$.tipo = sim.tipo;
            $$.pos = sim.desp;
            if ($3.postincr){
              emite($3.postincr-1, crArgPos($3.pos), crArgEnt(1), crArgPos($3.pos));
            }
        }
    } /*fin if arrastrar error*/
}
| /* Esto es lamda */
{
    $$.tipo = T_VACIO;
}
;

expresion :     expresionIgualdad
{
    $$.tipo = $1.tipo;
    $$.pos = $1.pos;
    $$.postincr = $1.postincr;
}
| expresion operadorLogico expresionIgualdad
{
    if ($1.tipo == T_ERROR || $3.tipo == T_ERROR) {
        $$.tipo = T_ERROR;
    }else
        $$.tipo = $3.tipo;
        /*=========== GCI =====================*/
        $$.postincr = $3.postincr;
        if ($2 == 0){ /*AND*/
            $$.pos = creaVarTemp();
            emite(EASIG, crArgEnt(0), crArgNul(), crArgPos($$.pos));
            emite(EIGUAL, crArgPos($1.pos), crArgEnt(0), crArgEtq(si + 3));
            emite(EIGUAL, crArgPos($3.pos), crArgEnt(0), crArgEtq(si + 2));
            emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
        }else{ /*OR*/
            $$.pos = creaVarTemp();
            emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
            emite(EIGUAL, crArgPos($1.pos), crArgEnt(1), crArgEtq(si + 3));
            emite(EIGUAL, crArgPos($3.pos), crArgEnt(1), crArgEtq(si + 2));
            emite(EASIG, crArgEnt(0), crArgNul(), crArgPos($$.pos));
            }
}
;

expresionIgualdad : expresionRelacional
{
    $$.tipo = $1.tipo;
    $$.pos = $1.pos;
    $$.postincr = $1.postincr;
}
| expresionIgualdad operadorIgualdad expresionRelacional
{
    if ($1.tipo == T_ERROR || $3.tipo == T_ERROR)
    {
    $$.tipo = T_ERROR;

    }
    else{
      if($1.tipo == $3.tipo){
          $$.tipo = T_LOGICO;
          /*GCI Vicent*/
          $$.pos = creaVarTemp();
          $$.postincr = $3.postincr;
          emite($2, crArgPos($1.pos), crArgPos($3.pos), crArgEtq(si+3));
          emite(EASIG, crArgEnt(0), crArgNul(), crArgPos($$.pos));
          emite(GOTOS, crArgNul(), crArgNul(), crArgEtq(si+2));
          emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
        }
    else{
        /*debug
        char str[15];
        sprintf(str, "%d", $1.tipo);
        yyerror(str);
        */
        $$.tipo = T_ERROR;
        yyerror("Tipos diferentes (IGUAL).");
      }
    }

}
;

expresionRelacional : expresionAditiva
{
    $$.tipo = $1.tipo;
    /*GCI VICENT*/
    $$.pos = $1.pos;
    $$.postincr = $1.postincr;
}
| expresionRelacional operadorRelacional expresionAditiva
{
    if ($1.tipo == T_ERROR || $3.tipo == T_ERROR){
      $$.tipo = T_ERROR;
    }
    else{
        if($1.tipo == $3.tipo){
            $$.tipo = T_LOGICO;
            /*============= GCI =============================*/
            $$.pos = creaVarTemp();
            $$.postincr = $3.postincr;
            emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
            emite($2, crArgPos($1.pos), crArgPos($3.pos), crArgEtq(si + 2));
            emite(EASIG, crArgEnt(0), crArgNul(), crArgPos($$.pos));
        }else{
            $$.tipo = T_ERROR;
            yyerror("Tipos diferentes (REL)");
         }

    }
}
;
expresionAditiva : expresionMultiplicativa
{
    $$.tipo = $1.tipo;
    $$.pos = $1.pos;
    $$.postincr = $1.postincr;
}
| expresionAditiva operadorAditivo expresionMultiplicativa
{

    if ($1.tipo == T_ERROR || $3.tipo == T_ERROR){
      $$.tipo = T_ERROR;
    }
    else{
      $$.tipo = $3.tipo;
      $$.pos = creaVarTemp();
      $$.postincr = $3.postincr;
      emite($2, crArgPos($1.pos), crArgPos($3.pos), crArgPos($$.pos));
    }
};

expresionMultiplicativa : expresionUnaria
{
    $$.tipo = $1.tipo;
    /*GCI VICENT*/
    $$.pos = $1.pos;
    $$.postincr = $1.postincr;
}
| expresionMultiplicativa operadorMultiplicativo expresionUnaria
{
    if ($1.tipo == T_ERROR || $3.tipo == T_ERROR) {
      $$.tipo = T_ERROR;
    }
    else{
      if ($3.tipo != T_ENTERO){
        yyerror("Expresion no entera");
        $$.tipo = T_ERROR;
      }
      else  {
        $$.tipo = T_ENTERO;
        $$.pos = creaVarTemp();
        $$.postincr = $3.postincr;
        emite($2, crArgPos($1.pos), crArgPos($3.pos), crArgPos($$.pos));
      }
    }
};

expresionUnaria : expresionSufija
{
    $$.tipo = $1.tipo;
    /*GCI VICENT*/
    $$.pos = $1.pos;
    $$.postincr = $1.postincr;
}
| operadorUnario expresionUnaria
{
    if ($2.tipo == T_ERROR){
      $$.tipo = T_ERROR;
    }
    else{
      if ($1.tipo == ESUM || $1.tipo == ESIG){
          if($2.tipo != T_ENTERO){
                      yyerror("Error de tipo");
                      $$.tipo = T_ERROR;
              }
              /* GCI -> -E */
              $$.tipo = $2.tipo; /*T_ENTERO*/
              if($1.tipo == ESIG){
                  $$.pos = creaVarTemp();
                  /**/
                  emite($1.tipo ,crArgPos($2.pos),  crArgNul(), crArgPos($$.pos));
                  }
          }else{
                  if($2.tipo != T_LOGICO){
                       yyerror("Error de tipo");
                      $$.tipo = T_ERROR;
                  }
                  /* GCI -> NOT*/
                  $$.tipo = T_LOGICO;
                  $$.pos = creaVarTemp();
                  $$.postincr = $2.postincr;
                  emite(ESUM,crArgPos($2.pos), crArgEnt(1), crArgPos($$.pos));  /* $$ = $2 + 1 */
                  emite(RESTO,crArgPos($$.pos), crArgEnt(2), crArgPos($$.pos)); /* $$ = $$ % 2 */
          }
    }
}
| operadorIncremento ID_
{
    SIMB sim = obtenerTDS($2);
    if (sim.tipo == T_ERROR)
    {
        $$.tipo = T_ERROR;
    }
    else
    {
        if (sim.tipo != T_ENTERO)
        {
            yyerror("Expresion no entera");
            $$.tipo = T_ERROR;
        }
        $$.tipo = T_ENTERO;
        /* GCI  ++ y -- */
        $$.pos = sim.desp;
        emite($1, crArgPos(sim.desp), crArgEnt(1), crArgPos($$.pos));
    }
};

expresionSufija :
ID_
    {
        SIMB sim = obtenerTDS($1);
        $$.tipo = sim.tipo;
        if (sim.tipo == T_ERROR){
            yyerror("Identificador no declarado (SUFIJA-ID)");
        }
        /*========== CGI ======================*/
        $$.pos = sim.desp;
        $$.postincr = 0;
        emite(EASIG, crArgPos(sim.desp), crArgNul(), crArgPos($$.pos)  );
    }
| ID_ CORCHETEA_ expresion CORCHETEC_
{
    if ($3.tipo != T_ERROR) {
        SIMB sim = obtenerTDS($1);
        if (!(sim.tipo != T_ERROR && sim.tipo == T_ARRAY && $3.tipo == T_ENTERO)){
            $$.tipo = T_ERROR;
            yyerror("Expresion mal formada");
        }
        else {
            DIM dim = obtenerInfoArray(sim.ref);
            $$.tipo = dim.telem;

            /*=== GCI =============================*/
            $$.pos = creaVarTemp();
            $$.postincr = 0;
            emite(ESUM, crArgEnt(sim.desp) ,  crArgPos($3.pos) , crArgPos($$.pos));
            emite(EAV, crArgEnt(sim.desp), crArgPos($$.pos), crArgPos($$.pos));
        }
    }

}
| ID_ PUNTO_ ID_
{
    SIMB sim = obtenerTDS($1);
    if (sim.tipo == T_ERROR){
        $$.tipo = T_ERROR;
        yyerror("Expresion mal formada");
    }else if(sim.ref == -1)
        yyerror("La variable no es un struct.");
    else{
        REG reg = obtenerInfoCampo(sim.ref, $3); /*como comprobar?*/
        if (reg.tipo == T_ERROR){
            $$.tipo = T_ERROR;
            yyerror("Campo inexistente");
        }else{
            $$.tipo = reg.tipo;
            /*==== GCI ============================*/
            int posTemp = sim.desp + reg.desp ;
            $$.pos = posTemp;
            $$.postincr = 0;
            emite(EASIG, crArgPos(posTemp), crArgNul(), crArgPos(posTemp));
        }
    }
}
| PARENTESISA_ expresion PARENTESISC_
{
    $$.tipo = $2.tipo;
     /*================ GCI ==========================*/
    $$.pos = $2.pos;
    $$.postincr = 0;
}
| ID_ operadorIncremento
{

    SIMB sim = obtenerTDS($1);
    /*si no es entero error*/
    if (sim.tipo != T_ENTERO || sim.tipo == T_ERROR){
        $$.tipo = T_ERROR;
        yyerror("Varible no declerada o de tipo erroneo");
    }else{
        $$.tipo = T_ENTERO;
        /*==== GCI ==============================================*/
        $$.pos = sim.desp;
        $$.postincr = $2+1;
        /*emite($2, crArgPos(sim.desp), crArgEnt(1), crArgPos(sim.desp));*/
    }
}
| CTE_
{
    $$.tipo = T_ENTERO;
    /*========== CGI ======================*/
    $$.pos = creaVarTemp();
    $$.postincr = 0;
    /*CTE.cent  -->  $1 */
    emite(EASIG, crArgEnt($1), crArgNul(), crArgPos($$.pos));
}

| TRUE_
{
    $$.tipo = T_LOGICO;
    /*=========== CGI =====================*/
    $$.pos = creaVarTemp();
    $$.postincr = 0;
    emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
}
| FALSE_
{
    $$.tipo = T_LOGICO;
    /*===========GCI ===========*/
    $$.pos = creaVarTemp();
    $$.postincr = 0;
    emite(EASIG, crArgEnt(0), crArgNul(), crArgPos($$.pos));
}
;

operadorLogico :
                AND_
                {
                    $$ = 0;
                }

                | OR_
                {
                    $$ = 1;
                }
                ;

operadorIgualdad :
                IGUAL_
                    { $$ = EIGUAL; }
                | DESIGUAL_
                    { $$ = EDIST; }
                ;

operadorRelacional :
                MAYOR_
                    { $$ = EMAY; }
                | MENOR_
                    { $$ = EMEN; }
                | MAYORIGUAL_
                    { $$ = EMAYEQ; }
                | MENORIGUAL_
                    { $$ = EMENEQ; }
                ;

operadorAditivo :
                SUMA_
                    { $$ = ESUM; }
                | RESTA_
                    { $$ = EDIF; }
                ;

operadorMultiplicativo :
                    MULT_
                        { $$ = EMULT; }
                    | DIV_
                        { $$ = EDIVI; }
                    ;

operadorUnario :
SUMA_
{
    $$.tipo = ESUM;
}
| RESTA_
{
    $$.tipo = ESIG;
}
| NO_
{
    $$.tipo = T_LOGICO;
};
operadorIncremento :
                    MASMAS_
                        { $$ = ESUM; }
                    | MENOSMENOS_
                        { $$ = EDIF; }
                    ;

%%
