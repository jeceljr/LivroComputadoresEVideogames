library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- (c) Jecel Mattos de Assumpcao Jr
-- Jogo tipo Pong implementado totalmente em hardware
--
-- O codigo neste arquivo esta' liberado para uso geral
-- nas condicoes da licenca X11 do MIT
--
-- O projeto foi criado inicialmente como uma demonstracao
-- na Fealtec 2001. Esta modificacao para a placa DE2 115
-- da Terasic inclui uma divisao em mais modulos para
-- separar a logica do jogo, a leitura do teclado e a
-- geracao de video.

-- adaptacao para DE0

entity pong0 is
	Port ( relogio50 : in std_logic;
-- VGA
	       r : out std_logic_vector(3 downto 0);
	       g : out std_logic_vector(3 downto 0);
	       b : out std_logic_vector(3 downto 0);
	       hsync : out std_logic;
	       vsync : out std_logic;
-- teclado
	       psrelogio : in std_logic;
	       psdados : in std_logic;
-- hex
	hex3, hex2, hex1, hex0 : out std_logic_vector(6 downto 0);
	resetbtn : in std_logic);
end pong0;

architecture Estrutural of pong0 is

	Signal vs : std_logic;
	Signal hs : std_logic;
	Signal rst : std_logic;
	Signal x, y, y1, y2 : std_logic_vector(10 downto 0);
	Signal hb, vb : std_logic;
	Signal novalinha, hd : std_logic;
	Signal novoquadro, fimsincv, vd : std_logic;
	Signal relogiopar : std_logic;

	Signal borda : std_logic;
	Signal bx, by : std_logic_vector(10 downto 0);
	Signal bola, jogador1, jogador2 : std_logic;
	Signal rstshft : std_logic_vector(3 downto 0);

	Signal sobe1, desce1, sobe2, desce2 : std_logic;

	Signal placar1, placar10, placar2, placar20 : std_logic_vector(3 downto 0);
	Signal plc1, plc2 : std_logic;

	Signal thischar, prevchar : std_logic_vector(7 downto 0);

	Component entrada is
		Port ( relogio50 : in std_logic;
		       inicializa : in std_logic;
		       ps2relogio : in std_logic;
		       ps2dados : in std_logic;
		       sobe1 : out std_logic;
		       desce1 : out std_logic;
		       sobe2 : out std_logic;
		       desce2 : out std_logic;
		thischar, prev : out std_logic_vector(7 downto 0));
	end component;

	Component temporizacao is
		Generic ( ATIVO : natural := 360;
			  PRESINC : natural := 13;
			  LARGURASINC : natural := 54;
			  POSSINC : natural := 27);
		Port ( relogio : in std_logic;
		       inicializa : in std_logic;
		       conta : in std_logic;
		       contagemsaida : out std_logic_vector(10 downto 0);
		       inativo : out std_logic;
		       sinc : out std_logic);
	end component;

	Component pintor is
		Generic ( TAMX : natural := 800; TAMY : natural := 600);
		Port (x, y, bx, by, j1y, j2y : in std_logic_vector(10 downto 0);
		digito1, digito10, digito2, digito20 : in std_logic_vector(3 downto 0);
		jogador1, placar1, jogador2, placar2, bola, borda : out std_logic);
	end component;

	Component jogo is
		Generic ( TAMX : natural := 800; TAMY : natural := 600);
		Port (relogio, inicializa, novoquadro, fimsincv : in std_logic;
		sobe1, desce1, sobe2, desce2 : in std_logic;
		bolax, bolay, j1y, j2y : out std_logic_vector(10 downto 0);
		digito1, digito10, digito2, digito20 : out std_logic_vector(3 downto 0));
	end component;

	Component toseg is
		Port ( digit : in std_logic_vector(3 downto 0);
		       segs : out std_logic_vector(6 downto 0));
	end component;

