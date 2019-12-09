#ifndef _MACHINE_H
#define _MACHINE_H



using namespace std;

struct Instruction
{
	int mode; //0
	int operation; // 4
	int operand; // 8
	int cc;		// 12
	int fl;		// 16
	int size;	//20
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
