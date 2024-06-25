/*
 * Generated by Digital. Don't modify this file!
 * Any changes will be lost if this file is regenerated.
 */

module DIG_Counter_Nbit
#(
    parameter Bits = 2
)
(
    output [(Bits-1):0] out,
    output ovf,
    input C,
    input en,
    input clr
);
    reg [(Bits-1):0] count;

    always @ (posedge C) begin
        if (clr)
          count <= 'h0;
        else if (en)
          count <= count + 1'b1;
    end

    assign out = count;
    assign ovf = en? &count : 1'b0;

    initial begin
        count = 'h0;
    end
endmodule


// Compara dois n�meros de 12 bits e indica se s�o iguais
module compara (
  input [11:0] A,
  input [11:0] B,
  output \= 
);
  wire [11:0] s0;
  wire [5:0] s1;
  wire [5:0] s2;
  assign s0 = (A ^ B);
  assign s1 = s0[5:0];
  assign s2 = s0[11:6];
  assign \=  = ~ (s1[0] | s1[1] | s1[2] | s1[3] | s1[4] | s1[5] | s2[0] | s2[1] | s2[2] | s2[3] | s2[4] | s2[5]);
endmodule

module DIG_Register
(
    input C,
    input en,
    input D,
    output Q
);

    reg  state = 'h0;

    assign Q = state;

    always @ (posedge C) begin
        if (en)
            state <= D;
   end
endmodule

// Este bloco gera uma contagem e dois sinais auxiliares que dividem
// a contagem em 4 regioes. O que esta sendo contado eh controlado por
// um sinal "conta" que pode ficar sempre em 1 se for desejado contar
// diretamente ciclos de relogio.
// 
// mostra:  ----------------------------------______________________---
// sinc:    _________________________________________----------________
//       4  |             1                  |  2    |    3    | 4  |  1
// 
// 1) ATIVO
// 2) PRESINC
// 3) LARGURASINC
// 4) POSSINC
// 
// A contagem comeca em zero no  inicio da regiao ativa e deve ser menor
// que o valor maximo do contador (4095 com 12 bits) ateh o fim da regiao 4
module temporiza (
  input relogio,
  input conta,
  input inicializa,
  input [11:0] upix, // indica que este � o �ltimo pixel visivel ou
                     // a �ltima linha vis�vel
  input [11:0] inisinc, // indica que o pulso de sincroniza��o deve iniciar
  input [11:0] fimsinc, // indica que o pulso de sincroniza��o deve terminar
  input [11:0] fimcont, // inidica que este � a �ltima contagem antes de voltar para zero
  output [11:0] contagem,
  output fim,
  output mostra,
  output sinc
);
  wire [11:0] contagem_temp;
  wire fim_temp;
  wire s0;
  wire s1;
  wire s2;
  wire s3;
  wire s4;
  wire s5;
  DIG_Counter_Nbit #(
    .Bits(12)
  )
  DIG_Counter_Nbit_i0 (
    .en( conta ),
    .C( relogio ),
    .clr( s0 ),
    .out( contagem_temp )
  );
  compara compara_i1 (
    .A( contagem_temp ),
    .B( upix ),
    .\= ( s1 )
  );
  compara compara_i2 (
    .A( contagem_temp ),
    .B( inisinc ),
    .\= ( s2 )
  );
  compara compara_i3 (
    .A( contagem_temp ),
    .B( fimsinc ),
    .\= ( s3 )
  );
  compara compara_i4 (
    .A( contagem_temp ),
    .B( fimcont ),
    .\= ( fim_temp )
  );
  assign s0 = ((fim_temp & conta) | inicializa);
  DIG_Register DIG_Register_i5 (
    .D( fim_temp ),
    .C( relogio ),
    .en( s4 ),
    .Q( mostra )
  );
  DIG_Register DIG_Register_i6 (
    .D( s2 ),
    .C( relogio ),
    .en( s5 ),
    .Q( sinc )
  );
  assign s4 = (s1 | fim_temp);
  assign s5 = (s2 | s3);
  assign contagem = contagem_temp;
  assign fim = fim_temp;
endmodule
module DIG_D_FF_1bit
#(
    parameter Default = 0
)
(
   input D,
   input C,
   output Q,
   output \~Q
);
    reg state;

    assign Q = state;
    assign \~Q = ~state;

    always @ (posedge C) begin
        state <= D;
    end

    initial begin
        state = Default;
    end
endmodule


module DIG_Register_BUS #(
    parameter Bits = 1
)
(
    input C,
    input en,
    input [(Bits - 1):0]D,
    output [(Bits - 1):0]Q
);

    reg [(Bits - 1):0] state = 'h0;

    assign Q = state;

    always @ (posedge C) begin
        if (en)
            state <= D;
   end
endmodule

module CompUnsigned #(
    parameter Bits = 1
)
(
    input [(Bits -1):0] a,
    input [(Bits -1):0] b,
    output \> ,
    output \= ,
    output \<
);
    assign \> = a > b;
    assign \= = a == b;
    assign \< = a < b;
endmodule

