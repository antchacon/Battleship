`timescale 1ns/1ps

module tb_vga_core_interconnect;

    logic clk_i       = 0;
    logic clk_pixel_i = 0;
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

    logic [8:0]  vga_addr;
    logic [31:0] vga_wdata;
    logic        vga_we;
    logic [31:0] vga_rdata;

    logic hsync_o;
    logic vsync_o;

    logic [3:0] vga_r_o;
    logic [3:0] vga_g_o;
    logic [3:0] vga_b_o;

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
        .ind_rdata_i(32'b0),

        .vga_addr_o(vga_addr),
        .vga_wdata_o(vga_wdata),
        .vga_we_o(vga_we),
        .vga_rdata_i(vga_rdata)
    );


    battleship_vga_core vga_dut (
        .clk_i,
        .clk_pixel_i,
        .rst_i,

        .cpu_addr_i(vga_addr),
        .cpu_wdata_i(vga_wdata),
        .cpu_we_i(vga_we),
        .cpu_rdata_o(vga_rdata),

        .hsync_o,
        .vsync_o,

        .vga_r_o,
        .vga_g_o,
        .vga_b_o
    );


    always #5  clk_i = ~clk_i;
    always #20 clk_pixel_i = ~clk_pixel_i;


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

        rst_i          = 1;
        data_address_i = 0;
        data_out_i     = 0;
        data_we_i      = 0;

        repeat(3) @(posedge clk_pixel_i);
        rst_i = 0;


        // =============================================
        // TILE 0 = BARCO = VERDE
        // =============================================

        cpu_write(
            32'h0001_1000,
            32'h0000_0001
        );


        // =============================================
        // TILE 1 = FALLO = BLANCO
        // =============================================

        cpu_write(
            32'h0001_1004,
            32'h0000_0003
        );


        // =============================================
        // COMPROBAR LECTURA MMIO
        // =============================================

        data_address_i = 32'h0001_1000;

        @(posedge clk_i);
        #1;

        check(
            data_in_o == 32'h0000_0001,
            "Lectura VGA por MMIO"
        );


        // =============================================
        // COMPROBAR TILE 0
        // =============================================

        wait(
            vga_dut.pixel_x == 10'd1 &&
            vga_dut.pixel_y == 10'd0 &&
            vga_dut.video_active
        );

        #1;

        check(
            vga_r_o == 4'h0 &&
            vga_g_o == 4'hF &&
            vga_b_o == 4'h0,
            "Tile 0 verde por MMIO"
        );


        // =============================================
        // COMPROBAR TILE 1
        // =============================================

        wait(
            vga_dut.pixel_x == 10'd33 &&
            vga_dut.pixel_y == 10'd0 &&
            vga_dut.video_active
        );

        #1;

        check(
            vga_r_o == 4'hF &&
            vga_g_o == 4'hF &&
            vga_b_o == 4'hF,
            "Tile 1 blanco por MMIO"
        );


        check(
            hsync_o == 1,
            "HSYNC"
        );

        check(
            vsync_o == 1,
            "VSYNC"
        );


        if (errors == 0)
            $display(
                "\nINTEGRACION VGA + INTERCONNECT COMPLETA"
            );
        else
            $display(
                "\nERRORES: %0d",
                errors
            );

        $finish;

    end

endmodule
