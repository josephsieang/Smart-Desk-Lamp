`timescale 1ns / 1ps
module OnePulse (
	output reg signal_single_pulse,
	input wire signal,
	input wire clock
	);
	
	reg signal_delay;

	always @(posedge clock) begin
		if (signal == 1'b1 & signal_delay == 1'b0)
		  signal_single_pulse <= 1'b1;
		else
		  signal_single_pulse <= 1'b0;

		signal_delay <= signal;
	end
endmodule

//////////////////////////////////////////////////////////////////////////////////
module clock_1sec(clk,clk_div);
//parameter n = 100_000_000;

input clk;
output reg clk_div;

reg [28:0] num;
reg [28:0] next_num;

always @(posedge clk)
 begin
    num<= next_num;
 end

//assign next_num = num+1;
always @* begin
    if( num == 29'd100_000_000) begin
        clk_div = 1;
        next_num = 0;
    end
    else begin
        clk_div = 0;
        next_num = num+1;
    end
end
endmodule
///////////////////////////////////////
module seven_decoder (DISPLAY, DIGIT, BCD3, BCD2, BCD1, BCD0, clk);
input clk;
input [3:0] BCD0,BCD1,BCD2,BCD3;
output reg[3:0] DIGIT;
output reg[0:6] DISPLAY;
reg[3:0] value;

always@(posedge clk) begin
    case (DIGIT)
    4'b1110: begin
     value = BCD1;
     DIGIT = 4'b1101;
    end
    4'b1101: begin
     value = BCD2;
     DIGIT = 4'b1011;
    end
    4'b1011: begin
     value = BCD3;
     DIGIT = 4'b0111;
    end
    4'b0111: begin
     value = BCD0;
     DIGIT = 4'b1110;
    end
    default : begin
     value = BCD0;
     DIGIT = 4'b1110;
    end
    endcase
end

always @* begin
    case (value)
 4'd0: DISPLAY = 7'b0000001;
 4'd1: DISPLAY = 7'b1001111;
 4'd2: DISPLAY = 7'b0010010;
 4'd3: DISPLAY = 7'b0000110;
 4'd4: DISPLAY = 7'b1001100;
 4'd5: DISPLAY = 7'b0100100;
 4'd6: DISPLAY = 7'b0100000;
 4'd7: DISPLAY = 7'b0001111;
 4'd8: DISPLAY = 7'b0000000;
 4'd9: DISPLAY = 7'b0000100;
 default: DISPLAY = 7'b1111111;
endcase
end
endmodule
/////////////////////////////////////////////////
module clock_divider #(parameter n = 25) (clk, clk_div);

    input clk;
    output reg clk_div;
    reg [n-1:0] num, num_next;
    
    always@(posedge clk) begin
        num = num_next;
    end
    
    always@* begin
        num_next = num + 1;
        clk_div = num[n-1];
    end

endmodule
////////////////////////////////////////////////

module KeyboardDecoder(
	output reg [511:0] key_down,
	output wire [8:0] last_change,
	output reg key_valid,
	inout wire PS2_DATA,
	inout wire PS2_CLK,
	input wire rst,
	input wire clk
    );
    
    parameter [1:0] INIT			= 2'b00;
    parameter [1:0] WAIT_FOR_SIGNAL = 2'b01;
    parameter [1:0] GET_SIGNAL_DOWN = 2'b10;
    parameter [1:0] WAIT_RELEASE    = 2'b11;
    
	parameter [7:0] IS_INIT			= 8'hAA;
    parameter [7:0] IS_EXTEND		= 8'hE0;
    parameter [7:0] IS_BREAK		= 8'hF0;
    
    reg [9:0] key;		// key = {been_extend, been_break, key_in}
    reg [1:0] state;
    reg been_ready, been_extend, been_break;
    
    wire [7:0] key_in;
    wire is_extend;
    wire is_break;
    wire valid;
    wire err;
    
    wire [511:0] key_decode = 1 << last_change;
    assign last_change = {key[9], key[7:0]};
    
    KeyboardCtrl_0 inst (
		.key_in(key_in),
		.is_extend(is_extend),
		.is_break(is_break),
		.valid(valid),
		.err(err),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
	
	OnePulse op (
		.signal_single_pulse(pulse_been_ready),
		.signal(been_ready),
		.clock(clk)
	);
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		state <= INIT;
    		been_ready  <= 1'b0;
    		been_extend <= 1'b0;
    		been_break  <= 1'b0;
    		key <= 10'b0_0_0000_0000;
    	end else begin
    		state <= state;
			been_ready  <= been_ready;
			been_extend <= (is_extend) ? 1'b1 : been_extend;
			been_break  <= (is_break ) ? 1'b1 : been_break;
			key <= key;
    		case (state)
    			INIT : begin
    					if (key_in == IS_INIT) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready  <= 1'b0;
							been_extend <= 1'b0;
							been_break  <= 1'b0;
							key <= 10'b0_0_0000_0000;
    					end else begin
    						state <= INIT;
    					end
    				end
    			WAIT_FOR_SIGNAL : begin
    					if (valid == 0) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready <= 1'b0;
    					end else begin
    						state <= GET_SIGNAL_DOWN;
    					end
    				end
    			GET_SIGNAL_DOWN : begin
						state <= WAIT_RELEASE;
						key <= {been_extend, been_break, key_in};
						been_ready  <= 1'b1;
    				end
    			WAIT_RELEASE : begin
    					if (valid == 1) begin
    						state <= WAIT_RELEASE;
    					end else begin
    						state <= WAIT_FOR_SIGNAL;
    						been_extend <= 1'b0;
    						been_break  <= 1'b0;
    					end
    				end
    			default : begin
    					state <= INIT;
						been_ready  <= 1'b0;
						been_extend <= 1'b0;
						been_break  <= 1'b0;
						key <= 10'b0_0_0000_0000;
    				end
    		endcase
    	end
    end
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		key_valid <= 1'b0;
    		key_down <= 511'b0;
    	end else if (key_decode[last_change] && pulse_been_ready) begin
    		key_valid <= 1'b1;
    		if (key[8] == 0) begin
    			key_down <= key_down | key_decode;
    		end else begin
    			key_down <= key_down & (~key_decode);
    		end
    	end else begin
    		key_valid <= 1'b0;
			key_down <= key_down;
    	end
    end

endmodule

///////////////////////////////////////////////
module create_large_pulse( clk, small_pulse , large_pulse);
input clk;
input small_pulse;
output large_pulse;
parameter waiting = 1'b0;
parameter counting = 1'b1;
reg state,next;
reg[15:0] counter, counter_next;


always @(posedge clk ) begin
        state <= next;
        counter <= counter_next;
end

always @* begin
    if ( state == waiting) begin
        if( small_pulse) begin
            next = counting;
            counter_next = 1;
        end
        else begin
            next = waiting;
            counter_next = 0;
        end
    end
    else begin
        if( counter != 0 ) begin
            counter_next = counter + 1;
            next = counting;
        end
        else begin
            counter_next = 0;
            next = waiting;
        end
    end
end

assign large_pulse = ( counter != 0) ? 1:0;

endmodule
//////////////////////

///////////////////////

module timer( clk, rst, DIGIT , DISPLAY , PS2_DATA, PS2_CLK , START, END , sw0 , stop);
input sw0, stop;
inout wire PS2_DATA;
inout wire PS2_CLK;
input clk, rst;
output [3:0] DIGIT; 
output [6:0] DISPLAY;
output reg START,END;
wire clk1,clk13;
clock_1sec clk_1sec_produce(clk ,clk1);
clock_divider #(13) c0( clk, clk13);
reg timeup;

reg [3:0] BCD3, BCD2, BCD1, BCD0;
seven_decoder seven0 (DISPLAY, DIGIT, BCD3, BCD2, BCD1, BCD0, clk13);

// input control
parameter [8:0] KEY_CODES [0: 21] = {
        9'b0_0100_0101,	// 0 => 45
		9'b0_0001_0110,	// 1 => 16
		9'b0_0001_1110,	// 2 => 1E
		9'b0_0010_0110,	// 3 => 26
		9'b0_0010_0101,	// 4 => 25
		9'b0_0010_1110,	// 5 => 2E
		9'b0_0011_0110,	// 6 => 36
		9'b0_0011_1101,	// 7 => 3D
		9'b0_0011_1110,	// 8 => 3E
		9'b0_0100_0110,	// 9 => 46
		
		9'b0_0111_0000, // right_0 => 70
		9'b0_0110_1001, // right_1 => 69
		9'b0_0111_0010, // right_2 => 72
		9'b0_0111_1010, // right_3 => 7A
		9'b0_0110_1011, // right_4 => 6B
		9'b0_0111_0011, // right_5 => 73
		9'b0_0111_0100, // right_6 => 74
		9'b0_0110_1100, // right_7 => 6C
		9'b0_0111_0101, // right_8 => 75
		9'b0_0111_1101,  // right_9 => 7D
		9'b0_0101_1010,  //enter => 5A
		9'b0_0111_0110   //ESC => 76
};

wire [511:0] key_down;
wire [8:0] last_change;
wire key_valid;
reg start,cancel;
reg [3:0] key_num;
reg [7:0] nums;

always @(posedge clk or posedge rst) begin
    if( rst) begin
        start <= 0;
        cancel <= 0;
        nums <= 16'b0;
    end
    else begin
        start = 0;
        //cancel = 0;
        if( key_valid && key_down[last_change] == 1) begin
            if( key_num != 4'b1111) begin
                nums <= {nums[3:0], key_num};
            end
            else begin
                if( last_change == KEY_CODES[20] ) start = 1;
                else start = 0;
                if( last_change == KEY_CODES[21] ) cancel = 1;
                else cancel = 0;
            end
        end
    end
end

KeyboardDecoder key_de( key_down, last_change , key_valid, PS2_DATA, PS2_CLK, rst, clk);

always @ (*) begin
	case (last_change)
		KEY_CODES[00] : key_num = 4'b0000;
		KEY_CODES[01] : key_num = 4'b0001;
		KEY_CODES[02] : key_num = 4'b0010;
		KEY_CODES[03] : key_num = 4'b0011;
		KEY_CODES[04] : key_num = 4'b0100;
		KEY_CODES[05] : key_num = 4'b0101;
		KEY_CODES[06] : key_num = 4'b0110;
		KEY_CODES[07] : key_num = 4'b0111;
		KEY_CODES[08] : key_num = 4'b1000;
		KEY_CODES[09] : key_num = 4'b1001;
		KEY_CODES[10] : key_num = 4'b0000;
		KEY_CODES[11] : key_num = 4'b0001;
		KEY_CODES[12] : key_num = 4'b0010;
		KEY_CODES[13] : key_num = 4'b0011;
		KEY_CODES[14] : key_num = 4'b0100;
		KEY_CODES[15] : key_num = 4'b0101;
		KEY_CODES[16] : key_num = 4'b0110;
		KEY_CODES[17] : key_num = 4'b0111;
		KEY_CODES[18] : key_num = 4'b1000;
		KEY_CODES[19] : key_num = 4'b1001;
		default		  : key_num = 4'b1111;
	endcase
end
wire start_ , cancel_;
create_large_pulse lp0( clk , start , start_);
create_large_pulse lp1( clk , cancel , cancel_);

parameter [1:0] NORMAL = 2'b00 , IDLE = 2'b01 , COUNT = 2'b11;
reg[1:0] state;
reg[1:0] state_next;
reg [3:0]N_BCD3, N_BCD2, N_BCD1, N_BCD0;
reg clk_;
always @* begin
    if ( state == IDLE || state == NORMAL) clk_ = clk;
    else clk_ = clk1;
end

always@* begin
    START = 0;
    END = 0;
    if( state == COUNT) START = 1;
    if( state == IDLE ) END = 1;

end

always @(posedge clk_ or posedge rst) begin
    if( rst) begin
        state <= 0;
        BCD3 <= 0;
        BCD2 <= 0; 
        BCD1 <= 0;
        BCD0 <= 0;
    end
    else begin
        state <= state_next;
        BCD3 <= N_BCD3;
        BCD2 <= N_BCD2;
        BCD1 <= N_BCD1;
        BCD0 <= N_BCD0;
    end
end
always @(*) begin
    N_BCD3 = BCD3;
    N_BCD2 = BCD2; 
    N_BCD1 = BCD1;
    N_BCD0 = BCD0;
    case( state) 
      IDLE : begin
                state_next = IDLE;
                if( !sw0 || stop) state_next = NORMAL;
            end
      NORMAL: begin
                state_next = NORMAL;
                N_BCD3 = nums[7:4];
                N_BCD2 = nums[3:0];
                if( start_) begin 
                    state_next = COUNT;
                    if( nums[3:0] != 0) N_BCD2 = nums[3:0] -1;
                    else begin
                        N_BCD3 = nums[7:4] -1;
                        N_BCD2 = 4'd9;
                    end
                    N_BCD1 = 4'd5;
                    N_BCD0 = 4'd9;
                end
              end
      COUNT: begin
           state_next = COUNT;
           timeup = 0;
           if( BCD0 == 0 && (BCD1 != 0 || BCD2 != 0 || BCD3 != 0)) begin
                N_BCD0 = 4'd9;
           end
           else if ( BCD1 == 0 && BCD2 == 0 && BCD3 == 0 && BCD0 == 0) N_BCD0 = 0;
           else N_BCD0 = BCD0 -1;
           
           if( BCD0 == 0) begin
                 if ( BCD1 == 0 ) N_BCD1 = 4'd5;
                 else if ( BCD2 == 0  && BCD1 == 0 && BCD3 == 0) N_BCD1 = 0;
                 else N_BCD1 = BCD1-1;
           end
           
           if ( BCD1 == 0 && BCD0 == 0) begin
               if (BCD2 == 0) N_BCD2 = 4'd9;
               else if ( BCD3 == 0 && BCD2 == 0 && BCD1 == 0 && BCD0 == 0) N_BCD2 = 0;
               else N_BCD2 = BCD2 - 1;
           end
             
           if( BCD2 == 0 && BCD1 == 0 && BCD0 == 0) begin
                 if( BCD3 == 0  )timeup = 1;
                 else begin
                    timeup = 0;
                    N_BCD3 = BCD3 - 1;
                 end
            end
            
             
           if( timeup || cancel_) begin
                 state_next = IDLE;
                 N_BCD3 = 0;
                 N_BCD2 = 0; 
                 N_BCD1 = 0;
                 N_BCD0 = 0;
           end
         end
     endcase
end

endmodule
