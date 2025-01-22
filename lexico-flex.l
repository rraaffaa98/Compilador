%{
#include <stdio.h>
#include "parser-bison.tab.h"
%}

%option noyywrap
%%
"int" { return INT; }
"+" { return MAIS; }
"-" { return MENOS; }
"*" { return MULT; }
"/" { return DIV; }
"%" { return MOD; }
"!=" { return DIF; }
"(" { return LPAR; }
")" { return RPAR; }
"=" { return ATRIB; }
"==" { return IGUAL; }
"<" { return MENOR; }
">" { return MAIOR; }
"<=" { return MENORIGUAL; }
">=" { return MAIORIGUAL; }
"&&" { return AND; }
"||" { return OR; }
"~" { return NOT; }
"abacate" { return PEV; }
"abre_a_chave_bem" { return LCHAVE; }
"fecha_a_chave_bem" { return RCHAVE; }
"gira_a_roleta_bem" { return PRINTF; }
"ju_ju" { return IF; }
"coco_bonito" { return WHILE; }
"doutor_penico" { return FOR; }
"ta_se_alimentando_bem" { return SCANF; }
"lara" { return ELSE; }
"[" {return LCOL; }
"]" {return RCOL; } 




[0-9]+ {
    yylval.int_val = atoi(yytext);
    return NUM;
}

\"([^\\\"]|\\.)*\"  {
    yylval.str_val = strdup(yytext); // obs: nao use direto yytext!
    return STRING;
}


[a-zA-Z][a-zA-Z0-9_]* {
    yylval.str_val = strdup(yytext); // obs: nao use direto yytext!
    return ID;
}


"?"[^"\n]* {} //ignora comentario


" " {}
"\n" {}
. {printf("erro lexico %s não identificado", yytext);} 
%%