begin

	-- gera um pulso de inicializacao sem ajuda de um sinal
	-- externo e que funciona em todas as FPGAs onde os
	-- registradores tem um valor '0' no fim da configuracao

	process (relogio50)
	begin
		if relogio50='1' and relogio50'event then
			rstshft <= rstshft (2 downto 0) & '1';
		end if;
	end process;

	rst <= (not rstshft(3)) or (not resetbtn);

	-- sinais de sincronismo atrasados por um ciclo de relogio

	process (relogio50, rst) 
	begin

		if rst='1' then 
			hd <= '0';
			vd <= '0';
			relogiopar <= '0';
		elsif relogio50='1' and relogio50'event then
			hd <= hs;
			vd <= vs;
			relogiopar <= not relogiopar;
		end if;
	end process;

	novalinha <= (not hd) and hs; -- borda de subida do sincronismo horizontal
	novoquadro <= (not vd) and vs; -- borda de subida do sincronismo vertical
	fimsincv <= vd and (not vs); -- borda de descida do sincronismo vertical

	led0: toseg
	Port map (digit=>prevchar(3 downto 0), segs=>hex0);
	led1: toseg
	Port map (digit=>prevchar(7 downto 4), segs=>hex1);
	led2: toseg
	Port map (digit=>thischar(3 downto 0), segs=>hex2);
	led3: toseg
	Port map (digit=>thischar(7 downto 4), segs=>hex3);

	controles: entrada
	Port map (relogio50=>relogio50, inicializa=>rst,
		  ps2relogio=>psrelogio, ps2dados=>psdados,
		  sobe1=>sobe1, desce1=>desce1, sobe2=>sobe2, desce2=>desce2,
		  thischar=>thischar, prev=>prevchar);

	-- padrao VESA: resolucao, freq vertical, freq pixel, dados horizontais, dados verticais
	--		640x480 60Hz, 25.175MHz, 640, 16, 96, 48, 480, 11, 2, 31
	--		800x600 60Hz, 40.000MHz, 800, 40, 128, 88, 600, 1, 4, 23
	--		800x600 72Hz, 50.000MHz, 800, 56, 120, 64, 600, 37, 6, 23
	--		1024x768 60Hz, 65.000MHz, 1024, 24, 136, 160, 768, 3, 6, 29
	horizontal: temporizacao
	Generic map ( ATIVO => 640,
		      PRESINC => 16,
		      LARGURASINC => 96,
		      POSSINC => 48)
	Port map ( relogio => relogio50,
		   inicializa => rst,
		   conta => relogiopar,
		   contagemsaida => x,
		   inativo => hb,
		   sinc => hs);

	vertical: temporizacao
	Generic map ( ATIVO => 480,
		      PRESINC => 11,
		      LARGURASINC => 2,
		      POSSINC => 31)
	Port map ( relogio => relogio50,
		   inicializa => rst,
		   conta => novalinha,
		   contagemsaida => y,
		   inativo => vb,
		   sinc => vs);

	leonardo : pintor
	Generic map ( TAMX => 640, TAMY => 480 )
	Port map (x=>x, y=>y, bx=>bx, by=>by, j1y=>y1, j2y=>y2,
		  digito1=>placar1, digito10=>placar10, digito2=>placar2, digito20=>placar20,
		  jogador1=>jogador1, placar1=>plc1, jogador2=>jogador2, placar2=>plc2,
		  bola=>bola, borda=>borda);

	gustavo : jogo
	Generic map ( TAMX => 640, TAMY => 480 )
	Port map (relogio=>relogio50, inicializa=>rst, novoquadro=>novoquadro, fimsincv=>fimsincv,
		  sobe1=>sobe1, desce1=>desce1, sobe2=>sobe2, desce2=>desce2,
		  bolax=>bx, bolay=>by, j1y=>y1, j2y=>y2,
		  digito1=>placar1, digito10=>placar10, digito2=>placar2, digito20=>placar20);

	-- palete de cores. Os primeiros sinais testados tem
	-- prioridade sobre os ultimos
	process (hb, vb, bola, jogador1, plc1, jogador2, plc2, borda) is
	begin
		if (hb='1' or vb='1') then
			r <= "0000"; g <= "0000"; b <= "0000"; -- forca preto em todo o retraco
		elsif (bola='1') then
			r <= "1111"; g <= "1111"; b <= "0000"; -- a bola eh amarela
		elsif (jogador1='1' or plc1='1') then
			r <= "1111"; g <= "0111"; b <= "0000"; -- jogador 1 eh laranja
		elsif (jogador2='1' or plc2='1') then
			r <= "0000"; g <= "0111"; b <= "1111"; -- jogador 2 eh azulado
		elsif (borda='1') then
			r <= "1111"; g <= "1100"; b <= "1111"; -- borda eh branca
		else
			r <= "0000"; g <= "1000"; b <= "0000"; -- fundo eh verde escuro
		end if;
	end process;
	-- note que os placares tem a mesma cor que os jogadores, mas eh
	-- muito facil modificar o codigo acima para serem cores diferentes

	-- padrao VESA para a polaridade do sincronismo:
	--			640x480 = -h -v
	--			800x600 = +h +v
	vsync <= not vs;
	hsync <= not hs;

