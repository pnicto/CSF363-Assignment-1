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
int currentStudentIndex = -1;

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

%%
"//".* { nComments++; }
.|\n
%%

void createNewStudentRecord(char *studID) {
  currentStudentIndex++;
  strcpy(studentRecords[currentStudentIndex].studID, studID);
  studentRecords[currentStudentIndex].courseCount = 0;
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

  fprintf(outputFile, "@%d", nComments);

  return 0;
}