module DIG_Add
#(
    parameter Bits = 1
)
(
    input [(Bits-1):0] a,
    input [(Bits-1):0] b,
    input c_i,
    output [(Bits - 1):0] s,
    output c_o
);
   wire [Bits:0] temp;

   assign temp = a + b + c_i;
   assign s = temp [(Bits-1):0];
   assign c_o = temp[Bits];
endmodule



module DIG_Sub #(
    parameter Bits = 2
)
(
    input [(Bits-1):0] a,
    input [(Bits-1):0] b,
    input c_i,
    output [(Bits-1):0] s,
    output c_o
);
    wire [Bits:0] temp;

    assign temp = a - b - c_i;
    assign s = temp[(Bits-1):0];
    assign c_o = temp[Bits];
endmodule


module Mux_4x1_NBits #(
    parameter Bits = 2
)
(
    input [1:0] sel,
    input [(Bits - 1):0] in_0,
    input [(Bits - 1):0] in_1,
    input [(Bits - 1):0] in_2,
    input [(Bits - 1):0] in_3,
    output reg [(Bits - 1):0] out
);
    always @ (*) begin
        case (sel)
            2'h0: out = in_0;
            2'h1: out = in_1;
            2'h2: out = in_2;
            2'h3: out = in_3;
            default:
                out = 'h0;
        endcase
    end
endmodule


module raquete (
  input relogio,
  input inicializa,
  input move,
  input sobe,
  input desce,
  output [11:0] y
);
  wire [11:0] y_temp;
  wire [11:0] s0;
  wire s1;
  wire s2;
  wire s3;
  wire [1:0] s4;
  wire [11:0] s5;
  wire [11:0] s6;
  assign s1 = (inicializa | move);
  // posicao
  DIG_Register_BUS #(
    .Bits(12)
  )
  DIG_Register_BUS_i0 (
    .D( s0 ),
    .C( relogio ),
    .en( s1 ),
    .Q( y_temp )
  );
  assign s4[0] = (inicializa | (sobe & s2));
  assign s4[1] = (inicializa | (desce & s3));
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i1 (
    .a( y_temp ),
    .b( 12'b101000 ),
    .\> ( s2 )
  );
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i2 (
    .a( y_temp ),
    .b( 12'b110111000 ),
    .\< ( s3 )
  );
  DIG_Add #(
    .Bits(12)
  )
  DIG_Add_i3 (
    .a( y_temp ),
    .b( 12'b10 ),
    .c_i( 1'b0 ),
    .s( s6 )
  );
  DIG_Sub #(
    .Bits(12)
  )
  DIG_Sub_i4 (
    .a( y_temp ),
    .b( 12'b10 ),
    .c_i( 1'b0 ),
    .s( s5 )
  );
  Mux_4x1_NBits #(
    .Bits(12)
  )
  Mux_4x1_NBits_i5 (
    .sel( s4 ),
    .in_0( y_temp ),
    .in_1( s5 ),
    .in_2( s6 ),
    .in_3( 12'b11110000 ),
    .out( s0 )
  );
  assign y = y_temp;
endmodule

// Flip flop mais b�sico, que pode ligar ou desligar a sa�da
module ffsr (
  input S, // liga Q
  input R, // desliga Q
  output Q,
  output \~Q 
);
  wire Q_temp;
  wire \~Q_temp ;
  assign Q_temp = ~ (R | \~Q_temp );
  assign \~Q_temp  = ~ (Q_temp | S);
  assign Q = Q_temp;
  assign \~Q  = \~Q_temp ;
endmodule

module placar (
  input relogio,
  input inicializa,
  input conta,
  output [3:0] digito1,
  output [3:0] digito10
);
  wire [3:0] digito1_temp;
  wire s0;
  DIG_Counter_Nbit #(
    .Bits(4)
  )
  DIG_Counter_Nbit_i0 (
    .en( s0 ),
    .C( relogio ),
    .clr( inicializa ),
    .out( digito10 )
  );
  DIG_Counter_Nbit #(
    .Bits(4)
  )
  DIG_Counter_Nbit_i1 (
    .en( conta ),
    .C( relogio ),
    .clr( s0 ),
    .out( digito1_temp )
  );
  assign s0 = ((digito1_temp[0] & ~ digito1_temp[1] & ~ digito1_temp[2] & digito1_temp[3] & conta) | inicializa);
  assign digito1 = digito1_temp;
endmodule

module Mux_2x1_NBits #(
    parameter Bits = 2
)
(
    input [0:0] sel,
    input [(Bits - 1):0] in_0,
    input [(Bits - 1):0] in_1,
    output reg [(Bits - 1):0] out
);
    always @ (*) begin
        case (sel)
            1'h0: out = in_0;
            1'h1: out = in_1;
            default:
                out = 'h0;
        endcase
    end
endmodule


module DIG_Neg #(
    parameter Bits = 1
)
(
      input signed [(Bits-1):0] in,
      output signed [(Bits-1):0] out
);
    assign out = -in;
endmodule


