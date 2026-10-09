
module battleship_buzzer_event_controller #(
    parameter integer CLK_FREQ = 100_000_000
)(
    input  logic        clk_i,
    input  logic        rst_i,

    input  logic        uart_we_i,
    input  logic [1:0]  uart_addr_i,
    input  logic [31:0] uart_wdata_i,

    input  logic        ram_we_i,
    input  logic [31:0] ram_addr_i,
    input  logic [31:0] ram_wdata_i,

    output logic [2:0] sound_code_o
);

    // =====================================================
    // CODIGOS DE SONIDO
    // =====================================================

    localparam logic [2:0] SOUND_NONE      = 3'b000;
    localparam logic [2:0] SOUND_START     = 3'b001;
    localparam logic [2:0] SOUND_HIT       = 3'b010;
    localparam logic [2:0] SOUND_MISS      = 3'b011;
    localparam logic [2:0] SOUND_SUNK      = 3'b100;
    localparam logic [2:0] SOUND_INVALID   = 3'b101;
    localparam logic [2:0] SOUND_WIN       = 3'b110;
    localparam logic [2:0] SOUND_PLACEMENT = 3'b111;

    // =====================================================
    // RAM JUGADOR 1
    // =====================================================

    localparam logic [31:0] J1_RAM_START =
        32'h0000_2000;

    localparam logic [31:0] J1_RAM_END =
        32'h0000_20FF;

    // =====================================================
    // BLOQUEO DE SONIDOS DE COLOCACION
    // =====================================================

    localparam integer PLACEMENT_LOCK_CYCLES =
        CLK_FREQ / 50;

    localparam integer PLACEMENT_LOCK_BITS =
        $clog2(PLACEMENT_LOCK_CYCLES + 1);

    logic [PLACEMENT_LOCK_BITS-1:0]
        placement_lock_counter;

    // =====================================================
    // UART
    // =====================================================

    logic tx_write_now;
    logic tx_write_prev;
    logic [7:0] tx_byte;

    assign tx_write_now =
        uart_we_i &&
        (uart_addr_i == 2'b01);

    assign tx_byte = uart_wdata_i[7:0];

    // =====================================================
    // ESTADO DE BATALLA
    // =====================================================

    logic battle_active;

    logic j1_ship_write;

    assign j1_ship_write =
        !battle_active &&
        ram_we_i &&
        (ram_addr_i >= J1_RAM_START) &&
        (ram_addr_i <= J1_RAM_END) &&
        (ram_wdata_i != 32'd0);

    // =====================================================
    // CONTROL PRINCIPAL
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            tx_write_prev <= 1'b0;
            battle_active <= 1'b0;

            placement_lock_counter <= '0;
            sound_code_o <= SOUND_NONE;

        end

        else begin

            // El codigo de sonido es un pulso.
            sound_code_o <= SOUND_NONE;

            tx_write_prev <= tx_write_now;

            if (placement_lock_counter != 0)
                placement_lock_counter <=
                    placement_lock_counter - 1'b1;

            // =============================================
            // EVENTOS UART
            // =============================================

            if (tx_write_now && !tx_write_prev) begin

                // INICIO DE BATALLA
                if (tx_byte == 8'h20) begin

                    battle_active <= 1'b1;
                    sound_code_o <= SOUND_START;

                end

                // =========================================
                // COLOCACION DEL JUGADOR 2
                // =========================================

                else if (!battle_active) begin

                    case (tx_byte)

                        8'h01: begin
                            sound_code_o <=
                                SOUND_PLACEMENT;
                        end

                        8'h02: begin
                            sound_code_o <=
                                SOUND_INVALID;
                        end

                        8'h04: begin
                            sound_code_o <=
                                SOUND_INVALID;
                        end

                        8'h08: begin
                            sound_code_o <=
                                SOUND_INVALID;
                        end

                        default: begin
                            sound_code_o <= SOUND_NONE;
                        end

                    endcase

                end

                // =========================================
                // BATALLA
                // =========================================

                else begin

                    // VICTORIA JUGADOR 1
                    if (tx_byte == 8'h7C) begin

                        sound_code_o <= SOUND_WIN;

                    end

                    // VICTORIA JUGADOR 2
                    else if (tx_byte == 8'h7E) begin

                        sound_code_o <= SOUND_SUNK;

                    end

                    // =====================================
                    // DISPARO JUGADOR 1
                    // =====================================

                    else if (tx_byte[0]) begin

                        if (tx_byte[7])
                            sound_code_o <= SOUND_HIT;
                        else
                            sound_code_o <= SOUND_MISS;

                    end

                    // =====================================
                    // RESPUESTA DISPARO JUGADOR 2
                    // =====================================

                    else begin

                        case (tx_byte)

                            // FALLO
                            8'h00: begin
                                sound_code_o <= SOUND_MISS;
                            end

                            // IMPACTO NORMAL
                            8'h02: begin
                                sound_code_o <= SOUND_HIT;
                            end

                            // DISPARO REPETIDO
                            8'h04: begin
                                sound_code_o <= SOUND_INVALID;
                            end

                            // =================================
                            // NUEVO: BARCO HUNDIDO POR JUGADOR 2
                            //
                            // La ROM nueva envia 0x0A.
                            // =================================
                            8'h0A: begin
                                sound_code_o <= SOUND_SUNK;
                            end

                            default: begin
                                sound_code_o <= SOUND_NONE;
                            end

                        endcase

                    end

                end

            end

            // =============================================
            // COLOCACION JUGADOR 1
            // =============================================

            else if (
                j1_ship_write &&
                (placement_lock_counter == 0)
            ) begin

                sound_code_o <= SOUND_PLACEMENT;

                placement_lock_counter <=
                    PLACEMENT_LOCK_CYCLES;

            end

        end

    end

endmodule
