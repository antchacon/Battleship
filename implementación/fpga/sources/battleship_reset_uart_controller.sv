module battleship_reset_uart_controller #(
    parameter logic [7:0] RESET_EVENT    = 8'h30,
    parameter logic [7:0] J1_READY_EVENT = 8'h31
)(
    input  logic        clk_i,
    input  logic        rst_i,


    // =====================================================
    // RESET
    // =====================================================

    input  logic        game_reset_request_i,
    input  logic        global_reset_request_i,


    // =====================================================
    // J1 TERMINO COLOCACION
    // =====================================================

    input  logic        j1_ready_request_i,


    // =====================================================
    // UART
    // =====================================================

    input  logic [31:0] uart_rdata_i,


    output logic        take_uart_o,

    output logic        uart_we_o,
    output logic [1:0]  uart_addr_o,
    output logic [31:0] uart_wdata_o,


    // =====================================================
    // RESET REAL
    // =====================================================

    output logic        game_reset_pulse_o,
    output logic        global_reset_pulse_o
);


    localparam logic [1:0] UART_CONTROL =
        2'b00;

    localparam logic [1:0] UART_DATA_TX =
        2'b01;


    // =====================================================
    // ACCIONES
    // =====================================================

    localparam logic [1:0] ACTION_READY =
        2'd0;

    localparam logic [1:0] ACTION_GAME =
        2'd1;

    localparam logic [1:0] ACTION_GLOBAL =
        2'd2;


    // =====================================================
    // FSM
    // =====================================================

    typedef enum logic [3:0] {

        IDLE,

        WAIT_UART_IDLE,

        WRITE_EVENT_BYTE,

        START_TRANSMISSION,

        WAIT_BUSY_HIGH,

        WAIT_BUSY_LOW,

        ISSUE_RESET,

        WAIT_RELEASE

    } state_t;


    state_t state;


    logic [1:0] pending_action;

    logic [7:0] pending_byte;


    // =====================================================
    // FSM
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            state <=
                IDLE;

            pending_action <=
                ACTION_READY;

            pending_byte <=
                J1_READY_EVENT;

        end

        else begin

            case (state)


                // =========================================
                // ESPERAR EVENTO
                // =========================================

                IDLE: begin

                    // SW15 primero
                    if (
                        global_reset_request_i
                    ) begin

                        pending_action <=
                            ACTION_GLOBAL;

                        pending_byte <=
                            RESET_EVENT;

                        state <=
                            WAIT_UART_IDLE;

                    end


                    // CENTER
                    else if (
                        game_reset_request_i
                    ) begin

                        pending_action <=
                            ACTION_GAME;

                        pending_byte <=
                            RESET_EVENT;

                        state <=
                            WAIT_UART_IDLE;

                    end


                    // J1 terminó sus barcos
                    else if (
                        j1_ready_request_i
                    ) begin

                        pending_action <=
                            ACTION_READY;

                        pending_byte <=
                            J1_READY_EVENT;

                        state <=
                            WAIT_UART_IDLE;

                    end

                end


                // =========================================
                // ESPERAR UART LIBRE
                // =========================================

                WAIT_UART_IDLE: begin

                    if (
                        uart_rdata_i[0] ==
                        1'b0
                    ) begin

                        state <=
                            WRITE_EVENT_BYTE;

                    end

                end


                // =========================================
                // CARGAR BYTE
                // =========================================

                WRITE_EVENT_BYTE: begin

                    state <=
                        START_TRANSMISSION;

                end


                // =========================================
                // COMENZAR TX
                // =========================================

                START_TRANSMISSION: begin

                    state <=
                        WAIT_BUSY_HIGH;

                end


                // =========================================
                // ESPERAR BUSY
                // =========================================

                WAIT_BUSY_HIGH: begin

                    if (
                        uart_rdata_i[0] ==
                        1'b1
                    ) begin

                        state <=
                            WAIT_BUSY_LOW;

                    end

                end


                // =========================================
                // ESPERAR FIN
                // =========================================

                WAIT_BUSY_LOW: begin

                    if (
                        uart_rdata_i[0] ==
                        1'b0
                    ) begin


                        // 0x31 no genera reset
                        if (
                            pending_action ==
                            ACTION_READY
                        ) begin

                            state <=
                                IDLE;

                        end


                        // 0x30 sí
                        else begin

                            state <=
                                ISSUE_RESET;

                        end

                    end

                end


                // =========================================
                // RESET
                // =========================================

                ISSUE_RESET: begin

                    state <=
                        WAIT_RELEASE;

                end


                // =========================================
                // ESPERAR LIBERACION DEL BOTON/SW
                // =========================================

                WAIT_RELEASE: begin

                    if (
                        !game_reset_request_i
                        &&
                        !global_reset_request_i
                    ) begin

                        state <=
                            IDLE;

                    end

                end


                default: begin

                    state <=
                        IDLE;

                end

            endcase

        end

    end


    // =====================================================
    // SALIDAS
    // =====================================================

    always_comb begin

        take_uart_o =
            1'b0;

        uart_we_o =
            1'b0;

        uart_addr_o =
            UART_CONTROL;

        uart_wdata_o =
            32'd0;


        game_reset_pulse_o =
            1'b0;

        global_reset_pulse_o =
            1'b0;


        case (state)


            WAIT_UART_IDLE: begin

                take_uart_o =
                    1'b1;

                uart_addr_o =
                    UART_CONTROL;

            end


            WRITE_EVENT_BYTE: begin

                take_uart_o =
                    1'b1;

                uart_we_o =
                    1'b1;

                uart_addr_o =
                    UART_DATA_TX;

                uart_wdata_o = {
                    24'd0,
                    pending_byte
                };

            end


            START_TRANSMISSION: begin

                take_uart_o =
                    1'b1;

                uart_we_o =
                    1'b1;

                uart_addr_o =
                    UART_CONTROL;

                uart_wdata_o =
                    32'h0000_0001;

            end


            WAIT_BUSY_HIGH,
            WAIT_BUSY_LOW: begin

                take_uart_o =
                    1'b1;

                uart_addr_o =
                    UART_CONTROL;

            end


            ISSUE_RESET: begin

                take_uart_o =
                    1'b1;


                if (
                    pending_action ==
                    ACTION_GLOBAL
                ) begin

                    global_reset_pulse_o =
                        1'b1;

                end

                else begin

                    game_reset_pulse_o =
                        1'b1;

                end

            end


            default: begin
            end

        endcase

    end


endmodule