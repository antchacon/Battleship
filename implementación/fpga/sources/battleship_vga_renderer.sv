module battleship_vga_renderer (
    input  logic       video_active_i,

    input  logic [9:0] x_i,
    input  logic [9:0] y_i,

    input  logic [2:0] tile_state_i,

    input  logic       blink_i,
    input  logic       cursor_here_i,

    output logic [3:0] vga_r_o,
    output logic [3:0] vga_g_o,
    output logic [3:0] vga_b_o
);

    logic [4:0] tile_col;
    logic [3:0] tile_row;

    logic [4:0] local_x;
    logic [4:0] local_y;

    logic in_board_1;
    logic in_board_2;
    logic in_board;

    logic grid_pixel;
    logic cursor_pixel;

    logic miss_x_pixel;
    logic hit_circle_pixel;

    logic signed [5:0] dx;
    logic signed [5:0] dy;

    logic signed [5:0] diag1;
    logic signed [6:0] diag2;

    logic [11:0] dist2;


    always_comb begin

        tile_col = x_i[9:5];
        tile_row = y_i[8:5];

        local_x = x_i[4:0];
        local_y = y_i[4:0];


        // =================================================
        // TABLERO J1
        // columnas 1..8
        // filas    3..10
        // =================================================

        in_board_1 =
            (tile_col >= 5'd1) &&
            (tile_col <= 5'd8) &&
            (tile_row >= 4'd3) &&
            (tile_row <= 4'd10);


        // =================================================
        // TABLERO J2
        // columnas 11..18
        // filas     3..10
        // =================================================

        in_board_2 =
            (tile_col >= 5'd11) &&
            (tile_col <= 5'd18) &&
            (tile_row >= 4'd3)  &&
            (tile_row <= 4'd10);


        in_board =
            in_board_1 ||
            in_board_2;


        // =================================================
        // CUADRICULA
        // =================================================

        grid_pixel =
            (local_x <= 5'd1)  ||
            (local_x >= 5'd30) ||
            (local_y <= 5'd1)  ||
            (local_y >= 5'd30);


        // =================================================
        // BORDE DEL CURSOR
        // =================================================

        cursor_pixel =
            (local_x >= 5'd3)  &&
            (local_x <= 5'd28) &&
            (local_y >= 5'd3)  &&
            (local_y <= 5'd28) &&
            (
                (local_x <= 5'd5)  ||
                (local_x >= 5'd26) ||
                (local_y <= 5'd5)  ||
                (local_y >= 5'd26)
            );


        // =================================================
        // X ROJA PARA FALLO
        // =================================================

        diag1 =
            $signed({1'b0, local_x}) -
            $signed({1'b0, local_y});

        diag2 =
            $signed({1'b0, local_x}) +
            $signed({1'b0, local_y}) -
            7'sd31;


        miss_x_pixel =
            (local_x >= 5'd6)  &&
            (local_x <= 5'd25) &&
            (local_y >= 5'd6)  &&
            (local_y <= 5'd25) &&
            (
                (
                    (diag1 >= -6'sd1) &&
                    (diag1 <=  6'sd1)
                )
                ||
                (
                    (diag2 >= -7'sd1) &&
                    (diag2 <=  7'sd1)
                )
            );


        // =================================================
        // CIRCULO VERDE PARA ACIERTO
        // =================================================

        dx =
            $signed({1'b0, local_x}) -
            6'sd16;

        dy =
            $signed({1'b0, local_y}) -
            6'sd16;


        dist2 =
            (dx * dx) +
            (dy * dy);


        hit_circle_pixel =
            (dist2 >= 12'd64) &&
            (dist2 <= 12'd100);


        // =================================================
        // FONDO GENERAL
        // =================================================

        vga_r_o = 4'h0;
        vga_g_o = 4'h0;
        vga_b_o = 4'h0;


        // =================================================
        // TABLEROS
        // =================================================

        if (video_active_i && in_board) begin

            if (grid_pixel) begin

                // Cuadricula gris oscura

                vga_r_o = 4'h4;
                vga_g_o = 4'h4;
                vga_b_o = 4'h4;

            end


            // =================================================
            // CURSOR
            //
            // El cursor se dibuja utilizando la direccion
            // capturada por el core.
            // =================================================

            else if (
                cursor_here_i &&
                blink_i &&
                cursor_pixel
            ) begin

                vga_r_o = 4'hF;
                vga_g_o = 4'hF;
                vga_b_o = 4'h0;

            end


            else begin

                case (tile_state_i)


                    // =====================================
                    // 0 = AGUA
                    // =====================================

                    3'd0: begin

                        vga_r_o = 4'h0;
                        vga_g_o = 4'h0;
                        vga_b_o = 4'hF;

                    end


                    // =====================================
                    // 1 = BARCO
                    // =====================================

                    3'd1: begin

                        vga_r_o = 4'h9;
                        vga_g_o = 4'h9;
                        vga_b_o = 4'h9;

                    end


                    // =====================================
                    // 2 = FALLO
                    // =====================================

                    3'd2: begin

                        if (miss_x_pixel) begin

                            vga_r_o = 4'hF;
                            vga_g_o = 4'h0;
                            vga_b_o = 4'h0;

                        end

                        else begin

                            vga_r_o = 4'h0;
                            vga_g_o = 4'h0;
                            vga_b_o = 4'hF;

                        end

                    end


                    // =====================================
                    // 3 = ACIERTO
                    // =====================================

                    3'd3: begin

                        if (hit_circle_pixel) begin

                            vga_r_o = 4'h0;
                            vga_g_o = 4'hF;
                            vga_b_o = 4'h0;

                        end

                        else begin

                            vga_r_o = 4'h0;
                            vga_g_o = 4'h0;
                            vga_b_o = 4'hF;

                        end

                    end


                    // =====================================
                    // 4 = CURSOR SOBRE AGUA
                    //
                    // El cursor amarillo se dibuja
                    // mediante cursor_here_i.
                    // =====================================

                    3'd4: begin

                        vga_r_o = 4'h0;
                        vga_g_o = 4'h0;
                        vga_b_o = 4'hF;

                    end


                    // =====================================
                    // 5 = BARCO + CURSOR
                    //
                    // El cursor amarillo se dibuja
                    // mediante cursor_here_i.
                    // =====================================

                    3'd5: begin

                        vga_r_o = 4'h9;
                        vga_g_o = 4'h9;
                        vga_b_o = 4'h9;

                    end


                    // =====================================
                    // DEFAULT
                    // =====================================

                    default: begin

                        vga_r_o = 4'h0;
                        vga_g_o = 4'h0;
                        vga_b_o = 4'hF;

                    end

                endcase

            end

        end

    end

endmodule