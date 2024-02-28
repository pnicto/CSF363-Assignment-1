%{
#include <stdio.h>
%}

%%
.* { printf("Matched: %s\n", yytext); }
%%

int main() {
  // TODO: Probably error handling for file opening
  FILE* inputFile = fopen("input.txt","r");
  FILE* outputFile = fopen("output.txt","w");
  yyin = fopen("data.txt", "r");
  yylex();

  return 0;
}