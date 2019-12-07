#include <stdio.h>
#include "machine.h"

using namespace std;

const char formats [8][10]= {"%c","%d","%s","%f","%u","%x"};


extern "C"{

int Decode (Instruction*,MachineState*);
int EmuPush (Instruction*,MachineState*);
int EmuPop (Instruction*,MachineState*);
int EmuWrite (Instruction*,MachineState*);
int EmuRead (Instruction*,MachineState*);
int EmuAdd (Instruction*,MachineState*);
int EmuSub (Instruction*,MachineState*);
int EmuMul (Instruction*,MachineState*);
int EmuDiv (Instruction*,MachineState*);
int EmuBz (Instruction*,MachineState*);
int EmuBn (Instruction*,MachineState*);
int EmuJmp (Instruction*,MachineState*);
int EmuJmpl (Instruction*,MachineState*);
int EmuRet (Instruction*,MachineState*);

}

class	Machine
{


	private:	MachineState state;
			bool stop;



	public:		Machine()
			{
				state.PS=0;
				state.PC=0;
				state.SP=3000;
				state.memory = new unsigned char [10000];
				stop=true;
			}

			~Machine()
			{
				delete state.memory;
			}

			void run();

			void step(Instruction);

			void load(unsigned char *,int);





};



void Machine::load(unsigned char* inst,int len)
{
 for(int i=0;i<len;i++)
 {
  state.memory[i]=inst[i];
 }

}





void Machine::run()
{
 stop=false;

 printf("Machine demarree a l'adresse 0x%x\n",state.PC);
 while(!stop)
 {
  	Instruction inst;
	if (Decode(&inst,&state)!=0)
	{
		printf("Indecodable\n");
		stop=true;
		continue;
	}
	step(inst);
 }

 printf("Machine arretee a l'adresse 0x%x\n",state.PC);

}




void Machine::step(Instruction inst)
{
	printf("\nMonde: %d\nOperation: %d\nOperand: %d\nCC: %d\nFl: %d\nSize: %d\n", inst.mode, inst.operation, inst.operand, inst.cc, inst.fl, inst.size);
  printf("!!  PC=0x%x  SP=0x%x  PS=0x%x !!    ",state.PC,state.SP,state.PS);
 int res=-1;
 if(inst.mode==0)
 {
 	if(inst.operation==0)
	{
	 	stop=true;
		printf("HALT\n");
		res=0;
	}

	else if(inst.operation == 3)
	{
		printf("READ %s\n",formats[inst.operand]);
		res=EmuRead(&inst,&state);
	}

	else if(inst.operation==4)
	{


		printf("WRITE %s\n",formats[inst.operand]);
		res=EmuWrite(&inst,&state);



	}


 }

 else if (inst.mode==1 ||inst.mode==2)
 {

 	char ccString[2][4] = {"","CC"};
	char flString[2][2] = {"","F"};
 	switch (inst.operation)
	{

		case 0: printf("PUSH%s",flString[inst.fl]);
			if(inst.mode==2)
			{
				printf(" 0x%x",inst.operand);
			}
			else
			{
				if (inst.fl==0)
				{
					printf(" %d",inst.operand);
				}
				else
				{
					float temp;
					unsigned char * tempptr;
					tempptr = (unsigned char* )&temp;
					unsigned char * opptr;
					opptr = (unsigned char *) &(inst.operand);
					for (int i=0;i<4;i++)
					{
						 tempptr[i]=opptr[i];
					}
					printf(" %f",temp);
				}
			}
			printf("\n");
			res=EmuPush(&inst,&state);
			break;

		case 1: printf("POP%s 0x%x\n",flString[inst.fl],inst.operand);
			res=EmuPop(&inst,&state);
			break;

		case 2: printf("ADD%s%s\n",flString[inst.fl],ccString[inst.cc]);

			res=EmuAdd(&inst,&state);
			break;

		case 3:
			printf("SUB%s%s\n",flString[inst.fl],ccString[inst.cc]);
			res=EmuSub(&inst,&state);
			break;

		case 4:
			printf("MUL%s%s\n",flString[inst.fl],ccString[inst.cc]);
			res=EmuMul(&inst,&state);
			break;

		case 5:
			printf("DIV%s%s\n",flString[inst.fl],ccString[inst.cc]);
			res=EmuDiv(&inst,&state);
			break;

		case 13:printf("RET\n");
			res=EmuRet(&inst,&state);
			break;
		case 14:printf("JMPL\n");
			res=EmuJmpl(&inst,&state);
			break;
		case 15:printf("JMP\n");
			res=EmuJmp(&inst,&state);
			break;


	}





 }



 else if(inst.mode==3)
 {

  	if(inst.operation == 0)
	{
		printf("BZ %d\n",inst.operand);
		res = EmuBz(&inst,&state);
	}
	else if (inst.operation==1)
	{
		printf("BN %d\n",inst.operand);
		res= EmuBn(&inst,&state);
	}
 }


 if(res==1)
 {
 	stop=true;
	printf("Unimplemented Instruction\n");
 }
 else if (res==-1)
 {
 	stop=true;
	printf("Illegal Instruction\n");
 }

 else
 {
 	state.PC += inst.size;
 }

}


int main(void)
{
 printf("Custom Pile Dumper v0.4b\n");



 printf("Taille de la section de code:");

 unsigned char code[10000];
 int size=0;
 scanf ("%d",&size);

 printf("\nCode:");

 for (int i=0;i<size;i++)
 {
 	unsigned int res;
	scanf("%x",&res);
	code[i]=res&0xFF;
 }

 Machine m;

 m.load(code,size);
 m.run();


}
