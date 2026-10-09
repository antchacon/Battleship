`timescale 1ns/1ps

module tb_data_ram;

    logic clk_i = 0;

    logic [31:0] addr_i;
    logic [31:0] wdata_i;
    logic        write_enable_i;
    logic [31:0] rdata_o;

    integer errors = 0;


    data_ram dut (
        .clk_i,
        .addr_i,
        .wdata_i,
        .write_enable_i,
        .rdata_o
    );


    always #5 clk_i = ~clk_i;


    task write_ram(
        input logic [31:0] addr,
        input logic [31:0] data
    );
        begin
            @(negedge clk_i);

            addr_i         = addr;
            wdata_i        = data;
            write_enable_i = 1;

            @(negedge clk_i);

            write_enable_i = 0;
        end
    endtask


    task check_ram(
        input logic [31:0] addr,
        input logic [31:0] expected,
        input string name
    );
        begin
            addr_i = addr;
            #1;

            if (rdata_o === expected)
                $display("PASS: %s", name);
            else begin
                $display(
                    "ERROR: %s | esperado=%h recibido=%h",
                    name,
                    expected,
                    rdata_o
                );
                errors++;
            end
        end
    endtask


    initial begin

        addr_i         = 0;
        wdata_i        = 0;
        write_enable_i = 0;


        // Primera palabra
        write_ram(32'h0000_2000, 32'h1234_5678);
        check_ram(32'h0000_2000, 32'h1234_5678, "RAM palabra 0");


        // Segunda palabra
        write_ram(32'h0000_2004, 32'hAABB_CCDD);
        check_ram(32'h0000_2004, 32'hAABB_CCDD, "RAM palabra 1");


        // Verificar que palabra 0 no cambió
        check_ram(32'h0000_2000, 32'h1234_5678, "RAM conserva datos");


        // Última palabra
        write_ram(32'h0000_2FFC, 32'hDEAD_BEEF);
        check_ram(32'h0000_2FFC, 32'hDEAD_BEEF, "RAM ultima palabra");


        // Dirección fuera del rango
        addr_i = 32'h0000_3000;
        #1;

        if (rdata_o == 0)
            $display("PASS: Direccion invalida");
        else begin
            $display("ERROR: Direccion invalida");
            errors++;
        end


        if (errors == 0)
            $display("\nTODAS LAS PRUEBAS PASARON");
        else
            $display("\nERRORES: %0d", errors);

        $finish;

    end

endmodule