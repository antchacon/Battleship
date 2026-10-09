`timescale 1ns/1ps

module tb_j1_interconnect;

    logic clk_i = 0;
    logic rst_i;

    logic btn_up_i;
    logic btn_down_i;
    logic btn_left_i;
    logic btn_right_i;
    logic btn_sel_i;
    logic btn_ok_i;
    logic btn_rst_i;

    logic [31:0] j1_rdata;

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

    integer errors = 0;


    j1_inputs_mmio #(
        .DEBOUNCE_CYCLES(3)
    ) j1_dut (
        .clk_i,
        .rst_i,
        .btn_up_i,
        .btn_down_i,
        .btn_left_i,
        .btn_right_i,
        .btn_sel_i,
        .btn_ok_i,
        .btn_rst_i,
        .rdata_o(j1_rdata)
    );


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

        .j1_rdata_i(j1_rdata),

        .ind_addr_o(ind_addr),
        .ind_wdata_o(ind_wdata),
        .ind_we_o(ind_we),
        .ind_rdata_i(32'b0),

        .vga_addr_o(vga_addr),
        .vga_wdata_o(vga_wdata),
        .vga_we_o(vga_we),
        .vga_rdata_i(32'b0)
    );


    always #5 clk_i = ~clk_i;


    task wait_debounce;
        begin
            repeat(6) @(posedge clk_i);
        end
    endtask


    task check(
        input logic [31:0] expected,
        input string name
    );
        begin

            data_address_i = 32'h0001_0120;
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

        rst_i = 1;

        btn_up_i    = 0;
        btn_down_i  = 0;
        btn_left_i  = 0;
        btn_right_i = 0;
        btn_sel_i   = 0;
        btn_ok_i    = 0;
        btn_rst_i   = 0;

        data_address_i = 0;
        data_out_i     = 0;
        data_we_i      = 0;


        repeat(3) @(posedge clk_i);
        rst_i = 0;

        wait_debounce();


        // UP
        btn_up_i = 1;

        wait_debounce();

        check(
            32'h0000_0001,
            "UP por MMIO"
        );


        // UP + SEL
        btn_sel_i = 1;

        wait_debounce();

        check(
            32'h0000_0011,
            "UP + SEL por MMIO"
        );


        // OK solamente
        btn_up_i  = 0;
        btn_sel_i = 0;
        btn_ok_i  = 1;

        wait_debounce();

        check(
            32'h0000_0020,
            "OK por MMIO"
        );


        // RST solamente
        btn_ok_i  = 0;
        btn_rst_i = 1;

        wait_debounce();

        check(
            32'h0000_0040,
            "RST por MMIO"
        );


        // Liberar
        btn_rst_i = 0;

        wait_debounce();

        check(
            32'h0000_0000,
            "Entradas liberadas"
        );


        if (errors == 0)
            $display(
                "\nINTEGRACION J1 + INTERCONNECT CORRECTA"
            );
        else
            $display(
                "\nERRORES: %0d",
                errors
            );

        $finish;

    end

endmodule