/********************************************************************************
*																				*
*	Ensemble de sous-programmes qui simulent le décodage et plusieurs          	*
*	instructions pour une machine à pile.										*
*															                    *
*	Auteurs: 																	*
*																				*
********************************************************************************/


.include "/root/SOURCES/ift209/tools/ift209.as"


.global Decode
.global EmuPush
.global EmuWrite
.global EmuPop
.global EmuRead
.global EmuAdd
.global EmuSub
.global EmuMul
.global EmuDiv
.global EmuBz
.global EmuBn
.global EmuJmp
.global EmuJmpl
.global EmuRet

.section ".text"

/*******************************************************************************
	Fonction qui décode une instruction.



	Paramètres
		x0: Adresse de la structure instruction (pour écrire le résultat)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x0->mode: type d'instruction
		x0->operation: champ oper (identifie l'opération spécifique)
		x0->operand: opérande (pour PUSH, POP, JMP, READ, WRITE)
		x0->cc: utilisation ou non des codes conditions
		x0->size: taille en octets de l'instruction décodée
*******************************************************************************/


Decode:
    SAVE					//Sauvegarde l'environnement de l'appelant
	mov		x19,x0
	mov		x20,x1
	ldr		w21,[x1]		//Obtention du compteur ordinal
	ldr		x22,[x1,16]		//Obtention du pointeur sur la memoire de la machine virtuelle
	ldrb	w23,[x22,x21]	//Lecture du premier octet de l'instruction courante

	cmp		x23,0			//Est-ce l'instruction HALT? (0x00)
	b.ne 	Decode10		//sinon, le reste n'est pas encore supporte: Erreur.

	str		xzr,[x19]		//type d'instruction: systeme (0)
	str		xzr,[x19,4]		//numero d'operation: 0 (HALT)
	bl		DecodeFin

Decode10:
	// Recupere le mode
	mov		x24, x23
	lsr		x24, x24, 6
	str		w24, [x19]		//Ecrit le mode dans x19
	add		x19, x19, 4		//Incremente l'adr x19

	//sub		x24,x24,1		//Option -1
	lsl		x24,x24,2		//Déplacement = (option-1) * 4
	adr		x1,switch		//l'instruction est à switch + déplacement
	add		x1,x1,x24		//...
	br		x1				//Saute au bon branchement

	// En fonction du mode je lis le type de format qui correspond
	//switch case pour chaque format
	switch:
			b		format00
			b		format01
			b		format10
			//Bloc de code pour le format 00
	format00:
			//Recupere l'operation
			and 	x25, x23, 0x38	//Masque 0011 1000
			lsr		x25, x25, 3
			str		w25, [x19]		//Ecrit l'operation dans x19
			add		x19, x19, 4

			//Recupere le format
			and 	x25, x23, 0x3	//Masque 0000 0111
			str		w25, [x19] // Sauvegarde du format dans operande
			add		x19, x19, 4
			str		xzr, [x19]		//Desactive le cc
			add		x19, x19, 4
		    str		xzr, [x19]		//Desactive le float
			add		x19, x19, 4
			mov		x26, 1 //Size
			str		w26, [x19]		// Ecrit la size dans Instruction->size

			cmp		x25, 0x3
			b.ne	decodeFormat00Float
			mov		x1, 1
			str		w1, [x19]		//Active le float
	decodeFormat00Float:

			b		swFin

			//Bloc de code pour le format 01
	format01:

			//Recupere l'operation
			mov		x25, x23
			and 	x25, x25, 0x3c	//Masque 0011 1100
			lsr		x25, x25, 2
			str		w25, [x19]		//Ecrit l'operation dans x19
			add		x19, x19, 4		//Incremente l'adr x19
			mov		x4, x25			//Sauvegarde l'operation dans x4

			mov		x26, xzr
			str		w26, [x19]		//Ecrit l'operande par defaut dans x19
			cmp		x4, xzr
			b.ne	format01SansOperande

			//Recupere l'operand
			add		x25, x22, x21
			ldrb	w26, [x25, 1]		// Lecture du premier octet l'operand
			ldrb	w27, [x25, 2]		// Lecture du premier octet l'operand
			lsl		x26, x26, 8
			add		x26, x26, x27
			str		w26, [x19]		//Ecrit l'operande dans x19
	format01SansOperande:
			add		x19, x19, 4		//Incremente l'adr x19
			//Recupere le cc
			mov		x25, x23
			and 	x25, x25, 0x2	//Masque 0000 0010
			lsr		x25, x25, 1
			str		w25, [x19]		//Ecrit le cc dans x0
			add		x19, x19, 4		//Incremente l'adr x19

			//Recupere le fl
			mov		x25, x23
			and 	x25, x25, 0x1	//Masque 0000 001
			str		w25, [x19]		//Ecrit le float dans x19
			add		x19, x19, 4		//Incremente l'adr x19

			mov		x26, 0x1  //Size pare defaut
			cmp		x4, xzr
			b.ne	decodeFormat0110

			mov		x26, 0x3 //Size sans le float pour un push
			cmp		x25, 1

			b.ne	decodeFormat0110
			//Recupere l'operand pour le float
			sub		x19, x19, 12
			add		x25, x22, x21
			ldrb	w26, [x25, 1]		// Lecture du premier octet l'operand
			ldrb	w27, [x25, 2]		// Lecture du deuxieme octet l'operand
			ldrb	w0, [x25, 3]		// Lecture du troisieme octet l'operand
			ldrb	w1, [x25, 4]		// Lecture du quatrieme octet l'operand

			lsl		x26, x26, 24
			lsl		x27, x27, 16
			lsl		x0, x0, 8

			add		x26, x26, x27
			add		x26, x26, x0
			add		x26, x26, x1

			str		w26, [x19]		//Ecrit l'operande dans x19

			add		x19, x19, 12

			mov		x26, 0x5 //Size avec le float

	decodeFormat0110:

			//Recupere la size
			str		w26, [x19]		//Ecrit la size dans x0
			add		x19, x19, 4		//Incremente l'adr x19


			b		swFin

			//Bloc de code pour le format10
	format10:
		//	adr		x0,ptfmt4
		//	bl		printf
			b		swFin
	swFin:

	//Ecrit dans x0 les differents elements d'une instruction

