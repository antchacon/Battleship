`timescale 1ns/1ps

module tb_interconnect;

    logic [31:0] data_address_i;
    logic [31:0] data_out_i;
    logic        data_we_i;
    logic [31:0] data_in_o;

    logic [31:0] ram_addr_o;
    logic [31:0] ram_wdata_o;
    logic        ram_we_o;
    logic [31:0] ram_rdata_i;

    logic [1:0]  uart_addr_o;
    logic [31:0] uart_wdata_o;
    logic        uart_we_o;
    logic [31:0] uart_rdata_i;

    logic [31:0] j1_rdata_i;

    logic [1:0]  ind_addr_o;
    logic [31:0] ind_wdata_o;
    logic        ind_we_o;
    logic [31:0] ind_rdata_i;

    logic [8:0]  vga_addr_o;
    logic [31:0] vga_wdata_o;
    logic        vga_we_o;
    logic [31:0] vga_rdata_i;

    integer errors = 0;


    memory_interconnect dut (
        .data_address_i,
        .data_out_i,
        .data_we_i,
        .data_in_o,

        .ram_addr_o,
        .ram_wdata_o,
        .ram_we_o,
        .ram_rdata_i,

        .uart_addr_o,
        .uart_wdata_o,
        .uart_we_o,
        .uart_rdata_i,

        .j1_rdata_i,

        .ind_addr_o,
        .ind_wdata_o,
        .ind_we_o,
        .ind_rdata_i,

        .vga_addr_o,
        .vga_wdata_o,
        .vga_we_o,
        .vga_rdata_i
    );


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


    initial begin

        data_out_i   = 32'h1234_5678;
        data_we_i    = 1'b0;

        ram_rdata_i  = 32'hAAAA_AAAA;
        uart_rdata_i = 32'hBBBB_BBBB;
        j1_rdata_i   = 32'hCCCC_CCCC;
        ind_rdata_i  = 32'hDDDD_DDDD;
        vga_rdata_i  = 32'hEEEE_EEEE;


        // =================================================
        // RAM
        // =================================================

        data_address_i = 32'h0000_2000;
        data_we_i = 1;
        #1;

        check(ram_we_o == 1, "RAM write enable");
        check(ram_addr_o == 32'h0000_2000, "RAM address");
        check(data_in_o == 32'hAAAA_AAAA, "RAM read");


        // =================================================
        // UART CONTROL
        // =================================================

        data_address_i = 32'h0001_0040;
        data_we_i = 1;
        #1;

        check(uart_addr_o == 2'b00, "UART CONTROL");
        check(uart_we_o == 1, "UART write enable");


        // =================================================
        // UART TX
        // =================================================

        data_address_i = 32'h0001_0044;
        #1;

        check(uart_addr_o == 2'b01, "UART TX");


        // =================================================
        // UART RX
        // =================================================

        data_address_i = 32'h0001_0048;
        data_we_i = 0;
        #1;

        check(uart_addr_o == 2'b10, "UART RX");
        check(data_in_o == 32'hBBBB_BBBB, "UART read");


        // =================================================
        // J1
        // =================================================

        data_address_i = 32'h0001_0120;
        #1;

        check(data_in_o == 32'hCCCC_CCCC, "J1 read");


        // =================================================
        // DISPLAY
        // =================================================

        data_address_i = 32'h0001_0130;
        data_we_i = 1;
        #1;

        check(ind_addr_o == 2'b00, "Display address");
        check(ind_we_o == 1, "Display write");


        // =================================================
        // LED
        // =================================================

        data_address_i = 32'h0001_0138;
        #1;

        check(ind_addr_o == 2'b01, "LED address");


        // =================================================
        // BUZZER
        // =================================================

        data_address_i = 32'h0001_0140;
        #1;

        check(ind_addr_o == 2'b10, "Buzzer address");


        // =================================================
        // VGA
        // =================================================

        data_address_i = 32'h0001_1008;
        data_we_i = 1;
        #1;

        check(vga_addr_o == 9'd2, "VGA address");
        check(vga_we_o == 1, "VGA write");
        check(data_in_o == 32'hEEEE_EEEE, "VGA read");


        // =================================================
        // DIRECCIÓN INVÁLIDA
        // =================================================

        data_address_i = 32'hFFFF_FFFF;
        data_we_i = 1;
        #1;

        check(data_in_o == 0, "Invalid address read");
        check(
            !ram_we_o &&
            !uart_we_o &&
            !ind_we_o &&
            !vga_we_o,
            "Invalid address write disable"
        );


        // =================================================
        // RESULTADO
        // =================================================

        if (errors == 0)
            $display("\nTODAS LAS PRUEBAS PASARON");
        else
            $display("\nERRORES: %0d", errors);

        $finish;

    end

endmodule