end Estrutural;

--
-- todo o estado que representa o jogo (placares, posicoes dos jogadores
-- e posicao da bola) eh modificado neste bloco de acordo com os
-- sinais vindo da entrada. Este pode ser um circuito muito lento jah
-- que nao adianta modificar o estado mais que uma vez por imagem de
-- video, que eh atualizado umas 60 vezes por segundo

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity jogo is
	Generic ( TAMX : natural := 800; TAMY : natural := 600);
	Port (relogio, inicializa, novoquadro, fimsincv : in std_logic;
	sobe1, desce1, sobe2, desce2 : in std_logic;
	bolax, bolay, j1y, j2y : out std_logic_vector(10 downto 0);
	digito1, digito10, digito2, digito20 : out std_logic_vector(3 downto 0));
end jogo;

architecture Comportamental of jogo is

	Signal bdx, bdy : std_logic_vector(10 downto 0);
	Signal bx, by : std_logic_vector(10 downto 0);
	Signal x, y, y1, y2 : std_logic_vector(10 downto 0);
	Signal placar1, placar10, placar2, placar20 : std_logic_vector(3 downto 0);

	Constant METADEX : natural := TAMX/2;
	Constant QUARTOX : natural := METADEX/2;
	Constant TRESQUARTOSX : natural := METADEX+QUARTOX;

	Constant METADEY : natural := TAMY/2;

	Constant LARGURABOLA : natural := TAMX/60;
	Constant ALTURABOLA : natural := TAMY/48;
	Constant MARGEMBY : natural := TAMY/96;

	Constant LARGURAJOGADOR : natural := TAMX/45;
	Constant MEIAALTURAJOGADOR : natural := TAMY/12;
	Constant POSJ1X : natural := TAMX/20;
	Constant POSJ2X : natural := TAMX - POSJ1X;
	Constant MARGEMJY : natural := TAMY/10;

