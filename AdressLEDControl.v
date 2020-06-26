
module SigGen(
    input wire [5:0] clk64
    , output wire out
);

    parameter TRESHHOLD = 19;
    
    assign out = clk64 <= TRESHHOLD;

endmodule

module PixLineTransmitter(input rst
    , input clk
    , input go
    , input signalPos
    , input signalNeg
    , input [5:0] cnt64
    , input [23:0] pixel
    , output out
    , output reg ready);
    
    localparam RESET = 6'b1xx
        , CONTINUE = 6'b011;
    
    wire [2:0] state;
    reg [4:0] bits_send;
    reg [23:0] pixel_reg;
    reg reset;
    wire startPos;
    wire done;
    reg preaq;
    reg cbit;
    reg started;
    
    wire last;
    
    
    assign last = bits_send == 23;
    assign state = {rst, go, startPos};
    assign startPos = cnt64 == 0;
    assign out = started ? (cbit ? signalPos : signalNeg) : 0;
    
    
    always @(posedge clk) begin
    
        if (last) begin
            pixel_reg <= pixel;
        end
        
        casex (state)
            RESET: begin
                bits_send <= 0;
                cbit <= 0;
                pixel_reg <= pixel;
                ready <= 0;
                started <= 0;
            end
            CONTINUE: begin
                started <= 1;
                cbit <= pixel_reg[bits_send];
                if (bits_send < 23) begin
                    bits_send <= bits_send + 1;
                    ready <= bits_send == 22;
                end else begin
                    bits_send <= 0;
                end
            end
        endcase
    end
    
endmodule

module linetransmitter(input clk
    , input rst
    , input [ADD_WIDTH - 1:0] pixel_count
    , input [23:0] pixel
    , output [ADD_WIDTH - 1:0] address
    , output out
    , output done);
    
    parameter ADD_WIDTH = 3;
    
    localparam RESET = 3'b1xx
    , DATA_SENDING = 3'b000
    , RESET_SENDING = 3'b010;
    
    reg [ADD_WIDTH - 1:0] addressReg;
    reg [ADD_WIDTH:0] sentCnt;
    reg [5:0] resetCnt;
    reg acquiring;
    reg [5:0] clk64;
    reg readyp;
    reg reset;
    reg wasreset;
    reg [4:0] bitsLeft;
    reg fin;
    
    wire dataSent;
    wire resetDone;
    wire [2:0] state;
    wire startPos;
    wire ready;
    wire pixout;
    wire pos;
    wire neg;
    
    assign dataSent = sentCnt - 1 == pixel_count;
    assign resetDone = resetCnt == 6'd40;
    assign state = {rst, dataSent, resetDone};
    assign startPos = clk64 == 0;
    assign address = addressReg;
    assign out = dataSent ? 0 : (fin ? 0 : pixout);
    
    always @(posedge clk) begin
        acquiring <= ~ready;
        if (~rst) begin
            clk64 <= clk64 + 1'b1;
        end
        if (reset) begin
            reset <= 0;
        end
    
        casex (state)
            RESET: begin
                clk64 <= 0;
                resetCnt <= 0;
                addressReg <= 0;
                sentCnt <= 0;
                readyp <= 0;
                reset <= 1;
            end
            DATA_SENDING: begin
                if (ready && acquiring) begin
                    addressReg <= addressReg + 1'b1;
                    sentCnt <= sentCnt + 1'b1;
                end
                if (sentCnt == pixel_count & startPos) begin
                    if (bitsLeft > 0) begin 
                        bitsLeft <= bitsLeft - 1;
                    end
                end else if (sentCnt < pixel_count) begin
                    bitsLeft <= 23;
                    fin <= 0;
                end else if (~fin) begin
                    fin <= (bitsLeft == 0) && (clk64 > 60);
                end
                
            end
            RESET_SENDING: begin
                if (ready) begin
                    resetCnt <= resetCnt + 1'b1;
                end
            end
        
        endcase
    end
    
    SigGen #(19) pg(.clk64(clk64), .out(neg));
    SigGen #(42) ng(.clk64(clk64), .out(pos));
    
    PixLineTransmitter pt(.rst(reset), .clk(clk), .go(1'b1), .signalPos(pos), .signalNeg(neg), .cnt64(clk64), .pixel(pixel), .out(pixout), .ready(ready));

endmodule

module main();

    reg S, R, clk, rst, b;
    wire out, ready;
    wire pos, neg;
    wire Q, Q1;
    
    reg [3:0] dataCnt;
    reg [23:0] data [5:0];
    
    reg [5:0] clk64;
    
    wire [23:0] pixel;
    wire [1:0] address;
    
    assign pixel = data[address];
    
linetransmitter lt(.clk(clk), .rst(rst), .pixel_count(4), .pixel(pixel), .address(address), .out(out), .done(ready));
    
    always begin
        #10 clk <= ~clk;
    end
    
    always @(posedge ready) begin
        dataCnt <= dataCnt + 1;
    end
    
    always @(posedge clk) begin
        clk64 <= clk64 + 1;
    end
    
    initial begin
        data[0] <= 24'hAAAAAA;
        data[1] <= 24'hFFFFFF;
        data[2] <= 24'hAAAAAA;
        data[3] <= 24'h000000;
        data[4] <= 24'hAAAAAA;
        data[5] <= 24'h000000;
        $dumpfile("addwire.vcd");
        $dumpvars;
        dataCnt <= 0;
        clk64<= 0;
        b <= 1;
        clk <= 0;
        rst <= 1;
        #30 rst <= 0; clk64 <= 0;
        #1300 b <= 0;
        #200000 $finish;
    end
   
endmodule
