`timescale 1ns/1ps

module tb_riscv_j1_mmio;

    logic clk_i = 0;
    logic rst_i;

    logic [31:0] prog_addr;
    logic [31:0] prog_instr;

    logic [31:0] data_addr;
    logic [31:0] data_out;
    logic [31:0] data_in;
    logic        data_we;

    logic [31:0] pc;

    logic [31:0] ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;
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

    logic [31:0] j1_rdata;

    integer errors = 0;


    // =====================================================
    // RISC-V
    // =====================================================

    riscv_core core_dut (
        .clk_i         (clk_i),
        .rst_i         (rst_i),

        .ProgAddress_o (prog_addr),
        .ProgIn_i      (prog_instr),

        .DataAddress_o (data_addr),
        .DataOut_o     (data_out),
        .DataIn_i      (data_in),

        .we_o          (data_we),
        .pc_out        (pc)
    );


    // =====================================================
    // ROM
    // =====================================================

    program_rom rom_dut (
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .prog_address_i (prog_addr),
        .prog_instr_o   (prog_instr)
    );


    // =====================================================
    // INTERCONNECT
    // =====================================================

    memory_interconnect interconnect_dut (
        .data_address_i (data_addr),
        .data_out_i     (data_out),
        .data_we_i      (data_we),
        .data_in_o      (data_in),

        .ram_addr_o     (ram_addr),
        .ram_wdata_o    (ram_wdata),
        .ram_we_o       (ram_we),
        .ram_rdata_i    (ram_rdata),

        .uart_addr_o    (uart_addr),
        .uart_wdata_o   (uart_wdata),
        .uart_we_o      (uart_we),
        .uart_rdata_i   (32'b0),

        .j1_rdata_i     (j1_rdata),

        .ind_addr_o     (ind_addr),
        .ind_wdata_o    (ind_wdata),
        .ind_we_o       (ind_we),
        .ind_rdata_i    (32'b0),

        .vga_addr_o     (vga_addr),
        .vga_wdata_o    (vga_wdata),
        .vga_we_o       (vga_we),
        .vga_rdata_i    (32'b0)
    );


    // =====================================================
    // RAM
    // =====================================================

    data_ram ram_dut (
        .clk_i          (clk_i),
        .addr_i         (ram_addr),
        .wdata_i        (ram_wdata),
        .write_enable_i (ram_we),
        .rdata_o        (ram_rdata)
    );


    // =====================================================
    // RELOJ
    // =====================================================

    always #5 clk_i = ~clk_i;


    // =====================================================
    // DEBUG
    // =====================================================

    always @(posedge clk_i) begin

        if (data_addr == 32'h0001_0120) begin

            $display(
                "READ J1 | PC=%h | addr=%h | DataIn=%h",
                pc,
                data_addr,
                data_in
            );

        end

    end


    // =====================================================
    // CHECK
    // =====================================================

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


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        rst_i     = 1'b1;
        j1_rdata  = 32'h0000_0009;


        #1;


        // =================================================
        // PROGRAMA
        // =================================================


        // x1 = 0x00010000
        // lui x1, 0x10

        rom_dut.memory[0] = 32'h0001_00B7;


        // x1 = 0x00010120
        // addi x1, x1, 0x120

        rom_dut.memory[1] = 32'h1200_8093;


        // x5 = J1 STATUS
        // lw x5, 0(x1)

        rom_dut.memory[2] = 32'h0000_A283;


        // x6 = x5 + 1
        // sirve también para verificar load-use

        rom_dut.memory[3] = 32'h0012_8313;


        // NOP

        rom_dut.memory[4] = 32'h0000_0013;
        rom_dut.memory[5] = 32'h0000_0013;
        rom_dut.memory[6] = 32'h0000_0013;


        // =================================================
        // RESET
        // =================================================

        repeat(4)
            @(posedge clk_i);

        rst_i = 1'b0;


        // =================================================
        // EJECUTAR
        // =================================================

        repeat(25)
            @(posedge clk_i);

        #1;


        // =================================================
        // RESULTADOS
        // =================================================

        $display("");
        $display("============================================");
        $display("LECTURA J1");
        $display("============================================");

        $display(
            "J1 = %h",
            j1_rdata
        );

        $display(
            "x5 = %h",
            core_dut.u_rf.registers[5]
        );

        $display(
            "x6 = %h",
            core_dut.u_rf.registers[6]
        );

        $display("");


        check(
            core_dut.u_rf.registers[5] == 32'h0000_0009,
            "CPU lee J1 por MMIO"
        );


        check(
            core_dut.u_rf.registers[6] == 32'h0000_000A,
            "Dato J1 utilizable por CPU"
        );


        // =================================================
        // RESULTADO FINAL
        // =================================================

        if (errors == 0)
            $display(
                "RISC-V + LECTURA MMIO J1 CORRECTO"
            );

        else
            $display(
                "ERRORES: %0d",
                errors
            );


        $finish;

    end

endmodule