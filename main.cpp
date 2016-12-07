/* Main.cpp*/
#include<iostream>
#include"grade.h"

/* To use static member of the class in the class member functions,
it should be defined before main function otherwise system throws 
undefined reference error*/
unsigned int grade::TotalNoOfStudents;

int main()
{
  grade s1;

  cout<<"Main\n";
  
  s1.AddStudent("Rama",1);
  s1.DeleteStudent(2);
  s1.DisplayStudents();
  


}

