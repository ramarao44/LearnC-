all: schoolapp

#compiler name
CC=g++

#Install Directory
INSTDIRECTORY=/home/m1019840/cpp/school/install/

#Location of Header file

INCLUDE=/home/m1019840/cpp/school/

#Compiler options for development
CFLAGS=-g -Wall

schoolapp: main.o source.o
	$(CC) -o schoolapp main.o source.o
mMain.o: main.cpp grade.h
	$(CC) -I$(INCLUDE) $(CFLAGS) -c main.cpp
source.o:source.cpp grade.h
	$(CC) -I$(INCLUDE) $(CFLAGS) -c source.cpp


clean:
	-rm main.o source.o schoolapp
install:schoolapp
	@if[ -d $(INSTDIRECTORY) ];\
		then\
	cp schoolapp $(INSTDIRECTORY);\
	chmod a+x $(INSTDIRECTORY)/schoolapp;\
	chmod og-w $(INSTDIRECTORY);\
	echo "Installed in $(INSTDIRECTORY)";\
	fi