//Penser à regarder si c'est un float pour le push
//Pour charger l'octet suivant, il est à l adr x21 + 1
//Pour le push ecrire le chiffre dans operande

//	x0->mode: type d'instruction
//	x0->operation: champ oper (identifie l'opération spécifique)
//	x0->operand: opérande (pour PUSH, POP, JMP, READ, WRITE)
//	x0->cc: utilisation ou non des codes conditions
//x0->size: taille en octets de l'instruction décodée

DecodeFin:
	mov		x0,0			//code d'erreur 0: decodage reussi

	RESTORE					//Ramène l'environnement de l'appelant
	ret



decodeError:

	mov	x0,1				//code d'erreur 1: instruction indécodable.

	RESTORE					//Ramène l'environnement de l'appelant
	ret


/*******************************************************************************
	Fonction qui empile 2 ou 4 octets sur la pile.

	Paramètres
		x0: Adresse de la structure Machine (état actuel du simulateur)
		x1:	Le nombre d'octets à empiler (2 ou 4).
		x2: La valeur à empiler


	Résultats
		x1->SP : modifie le pointeur de pile (avance de 2 ou 4 octets)
		x1->memory[SP]: modifie la pile (empile une valeur int16 ou float)

*******************************************************************************/
Empile:
	SAVE					//Sauvegarde l'environnement de l'appelant


	//Recupere memory à partir de la structure machine de dans x0
	mov	x19, x0		//Recupere l'adresse de MachineState
	mov	x27, x1

	ldr w20, [x19, 4] //Recupere l'adresse de la pile
	ldr	w21, [x19, 16] // Recupere l'adresse de memory
	add x20, x20, x21 // Calcul de l'adresse de la pile de puis memory
	strh w2, [x20] //On ajoute à la pile le chiffre ( 2 octets)


	cmp	x27, 4		// C'est un float
	b.ne	Empile10
	str w2, [x20]//On ajoute à la pile 4 octets si c'est un float

Empile10:


	//Faire avancer l'adresse de la pile ( add SP puis ecriture au meme endroit)
	ldr w20, [x19, 4] //Recupere de nouveau l'adresse de la pile
	add x20, x20, x27 // On increment l'adresse avec le nombre d'octet du chiffre
	str w20, [x19, 4]	// On save la nouvelle adresse de la pile

	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant


