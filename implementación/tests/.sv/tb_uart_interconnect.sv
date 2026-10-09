`timescale 1ns/1ps

module tb_uart_interconnect;

    localparam int CLK_FREQ  = 100_000_000;
    localparam int BAUD_RATE = 10_000_000;
    localparam int BIT_CLKS  = CLK_FREQ / BAUD_RATE;

    localparam logic [31:0] UART_CTRL = 32'h0001_0040;
    localparam logic [31:0] UART_TX   = 32'h0001_0044;
    localparam logic [31:0] UART_RX   = 32'h0001_0048;

    logic clk_i = 0;
    logic rst_i;

    // Bus del procesador
    logic [31:0] data_address_i;
    logic [31:0] data_out_i;
    logic        data_we_i;
    logic [31:0] data_in_o;

    // Conexión Interconnect -> UART
    logic [1:0]  uart_addr;
    logic [31:0] uart_wdata;
    logic        uart_we;
    logic [31:0] uart_rdata;

    logic uart_rx_i;
    logic uart_tx_o;

    // Señales no utilizadas en esta prueba
    logic [31:0] ram_addr;
    logic [31:0] ram_wdata;
    logic        ram_we;

    logic [1:0]  ind_addr;
    logic [31:0] ind_wdata;
    logic        ind_we;

    logic [8:0]  vga_addr;
    logic [31:0] vga_wdata;
    logic        vga_we;

    integer errors = 0;


    // =====================================================
    // INTERCONNECT
    // =====================================================

    memory_interconnect interconnect_dut (
        .data_address_i (data_address_i),
        .data_out_i     (data_out_i),
        .data_we_i      (data_we_i),
        .data_in_o      (data_in_o),

        .ram_addr_o     (ram_addr),
        .ram_wdata_o    (ram_wdata),
        .ram_we_o       (ram_we),
        .ram_rdata_i    (32'b0),

        .uart_addr_o    (uart_addr),
        .uart_wdata_o   (uart_wdata),
        .uart_we_o      (uart_we),
        .uart_rdata_i   (uart_rdata),

        .j1_rdata_i     (32'b0),

        .ind_addr_o     (ind_addr),
        .ind_wdata_o    (ind_wdata),
        .ind_we_o       (ind_we),
        .ind_rdata_i    (32'b0),

        .vga_addr_o     (vga_addr),
        .vga_wdata_o    (vga_wdata),
        .vga_we_o       (vga_we),
        .vga_rdata_i    (32'b0)
    );


    // =====================================================
    // UART
    // =====================================================

    uart_peripheral #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) uart_dut (
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .write_enable_i (uart_we),
        .addr_i         (uart_addr),
        .wdata_i        (uart_wdata),
        .rdata_o        (uart_rdata),

        .uart_rx_i      (uart_rx_i),
        .uart_tx_o      (uart_tx_o)
    );


    always #5 clk_i = ~clk_i;


    // =====================================================
    // ESCRITURA DESDE EL "CPU"
    // =====================================================

    task cpu_write(
        input logic [31:0] addr,
        input logic [31:0] data
    );
        begin
            @(negedge clk_i);

            data_address_i = addr;
            data_out_i     = data;
            data_we_i      = 1;

            @(negedge clk_i);

            data_we_i = 0;
        end
    endtask


    // =====================================================
    // COMPROBAR
    // =====================================================

    task check(
        input logic condition,
        input string name
    );
        begin
            if (condition)
                $display("PASS: %s", name);
            else begin
                $display("ERROR: %s", name);
                errors++;
            end
        end
    endtask


    // =====================================================
    // SIMULAR BYTE EN RX
    // =====================================================

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


    // =====================================================
    // COMPROBAR TX
    // =====================================================

    task check_tx(input logic [7:0] expected);
        integer i;
        begin
            wait(uart_tx_o == 0);

            repeat(BIT_CLKS/2) @(posedge clk_i);

            for (i = 0; i < 8; i++) begin
                repeat(BIT_CLKS) @(posedge clk_i);

                if (uart_tx_o !== expected[i])
                    errors++;
            end

            repeat(BIT_CLKS) @(posedge clk_i);
        end
    endtask


    // =====================================================
    // PRUEBAS
    // =====================================================

    initial begin

        rst_i          = 1;
        data_address_i = 0;
        data_out_i     = 0;
        data_we_i      = 0;
        uart_rx_i      = 1;

        repeat(4) @(posedge clk_i);
        rst_i = 0;
        repeat(2) @(posedge clk_i);


        // =================================================
        // TX USANDO DIRECCIONES GLOBALES
        // =================================================

        cpu_write(UART_TX, 32'h0000_00A5);

        check(
            uart_addr == 2'b01,
            "Direccion global UART TX"
        );


        fork

            check_tx(8'hA5);

            begin
                cpu_write(UART_CTRL, 32'h1);

                data_address_i = UART_CTRL;
                #1;

                check(
                    data_in_o[0] == 1,
                    "tx_busy por MMIO"
                );
            end

        join


        data_address_i = UART_CTRL;

        wait(data_in_o[0] == 0);

        check(
            data_in_o[0] == 0,
            "TX finalizado"
        );


        // =================================================
        // RX
        // =================================================

        send_rx(8'h3C);


        data_address_i = UART_CTRL;
        #1;

        check(
            data_in_o[1] == 1,
            "new_rx por MMIO"
        );


        data_address_i = UART_RX;
        #1;

        check(
            data_in_o[7:0] == 8'h3C,
            "Dato RX por MMIO"
        );


        // =================================================
        // LIMPIAR new_rx
        // =================================================

        cpu_write(UART_CTRL, 32'h2);

        data_address_i = UART_CTRL;
        #1;

        check(
            data_in_o[1] == 0,
            "new_rx limpio"
        );


        // =================================================
        // RESULTADO
        // =================================================

        if (errors == 0)
            $display("\nINTEGRACION UART + INTERCONNECT CORRECTA");
        else
            $display("\nERRORES: %0d", errors);

        $finish;

    end

endmodule