%{
#include <stdio.h>
%}

%%
.* { printf("Matched: %s\n", yytext); }
%%

int main() {
  printf("Hello, World!\n");
  yylex();
  return 0;
}