module bola1d (
  input relogio,
  input inicializa,
  input move,
  input [11:0] centro,
  input volta,
  input reflete,
  input sobe,
  input desce,
  output [11:0] posicao,
  output dir
);
  wire [11:0] posicao_temp;
  wire [11:0] s0;
  wire s1;
  wire [11:0] s2;
  wire [11:0] s3;
  wire [11:0] s4;
  wire [11:0] s5;
  wire [1:0] s6;
  wire [11:0] s7;
  wire [11:0] s8;
  wire s9;
  wire [11:0] s10;
  assign s1 = (inicializa | move);
  assign s6[0] = (desce | inicializa);
  assign s6[1] = (sobe | inicializa);
  assign s9 = (volta | inicializa);
  // posicao
  DIG_Register_BUS #(
    .Bits(12)
  )
  DIG_Register_BUS_i0 (
    .D( s0 ),
    .C( relogio ),
    .en( s1 ),
    .Q( posicao_temp )
  );
  // velocidade
  DIG_Register_BUS #(
    .Bits(12)
  )
  DIG_Register_BUS_i1 (
    .D( s2 ),
    .C( relogio ),
    .en( s1 ),
    .Q( s3 )
  );
  Mux_2x1_NBits #(
    .Bits(12)
  )
  Mux_2x1_NBits_i2 (
    .sel( reflete ),
    .in_0( s3 ),
    .in_1( s4 ),
    .out( s5 )
  );
  Mux_4x1_NBits #(
    .Bits(12)
  )
  Mux_4x1_NBits_i3 (
    .sel( s6 ),
    .in_0( s5 ),
    .in_1( s7 ),
    .in_2( s8 ),
    .in_3( 12'b111111111111 ),
    .out( s2 )
  );
  Mux_2x1_NBits #(
    .Bits(12)
  )
  Mux_2x1_NBits_i4 (
    .sel( s9 ),
    .in_0( s10 ),
    .in_1( centro ),
    .out( s0 )
  );
  DIG_Neg #(
    .Bits(12)
  )
  DIG_Neg_i5 (
    .in( s3 ),
    .out( s4 )
  );
  DIG_Add #(
    .Bits(12)
  )
  DIG_Add_i6 (
    .a( s5 ),
    .b( 12'b1 ),
    .c_i( 1'b0 ),
    .s( s7 )
  );
  DIG_Sub #(
    .Bits(12)
  )
  DIG_Sub_i7 (
    .a( s5 ),
    .b( 12'b1 ),
    .c_i( 1'b0 ),
    .s( s8 )
  );
  DIG_Add #(
    .Bits(12)
  )
  DIG_Add_i8 (
    .a( posicao_temp ),
    .b( s2 ),
    .c_i( 1'b0 ),
    .s( s10 )
  );
  assign dir = s3[11];
  assign posicao = posicao_temp;
endmodule

// Todo o estado que representa o jogo (placares, posicoes dos jogadores
// e posicao da bola) eh modificado neste bloco de acordo com os
// sinais vindo da entrada. Este pode ser um circuito muito lento jah
// que nao adianta modificar o estado mais que uma vez por imagem de
// video, que eh atualizado umas 60 vezes por segundo
module jogo (
  input relogio,
  input inicializa,
  input vs,
  input sobe1,
  input desce1,
  input sobe2,
  input desce2,
  input colj1,
  input colj2,
  output [11:0] bolax,
  output [11:0] bolay,
  output [11:0] j1y,
  output [11:0] j2y,
  output [3:0] digito1,
  output [3:0] digito10,
  output [3:0] digito2,
  output [3:0] digito20,
  output a_rebate,
  output a_reflete,
  output a_torcida
);
  wire [11:0] bolax_temp;
  wire [11:0] bolay_temp;
  wire s0;
  wire s1;
  wire s2;
  wire s3;
  wire volta;
  wire reflete;
  wire s4;
  wire s5;
  wire rebate;
  wire xdir;
  wire s6;
  wire s7;
  wire s8;
  wire s9;
  wire s10;
  wire s11;
  wire s12;
  wire a_rebate_temp;
  wire a_reflete_temp;
  wire a_torcida_temp;
  wire s13;
  wire [5:0] s14;
  wire s15;
  wire s16;
  wire s17;
  wire [2:0] s18;
  wire s19;
  wire s20;
  wire s21;
  wire [3:0] s22;
  wire s23;
  wire s24;
  DIG_D_FF_1bit #(
    .Default(0)
  )
  DIG_D_FF_1bit_i0 (
    .D( vs ),
    .C( relogio ),
    .\~Q ( s0 )
  );
  assign s16 = ~ relogio;
  assign s20 = ~ relogio;
  assign s24 = ~ relogio;
  assign s1 = (vs & s0);
  assign s6 = ~ (s0 | vs);
  raquete raquete_i1 (
    .relogio( relogio ),
    .inicializa( inicializa ),
    .move( s1 ),
    .sobe( sobe2 ),
    .desce( desce2 ),
    .y( j2y )
  );
  raquete raquete_i2 (
    .relogio( relogio ),
    .inicializa( inicializa ),
    .move( s1 ),
    .sobe( sobe1 ),
    .desce( desce1 ),
    .y( j1y )
  );
  ffsr ffsr_i3 (
    .S( colj1 ),
    .R( s6 ),
    .Q( s11 )
  );
  ffsr ffsr_i4 (
    .S( colj2 ),
    .R( s6 ),
    .Q( s12 )
  );
  placar placar_i5 (
    .relogio( relogio ),
    .inicializa( inicializa ),
    .conta( s2 ),
    .digito1( digito1 ),
    .digito10( digito10 )
  );
  placar placar_i6 (
    .relogio( relogio ),
    .inicializa( inicializa ),
    .conta( s3 ),
    .digito1( digito2 ),
    .digito10( digito20 )
  );
  // vertical
  bola1d bola1d_i7 (
    .relogio( relogio ),
    .inicializa( inicializa ),
    .move( s1 ),
    .centro( 12'b11110000 ),
    .volta( volta ),
    .reflete( reflete ),
    .sobe( s4 ),
    .desce( s5 ),
    .posicao( bolay_temp )
  );
  // horizontal
  bola1d bola1d_i8 (
    .relogio( relogio ),
    .inicializa( inicializa ),
    .move( s1 ),
    .centro( 12'b101000000 ),
    .volta( volta ),
    .reflete( rebate ),
    .sobe( 1'b0 ),
    .desce( 1'b0 ),
    .posicao( bolax_temp ),
    .dir( xdir )
  );
  assign rebate = ((s11 & xdir) | (s12 & ~ xdir));
  assign s2 = (s8 & s1);
  assign s3 = (s7 & s1);
  assign s5 = (rebate & ((s12 & desce2) | (s11 & desce1)));
  assign s4 = (rebate & ((s12 & sobe2) | (s11 & sobe1)));
  DIG_Counter_Nbit #(
    .Bits(6)
  )
  DIG_Counter_Nbit_i9 (
    .en( s13 ),
    .C( relogio ),
    .clr( volta ),
    .out( s14 )
  );
  assign s13 = (a_torcida_temp & s6);
  DIG_D_FF_1bit #(
    .Default(0)
  )
  DIG_D_FF_1bit_i10 (
    .D( s15 ),
    .C( s16 ),
    .\~Q ( a_torcida_temp )
  );
  DIG_Counter_Nbit #(
    .Bits(3)
  )
  DIG_Counter_Nbit_i11 (
    .en( s17 ),
    .C( relogio ),
    .clr( reflete ),
    .out( s18 )
  );
  assign s17 = (a_reflete_temp & s6);
  DIG_D_FF_1bit #(
    .Default(0)
  )
  DIG_D_FF_1bit_i12 (
    .D( s19 ),
    .C( s20 ),
    .\~Q ( a_reflete_temp )
  );
  DIG_Counter_Nbit #(
    .Bits(4)
  )
  DIG_Counter_Nbit_i13 (
    .en( s21 ),
    .C( relogio ),
    .clr( rebate ),
    .out( s22 )
  );
  assign s21 = (a_rebate_temp & s6);
  DIG_D_FF_1bit #(
    .Default(0)
  )
  DIG_D_FF_1bit_i14 (
    .D( s23 ),
    .C( s24 ),
    .\~Q ( a_rebate_temp )
  );
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i15 (
    .a( bolax_temp ),
    .b( 12'b1000 ),
    .\< ( s7 )
  );
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i16 (
    .a( bolax_temp ),
    .b( 12'b1001111000 ),
    .\> ( s8 )
  );
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i17 (
    .a( bolay_temp ),
    .b( 12'b1000 ),
    .\< ( s9 )
  );
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i18 (
    .a( bolay_temp ),
    .b( 12'b111011000 ),
    .\> ( s10 )
  );
  assign s15 = s14[5];
  assign s19 = s18[2];
  assign s23 = s22[3];
  assign reflete = (s9 | s10);
  assign volta = (s7 | s8);
  assign bolax = bolax_temp;
  assign bolay = bolay_temp;
  assign a_rebate = a_rebate_temp;
  assign a_reflete = a_reflete_temp;
  assign a_torcida = a_torcida_temp;
endmodule
module DIG_ROM_16X7_hex2seg (
    input [3:0] A,
    input sel,
    output reg [6:0] D
);
    reg [6:0] my_rom [0:15];

    always @ (*) begin
        if (~sel)
            D = 7'hz;
        else
            D = my_rom[A];
    end

    initial begin
        my_rom[0] = 7'h3f;
        my_rom[1] = 7'h6;
        my_rom[2] = 7'h5b;
        my_rom[3] = 7'h4f;
        my_rom[4] = 7'h66;
        my_rom[5] = 7'h6d;
        my_rom[6] = 7'h7d;
        my_rom[7] = 7'h7;
        my_rom[8] = 7'h7f;
        my_rom[9] = 7'h6f;
        my_rom[10] = 7'h77;
        my_rom[11] = 7'h7c;
        my_rom[12] = 7'h39;
        my_rom[13] = 7'h5e;
        my_rom[14] = 7'h79;
        my_rom[15] = 7'h71;
    end
endmodule


module retangulo (
  input [11:0] x, // posicao horizontal do feixe
  input [11:0] y, // posicao vertical do feixe
  input [11:0] xmin, // lado esquerdo
  input [11:0] xmax, // lado direito
  input [11:0] ymin, // lado de cima
  input [11:0] ymax, // lado de baixo
  output r // � 1 quando o feixe est� dentro do retangulo indicado

);
  wire s0;
  wire s1;
  wire s2;
  wire s3;
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i0 (
    .a( x ),
    .b( xmin ),
    .\< ( s0 )
  );
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i1 (
    .a( x ),
    .b( xmax ),
    .\> ( s1 )
  );
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i2 (
    .a( y ),
    .b( ymin ),
    .\< ( s2 )
  );
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i3 (
    .a( y ),
    .b( ymax ),
    .\> ( s3 )
  );
  assign r = ~ (s0 | s1 | s2 | s3);
endmodule

module digito (
  input [11:0] x,
  input [11:0] y,
  input [3:0] digito,
  input [4:0] pos,
  output caracter
);
  wire [11:0] x1;
  wire [11:0] x4;
  wire s0;
  wire [11:0] x2;
  wire s1;
  wire [11:0] x3;
  wire s2;
  wire s3;
  wire s4;
  wire s5;
  wire s6;
  wire [6:0] s7;
  // hex2seg
  DIG_ROM_16X7_hex2seg DIG_ROM_16X7_hex2seg_i0 (
    .A( digito ),
    .sel( 1'b1 ),
    .D( s7 )
  );
  assign x1[4:0] = 5'b0;
  assign x1[9:5] = pos;
  assign x1[11:10] = 2'b0;
  assign x2[4:0] = 5'b10;
  assign x2[9:5] = pos;
  assign x2[11:10] = 2'b0;
  assign x3[4:0] = 5'b1101;
  assign x3[9:5] = pos;
  assign x3[11:10] = 2'b0;
  assign x4[4:0] = 5'b1111;
  assign x4[9:5] = pos;
  assign x4[11:10] = 2'b0;
  // 0
  retangulo retangulo_i1 (
    .x( x ),
    .y( y ),
    .xmin( x1 ),
    .xmax( x4 ),
    .ymin( 12'b11110 ),
    .ymax( 12'b100000 ),
    .r( s0 )
  );
  // 5
  retangulo retangulo_i2 (
    .x( x ),
    .y( y ),
    .xmin( x1 ),
    .xmax( x2 ),
    .ymin( 12'b11110 ),
    .ymax( 12'b101100 ),
    .r( s1 )
  );
  // 1
  retangulo retangulo_i3 (
    .x( x ),
    .y( y ),
    .xmin( x3 ),
    .xmax( x4 ),
    .ymin( 12'b11110 ),
    .ymax( 12'b101100 ),
    .r( s2 )
  );
  // 6
  retangulo retangulo_i4 (
    .x( x ),
    .y( y ),
    .xmin( x1 ),
    .xmax( x4 ),
    .ymin( 12'b101010 ),
    .ymax( 12'b101100 ),
    .r( s3 )
  );
  // 4
  retangulo retangulo_i5 (
    .x( x ),
    .y( y ),
    .xmin( x1 ),
    .xmax( x2 ),
    .ymin( 12'b101010 ),
    .ymax( 12'b110111 ),
    .r( s4 )
  );
  // 2
  retangulo retangulo_i6 (
    .x( x ),
    .y( y ),
    .xmin( x3 ),
    .xmax( x4 ),
    .ymin( 12'b101010 ),
    .ymax( 12'b110111 ),
    .r( s5 )
  );
  // 3
  retangulo retangulo_i7 (
    .x( x ),
    .y( y ),
    .xmin( x1 ),
    .xmax( x4 ),
    .ymin( 12'b110101 ),
    .ymax( 12'b110111 ),
    .r( s6 )
  );
  assign caracter = ((s0 & s7[0]) | (s2 & s7[1]) | (s5 & s7[2]) | (s6 & s7[3]) | (s4 & s7[4]) | (s1 & s7[5]) | (s3 & s7[6]));
endmodule

// Este bloco transforma o estado do jogo numa imagem visivel na tela usando
// a informacao das coordenadas x e y do ponto que esta sendo desenhado na
// tela neste instante.
module pintor (
  input [11:0] x,
  input [11:0] y,
  input [11:0] bx,
  input [11:0] by,
  input [11:0] j1y,
  input [11:0] j2y,
  input [3:0] digito1,
  input [3:0] digito10,
  input [3:0] digito2,
  input [3:0] digito20,
  output borda,
  output placar2,
  output jogador2,
  output placar1,
  output jogador1,
  output bola
);
  wire s0;
  wire s1;
  wire s2;
  wire s3;
  wire [11:0] s4;
  wire [11:0] s5;
  wire [11:0] s6;
  wire [11:0] s7;
  wire [11:0] s8;
  wire [11:0] s9;
  wire [11:0] s10;
  wire [11:0] s11;
  wire s12;
  wire s13;
  wire s14;
  digito digito_i0 (
    .x( x ),
    .y( y ),
    .digito( digito1 ),
    .pos( 5'b110 ),
    .caracter( s0 )
  );
  digito digito_i1 (
    .x( x ),
    .y( y ),
    .digito( digito10 ),
    .pos( 5'b101 ),
    .caracter( s1 )
  );
  digito digito_i2 (
    .x( x ),
    .y( y ),
    .digito( digito2 ),
    .pos( 5'b1111 ),
    .caracter( s2 )
  );
  digito digito_i3 (
    .x( x ),
    .y( y ),
    .digito( digito20 ),
    .pos( 5'b1110 ),
    .caracter( s3 )
  );
  DIG_Add #(
    .Bits(12)
  )
  DIG_Add_i4 (
    .a( bx ),
    .b( 12'b110 ),
    .c_i( 1'b0 ),
    .s( s5 )
  );
  DIG_Sub #(
    .Bits(12)
  )
  DIG_Sub_i5 (
    .a( bx ),
    .b( 12'b110 ),
    .c_i( 1'b0 ),
    .s( s4 )
  );
  DIG_Add #(
    .Bits(12)
  )
  DIG_Add_i6 (
    .a( by ),
    .b( 12'b110 ),
    .c_i( 1'b0 ),
    .s( s7 )
  );
  DIG_Sub #(
    .Bits(12)
  )
  DIG_Sub_i7 (
    .a( by ),
    .b( 12'b110 ),
    .c_i( 1'b0 ),
    .s( s6 )
  );
  DIG_Add #(
    .Bits(12)
  )
  DIG_Add_i8 (
    .a( j1y ),
    .b( 12'b101000 ),
    .c_i( 1'b0 ),
    .s( s9 )
  );
  DIG_Sub #(
    .Bits(12)
  )
  DIG_Sub_i9 (
    .a( j1y ),
    .b( 12'b101000 ),
    .c_i( 1'b0 ),
    .s( s8 )
  );
  DIG_Add #(
    .Bits(12)
  )
  DIG_Add_i10 (
    .a( j2y ),
    .b( 12'b101000 ),
    .c_i( 1'b0 ),
    .s( s11 )
  );
  DIG_Sub #(
    .Bits(12)
  )
  DIG_Sub_i11 (
    .a( j2y ),
    .b( 12'b101000 ),
    .c_i( 1'b0 ),
    .s( s10 )
  );
  retangulo retangulo_i12 (
    .x( x ),
    .y( y ),
    .xmin( 12'b100111100 ),
    .xmax( 12'b101000100 ),
    .ymin( 12'b1 ),
    .ymax( 12'b111011110 ),
    .r( s12 )
  );
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i13 (
    .a( y ),
    .b( 12'b1000 ),
    .\< ( s13 )
  );
  CompUnsigned #(
    .Bits(12)
  )
  CompUnsigned_i14 (
    .a( y ),
    .b( 12'b111011000 ),
    .\> ( s14 )
  );
  assign placar1 = (s0 | s1);
  assign placar2 = (s2 | s3);
  retangulo retangulo_i15 (
    .x( x ),
    .y( y ),
    .xmin( s4 ),
    .xmax( s5 ),
    .ymin( s6 ),
    .ymax( s7 ),
    .r( bola )
  );
  retangulo retangulo_i16 (
    .x( x ),
    .y( y ),
    .xmin( 12'b100000 ),
    .xmax( 12'b101110 ),
    .ymin( s8 ),
    .ymax( s9 ),
    .r( jogador1 )
  );
  retangulo retangulo_i17 (
    .x( x ),
    .y( y ),
    .xmin( 12'b1001010010 ),
    .xmax( 12'b1001100000 ),
    .ymin( s10 ),
    .ymax( s11 ),
    .r( jogador2 )
  );
  assign borda = (s13 | s12 | s14);
endmodule
module PriorityEncoder3 (
    input in0,
    input in1,
    input in2,
    input in3,
    input in4,
    input in5,
    input in6,
    input in7,
    output reg [2:0] num,
    output any
);
    always @ (*) begin
        if (in7 == 1'b1)
            num = 3'h7;
        else if (in6 == 1'b1)
            num = 3'h6;
        else if (in5 == 1'b1)
            num = 3'h5;
        else if (in4 == 1'b1)
            num = 3'h4;
        else if (in3 == 1'b1)
            num = 3'h3;
        else if (in2 == 1'b1)
            num = 3'h2;
        else if (in1 == 1'b1)
            num = 3'h1;
        else 
            num = 3'h0;
    end

    assign any = in0 | in1 | in2 | in3 | in4 | in5 | in6 | in7;
endmodule


module Mux_8x1_NBits #(
    parameter Bits = 2
)
(
    input [2:0] sel,
    input [(Bits - 1):0] in_0,
    input [(Bits - 1):0] in_1,
    input [(Bits - 1):0] in_2,
    input [(Bits - 1):0] in_3,
    input [(Bits - 1):0] in_4,
    input [(Bits - 1):0] in_5,
    input [(Bits - 1):0] in_6,
    input [(Bits - 1):0] in_7,
    output reg [(Bits - 1):0] out
);
    always @ (*) begin
        case (sel)
            3'h0: out = in_0;
            3'h1: out = in_1;
            3'h2: out = in_2;
            3'h3: out = in_3;
            3'h4: out = in_4;
            3'h5: out = in_5;
            3'h6: out = in_6;
            3'h7: out = in_7;
            default:
                out = 'h0;
        endcase
    end
endmodule

module DIG_D_FF_Nbit
#(
    parameter Bits = 2,
    parameter Default = 0
)
(
   input [(Bits-1):0] D,
   input C,
   output [(Bits-1):0] Q,
   output [(Bits-1):0] \~Q
);
    reg [(Bits-1):0] state;

    assign Q = state;
    assign \~Q = ~state;

    always @ (posedge C) begin
        state <= D;
    end

    initial begin
        state = Default;
    end
endmodule


module vg (
  input clock50MHz_i,
  input resetn_i,
  input p1_select_i,
  input p1_start_i,
  input p1_up_i,
  input p1_down_i,
  input p1_left_i,
  input p1_right_i,
  input p1_button1_i,
  input p1_button2_i,
  input p1_button3_i,
  input p1_button4_i,
  input p1_button5_i,
  input p1_button6_i,
  input p2_select_i,
  input p2_start_i,
  input p2_up_i,
  input p2_down_i,
  input p2_left_i,
  input p2_right_i,
  input p2_button1_i,
  input p2_button2_i,
  input p2_button3_i,
  input p2_button4_i,
  input p2_button5_i,
  input p2_button6_i,
  input [15:0] switch_i,
  input [31:0] wb_data_i,
  input wb_ack_i,
  input dmi_req_valid_i,
  input [6:0] dmi_req_address_i,
  input [31:0] dmi_req_data_i,
  input [1:0] dmi_req_op_i,
  input dmi_rsp_ready_i,
  output [7:0] v_r_o,
  output [7:0] v_g_o,
  output [7:0] v_b_o,
  output v_vs_o,
  output v_hs_o,
  output v_clk_o,
  output [11:0] v_x_o,
  output [11:0] v_y_o,
  output v_de_o,
  output [15:0] a_left_o,
  output [15:0] a_right_o,
  output a_clk_o,
  output [15:0] led_o,
  output [63:0] seg_o,
  output [31:0] wb_adr_o,
  output [31:0] wb_dat_o,
  output wb_we_o,
  output [3:0] wb_sel_o,
  output wb_stb_o,
  output wb_cyc_o,
  output dmi_req_ready_o,
  output dmi_rsp_valid_o,
  output [31:0] dmi_rsp_data_o,
  output [1:0] dmi_rsp_op_o
);
  wire v_clk_o_temp;
  wire [11:0] v_x_o_temp;
  wire [11:0] v_y_o_temp;
  wire v_de_o_temp;
  wire [15:0] a_right_o_temp;
  wire a_clk_o_temp;
  wire [31:0] wb_dat_o_temp;
  wire wb_cyc_o_temp;
  wire s0;
  wire s1;
  wire s2;
  wire s3;
  wire s4;
  wire s5;
  wire [23:0] s6;
  wire s7;
  wire s8;
  wire s9;
  wire s10;
  wire s11;
  wire s12;
  wire s13;
  wire [2:0] s14;
  wire [11:0] s15;
  wire [11:0] s16;
  wire [11:0] s17;
  wire [11:0] s18;
  wire [3:0] s19;
  wire [3:0] s20;
  wire [3:0] s21;
  wire [3:0] s22;
  wire s23;
  wire s24;
  wire s25;
  wire s26;
  wire s27;
  wire s28;
  wire s29;
  wire s30;
  wire s31;
  wire s32;
  wire [14:0] s33;
  wire [14:0] s34;
  wire s35;
  assign led_o = 16'b0;
  assign seg_o = 64'b0;
  assign wb_dat_o_temp = 32'b0;
  assign wb_sel_o = 4'b0;
  assign wb_cyc_o_temp = 1'b0;
  assign dmi_rsp_op_o = 2'b0;
  assign s0 = (~ resetn_i | p1_start_i);
  assign s23 = (p1_button1_i | p2_up_i);
  assign s24 = (p1_button2_i | p2_down_i);
  // horizontal
  temporiza temporiza_i0 (
    .relogio( v_clk_o_temp ),
    .conta( 1'b1 ),
    .inicializa( s0 ),
    .upix( 12'b1001111111 ),
    .inisinc( 12'b1010001111 ),
    .fimsinc( 12'b1011101111 ),
    .fimcont( 12'b1100011111 ),
    .contagem( v_x_o_temp ),
    .fim( s1 ),
    .mostra( s2 ),
    .sinc( s3 )
  );
  // vertical
  temporiza temporiza_i1 (
    .relogio( v_clk_o_temp ),
    .conta( s1 ),
    .inicializa( s0 ),
    .upix( 12'b111011111 ),
    .inisinc( 12'b111101001 ),
    .fimsinc( 12'b111101011 ),
    .fimcont( 12'b1000001100 ),
    .contagem( v_y_o_temp ),
    .mostra( s4 ),
    .sinc( s5 )
  );
  jogo jogo_i2 (
    .relogio( v_clk_o_temp ),
    .inicializa( s0 ),
    .vs( s5 ),
    .sobe1( p1_up_i ),
    .desce1( p1_down_i ),
    .sobe2( s23 ),
    .desce2( s24 ),
    .colj1( s25 ),
    .colj2( s26 ),
    .bolax( s15 ),
    .bolay( s16 ),
    .j1y( s17 ),
    .j2y( s18 ),
    .digito1( s19 ),
    .digito10( s20 ),
    .digito2( s21 ),
    .digito20( s22 ),
    .a_rebate( s27 ),
    .a_reflete( s28 ),
    .a_torcida( s29 )
  );
  DIG_D_FF_1bit #(
    .Default(0)
  )
  DIG_D_FF_1bit_i3 (
    .D( v_clk_o_temp ),
    .C( clock50MHz_i ),
    .\~Q ( v_clk_o_temp )
  );
  assign v_vs_o = ~ s5;
  assign v_hs_o = ~ s3;
  assign v_de_o_temp = (s4 & s2);
  pintor pintor_i4 (
    .x( v_x_o_temp ),
    .y( v_y_o_temp ),
    .bx( s15 ),
    .by( s16 ),
    .j1y( s17 ),
    .j2y( s18 ),
    .digito1( s19 ),
    .digito10( s20 ),
    .digito2( s21 ),
    .digito20( s22 ),
    .borda( s7 ),
    .placar2( s8 ),
    .jogador2( s9 ),
    .placar1( s10 ),
    .jogador1( s11 ),
    .bola( s12 )
  );
  assign a_clk_o_temp = v_y_o_temp[0];
  assign s13 = ~ v_de_o_temp;
  assign s30 = (s12 & s11);
  assign s31 = (s12 & s9);
  PriorityEncoder3 PriorityEncoder3_i5 (
    .in0( 1'b1 ),
    .in1( s7 ),
    .in2( s8 ),
    .in3( s9 ),
    .in4( s10 ),
    .in5( s11 ),
    .in6( s12 ),
    .in7( s13 ),
    .num( s14 )
  );
  DIG_D_FF_1bit #(
    .Default(0)
  )
  DIG_D_FF_1bit_i6 (
    .D( s30 ),
    .C( v_clk_o_temp ),
    .Q( s25 )
  );
  DIG_D_FF_1bit #(
    .Default(0)
  )
  DIG_D_FF_1bit_i7 (
    .D( s31 ),
    .C( v_clk_o_temp ),
    .Q( s26 )
  );
  Mux_8x1_NBits #(
    .Bits(24)
  )
  Mux_8x1_NBits_i8 (
    .sel( s14 ),
    .in_0( 24'b100000000000000 ),
    .in_1( 24'b111111111111000011111111 ),
    .in_2( 24'b111111110111111100000000 ),
    .in_3( 24'b111111110111111100000000 ),
    .in_4( 24'b111111111111111 ),
    .in_5( 24'b111111111111111 ),
    .in_6( 24'b1111111111111111 ),
    .in_7( 24'b0 ),
    .out( s6 )
  );
  assign v_r_o = s6[7:0];
  assign v_g_o = s6[15:8];
  assign v_b_o = s6[23:16];
  assign a_right_o_temp[12:0] = 13'b0;
  assign a_right_o_temp[13] = ((v_y_o_temp[4] & s27) | (v_y_o_temp[2] & s28) | (s32 & s29));
  assign a_right_o_temp[15:14] = 2'b0;
  DIG_D_FF_Nbit #(
    .Bits(15),
    .Default(0)
  )
  DIG_D_FF_Nbit_i9 (
    .D( s33 ),
    .C( a_clk_o_temp ),
    .Q( s34 )
  );
  assign s35 = s34[13];
  assign s32 = ~ (s35 ^ s34[14]);
  assign s33[0] = s32;
  assign s33[13:1] = s34[12:0];
  assign s33[14] = s35;
  assign v_clk_o = v_clk_o_temp;
  assign v_x_o = v_x_o_temp;
  assign v_y_o = v_y_o_temp;
  assign v_de_o = v_de_o_temp;
  assign a_left_o = a_right_o_temp;
  assign a_right_o = a_right_o_temp;
  assign a_clk_o = a_clk_o_temp;
  assign wb_adr_o = wb_dat_o_temp;
  assign wb_dat_o = wb_dat_o_temp;
  assign wb_we_o = wb_cyc_o_temp;
  assign wb_stb_o = wb_cyc_o_temp;
  assign wb_cyc_o = wb_cyc_o_temp;
  assign dmi_req_ready_o = wb_cyc_o_temp;
  assign dmi_rsp_valid_o = wb_cyc_o_temp;
  assign dmi_rsp_data_o = wb_dat_o_temp;
endmodule
