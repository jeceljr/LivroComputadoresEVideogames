// normalmente este arquivo seria criado pelo gerador
// Shin JAMMA, mas para este exemplo inicial está
// sendo escrito à mão.

module fpga_pong_de0 (
    input wire CLOCK_50,
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B,
    output wire VGA_HS,
    output wire VGA_VS,
    input wire PS2_CLK,
    input wire PS2_DAT,
	 input wire button
);


    assign led = button;
	 assign ld = PS2_DAT;
	 assign lc = PS2_CLK;

    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;
    wire hsync;
    wire vsync;

    assign VGA_R = red[7:4];
    assign VGA_G = green[7:4];
    assign VGA_B = blue[7:4];
    assign VGA_HS = hsync;
    assign VGA_VS = vsync;

    wire p1start;
    wire p1up;
    wire p1down;
    wire p2up;
    wire p2down;
    
    wire rst;
    wire iniciaj1;
    reg [3:0] rstshft;
    
// gera um pulso de inicializacao sem ajuda de um sinal
// externo e que funciona em todas as FPGAs onde os
// registradores tem um valor '0' no fim da configuracao
    always @(posedge CLOCK_50) begin
        rstshft <= {rstshft[2:0],1'b1};
    end
    assign rst = ~rstshft[3] | ~button;
    assign p1start = rst | iniciaj1;

    pong_sj videogame (
        .clock50MHz(CLOCK_50),
        .p1start(p1start),
        .p1up(p1up),
        .p1down(p1down),
        .p2up(p2up),
        .p2down(p2down),
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .pixelclk()
    );

    entrada controles (
        .relogio50(CLOCK_50),
        .inicializa(rst),
        .ps2relogio(PS2_CLK),
        .ps2dados(PS2_DAT),
        .iniciaj1(iniciaj1),
        .sobe1(p1up),
        .desce1(p1down),
        .sobe2(p2up),
        .desce2(p2down)
    );

endmodule

// Este bloco simula dois controles simples (com apenas sinais "sobe"
// e "desce"). Neste caso os sinais estao vindo de um teclado padrao PS/2
// mas seria possivel usar diretamente botoes da placa de FPGA
// A inteface PS/2 de teclado eh bidirecional, mas se abrirmos mao de
// podermos reinicializar e reconfigurar o teclado e nao tivermos
// interesse em controlado os LEDs podemos fingir que eh uma interface
// apenas de leitura com estas formas de onda:
// ps2relogio:------____-----_____-----_____-----_____----
// ps2dados: xxxx________x====D0===x====D1===x====D2===x==
// ps2relogio: ___------_____------______-----_______---------
// ps2dados:   D6====x====D7====x=====P=====x-----------------
// Sao sempre 11 bits onde o primeiro eh sempre zero e ultimo
// eh sempre um, Os bits D0 a D7 sao o dado que queremos ler e
// o bit P eh a paridade de D0 a D7.

    module entrada (
        input wire relogio50,
        input wire inicializa,
        input wire ps2relogio,
        input wire ps2dados,
        output reg iniciaj1,
        output reg sobe1,
        output reg desce1,
        output reg sobe2,
        output reg desce2
    );
    

    reg [10:0] psshft;
    reg [7:0] pschar; reg [7:0] prevchar;
    reg [14:0] pscnt;
    reg ps2r1; reg ps2r2; reg amostra;
    reg ps2d1; reg ps2d2;
    
    // atraso com dois flip-flops para reduzir meta-estabilidade
    always @(posedge relogio50) begin
        ps2r1 <= ps2relogio;
        ps2r2 <= ps2r1;
        amostra <= ps2r2 & ( ~(ps2r1));
        ps2d1 <= ps2dados;
        ps2d2 <= ps2d1;
    end
    
    always @(posedge relogio50) begin
        if(amostra == 1'b1) begin
            psshft <= {ps2d2,psshft[10:1]};
            pscnt <= 15'b000000000000000;
        end
        else begin
            pscnt <= pscnt + 1;
            if(psshft[0] == 1'b0) begin
    // chegou o "start bit" la em baixo!! Entao chegaram todos
                prevchar <= pschar;
                pschar <= psshft[8:1];
    // nao pega inicio, fim e nem paridade
                psshft <= 11'b11111111111;
            end
            if(pscnt == 15'b111111111111100) begin
                psshft <= 11'b11111111111;
    // forca reinicializacao depois de 0x3ffc * 20ns = 328us sem descida em ps2relogio
            end
            if(pscnt == 15'b111111111111111) begin
                pscnt <= 15'b111111111111101;
    // trava a contagem para nao voltar a zero sozinha
            end
        end
    end
    
    always @(inicializa, pschar, prevchar) begin
        if(inicializa == 1'b1) begin
            iniciaj1 <= 1'b0;
            sobe1 <= 1'b0;
            desce1 <= 1'b0;
            sobe2 <= 1'b0;
            desce2 <= 1'b0;
        end
        else begin
		      iniciaj1 <= 1'b0;
            if(pschar == 8'h76) begin
    // "ESC"
                if(prevchar == 8'hF0) begin
    // keyup
                    iniciaj1 <= 1'b0;
                    sobe1 <= 1'b0;
                    desce1 <= 1'b0;
                    sobe2 <= 1'b0;
                    desce2 <= 1'b0;
                end
                else begin
                    iniciaj1 <= 1'b1;
                end
            end
            if(pschar == 8'h1C) begin
    // "a"
                if(prevchar == 8'hF0) begin
    // keyup
                    sobe1 <= 1'b0;
                end
                else begin
                    sobe1 <= 1'b1;
                    desce1 <= 1'b0;
                end
            end
            if(pschar == 8'h1A) begin
    // "z"
                if(prevchar == 8'hF0) begin
    // keyup
                    desce1 <= 1'b0;
                end
                else begin
                    desce1 <= 1'b1;
                    sobe1 <= 1'b0;
                end
            end
            if(pschar == 8'h42) begin
    // "k"
                if(prevchar == 8'hF0) begin
    // keyup
                    sobe2 <= 1'b0;
                end
                else begin
                    sobe2 <= 1'b1;
                    desce2 <= 1'b0;
                end
            end
            if(pschar == 8'h3A) begin
    // "m"
                if(prevchar == 8'hF0) begin
    // keyup
                    desce2 <= 1'b0;
                end
                else begin
                    desce2 <= 1'b1;
                    sobe2 <= 1'b0;
                end
            end
        end
    end
	 

endmodule
