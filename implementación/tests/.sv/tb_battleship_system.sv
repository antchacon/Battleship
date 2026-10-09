`timescale 1ns/1ps

module tb_battleship_system;

    logic clk_i       = 0;
    logic clk_pixel_i = 0;
    logic rst_i;


    // J1
    logic btn_up_i;
    logic btn_down_i;
    logic btn_left_i;
    logic btn_right_i;
    logic btn_sel_i;
    logic btn_ok_i;
    logic btn_rst_i;


    // UART
    logic uart_rx_i;
    logic uart_tx_o;


    // VGA
    logic       vga_hsync_o;
    logic       vga_vsync_o;

    logic [3:0] vga_r_o;
    logic [3:0] vga_g_o;
    logic [3:0] vga_b_o;


    // Indicadores
    logic [31:0] display_data_o;
    logic [31:0] led_data_o;
    logic [31:0] buzzer_data_o;


    logic [31:0] pc_debug_o;


    integer errors = 0;


    // =====================================================
    // DUT
    // =====================================================

    battleship_system #(
        .UART_CLK_FREQ      (100_000_000),
        .UART_BAUD_RATE     (10_000_000),
        .J1_DEBOUNCE_CYCLES (3)
    ) dut (
        .clk_i,
        .clk_pixel_i,
        .rst_i,

        .btn_up_i,
        .btn_down_i,
        .btn_left_i,
        .btn_right_i,
        .btn_sel_i,
        .btn_ok_i,
        .btn_rst_i,

        .uart_rx_i,
        .uart_tx_o,

        .vga_hsync_o,
        .vga_vsync_o,

        .vga_r_o,
        .vga_g_o,
        .vga_b_o,

        .display_data_o,
        .led_data_o,
        .buzzer_data_o,

        .pc_debug_o
    );


    // =====================================================
    // RELOJES
    // =====================================================

    always #5  clk_i       = ~clk_i;
    always #20 clk_pixel_i = ~clk_pixel_i;


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

        rst_i = 1'b1;

        btn_up_i    = 0;
        btn_down_i  = 0;
        btn_left_i  = 0;
        btn_right_i = 0;
        btn_sel_i   = 0;
        btn_ok_i    = 0;
        btn_rst_i   = 0;

        uart_rx_i = 1'b1;


        #1;


        // =================================================
        // PROGRAMA
        // =================================================


        // Esperar un poco para que J1 se sincronice
        dut.rom.memory[0]  = 32'h0000_0013;
        dut.rom.memory[1]  = 32'h0000_0013;
        dut.rom.memory[2]  = 32'h0000_0013;
        dut.rom.memory[3]  = 32'h0000_0013;
        dut.rom.memory[4]  = 32'h0000_0013;
        dut.rom.memory[5]  = 32'h0000_0013;
        dut.rom.memory[6]  = 32'h0000_0013;
        dut.rom.memory[7]  = 32'h0000_0013;
        dut.rom.memory[8]  = 32'h0000_0013;
        dut.rom.memory[9]  = 32'h0000_0013;


        // -------------------------------------------------
        // x1 = 0x00010120
        // J1 STATUS
        // -------------------------------------------------

        dut.rom.memory[10] = 32'h0001_00B7;

        dut.rom.memory[11] = 32'h1200_8093;


        // -------------------------------------------------
        // lw x5, 0(x1)
        //
        // x5 = J1
        // -------------------------------------------------

        dut.rom.memory[12] = 32'h0000_A283;


        // -------------------------------------------------
        // x3 = 0x00010130
        // Indicadores
        // -------------------------------------------------

        dut.rom.memory[13] = 32'h0001_01B7;

        dut.rom.memory[14] = 32'h1301_8193;


        // -------------------------------------------------
        // sw x5, 8(x3)
        //
        // LED = valor leído desde J1
        //
        // Dirección = 0x00010138
        // -------------------------------------------------

        dut.rom.memory[15] = 32'h0051_A423;


        // -------------------------------------------------
        // x6 = 0x00011000
        // VGA
        // -------------------------------------------------

        dut.rom.memory[16] = 32'h0001_1337;


        // -------------------------------------------------
        // x7 = 2
        // -------------------------------------------------

        dut.rom.memory[17] = 32'h0020_0393;


        // -------------------------------------------------
        // VGA tile 0 = 2
        // -------------------------------------------------

        dut.rom.memory[18] = 32'h0073_2023;


        // NOP
        dut.rom.memory[19] = 32'h0000_0013;
        dut.rom.memory[20] = 32'h0000_0013;
        dut.rom.memory[21] = 32'h0000_0013;


        // =================================================
        // RESET
        // =================================================

        repeat(4)
            @(posedge clk_i);

        rst_i = 1'b0;


        // =================================================
        // ACTIVAR J1
        //
        // RIGHT = bit 3
        // OK    = bit 5
        //
        // esperado = 0x28
        // =================================================

        btn_right_i = 1'b1;
        btn_ok_i    = 1'b1;


        // =================================================
        // EJECUTAR
        // =================================================

        repeat(60)
            @(posedge clk_i);

        #1;


        // =================================================
        // RESULTADOS
        // =================================================

        $display("");
        $display("============================================");
        $display("BATTLESHIP SYSTEM");
        $display("============================================");

        $display(
            "J1 status  = %h",
            dut.j1_rdata
        );

        $display(
            "CPU x5     = %h",
            dut.cpu.u_rf.registers[5]
        );

        $display(
            "LED        = %h",
            led_data_o
        );

        $display(
            "VGA tile 0 = %h",
            dut.vga.vga_ram.memory[0]
        );

        $display("");


        // =================================================
        // CHECK J1
        // =================================================

        check(
            dut.j1_rdata == 32'h0000_0028,
            "J1 genera RIGHT + OK"
        );


        // =================================================
        // CHECK CPU
        // =================================================

        check(
            dut.cpu.u_rf.registers[5] == 32'h0000_0028,
            "CPU lee J1"
        );


        // =================================================
        // CHECK LED
        // =================================================

        check(
            led_data_o == 32'h0000_0028,
            "CPU copia J1 al LED"
        );


        // =================================================
        // CHECK VGA
        // =================================================

        check(
            dut.vga.vga_ram.memory[0] == 32'h0000_0002,
            "CPU escribe VGA"
        );


        // =================================================
        // RESULTADO FINAL
        // =================================================

        if (errors == 0) begin

            $display("");
            $display(
                "BATTLESHIP SYSTEM INTEGRADO CORRECTO"
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