/*******************************************************************************
	Fonction qui dépile 2 ou 4 octets de la pile.

	Paramètres
		x0: Adresse de la structure Machine (état actuel du simulateur)
		x1:	Le nombre d'octets à dépiler (2 ou 4).

	Résultats
		x0->SP : modifie le pointeur de pile (recule de 2 ou 4 octets)
		x0->memory[SP]: modifie la pile (dépile une valeur int16 ou float)
		x0: La valeur dépilée

*******************************************************************************/
Depile:
	SAVE					//Sauvegarde l'environnement de l'appelant

	//Recupere memory à partir de la structure machine de dans x0
	mov	x19, x0		//Recupere l'adresse de MachineState
	mov	x27, x1		// Recupere le nombre d'octet à depiler

	ldr	w21, [x19, 16] // Recupere l'adresse de memory
	ldr w20, [x19, 4] //Recupere l'adresse de la pile a partir de memory
	add x20, x20, x21 // Calcul de l'adresse de la pile depuis memory
	sub x20, x20, 2  // On recul pour avoir le nombre sur la pile
	ldrh w2, [x20] //On charge le chiffre depuis la pile ( 2 octets)

	//mov x1, x2
	//adr x0, fmtWriteD
//	bl printf

	cmp	x27, 4		// C'est un float
	b.ne	Depile10
	sub x20, x20, 2  // On recul encore de 2 si c'est un float
	ldr w2, [x20] //On charge le chiffre depuis la pile ( 4 octets)
//	strw xzr, [x20] // On remet à 0
Depile10:
	//strh xzr, [x20] // On remet à 0

	ldr w20, [x19, 4] //Recupere de nouveau l'adresse de la pile
	sub x20, x20, x27 // On decremente l'adresse avec le nombre d'octet du chiffre
	str w20, [x19, 4]	// On save la nouvelle adresse de la pile

	mov x0, x2 				//On retoure le nombre depilé
	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant

/*******************************************************************************
	Fonction qui simule PUSH: empile une valeur immédiate de 16 bits (entier) ou
	32 bits (float) en mode immédiat.

	Overdrive 120%.
	Empile une valeur de 16 bits (entier) ou 32 bits (float) se trouvant en
	mémoire à l'adresse dans le champ adresse16	en mode direct.


	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->SP : modifie le pointeur de pile (avance de 2 ou 4 octets)
		x1->memory[SP]: modifie la pile (empile une valeur int16 ou float)

*******************************************************************************/
EmuPush:
	SAVE					//Sauvegarde l'environnement de l'appelant

	mov	x19, x0 // Adresse de la structure instruction
	mov x20, x1 // Adresse de la structure Machine



	ldr w21, [x19, 20] // Charge la size de l'instruction
	sub	x21, x21, 1		// On enleve l'octet de l'instruction

	ldr w22, [x19, 8]	// Charge l'operande


	//x0: Adresse de la structure Machine (état actuel du simulateur)
 	//x1: Le nombre d'octets à empiler (2 ou 4).
	//x2: La valeur à empiler
	mov	x0, x20
	mov x1, x21
	mov x2, x22

	bl Empile

	// Prepare les valeurs de retour
	mov		x0, 0
	//mov	x0,1				//code d'erreur 1: instruction non implantée.

	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant

/*******************************************************************************
	Fonction qui simule WRITE: affiche une valeur sur la console


	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->SP : modifie le pointeur de pile (recule de 2 ou 4 octets)
		x1->memory[SP]: modifie la pile (dépile une valeur int16 ou float)
*******************************************************************************/
EmuWrite:
	SAVE					//Sauvegarde l'environnement de l'appelant

	mov	x19, x0 // Adresse de la structure instruction
	mov x20, x1 // Adresse de la structure Machine

	ldr w22, [x19, 8] // Charge le format de l'instruction

	ldr w21, [x19, 20] // Charge la size de l'instruction



	mov x0, x20
	mov x1, x21
	//x0: Adresse de la structure Machine (état actuel du simulateur)
	//x1:	Le nombre d'octets à dépiler (2 ou 4).
	bl Depile
	//Verifier si c'est un float pour la taille et le format
	// Sinon tu depile ton format / chiffre
	mov 	x25, x0

	lsl		x22,x22,2		//Déplacement = (option-1) * 4
	adr		x27,switchWrite		//l'instruction est à switch + déplacement
	add		x27,x27,x22		//...
	br		x27				//Saute au bon branchement



