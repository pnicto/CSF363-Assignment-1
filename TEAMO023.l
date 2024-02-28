%{
#include <stdio.h>
int nComments = 0;
%}

%%
"//".* { nComments++; }
.|\n
%%

int main() {
  // TODO: Probably error handling for file opening
  FILE* inputFile = fopen("input.txt","r");
  FILE* outputFile = fopen("output.txt","w");
  yyin = fopen("data.txt", "r");
  yylex();

  fprintf(outputFile, "@%d", nComments);

  return 0;
}