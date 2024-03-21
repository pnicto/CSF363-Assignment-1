%{
#include <stdio.h>
#include <string.h>
#include <math.h>

struct CourseInfo {
  char courseID[31];
  int units;
  // We'll just store the numeric grade value directly
  int gradeVal;
};

struct StudentRecord {
  char studID[31];
  int courseCount;
  struct CourseInfo courses[30];
};

// Student records (with a temporary placeholder)
struct StudentRecord studentRecords[1000];
struct StudentRecord temporaryStudentRecord;

// (Number of students whose records we have) - 1
int maxStudentIndex = -1;
// Holds the index of the current student record we are editing
int currentStudentIndex = -1;

int validRecords = 0;
int nComments = 0;

// Holds the course record while it is being created
struct CourseInfo currentCourse;

// Called when we see a new valid student ID after a $, or when we wish to save the record after validating
// isSaveStudentRecord indicates whether we are saving the record to the database or not
void createNewStudentRecord(char *studID, int isSaveStudentRecord);

// Called when we see a valid courseID after a <
void createNewCourse(char *courseID);

// Set course units for a course
void setCourseUnits(int units);

// Set course grade for a course
void setCourseGrade(int value);

// Save a course to a student record
// isSaveStudentRecord indicates whether the course gets saved to the temporary record or actual saved student records
void saveCourse(int isSaveStudentRecord);

// Validate the current temporary record and save it to studentRecords if it is valid
void saveStudentRecord();
%}

%x STUDENT STUDENT_ID COURSE COURSE_SPACE UNIT UNIT_SPACE GRADE VALID

%%
 /* Ignore comments in ALL states */
<*>"//".* { nComments++; }
  /* Enter STUDENT_ID state once you find $ */
<INITIAL,STUDENT_ID>"$"" "* { BEGIN STUDENT_ID; }
  /* If we were already in STUDENT state, then save the student record before resetting*/
<STUDENT>"$"" "* { saveStudentRecord(); BEGIN STUDENT_ID; }
  /* Enter STUDENT state once you find valid student id
  We initialize the temporary student record with obtanied student id */
<STUDENT_ID>[A-Z]+[0-9]+ { createNewStudentRecord(yytext, 0); BEGIN STUDENT; }
  /* Once in STUDENT state look for valid course */
<STUDENT>" "*"<"" "* { BEGIN COURSE; }
  /* Once in COURSE state look for valid course */
<COURSE>[A-Z]+[0-9]+ { createNewCourse(yytext); BEGIN COURSE_SPACE; }
  /* Make sure there's at least one space after the course ID */
<COURSE_SPACE>" "+ { BEGIN UNIT; }
  /* Once in UNIT state look for valid unit */
<UNIT>[2-4] { setCourseUnits(atoi(yytext)); BEGIN UNIT_SPACE; }
  /* Make sure there's at least one space after the number of units */
<UNIT_SPACE>" "+ { BEGIN GRADE; }
  /* Once in GRADE state look for valid GRADE */
<GRADE>A { setCourseGrade(10); BEGIN VALID; }
<GRADE>A\- { setCourseGrade(8); BEGIN VALID; }
<GRADE>B { setCourseGrade(6); BEGIN VALID; }
<GRADE>B\- { setCourseGrade(4); BEGIN VALID; }
<GRADE>C { setCourseGrade(2); BEGIN VALID; }
  /* Once we see a valid grade we move to a state indicating that all 3 values are present in the tuple */
<VALID>" "*">"" "* {
  /* If we reach here that means we have seen one valid course tuple
  We save the course tuple to the temporary student record */
  saveCourse(0);
  BEGIN STUDENT;
  }
  /* If we are in initial state, ignore everything besides $ */
<INITIAL>.|\n {}
  /* If we are in student state, ignore everything besides $, < and newline */
<STUDENT>. {}
  /* If we are in student state, newline means the current student record has ended
  Validate the temporary student record and save it to studentRecords if it is valid */
<STUDENT>\n { saveStudentRecord(); BEGIN INITIAL; }
  /* Ignore space in these states else */
<STUDENT,COURSE,UNIT,GRADE,VALID>" "
  /* In these states, any invalid character means the record is invalid */
<COURSE,COURSE_SPACE,UNIT,UNIT_SPACE,GRADE,VALID>. { BEGIN STUDENT; }
  /* A newline in these states means the record is invalid, and the current student record has ended */
<COURSE,COURSE_SPACE,UNIT,UNIT_SPACE,GRADE,VALID>\n { BEGIN INITIAL; }
  /* If the student ID was invalid or the line ended, we look for the next record */
<STUDENT_ID>.|\n { BEGIN INITIAL; }
%%