switchWrite:
		b		swop1 //000 : « %c »
		b		swop2 //001 : « %d »
		b		swop3 //010 : « %s »
		b		swop4 //011 : « %f »
		b		swop5 //100 : « %u »
		b		swop6 //101 : « %x »

swop1:
		adr		x0,fmtWriteC
		mov		x1, x25 //Nombre à afficher
		bl		printf
		b		switchWriteFin

swop2:
		adr		x0,fmtWriteD
		mov		x1, x25 //Nombre à afficher

		bl		printf
		b		switchWriteFin

swop3:
		adr		x0,fmtWriteS
		mov		x1, x25 //Nombre à afficher
		bl		printf
		b		switchWriteFin

swop4:
		adr		x0,fmtWriteF
		mov		x1, x25 //Nombre à afficher
		//mov 	x1, xf1 // utiliser un registre floats

		bl		printf
		b		switchWriteFin
swop5:
		adr		x0,fmtWriteU
		mov		x1, x25 //Nombre à afficher
		bl		printf
		b		switchWriteFin
swop6:
		adr		x0,fmtWriteX
		mov		x1, x25 //Nombre à afficher
		bl		printf
		b		switchWriteFin
switchWriteFin:

	mov	x0,	0			//code d'erreur 1: instruction non implantée.

	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant

/*******************************************************************************
	Overdrive 120%
	Fonction qui simule POP: dépile une valeur et la stocke en mémoire

	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->SP : modifie le pointeur de pile (recule de 2 ou 4 octets)
		x1->memory[SP]: modifie la pile (dépile une valeur int16 ou float)
		x1->memory[adresse16]: modifie la mémoire à l'adresse adresse16.
*******************************************************************************/
EmuPop:
	SAVE					//Sauvegarde l'environnement de l'appelant


	mov	x0,1				//code d'erreur 1: instruction non implantée.

	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant

/*******************************************************************************
	Fonction qui simule READ: lecture d'une valeur sur la console

	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->SP : modifie le pointeur de pile (avance de 2 ou 4 octets)
		x1->memory[SP]: modifie la pile (empile une valeur int16 ou float)
*******************************************************************************/
EmuRead:
	SAVE					//Sauvegarde l'environnement de l'appelant


	mov	x0,1				//code d'erreur 1: instruction non implantée.

	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant


/*******************************************************************************
	Fonction qui simule ADD: addition de deux entiers sur le dessus de la pile,
	dépôt du résultat sur le dessus de la pile.

	Overdrive 125%: modifie les codes condition (machine->PS)

	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->SP : modifie le pointeur de pile (recule de 2 ou 4 octets)
		x1->memory[SP]: modifie la pile (dépile deux valeurs int16 ou float),
						puis empile le résultat du calcul.
*******************************************************************************/

EmuAdd:
	SAVE					//Sauvegarde l'environnement de l'appelant
	mov	x19, x0
	mov	x20, x1

	ldr w23, [x19, 16]
	mov	x22, 2 // Taille du nombre par defaut

	cmp	x23, 0x1
	b.ne	EmuAdd10
	mov	x22, 4 // Taille du nombre pour les floats

EmuAdd10:
	mov x0, x20	//x0: Adresse de la structure Machine (état actuel du simulateur)
	mov x1, x22
	//x1:	Le nombre d'octets à dépiler (2 ou 4).
	bl	Depile
	mov	x27, x0	//premier chiffre à ADD

	mov x0, x20	//x0: Adresse de la structure Machine (état actuel du simulateur)
	mov x1, x22		//x1:	Le nombre d'octets à dépiler (2 ou 4).
	bl	Depile
	mov	x26, x0	//second chiffre à ADD

	//x0: Adresse de la structure Machine (état actuel du simulateur)
 	//x1: Le nombre d'octets à empiler (2 ou 4).
	mov	x0, x20
	mov x1, x22		//x1:	Le nombre d'octets à dépiler (2 ou 4).
	add x2, x26, x27	//x2: La valeur à empiler

	bl Empile

	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant

