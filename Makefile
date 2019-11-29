AS = as
CC = g++


tp6:	tp6.o machine.o
	@echo
	@echo ------------------
	@echo Edition des liens
	@echo ------------------
	@echo

	$(CC) -g tp6.o machine.o -o machine

machine.o:  machine.cc
	@echo
	@echo ------------------
	@echo Compilation du programme principal, machine.cc
	@echo ------------------
	@echo

	$(CC) -g -c machine.cc -o machine.o




tp6.o: tp6.as
	@echo
	@echo ------------------------------------------------
	@echo Compilation des fonctions pour emulation, tp6.as
	@echo ------------------------------------------------
	@echo

	$(AS)  -gstabs tp6.as -o tp6.o
