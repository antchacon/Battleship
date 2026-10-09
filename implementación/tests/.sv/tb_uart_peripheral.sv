`timescale 1ns/1ps

module tb_uart_peripheral;

    localparam int CLK_FREQ  = 100_000_000;
    localparam int BAUD_RATE = 10_000_000;
    localparam int BIT_CLKS  = CLK_FREQ / BAUD_RATE;

    localparam logic [1:0] CONTROL = 2'b00;
    localparam logic [1:0] DATA_TX = 2'b01;
    localparam logic [1:0] DATA_RX = 2'b10;

    logic clk_i = 0;
    logic rst_i;
    logic write_enable_i;
    logic [1:0] addr_i;
    logic [31:0] wdata_i;
    logic [31:0] rdata_o;
    logic uart_rx_i;
    logic uart_tx_o;

    integer errors = 0;

    uart_peripheral #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk_i,
        .rst_i,
        .write_enable_i,
        .addr_i,
        .wdata_i,
        .rdata_o,
        .uart_rx_i,
        .uart_tx_o
    );

    always #5 clk_i = ~clk_i;


    task write_reg(
        input logic [1:0] addr,
        input logic [31:0] data
    );
        begin
            @(negedge clk_i);
            addr_i = addr;
            wdata_i = data;
            write_enable_i = 1;

            @(negedge clk_i);
            write_enable_i = 0;
        end
    endtask


    task check_reg(
        input logic [1:0] addr,
        input logic [31:0] expected,
        input logic [31:0] mask,
        input string name
    );
        begin
            addr_i = addr;
            #1;

            if ((rdata_o & mask) !== (expected & mask)) begin
                $display("ERROR: %s", name);
                errors++;
            end
            else
                $display("PASS: %s", name);
        end
    endtask


    task send_rx(input logic [7:0] data);
        integer i;
        begin
            uart_rx_i = 0;
            repeat(BIT_CLKS) @(posedge clk_i);

            for (i = 0; i < 8; i++) begin
                uart_rx_i = data[i];
                repeat(BIT_CLKS) @(posedge clk_i);
            end

            uart_rx_i = 1;
            repeat(BIT_CLKS + 3) @(posedge clk_i);
        end
    endtask


    task check_tx(input logic [7:0] expected);
        integer i;
        begin
            wait(uart_tx_o == 0);

            repeat(BIT_CLKS/2) @(posedge clk_i);

            if (uart_tx_o !== 0)
                errors++;

            for (i = 0; i < 8; i++) begin
                repeat(BIT_CLKS) @(posedge clk_i);

                if (uart_tx_o !== expected[i]) begin
                    $display("ERROR: TX bit %0d", i);
                    errors++;
                end
            end

            repeat(BIT_CLKS) @(posedge clk_i);

            if (uart_tx_o !== 1) begin
                $display("ERROR: Stop bit");
                errors++;
            end
        end
    endtask


    initial begin

        rst_i = 1;
        write_enable_i = 0;
        addr_i = CONTROL;
        wdata_i = 0;
        uart_rx_i = 1;

        repeat(4) @(posedge clk_i);
        rst_i = 0;
        repeat(2) @(posedge clk_i);


        // RESET
        check_reg(CONTROL, 0, 32'h3, "Reset");


        // TX
        write_reg(DATA_TX, 32'hA5);

        fork
            check_tx(8'hA5);

            begin
                write_reg(CONTROL, 32'h1);

                repeat(2) @(posedge clk_i);

                check_reg(
                    CONTROL,
                    32'h1,
                    32'h1,
                    "tx_busy activo"
                );
            end
        join

        addr_i = CONTROL;
        wait(rdata_o[0] == 0);

        check_reg(
            CONTROL,
            0,
            32'h1,
            "tx_busy finalizado"
        );


        // RX
        send_rx(8'h3C);

        check_reg(
            CONTROL,
            32'h2,
            32'h2,
            "new_rx activo"
        );

        check_reg(
            DATA_RX,
            32'h3C,
            32'hFF,
            "Dato RX"
        );


        // LIMPIAR new_rx
        write_reg(CONTROL, 32'h2);

        check_reg(
            CONTROL,
            0,
            32'h2,
            "new_rx limpio"
        );


        if (errors == 0)
            $display("\nTODAS LAS PRUEBAS PASARON");
        else
            $display("\nERRORES: %0d", errors);

        $finish;

    end

endmodule