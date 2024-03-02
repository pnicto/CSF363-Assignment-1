%{
#include <stdio.h>
int nComments = 0;
%}

%x STUDENT COURSE UNIT GRADE VALID

%%
"//".* { nComments++; }
  /* Enter STUDENT state once you find valid student id */
"$"" "*[A-Z]+[0-9]+ { printf("StudentID: %s ", yytext); BEGIN STUDENT; }
  /* once in STUDENT state look for valid course */
<STUDENT>"<" { BEGIN COURSE; }
  /* once in COURSE state look for valid course */
<COURSE>[A-Z]+[0-9]+ { printf("Course: %s ", yytext); BEGIN UNIT; }
  /* once in UNIT state look for valid unit */
<UNIT>[2-4] { printf("Unit: %s ", yytext); BEGIN GRADE; }
  /* once in GRADE state look for valid GRADE */
<GRADE>[A|A-|B|B-|C] { printf("Grade: %s\n", yytext); BEGIN VALID; }
  /* once we see a valid grade we move to a state indicating that all 3 values are present in the tuple */
<VALID>">" {
  // if we reach here that means we have seen one valid course tuple
    BEGIN STUDENT;
  }
  /* if we are in a valid state */
<VALID>\n {}
  /* ignore space in these states else */
<STUDENT,COURSE,UNIT,GRADE,VALID>" "
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