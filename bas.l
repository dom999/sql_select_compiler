%{
#include <stdlib.h>
#include "sel.h"
#include "y.tab.h"
void yyerror(char *);
%}
%%

"select"|"SELECT" return SELECT;
"from"|"FROM" return FROM;
"where"|"WHERE" return WHERE;
"group by"|"GROUP BY" return GROUPBY;
"order by"|"ORDER BY" return ORDERBY;
"and"|"AND" return AND;

[a-z0-9]+ {
   strcpy( yylval.Word, yytext );
   return WORD;
}

[-=,] {
   return *yytext;
}

[ \t\n]+ ; /* ignore whitespace */

. yyerror("Unknown character");
%%
int yywrap(void)
{
   return 1;
}
