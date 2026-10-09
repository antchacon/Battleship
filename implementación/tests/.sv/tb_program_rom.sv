`timescale 1ns/1ps

module tb_program_rom;

    logic clk_i = 0;
    logic rst_i;

    logic [31:0] prog_address_i;
    logic [31:0] prog_instr_o;

    integer errors = 0;


    program_rom dut (
        .clk_i,
        .rst_i,
        .prog_address_i,
        .prog_instr_o
    );


    always #5 clk_i = ~clk_i;


    task check(
        input logic [31:0] addr,
        input logic [31:0] expected,
        input string name
    );
        begin

            @(negedge clk_i);
            prog_address_i = addr;

            @(posedge clk_i);
            #1;

            if (prog_instr_o === expected)
                $display("PASS: %s", name);

            else begin

                $display(
                    "ERROR: %s | esperado=%h recibido=%h",
                    name,
                    expected,
                    prog_instr_o
                );

                errors++;

            end

        end
    endtask


    initial begin

        rst_i          = 1;
        prog_address_i = 0;

        // Datos de prueba
        #1;
        dut.memory[0]    = 32'h0010_0093;
        dut.memory[1]    = 32'h0020_0113;
        dut.memory[2047] = 32'hDEAD_BEEF;


        repeat(2) @(posedge clk_i);

        rst_i = 0;


        // Primera instruccion
        check(
            32'h0000_0000,
            32'h0010_0093,
            "ROM palabra 0"
        );


        // Segunda instruccion
        check(
            32'h0000_0004,
            32'h0020_0113,
            "ROM palabra 1"
        );


        // Ultima posicion
        check(
            32'h0000_1FFC,
            32'hDEAD_BEEF,
            "ROM ultima palabra"
        );


        // Fuera de rango -> NOP
        check(
            32'h0000_2000,
            32'h0000_0013,
            "Direccion fuera de ROM"
        );


        if (errors == 0)
            $display("\nTODAS LAS PRUEBAS PASARON");
        else
            $display("\nERRORES: %0d", errors);

        $finish;

    end

endmodule
