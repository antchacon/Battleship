`timescale 1ns/1ps

module tb_indicators_interconnect;

    logic clk_i = 0;
    logic rst_i;

    logic [31:0] data_address_i;
    logic [31:0] data_out_i;
    logic        data_we_i;
    logic [31:0] data_in_o;

    logic [31:0] ram_addr;
    logic [31:0] ram_wdata;
    logic        ram_we;

    logic [1:0]  uart_addr;
    logic [31:0] uart_wdata;
    logic        uart_we;

    logic [1:0]  ind_addr;
    logic [31:0] ind_wdata;
    logic        ind_we;
    logic [31:0] ind_rdata;

    logic [8:0]  vga_addr;
    logic [31:0] vga_wdata;
    logic        vga_we;

    logic [31:0] display_data;
    logic [31:0] led_data;
    logic [31:0] buzzer_data;

    integer errors = 0;


    memory_interconnect interconnect_dut (
        .data_address_i,
        .data_out_i,
        .data_we_i,
        .data_in_o,

        .ram_addr_o(ram_addr),
        .ram_wdata_o(ram_wdata),
        .ram_we_o(ram_we),
        .ram_rdata_i(32'b0),

        .uart_addr_o(uart_addr),
        .uart_wdata_o(uart_wdata),
        .uart_we_o(uart_we),
        .uart_rdata_i(32'b0),

        .j1_rdata_i(32'b0),

        .ind_addr_o(ind_addr),
        .ind_wdata_o(ind_wdata),
        .ind_we_o(ind_we),
        .ind_rdata_i(ind_rdata),

        .vga_addr_o(vga_addr),
        .vga_wdata_o(vga_wdata),
        .vga_we_o(vga_we),
        .vga_rdata_i(32'b0)
    );


    indicators_mmio indicators_dut (
        .clk_i,
        .rst_i,
        .write_enable_i(ind_we),
        .addr_i(ind_addr),
        .wdata_i(ind_wdata),
        .rdata_o(ind_rdata),
        .display_data_o(display_data),
        .led_data_o(led_data),
        .buzzer_data_o(buzzer_data)
    );


    always #5 clk_i = ~clk_i;


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

        rst_i = 1;

        data_address_i = 0;
        data_out_i     = 0;
        data_we_i      = 0;

        repeat(3) @(posedge clk_i);
        rst_i = 0;


        // DISPLAY
        cpu_write(
            32'h0001_0130,
            32'h0000_1234
        );

        check(
            display_data == 32'h0000_1234,
            "Display por MMIO"
        );


        // LED
        cpu_write(
            32'h0001_0138,
            32'h0000_0001
        );

        check(
            led_data == 32'h0000_0001,
            "LED por MMIO"
        );


        // BUZZER
        cpu_write(
            32'h0001_0140,
            32'h0000_0003
        );

        check(
            buzzer_data == 32'h0000_0003,
            "Buzzer por MMIO"
        );


        // LECTURA DISPLAY
        data_address_i = 32'h0001_0130;
        #1;

        check(
            data_in_o == 32'h0000_1234,
            "Lectura Display"
        );


        // LECTURA LED
        data_address_i = 32'h0001_0138;
        #1;

        check(
            data_in_o == 32'h0000_0001,
            "Lectura LED"
        );


        // LECTURA BUZZER
        data_address_i = 32'h0001_0140;
        #1;

        check(
            data_in_o == 32'h0000_0003,
            "Lectura Buzzer"
        );


        if (errors == 0)
            $display(
                "\nINTEGRACION INDICADORES + INTERCONNECT CORRECTA"
            );
        else
            $display(
                "\nERRORES: %0d",
                errors
            );

        $finish;

    end

endmodule