begin

	digito1 <= placar1;
	digito10 <= placar10;
	digito2 <= placar2;
	digito20 <= placar20;
	bolax <= bx;
	bolay <= by;
	j1y <= y1;
	j2y <= y2;

	process (relogio, inicializa, novoquadro,fimsincv) 
	begin

		if inicializa='1' then 
			bx <= CONV_STD_LOGIC_VECTOR(METADEX,11);
			by <= CONV_STD_LOGIC_VECTOR(METADEY,11);
			bdx <= CONV_STD_LOGIC_VECTOR(1,11);
			bdy <= CONV_STD_LOGIC_VECTOR(1,11);
			y1 <= CONV_STD_LOGIC_VECTOR(METADEY,11);
			y2 <= CONV_STD_LOGIC_VECTOR(METADEY,11);
			placar1 <= "0000";
			placar10 <= "0000";
			placar2 <= "0000";
			placar20 <= "0000";
		elsif relogio='1' and relogio'event then
			if novoquadro='1' then -- 60 vezes por segundo (na verdade frequencia vertical)
				if (bx=POSJ1X and by+(ALTURABOLA+MEIAALTURAJOGADOR)>y1 and by<y1+MEIAALTURAJOGADOR) then -- jogador 1 rebateu
					bdx <= (bdx xor "11111111111")+1; -- bdx = 0 - bdx
					if (sobe1='1') then
						bdy <= bdy-1;
					end if;
					if (desce1='1') then
						bdy <= bdy+1;
					end if;
				end if;
				if (bx=(POSJ2X-LARGURABOLA) and by+(ALTURABOLA+MEIAALTURAJOGADOR)>y2 and by<y2+MEIAALTURAJOGADOR) then -- jogador 2 rebateu
					bdx <= (bdx xor "11111111111")+1; -- bdx = 0 - bdx
					if (sobe2='1') then
						bdy <= bdy-1;
					end if;
					if (desce2='1') then
						bdy <= bdy+1;
					end if;
				end if;
				if (bx<1) then -- jogador 1 deixou passar
					bx <= CONV_STD_LOGIC_VECTOR(POSJ2X-LARGURABOLA-1,11);
					by <= y2;
					bdx <= "11111111111";
					if (desce2='1') then
						bdy <= "00000000001";
					elsif (sobe2='1') then
						bdy <= "11111111111";
					else
						bdy <= "00000000000";
					end if;
					if (placar2="1001") then -- se digito ja eh 9 entao vai um
						placar20 <= placar20+1;
						placar2 <= "0000";
					else
						placar2 <= placar2+1;
					end if;
				end if;
				if (bx>(TAMX-LARGURABOLA)) then -- jogador 2 deixou passar
					bx <= CONV_STD_LOGIC_VECTOR(POSJ1X+1,11);
					by <= y1;
					bdx <= "00000000001";
					if (desce1='1') then
						bdy <= "00000000001";
					elsif (sobe1='1') then
						bdy <= "11111111111";
					else
						bdy <= "00000000000";
					end if;
					if (placar1="1001") then -- se digito ja eh 9 entao vai um
						placar10 <= placar10+1;
						placar1 <= "0000";
					else
						placar1 <= placar1+1;
					end if;
				end if;
				if (by<MARGEMBY or by>(TAMY-MARGEMBY-ALTURABOLA)) then -- bordas horizontais sempre refletem verticalmente
					bdy <= (bdy xor "11111111111")+1; -- bdy = 0 - bdy
				end if;
				if (sobe1='1' and y1>MARGEMJY) then -- ainda tem espaco para subir?
					y1 <= y1-2;
				end if;
				if (desce1='1' and y1<(TAMY-MARGEMJY)) then -- ainda tem espaco para descer?
					y1 <= y1+2;
				end if;
				if (sobe2='1' and y2>MARGEMJY) then -- ainda tem espaco para subir?
					y2 <= y2-2;
				end if;
				if (desce2='1' and y2<(TAMY-MARGEMJY)) then -- ainda tem espaco para descer?
					y2 <= y2+2;
				end if;
			end if;
			if fimsincv='1' then -- no fim do sincronismo movimenta a bola com a velocidade calculada acima
				bx <= bx+bdx;
				by <= by+bdy;
			end if;
		end if;
	end process;

end Comportamental;

--
-- Este bloco transforma o estado do jogo numa imagem visivel na tela usando
-- a informacao das coordenadas x e y do ponto que esta sendo desenhado na
-- tela neste instante.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pintor is
	Generic ( TAMX : natural := 800; TAMY : natural := 600);
	Port (x, y, bx, by, j1y, j2y : in std_logic_vector(10 downto 0);
	digito1, digito10, digito2, digito20 : in std_logic_vector(3 downto 0);
	jogador1, placar1, jogador2, placar2, bola, borda : out std_logic);
end pintor;

