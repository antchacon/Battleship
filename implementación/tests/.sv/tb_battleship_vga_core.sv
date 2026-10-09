`timescale 1ns/1ps

module tb_battleship_vga_core;

    logic clk_i       = 0;
    logic clk_pixel_i = 0;
    logic rst_i;

    logic [8:0]  cpu_addr_i;
    logic [31:0] cpu_wdata_i;
    logic        cpu_we_i;
    logic [31:0] cpu_rdata_o;

    logic hsync_o;
    logic vsync_o;

    logic [3:0] vga_r_o;
    logic [3:0] vga_g_o;
    logic [3:0] vga_b_o;

    integer errors = 0;


    battleship_vga_core dut (
        .clk_i,
        .clk_pixel_i,
        .rst_i,

        .cpu_addr_i,
        .cpu_wdata_i,
        .cpu_we_i,
        .cpu_rdata_o,

        .hsync_o,
        .vsync_o,

        .vga_r_o,
        .vga_g_o,
        .vga_b_o
    );


    always #5  clk_i = ~clk_i;
    always #20 clk_pixel_i = ~clk_pixel_i;


    task cpu_write(
        input logic [8:0] addr,
        input logic [31:0] data
    );
        begin

            @(negedge clk_i);

            cpu_addr_i  = addr;
            cpu_wdata_i = data;
            cpu_we_i    = 1;

            @(negedge clk_i);

            cpu_we_i = 0;

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

        rst_i       = 1;
        cpu_addr_i  = 0;
        cpu_wdata_i = 0;
        cpu_we_i    = 0;

        repeat(3) @(posedge clk_pixel_i);

        rst_i = 0;


        // Tile 0 = barco = verde
        cpu_write(
            9'd0,
            32'h0000_0001
        );


        // Tile 1 = fallo = blanco
        cpu_write(
            9'd1,
            32'h0000_0003
        );


        // =============================================
        // TILE 0
        // =============================================

        wait(
            dut.pixel_x == 10'd1 &&
            dut.pixel_y == 10'd0 &&
            dut.video_active
        );

        #1;

        check(
            vga_r_o == 4'h0 &&
            vga_g_o == 4'hF &&
            vga_b_o == 4'h0,
            "Tile 0 verde"
        );


        // =============================================
        // TILE 1
        // =============================================

        wait(
            dut.pixel_x == 10'd33 &&
            dut.pixel_y == 10'd0 &&
            dut.video_active
        );

        #1;

        check(
            vga_r_o == 4'hF &&
            vga_g_o == 4'hF &&
            vga_b_o == 4'hF,
            "Tile 1 blanco"
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
                "\nVGA CORE COMPLETO CORRECTO"
            );
        else
            $display(
                "\nERRORES: %0d",
                errors
            );

        $finish;

    end

endmodule