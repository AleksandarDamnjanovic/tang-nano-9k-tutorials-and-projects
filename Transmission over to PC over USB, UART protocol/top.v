module top(
    input wire clk,
    output wire uart_tx
);

parameter  CLK_FREQ = 27000000;
parameter BAUD_RATE = 115200;

reg tx_start = 0;
reg [7:0] tx_data = 0;
wire tx_busy;

uart_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
)uart0(
    .clk(clk),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(uart_tx),
    .tx_busy(tx_busy)
);

reg [7:0] message [0:24];

initial begin
    message[0]= "h";
    message[1]= "e";
    message[2]= "y";
    message[3]= " ";
    message[4]= "f";
    message[5]= "r";
    message[6]= "o";
    message[7]= "m";
    message[8]= " ";
    message[9]= "T";
    message[10]= "A";
    message[11]= "N";
    message[12]= "G";
    message[13]= " ";
    message[14]= "N";
    message[15]= "A";
    message[16]= "N";
    message[17]= "O";
    message[18]= " ";
    message[19]= "9";
    message[20]= "K";
    message[21]= "\r";
    message[22]= "\n";
    message[23]= 8'h00;
end

reg [7:0] char_index = 0;
reg [31:0] pause_counter = 0;
localparam PAUSE = 27000000;
reg [1:0] state = 0;

localparam S_IDLE = 0;
localparam S_START_TX = 1;
localparam S_WAIT_BUSY = 2;
localparam S_NEXT = 3;

always @(posedge clk)begin

    tx_start <= 0;

    case(state)
        S_IDLE: begin
            if(message[char_index]==8'h00)begin
                if(pause_counter < PAUSE)begin
                    pause_counter <= pause_counter + 1;
                end else begin
                    pause_counter <= 0;
                    char_index <= 0;
                end
            end else if(!tx_busy)begin
                tx_data <= message[char_index];
                state <= S_START_TX;
            end
        end

        S_START_TX: begin
            tx_start <= 1;
            state <= S_WAIT_BUSY;
        end

        S_WAIT_BUSY:begin
            if(tx_busy)
                state <= S_NEXT;
        end

        S_NEXT:begin
            if(!tx_busy)begin
                char_index <= char_index + 1;
                state <= S_IDLE;
            end
        end

        default: state <= S_IDLE;
    endcase
end
endmodule