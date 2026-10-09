`timescale 1ns/1ps

module tb_riscv_memory;

    logic clk_i = 0;
    logic rst_i;

    logic [31:0] prog_addr;
    logic [31:0] prog_instr;

    logic [31:0] data_addr;
    logic [31:0] data_out;
    logic [31:0] data_in;
    logic        data_we;

    logic [31:0] ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;
    logic        ram_we;

    logic [31:0] pc;

    logic saw_store = 0;

    integer errors = 0;


    // =====================================================
    // RISC-V
    // =====================================================

    riscv_core core_dut (
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .ProgAddress_o  (prog_addr),
        .ProgIn_i       (prog_instr),

        .DataAddress_o  (data_addr),
        .DataOut_o      (data_out),
        .DataIn_i       (data_in),

        .we_o           (data_we),
        .pc_out         (pc)
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

        .uart_addr_o    (),
        .uart_wdata_o   (),
        .uart_we_o      (),
        .uart_rdata_i   (32'b0),

        .j1_rdata_i     (32'b0),

        .ind_addr_o     (),
        .ind_wdata_o    (),
        .ind_we_o       (),
        .ind_rdata_i    (32'b0),

        .vga_addr_o     (),
        .vga_wdata_o    (),
        .vga_we_o       (),
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
    // RELOJ 100 MHz
    // =====================================================

    always #5 clk_i = ~clk_i;


    // =====================================================
    // DETECTAR STORE
    // =====================================================

    always @(posedge clk_i) begin

        if (
            data_we &&
            data_addr == 32'h0000_2000 &&
            data_out == 32'd42
        ) begin

            saw_store <= 1'b1;

        end

    end


    // =====================================================
    // DEBUG DEL LOAD
    // =====================================================

    always @(posedge clk_i) begin

        if (core_dut.mem_read_mem) begin

            $display(
                "DEBUG LOAD | PC=%h | addr=%h | RAM=%h | DataIn=%h | rd=%0d | wb_sel=%0d",
                pc,
                data_addr,
                ram_rdata,
                data_in,
                core_dut.rd_idx_mem,
                core_dut.wb_mux_sel_mem
            );

        end

    end


    // =====================================================
    // DEBUG DEL WRITE BACK
    // =====================================================

    always @(posedge clk_i) begin

        if (core_dut.reg_file_wr_wb) begin

            $display(
                "DEBUG WB   | PC=%h | rd=%0d | wb_data=%h | mem_data_wb=%h | alu=%h | wb_sel=%0d",
                pc,
                core_dut.rd_idx_wb,
                core_dut.wb_data,
                core_dut.mem_data_wb,
                core_dut.alu_out_wb,
                core_dut.wb_mux_sel_wb
            );

        end

    end


    // =====================================================
    // DEBUG DEL BUS DE DATOS
    // =====================================================

    always @(posedge clk_i) begin

        if (
            data_addr >= 32'h0000_2000 &&
            data_addr <= 32'h0000_2FFF
        ) begin

            $display(
                "DEBUG BUS  | addr=%h | DataOut=%h | DataIn=%h | WE=%b | RAMout=%h",
                data_addr,
                data_out,
                data_in,
                data_we,
                ram_rdata
            );

        end

    end


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
    // TEST
    // =====================================================

    initial begin

        rst_i = 1;


        // =================================================
        // PROGRAMA DE PRUEBA
        // =================================================

        #1;


        // -------------------------------------------------
        // lui x1, 0x2
        //
        // x1 = 0x00002000
        // -------------------------------------------------

        rom_dut.memory[0] = 32'h0000_20B7;


        // -------------------------------------------------
        // addi x2, x0, 42
        //
        // x2 = 42
        // -------------------------------------------------

        rom_dut.memory[1] = 32'h02A0_0113;


        // -------------------------------------------------
        // sw x2, 0(x1)
        //
        // RAM[0x2000] = 42
        // -------------------------------------------------

        rom_dut.memory[2] = 32'h0020_A023;


        // -------------------------------------------------
        // lw x3, 0(x1)
        //
        // x3 = RAM[0x2000]
        // -------------------------------------------------

        rom_dut.memory[3] = 32'h0000_A183;


        // -------------------------------------------------
        // addi x4, x3, 1
        //
        // x4 = 43
        //
        // Tambien sirve para comprobar load-use hazard.
        // -------------------------------------------------

        rom_dut.memory[4] = 32'h0011_8213;


        // -------------------------------------------------
        // EBREAK
        // -------------------------------------------------

        rom_dut.memory[5] = 32'h0010_0073;


        // =================================================
        // RESET
        // =================================================

        repeat(4)
            @(posedge clk_i);

        rst_i = 0;


        // =================================================
        // DEJAR AVANZAR EL PIPELINE
        // =================================================

        repeat(30)
            @(posedge clk_i);

        #1;


        // =================================================
        // MOSTRAR ESTADO FINAL
        // =================================================

        $display("");
        $display("============================================");
        $display("REGISTROS FINALES");
        $display("============================================");

        $display(
            "x1 = %h  decimal=%0d",
            core_dut.u_rf.registers[1],
            core_dut.u_rf.registers[1]
        );

        $display(
            "x2 = %h  decimal=%0d",
            core_dut.u_rf.registers[2],
            core_dut.u_rf.registers[2]
        );

        $display(
            "x3 = %h  decimal=%0d",
            core_dut.u_rf.registers[3],
            core_dut.u_rf.registers[3]
        );

        $display(
            "x4 = %h  decimal=%0d",
            core_dut.u_rf.registers[4],
            core_dut.u_rf.registers[4]
        );

        $display("============================================");
        $display("");


        // =================================================
        // MOSTRAR RAM
        // =================================================

        $display(
            "RAM[0] = %h  decimal=%0d",
            ram_dut.memory[0],
            ram_dut.memory[0]
        );

        $display("");


        // =================================================
        // COMPROBACIONES
        // =================================================

        check(
            saw_store,
            "Store generado por RISC-V"
        );


        check(
            ram_dut.memory[0] == 32'd42,
            "RAM[0x2000] = 42"
        );


        check(
            core_dut.u_rf.registers[3] == 32'd42,
            "LW carga x3 = 42"
        );


        check(
            core_dut.u_rf.registers[4] == 32'd43,
            "Load-use x4 = 43"
        );


        // =================================================
        // RESULTADO
        // =================================================

        if (errors == 0) begin

            $display("");
            $display(
                "RISC-V + ROM + RAM + INTERCONNECT CORRECTO"
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