architecture Comportamental of pintor is

	Component digito is
		Generic ( POSICAOX : natural := 0 );
		Port ( x, y : in std_logic_vector(10 downto 0);
		       placar : in std_logic_vector(3 downto 0);
		       caracter : out std_logic);
	end component;

	Signal d1, d10, d2, d20 : std_logic;

	Constant METADEX : natural := TAMX/2;
	Constant QUARTOX : natural := METADEX/2;
	Constant TRESQUARTOSX : natural := METADEX+QUARTOX;

	Constant METADEY : natural := TAMY/2;

	Constant LARGURABOLA : natural := TAMX/60;
	Constant ALTURABOLA : natural := TAMY/48;
	Constant MARGEMBY : natural := TAMY/96;

	Constant LARGURAJOGADOR : natural := TAMX/45;
	Constant MEIAALTURAJOGADOR : natural := TAMY/12;
	Constant POSJ1X : natural := TAMX/20;
	Constant POSJ2X : natural := TAMX - POSJ1X;
	Constant MARGEMJY : natural := TAMY/10;

	Constant MEIAFAIXAVERT : natural := TAMX/180;

begin

	plc10: digito
	Generic map ( POSICAOX => QUARTOX-10)
	Port map ( x=>x, y=>y, placar=>digito10, caracter=>d10);

	plc1: digito
	Generic map ( POSICAOX => QUARTOX+10)
	Port map ( x=>x, y=>y, placar=>digito1, caracter=>d1);

	plc20: digito
	Generic map ( POSICAOX => TRESQUARTOSX-10)
	Port map ( x=>x, y=>y, placar=>digito20, caracter=>d20);

	plc2: digito
	Generic map ( POSICAOX => TRESQUARTOSX+10)
	Port map ( x=>x, y=>y, placar=>digito2, caracter=>d2);


	bola <= '1' when (x>bx and x<bx+LARGURABOLA and y>by and y<by+ALTURABOLA) else '0';
	jogador1 <= '1' when (x>(POSJ1X-LARGURAJOGADOR) and x<POSJ1X and y>j1y-MEIAALTURAJOGADOR and y<j1y+MEIAALTURAJOGADOR) else '0';
	jogador2 <= '1' when (x>POSJ2X and x<(POSJ2X+LARGURAJOGADOR) and y>j2y-MEIAALTURAJOGADOR and y<j2y+MEIAALTURAJOGADOR) else '0';
	placar1 <= '1' when (d1='1' or d10='1') else '0';
	placar2 <= '1' when (d2='1' or d20='1') else '0';
	borda <=  '1' when (x>(METADEX-MEIAFAIXAVERT) and x<(METADEX+MEIAFAIXAVERT)) else -- faixa central
		  '1' when (y<MARGEMBY or y>(TAMY-MARGEMBY)) else -- borda de cima e de baixo
		  '0';

end Comportamental;

--
-- Este bloco simula dois controles simples (com apenas sinais "sobe" e
-- "desce"). Neste caso os sinais estao vindo de um teclado padrao PS/2
-- mas seria possivel usar diretamente botoes da placa de FPGA
--
-- A inteface PS/2 de teclado eh bidirecional, mas se abrirmos mao de
-- podermos reinicializar e reconfigurar o teclado e nao tivermos
-- interesse em controlado os LEDs podemos fingir que eh uma interface
-- apenas de leitura com estas formas de onda:
-- ps2relogio:------____-----_____-----_____-----_____----
-- ps2dados:  xxxx________x====D0===x====D1===x====D2===x==
--
-- ps2relogio: ___------_____------______-----_______---------
-- ps2dados:   D6====x====D7====x=====P=====x-----------------
--
-- Sao sempre 11 bits onde o primeiro eh sempre zero e ultimo
-- eh sempre um, Os bits D0 a D7 sao o dado que queremos ler e
-- o bit P eh a paridade de D0 a D7.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity entrada is
	Port ( relogio50 : in std_logic;
	       inicializa : in std_logic;
	       ps2relogio : in std_logic;
	       ps2dados : in std_logic;
	       sobe1 : out std_logic;
	       desce1 : out std_logic;
	       sobe2 : out std_logic;
	       desce2 : out std_logic;
	thischar, prev : out std_logic_vector(7 downto 0));
end entrada;

architecture Comportamental of entrada is

	Signal psshft : std_logic_vector(10 downto 0);
	Signal pschar, prevchar : std_logic_vector(7 downto 0);
	Signal pscnt : std_logic_vector(14 downto 0);

	Signal ps2r1, ps2r2, amostra : std_logic;
	Signal ps2d1, ps2d2 : std_logic;

