module memory_interconnect (

    // =====================================================
    // INTERFAZ CON RISC-V
    // =====================================================

    input  logic [31:0] data_address_i,
    input  logic [31:0] data_out_i,
    input  logic        data_we_i,
    output logic [31:0] data_in_o,


    // =====================================================
    // RAM
    // =====================================================

    output logic [31:0] ram_addr_o,
    output logic [31:0] ram_wdata_o,
    output logic        ram_we_o,
    input  logic [31:0] ram_rdata_i,


    // =====================================================
    // UART
    // =====================================================

    output logic [1:0]  uart_addr_o,
    output logic [31:0] uart_wdata_o,
    output logic        uart_we_o,
    input  logic [31:0] uart_rdata_i,


    // =====================================================
    // ENTRADAS JUGADOR 1
    // =====================================================

    input logic [31:0] j1_rdata_i,


    // =====================================================
    // INDICADORES
    // =====================================================

    output logic [1:0]  ind_addr_o,
    output logic [31:0] ind_wdata_o,
    output logic        ind_we_o,
    input  logic [31:0] ind_rdata_i,


    // =====================================================
    // VGA
    // =====================================================

    output logic [8:0]  vga_addr_o,
    output logic [31:0] vga_wdata_o,
    output logic        vga_we_o,
    input  logic [31:0] vga_rdata_i
);


    // =====================================================
    // DIRECCIONES
    // =====================================================

    localparam logic [31:0] RAM_START = 32'h0000_2000;
    localparam logic [31:0] RAM_END   = 32'h0000_2FFF;

    localparam logic [31:0] UART_CTRL = 32'h0001_0040;
    localparam logic [31:0] UART_TX   = 32'h0001_0044;
    localparam logic [31:0] UART_RX   = 32'h0001_0048;

    localparam logic [31:0] J1_STATUS = 32'h0001_0120;

    localparam logic [31:0] DISPLAY   = 32'h0001_0130;
    localparam logic [31:0] LED       = 32'h0001_0138;
    localparam logic [31:0] BUZZER    = 32'h0001_0140;

    localparam logic [31:0] VGA_START = 32'h0001_1000;
    localparam logic [31:0] VGA_END   = 32'h0001_17FF;


    // =====================================================
    // DECODIFICACIÓN
    // =====================================================

    always_comb begin

        // =================================================
        // VALORES POR DEFECTO
        // =================================================

        data_in_o = 32'b0;


        // -------------------------------------------------
        // RAM
        // -------------------------------------------------

        ram_addr_o  = data_address_i;
        ram_wdata_o = data_out_i;
        ram_we_o    = 1'b0;


        // -------------------------------------------------
        // UART
        // -------------------------------------------------

        uart_addr_o  = 2'b00;
        uart_wdata_o = data_out_i;
        uart_we_o    = 1'b0;


        // -------------------------------------------------
        // INDICADORES
        // -------------------------------------------------

        ind_addr_o  = 2'b00;
        ind_wdata_o = data_out_i;
        ind_we_o    = 1'b0;


        // -------------------------------------------------
        // VGA
        // -------------------------------------------------

        vga_addr_o  = 9'b0;
        vga_wdata_o = data_out_i;
        vga_we_o    = 1'b0;


        // =================================================
        // RAM
        // =================================================

        if (
            data_address_i >= RAM_START &&
            data_address_i <= RAM_END
        ) begin

            ram_we_o = data_we_i;

            data_in_o = ram_rdata_i;

        end


        // =================================================
        // UART CONTROL
        //
        // 0x0001_0040
        // addr interno = 00
        // =================================================

        else if (data_address_i == UART_CTRL) begin

            uart_addr_o = 2'b00;
            uart_we_o   = data_we_i;

            data_in_o = uart_rdata_i;

        end


        // =================================================
        // UART TX
        //
        // 0x0001_0044
        // addr interno = 01
        // =================================================

        else if (data_address_i == UART_TX) begin

            uart_addr_o = 2'b01;
            uart_we_o   = data_we_i;

            data_in_o = uart_rdata_i;

        end


        // =================================================
        // UART RX
        //
        // 0x0001_0048
        // addr interno = 10
        // =================================================

        else if (data_address_i == UART_RX) begin

            uart_addr_o = 2'b10;
            uart_we_o   = data_we_i;

            data_in_o = uart_rdata_i;

        end


        // =================================================
        // ENTRADAS JUGADOR 1
        // =================================================

        else if (data_address_i == J1_STATUS) begin

            data_in_o = j1_rdata_i;

        end


        // =================================================
        // DISPLAY
        // =================================================

        else if (data_address_i == DISPLAY) begin

            ind_addr_o = 2'b00;
            ind_we_o   = data_we_i;

            data_in_o = ind_rdata_i;

        end


        // =================================================
        // LED
        // =================================================

        else if (data_address_i == LED) begin

            ind_addr_o = 2'b01;
            ind_we_o   = data_we_i;

            data_in_o = ind_rdata_i;

        end


        // =================================================
        // BUZZER
        // =================================================

        else if (data_address_i == BUZZER) begin

            ind_addr_o = 2'b10;
            ind_we_o   = data_we_i;

            data_in_o = ind_rdata_i;

        end


        // =================================================
        // VGA
        // =================================================

        else if (
            data_address_i >= VGA_START &&
            data_address_i <= VGA_END
        ) begin

            vga_addr_o =
                (data_address_i - VGA_START) >> 2;

            vga_we_o = data_we_i;

            data_in_o = vga_rdata_i;

        end

    end

endmodule