/*******************************************************************************
	Fonction qui simule SUB: soustraction de deux entiers sur le dessus de la
	pile, dépôt du résultat sur le dessus de la pile.

	Overdrive 125%: modifie les codes condition (machine->PS)

	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->SP : modifie le pointeur de pile (recule de 2 ou 4 octets)
		x1->memory[SP]: modifie la pile (dépile deux valeurs int16 ou float),
						puis empile le résultat du calcul.
		x1->PS : modifie les codes condition (Overdrive 125%)

*******************************************************************************/
EmuSub:
	SAVE					//Sauvegarde l'environnement de l'appelant

	mov	x19, x0
	mov	x20, x1
	ldr w23, [x19, 16]
	mov	x22, 2 // Taille du nombre par defaut

	cmp	x23, 0x1
	b.ne	EmuSub10
	mov	x22, 4 // Taille du nombre pour les floats

EmuSub10:
	mov x0, x20	//x0: Adresse de la structure Machine (état actuel du simulateur)
	mov x1, x22
	//x1:	Le nombre d'octets à dépiler (2 ou 4).
	bl	Depile
	mov	x27, x0	//premier chiffre à ADD

	mov x0, x20	//x0: Adresse de la structure Machine (état actuel du simulateur)
	mov x1, x22		//x1:	Le nombre d'octets à dépiler (2 ou 4).
	bl	Depile
	mov	x26, x0	//second chiffre à ADD

	//x0: Adresse de la structure Machine (état actuel du simulateur)
	//x1: Le nombre d'octets à empiler (2 ou 4).
	mov	x0, x20
	mov x1, x22		//x1:	Le nombre d'octets à dépiler (2 ou 4).
	sub x2, x27, x26	//x2: La valeur à empiler

	bl Empile

	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant
/*******************************************************************************
	Fonction qui simule MUL: multiplaction de deux entiers sur le dessus de la
	pile, dépôt du résultat sur le dessus de la pile.

	Overdrive 125%: modifie les codes condition (machine->PS)

	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->SP : modifie le pointeur de pile (recule de 2 ou 4 octets)
		x1->memory[SP]: modifie la pile (dépile deux valeurs int16 ou float),
						puis empile le résultat du calcul.
		x1->PS : modifie les codes condition (Overdrive 125%)

*******************************************************************************/
EmuMul:
	SAVE					//Sauvegarde l'environnement de l'appelant
	mov	x19, x0
	mov	x20, x1
	ldr w23, [x19, 16]
	mov	x22, 2 // Taille du nombre par defaut

	cmp	x23, 0x1
	b.ne	EmuMul10
	mov	x22, 4 // Taille du nombre pour les floats

EmuMul10:
	mov x0, x20	//x0: Adresse de la structure Machine (état actuel du simulateur)
	mov x1, x22
	//x1:	Le nombre d'octets à dépiler (2 ou 4).
	bl	Depile
	mov	x27, x0	//premier chiffre à ADD

	mov x0, x20	//x0: Adresse de la structure Machine (état actuel du simulateur)
	mov x1, x22		//x1:	Le nombre d'octets à dépiler (2 ou 4).
	bl	Depile
	mov	x26, x0	//second chiffre à ADD

	//x0: Adresse de la structure Machine (état actuel du simulateur)
	//x1: Le nombre d'octets à empiler (2 ou 4).
	mov	x0, x20
	mov x1, x22		//x1:	Le nombre d'octets à dépiler (2 ou 4).
	mul x2, x27, x26	//x2: La valeur à empiler


	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant

/*******************************************************************************
	Fonction qui simule DIV: division de deux entiers sur le dessus de la
	pile, dépôt du résultat sur le dessus de la pile.

	Overdrive 125%: modifie les codes condition (machine->PS)

	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->SP : modifie le pointeur de pile (recule de 2 ou 4 octets)
		x1->memory[SP]: modifie la pile (dépile deux valeurs int16 ou float),
						puis empile le résultat du calcul.
		x1->PS : modifie les codes condition (Overdrive 125%)

*******************************************************************************/
EmuDiv:
	SAVE					//Sauvegarde l'environnement de l'appelant

	mov	x19, x0
	mov	x20, x1
	ldr w23, [x19, 16]
	mov	x22, 2 // Taille du nombre par defaut

	cmp	x23, 0x1
	b.ne	EmuDiv10
	mov	x22, 4 // Taille du nombre pour les floats

