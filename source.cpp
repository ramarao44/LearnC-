/* source.cpp*/
#include<iostream>
#include"grade.h"

grade::grade()
{
    cout<<"In default constructor\n";
}

grade::~grade()
{
 
    cout<<"In default destructor\n";

}
grade::student grade::AddStudent(const string name, const unsigned int rollno)
{
    cout<<"Addstudent\n";
    this->studentarray[grade::TotalNoOfStudents].studentname=name;
    this->studentarray[grade::TotalNoOfStudents].studentrollno=rollno;
    grade::TotalNoOfStudents++;  
   
  return this->studentarray[grade::TotalNoOfStudents];
  
}
grade::student grade::DeleteStudent(const unsigned int rollno)
{
   grade::student s;
       cout<<"DeleteStudent\n";
   return s;

}
void grade::DisplayStudents()
{
  cout<<"In Display Student\n";
  
  cout<<"Student name"<<this->studentarray[0].studentname<<"\n";
  cout<<"Student rollno"<<this->studentarray[0].studentrollno<<"\n";

}	

