`timescale 1ns/1ps

module tb_vga_interconnect;

    logic clk_i = 0;
    logic clk_pixel_i = 0;

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

    logic [8:0]  video_addr;
    logic [31:0] video_rdata;

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


    battleship_vga_ram vga_ram_dut (
        .clk_i          (clk_i),
        .cpu_addr_i     (vga_addr),
        .cpu_wdata_i    (vga_wdata),
        .cpu_we_i       (vga_we),
        .cpu_rdata_o    (vga_rdata),

        .clk_pixel_i    (clk_pixel_i),
        .video_addr_i   (video_addr),
        .video_rdata_o  (video_rdata)
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


    task check_cpu(
        input logic [31:0] addr,
        input logic [31:0] expected,
        input string name
    );
        begin

            @(negedge clk_i);
            data_address_i = addr;

            // La RAM VGA tiene lectura síncrona
            @(posedge clk_i);
            #1;

            if (data_in_o === expected)
                $display("PASS: %s", name);
            else begin

                $display(
                    "ERROR: %s | esperado=%h recibido=%h",
                    name,
                    expected,
                    data_in_o
                );

                errors++;

            end

        end
    endtask


    initial begin

        data_address_i = 0;
        data_out_i     = 0;
        data_we_i      = 0;

        video_addr = 0;


        // =============================================
        // PRIMERA DIRECCION VGA
        // =============================================

        cpu_write(
            32'h0001_1000,
            32'h0000_0001
        );

        check_cpu(
            32'h0001_1000,
            32'h0000_0001,
            "VGA direccion 0 por MMIO"
        );


        // =============================================
        // DIRECCION VGA 2
        // =============================================

        cpu_write(
            32'h0001_1008,
            32'h0000_0003
        );

        check_cpu(
            32'h0001_1008,
            32'h0000_0003,
            "VGA direccion 2 por MMIO"
        );


        // =============================================
        // COMPROBAR CONVERSION DE DIRECCION
        // =============================================

        data_address_i = 32'h0001_1008;
        #1;

        if (vga_addr == 9'd2)
            $display("PASS: Conversion direccion VGA");
        else begin
            $display("ERROR: Conversion direccion VGA");
            errors++;
        end


        // =============================================
        // ULTIMA PALABRA
        // =============================================

        cpu_write(
            32'h0001_17FC,
            32'hDEAD_BEEF
        );

        check_cpu(
            32'h0001_17FC,
            32'hDEAD_BEEF,
            "VGA ultima palabra"
        );


        // =============================================
        // PUERTO DE VIDEO
        // =============================================

        video_addr = 9'd2;

        @(posedge clk_pixel_i);
        #1;

        if (video_rdata === 32'h0000_0003)
            $display("PASS: Lectura puerto VGA");
        else begin
            $display("ERROR: Lectura puerto VGA");
            errors++;
        end


        // =============================================
        // FUERA DEL RANGO VGA
        // =============================================

        data_address_i = 32'h0001_1800;
        #1;

        if (!vga_we && data_in_o == 0)
            $display("PASS: Direccion fuera de VGA");
        else begin
            $display("ERROR: Direccion fuera de VGA");
            errors++;
        end


        // =============================================
        // RESULTADO
        // =============================================

        if (errors == 0)
            $display(
                "\nINTEGRACION VGA RAM + INTERCONNECT CORRECTA"
            );
        else
            $display(
                "\nERRORES: %0d",
                errors
            );

        $finish;

    end

endmodule