`timescale 1ns/1ps

module tb_riscv_uart_mmio;

    localparam int CLK_FREQ  = 100_000_000;
    localparam int BAUD_RATE = 10_000_000;
    localparam int BIT_CLKS  = CLK_FREQ / BAUD_RATE;

    logic clk_i = 0;
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
    // INTERCONNECT
    // =====================================================

    logic [31:0] ram_addr;
    logic [31:0] ram_wdata;
    logic        ram_we;

    logic [1:0]  uart_addr;
    logic [31:0] uart_wdata;
    logic [31:0] uart_rdata;
    logic        uart_we;

    logic [1:0]  ind_addr;
    logic [31:0] ind_wdata;
    logic        ind_we;

    logic [8:0]  vga_addr;
    logic [31:0] vga_wdata;
    logic        vga_we;


    // =====================================================
    // UART FISICO
    // =====================================================

    logic uart_rx_i;
    logic uart_tx_o;


    // =====================================================
    // CONTROL DE PRUEBA
    // =====================================================

    logic saw_tx_data;
    logic saw_tx_start;

    integer errors = 0;
    integer i;


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
        .ram_rdata_i    (32'b0),

        .uart_addr_o    (uart_addr),
        .uart_wdata_o   (uart_wdata),
        .uart_we_o      (uart_we),
        .uart_rdata_i   (uart_rdata),

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


    // =====================================================
    // UART
    // =====================================================

    uart_peripheral #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) uart_dut (
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .write_enable_i (uart_we),
        .addr_i         (uart_addr),
        .wdata_i        (uart_wdata),
        .rdata_o        (uart_rdata),

        .uart_rx_i      (uart_rx_i),
        .uart_tx_o      (uart_tx_o)
    );


    // =====================================================
    // RELOJ 100 MHz
    // =====================================================

    always #5 clk_i = ~clk_i;


    // =====================================================
    // ENVIAR BYTE HACIA EL UART RX
    // =====================================================

    task uart_send_byte(
        input logic [7:0] data
    );

        integer bit_index;

        begin

            // Reposo
            uart_rx_i = 1'b1;

            repeat(2)
                @(posedge clk_i);


            // Start bit
            uart_rx_i = 1'b0;

            repeat(BIT_CLKS)
                @(posedge clk_i);


            // 8 bits de datos, LSB primero
            for (
                bit_index = 0;
                bit_index < 8;
                bit_index = bit_index + 1
            ) begin

                uart_rx_i = data[bit_index];

                repeat(BIT_CLKS)
                    @(posedge clk_i);

            end


            // Stop bit
            uart_rx_i = 1'b1;

            repeat(BIT_CLKS)
                @(posedge clk_i);


            // Reposo
            repeat(3)
                @(posedge clk_i);

        end

    endtask


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
    // DETECTAR ESCRITURAS UART DEL CPU
    // =====================================================

    always @(posedge clk_i) begin

        if (
            data_we &&
            data_addr == 32'h0001_0044
        ) begin

            $display(
                "UART TX WRITE | PC=%h | data=%h",
                pc,
                data_out
            );

            if (data_out[7:0] == 8'h41)
                saw_tx_data <= 1'b1;

        end


        if (
            data_we &&
            data_addr == 32'h0001_0040
        ) begin

            $display(
                "UART CONTROL WRITE | PC=%h | data=%h",
                pc,
                data_out
            );

            if (data_out[0])
                saw_tx_start <= 1'b1;

        end

    end


    // =====================================================
    // MOSTRAR LECTURAS UART
    // =====================================================

    always @(posedge clk_i) begin

        if (
            data_addr == 32'h0001_0048 &&
            !data_we
        ) begin

            $display(
                "UART RX READ | PC=%h | DataIn=%h",
                pc,
                data_in
            );

        end

    end


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        rst_i        = 1'b1;
        uart_rx_i    = 1'b1;

        saw_tx_data  = 1'b0;
        saw_tx_start = 1'b0;


        #1;


        // =================================================
        // PROGRAMA RISC-V
        // =================================================


        // -------------------------------------------------
        // x1 = 0x00010000
        //
        // lui x1, 0x10
        // -------------------------------------------------

        rom_dut.memory[0] = 32'h0001_00B7;


        // -------------------------------------------------
        // x1 = 0x00010040
        //
        // CONTROL UART
        //
        // addi x1, x1, 0x40
        // -------------------------------------------------

        rom_dut.memory[1] = 32'h0400_8093;


        // -------------------------------------------------
        // x2 = 0x41 = 'A'
        //
        // addi x2, x0, 0x41
        // -------------------------------------------------

        rom_dut.memory[2] = 32'h0410_0113;


        // -------------------------------------------------
        // TX DATA = 0x41
        //
        // sw x2, 4(x1)
        //
        // 0x00010044
        // -------------------------------------------------

        rom_dut.memory[3] = 32'h0020_A223;


        // -------------------------------------------------
        // x2 = 1
        //
        // CONTROL bit0 = START
        // -------------------------------------------------

        rom_dut.memory[4] = 32'h0010_0113;


        // -------------------------------------------------
        // sw x2, 0(x1)
        //
        // inicia TX
        // -------------------------------------------------

        rom_dut.memory[5] = 32'h0020_A023;


        // =================================================
        // ESPERA PARA QUE LLEGUE EL RX
        // =================================================

        for (i = 6; i < 140; i = i + 1)
            rom_dut.memory[i] = 32'h0000_0013;


        // =================================================
        // LEER RX
        //
        // lw x5, 8(x1)
        //
        // 0x00010048
        // =================================================

        rom_dut.memory[140] = 32'h0080_A283;


        // =================================================
        // USAR DATO RECIBIDO
        //
        // x6 = x5 + 1
        // =================================================

        rom_dut.memory[141] = 32'h0012_8313;


        // NOP
        rom_dut.memory[142] = 32'h0000_0013;
        rom_dut.memory[143] = 32'h0000_0013;
        rom_dut.memory[144] = 32'h0000_0013;


        // =================================================
        // RESET
        // =================================================

        repeat(4)
            @(posedge clk_i);

        rst_i = 1'b0;


        // =================================================
        // ENVIAR 0x5A HACIA RX
        // =================================================

        repeat(15)
            @(posedge clk_i);

        uart_send_byte(8'h5A);


        // =================================================
        // ESPERAR A QUE EL PROGRAMA TERMINE
        // =================================================

        repeat(100)
            @(posedge clk_i);

        #1;


        // =================================================
        // RESULTADOS
        // =================================================

        $display("");
        $display("============================================");
        $display("UART");
        $display("============================================");

        $display(
            "TX data interno = %h",
            uart_dut.tx_data
        );

        $display(
            "RX data interno = %h",
            uart_dut.rx_data
        );

        $display(
            "new_rx          = %b",
            uart_dut.new_rx
        );

        $display(
            "x5              = %h",
            core_dut.u_rf.registers[5]
        );

        $display(
            "x6              = %h",
            core_dut.u_rf.registers[6]
        );

        $display("");


        // =================================================
        // COMPROBACIONES TX
        // =================================================

        check(
            saw_tx_data,
            "CPU escribe dato UART TX"
        );


        check(
            saw_tx_start,
            "CPU inicia transmision UART"
        );


        check(
            uart_dut.tx_data == 8'h41,
            "UART conserva TX = 0x41"
        );


        // =================================================
        // COMPROBACIONES RX
        // =================================================

        check(
            uart_dut.rx_data == 8'h5A,
            "UART recibe 0x5A"
        );


        check(
            uart_dut.new_rx == 1'b1,
            "UART activa new_rx"
        );


        check(
            core_dut.u_rf.registers[5] == 32'h0000_005A,
            "CPU lee UART RX por MMIO"
        );


        check(
            core_dut.u_rf.registers[6] == 32'h0000_005B,
            "Dato UART utilizable por CPU"
        );


        // =================================================
        // RESULTADO FINAL
        // =================================================

        if (errors == 0) begin

            $display("");
            $display(
                "RISC-V + UART MMIO CORRECTO"
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