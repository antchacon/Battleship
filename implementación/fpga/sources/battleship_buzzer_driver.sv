module battleship_buzzer_driver #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter logic ACTIVE_LOW = 1'b0
)(
    input  logic        clk_i,
    input  logic        rst_i,

    input  logic [31:0] buzzer_data_i,

    output logic        buzzer_o
);


    // =====================================================
    // CODIGO DE ENTRADA
    // =====================================================

    logic [2:0] input_code;
    logic [2:0] previous_input_code;


    assign input_code =
        buzzer_data_i[2:0];


    // =====================================================
    // SONIDO ACTUAL
    // =====================================================

    logic [2:0] active_code;

    logic [2:0] pending_code;
    logic       pending_valid;


    // =====================================================
    // CONTROL DEL PATRON
    // =====================================================

    logic [4:0] step;

    logic playing;
    logic step_on;

    integer step_duration_ms;
    integer last_step;

    integer step_counter_ms;


    // =====================================================
    // TICK 1 ms
    // =====================================================

    localparam integer TICKS_1MS =
        CLK_FREQ / 1000;


    integer ms_counter;

    logic tick_1ms;


    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            ms_counter <= 0;

            tick_1ms <=
                1'b0;

        end

        else begin

            if (
                ms_counter >=
                TICKS_1MS - 1
            ) begin

                ms_counter <= 0;

                tick_1ms <=
                    1'b1;

            end

            else begin

                ms_counter <=
                    ms_counter + 1;

                tick_1ms <=
                    1'b0;

            end

        end

    end


    // =====================================================
    // PATRONES
    // =====================================================

    always_comb begin

        step_on          = 1'b0;
        step_duration_ms = 80;
        last_step        = 0;


        case (active_code)


            // =================================================
            // 001 - INICIO
            //
            // bip - bip - BIIIP
            // =================================================

            3'b001: begin

                last_step = 4;

                case (step)

                    0: begin
                        step_on = 1'b1;
                        step_duration_ms = 90;
                    end

                    1: begin
                        step_on = 1'b0;
                        step_duration_ms = 100;
                    end

                    2: begin
                        step_on = 1'b1;
                        step_duration_ms = 90;
                    end

                    3: begin
                        step_on = 1'b0;
                        step_duration_ms = 100;
                    end

                    4: begin
                        step_on = 1'b1;
                        step_duration_ms = 220;
                    end

                    default: begin
                        step_on = 1'b0;
                    end

                endcase

            end


            // =================================================
            // 010 - IMPACTO
            //
            // bip-bip-BIP
            // =================================================

            3'b010: begin

                last_step = 4;

                case (step)

                    0: begin
                        step_on = 1'b1;
                        step_duration_ms = 60;
                    end

                    1: begin
                        step_on = 1'b0;
                        step_duration_ms = 50;
                    end

                    2: begin
                        step_on = 1'b1;
                        step_duration_ms = 60;
                    end

                    3: begin
                        step_on = 1'b0;
                        step_duration_ms = 50;
                    end

                    4: begin
                        step_on = 1'b1;
                        step_duration_ms = 160;
                    end

                    default: begin
                        step_on = 1'b0;
                    end

                endcase

            end


            // =================================================
            // 011 - FALLO
            //
            // BEEEEEP --- bip
            // =================================================

            3'b011: begin

                last_step = 2;

                case (step)

                    0: begin
                        step_on = 1'b1;
                        step_duration_ms = 280;
                    end

                    1: begin
                        step_on = 1'b0;
                        step_duration_ms = 140;
                    end

                    2: begin
                        step_on = 1'b1;
                        step_duration_ms = 90;
                    end

                    default: begin
                        step_on = 1'b0;
                    end

                endcase

            end


            // =================================================
            // 100 - HUNDIDO / DERROTA FPGA
            //
            // BOOM - BOOM - BAAAAAM
            // =================================================

            3'b100: begin

                last_step = 4;

                case (step)

                    0: begin
                        step_on = 1'b1;
                        step_duration_ms = 160;
                    end

                    1: begin
                        step_on = 1'b0;
                        step_duration_ms = 90;
                    end

                    2: begin
                        step_on = 1'b1;
                        step_duration_ms = 160;
                    end

                    3: begin
                        step_on = 1'b0;
                        step_duration_ms = 90;
                    end

                    4: begin
                        step_on = 1'b1;
                        step_duration_ms = 280;
                    end

                    default: begin
                        step_on = 1'b0;
                    end

                endcase

            end


            // =================================================
            // 101 - INVALIDO / REPETIDO
            //
            // bip-bip-bip
            // =================================================

            3'b101: begin

                last_step = 4;

                case (step)

                    0: begin
                        step_on = 1'b1;
                        step_duration_ms = 60;
                    end

                    1: begin
                        step_on = 1'b0;
                        step_duration_ms = 60;
                    end

                    2: begin
                        step_on = 1'b1;
                        step_duration_ms = 60;
                    end

                    3: begin
                        step_on = 1'b0;
                        step_duration_ms = 60;
                    end

                    4: begin
                        step_on = 1'b1;
                        step_duration_ms = 60;
                    end

                    default: begin
                        step_on = 1'b0;
                    end

                endcase

            end


            // =================================================
            // 110 - VICTORIA
            //
            // BIIIIIP
            //    pausa
            // bip-bip
            //    pausa
            // BIIIIIIIIIP
            //
            // Muy diferente de impacto/fallo.
            // =================================================

            3'b110: begin

                last_step = 6;

                case (step)

                    // Largo inicial
                    0: begin
                        step_on = 1'b1;
                        step_duration_ms = 350;
                    end

                    // Pausa grande
                    1: begin
                        step_on = 1'b0;
                        step_duration_ms = 180;
                    end

                    // Corto
                    2: begin
                        step_on = 1'b1;
                        step_duration_ms = 70;
                    end

                    // Pausa corta
                    3: begin
                        step_on = 1'b0;
                        step_duration_ms = 70;
                    end

                    // Corto
                    4: begin
                        step_on = 1'b1;
                        step_duration_ms = 70;
                    end

                    // Pausa
                    5: begin
                        step_on = 1'b0;
                        step_duration_ms = 180;
                    end

                    // Final largo
                    6: begin
                        step_on = 1'b1;
                        step_duration_ms = 550;
                    end

                    default: begin
                        step_on = 1'b0;
                    end

                endcase

            end


            // =================================================
            // 111 - COLOCACION ACEPTADA
            //
            // bip --- BIP
            //
            // Corto y limpio.
            // =================================================

            3'b111: begin

                last_step = 2;

                case (step)

                    0: begin
                        step_on = 1'b1;
                        step_duration_ms = 90;
                    end

                    1: begin
                        step_on = 1'b0;
                        step_duration_ms = 80;
                    end

                    2: begin
                        step_on = 1'b1;
                        step_duration_ms = 150;
                    end

                    default: begin
                        step_on = 1'b0;
                    end

                endcase

            end


            // =================================================
            // SILENCIO
            // =================================================

            default: begin

                step_on = 1'b0;

                step_duration_ms = 80;

                last_step = 0;

            end

        endcase

    end


    // =====================================================
    // DETECTAR NUEVO COMANDO
    // =====================================================

    logic new_command;


    assign new_command =

        (input_code != 3'b000)

        &&

        (
            input_code !=
            previous_input_code
        );


    // =====================================================
    // REPRODUCTOR
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            previous_input_code <=
                3'b000;

            active_code <=
                3'b000;

            pending_code <=
                3'b000;

            pending_valid <=
                1'b0;

            step <=
                5'd0;

            step_counter_ms <=
                0;

            playing <=
                1'b0;

        end

        else begin

            previous_input_code <=
                input_code;


            // =================================================
            // NUEVO SONIDO
            // =================================================

            if (new_command) begin


                // ---------------------------------------------
                // Si está libre, reproducir inmediatamente
                // ---------------------------------------------

                if (!playing) begin

                    active_code <=
                        input_code;

                    step <=
                        5'd0;

                    step_counter_ms <=
                        0;

                    playing <=
                        1'b1;

                end


                // ---------------------------------------------
                // Si está ocupado, guardar el siguiente
                // ---------------------------------------------

                else begin

                    pending_code <=
                        input_code;

                    pending_valid <=
                        1'b1;

                end

            end


            // =================================================
            // AVANZAR PATRON
            // =================================================

            else if (
                playing &&
                tick_1ms
            ) begin

                if (
                    step_counter_ms >=
                    step_duration_ms - 1
                ) begin

                    step_counter_ms <=
                        0;


                    // =========================================
                    // TERMINO EL SONIDO
                    // =========================================

                    if (
                        step >=
                        last_step
                    ) begin


                        // -------------------------------------
                        // Hay otro sonido esperando
                        // -------------------------------------

                        if (pending_valid) begin

                            active_code <=
                                pending_code;

                            pending_valid <=
                                1'b0;

                            step <=
                                5'd0;

                            step_counter_ms <=
                                0;

                            playing <=
                                1'b1;

                        end


                        // -------------------------------------
                        // Nada pendiente
                        // -------------------------------------

                        else begin

                            active_code <=
                                3'b000;

                            playing <=
                                1'b0;

                            step <=
                                5'd0;

                        end

                    end


                    // =========================================
                    // SIGUIENTE PASO
                    // =========================================

                    else begin

                        step <=
                            step + 1'b1;

                    end

                end

                else begin

                    step_counter_ms <=
                        step_counter_ms + 1;

                end

            end

        end

    end


    // =====================================================
    // SALIDA FISICA
    // =====================================================

    always_comb begin

        if (ACTIVE_LOW) begin

            if (
                playing &&
                step_on
            ) begin

                buzzer_o =
                    1'b0;

            end

            else begin

                buzzer_o =
                    1'b1;

            end

        end

        else begin

            if (
                playing &&
                step_on
            ) begin

                buzzer_o =
                    1'b1;

            end

            else begin

                buzzer_o =
                    1'b0;

            end

        end

    end


endmodule