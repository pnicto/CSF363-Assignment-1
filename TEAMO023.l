%{
#include <stdio.h>
#include <string.h>

struct CourseInfo {
  char courseID[31];
  int units;
  // we'll just store the numeric grade value directly
  int gradeVal;
};

struct StudentRecord {
  char studID[31];
  int courseCount;
  struct CourseInfo courses[30];
};

int nComments = 0;
struct StudentRecord studentRecords[1000];
// index of record we're currently editing
int maxStudentIndex = -1;
int currentStudentIndex = -1;

int validRecords = 0;

// to hold the course record while it is being created
struct CourseInfo currentCourse;

// called when we see a new valid student ID after a $
void createNewStudentRecord(char *studID);
// called when we see a valid courseID after a <
void createNewCourse(char *courseID);
void setCourseUnits(int units);
void setCourseGrade(char *grade);
void saveCourse();
%}

%x STUDENT STUDENT_ID COURSE COURSE_SPACE UNIT UNIT_SPACE GRADE VALID

%%
 /* ignore comments in ALL states */
<*>"//".* { nComments++; }
  /* Enter STUDENT_ID state once you find $ */
<INITIAL,STUDENT>"$"" "* { BEGIN STUDENT_ID; }
  /* Enter STUDENT state once you find valid student id */
<STUDENT_ID>[A-Z]+[0-9]+ { createNewStudentRecord(yytext); BEGIN STUDENT; }
  /* once in STUDENT state look for valid course */
<STUDENT>" "*"<"" "* { BEGIN COURSE; }
  /* once in COURSE state look for valid course */
<COURSE>[A-Z]+[0-9]+ { createNewCourse(yytext); BEGIN COURSE_SPACE; }
  /* make sure there's at least one space after the course ID */
<COURSE_SPACE>" "+ { BEGIN UNIT; }
  /* once in UNIT state look for valid unit */
<UNIT>[2-4] { setCourseUnits(atoi(yytext)); BEGIN UNIT_SPACE; }
  /* make sure there's at least one space after the number of units */
<UNIT_SPACE>" "+ { BEGIN GRADE; }
  /* once in GRADE state look for valid GRADE */
<GRADE>A|A\-|B|B\-|C { setCourseGrade(yytext); BEGIN VALID; }
  /* once we see a valid grade we move to a state indicating that all 3 values are present in the tuple */
<VALID>" "*">"" "* {
  // if we reach here that means we have seen one valid course tuple
  saveCourse();
  BEGIN STUDENT;
  }
  /* if we are in initial state, ignore everything besides $ */
<INITIAL>.|\n {}
  /* if we are in student state, ignore everything besides $, < and newline */
<STUDENT>. {}
  /* if we are in student state, newline means the current student record has ended */
<STUDENT>\n { BEGIN INITIAL; }
  /* ignore space in these states else */
<STUDENT,COURSE,UNIT,GRADE,VALID>" "
  /* in these states, any invalid character means the record is invalid */
<COURSE,COURSE_SPACE,UNIT,UNIT_SPACE,GRADE,VALID>. { BEGIN STUDENT; }
  /* a newline in these states means the record is invalid, and the current student record has ended */
<COURSE,COURSE_SPACE,UNIT,UNIT_SPACE,GRADE,VALID>\n { BEGIN INITIAL; }
  /* if the student ID was invalid or the line ended, we look for the next record */
<STUDENT_ID>.|\n { BEGIN INITIAL; }
%%

void createNewStudentRecord(char *studID) {
  int flag = 0;
  validRecords++;
  for(int i = 0; i < maxStudentIndex; i++) {
    if(strcmp(studentRecords[i].studID, studID) == 0) {
      currentStudentIndex = i;
      flag = 1;
      break;
    }
  }
  if(!flag) {
    maxStudentIndex++;
    currentStudentIndex = maxStudentIndex;
    strcpy(studentRecords[currentStudentIndex].studID, studID);
    studentRecords[currentStudentIndex].courseCount = 0;
  }
}

void createNewCourse(char *courseID) {
  strcpy(currentCourse.courseID, courseID);
}

void setCourseUnits(int units) { currentCourse.units = units; }

void setCourseGrade(char *grade) {
  int gradeVal;
  char gradeLetter = grade[0];

  switch (gradeLetter) {
  case 'A':
    if (strlen(grade) == 1) {
      gradeVal = 10;
    } else {
      gradeVal = 8;
    }
    break;
  case 'B':
    if (strlen(grade) == 1) {
      gradeVal = 6;
    } else {
      gradeVal = 4;
    }
    break;

  default:
    gradeVal = 2;
    break;
  }

  currentCourse.gradeVal = gradeVal;
}

void saveCourse() {
  int courseIndex = 0;
  // first check if a course with this name already exists
  for (courseIndex = 0;
       courseIndex < studentRecords[currentStudentIndex].courseCount;
       courseIndex++) {
    if (strcmp(
            studentRecords[currentStudentIndex].courses[courseIndex].courseID,
            currentCourse.courseID) == 0) {
      break;
    }
  }

  strcpy(studentRecords[currentStudentIndex].courses[courseIndex].courseID,
         currentCourse.courseID);
  studentRecords[currentStudentIndex].courses[courseIndex].units =
      currentCourse.units;
  studentRecords[currentStudentIndex].courses[courseIndex].gradeVal =
      currentCourse.gradeVal;

  if (courseIndex == studentRecords[currentStudentIndex].courseCount) {
    studentRecords[currentStudentIndex].courseCount++;
  }
}

int main() {
  // TODO: Probably error handling for file opening
  FILE *inputFile = fopen("input.txt", "r");
  FILE *outputFile = fopen("output.txt", "w");
  yyin = fopen("data.txt", "r");
  yylex();

  // fprintf(outputFile, "@%d", nComments);

  printf("Number of students: %d\n", maxStudentIndex + 1);
  for (int i = 0; i < maxStudentIndex + 1; i++) {
    printf("\nStudentID: %s\n", studentRecords[i].studID);
    for (int j = 0; j < studentRecords[i].courseCount; j++) {
      printf("CourseID: %s\nUnits: %d\nGrade: %d\n\n",
             studentRecords[i].courses[j].courseID,
             studentRecords[i].courses[j].units,
             studentRecords[i].courses[j].gradeVal);
    }
  }

  char line[31];
  fgets(line, 31, inputFile);
  for(int i = 0; i < maxStudentIndex + 1; i++) {
    if(strcmp(line, studentRecords[i].studID) == 0) {
      int totalUnits = 0, totalGradeVal = 0, totalGrade;

      for(int j = 0; j < studentRecords[i].courseCount; j++) {
        totalUnits += studentRecords[i].courses[j].units;
        totalGradeVal += studentRecords[i].courses[j].gradeVal;
      }
      totalGradeVal *= 100;
      totalGrade = totalGradeVal / totalUnits;

      printf("Student ID output: %s\n", studentRecords[i].studID);
      printf("Total Units: %d\nTotal Grade Value: %d\nTotal Grade: %d\n",
         totalUnits,
         totalGradeVal,
         totalGrade);

      // Currently displaying maxStudentIndex and not validRecords, update this after clarification
      fprintf(outputFile, "@%d@%d@%d@%d#",
         maxStudentIndex + 1,
         nComments,
         studentRecords[i].courseCount,
         totalGrade);
      break;
    }
  }

  fclose(inputFile);
  fclose(outputFile);

  return 0;
}