`timescale 1ns/1ps

module tb_battleship_sevenseg_driver;

    logic clk_i = 0;
    logic rst_i;

    logic [31:0] display_data_i;

    logic [6:0] seg_o;
    logic [3:0] an_o;

    integer errors = 0;


    // =====================================================
    // DUT
    // =====================================================

    battleship_sevenseg_driver #(
        .REFRESH_DIV (2)
    ) dut (
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .display_data_i (display_data_i),

        .seg_o          (seg_o),
        .an_o           (an_o)
    );


    // 100 MHz
    always #5 clk_i = ~clk_i;


    // =====================================================
    // CHECK
    // =====================================================

    task check(
        input logic       condition,
        input string      name
    );

        begin

            if (condition)
                $display("PASS: %s", name);

            else begin

                $display(
                    "ERROR: %s | AN=%b SEG=%b",
                    name,
                    an_o,
                    seg_o
                );

                errors++;

            end

        end

    endtask


    // =====================================================
    // AVANZAR UN DIGITO
    // =====================================================

    task next_digit;

        begin

            repeat(2)
                @(posedge clk_i);

            #1;

        end

    endtask


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        rst_i = 1'b1;

        // J1 = 12
        // J2 = 03
        //
        // display esperado = 1203

        display_data_i = 32'h0000_030C;


        repeat(2)
            @(posedge clk_i);

        @(negedge clk_i);

        rst_i = 1'b0;

        #1;


        // =================================================
        // DIGITO 0
        // J2 unidades = 3
        // =================================================

        check(
            an_o  == 4'b1110 &&
            seg_o == 7'b0110000,
            "J2 unidades = 3"
        );


        // =================================================
        // DIGITO 1
        // J2 decenas = 0
        // =================================================

        next_digit();

        check(
            an_o  == 4'b1101 &&
            seg_o == 7'b1000000,
            "J2 decenas = 0"
        );


        // =================================================
        // DIGITO 2
        // J1 unidades = 2
        // =================================================

        next_digit();

        check(
            an_o  == 4'b1011 &&
            seg_o == 7'b0100100,
            "J1 unidades = 2"
        );


        // =================================================
        // DIGITO 3
        // J1 decenas = 1
        // =================================================

        next_digit();

        check(
            an_o  == 4'b0111 &&
            seg_o == 7'b1111001,
            "J1 decenas = 1"
        );


        // =================================================
        // RESULTADO
        // =================================================

        if (errors == 0) begin

            $display("");
            $display(
                "DRIVER 7 SEGMENTOS CORRECTO"
            );

        end

        else begin

            $display("");
            $display(
                "ERRORES: %0d",
                errors
            );

        end


        $finish;

    end

endmodule