begin

	-- atraso com dois flip-flops para reduzir meta-estabilidade

	process (relogio50)
	begin
		if relogio50'EVENT and relogio50 = '1' then
			ps2r1 <= ps2relogio;
			ps2r2 <= ps2r1;
			amostra <= ps2r2 and (not(ps2r1));
			ps2d1 <= ps2dados;
			ps2d2 <= ps2d1;
		end if;
	end process;

	process (relogio50,amostra)
	begin
		if relogio50='1' and relogio50'event then
			if amostra='1' then
				psshft <= ps2d2 & psshft(10 downto 1);
				pscnt <= "000000000000000";
			else
				pscnt <= pscnt+1;
				if psshft(0)='0' then -- chegou o "start bit" la em baixo!! Entao chegaram todos
					prevchar <= pschar;
					pschar <= psshft(8 downto 1); -- nao pega inicio, fim e nem paridade
					psshft <= "11111111111";
				end if;
				if pscnt = "111111111111100" then
					psshft <= "11111111111"; -- forca reinicializacao depois de 0x3ffc * 20ns = 328us sem descida em ps2relogio
				end if;
				if pscnt = "111111111111111" then
					pscnt <= "111111111111101"; -- trava a contagem para nao voltar a zero sozinha
				end if;
			end if;
		end if;
	end process;

	process (inicializa,pschar,prevchar)
	begin
		if inicializa='1' then
			sobe1 <= '0';
			desce1 <= '0';
			sobe2 <= '0';
			desce2 <= '0';
		else
			if pschar = x"1C" then -- "a"
				if prevchar = x"F0" then -- keyup
					sobe1 <= '0';
				else
					sobe1 <= '1';
					desce1 <= '0';
				end if;
			end if;
			if pschar = x"1A" then -- "z"
				if prevchar = x"F0" then -- keyup
					desce1 <= '0';
				else
					desce1 <= '1';
					sobe1 <= '0';
				end if;
			end if;
			if pschar = x"42" then -- "k"
				if prevchar = x"F0" then -- keyup
					sobe2 <= '0';
				else
					sobe2 <= '1';
					desce2 <= '0';
				end if;
			end if;
			if pschar = x"3A" then -- "m"
				if prevchar = x"F0" then -- keyup
					desce2 <= '0';
				else
					desce2 <= '1';
					sobe2 <= '0';
				end if;
			end if;
		end if;
	end process;


	thischar <= pschar;
	prev <= prevchar;

end Comportamental;

--
-- Este bloco gera uma contagem e dois sinais auxiliares que dividem
-- a contagem em 4 regioes. O que esta sendo contado eh controlado por
-- um sinal "conta" que pode ficar sempre em 1 se for desejado contar
-- diretamente ciclos de relogio.
--
-- inativo: _________________________________-----------------------___
-- sinc:    _________________________________________----------________
--       4  |             1                  |  2    |    3    | 4  |  1
-- 1) ATIVO
-- 2) PRESINC
-- 3) LARGURASINC
-- 4) POSSINC
--
-- A contagem comeca em zero no  inicio da regiao ativa e deve ser menor
-- que o valor maximo do contador (2047 com 11 bits) ateh o fim da regiao 4
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity temporizacao is
	Generic ( ATIVO : natural := 360;
		  PRESINC : natural := 13;
		  LARGURASINC : natural := 54;
		  POSSINC : natural := 27);
	Port ( relogio : in std_logic;
	       conta : in std_logic;
	       inicializa : in std_logic;
	       contagemsaida : out std_logic_vector(10 downto 0);
	       inativo : out std_logic;
	       sinc : out std_logic);
end temporizacao;

architecture Comportamental of temporizacao is

	Constant TOTAL : natural := ATIVO+PRESINC+LARGURASINC+POSSINC;
	Signal contagem : std_logic_vector(10 downto 0);

