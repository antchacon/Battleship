module battleship_victory_counter (
    input  logic        clk_i,
    input  logic        rst_i,

    // =====================================================
    // GANADOR
    //
    // 00 = ninguno
    // 01 = J1
    // 10 = J2
    // =====================================================

    input  logic [1:0]  winner_i,


    // =====================================================
    // SALIDA PARA EL DRIVER DE 7 SEGMENTOS
    //
    // [7:0]  = victorias J1
    // [15:8] = victorias J2
    // =====================================================

    output logic [31:0] display_data_o
);


    localparam logic [1:0] WINNER_NONE =
        2'd0;

    localparam logic [1:0] WINNER_J1 =
        2'd1;

    localparam logic [1:0] WINNER_J2 =
        2'd2;


    logic [7:0] j1_wins;
    logic [7:0] j2_wins;

    logic [1:0] previous_winner;


    // =====================================================
    // CONTADOR
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            j1_wins <=
                8'd0;

            j2_wins <=
                8'd0;

            previous_winner <=
                WINNER_NONE;

        end

        else begin

            previous_winner <=
                winner_i;


            // =================================================
            // SOLO CONTAR UNA VEZ CUANDO APARECE EL GANADOR
            // =================================================

            if (
                (previous_winner == WINNER_NONE) &&
                (winner_i != WINNER_NONE)
            ) begin


                // =============================================
                // VICTORIA J1
                // =============================================

                if (
                    winner_i == WINNER_J1
                ) begin

                    if (
                        j1_wins < 8'd99
                    ) begin

                        j1_wins <=
                            j1_wins + 1'b1;

                    end

                end


                // =============================================
                // VICTORIA J2
                // =============================================

                else if (
                    winner_i == WINNER_J2
                ) begin

                    if (
                        j2_wins < 8'd99
                    ) begin

                        j2_wins <=
                            j2_wins + 1'b1;

                    end

                end

            end

        end

    end


    // =====================================================
    // FORMATO PARA EL DISPLAY
    //
    // bits 7:0   -> J1 -> dos displays izquierda
    // bits 15:8  -> J2 -> dos displays derecha
    // =====================================================

    always_comb begin

        display_data_o =
            32'd0;

        display_data_o[7:0] =
            j1_wins;

        display_data_o[15:8] =
            j2_wins;

    end


endmodule