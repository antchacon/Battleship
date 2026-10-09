`timescale 1ns/1ps

module tb_ram_interconnect;

    logic clk_i = 0;

    logic [31:0] data_address_i;
    logic [31:0] data_out_i;
    logic        data_we_i;
    logic [31:0] data_in_o;

    logic [31:0] ram_addr;
    logic [31:0] ram_wdata;
    logic        ram_we;
    logic [31:0] ram_rdata;

    logic [1:0]  uart_addr;
    logic [31:0] uart_wdata;
    logic        uart_we;

    logic [1:0]  ind_addr;
    logic [31:0] ind_wdata;
    logic        ind_we;

    logic [8:0]  vga_addr;
    logic [31:0] vga_wdata;
    logic        vga_we;

    integer errors = 0;


    memory_interconnect interconnect_dut (
        .data_address_i (data_address_i),
        .data_out_i     (data_out_i),
        .data_we_i      (data_we_i),
        .data_in_o      (data_in_o),

        .ram_addr_o     (ram_addr),
        .ram_wdata_o    (ram_wdata),
        .ram_we_o       (ram_we),
        .ram_rdata_i    (ram_rdata),

        .uart_addr_o    (uart_addr),
        .uart_wdata_o   (uart_wdata),
        .uart_we_o      (uart_we),
        .uart_rdata_i   (32'b0),

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


    data_ram ram_dut (
        .clk_i          (clk_i),
        .addr_i         (ram_addr),
        .wdata_i        (ram_wdata),
        .write_enable_i (ram_we),
        .rdata_o        (ram_rdata)
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

        data_address_i = 0;
        data_out_i     = 0;
        data_we_i      = 0;


        // =============================================
        // ESCRITURA EN RAM
        // =============================================

        cpu_write(
            32'h0000_2000,
            32'h1234_5678
        );

        data_address_i = 32'h0000_2000;
        #1;

        check(
            data_in_o == 32'h1234_5678,
            "RAM palabra 0 por interconnect"
        );


        // =============================================
        // SEGUNDA POSICION
        // =============================================

        cpu_write(
            32'h0000_2004,
            32'hAABB_CCDD
        );

        data_address_i = 32'h0000_2004;
        #1;

        check(
            data_in_o == 32'hAABB_CCDD,
            "RAM palabra 1 por interconnect"
        );


        // =============================================
        // VERIFICAR PRIMER DATO
        // =============================================

        data_address_i = 32'h0000_2000;
        #1;

        check(
            data_in_o == 32'h1234_5678,
            "RAM conserva palabra 0"
        );


        // =============================================
        // ULTIMA POSICION
        // =============================================

        cpu_write(
            32'h0000_2FFC,
            32'hDEAD_BEEF
        );

        data_address_i = 32'h0000_2FFC;
        #1;

        check(
            data_in_o == 32'hDEAD_BEEF,
            "RAM ultima palabra por interconnect"
        );


        // =============================================
        // FUERA DE RANGO
        // =============================================

        data_address_i = 32'h0000_3000;
        #1;

        check(
            data_in_o == 0,
            "Direccion fuera de RAM"
        );


        // =============================================
        // RESULTADO
        // =============================================

        if (errors == 0)
            $display(
                "\nINTEGRACION RAM + INTERCONNECT CORRECTA"
            );
        else
            $display(
                "\nERRORES: %0d",
                errors
            );

        $finish;

    end

endmodule