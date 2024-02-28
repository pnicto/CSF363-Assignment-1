%{
#include <stdio.h>
%}

%%
.* { printf("Matched: %s\n", yytext); }
%%

int main() {
  // TODO: Probably error handling for file opening
  FILE* inputFile = fopen("input.txt","r");
  yyin = fopen("data.txt", "r");
  // TODO: Output file with the final result
  yylex();

  return 0;
}