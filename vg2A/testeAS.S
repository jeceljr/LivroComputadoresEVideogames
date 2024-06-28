/* teste uso do GNU AS para gerar binários para drv16 */

.include "drv16.inc"

inicio:
        xor s0, s1, s1
        bne s0,zero, inicio
        addi a0,s0,128
        la t0, temp
        lh t1,t0,0
        jal a1,.+2
        subi a1,a1,2
        auipc a0, 512
        jalr ra,a1,0
temp:   .word 0
