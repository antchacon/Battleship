`timescale 1ns/1ps

module tb_riscv_mmio;

    logic clk_i       = 0;
    logic clk_pixel_i = 0;
    logic rst_i;

    // =====================================================
    // RISC-V
    // =====================================================

    logic [31:0] prog_addr;
    logic [31:0] prog_instr;

    logic [31:0] data_addr;
    logic [31:0] data_out;
    logic [31:0] data_in;
    logic        data_we;

    logic [31:0] pc;


    // =====================================================
    // RAM
    // =====================================================

    logic [31:0] ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;
    logic        ram_we;


    // =====================================================
    // UART
    // =====================================================

    logic [1:0]  uart_addr;
    logic [31:0] uart_wdata;
    logic        uart_we;


    // =====================================================
    // INDICADORES
    // =====================================================

    logic [1:0]  ind_addr;
    logic [31:0] ind_wdata;
    logic [31:0] ind_rdata;
    logic        ind_we;

    logic [31:0] display_data;
    logic [31:0] led_data;
    logic [31:0] buzzer_data;


    // =====================================================
    // VGA
    // =====================================================

    logic [8:0]  vga_addr;
    logic [31:0] vga_wdata;
    logic [31:0] vga_rdata;
    logic        vga_we;

    logic        hsync;
    logic        vsync;

    logic [3:0]  vga_r;
    logic [3:0]  vga_g;
    logic [3:0]  vga_b;


    integer errors = 0;


    // =====================================================
    // RISC-V CORE
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
    // PROGRAM ROM
    // =====================================================

    program_rom rom_dut (
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .prog_address_i (prog_addr),
        .prog_instr_o   (prog_instr)
    );


    // =====================================================
    // MEMORY INTERCONNECT
    // =====================================================

    memory_interconnect interconnect_dut (
        .data_address_i (data_addr),
        .data_out_i     (data_out),
        .data_we_i      (data_we),
        .data_in_o      (data_in),

        // RAM
        .ram_addr_o     (ram_addr),
        .ram_wdata_o    (ram_wdata),
        .ram_we_o       (ram_we),
        .ram_rdata_i    (ram_rdata),

        // UART
        .uart_addr_o    (uart_addr),
        .uart_wdata_o   (uart_wdata),
        .uart_we_o      (uart_we),
        .uart_rdata_i   (32'b0),

        // J1
        .j1_rdata_i     (32'b0),

        // Indicadores
        .ind_addr_o     (ind_addr),
        .ind_wdata_o    (ind_wdata),
        .ind_we_o       (ind_we),
        .ind_rdata_i    (ind_rdata),

        // VGA
        .vga_addr_o     (vga_addr),
        .vga_wdata_o    (vga_wdata),
        .vga_we_o       (vga_we),
        .vga_rdata_i    (vga_rdata)
    );


    // =====================================================
    // DATA RAM
    // =====================================================

    data_ram ram_dut (
        .clk_i          (clk_i),

        .addr_i         (ram_addr),
        .wdata_i        (ram_wdata),
        .write_enable_i (ram_we),

        .rdata_o        (ram_rdata)
    );


    // =====================================================
    // INDICADORES
    // =====================================================

    indicators_mmio indicators_dut (
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .write_enable_i (ind_we),
        .addr_i         (ind_addr),
        .wdata_i        (ind_wdata),

        .rdata_o        (ind_rdata),

        .display_data_o (display_data),
        .led_data_o     (led_data),
        .buzzer_data_o  (buzzer_data)
    );


    // =====================================================
    // VGA CORE
    // =====================================================

    battleship_vga_core vga_dut (
        .clk_i          (clk_i),
        .clk_pixel_i    (clk_pixel_i),
        .rst_i          (rst_i),

        .cpu_addr_i     (vga_addr),
        .cpu_wdata_i    (vga_wdata),
        .cpu_we_i       (vga_we),
        .cpu_rdata_o    (vga_rdata),

        .hsync_o        (hsync),
        .vsync_o        (vsync),

        .vga_r_o        (vga_r),
        .vga_g_o        (vga_g),
        .vga_b_o        (vga_b)
    );


    // =====================================================
    // RELOJES
    // =====================================================

    // 100 MHz
    always #5 clk_i = ~clk_i;

    // 25 MHz
    always #20 clk_pixel_i = ~clk_pixel_i;


    // =====================================================
    // TASK DE COMPROBACION
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
    // MOSTRAR ESCRITURAS MMIO
    // =====================================================

    always @(posedge clk_i) begin

        if (data_we) begin

            $display(
                "WRITE MMIO | PC=%h | addr=%h | data=%h",
                pc,
                data_addr,
                data_out
            );

        end

    end


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        rst_i = 1'b1;

        #1;


        // =================================================
        // PROGRAMA RISC-V
        // =================================================


        // -------------------------------------------------
        // x1 = 0x00011000
        //
        // Base de memoria VGA
        // -------------------------------------------------

        // lui x1, 0x11
        rom_dut.memory[0] = 32'h0001_10B7;


        // -------------------------------------------------
        // x2 = 1
        //
        // Estado VGA 001
        // -------------------------------------------------

        // addi x2, x0, 1
        rom_dut.memory[1] = 32'h0010_0113;


        // -------------------------------------------------
        // VGA[0] = 1
        //
        // sw x2, 0(x1)
        // direccion = 0x00011000
        // -------------------------------------------------

        rom_dut.memory[2] = 32'h0020_A023;


        // -------------------------------------------------
        // x2 = 3
        // -------------------------------------------------

        // addi x2, x0, 3
        rom_dut.memory[3] = 32'h0030_0113;


        // -------------------------------------------------
        // VGA[1] = 3
        //
        // sw x2, 4(x1)
        // direccion = 0x00011004
        // -------------------------------------------------

        rom_dut.memory[4] = 32'h0020_A223;


        // =================================================
        // INDICADORES
        // =================================================


        // -------------------------------------------------
        // x3 = 0x00010000
        // -------------------------------------------------

        // lui x3, 0x10
        rom_dut.memory[5] = 32'h0001_01B7;


        // -------------------------------------------------
        // x3 = 0x00010130
        //
        // Base de DISPLAY
        // -------------------------------------------------

        // addi x3, x3, 0x130
        rom_dut.memory[6] = 32'h1301_8193;


        // -------------------------------------------------
        // DISPLAY = 12
        // -------------------------------------------------

        // addi x4, x0, 12
        rom_dut.memory[7] = 32'h00C0_0213;

        // sw x4, 0(x3)
        // 0x00010130
        rom_dut.memory[8] = 32'h0041_A023;


        // -------------------------------------------------
        // LED = 1
        // -------------------------------------------------

        // addi x4, x0, 1
        rom_dut.memory[9] = 32'h0010_0213;

        // sw x4, 8(x3)
        // 0x00010138
        rom_dut.memory[10] = 32'h0041_A423;


        // -------------------------------------------------
        // BUZZER = 3
        // -------------------------------------------------

        // addi x4, x0, 3
        rom_dut.memory[11] = 32'h0030_0213;

        // sw x4, 16(x3)
        // 0x00010140
        rom_dut.memory[12] = 32'h0041_A823;


        // -------------------------------------------------
        // NOP
        // -------------------------------------------------

        rom_dut.memory[13] = 32'h0000_0013;
        rom_dut.memory[14] = 32'h0000_0013;
        rom_dut.memory[15] = 32'h0000_0013;


        // =================================================
        // RESET
        // =================================================

        repeat(4)
            @(posedge clk_i);

        rst_i = 1'b0;


        // =================================================
        // EJECUTAR PROGRAMA
        // =================================================

        repeat(40)
            @(posedge clk_i);

        #1;


        // =================================================
        // VGA
        // =================================================

        $display("");
        $display("============================================");
        $display("VGA");
        $display("============================================");

        $display(
            "VGA tile 0 = %h",
            vga_dut.vga_ram.memory[0]
        );

        $display(
            "VGA tile 1 = %h",
            vga_dut.vga_ram.memory[1]
        );

        $display("");


        check(
            vga_dut.vga_ram.memory[0] == 32'h0000_0001,
            "CPU escribe VGA tile 0"
        );


        check(
            vga_dut.vga_ram.memory[1] == 32'h0000_0003,
            "CPU escribe VGA tile 1"
        );


        // =================================================
        // INDICADORES
        // =================================================

        $display("");
        $display("============================================");
        $display("INDICADORES");
        $display("============================================");

        $display(
            "Display = %h",
            display_data
        );

        $display(
            "LED     = %h",
            led_data
        );

        $display(
            "Buzzer  = %h",
            buzzer_data
        );

        $display("");


        check(
            display_data == 32'd12,
            "CPU escribe Display"
        );


        check(
            led_data == 32'd1,
            "CPU escribe LED"
        );


        check(
            buzzer_data == 32'd3,
            "CPU escribe Buzzer"
        );


        // =================================================
        // RESULTADO
        // =================================================

        if (errors == 0) begin

            $display("");
            $display(
                "RISC-V + MMIO VGA + INDICADORES CORRECTO"
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
