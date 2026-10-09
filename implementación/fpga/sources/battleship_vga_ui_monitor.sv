module battleship_vga_ui_monitor #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer NOTICE_MS = 8000,
    parameter integer J1_CHECK_US = 1000
)(
    input logic clk_i,
    input logic rst_i,

    input logic uart_we_i,
    input logic [1:0] uart_addr_i,
    input logic [31:0] uart_wdata_i,

    input logic [31:0] j1_status_i,

    input logic vga_we_i,
    input logic [8:0] vga_addr_i,
    input logic [31:0] vga_wdata_i,

    input logic ram_we_i,
    input logic [31:0] ram_addr_i,
    input logic [31:0] ram_wdata_i,

    output logic [1:0] ui_phase_o,
    output logic ui_turn_o,
    output logic [3:0] ui_notice_o,
    output logic [1:0] ui_winner_o,

    output logic ui_j2_ready_o,
    output logic ui_j1_ready_o,
    output logic j1_ready_pulse_o
);

    localparam logic [1:0] PHASE_PLACEMENT = 2'd0;
    localparam logic [1:0] PHASE_BATTLE = 2'd1;
    localparam logic [1:0] PHASE_GAME_OVER = 2'd2;

    localparam logic [3:0] NOTICE_NONE = 4'd0;
    localparam logic [3:0] NOTICE_ACCEPTED = 4'd1;
    localparam logic [3:0] NOTICE_OVERLAP = 4'd2;
    localparam logic [3:0] NOTICE_OUTSIDE = 4'd3;
    localparam logic [3:0] NOTICE_J1_HIT = 4'd4;
    localparam logic [3:0] NOTICE_J1_MISS = 4'd5;
    localparam logic [3:0] NOTICE_J2_HIT = 4'd6;
    localparam logic [3:0] NOTICE_J2_MISS = 4'd7;
    localparam logic [3:0] NOTICE_J2_REPEAT = 4'd8;
    localparam logic [3:0] NOTICE_BATTLE_START = 4'd9;
    localparam logic [3:0] NOTICE_J2_SUNK = 4'd10;
    localparam logic [3:0] NOTICE_J1_REPEAT = 4'd11;
    localparam logic [3:0] NOTICE_J1_SUNK = 4'd12;

    localparam logic [1:0] WINNER_NONE = 2'd0;
    localparam logic [1:0] WINNER_J1 = 2'd1;
    localparam logic [1:0] WINNER_J2 = 2'd2;

    localparam integer NOTICE_CYCLES =
        (CLK_FREQ / 1000) * NOTICE_MS;

    localparam integer NOTICE_BITS =
        (NOTICE_CYCLES <= 1) ? 1 :
        $clog2(NOTICE_CYCLES + 1);

    localparam integer J1_CHECK_CYCLES =
        (CLK_FREQ / 1_000_000) * J1_CHECK_US;

    localparam integer J1_CHECK_BITS =
        (J1_CHECK_CYCLES <= 1) ? 1 :
        $clog2(J1_CHECK_CYCLES + 1);

    localparam logic [31:0] J1_RAM_START = 32'h0000_2000;
    localparam logic [31:0] J1_RAM_END = 32'h0000_20FF;

    logic [NOTICE_BITS-1:0] notice_counter;
    logic [J1_CHECK_BITS-1:0] j1_check_counter;

    logic [7:0] tx_byte;
    logic tx_write_now;
    logic tx_write_prev;

    logic j1_ok_prev;
    logic j1_attempt_active;
    logic j1_ship_write;

    logic [1:0] j1_accept_count;
    logic [1:0] j2_accept_count;

    logic [255:0] j1_shots_seen;
    logic [8:0] j1_cursor_addr;
    logic j1_cursor_valid;
    logic j1_fire_prev;

    // Posiciones reales guardadas en RAM (8 x 8).
    logic [63:0] j1_cells;
    logic [63:0] j2_len4, j2_len3, j2_len2;
    logic [63:0] j2_hits;

    // El tile 5 indica el inicio de la previsualizacion J1.
    logic [2:0] preview_row, preview_col;
    logic preview_valid;
    logic [3:0] directions_prev;

    wire j1_confirm_edge = j1_status_i[5] && !j1_ok_prev;
    wire [3:0] directions_now = j1_status_i[3:0];
    wire [3:0] directions_rising = directions_now & ~directions_prev;

    wire [2:0] ship_length = (j1_accept_count == 0) ? 3'd4 :
                             (j1_accept_count == 1) ? 3'd3 : 3'd2;

    logic placement_outside;
    logic placement_overlap;
    logic border_movement;
    logic [5:0] shot_index;
    logic [63:0] shot_bit;
    logic last_hit_4, last_hit_3, last_hit_2;
    logic target_sunk;

    logic [3:0] row_check, col_check;
    logic [5:0] cell_index;
    always_comb begin
        placement_outside = !preview_valid;
        placement_overlap = 1'b0;
        row_check = 4'd0;
        col_check = 4'd0;
        cell_index = 6'd0;
        for (integer n=0; n<4; n=n+1) begin
            if (n < ship_length && preview_valid) begin
                row_check = {1'b0, preview_row} +
                            (j1_status_i[4] ? n[3:0] : 4'd0);
                col_check = {1'b0, preview_col} +
                            (j1_status_i[4] ? 4'd0 : n[3:0]);
                cell_index = {row_check[2:0], col_check[2:0]};
                if (row_check > 4'd7 || col_check > 4'd7)
                    placement_outside = 1'b1;
                else if (j1_cells[cell_index])
                    placement_overlap = 1'b1;
            end
        end

        border_movement = 1'b0;
        if (preview_valid) begin
            if (directions_rising[0] && preview_row==0) border_movement=1'b1;
            if (directions_rising[2] && preview_col==0) border_movement=1'b1;
            if (directions_rising[1] &&
                (preview_row + (j1_status_i[4] ? ship_length : 1) >= 8))
                border_movement=1'b1;
            if (directions_rising[3] &&
                (preview_col + (j1_status_i[4] ? 1 : ship_length) >= 8))
                border_movement=1'b1;
        end

        shot_index = {tx_byte[6:4], tx_byte[3:1]};
        shot_bit = (64'h1 << shot_index);
        // La comprobacion es paralela para cada barco.
        // Evita un multiplexor de 64 bits y una comparacion posterior.
        last_hit_4 = j2_len4[shot_index] &&
                     ((j2_len4 & ~(j2_hits | shot_bit)) == 64'd0);
        last_hit_3 = j2_len3[shot_index] &&
                     ((j2_len3 & ~(j2_hits | shot_bit)) == 64'd0);
        last_hit_2 = j2_len2[shot_index] &&
                     ((j2_len2 & ~(j2_hits | shot_bit)) == 64'd0);
        target_sunk = !j2_hits[shot_index] &&
                      (last_hit_4 || last_hit_3 || last_hit_2);
    end

    assign tx_byte = uart_wdata_i[7:0];

    assign tx_write_now =
        uart_we_i && (uart_addr_i == 2'b01);

    assign j1_ship_write =
        (ui_phase_o == PHASE_PLACEMENT) &&
        ram_we_i &&
        (ram_addr_i >= J1_RAM_START) &&
        (ram_addr_i <= J1_RAM_END) &&
        (ram_wdata_i != 32'd0);

    always_ff @(posedge clk_i) begin

        if (rst_i) begin
            ui_phase_o <= PHASE_PLACEMENT;
            ui_turn_o <= 1'b0;
            ui_notice_o <= NOTICE_NONE;
            ui_winner_o <= WINNER_NONE;

            ui_j2_ready_o <= 1'b0;
            ui_j1_ready_o <= 1'b0;
            j1_ready_pulse_o <= 1'b0;

            notice_counter <= '0;
            j1_check_counter <= '0;

            tx_write_prev <= 1'b0;
            j1_ok_prev <= 1'b0;
            j1_attempt_active <= 1'b0;

            j1_accept_count <= 2'd0;
            j2_accept_count <= 2'd0;

            j1_shots_seen <= '0;
            j1_cursor_addr <= 9'd0;
            j1_cursor_valid <= 1'b0;
            j1_fire_prev <= 1'b0;
            j1_cells <= 64'd0;
            j2_len4 <= 64'd0;
            j2_len3 <= 64'd0;
            j2_len2 <= 64'd0;
            j2_hits <= 64'd0;
            preview_row <= 3'd0;
            preview_col <= 3'd0;
            preview_valid <= 1'b0;
            directions_prev <= 4'd0;
        end

        else begin

            j1_ready_pulse_o <= 1'b0;

            tx_write_prev <= tx_write_now;
            j1_ok_prev <= j1_status_i[5];
            j1_fire_prev <= j1_status_i[5];
            directions_prev <= directions_now;

            // Registrar solo escrituras del mapa, no inferir
            // colisiones mediante retardos.
            if (ui_phase_o==PHASE_PLACEMENT && ram_we_i &&
                ram_addr_i>=32'h00002000 && ram_addr_i<=32'h000020FC &&
                ram_addr_i[1:0]==2'b00) begin
                if (ram_wdata_i!=0)
                    j1_cells[ram_addr_i[7:2]] <= 1'b1;
                else
                    j1_cells[ram_addr_i[7:2]] <= 1'b0;
            end
            if (ui_phase_o==PHASE_PLACEMENT && ram_we_i &&
                ram_addr_i>=32'h00002100 && ram_addr_i<=32'h000021FC &&
                ram_addr_i[1:0]==2'b00) begin
                case (ram_wdata_i)
                    32'd4: j2_len4[ram_addr_i[7:2]] <= 1'b1;
                    32'd3: j2_len3[ram_addr_i[7:2]] <= 1'b1;
                    32'd2: j2_len2[ram_addr_i[7:2]] <= 1'b1;
                    default: begin end
                endcase
            end

            // Primera celda de la previsualizacion del barco.
            // Decodificacion por rangos: evita division y modulo entre 20,
            // que sintetizan mucha logica en una FPGA pequena.
            if (ui_phase_o == PHASE_PLACEMENT && vga_we_i &&
                vga_wdata_i[2:0] == 3'd5) begin
                if (vga_addr_i >= 9'd61 && vga_addr_i <= 9'd68) begin
                    preview_row <= 3'd0;
                    preview_col <= vga_addr_i - 9'd61;
                    preview_valid <= 1'b1;
                end else if (vga_addr_i >= 9'd81 && vga_addr_i <= 9'd88) begin
                    preview_row <= 3'd1;
                    preview_col <= vga_addr_i - 9'd81;
                    preview_valid <= 1'b1;
                end else if (vga_addr_i >= 9'd101 && vga_addr_i <= 9'd108) begin
                    preview_row <= 3'd2;
                    preview_col <= vga_addr_i - 9'd101;
                    preview_valid <= 1'b1;
                end else if (vga_addr_i >= 9'd121 && vga_addr_i <= 9'd128) begin
                    preview_row <= 3'd3;
                    preview_col <= vga_addr_i - 9'd121;
                    preview_valid <= 1'b1;
                end else if (vga_addr_i >= 9'd141 && vga_addr_i <= 9'd148) begin
                    preview_row <= 3'd4;
                    preview_col <= vga_addr_i - 9'd141;
                    preview_valid <= 1'b1;
                end else if (vga_addr_i >= 9'd161 && vga_addr_i <= 9'd168) begin
                    preview_row <= 3'd5;
                    preview_col <= vga_addr_i - 9'd161;
                    preview_valid <= 1'b1;
                end else if (vga_addr_i >= 9'd181 && vga_addr_i <= 9'd188) begin
                    preview_row <= 3'd6;
                    preview_col <= vga_addr_i - 9'd181;
                    preview_valid <= 1'b1;
                end else if (vga_addr_i >= 9'd201 && vga_addr_i <= 9'd208) begin
                    preview_row <= 3'd7;
                    preview_col <= vga_addr_i - 9'd201;
                    preview_valid <= 1'b1;
                end
            end

            // El firmware limita los bordes. Si se intenta
            // mover mas alla, mostrar advertencia de borde.
            if (ui_phase_o==PHASE_PLACEMENT && !ui_j1_ready_o &&
                border_movement) begin
                ui_notice_o <= NOTICE_OUTSIDE;
                notice_counter <= NOTICE_CYCLES;
            end

            // =============================================
            // ACTUALIZAR CURSOR VGA
            // =============================================

            if (
                vga_we_i &&
                (
                    vga_wdata_i[2:0] == 3'd4 ||
                    vga_wdata_i[2:0] == 3'd5
                )
            ) begin
                j1_cursor_addr <= vga_addr_i;
                j1_cursor_valid <= 1'b1;
            end

            // =============================================
            // DETECTAR DISPARO REPETIDO J1
            // =============================================

            if (
                ui_phase_o == PHASE_BATTLE &&
                !ui_turn_o &&
                j1_status_i[5] &&
                !j1_fire_prev &&
                j1_cursor_valid
            ) begin

                if (j1_shots_seen[j1_cursor_addr[7:0]]) begin
                    ui_notice_o <= NOTICE_J1_REPEAT;
                    notice_counter <= NOTICE_CYCLES;
                end
                else begin
                    j1_shots_seen[j1_cursor_addr[7:0]] <= 1'b1;
                end
            end

            // =============================================
            // TEMPORIZADOR VISUAL
            // =============================================

            if (notice_counter != 0) begin
                notice_counter <= notice_counter - 1'b1;

                if (notice_counter == 1)
                    ui_notice_o <= NOTICE_NONE;
            end

            // =============================================
            // DETECTAR INTENTO DE COLOCACION J1
            // =============================================

            if (
                ui_phase_o == PHASE_PLACEMENT &&
                !ui_j1_ready_o &&
                j1_status_i[5] &&
                !j1_ok_prev &&
                !j1_attempt_active
            ) begin
                if (placement_outside) begin
                    j1_attempt_active <= 1'b0;
                    ui_notice_o <= NOTICE_OUTSIDE;
                    notice_counter <= NOTICE_CYCLES;
                end else if (placement_overlap) begin
                    j1_attempt_active <= 1'b0;
                    ui_notice_o <= NOTICE_OVERLAP;
                    notice_counter <= NOTICE_CYCLES;
                end else begin
                    j1_attempt_active <= 1'b1;
                    j1_check_counter <= J1_CHECK_CYCLES;
                end
            end

            // =============================================
            // COLOCACION ACEPTADA
            // =============================================

            if (
                j1_attempt_active &&
                j1_ship_write
            ) begin

                j1_attempt_active <= 1'b0;
                j1_check_counter <= '0;

                ui_notice_o <= NOTICE_ACCEPTED;
                notice_counter <= NOTICE_CYCLES;

                if (j1_accept_count < 2'd3)
                    j1_accept_count <= j1_accept_count + 1'b1;

                if (j1_accept_count == 2'd2) begin
                    ui_j1_ready_o <= 1'b1;
                    j1_ready_pulse_o <= 1'b1;
                end
            end

            // =============================================
            // CORRECCION DEL FALSO TRASLAPE
            //
            // No haber detectado una escritura en RAM
            // dentro de la ventana no demuestra traslape.
            //
            // Por tanto, se cierra la ventana sin generar
            // un mensaje de error falso.
            // =============================================

            else if (j1_attempt_active) begin

                if (j1_check_counter != 0) begin
                    j1_check_counter <= j1_check_counter - 1'b1;
                end

                else begin
                    j1_attempt_active <= 1'b0;
                    j1_check_counter <= '0;
                end
            end

            // =============================================
            // EVENTOS UART
            // =============================================

            if (tx_write_now && !tx_write_prev) begin

                // =========================================
                // ETAPA DE COLOCACION
                // =========================================

                if (ui_phase_o == PHASE_PLACEMENT) begin

                    case (tx_byte)

                        8'h01: begin
                            if (j2_accept_count < 2'd3)
                                j2_accept_count <= j2_accept_count + 1'b1;

                            if (j2_accept_count == 2'd2)
                                ui_j2_ready_o <= 1'b1;
                        end

                        8'h20: begin
                            ui_phase_o <= PHASE_BATTLE;
                            ui_turn_o <= 1'b0;
                            ui_notice_o <= NOTICE_BATTLE_START;
                            ui_winner_o <= WINNER_NONE;

                            ui_j1_ready_o <= 1'b1;
                            ui_j2_ready_o <= 1'b1;

                            notice_counter <= NOTICE_CYCLES;
                            j1_attempt_active <= 1'b0;
                            j1_check_counter <= '0;

                            j1_shots_seen <= '0;
                            j1_cursor_valid <= 1'b0;
                        end

                        default: begin
                        end

                    endcase
                end

                // =========================================
                // ETAPA DE BATALLA
                // =========================================

                else if (ui_phase_o == PHASE_BATTLE) begin

                    if (tx_byte == 8'h7C) begin

                        ui_phase_o <= PHASE_GAME_OVER;
                        ui_winner_o <= WINNER_J1;
                        ui_turn_o <= 1'b0;
                        ui_notice_o <= NOTICE_NONE;
                        notice_counter <= '0;
                    end

                    else if (tx_byte == 8'h7E) begin

                        ui_phase_o <= PHASE_GAME_OVER;
                        ui_winner_o <= WINNER_J2;
                        ui_turn_o <= 1'b1;
                        ui_notice_o <= NOTICE_NONE;
                        notice_counter <= '0;
                    end

                    // DISPARO J1
                    else if (tx_byte[0]) begin

                        if (tx_byte[7]) begin
                            if (target_sunk)
                                ui_notice_o <= NOTICE_J1_SUNK;
                            else
                                ui_notice_o <= NOTICE_J1_HIT;
                            j2_hits[shot_index] <= 1'b1;
                        end else
                            ui_notice_o <= NOTICE_J1_MISS;

                        notice_counter <= NOTICE_CYCLES;
                        ui_turn_o <= 1'b1;
                    end

                    // RESPUESTA A DISPARO J2
                    else begin

                        case (tx_byte)

                            8'h00: begin
                                ui_notice_o <= NOTICE_J2_MISS;
                                notice_counter <= NOTICE_CYCLES;
                                ui_turn_o <= 1'b0;
                            end

                            8'h02: begin
                                ui_notice_o <= NOTICE_J2_HIT;
                                notice_counter <= NOTICE_CYCLES;
                                ui_turn_o <= 1'b0;
                            end

                            8'h0A: begin
                                ui_notice_o <= NOTICE_J2_SUNK;
                                notice_counter <= NOTICE_CYCLES;
                                ui_turn_o <= 1'b0;
                            end

                            8'h04: begin
                                ui_notice_o <= NOTICE_J2_REPEAT;
                                notice_counter <= NOTICE_CYCLES;
                                ui_turn_o <= 1'b1;
                            end

                                                      default: begin
                            end

                        endcase
                    end
                end
            end
        end
    end

endmodule
