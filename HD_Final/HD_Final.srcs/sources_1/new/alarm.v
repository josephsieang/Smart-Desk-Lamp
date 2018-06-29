`timescale 1ns / 1ps

module clock_divider2 #(parameter n = 25) (clk, clk_div);

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

module debounce (clk, pb, pb_debounced);

    input clk, pb;
    output reg pb_debounced;
    reg [3:0] shift_reg;
    
    always@(posedge clk) begin 
        shift_reg = {shift_reg[2:0], pb};
    end
    
    always@* begin
        if(shift_reg == 4'b1111) begin
            pb_debounced = 1'b1;
        end else begin
            pb_debounced = 1'b0;
        end
   end
    
endmodule

module onepulse (clk, reset, pb_debounced, pb_1pulse);

    input clk, reset, pb_debounced;
    output reg pb_1pulse;
    reg pb_debounced_delay, pb_1pulse_next;
    
    always@(posedge clk, posedge reset) begin
        if(reset == 1'b1) begin
            pb_1pulse = 1'b0;
            pb_debounced_delay = 1'b0;
        end else begin
            pb_1pulse = pb_1pulse_next;
            pb_debounced_delay = pb_debounced;
        end
    end
    
    always@* begin
        pb_1pulse_next = pb_debounced & ~pb_debounced_delay;
    end

endmodule


module PWM_gen2 (
    input wire clk,
    input wire reset,
	input [31:0] freq,
    input [9:0] duty,
    output reg PWM
);

wire [31:0] count_max = 100_000_000 / freq;
wire [31:0] count_duty = count_max * duty / 1024;
reg [31:0] count;
    
always @(posedge clk, posedge reset) begin
    if (reset) begin
        count <= 0;
        PWM <= 0;
    end else if (count < count_max) begin
        count <= count + 1;
		if(count < count_duty)
            PWM <= 1;
        else
            PWM <= 0;
    end else begin
        count <= 0;
        PWM <= 0;
    end
end

endmodule

module ALARM(clk, stop, alarm_mode, music, counter, pmodA1, pmodA2, pmodA4);

    input clk, stop, music, alarm_mode, counter;
    output pmodA1, pmodA2, pmodA4;
    
    parameter BEAT_FREQ = 32'd8;//8 Hz == 0.125s
    parameter DUTY_BEST = 10'd512;//duty cycle = 50%
    
    wire clk_div_16;
    wire stop_debounced;
    wire stop_1pulse;
    
    wire [31:0] freq0;
    wire [31:0] freq1;
    wire [7:0] ibeatNum0;
    wire [7:0] ibeatNum1;
    wire beatFreq;
    reg [31:0] out_freq;
    reg change_music, end_music;
    reg music_delay;//to detect music change
    
    reg [7:0] out_BEATLENGTH;
    parameter LONG_BEATLENGTH = 127;
    parameter SHORT_BEATLENGTH = 31;
    
    reg state, state_next;
    reg [7:0] ibeat, ibeat_next;
    parameter STOP = 1'b0;
    parameter PLAY = 1'b1;
    
    assign pmodA2 = 1'd0; //nogain (6db)
    //mute, STOP state, PAUSE state music control
    assign pmodA4 = (state == STOP) ? 1'b0 : 1'b1;
    
    
    clock_divider2 #(.n(16)) clock_divider_16(
        .clk(clk),
        .clk_div(clk_div_16)
    );
    
    debounce stop_debounce(
        .clk(clk_div_16),
        .pb(stop),
        .pb_debounced(stop_debounced)
    );

    
    onepulse stop_onepulse(
        .clk(clk),
        .pb_debounced(stop_debounced),
        .pb_1pulse(stop_1pulse)
    );

    //generate beat speed
    PWM_gen2 btSpeedGen(
        .clk(clk),
        .freq(BEAT_FREQ),
        .duty(DUTY_BEST),
        .PWM(beatFreq)
    );
    
    //music file
    Music music0(
        .ibeatNum(ibeat),
        .tone(freq0)
    );
    
    Music2 music1(
        .ibeatNum(ibeat),
        .tone(freq1)
    );
    
    //generate particular freq signal
    PWM_gen2 toneGen(
        .clk(clk),
        .freq(out_freq),
        .duty(DUTY_BEST),
        .PWM(pmodA1)
    );
    
    //select music
    always@* begin
        if(music == 1'b0) begin
            out_freq = freq0;
            out_BEATLENGTH = LONG_BEATLENGTH;
        end else begin
            out_freq = freq1;
            out_BEATLENGTH = SHORT_BEATLENGTH;
        end
    end
    
    //detect end music
    always@* begin
        if(ibeat == out_BEATLENGTH) begin
            end_music = 1'b1;
        end else begin
            end_music = 1'b0;
        end
    end
    
    //fsm + manipulate ibeat
    always@(posedge beatFreq) begin
        music_delay = music;
        if(end_music || change_music) begin
            ibeat = 0;
        end else begin
            ibeat = ibeat_next;
        end
    end
    
    //detect music change
    always@* begin
        if(music_delay != music) begin
            change_music = 1'b1;
        end else begin
            change_music = 1'b0;
        end
    end
    
    always@(posedge clk) begin
        state = state_next;
    end

    always@* begin    
        if(state == STOP) begin
             state_next = STOP;
             ibeat_next = 0;
             if(counter == 1'b1 && alarm_mode == 1'b1) begin //use counter in future at here
                 state_next = PLAY;
             end
        end else begin
            if(stop_1pulse == 1'b1) begin
                ibeat_next = 0;
                state_next = STOP;
            end else begin
                ibeat_next = ibeat + 1;
                state_next = PLAY;
            end
        end
    end  


endmodule
