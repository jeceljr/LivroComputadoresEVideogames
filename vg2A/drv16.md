# drv16

O processador drv16 é baseado no padrão RISC-V mas com apenas 16 registradores
de 16 bits cada. Ele implementa menos instruções que o RV32I mas as que implementa
usam o mesmo mnemonico e tem uma funcionalidade equivalente.

O código binário das instruções é de 16 bits mas não é compatível com a extensão C do
RISC-V. A maior diferença é o código que acrescenta 12 bits ao valor imediato
da instrução seguinte, criando uma instrução com 32 bits no total.

As demais instruções usam o formato:

| 15 14 13 12 | 11 10 09 08 | 07 06 05 04 | 03 02 01 00 |
|-------------|-------------|-------------|-------------|
| rD | rS1 | rS2 | operação |

O registrador x0 contém o valor atual do contador de instruções (PC), mas quando
os campo rD é zero nenhum registrador é alterado e quando os campos rS1 ou rS2
são zero o valor 0 é usado e não o que está em x0.

A busca normal das instruções equivale a `@RI := mem[@PC := @PC + 2]`. Nas memórias
incluidas em FPGAs o dado só pode ser usado no ciclo seguinte ao que fornece o
endereço para leitura. Isso faz a maioria das instruções usarem 2 ciclos de relógio
enquanto as que leem da memória usam 3 ciclos.

A notação **@rS2** indica o valor de 16 bits contido no registrador cujo endereço é
o campo rS2 da instrução enquanto só **rS2** indica o valor imediato de 4 bits
extendido para 16 bits daquele campo (instrução de 32 bits). Já **rD** indica o valor
imediato de 4 bits que pode ter sido extendido ou não para 16 bits.

| operação | assembly | funcionamento |
|----------|----------|---------------|
| 0 |  | @IM := @IR, @IR := mem[@PC := @PC + 2] |
| 1 | AND | @rD := @rS1 & @rS2 |
| 1 | ANDI | @rD := @rS1 & (@IM \| rS2) |
| 2 | OR | @rD := @rS1 \| @rS2 |
| 2 | ORI | @rD := @rS1 \| (@IM \| rS2) |
| 3 | XOR | @rD := @rS1 ^ @rS2 |
| 3 | XORI | @rD := @rS1 ^ (@IM | rS2) |
| 4 | JALR | @rD := @PC + 2. @IR := mem[@PC := @rS1 + @rS2] |
| 4 | JAL | @rD := @PC + 2. @IR := mem[@PC := @rS1 + rS2] |
| 5 | ADD | @rD := @rS1 + @rS2 |
| 5 | ADDI | @rD := @rS1 + (@IM \| rS2) |
| 6 | SUB | @rD := @rS1 - @rS2 |
| 6 | SUBI | @rD := @rS1 - (@IM \| rS2) |
| 7 | SLT | @rD := @rS1 < @rS2 |
| 7 | SLTI | @rD := @rS1 < (@IM \| rS2) |
| 8 | | |
| 9 | LH | @rD := mem[@rS1 + @rS2] |
| 9 | LH | @rD := mem[@rS1 + (@IM \| rS2)] |
| A | LB | @rD := ExtendeSinal(mem[@rS1 + @rS2]) |
| A | LB | @rD := ExtendeSinal(mem[@rS1 + (@IM \| rS2)]) |
| B | LBU | @rD := ExtendeZeros(mem[@rS1 + @rS2]) |
| B | LBU | @rD := ExtendeZeros(mem[@rS1 + (@IM \| rS2)]) |
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

O drv16 tem a instrução **SUBI** que o RV32I não tem (já que constantes para **ADDI**
podem ser negativos). Ele não tem comparações sem sinal (**SLTIU**, **SLTU**,
**BLTU**, **BGEU**) e **LUI** ou **AUI** já que valores imediatos maiores são
gerados de maneira diferente.

Também faltam todas as instruções de deslocamente (**SLLI**, **SRLI**, **SRAI**,
**SLL**, **SRL**, **SRA**) pois o hardware necessário para isso geralmente é grande
comparado com o resto do processador. A instrução `SLLI x3,x4,3` pode ser
implementada pela sequência `ADD x3,x4,x4. ADD x3,x3,x3. ADD x3,x3,x3`. Os
deslocamentos para a direita são mais complexos, mas viáveis.

Não foram implementadas **ECALL** ou **EBREAK** mas ainda existe uma operação
não definida.