begin

	contagemsaida <= contagem;
	inativo <= '0' when (contagem < ATIVO) else '1';
	sinc <= '0' when (contagem < (ATIVO+PRESINC)) else
		'1' when (contagem < (ATIVO+PRESINC+LARGURASINC)) else
		'0';

	process (relogio, inicializa) 
	begin

		if inicializa='1' then 
			contagem <= "00000000000";
		elsif relogio='1' and relogio'event then
			if conta='1' then
				if contagem < (TOTAL-1) then
					contagem <= contagem + 1;
				else
					contagem <= "00000000000";
				end if;
			end if;
		end if;
	end process;

end Comportamental;

--
-- converte um numero de 4 bits em informacoes para LED de
-- 7 segmentos e depois converte esta informacao em 7 retangulos
-- na tela, ascesos ou apagados conforme a entrada
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity digito is
	Generic ( POSICAOX : natural := 0 );
	Port ( x, y : in std_logic_vector(10 downto 0);
	       placar : in std_logic_vector(3 downto 0);
	       caracter : out std_logic);
end digito;

architecture Comportamental of digito is

	Constant X1 : natural := POSICAOX;
	Constant X2 : natural := POSICAOX+5;
	Constant X3 : natural := POSICAOX+10;
	Constant X4 : natural := POSICAOX+15;
	Constant Y1 : natural := 30;
	Constant Y2 : natural := 35;
	Constant Y3 : natural := 40;
	Constant Y4 : natural := 45;
	Constant Y5 : natural := 50;
	Constant Y6 : natural := 55;
	Signal segment : std_logic_vector(6 downto 0);

begin

	-- segment encoding
	--      0
	--     ---  
	--  5 |   | 1
	--     ---   <- 6
	--  4 |   | 2
	--     ---
	--      3

	with placar SELect
		segment<= "1111001" when "0001",   --1
			  "0100100" when "0010",   --2
			  "0110000" when "0011",   --3
			  "0011001" when "0100",   --4
			  "0010010" when "0101",   --5
			  "0000010" when "0110",   --6
			  "1111000" when "0111",   --7
			  "0000000" when "1000",   --8
			  "0010000" when "1001",   --9
			  "0001000" when "1010",   --A
			  "0000011" when "1011",   --b
			  "1000110" when "1100",   --C
			  "0100001" when "1101",   --d
			  "0000110" when "1110",   --E
			  "0001110" when "1111",   --F
			  "1000000" when others;   --0


	caracter <= '1' when (segment(0)='0' and x>X1 and x<X4 and y>Y1 and y<Y2) else
		    '1' when (segment(1)='0' and x>X3 and x<X4 and y>Y1 and y<Y4) else
		    '1' when (segment(2)='0' and x>X3 and x<X4 and y>Y3 and y<Y6) else
		    '1' when (segment(3)='0' and x>X1 and x<X4 and y>y5 and y<Y6) else
		    '1' when (segment(4)='0' and x>X1 and x<X2 and y>Y3 and y<Y6) else
		    '1' when (segment(5)='0' and x>X1 and x<X2 and Y>Y1 and y<Y4) else
		    '1' when (segment(6)='0' and x>X1 and x<X4 and Y>Y3 and y<Y4) else
		    '0';

end Comportamental;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity toseg is
	Port ( digit : in std_logic_vector(3 downto 0);
	       segs : out std_logic_vector(6 downto 0));
end toseg;

architecture Comportamental of toseg is

begin

	-- segment encoding
	--      0
	--     ---  
	--  5 |   | 1
	--     ---   <- 6
	--  4 |   | 2
	--     ---
	--      3

	with digit SELect
		segs<= "1111001" when "0001",   --1
		       "0100100" when "0010",   --2
		       "0110000" when "0011",   --3
		       "0011001" when "0100",   --4
		       "0010010" when "0101",   --5
		       "0000010" when "0110",   --6
		       "1111000" when "0111",   --7
		       "0000000" when "1000",   --8
		       "0010000" when "1001",   --9
		       "0001000" when "1010",   --A
		       "0000011" when "1011",   --b
		       "1000110" when "1100",   --C
		       "0100001" when "1101",   --d
		       "0000110" when "1110",   --E
		       "0001110" when "1111",   --F
		       "1000000" when others;   --0

end Comportamental;
