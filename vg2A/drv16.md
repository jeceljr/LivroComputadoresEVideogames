# drv16

O processador drv16 é baseado no padrão RISC-V mas com apenas 16 registradores
de 16 bits cada. Ele implementa menos instruções que o RV32I mas as que implementa
usam o mesmo mnemonico e tem uma funcionalidade diferente.

O código binário das instruções é de 16 mas não é compatível com a extensão C do
RISC-V. A maior diferença é o código que acrescenta 12 bits ao valor imediato
da instrução seguinte, criando uma instrução com 32 bits no total.

As demais instruções usam o formato:

| 15 14 13 12 | 11 10 09 08 | 07 06 05 04 | 03 02 01 00 |
|-------------|-------------|-------------|-------------|
| rD | rS1 | rS2 | operação |

O registrador x0 contém o valor atual do contador de instruções (PC), mas quando
os campo rD é zero nenhum registrador é alterado e quando os campos rS1 ou rS2
são zero o valor 0 é usado e não o que está em x0.

A busca normal das instruções equivale a

' @RI := mem[@PC := @PC + 2]

A notação **@rS2** indica o valor de 16 bits contido no registrador cujo endereço é
o campo rS2 da instrução enquanto só **rS2** indica o valor imediato de 4 bits
extendido para 16 bits daquele campo (instrução de 32 bits). Já rD indica o valor
imediato de 4 bits que pode ter sido extendido ou não para 16 bits.

| operação | assembly | funcionamento |
|----------|----------|---------------|
| 0 |  | define bits 4 a 15 do valor imediato |
| 1 | ADD | @rD := @rS1 + @rS2 |
| 1 | ADDI | @rD := @rS1 + rS2 |
| 2 | SUB | @rD := @rS1 - @rS2 |
| 2 | SUBI | @rD := @rS1 - rS2 |
| 3 | SLT | @rD := @rS1 < @rS2 |
| 3 | SLTI | @rD := @rS1 < rS2 |
| 4 | JALR | @rD := @PC + 2. @PC := @rS1 + @rS2 |
| 4 | JAL | @rD := @PC + 2. @PC := @rS1 + rS2 |
| 5 | AND | @rD := @rS1 & @rS2 |
| 5 | ANDI | @rD := @rS1 & rS2 |
| 6 | OR | @rD := @rS1 \| @rS2 |
| 6 | ORI | @rD := @rS1 \| rS2 |
| 7 | XOR | @rD := @rS1 ^ @rS2 |
| 7 | XORI | @rD := @rS1 ^ rS2 |
| 8 | | |
| 9 | LH | @rD := mem[@rS1 + @rS2] |
| 9 | LH | @rD := mem[@rS1 + rS2] |
| A | LB | @rD := ExtendeSinal(mem[@rS1 + @rS2]) |
| A | LB | @rD := ExtendeSinal(mem[@rS1 + rS2]) |
| B | LBU | @rD := ExtendeZeros(mem[@rS1 + @rS2]) |
| B | LBU | @rD := ExtendeZeros(mem[@rS1 + rS2]) |
| C | SH | mem[@rS1 + rD] := @rS2 |
| D | SB | mem[@rS1 + rD] := 8Bits(@rS2) |
| E | BEQ | se @rS1 = @rS2 então @RI := mem[@PC := @PC + rD] |
| E | BNE | se @rS1 ~= @rS2 então @RI := mem[@PC := @PC + rD] |
| F | BLT | se @rS1 \< @rS2 então @RI := mem[@PC := @PC + rD] |
| F | BGE | se @rS1 \>= @rS2 então @RI := mem[@PC := @PC + rD] |

A maioria das instruções tem duas variantes e é a presença de uma extensão que
seleciona entre elas. No caso do **BEQ** e **BNE** é o bit menos siginificativo
de **rD** (extendido ou não) que seleciona entre elas já que não faz sentido
pular para um endereço ímpar.
