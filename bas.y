%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include "sel.h"

/* prototypes */
nodeType *opr(int oper, int nops, ...);
nodeType *comm(int value);
nodeType *con(char * value);
void freeNode(nodeType *p);
int ex(nodeType *p);
int yylex(void);
void yyerror(char *s);
%}
%union {
   char Word[SIZEOFWORD] ;
   nodeType *nPtr; /* node pointer */
   };
%token <Word> WORD
%token SELECT FROM WHERE GROUPBY ORDERBY
%left AND
%token '='','
%type<nPtr> stmt expr cols tables add add2 add3 word
%%
program :
   function { exit(0); }
   ;
function :
   function stmt { ex($2); freeNode($2); }
   | /* NULL */
   ;
stmt :
   SELECT cols FROM tables add { $$ = opr(SELECT,
                                           3, $2,$4,$5) ;}
   ;
cols :
   WORD ',' cols { $$ = opr(',',2,$1,$3); }
   |WORD { $$ = con($1); }
   ;
tables :
   cols
   ;
add :
   /* NULL */ { $$ = NULL; }
   |WHERE expr add2 { $$ = opr(WHERE,2,$2,$3) ; }
   |GROUPBY cols add3 { $$ = opr(GROUPBY,2,$2,$3) ;}
   |ORDERBY cols { $$ = opr( ORDERBY,1,$2 ) ;}
   ;
add2 :
   /* NULL */ { $$ = NULL; }
   |GROUPBY cols add3  { $$ = opr(GROUPBY,2,$2,$3) ;}
   |ORDERBY cols { $$ = opr( ORDERBY,1,$2 ) ;}
   ;
add3 :
   /* NULL */ { $$ = NULL; }
   |ORDERBY cols  { $$ = opr( ORDERBY,1,$2 ) ;}
   ;
expr :
   expr AND expr { $$ = opr(AND,2,$1,$3); }
   |word '=' word { $$ = opr('=',2,$1,$3); }
   ;
word :
   WORD  { $$ = con($1); }
   ;
%%
#define SIZEOF_NODETYPE ((char*)&p->con-(char*)p)

nodeType *con(char * value){
   nodeType *p;
   size_t nodeSize;
   /* allcate node */
   nodeSize = SIZEOF_NODETYPE + sizeof(conNodeType);
   if (( p = malloc(nodeSize)) == NULL )
      yyerror("out of memory");
   /* copy information */
   p->type = typeCon;
   strcpy(p->con.value, value);
   return p;
}

nodeType *comm(int value) {
   nodeType *p;
   size_t nodeSize;
   /* allocate node */
   nodeSize = SIZEOF_NODETYPE + sizeof(commNodeType);
   if ( (p=malloc(nodeSize))==NULL )
      yyerror("out of memory");
   /* copy info */
   p->type = typeComm;
   p->comm.i = value;
   return p;
}

nodeType *opr(int oper, int nops,...) {
   va_list ap;
   nodeType *p;
   size_t nodeSize;
   int i;
   /* allocate node */
   nodeSize = SIZEOF_NODETYPE + sizeof(oprNodeType) +
              (nops - 1) * sizeof(nodeType*);
   if ((p=malloc(nodeSize))==NULL)
      yyerror("out of memory");
   /* copy info */
   p->type = typeOpr;
   p->opr.oper = oper;
   p->opr.nops = nops;
   va_start(ap,nops);
   for(i=0;i<nops;++i)
      p->opr.op[i] = va_arg(ap,nodeType*);
   va_end(ap);
   return p;
}

void freeNode(nodeType *p)
{
   int i;
   if (!p) return;
   if ( p->type == typeOpr) {
      for(i=0;i < p->opr.nops;++i)
         freeNode(p->opr.op[i]);
   }
   free(p);
}

void yyerror(char *s)
{
   fprintf(stdout,"%s\n",s);
}

void indentPrint( int i, char * s)
{
   int t;
   for(t=0;t<i;++t)
      printf("--");
   printf("%s",s);
}
int ex(nodeType *p){
   static int indent = 1;
   if(!p)return 0;
   switch(p->type) {
   case typeCon: indentPrint( indent, p->con.value );printf("\n");
   case typeOpr:
      switch(p->opr.oper){
         case SELECT: 
            indentPrint( indent, "SELECT\n" );
            ++indent ;ex(p->opr.op[0]); --indent;
            indentPrint( indent, "FROM\n" );
            ++indent ;ex(p->opr.op[1]); --indent;
            if( p->opr.op[2]!= NULL ) { ++indent; ex(p->opr.op[2]); --indent;}
            break;
         case WHERE:
            indentPrint( indent,"WHERE\n");
            ++indent ;ex(p->opr.op[0]); --indent;
            if( p->opr.op[1]!= NULL ) { ++indent; ex(p->opr.op[1]); --indent;}
            break; 
         case GROUPBY:
            indentPrint( indent,"GROUP BY\n" );
            ++indent; ex(p->opr.op[0]); --indent;
            if( p->opr.op[1]!= NULL ) { ++indent; ex(p->opr.op[1]); --indent; }
            break;
         case ORDERBY:
            indentPrint( indent,"ORDER BY\n" );
            ++indent; ex(p->opr.op[0]); --indent;
            break;
         case AND:
            indentPrint( indent,"AND\n" );
            ++indent; ex(p->opr.op[0]); ex(p->opr.op[1]); --indent;
            break;
         case ',':
            indentPrint( indent,",\n");
            ++indent; ex(p->opr.op[0]); ex(p->opr.op[1]); --indent;
            break;
         case '=':
            indentPrint( indent,"=\n");
            ++indent; ex(p->opr.op[0]); ex(p->opr.op[1]); --indent;
            break;
      }
   }
   return 0;
}

int main(void) {
   yyparse();
   return 0;
}
