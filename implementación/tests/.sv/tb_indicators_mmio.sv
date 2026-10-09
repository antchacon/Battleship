`timescale 1ns/1ps

module tb_indicators_mmio;

    logic clk_i = 0;
    logic rst_i;

    logic        write_enable_i;
    logic [1:0]  addr_i;
    logic [31:0] wdata_i;
    logic [31:0] rdata_o;

    logic [31:0] display_data_o;
    logic [31:0] led_data_o;
    logic [31:0] buzzer_data_o;

    integer errors = 0;


    indicators_mmio dut (
        .clk_i,
        .rst_i,
        .write_enable_i,
        .addr_i,
        .wdata_i,
        .rdata_o,
        .display_data_o,
        .led_data_o,
        .buzzer_data_o
    );


    always #5 clk_i = ~clk_i;


    task write_reg(
        input logic [1:0] addr,
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


    task check(
        input logic [31:0] expected,
        input string name
    );
        begin

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

        rst_i          = 1;
        write_enable_i = 0;
        addr_i         = 0;
        wdata_i        = 0;

        repeat(3) @(posedge clk_i);

        rst_i = 0;


        // DISPLAY
        write_reg(2'b00, 32'h0000_1234);

        addr_i = 2'b00;
        check(32'h0000_1234, "Display");


        // LED
        write_reg(2'b01, 32'h0000_0001);

        addr_i = 2'b01;
        check(32'h0000_0001, "LED");


        // BUZZER
        write_reg(2'b10, 32'h0000_0003);

        addr_i = 2'b10;
        check(32'h0000_0003, "Buzzer");


        // VERIFICAR QUE DISPLAY CONSERVA SU VALOR
        addr_i = 2'b00;
        check(32'h0000_1234, "Display conserva dato");


        if (errors == 0)
            $display("\nTODAS LAS PRUEBAS PASARON");
        else
            $display("\nERRORES: %0d", errors);

        $finish;

    end

endmodule
