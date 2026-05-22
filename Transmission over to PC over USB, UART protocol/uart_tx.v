module uart_tx#(
    parameter  CLK_FREQ = 27000000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx = 1'b1,
    output reg tx_busy = 0
);

localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
reg [31:0] baud_counter = 0;
reg [3:0] bit_counter = 0;
reg [9:0] shift_reg = 10'b1111111111;

always @(posedge clk) begin
    if (!tx_busy)begin
        tx <= 1'b1;
        baud_counter <= 0;
        bit_counter <= 0;
        if(tx_start)begin
            shift_reg <= {1'b1, tx_data , 1'b0};
            tx_busy <= 1'b1;
        end
    end else begin
        tx <= shift_reg[0];
        if(baud_counter < CLKS_PER_BIT -1)begin
            baud_counter <= baud_counter + 1;
        end else begin
            baud_counter <= 0;
            shift_reg <= {1'b1, shift_reg[9:1]};
            if(bit_counter <9)begin
                bit_counter <= bit_counter + 1;
            end else begin
                tx_busy <= 0;
                tx <= 1'b1;
            end
        end
    end
end

endmodule