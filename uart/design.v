// CORRECTED UART Transmitter
module uart_tx #(
    parameter CLKS_PER_BIT = 5208
) (
    input  wire        i_clk,
    input  wire        i_rst,
    input  wire [7:0]  i_tx_data,
    input  wire        i_tx_start,
    output wire        o_tx_serial,
    output wire        o_tx_busy
);

    // State machine definitions
    localparam STATE_IDLE      = 2'b00;
    localparam STATE_START_BIT = 2'b01;
    localparam STATE_DATA_BITS = 2'b10;
    localparam STATE_STOP_BIT  = 2'b11;

    // Internal Registers
    reg [1:0]  r_state;
    reg [15:0] r_clk_counter;
    reg [2:0]  r_bit_index;
    reg [9:0]  r_tx_shift_reg;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_state       <= STATE_IDLE;
            r_clk_counter <= 0;
            r_bit_index   <= 0;
        end else begin
            // Main FSM
            case (r_state)
                STATE_IDLE: begin
                    if (i_tx_start) begin
                        r_state       <= STATE_START_BIT;
                        r_clk_counter <= 0;
                        r_tx_shift_reg <= {1'b1, i_tx_data, 1'b0}; // {Stop, Data, Start}
                    end else begin
                        r_clk_counter <= 0;
                    end
                end

                STATE_START_BIT: begin
                    if (r_clk_counter < CLKS_PER_BIT - 1) begin
                        r_clk_counter <= r_clk_counter + 1;
                    end else begin
                        r_clk_counter <= 0;
                        r_state     <= STATE_DATA_BITS;
                        r_bit_index <= 0;
                        r_tx_shift_reg <= r_tx_shift_reg >> 1; // Shift out start bit
                    end
                end

                STATE_DATA_BITS: begin
                    if (r_clk_counter < CLKS_PER_BIT - 1) begin
                        r_clk_counter <= r_clk_counter + 1;
                    end else begin
                        r_clk_counter <= 0;
                        r_tx_shift_reg <= r_tx_shift_reg >> 1; // Shift out data bit
                        if (r_bit_index < 7) begin
                            r_bit_index <= r_bit_index + 1;
                        end else begin
                            r_state <= STATE_STOP_BIT;
                        end
                    end
                end

                STATE_STOP_BIT: begin
                    if (r_clk_counter < CLKS_PER_BIT - 1) begin
                        r_clk_counter <= r_clk_counter + 1;
                    end else begin
                        r_clk_counter <= 0;
                        r_state <= STATE_IDLE;
                    end
                end

                default: r_state <= STATE_IDLE;
            endcase
        end
    end

    assign o_tx_serial = (r_state == STATE_IDLE) ? 1'b1 : r_tx_shift_reg[0];
    assign o_tx_busy   = (r_state != STATE_IDLE);

endmodule


// A simple UART Receiver for 8-N-1 format
module uart_rx #(
    parameter CLKS_PER_BIT = 5208
) (
    input  wire        i_clk,
    input  wire        i_rst,
    input  wire        i_rx_serial,
    output reg  [7:0]  o_rx_data,
    output reg         o_rx_dv // Data Valid signal
);

    // State machine definitions
    localparam STATE_IDLE      = 2'b00;
    localparam STATE_START_BIT = 2'b01;
    localparam STATE_DATA_BITS = 2'b10;
    localparam STATE_STOP_BIT  = 2'b11;

    // Internal Registers
    reg [1:0]  r_state;
    reg [15:0] r_clk_counter;
    reg [2:0]  r_bit_index;
    reg [7:0]  r_rx_shift_reg;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_state       <= STATE_IDLE;
            r_clk_counter <= 0;
            o_rx_dv       <= 1'b0;
        end else begin
            // Default assignment to de-assert data valid after one cycle
            o_rx_dv <= 1'b0;

            // Main FSM
            case (r_state)
                STATE_IDLE: begin
                    if (i_rx_serial == 1'b0) begin
                        // Potential start bit detected
                        r_state       <= STATE_START_BIT;
                        r_clk_counter <= 0;
                    end
                end

                STATE_START_BIT: begin
                    // Wait until the middle of the bit period to sample
                    if (r_clk_counter == (CLKS_PER_BIT / 2)) begin
                        if (i_rx_serial == 1'b0) begin
                            // Confirmed start bit, move to data
                            r_state       <= STATE_DATA_BITS;
                            r_clk_counter <= 0;
                            r_bit_index   <= 0;
                        end else begin
                            // False start bit, go back to idle
                            r_state <= STATE_IDLE;
                        end
                    end else begin
                        r_clk_counter <= r_clk_counter + 1;
                    end
                end

                STATE_DATA_BITS: begin
                    if (r_clk_counter >= CLKS_PER_BIT - 1) begin
                        r_clk_counter <= 0;
                        // Sample the data bit and shift it in
                        r_rx_shift_reg <= {i_rx_serial, r_rx_shift_reg[7:1]};
                        
                        if (r_bit_index == 7) begin
                            r_state <= STATE_STOP_BIT;
                        end else begin
                            r_bit_index <= r_bit_index + 1;
                        end
                    end else begin
                        r_clk_counter <= r_clk_counter + 1;
                    end
                end

                STATE_STOP_BIT: begin
                    if (r_clk_counter >= CLKS_PER_BIT - 1) begin
                        // Check for a valid stop bit (must be '1')
                        if (i_rx_serial == 1'b1) begin
                            o_rx_data <= r_rx_shift_reg;
                            o_rx_dv   <= 1'b1; // Signal that data is valid for one cycle
                        end
                        r_state <= STATE_IDLE;
                    end else begin
                        r_clk_counter <= r_clk_counter + 1;
                    end
                end

                default: r_state <= STATE_IDLE;
            endcase
        end
    end
endmodule
