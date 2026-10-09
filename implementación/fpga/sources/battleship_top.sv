module battleship_top #(
    parameter string ROM_INIT_FILE =
        "placement_both_players.mem"
)(
    // =====================================================
    // CLOCK
    // =====================================================

    input logic clk_100mhz_i,


    // =====================================================
    // SW15
    //
    // RESET GLOBAL
    // =====================================================

    input logic sys_rst_i,


    // =====================================================
    // CONTROLES
    // =====================================================

    input logic btn_up_i,
    input logic btn_down_i,
    input logic btn_left_i,
    input logic btn_right_i,

    // CENTER = reset partida
    input logic btn_center_i,


    // SW0 = confirmar
    input logic sw_sel_i,

    // SW1 = rotar
    input logic sw_rst_i,


    // =====================================================
    // UART
    // =====================================================

    input  logic uart_rx_i,
    output logic uart_tx_o,


    // =====================================================
    // VGA
    // =====================================================

    output logic       vga_hsync_o,
    output logic       vga_vsync_o,

    output logic [3:0] vga_r_o,
    output logic [3:0] vga_g_o,
    output logic [3:0] vga_b_o,


    // =====================================================
    // DISPLAY
    // =====================================================

    output logic [6:0] seg_o,
    output logic [3:0] an_o,
    output logic       dp_o,


    // =====================================================
    // LEDS
    // =====================================================

    output logic [15:0] led_o,


    // =====================================================
    // BUZZER
    // =====================================================

    output logic buzzer_o
);


    // =====================================================
    // CLOCKS
    // =====================================================

    logic clk_system;
    logic clk_pixel;
    logic clk_locked;


    // =====================================================
    // RESET BASE
    // =====================================================

    logic base_rst;


    // =====================================================
    // RESET REQUESTS YA FILTRADOS
    // =====================================================

    logic game_reset_request;
    logic global_reset_request;


    // =====================================================
    // INDICADORES
    // =====================================================

    logic [31:0] display_data;
    logic [31:0] led_data;
    logic [31:0] buzzer_data;


    // =====================================================
    // BUZZER EVENT
    // =====================================================

    logic [2:0] buzzer_event_code;

    logic [31:0] buzzer_driver_data;


    // =====================================================
    // DEBUG
    // =====================================================

    logic [31:0] pc_debug;


    // =====================================================
    // CLOCK GENERATOR
    //
    // IMPORTANTE:
    //
    // SW15 ya NO resetea el Clock Wizard directamente.
    //
    // Necesitamos mantener los clocks funcionando para
    // transmitir 0x30 a Python antes del reset.
    // =====================================================

    battleship_clock_gen clock_gen (
        .clk_100mhz_i (
            clk_100mhz_i
        ),

        .rst_i (
            1'b0
        ),

        .clk_system_o (
            clk_system
        ),

        .clk_pixel_o (
            clk_pixel
        ),

        .locked_o (
            clk_locked
        )
    );


    // =====================================================
    // RESET DE ARRANQUE
    //
    // Mientras el MMCM no esté listo.
    // =====================================================

    assign base_rst =
        ~clk_locked;


    // =====================================================
    // CENTER
    //
    // RESET DE PARTIDA
    // =====================================================

    debounce_j1 #(
        .COUNT_MAX (
            500_000
        )
    ) db_center_reset (
        .clk_i (
            clk_system
        ),

        .rst_i (
            base_rst
        ),

        .signal_i (
            btn_center_i
        ),

        .signal_o (
            game_reset_request
        )
    );


    // =====================================================
    // SW15
    //
    // RESET GLOBAL
    // =====================================================

    debounce_j1 #(
        .COUNT_MAX (
            500_000
        )
    ) db_global_reset (
        .clk_i (
            clk_system
        ),

        .rst_i (
            base_rst
        ),

        .signal_i (
            sys_rst_i
        ),

        .signal_o (
            global_reset_request
        )
    );


    // =====================================================
    // SISTEMA
    // =====================================================

    battleship_system #(
        .UART_CLK_FREQ (
            100_000_000
        ),

        .UART_BAUD_RATE (
            115200
        ),

        .J1_DEBOUNCE_CYCLES (
            500_000
        ),

        .ROM_INIT_FILE (
            ROM_INIT_FILE
        )
    ) system (
        .clk_i (
            clk_system
        ),

        .clk_pixel_i (
            clk_pixel
        ),


        // ---------------------------------------------
        // RESET BASE
        // ---------------------------------------------

        .rst_i (
            base_rst
        ),


        // ---------------------------------------------
        // CENTER
        // ---------------------------------------------

        .game_rst_i (
            game_reset_request
        ),


        // ---------------------------------------------
        // SW15
        // ---------------------------------------------

        .global_rst_i (
            global_reset_request
        ),


        // ---------------------------------------------
        // FLECHAS
        // ---------------------------------------------

        .btn_up_i (
            btn_up_i
        ),

        .btn_down_i (
            btn_down_i
        ),

        .btn_left_i (
            btn_left_i
        ),

        .btn_right_i (
            btn_right_i
        ),


        // ---------------------------------------------
        // SW1 = ROTACION
        // ---------------------------------------------

        .btn_sel_i (
            sw_rst_i
        ),


        // ---------------------------------------------
        // SW0 = CONFIRMAR / DISPARAR
        // ---------------------------------------------

        .btn_ok_i (
            sw_sel_i
        ),


        .btn_rst_i (
            1'b0
        ),


        // ---------------------------------------------
        // UART
        // ---------------------------------------------

        .uart_rx_i (
            uart_rx_i
        ),

        .uart_tx_o (
            uart_tx_o
        ),


        // ---------------------------------------------
        // VGA
        // ---------------------------------------------

        .vga_hsync_o (
            vga_hsync_o
        ),

        .vga_vsync_o (
            vga_vsync_o
        ),

        .vga_r_o (
            vga_r_o
        ),

        .vga_g_o (
            vga_g_o
        ),

        .vga_b_o (
            vga_b_o
        ),


        // ---------------------------------------------
        // INDICADORES
        // ---------------------------------------------

        .display_data_o (
            display_data
        ),

        .led_data_o (
            led_data
        ),

        .buzzer_data_o (
            buzzer_data
        ),


        // ---------------------------------------------
        // BUZZER
        // ---------------------------------------------

        .buzzer_event_code_o (
            buzzer_event_code
        ),


        // ---------------------------------------------
        // DEBUG
        // ---------------------------------------------

        .pc_debug_o (
            pc_debug
        )
    );


    // =====================================================
    // DISPLAY
    // =====================================================

    battleship_sevenseg_driver #(
        .REFRESH_DIV (
            50_000
        )
    ) sevenseg_driver (
        .clk_i (
            clk_system
        ),

        // SW15 puede reiniciar visualmente el display.
        // CENTER NO.
        .rst_i (
            base_rst |
            global_reset_request
        ),

        .display_data_i (
            display_data
        ),

        .seg_o (
            seg_o
        ),

        .an_o (
            an_o
        )
    );


    // =====================================================
    // DP
    // =====================================================

    assign dp_o =
        1'b1;


    // =====================================================
    // LEDS
    // =====================================================

    assign led_o =
        led_data[15:0];


    // =====================================================
    // BUZZER DATA
    // =====================================================

    assign buzzer_driver_data =

        (buzzer_event_code != 3'b000)

        ? {
            29'd0,
            buzzer_event_code
        }

        : buzzer_data;


    // =====================================================
    // BUZZER
    // =====================================================

    battleship_buzzer_driver #(
        .CLK_FREQ (
            100_000_000
        )
    ) buzzer_driver (
        .clk_i (
            clk_system
        ),

        .rst_i (
            base_rst |
            game_reset_request |
            global_reset_request
        ),

        .buzzer_data_i (
            buzzer_driver_data
        ),

        .buzzer_o (
            buzzer_o
        )
    );


endmodule