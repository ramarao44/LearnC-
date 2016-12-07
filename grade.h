/*****************************************/
/* The object of writing this code is to 
  practice all the cpp concepts at one place from class to templates*/
/*****************************************/


#ifndef __GRADE_H__
#define __GRADE_H_
#include<iostream>
#define MAX_NO_OF_STUDENTS 100

using namespace std;
class grade
{
  
  
     
   public:
     struct student
     {
        string studentname;
        unsigned int studentrollno;
     };
     student studentarray[MAX_NO_OF_STUDENTS];

      grade();
      static unsigned int TotalNoOfStudents;
      struct student AddStudent(const string,const unsigned int);
      struct student DeleteStudent(const unsigned int);
      void DisplayStudents();
      ~grade();
};
#endif
