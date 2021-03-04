----------------------------------------------------------------
-- Prova Finale  - Progetto di Reti Logiche - 2020/2021
-- Luca Gabaglio - Codice Persona 10578930  - Matricola 889641
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
    port (
        i_clk       : in std_logic;
        i_rst       : in std_logic;
        i_start     : in std_logic;
        i_data      : in std_logic_vector(7 downto 0);
        o_address   : out std_logic_vector(15 downto 0);
        o_done      : out std_logic;
        o_en        : out std_logic;
        o_we        : out std_logic;
        o_data      : out std_logic_vector(7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type tipo_stato is (IDLE, IDLES1, S1, S1S2, S2, S2S3, S3, S3S3, S4, S4S5, S5, S5S4,  DONE);
    signal state : tipo_stato;
    signal max : std_logic_vector(7 downto 0) := "00000000";
    signal min : std_logic_vector(7 downto 0) := "11111111";
    signal counter : std_logic_vector(15 downto 0) := "0000000000000000"; -- contatore del numero di righe e colonne
    shared variable deltaValue : std_logic_vector(7 downto 0) := "00000000";
    signal shiftLevel : std_logic_vector(3 downto 0) := "0000"; --numero intero con valori da 0 a 8
    shared variable newPixelValue : std_logic_vector(7 downto 0) := "00000000";
    shared variable tempPixel : std_logic_vector(15 downto 0) := "0000000000000000";
    shared variable nRighe, nColonne, counterSave, log2 : integer := 0;

begin  
    process (i_clk, i_rst, i_start, i_data)
        begin
            -----------------------------------------------------------------------------------------------se devo resettare
            if (i_rst = '1') then
                o_en <= '0';
                o_we <= '0';
                o_done <= '0';
                o_address <= "0000000000000000";
                o_data <= "00000000";
                max <= "00000000";
                min <= "11111111";
                nRighe := 0;
                nColonne := 0;
                log2 := 0;
                counterSave := 0;
                counter <= std_logic_vector(to_unsigned(0, 16));
                deltavalue := std_logic_vector(to_unsigned(0, 8));
                shiftLevel <= std_logic_vector(to_unsigned(0, 4));
                tempPixel := std_logic_vector(to_unsigned(0, 16));
                newPixelValue := std_logic_vector(to_unsigned(0, 8));
                state <= IDLE;  
            -----------------------------------------------------------------------------------------------se non devo resettare                                        
            elsif rising_edge(i_clk) then
                --------------------------------------------------------------------------switch case sullo stato
                case state is
                --------------------------------------------------------------------------IDLE
                when IDLE =>
                    o_done <= '0';
                    if (i_start = '1') then
                        o_en <= '1';
                        o_address <= std_logic_vector(to_unsigned(0, 16));
                        state <= IDLES1;
                    end if;
                --------------------------------------------------------------------------S1
                when IDLES1 =>                    
                    state <= S1;
                --------------------------------------------------------------------------S1
                when S1 =>
                    nColonne := to_integer(unsigned(i_data));
                    o_address <= std_logic_vector(to_unsigned(1, 16));
                    state <=S1S2; 
                --------------------------------------------------------------------------S1S2   
                when S1S2 =>
                    state <= S2;
                --------------------------------------------------------------------------S2                   
                when S2 =>
                    nRighe := to_integer(unsigned(i_data));
                    counterSave := nRighe*nColonne;
                    counter <= std_logic_vector(to_unsigned(nRighe*nColonne, 16));
                    o_address <= std_logic_vector(to_unsigned(counterSave, 16) + to_unsigned(1, 16));
                    state <= S2S3;
                --------------------------------------------------------------------------S2S3   
                when S2S3 =>
                    state <= S3;
                --------------------------------------------------------------------------S3    
                when S3 =>
                    if (counter = std_logic_vector(to_unsigned(0, 16))) then
                        state <= S4;
                        deltaValue := std_logic_vector(unsigned(max) - unsigned(min));
                        if(unsigned(deltaValue)=to_unsigned(255,8)) then
                            log2 := 8;
                        elsif(unsigned(deltaValue)>=127) then
                            log2 := 7;
                        elsif(unsigned(deltaValue)>=63) then
                            log2 := 6;
                        elsif(unsigned(deltaValue)>=31) then
                            log2 := 5;
                        elsif(unsigned(deltaValue)>=15) then
                            log2 := 4;
                        elsif(unsigned(deltaValue)>=7) then
                            log2 := 3;
                        elsif(unsigned(deltaValue)>=3) then
                            log2 := 2;
                        elsif(unsigned(deltaValue)>=1) then
                            log2 := 1;
                        else
                            log2 := 0;
                        end if;
                        shiftLevel <= std_logic_vector(to_unsigned(8 - log2, 4));
                        counter <= std_logic_vector(to_unsigned(counterSave, 16));                   
                    else
                        state <= S3S3;
                        o_address <= counter;
                        counter <= std_logic_vector(unsigned(counter) - to_unsigned(1, 16));
                        if (unsigned(i_data) < unsigned(min)) then
                            min <= i_data;
                        end if;
                        if (unsigned(i_data) > unsigned(max)) then
                            max <= i_data;
                        end if;                                       
                    end if;
                --------------------------------------------------------------------------S3S3   
                when S3S3 =>
                    state <= S3;     
                --------------------------------------------------------------------------S4    
                when S4 =>
                    if (counter = std_logic_vector(to_unsigned(0, 16))) then
                        o_en <= '0';
                        o_done <= '1';
                        o_address <= "0000000000000000";
                        o_data <= "00000000";
                        max <= "00000000";
                        min <= "11111111";
                        nRighe := 0;
                        nColonne := 0;
                        log2 := 0;
                        counterSave := 0;
                        counter <= std_logic_vector(to_unsigned(0, 16));
                        deltavalue := std_logic_vector(to_unsigned(0, 8));
                        shiftLevel <= std_logic_vector(to_unsigned(0, 4));
                        tempPixel := std_logic_vector(to_unsigned(0, 16));
                        newPixelValue := std_logic_vector(to_unsigned(0, 8));
                        state <= DONE;
                    else 
                        o_address <= std_logic_vector(unsigned(counter) + to_unsigned(1, 16));
                        state <=S4S5;
                    end if;
                --------------------------------------------------------------------------S4S5   
                when S4S5 =>
                    state <= S5;                    
                --------------------------------------------------------------------------S5    
                when S5 =>
                    o_we <= '1';
                    o_address <= std_logic_vector(unsigned(counter) + to_unsigned(1 + counterSave, 16));
                    tempPixel := std_logic_vector(to_unsigned(to_integer(unsigned(i_data) - unsigned(min)), 16));
                    tempPixel := std_logic_vector(unsigned(tempPixel) sll to_integer(unsigned(shiftLevel)));
                    if(unsigned(tempPixel) < to_unsigned(255, 8)) then
                        o_data <= std_logic_vector(to_unsigned(to_integer(unsigned(tempPixel)),8));
                    else
                        o_data <= std_logic_vector(to_unsigned(255, 8));
                    end if;
                    state <= S5S4;
                    counter <= std_logic_vector(unsigned(counter) - to_unsigned(1, 16));
                --------------------------------------------------------------------------S5S4   
                when S5S4 =>
                    o_we <= '0';
                    state <= S4;                      
                --------------------------------------------------------------------------DONE
                when DONE =>                    
                    state <= DONE;
                    if (i_start = '0') then
                        state <= IDLE;    
                        o_done <= '0'; 
                    end if;           
                end case;
            end if;
    end process;    
end Behavioral;