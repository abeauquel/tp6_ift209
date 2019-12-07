#ifndef _MACHINE_H
#define _MACHINE_H



using namespace std;

struct Instruction
{
	int mode;
	int operation;
	int operand;
	int cc;
	int fl;
	int size;
};


struct MachineState
{
 int PC; // compteur ordinal
 int SP; // Adresse de la pile
 int PS;
 int padding;
 unsigned char* memory;// Debut adresse memoire vm

};


#endif
