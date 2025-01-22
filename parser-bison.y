%{
#include <stdio.h>


typedef struct {
    char *id;
    int end;
} simbolo;

simbolo tabsimb[1000];
int nsimbs = 0;
int endereco = 0;


int getendereco(char *id) {
    for (int i=0;i<nsimbs;i++)
        if (!strcmp(tabsimb[i].id, id))
            return tabsimb[i].end;
    return -1;
}

/* Contador global de registradores temporarios */
int T=0;
int L=0;

/*Pilha para rótulos de controle de fluxo */
typedef struct {
    int data[100]; //armazena os elementos da pilha
    int top; //aponta para o topo da pilha
} Stack;

Stack loopStack = {.top = 0}; //inicializa top em 0 (pilha vazia) 

void push(int value) { //adiciona na pilha
    if (loopStack.top < 100) { //verifica se a pilha não está cheia
        loopStack.data[loopStack.top++] = value; //armazena o valor na vilha
    } else {
        printf("Pilha cheia\n");
        exit(1);
    }
}

int pop() { 
    if (loopStack.top > 0) { //remore da pilha equanto é maior que zero
        return loopStack.data[--loopStack.top];
    } else {
        printf("Pilha vazia\n");
        exit(1);
    }
}

int top() { //retorna o valor da pilha sem remover
    if (loopStack.top > 0) {
        return loopStack.data[loopStack.top - 1];
    } else {
        printf("Pilha vazia\n");
        exit(1);
    }
}
%}

/* o union lista os tipos que o texto/valor de um token pode ter */
%union {
    char *str_val;
    int int_val;
    
}

/* indicação do tipo do texto/valor de um token, conforme o union. */
%token <str_val>ID ATRIB PEV MAIS DIV <int_val>NUM LPAR RPAR LCHAVE RCHAVE PRINTF IF WHILE FOR SCANF ELSE MAIOR MENOR IGUAL MENOS MULT AND OR NOT DIF MOD <str_val>STRING LCOL RCOL MAIORIGUAL MENORIGUAL INT 

/* define o tipo do "retorno"/"yylval" dos simbolos nao terminais.
   Aqui, os simbolos irão "retornar" um inteiro indicando em qual
   registrador temporario o resultado de sua (sub)expressao está */
%type <int_val> expr termo fator cond condTermo condFator condSimp 

/* mostra detalhes do erro de sintaxe */
%define parse.error verbose

%%

/* o código depois de um simbolo será executado quando o simbolo for
   "encontrado" na entrada (reduce) */

/* o texto/valor do primeiro simbolo da produção (neste caso, ID) é $1;
   o do segundo (ATRIB) é $2; do terceiro (expr) seria $3; do quarto (PEV) é $4,
   e assim por diante em todas as produções */

listacomando: comando listacomando | comando;

comando: atrib | printf | while | for | scanf | if | bloco | declaracao;


atrib : ID ATRIB expr PEV {printf("mov %%r%d, %%t%d\n", getendereco($1), $3);};
     | ID LCOL expr RCOL ATRIB expr PEV {   
            printf("store %%t%d, %%t%d(%d)\n", $6, $3, getendereco($1)); // Store no endereço calculado
      }     | ID MAIS MAIS PEV{
           printf("add %%r%d, %%r%d, %d\n", getendereco($1), getendereco($1), 1);
       
       };

/* note que '+' será impresso só depois das impressoes em expr e termo */
expr : expr MAIS termo {
           printf("add %%t%d, %%t%d, %%t%d\n", T, $1, $3);
           $$ = T++;
       }
     | expr MENOS termo {
           printf("sub %%t%d, %%t%d, %%t%d\n", T, $1, $3);
           $$ = T++;
       } 
     | termo { $$ = $1; };

termo : termo DIV fator {
           printf("div %%t%d, %%t%d, %%t%d\n", T, $1, $3);
           $$ = T++;
        }
      |	termo MULT fator{
           printf("mult %%t%d, %%t%d, %%t%d\n", T, $1, $3);
           $$ = T++;
        }
      |	termo MOD fator {
           printf("mod %%t%d, %%t%d, %%t%d\n", T, $1, $3);
           $$ = T++;
        }
      | fator {$$ = $1; };