EmuDiv10:
	mov x0, x20	//x0: Adresse de la structure Machine (état actuel du simulateur)
	mov x1, x22
	//x1:	Le nombre d'octets à dépiler (2 ou 4).
	bl	Depile
	mov	x27, x0	//premier chiffre à ADD

	mov x0, x20	//x0: Adresse de la structure Machine (état actuel du simulateur)
	mov x1, x22		//x1:	Le nombre d'octets à dépiler (2 ou 4).
	bl	Depile
	mov	x26, x0	//second chiffre à ADD

	//x0: Adresse de la structure Machine (état actuel du simulateur)
	//x1: Le nombre d'octets à empiler (2 ou 4).
	mov	x0, x20
	mov x1, x22		//x1:	Le nombre d'octets à dépiler (2 ou 4).
	sdiv x2, x26, x27	//x2: La valeur à empiler


	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant

/*******************************************************************************
	Overdrive 125%
	Fonction qui simule BZ: branchement si zéro.
	Additionne le contenu du champ Depl13 au compteur ordinal (machine->PC) si
	le bit Z des codes conditions (machine->PS) est allumé.

	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->PC : modifie compteur ordinal

*******************************************************************************/
EmuBz:
	SAVE					//Sauvegarde l'environnement de l'appelant


	mov	x0,1				//code d'erreur 1: instruction non implantée.

	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant

/*******************************************************************************
	Overdrive 125%
	Fonction qui simule BN: branchement si négatif.
	Additionne le contenu du champ Depl13 au compteur ordinal (machine->PC) si
	le bit N des codes conditions (machine->PS) est allumé.

	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->PC : modifie compteur ordinal

*******************************************************************************/
EmuBn:
	SAVE					//Sauvegarde l'environnement de l'appelant


	mov	x0,1				//code d'erreur 1: instruction non implantée.

	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant


/*******************************************************************************
	Overdrive 125%
	Fonction qui simule JMP: saut inconditionnel.
	Remplace la valeur du compteur ordinal(machine->PC) par celle qui se trouve
	dans le champ immediat16.

	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->PC : modifie compteur ordinal

*******************************************************************************/
EmuJmp:
	SAVE					//Sauvegarde l'environnement de l'appelant


	mov	x0,1				//code d'erreur 1: instruction non implantée.

	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant

/*******************************************************************************
	Overdrive 130%
	Fonction qui simule JMPL: saut inconditionnel avec lien.
	Empile la valeur actuelle du compteur ordinal (sur 16 bits), puis
	additionne le contenu du champ immediat16 au compteur ordinal.

	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->PC : modifie compteur ordinal
		x1->SP : modifie le pointeur de pile (avance de 2 octets)
		x1->memory[SP]: modifie la pile (empile une adresse de 16 bits)

*******************************************************************************/
EmuJmpl:
	SAVE					//Sauvegarde l'environnement de l'appelant


	mov	x0,1				//code d'erreur 1: instruction non implantée.

	RESTORE					//Ramène l'environnement de l'appelant
	ret						//Retour à l'appelant

/*******************************************************************************
	Overdrive 130%
	Fonction qui simule RET: retour de sous-programme
	Dépile une adresse de sur la pile (sur 16 bits), la copie dans le compteur
	ordinal.

	Paramètres
		x0: Adresse de la structure instruction (instruction décodée)
		x1: Adresse de la structure Machine (état actuel du simulateur)

	Résultats
		x1->PC : modifie compteur ordinal
		x1->SP : modifie le pointeur de pile (recule de 2 octets)
		x1->memory[SP]: modifie la pile (dépile une adresse de 16 bits)

*******************************************************************************/
EmuRet:
	SAVE					//Sauvegarde l'environnement de l'appelant


	mov	x0,1				//code d'erreur 1: instruction non implantée.

	RESTORE					//Ramène l'environnement de l'appelant
	ret
							//Retour à l'appelant
.section ".rodata"
fmtTest:		.asciz	"test : %d \n"
fmtWriteD:		.asciz	"Write : %d \n"
fmtWriteC:		.asciz	"Write : %c \n"
fmtWriteF:		.asciz	"Write : %f \n"
fmtWriteS:		.asciz	"Write : %s \n"
fmtWriteX:		.asciz	"Write : %x \n"
fmtWriteU:		.asciz	"Write : %u \n"

fmtFormat:		.asciz	"\n Format : %x \n"