// Initializes a new student record
// isSaveStudentRecord indicates whether the record is being saved to studentRecords or temporaryStudentRecord
void createNewStudentRecord(char *studID, int isSaveStudentRecord) {
  if (isSaveStudentRecord == 0) {
    strcpy(temporaryStudentRecord.studID, studID);
    temporaryStudentRecord.courseCount = 0;
  } else {
    // First check if a student with this student id already exists
    int flag = 0;
    for (int i = 0; i < maxStudentIndex + 1; i++) {
      if (strcmp(studentRecords[i].studID, studID) == 0) {
        currentStudentIndex = i;
        flag = 1;
        break;
      }
    }
    if (!flag) {
      maxStudentIndex++;
      currentStudentIndex = maxStudentIndex;
      strcpy(studentRecords[currentStudentIndex].studID, studID);
      studentRecords[currentStudentIndex].courseCount = 0;
    }
  }
}

// Update currentCourse with a new course id to initialize a new course tuple
void createNewCourse(char *courseID) {
  strcpy(currentCourse.courseID, courseID);
}

// Set course units for the current course tuple
void setCourseUnits(int units) { currentCourse.units = units; }

// Set course grade for the current course tuple
void setCourseGrade(int value) {
  currentCourse.gradeVal = value;
}

// Save the current course tuple to a student record
// isSaveStudentRecord indicates whether the course tuple is being saved to studentRecords or temporaryStudentRecord
void saveCourse(int isSaveStudentRecord) {
  int courseIndex = 0;
  if (isSaveStudentRecord == 0) {
    // First check if a course with this name already exists
    for (courseIndex = 0;
        courseIndex < temporaryStudentRecord.courseCount;
         courseIndex++) {
      if (strcmp(
              temporaryStudentRecord.courses[courseIndex].courseID,
              currentCourse.courseID) == 0) {
        break;
      }
    }

    strcpy(temporaryStudentRecord.courses[courseIndex].courseID,
           currentCourse.courseID);
    temporaryStudentRecord.courses[courseIndex].units =
        currentCourse.units;
    temporaryStudentRecord.courses[courseIndex].gradeVal =
        currentCourse.gradeVal;

    if (courseIndex == temporaryStudentRecord.courseCount) {
      temporaryStudentRecord.courseCount++;
    }
  } else {
    // First check if a course with this name already exists
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
}

// Check for the validity of the temporary student record
// If the record is valid, then save it to studentRecords
void saveStudentRecord() {
  if (temporaryStudentRecord.courseCount > 0) {
    validRecords++;
    createNewStudentRecord(temporaryStudentRecord.studID, 1);

    for (int i = 0; i < temporaryStudentRecord.courseCount; i++) {
      strcpy(currentCourse.courseID, temporaryStudentRecord.courses[i].courseID);
      currentCourse.units = temporaryStudentRecord.courses[i].units;
      currentCourse.gradeVal = temporaryStudentRecord.courses[i].gradeVal;

      saveCourse(1);
    }
    strcpy(temporaryStudentRecord.studID, "$");
    temporaryStudentRecord.courseCount = 0;
  }
}

int main() {
  // TODO: Probably error handling for file opening
  FILE *inputFile = fopen("input.txt", "r");
  FILE *outputFile = fopen("output.txt", "w");
  yyin = fopen("data.txt", "r");
  yylex();

  if (strcmp(temporaryStudentRecord.studID, "$") != 0) {
    saveStudentRecord();
  }

  // printf("Number of students: %d\n", maxStudentIndex + 1);
  // for (int i = 0; i < maxStudentIndex + 1; i++) {
  //   printf("\nStudentID: %s\n", studentRecords[i].studID);
  //   for (int j = 0; j < studentRecords[i].courseCount; j++) {
  //     printf("CourseID: %s\nUnits: %d\nGrade: %d\n\n",
  //            studentRecords[i].courses[j].courseID,
  //            studentRecords[i].courses[j].units,
  //            studentRecords[i].courses[j].gradeVal);
  //   }
  // }

  // Search for the student record using the given student id from input file
  char line[31];
  int flag = 0;
  fgets(line, 31, inputFile);
  for (int i = 0; i < maxStudentIndex + 1; i++) {
    if (strcmp(line, studentRecords[i].studID) == 0) {
      flag = 1;
      float totalUnits = 0.0, totalGradeVal = 0.0;
      int totalGrade;

      for (int j = 0; j < studentRecords[i].courseCount; j++) {
        totalUnits += (float)studentRecords[i].courses[j].units;
        totalGradeVal += (float)((float)studentRecords[i].courses[j].gradeVal * (float)studentRecords[i].courses[j].units);
      }
      totalGrade = round((float)(totalGradeVal / totalUnits) * 100.0);

      // Terminal output (remove before final submission)
      // printf("Student ID output: %s\n", studentRecords[i].studID);
      // printf("Total Units: %f\nTotal Grade Value: %f\nTotal Grade: %d\n",
      //    totalUnits,
      //    totalGradeVal,
      //    totalGrade);

      fprintf(outputFile, "@%d@%d@%d@%d#",
         validRecords,
         nComments,
         studentRecords[i].courseCount,
         totalGrade);
      break;
    }
  }

  // No student with given student id found
  if (!flag) {
    // printf("No student found\n");
    fprintf(outputFile, "@%d@%d@0@0#",
       validRecords,
       nComments);
  }

  fclose(inputFile);
  fclose(outputFile);

  return 0;
}