fator : ID {
            /* atribui o conteudo da variavel (registrador r
               definido na tabela de simbolos) a um temporario
               e o "retorna" em $$ */
            printf("mov %%t%d, %%r%d\n",T, getendereco($1));
            $$ = T++;
        }
      | NUM {
            /* analogo */
            printf("mov %%t%d, %d\n", T, $1);
            $$ = T++;
      }
      | MENOS NUM {
            /* analogo */
            printf("mov %%t%d, %d\n", T, $1);
            $$ = T++;
      }
      | LPAR expr RPAR {
            /* o "retorno" do fator é o mesmo da expr neste caso */
          $$ = $2;
      }
      | ID LCOL expr RCOL {  printf("load %%t%d, %%t%d(%d)\n", T, $3, getendereco($1));
        $$ = T++; };
      
      

printf: PRINTF LPAR expr RPAR PEV {
            printf("printv %%t%d\n",  $3);
      }
       | PRINTF LPAR STRING RPAR PEV {
            printf("printf %s\n", $3);
      }; 



while: WHILE {
	    int start = L++; 
            int end = L++;
            printf("label L%d\n", start);
            push(start);
            push(end);}
       LPAR cond{ int end = top(); printf("jf %%t%d, L%d\n", T-1, end);}
       RPAR bloco {
           int start = pop();
           int end = pop();
           printf("jump L%d\n", end);
           printf("label L%d\n", start);
        }; 
     
	
cond: cond AND condTermo {
            printf("and %%t%d, %%t%d, %%t%d\n", T, $1, $3);
            $$ = T++;
         }
       | condTermo {
            $$ = $1;
         };

condTermo: condTermo OR condFator {
               printf("or %%t%d, %%t%d, %%t%d\n", T, $1, $3);
               $$ = T++;
           }
         | condFator {
               $$ = $1;
           };

condFator: NOT condSimp {
               printf("not %%t%d, %%t%d\n", T, $2);
               $$ = T++;
           }
         | condSimp {
               $$ = $1;
           };

condSimp: expr MENOR expr {
               printf("less %%t%d, %%t%d, %%t%d\n", T, $1, $3);
               $$ = T++;
           }
         | expr MAIOR expr {
               printf("greater %%t%d, %%t%d, %%t%d\n", T, $1, $3);
               $$ = T++;
           }
         | expr MAIORIGUAL expr {
               printf("greatereq %%t%d, %%t%d, %%t%d\n", T, $1, $3);
               $$ = T++;
           }
         | expr MENORIGUAL expr {
               printf("lesseq %%t%d, %%t%d, %%t%d\n", T, $1, $3);
               $$ = T++;
           }
         | expr DIF expr {
               printf("diff %%t%d, %%t%d, %%t%d\n", T, $1, $3);
               $$ = T++;
           }
         | expr IGUAL expr {
               printf("equal %%t%d, %%t%d, %%t%d\n", T, $1, $3);
               $$ = T++;
           }
         | LPAR cond RPAR {
               $$ = $2;
           };

	
for: FOR LPAR ID ATRIB expr{  printf("mov %%r%d, %%t%d\n", getendereco($3),$5);
} PEV {
    int start = L++;
        int end = L++;
        printf("label L%d\n", start);
        push(start);
        push(end);
} cond {  int end = top();
        printf("jf %%t%d, L%d\n", T-1, end);}
        RPAR bloco { int start = pop();
        int end = pop();
        printf("jump L%d\n", end);
        printf("label L%d\n", start);
    };

scanf: SCANF LPAR ID RPAR PEV {
			printf("read %%r%d\n", getendereco($3));
}
	   | SCANF LPAR ID LCOL expr RCOL RPAR PEV {
    printf("read %%t%d\n", T);
    printf("store %%t%d, %%t%d(%d)\n", T, $5, getendereco($3));

};
if: IF LPAR cond RPAR {
        int start = L++;
        printf("jf %%t%d, L%d\n", $3, start);
    } bloco {
        int end = L++;
        printf("jump L%d\n", end);
        printf("label L%d\n", L-2); 
        push(end);
    } else {
        int end = pop();
        printf("label L%d\n", end);
    };

else: ELSE bloco
     | ;
     
bloco: LCHAVE listacomando RCHAVE;


declaracao: INT ID PEV {
    tabsimb[nsimbs] = (simbolo){$2, endereco};
    endereco++;
    nsimbs++;
} | INT ID LCOL NUM RCOL PEV {
    tabsimb[nsimbs] = (simbolo){$2, endereco};
    endereco += $4; 
    nsimbs++;
};

%%

// extern FILE yyin;                   // () descomente para ler de um arquivo

int main(int argc, char *argv[]) {

    //yyin = fopen(argv[1], "r");       // (*)

    yyparse();

  //  fclose(yyin);                     // (*)

    return 0;
}

void yyerror(char *s) { fprintf(stderr,"ERRO: %s\n", s); }
