`timescale 1ns / 1ps
// sw0 on/off
// sw1, sw2 control light intensity manually
// sen_1 , sen_2 light intensity data from sensor
// sw3 auto == 1/manual == 0 switch
// sw15 alarm = 0 and countdown = 1
// sw14 music change

module ledcontrol( clk, sw0, sw1, sw2, sw3,  pmod_1, pmod_2, pmod_3, pmod_4, pmod_5, pmod_6, pmod_7, pmod_8 , sen_1 , sen_2 , sw15 , DIGIT, DISPLAY, PS2_DATA, PS2_CLK, button,pmodA1, pmodA2, pmodA4,sw14);

    input clk, sw0, sw1, sw2 , sw3 , sen_1 , sen_2 , sw15,sw14;
    input button;
    output reg pmod_1, pmod_2, pmod_3, pmod_4, pmod_5, pmod_6, pmod_7, pmod_8;
    output wire pmodA1, pmodA2, pmodA4;
    reg pmod1, pmod2, pmod3, pmod4, pmod5, pmod6, pmod7, pmod8;
    reg reset;
    wire pmod_1_, pmod_2_, pmod_3_, pmod_4_, pmod_5_, pmod_6_, pmod_7_, pmod_8_;
    reg alarm, countdown, off;
    inout wire PS2_DATA;
    inout wire PS2_CLK;
    output [3:0] DIGIT; 
    output [6:0] DISPLAY;
    wire stop;
    wire START, END;
    
clock_divider2 #(.n(16)) clock_divide_16(
            .clk(clk),
            .clk_div(clk_div_16)
        );
        
        debounce stop_debounc(
            .clk(clk_div_16),
            .pb(button),
            .pb_debounced(stop_debounced)
        );
    
        
        onepulse stop_onepuls(
            .clk(clk),
            .pb_debounced(stop_debounced),
            .pb_1pulse(stop)
        );
  timer t1( clk, reset, DIGIT , DISPLAY , PS2_DATA, PS2_CLK , START, END , sw0 , button);
  wire alarm_mode;
  assign alarm_mode = ~sw15;
  ALARM alarm1(clk, button, alarm_mode,sw14, alarm, pmodA1, pmodA2, pmodA4);
 
 PWM_gen (
    clk,
    reset,
    pmod1,
    pmod2,
    pmod3,
    pmod4,
    pmod5,
    pmod6,
    pmod7,
    pmod8,
    sw1,
    sw2,
    sw3,
    alarm,
    countdown,
    off,
    pmod_1_,
    pmod_2_,
    pmod_3_,
    pmod_4_,
    pmod_5_,
    pmod_6_,
    pmod_7_,
    pmod_8_,
    sen_1,
    sen_2
);

    parameter [1:0] NORMAL = 2'b00 , ALARM = 2'b01 , COUNTDOWN = 2'b10 , OFF = 2'b11;
    reg [1:0] state, state_next;
    
    always@(posedge clk) begin
        state <= state_next;
    end
    
    
    always@* begin
        if( state == ALARM) begin
            alarm = 1;
            countdown = 0;
            off = 0;
        end
        else if (state == COUNTDOWN) begin
            countdown = 1;
            alarm = 0;
            off = 0;
        end
        else if ( state == OFF) begin
            countdown = 0;
            alarm = 0;
            off = 1;
        end
        else begin
            countdown = 0;
            alarm = 0;
            off = 0;
        end
    end

    always@* begin
        case(state) 
            NORMAL: begin
                state_next = NORMAL;
                if( !sw15 && START) state_next = OFF;
                else if( sw15 && END) state_next = COUNTDOWN;
            end
            ALARM: begin
                state_next = ALARM;
                if( stop) state_next = NORMAL;
                // return to normal
            end
            COUNTDOWN: begin
                state_next = COUNTDOWN;
                if( !sw0) state_next = NORMAL;
            end     
            OFF : begin
                state_next = OFF;
                if( !sw15 && END) state_next = ALARM;
            end
        endcase
    end

always @* begin
    if (sw0) begin
        pmod_1 = pmod_1_;
        pmod_2 = pmod_2_;
        pmod_3 = pmod_3_;
        pmod_4 = pmod_4_;
        pmod_5 = pmod_5_;
        pmod_6 = pmod_6_;
        pmod_7 = pmod_7_;
        pmod_8 = pmod_8_;
    end 
    else begin
        pmod_1 = 0;
        pmod_2 = 0;
        pmod_3 = 0;
        pmod_4 = 0;
        pmod_5 = 0;
        pmod_6 = 0;
        pmod_7 = 0;
        pmod_8 = 0;
    end
end

always@(posedge clk) begin
    if ( sw0) begin
        pmod1 <= 1;
        pmod2 <= 1;
        pmod3 <= 1;
        pmod4 <= 1;
        pmod5 <= 1;
        pmod6 <= 1;
        pmod7 <= 1;
        pmod8 <= 1;
    end
    else begin
        pmod1 <= 0;
        pmod2 <= 0;
        pmod3 <= 0;
        pmod4 <= 0;
        pmod5 <= 0;
        pmod6 <= 0;
        pmod7 <= 0;
        pmod8 <= 0;
    end
end

endmodule

module PWM_gen (
    input wire clk,
    input wire reset,
    input pmod1,
    input pmod2,
    input pmod3,
    input pmod4,
    input pmod5,
    input pmod6,
    input pmod7,
    input pmod8,
    input sw1,
    input sw2,
    input sw3,
    input alarm,
    input countdown,
    input off,
    output reg pmod_1_,
    output reg pmod_2_,
    output reg pmod_3_,
    output reg pmod_4_,
    output reg pmod_5_,
    output reg pmod_6_,
    output reg pmod_7_,
    output reg pmod_8_,
    input sen_1,
    input sen_2
);

reg [31:0] count_max;
reg [31:0] count_duty;
reg [31:0] count;

always@* begin
    count_max = 1500_000;
    if( alarm) begin
        count_max = 1500_000_0;
        count_duty = 50000;
    end
    else if ( countdown) begin
        count_duty = 0;
    end
    
    else if ( off) begin
        count_duty = 0;
    end
    else begin
        if (!sw3) begin
            if(!sw1 && !sw2 ) begin // dark
                count_duty = 75000;
            end else if(!sw1 && sw2 ) begin // medium
                count_duty = 150_000;
            end else if(sw1 && !sw2 ) begin // medium
                count_duty = 150_000;
            end else begin
                count_duty = 375_000; // bright
            end
        end
        else begin
            if (!sen_1 && !sen_2 ) count_duty = 75000;// dark
            else if ( !sen_1 && sen_2 ) count_duty = 150_000; // medium
            else if ( sen_1 && !sen_2 )count_duty = 375_000;// bright
            else count_duty = 0;
        end
    end
end

always @(posedge clk, posedge reset) begin
    if (reset) begin
        count <= 0;
        pmod_1_ <= 0;
        pmod_2_ <= 0;
        pmod_3_ <= 0;
        pmod_4_ <= 0;
        pmod_5_ <= 0;
        pmod_6_ <= 0;
        pmod_7_ <= 0;
        pmod_8_ <= 0;
    end else if (count < count_max) begin
        count <= count + 1;
		if(count < count_duty) begin
            pmod_1_ <= 1;
            pmod_2_ <= 1;
            pmod_3_ <= 1;
            pmod_4_ <= 1;
            pmod_5_ <= 1;
            pmod_6_ <= 1;
            pmod_7_ <= 1;
            pmod_8_ <= 1;
        end else begin
            pmod_1_ <= 0;
            pmod_2_ <= 0;
            pmod_3_ <= 0;
            pmod_4_ <= 0;
            pmod_5_ <= 0;
            pmod_6_ <= 0;
            pmod_7_ <= 0;
            pmod_8_ <= 0;
        end
    end else begin
        count <= 0;
        pmod_1_ <= 0;
        pmod_2_ <= 0;
        pmod_3_ <= 0;
        pmod_4_ <= 0;
        pmod_5_ <= 0;
        pmod_6_ <= 0;
        pmod_7_ <= 0;
        pmod_8_ <= 0;
    end
end

endmodule
