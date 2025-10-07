module tb_uart;
    // Parameters for the testbench
    localparam CLOCK_PERIOD   = 20;    // Simulates a 50MHz clock (1 / 50MHz = 20ns)
    localparam BAUD_RATE      = 9600;
    localparam CLKS_PER_BIT   = 50_000_000 / BAUD_RATE;

    // Testbench signals to drive the design
    reg        i_clk;
    reg        i_rst;
    reg [7:0]  i_tx_data;
    reg        i_tx_start;

    // Wires to monitor the design's outputs
    wire       o_tx_serial;
    wire       o_tx_busy;
    wire [7:0] o_rx_data;
    wire       o_rx_dv;

    // Instantiate the Transmitter (Device Under Test - DUT)
    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut_tx (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_tx_data(i_tx_data),
        .i_tx_start(i_tx_start),
        .o_tx_serial(o_tx_serial),
        .o_tx_busy(o_tx_busy)
    );

    // Instantiate the Receiver (DUT)
    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut_rx (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rx_serial(o_tx_serial), // Loopback Tx output to Rx input
        .o_rx_data(o_rx_data),
        .o_rx_dv(o_rx_dv)
    );

    // Clock generation block
    initial begin
        i_clk = 0;
        forever #(CLOCK_PERIOD / 2) i_clk = ~i_clk;
    end

    // Test sequence block
    initial begin
        // Open a file to dump waveforms for viewing
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_uart);

        // 1. Reset the system
        i_rst      = 1;
        i_tx_start = 0;
        i_tx_data  = 8'h00;
        # (CLOCK_PERIOD * 10);
        i_rst = 0;
        # (CLOCK_PERIOD * 10);

        // 2. Test Case 1: Send the ASCII character 'H' (0x48)
        $display("TEST: Sending 8'h48 ('H')...");
        i_tx_data = 8'h48;
        i_tx_start = 1;
        #CLOCK_PERIOD;
        i_tx_start = 0;
        wait (o_tx_busy == 0); // Wait for the transmitter to finish
        $display("INFO: Transmission finished.");
        # (CLOCK_PERIOD * 10); // Wait a bit for the receiver to process

        // 3. Test Case 2: Send the ASCII character 'i' (0x69)
        $display("TEST: Sending 8'h69 ('i')...");
        i_tx_data = 8'h69;
        i_tx_start = 1;
        #CLOCK_PERIOD;
        i_tx_start = 0;
        wait (o_tx_busy == 0);
        $display("INFO: Transmission finished.");
        # (CLOCK_PERIOD * 10);
        
        $display("--- TEST COMPLETE ---");
        $finish;
    end

    // This block continuously monitors for received data
    always @(posedge i_clk) begin
        if (o_rx_dv) begin // Check if the data valid flag is high
            if (o_rx_data == 8'h48 || o_rx_data == 8'h69) begin
                $display("SUCCESS: Received data 0x%h at time %0t", o_rx_data, $time);
            end else begin
                $display("ERROR: Received unexpected data 0x%h at time %0t", o_rx_data, $time);
            end
        end
    end

endmodule
