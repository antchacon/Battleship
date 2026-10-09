
module battleship_system #(
    parameter int UART_CLK_FREQ = 100_000_000,
    parameter int UART_BAUD_RATE = 115200,
    parameter int J1_DEBOUNCE_CYCLES = 500_000,
    parameter string ROM_INIT_FILE = ""
)(
    input logic clk_i,
    input logic clk_pixel_i,
    input logic rst_i,
    input logic game_rst_i,
    input logic global_rst_i,

    input logic btn_up_i,
    input logic btn_down_i,
    input logic btn_left_i,
    input logic btn_right_i,
    input logic btn_sel_i,
    input logic btn_ok_i,
    input logic btn_rst_i,

    input logic uart_rx_i,
    output logic uart_tx_o,

    output logic vga_hsync_o,
    output logic vga_vsync_o,
    output logic [3:0] vga_r_o,
    output logic [3:0] vga_g_o,
    output logic [3:0] vga_b_o,

    output logic [31:0] display_data_o,
    output logic [31:0] led_data_o,
    output logic [31:0] buzzer_data_o,
    output logic [2:0] buzzer_event_code_o,
    output logic [31:0] pc_debug_o
);

    // =====================================================
    // RESET
    // =====================================================

    logic game_reset_pulse;
    logic global_reset_pulse;
    logic game_logic_rst;
    logic victory_counter_rst;
    logic allow_game_reset;

    // =====================================================
    // CPU
    // =====================================================

    logic [31:0] prog_address;
    logic [31:0] prog_instr;
    logic [31:0] data_address;
    logic [31:0] data_out;
    logic [31:0] data_in;
    logic data_we;

    // =====================================================
    // RAM
    // =====================================================

    logic [31:0] ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;
    logic ram_we;

    // =====================================================
    // UART
    // =====================================================

    logic [1:0] uart_cpu_addr;
    logic [31:0] uart_cpu_wdata;
    logic uart_cpu_we;
    logic [31:0] uart_rdata;

    logic [1:0] uart_bus_addr;
    logic [31:0] uart_bus_wdata;
    logic uart_bus_we;

    // =====================================================
    // EVENTOS UART
    // =====================================================

    logic event_take_uart;
    logic event_uart_we;
    logic [1:0] event_uart_addr;
    logic [31:0] event_uart_wdata;

    // =====================================================
    // JUGADOR 1
    // =====================================================

    logic [31:0] j1_rdata;

    // =====================================================
    // INDICADORES
    // =====================================================

    logic [1:0] ind_addr;
    logic [31:0] ind_wdata;
    logic [31:0] ind_rdata;
    logic ind_we;
    logic [31:0] display_mmio_data;

    // =====================================================
    // VGA
    // =====================================================

    logic [8:0] vga_addr;
    logic [31:0] vga_wdata;
    logic [31:0] vga_rdata;
    logic vga_we;

    // =====================================================
    // ESTADOS
    // =====================================================

    logic [1:0] ui_phase;
    logic ui_turn;
    logic [3:0] ui_notice;
    logic [1:0] ui_winner;

    logic ui_j2_ready;
    logic ui_j1_ready;
    logic j1_ready_pulse;

    // =====================================================
    // HABILITACION DE CENTER
    //
    // No permitir reset durante la colocacion incompleta.
    // Permitirlo durante batalla o cuando ambas flotas
    // esten listas.
    // =====================================================

    assign allow_game_reset =
        (ui_phase != 2'd0) ||
        (ui_j1_ready && ui_j2_ready);

    assign game_logic_rst =
        rst_i |
        game_reset_pulse |
        global_reset_pulse;

    // CENTER NO REINICIA EL CONTADOR DE VICTORIAS.
    assign victory_counter_rst =
        rst_i |
        global_reset_pulse;

    // =====================================================
    // PROCESADOR
    // =====================================================

    riscv_core cpu (
        .clk_i(clk_i),
        .rst_i(game_logic_rst),
        .ProgAddress_o(prog_address),
        .ProgIn_i(prog_instr),
        .DataAddress_o(data_address),
        .DataOut_o(data_out),
        .DataIn_i(data_in),
        .we_o(data_we),
        .pc_out(pc_debug_o)
    );

    // =====================================================
    // ROM
    // =====================================================

    program_rom #(
        .INIT_FILE(ROM_INIT_FILE)
    ) rom (
        .clk_i(clk_i),
        .rst_i(game_logic_rst),
        .prog_address_i(prog_address),
        .prog_instr_o(prog_instr)
    );

    // =====================================================
    // INTERCONNECT
    // =====================================================

    memory_interconnect mem_interconnect_u (
        .data_address_i(data_address),
        .data_out_i(data_out),
        .data_we_i(data_we),
        .data_in_o(data_in),

        .ram_addr_o(ram_addr),
        .ram_wdata_o(ram_wdata),
        .ram_we_o(ram_we),
        .ram_rdata_i(ram_rdata),

        .uart_addr_o(uart_cpu_addr),
        .uart_wdata_o(uart_cpu_wdata),
        .uart_we_o(uart_cpu_we),
        .uart_rdata_i(uart_rdata),

        .j1_rdata_i(j1_rdata),

        .ind_addr_o(ind_addr),
        .ind_wdata_o(ind_wdata),
        .ind_we_o(ind_we),
        .ind_rdata_i(ind_rdata),

        .vga_addr_o(vga_addr),
        .vga_wdata_o(vga_wdata),
        .vga_we_o(vga_we),
        .vga_rdata_i(vga_rdata)
    );

    // =====================================================
    // RAM
    // =====================================================

    data_ram ram (
        .clk_i(clk_i),
        .addr_i(ram_addr),
        .wdata_i(ram_wdata),
        .write_enable_i(ram_we),
        .rdata_o(ram_rdata)
    );

    // =====================================================
    // ENTRADAS J1
    // =====================================================

    j1_inputs_mmio #(
        .DEBOUNCE_CYCLES(J1_DEBOUNCE_CYCLES)
    ) j1_inputs (
        .clk_i(clk_i),
        .rst_i(game_logic_rst),

        .btn_up_i(btn_up_i),
        .btn_down_i(btn_down_i),
        .btn_left_i(btn_left_i),
        .btn_right_i(btn_right_i),

        .btn_sel_i(btn_sel_i),
        .btn_ok_i(btn_ok_i),
        .btn_rst_i(1'b0),

        .rdata_o(j1_rdata)
    );

    // =====================================================
    // MONITOR VGA
    // =====================================================

    battleship_vga_ui_monitor #(
        .CLK_FREQ(UART_CLK_FREQ),
        .NOTICE_MS(8000),
        .J1_CHECK_US(1000)
    ) vga_ui_monitor (
        .clk_i(clk_i),
        .rst_i(game_logic_rst),

        .uart_we_i(uart_bus_we),
        .uart_addr_i(uart_bus_addr),
        .uart_wdata_i(uart_bus_wdata),

        .j1_status_i(j1_rdata),

        .vga_we_i(vga_we),
        .vga_addr_i(vga_addr),
        .vga_wdata_i(vga_wdata),

        .ram_we_i(ram_we),
        .ram_addr_i(ram_addr),
        .ram_wdata_i(ram_wdata),

        .ui_phase_o(ui_phase),
        .ui_turn_o(ui_turn),
        .ui_notice_o(ui_notice),
        .ui_winner_o(ui_winner),

        .ui_j2_ready_o(ui_j2_ready),
        .ui_j1_ready_o(ui_j1_ready),
        .j1_ready_pulse_o(j1_ready_pulse)
    );

    // =====================================================
    // RESET Y EVENTOS UART
    // =====================================================

    battleship_reset_uart_controller #(
        .RESET_EVENT(8'h30),
        .J1_READY_EVENT(8'h31)
    ) reset_controller (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .game_reset_request_i(
            game_rst_i && allow_game_reset
        ),

        .global_reset_request_i(global_rst_i),
        .j1_ready_request_i(j1_ready_pulse),

        .uart_rdata_i(uart_rdata),

        .take_uart_o(event_take_uart),
        .uart_we_o(event_uart_we),
        .uart_addr_o(event_uart_addr),
        .uart_wdata_o(event_uart_wdata),

        .game_reset_pulse_o(game_reset_pulse),
        .global_reset_pulse_o(global_reset_pulse)
    );

    // =====================================================
    // MULTIPLEXOR UART
    // =====================================================

    always_comb begin

        if (event_take_uart) begin
            uart_bus_addr = event_uart_addr;
            uart_bus_wdata = event_uart_wdata;
            uart_bus_we = event_uart_we;
        end

        else begin
            uart_bus_addr = uart_cpu_addr;
            uart_bus_wdata = uart_cpu_wdata;
            uart_bus_we = uart_cpu_we;
        end
    end

    // =====================================================
    // UART FISICA
    // =====================================================

    uart_peripheral #(
        .CLK_FREQ(UART_CLK_FREQ),
        .BAUD_RATE(UART_BAUD_RATE)
    ) uart (
        .clk_i(clk_i),
        .rst_i(game_logic_rst),

        .write_enable_i(uart_bus_we),
        .addr_i(uart_bus_addr),
        .wdata_i(uart_bus_wdata),
        .rdata_o(uart_rdata),

        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o)
    );

    // =====================================================
    // BUZZER
    // =====================================================

    battleship_buzzer_event_controller #(
        .CLK_FREQ(UART_CLK_FREQ)
    ) buzzer_event_controller (
        .clk_i(clk_i),
        .rst_i(game_logic_rst),

        .uart_we_i(uart_bus_we),
        .uart_addr_i(uart_bus_addr),
        .uart_wdata_i(uart_bus_wdata),

        .ram_we_i(ram_we),
        .ram_addr_i(ram_addr),
        .ram_wdata_i(ram_wdata),

        .sound_code_o(buzzer_event_code_o)
    );

    // =====================================================
    // INDICADORES
    // =====================================================

    indicators_mmio indicators (
        .clk_i(clk_i),
        .rst_i(game_logic_rst),

        .write_enable_i(ind_we),
        .addr_i(ind_addr),
        .wdata_i(ind_wdata),
        .rdata_o(ind_rdata),

        .display_data_o(display_mmio_data),
        .led_data_o(led_data_o),
        .buzzer_data_o(buzzer_data_o)
    );

    // =====================================================
    // CONTADOR DE VICTORIAS
    // =====================================================

    battleship_victory_counter victory_counter (
        .clk_i(clk_i),
        .rst_i(victory_counter_rst),
        .winner_i(ui_winner),
        .display_data_o(display_data_o)
    );

    // =====================================================
    // VGA CORE
    // =====================================================

    battleship_vga_core vga (
        .clk_i(clk_i),
        .clk_pixel_i(clk_pixel_i),
        .rst_i(game_logic_rst),

        .cpu_addr_i(vga_addr),
        .cpu_wdata_i(vga_wdata),
        .cpu_we_i(vga_we),
        .cpu_rdata_o(vga_rdata),

        .ui_phase_i(ui_phase),
        .ui_turn_i(ui_turn),
        .ui_notice_i(ui_notice),
        .ui_winner_i(ui_winner),
        .ui_j2_ready_i(ui_j2_ready),

        .hsync_o(vga_hsync_o),
        .vsync_o(vga_vsync_o),

        .vga_r_o(vga_r_o),
        .vga_g_o(vga_g_o),
        .vga_b_o(vga_b_o)
    );

endmodule
