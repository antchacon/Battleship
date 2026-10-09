`timescale 1ns/1ps

module tb_j1_inputs;

    logic clk_i = 0;
    logic rst_i;

    logic btn_up_i;
    logic btn_down_i;
    logic btn_left_i;
    logic btn_right_i;
    logic btn_sel_i;
    logic btn_ok_i;
    logic btn_rst_i;

    logic [31:0] rdata_o;

    integer errors = 0;


    j1_inputs_mmio #(
        .DEBOUNCE_CYCLES(3)
    ) dut (
        .clk_i       (clk_i),
        .rst_i       (rst_i),

        .btn_up_i    (btn_up_i),
        .btn_down_i  (btn_down_i),
        .btn_left_i  (btn_left_i),
        .btn_right_i (btn_right_i),

        .btn_sel_i   (btn_sel_i),
        .btn_ok_i    (btn_ok_i),
        .btn_rst_i   (btn_rst_i),

        .rdata_o     (rdata_o)
    );


    always #5 clk_i = ~clk_i;


    task check(
        input logic [31:0] expected,
        input string name
    );
        begin

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


    task wait_debounce;
        begin
            repeat(6) @(posedge clk_i);
        end
    endtask


    initial begin

        rst_i = 1;

        btn_up_i    = 0;
        btn_down_i  = 0;
        btn_left_i  = 0;
        btn_right_i = 0;

        btn_sel_i   = 0;
        btn_ok_i    = 0;
        btn_rst_i   = 0;


        // =============================================
        // RESET
        // =============================================

        repeat(3) @(posedge clk_i);

        rst_i = 0;

        wait_debounce();

        check(
            32'h0000_0000,
            "Reset"
        );


        // =============================================
        // RIGHT -> bit 3
        // =============================================

        btn_right_i = 1;

        wait_debounce();

        check(
            32'h0000_0008,
            "RIGHT"
        );


        // =============================================
        // RIGHT + OK -> bits 3 y 5
        // =============================================

        btn_ok_i = 1;

        wait_debounce();

        check(
            32'h0000_0028,
            "RIGHT + OK"
        );


        // =============================================
        // SOLTAR BOTONES
        // =============================================

        btn_right_i = 0;
        btn_ok_i    = 0;

        wait_debounce();

        check(
            32'h0000_0000,
            "Botones liberados"
        );


        // =============================================
        // RST -> bit 6
        // =============================================

        btn_rst_i = 1;

        wait_debounce();

        check(
            32'h0000_0040,
            "BTN RST"
        );


        // =============================================
        // RESULTADO
        // =============================================

        if (errors == 0)
            $display("\nTODAS LAS PRUEBAS PASARON");

        else
            $display("\nERRORES: %0d", errors);


        $finish;

    end

endmodule