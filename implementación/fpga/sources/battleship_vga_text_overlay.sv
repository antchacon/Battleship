module battleship_vga_text_overlay (
    input  logic        video_active_i,
    input  logic [9:0]  x_i,
    input  logic [9:0]  y_i,

    input  logic [1:0]  ui_phase_i,
    input  logic        ui_turn_i,
    input  logic [3:0]  ui_notice_i,
    input  logic [1:0]  ui_winner_i,
    input  logic        ui_j2_ready_i,

    output logic        overlay_valid_o,
    output logic [3:0]  overlay_r_o,
    output logic [3:0]  overlay_g_o,
    output logic [3:0]  overlay_b_o
);


    // =====================================================
    // CONFIGURACION
    // =====================================================

    localparam integer MAX_CHARS = 64;


    // =====================================================
    // FASES
    // =====================================================

    localparam logic [1:0] PHASE_PLACEMENT = 2'd0;
    localparam logic [1:0] PHASE_BATTLE    = 2'd1;
    localparam logic [1:0] PHASE_GAME_OVER = 2'd2;


    // =====================================================
    // AVISOS
    // =====================================================

    localparam logic [3:0] NOTICE_NONE         = 4'd0;
    localparam logic [3:0] NOTICE_ACCEPTED     = 4'd1;
    localparam logic [3:0] NOTICE_OVERLAP      = 4'd2;
    localparam logic [3:0] NOTICE_OUTSIDE      = 4'd3;
    localparam logic [3:0] NOTICE_J1_HIT       = 4'd4;
    localparam logic [3:0] NOTICE_J1_MISS      = 4'd5;
    localparam logic [3:0] NOTICE_J2_HIT       = 4'd6;
    localparam logic [3:0] NOTICE_J2_MISS      = 4'd7;
    localparam logic [3:0] NOTICE_J2_REPEAT    = 4'd8;
    localparam logic [3:0] NOTICE_BATTLE_START = 4'd9;
    localparam logic [3:0] NOTICE_J1_SUNK = 4'd12;


    // =====================================================
    // GANADOR
    // =====================================================

    localparam logic [1:0] WINNER_NONE = 2'd0;
    localparam logic [1:0] WINNER_J1   = 2'd1;
    localparam logic [1:0] WINNER_J2   = 2'd2;


    // =====================================================
    // TEXTOS
    // =====================================================

    localparam logic [MAX_CHARS*8-1:0]
        TXT_TU_TABLERO =
            "TU TABLERO";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_TABLERO_RIVAL =
            "TABLERO RIVAL";


    localparam logic [MAX_CHARS*8-1:0]
        TXT_COLOCACION =
            "COLOCACION DE FLOTA";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_ACEPTADA =
            "POSICION ACEPTADA";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_RECHAZADA =
            "POSICION RECHAZADA";


    localparam logic [MAX_CHARS*8-1:0]
        TXT_TRASLAPE_1 =
            "UPS! TUS BARCOS SE HUNDIRAN";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_TRASLAPE_2 =
            "COLOCALOS DONDE NO CHOQUEN";


    localparam logic [MAX_CHARS*8-1:0]
        TXT_FUERA_1 =
            "TU BARCO SE ESTA ALEJANDO";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_FUERA_2 =
            "COLOCALO EN EL ESPACIO DE GUERRA";


    localparam logic [MAX_CHARS*8-1:0]
        TXT_J2_LISTA =
            "FLOTA JUGADOR 2 LISTA";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_ESPERA_J1 =
            "ESPERANDO AL JUGADOR 1";


    localparam logic [MAX_CHARS*8-1:0]
        TXT_AMBOS_LISTOS =
            "AMBOS JUGADORES LISTOS";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_INICIO =
            "INICIO DE BATALLA";


    localparam logic [MAX_CHARS*8-1:0]
        TXT_TURNO_J1 =
            "TURNO: JUGADOR 1";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_TURNO_J2 =
            "TURNO: JUGADOR 2";


    // =====================================================
    // NUEVO MENSAJE DE TURNO J1
    //
    // Se divide en tres lineas para que no quede
    // atravesando toda la pantalla.
    // =====================================================

    localparam logic [MAX_CHARS*8-1:0]
        TXT_ESTRATEGIA_1 =
            "CREA TU ESTRATEGIA";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_ESTRATEGIA_2 =
            "CALIBRA TUS TANQUES";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_ESTRATEGIA_3 =
            "Y DISPARA";


    // Mensaje permanente mientras el Jugador 2 prepara su disparo.
    localparam logic [MAX_CHARS*8-1:0]
        TXT_J2_ESTRATEGIA =
            "PREPARA TU ESTRATEGIA";
    localparam logic [MAX_CHARS*8-1:0]
        TXT_J2_CALIBRA =
            "CALIBRA TUS TANQUES";
    localparam logic [MAX_CHARS*8-1:0]
        TXT_J2_ATACA =
            "Y ATACA AL ENEMIGO";


    localparam logic [MAX_CHARS*8-1:0]
        TXT_J1_HIT =
            "IMPACTO AL ENEMIGO";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_J1_MISS =
            "DISPARO FALLIDO";


    localparam logic [MAX_CHARS*8-1:0]
        TXT_J2_HIT =
            "IMPACTO EN TU FLOTA";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_J2_MISS =
            "EL ENEMIGO FALLO";


    localparam logic [MAX_CHARS*8-1:0]
        TXT_REPETIDO =
            "DISPARO REPETIDO";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_OTRA =
            "ELIGE OTRA CASILLA";


    localparam logic [MAX_CHARS*8-1:0]
        TXT_FIN =
            "FIN DEL JUEGO";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_VICTORIA =
            "VICTORIA";

    localparam logic [MAX_CHARS*8-1:0]
        TXT_DERROTA =
            "DERROTA";


    // =====================================================
    // MENSAJES NUEVOS - 3 LINEAS MAXIMO POR AVISO
    // =====================================================
    localparam logic [MAX_CHARS*8-1:0] TXT_UPS_1 = "UPS! TU DISPARO FUE";
    localparam logic [MAX_CHARS*8-1:0] TXT_UPS_2 = "ALGO IMPRECISO";
    localparam logic [MAX_CHARS*8-1:0] TXT_UPS_3 = "PIENSA MEJOR TU ESTRATEGIA";
    localparam logic [MAX_CHARS*8-1:0] TXT_EXC_1 = "EXCELENTE PUNTERIA";
    localparam logic [MAX_CHARS*8-1:0] TXT_EXC_2 = "RECARGA TUS CANONES";
    localparam logic [MAX_CHARS*8-1:0] TXT_REP_1 = "SEGURO QUE QUIERES";
    localparam logic [MAX_CHARS*8-1:0] TXT_REP_2 = "REPETIR ESE TIRO?";
    localparam logic [MAX_CHARS*8-1:0] TXT_REP_3 = "NO PARECE UNA ESTRATEGIA";
    localparam logic [MAX_CHARS*8-1:0] TXT_REP_4 = "MUY CONVENIENTE";
    localparam logic [MAX_CHARS*8-1:0] TXT_SUNK_1 = "ENHORABUENA! HAS DISMINUIDO";
    localparam logic [MAX_CHARS*8-1:0] TXT_SUNK_2 = "LA FLOTA DEL ENEMIGO";
    localparam logic [3:0] NOTICE_J2_SUNK = 4'd10;
    localparam logic [MAX_CHARS*8-1:0] TXT_ATAQUE_1 = "RAYOS! EL CONTRINCANTE";
    localparam logic [MAX_CHARS*8-1:0] TXT_ATAQUE_2 = "DESCUBRIO TU ESTRATEGIA";
    localparam logic [MAX_CHARS*8-1:0] TXT_ATAQUE_3 = "NO DEJES QUE TOME VENTAJA";
    localparam logic [3:0] NOTICE_J1_REPEAT = 4'd11;

    // =====================================================
    // FUENTE 5x7
    // =====================================================

    function automatic logic [34:0]
    glyph5x7 (
        input logic [7:0] c
    );

        begin

            case (c)

                "A": glyph5x7 = {
                    5'b01110,
                    5'b10001,
                    5'b10001,
                    5'b11111,
                    5'b10001,
                    5'b10001,
                    5'b10001
                };

                "B": glyph5x7 = {
                    5'b11110,
                    5'b10001,
                    5'b10001,
                    5'b11110,
                    5'b10001,
                    5'b10001,
                    5'b11110
                };

                "C": glyph5x7 = {
                    5'b01111,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b01111
                };

                "D": glyph5x7 = {
                    5'b11110,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b11110
                };

                "E": glyph5x7 = {
                    5'b11111,
                    5'b10000,
                    5'b10000,
                    5'b11110,
                    5'b10000,
                    5'b10000,
                    5'b11111
                };

                "F": glyph5x7 = {
                    5'b11111,
                    5'b10000,
                    5'b10000,
                    5'b11110,
                    5'b10000,
                    5'b10000,
                    5'b10000
                };

                "G": glyph5x7 = {
                    5'b01111,
                    5'b10000,
                    5'b10000,
                    5'b10111,
                    5'b10001,
                    5'b10001,
                    5'b01111
                };

                "H": glyph5x7 = {
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b11111,
                    5'b10001,
                    5'b10001,
                    5'b10001
                };

                "I": glyph5x7 = {
                    5'b11111,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b11111
                };

                "J": glyph5x7 = {
                    5'b00111,
                    5'b00010,
                    5'b00010,
                    5'b00010,
                    5'b10010,
                    5'b10010,
                    5'b01100
                };

                "K": glyph5x7 = {
                    5'b10001,
                    5'b10010,
                    5'b10100,
                    5'b11000,
                    5'b10100,
                    5'b10010,
                    5'b10001
                };

                "L": glyph5x7 = {
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b11111
                };

                "M": glyph5x7 = {
                    5'b10001,
                    5'b11011,
                    5'b10101,
                    5'b10101,
                    5'b10001,
                    5'b10001,
                    5'b10001
                };

                "N": glyph5x7 = {
                    5'b10001,
                    5'b11001,
                    5'b10101,
                    5'b10011,
                    5'b10001,
                    5'b10001,
                    5'b10001
                };

                "O": glyph5x7 = {
                    5'b01110,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b01110
                };

                "P": glyph5x7 = {
                    5'b11110,
                    5'b10001,
                    5'b10001,
                    5'b11110,
                    5'b10000,
                    5'b10000,
                    5'b10000
                };

                "Q": glyph5x7 = {
                    5'b01110,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10101,
                    5'b10010,
                    5'b01101
                };

                "R": glyph5x7 = {
                    5'b11110,
                    5'b10001,
                    5'b10001,
                    5'b11110,
                    5'b10100,
                    5'b10010,
                    5'b10001
                };

                "S": glyph5x7 = {
                    5'b01111,
                    5'b10000,
                    5'b10000,
                    5'b01110,
                    5'b00001,
                    5'b00001,
                    5'b11110
                };

                "T": glyph5x7 = {
                    5'b11111,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100
                };

                "U": glyph5x7 = {
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b01110
                };

                "V": glyph5x7 = {
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b01010,
                    5'b00100
                };

                "W": glyph5x7 = {
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10101,
                    5'b10101,
                    5'b10101,
                    5'b01010
                };

                "X": glyph5x7 = {
                    5'b10001,
                    5'b10001,
                    5'b01010,
                    5'b00100,
                    5'b01010,
                    5'b10001,
                    5'b10001
                };

                "Y": glyph5x7 = {
                    5'b10001,
                    5'b10001,
                    5'b01010,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100
                };

                "Z": glyph5x7 = {
                    5'b11111,
                    5'b00001,
                    5'b00010,
                    5'b00100,
                    5'b01000,
                    5'b10000,
                    5'b11111
                };


                "0": glyph5x7 = {
                    5'b01110,
                    5'b10001,
                    5'b10011,
                    5'b10101,
                    5'b11001,
                    5'b10001,
                    5'b01110
                };

                "1": glyph5x7 = {
                    5'b00100,
                    5'b01100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b01110
                };

                "2": glyph5x7 = {
                    5'b01110,
                    5'b10001,
                    5'b00001,
                    5'b00010,
                    5'b00100,
                    5'b01000,
                    5'b11111
                };

                "3": glyph5x7 = {
                    5'b11110,
                    5'b00001,
                    5'b00001,
                    5'b01110,
                    5'b00001,
                    5'b00001,
                    5'b11110
                };

                "4": glyph5x7 = {
                    5'b00010,
                    5'b00110,
                    5'b01010,
                    5'b10010,
                    5'b11111,
                    5'b00010,
                    5'b00010
                };

                "5": glyph5x7 = {
                    5'b11111,
                    5'b10000,
                    5'b10000,
                    5'b11110,
                    5'b00001,
                    5'b00001,
                    5'b11110
                };

                "6": glyph5x7 = {
                    5'b01110,
                    5'b10000,
                    5'b10000,
                    5'b11110,
                    5'b10001,
                    5'b10001,
                    5'b01110
                };

                "7": glyph5x7 = {
                    5'b11111,
                    5'b00001,
                    5'b00010,
                    5'b00100,
                    5'b01000,
                    5'b01000,
                    5'b01000
                };

                "8": glyph5x7 = {
                    5'b01110,
                    5'b10001,
                    5'b10001,
                    5'b01110,
                    5'b10001,
                    5'b10001,
                    5'b01110
                };

                "9": glyph5x7 = {
                    5'b01110,
                    5'b10001,
                    5'b10001,
                    5'b01111,
                    5'b00001,
                    5'b00001,
                    5'b01110
                };


                ":": glyph5x7 = {
                    5'b00000,
                    5'b00100,
                    5'b00100,
                    5'b00000,
                    5'b00100,
                    5'b00100,
                    5'b00000
                };

                "!": glyph5x7 = {
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00000,
                    5'b00100
                };

                ",": glyph5x7 = {
                    5'b00000,
                    5'b00000,
                    5'b00000,
                    5'b00000,
                    5'b00100,
                    5'b00100,
                    5'b01000
                };

                "-": glyph5x7 = {
                    5'b00000,
                    5'b00000,
                    5'b00000,
                    5'b11111,
                    5'b00000,
                    5'b00000,
                    5'b00000
                };


                default: begin

                    glyph5x7 =
                        35'd0;

                end

            endcase

        end

    endfunction


    // =====================================================
    // RENDERIZADO DE TEXTO
    //
    // Fuente 5x7 escalada 2x2.
    //
    // Cada caracter ocupa:
    //
    // 12 pixeles de ancho
    // 14 pixeles de alto
    // =====================================================

    function automatic logic text_pixel (

        input logic [9:0] px,
        input logic [9:0] py,

        input integer x0,
        input integer y0,

        input integer len,

        input logic [MAX_CHARS*8-1:0] text
    );

        integer rel_x;
        integer rel_y;

        integer char_index;

        integer glyph_col;
        integer glyph_row;

        integer bit_index;

        logic [7:0] ch;
        logic [34:0] glyph;


        begin

            text_pixel =
                1'b0;


            if (
                (px >= x0)
                &&
                (px < x0 + len * 12)
                &&
                (py >= y0)
                &&
                (py < y0 + 14)
            ) begin

                rel_x =
                    px - x0;

                rel_y =
                    py - y0;


                char_index =
                    rel_x / 12;


                glyph_col =
                    (rel_x % 12) / 2;

                glyph_row =
                    rel_y / 2;


                if (
                    (char_index < len)
                    &&
                    (glyph_col < 5)
                    &&
                    (glyph_row < 7)
                ) begin

                    ch =
                        text[
                            (
                                (len - 1 - char_index)
                                * 8
                            )
                            +:
                            8
                        ];


                    glyph =
                        glyph5x7(
                            ch
                        );


                    bit_index =
                        (
                            (6 - glyph_row)
                            * 5
                        )
                        +
                        (
                            4 - glyph_col
                        );


                    text_pixel =
                        glyph[
                            bit_index
                        ];

                end

            end

        end

    endfunction


    // =====================================================
    // DIBUJADO
    // =====================================================

    always_comb begin

        overlay_valid_o =
            1'b0;

        overlay_r_o =
            4'h0;

        overlay_g_o =
            4'h0;

        overlay_b_o =
            4'h0;


        if (
            video_active_i
        ) begin


            // =================================================
            // TU TABLERO
            // =================================================

            if (
                text_pixel(
                    x_i,
                    y_i,
                    100,
                    76,
                    10,
                    TXT_TU_TABLERO
                )
            ) begin

                overlay_valid_o = 1'b1;

                overlay_r_o = 4'hF;
                overlay_g_o = 4'hF;
                overlay_b_o = 4'hF;

            end


            // =================================================
            // TABLERO RIVAL
            // =================================================

            if (
                text_pixel(
                    x_i,
                    y_i,
                    402,
                    76,
                    13,
                    TXT_TABLERO_RIVAL
                )
            ) begin

                overlay_valid_o = 1'b1;

                overlay_r_o = 4'hF;
                overlay_g_o = 4'hF;
                overlay_b_o = 4'hF;

            end


            // =================================================
            // COLOCACION
            // =================================================

            if (
                ui_phase_i ==
                PHASE_PLACEMENT
            ) begin

                case (
                    ui_notice_i
                )


                    // =========================================
                    // J1: POSICION ACEPTADA
                    // =========================================

                    NOTICE_ACCEPTED: begin

                        if (
                            text_pixel(
                                x_i,
                                y_i,
                                218,
                                396,
                                17,
                                TXT_ACEPTADA
                            )
                        ) begin

                            overlay_valid_o = 1'b1;

                            overlay_r_o = 4'h0;
                            overlay_g_o = 4'hF;
                            overlay_b_o = 4'h3;

                        end

                    end


                    // =========================================
                    // J1: TRASLAPE
                    // =========================================

                    NOTICE_OVERLAP: begin

                        if (
                            text_pixel(
                                x_i,
                                y_i,
                                212,
                                366,
                                18,
                                TXT_RECHAZADA
                            )
                        ) begin

                            overlay_valid_o = 1'b1;

                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;

                        end


                        if (
                            text_pixel(
                                x_i,
                                y_i,
                                158,
                                394,
                                27,
                                TXT_TRASLAPE_1
                            )
                        ) begin

                            overlay_valid_o = 1'b1;

                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;

                        end


                        if (
                            text_pixel(
                                x_i,
                                y_i,
                                164,
                                422,
                                26,
                                TXT_TRASLAPE_2
                            )
                        ) begin

                            overlay_valid_o = 1'b1;

                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;

                        end

                    end


                    // =========================================
                    // J1: FUERA DEL TABLERO
                    // =========================================

                    NOTICE_OUTSIDE: begin

                        if (
                            text_pixel(
                                x_i,
                                y_i,
                                212,
                                366,
                                18,
                                TXT_RECHAZADA
                            )
                        ) begin

                            overlay_valid_o = 1'b1;

                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;

                        end


                        if (
                            text_pixel(
                                x_i,
                                y_i,
                                170,
                                394,
                                25,
                                TXT_FUERA_1
                            )
                        ) begin

                            overlay_valid_o = 1'b1;

                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;

                        end


                        if (
                            text_pixel(
                                x_i,
                                y_i,
                                128,
                                422,
                                32,
                                TXT_FUERA_2
                            )
                        ) begin

                            overlay_valid_o = 1'b1;

                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;

                        end

                    end


                    // =========================================
                    // SIN MENSAJE TEMPORAL
                    // =========================================

                    default: begin

                        if (
                            ui_j2_ready_i
                        ) begin

                            if (
                                text_pixel(
                                    x_i,
                                    y_i,
                                    194,
                                    382,
                                    21,
                                    TXT_J2_LISTA
                                )
                            ) begin

                                overlay_valid_o = 1'b1;

                                overlay_r_o = 4'h0;
                                overlay_g_o = 4'hF;
                                overlay_b_o = 4'h3;

                            end


                            if (
                                text_pixel(
                                    x_i,
                                    y_i,
                                    188,
                                    410,
                                    22,
                                    TXT_ESPERA_J1
                                )
                            ) begin

                                overlay_valid_o = 1'b1;

                                overlay_r_o = 4'hF;
                                overlay_g_o = 4'hD;
                                overlay_b_o = 4'h0;

                            end

                        end


                        else begin

                            if (
                                text_pixel(
                                    x_i,
                                    y_i,
                                    206,
                                    396,
                                    19,
                                    TXT_COLOCACION
                                )
                            ) begin

                                overlay_valid_o = 1'b1;

                                overlay_r_o = 4'hF;
                                overlay_g_o = 4'hF;
                                overlay_b_o = 4'hF;

                            end

                        end

                    end

                endcase

            end


            // =================================================
            // BATALLA
            // =================================================

            else if (
                ui_phase_i ==
                PHASE_BATTLE
            ) begin

                case (
                    ui_notice_i
                )


                    // =========================================
                    // INICIO
                    // =========================================

                    NOTICE_BATTLE_START: begin

                        if (
                            text_pixel(
                                x_i,
                                y_i,
                                188,
                                382,
                                22,
                                TXT_AMBOS_LISTOS
                            )
                        ) begin

                            overlay_valid_o = 1'b1;

                            overlay_r_o = 4'h0;
                            overlay_g_o = 4'hF;
                            overlay_b_o = 4'h3;

                        end


                        if (
                            text_pixel(
                                x_i,
                                y_i,
                                218,
                                410,
                                17,
                                TXT_INICIO
                            )
                        ) begin

                            overlay_valid_o = 1'b1;

                            overlay_r_o = 4'h0;
                            overlay_g_o = 4'hF;
                            overlay_b_o = 4'h3;

                        end

                    end


                    // =========================================
                    // J1 IMPACTO
                    // =========================================

                    NOTICE_J1_HIT: begin
                        if (text_pixel(x_i, y_i, 212, 380, 18, TXT_EXC_1)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'h0;
                            overlay_g_o = 4'hF;
                            overlay_b_o = 4'h3;
                        end
                        if (text_pixel(x_i, y_i, 206, 404, 19, TXT_EXC_2)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'h0;
                            overlay_g_o = 4'hF;
                            overlay_b_o = 4'h3;
                        end
                    end

                    NOTICE_J1_MISS: begin
                        if (text_pixel(x_i, y_i, 206, 380, 19, TXT_UPS_1)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;
                        end
                        if (text_pixel(x_i, y_i, 236, 404, 14, TXT_UPS_2)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;
                        end
                        if (text_pixel(x_i, y_i, 164, 428, 26, TXT_UPS_3)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;
                        end
                    end

                    // El enemigo acerto contra nuestra flota.
                    NOTICE_J2_HIT: begin
                        if (text_pixel(x_i, y_i, 176, 380, 24, TXT_ATAQUE_1) ||
                            text_pixel(x_i, y_i, 170, 404, 25, TXT_ATAQUE_2) ||
                            text_pixel(x_i, y_i, 164, 428, 26, TXT_ATAQUE_3)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;
                        end
                    end

                    // Un fallo enemigo no genera texto.
                    NOTICE_J2_MISS: begin
                    end

                    NOTICE_J2_REPEAT, NOTICE_J1_REPEAT: begin
                        if (text_pixel(x_i, y_i, 212, 380, 18, TXT_REP_1)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;
                        end
                        if (text_pixel(x_i, y_i, 218, 404, 17, TXT_REP_2)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;
                        end
                        if (text_pixel(x_i, y_i, 176, 428, 24, TXT_REP_3)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;
                        end
                        if (text_pixel(x_i, y_i, 230, 452, 15, TXT_REP_4)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'hF;
                            overlay_g_o = 4'h2;
                            overlay_b_o = 4'h2;
                        end
                    end

                    NOTICE_J2_SUNK, NOTICE_J1_SUNK: begin
                        if (text_pixel(x_i, y_i, 158, 392, 27, TXT_SUNK_1)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'h0;
                            overlay_g_o = 4'hF;
                            overlay_b_o = 4'h3;
                        end
                        if (text_pixel(x_i, y_i, 200, 420, 20, TXT_SUNK_2)) begin
                            overlay_valid_o = 1'b1;
                            overlay_r_o = 4'h0;
                            overlay_g_o = 4'hF;
                            overlay_b_o = 4'h3;
                        end

                    end

                    // =========================================
                    // MENSAJES NORMALES DE TURNO
                    // =========================================

                    default: begin


                        // =====================================
                        // TURNO J1
                        // =====================================

                        if (
                            !ui_turn_i
                        ) begin

                            if (
                                text_pixel(
                                    x_i,
                                    y_i,
                                    224,
                                    370,
                                    16,
                                    TXT_TURNO_J1
                                )
                            ) begin

                                overlay_valid_o = 1'b1;

                                overlay_r_o = 4'h0;
                                overlay_g_o = 4'hF;
                                overlay_b_o = 4'h3;

                            end


                            // =================================
                            // CREA TU ESTRATEGIA
                            // =================================

                            if (
                                text_pixel(
                                    x_i,
                                    y_i,
                                    212,
                                    398,
                                    18,
                                    TXT_ESTRATEGIA_1
                                )
                            ) begin

                                overlay_valid_o = 1'b1;

                                overlay_r_o = 4'hF;
                                overlay_g_o = 4'hD;
                                overlay_b_o = 4'h0;

                            end


                            // =================================
                            // CALIBRA TUS TANQUES
                            // =================================

                            if (
                                text_pixel(
                                    x_i,
                                    y_i,
                                    206,
                                    420,
                                    19,
                                    TXT_ESTRATEGIA_2
                                )
                            ) begin

                                overlay_valid_o = 1'b1;

                                overlay_r_o = 4'hF;
                                overlay_g_o = 4'hD;
                                overlay_b_o = 4'h0;

                            end


                            // =================================
                            // Y DISPARA
                            // =================================

                            if (
                                text_pixel(
                                    x_i,
                                    y_i,
                                    266,
                                    442,
                                    9,
                                    TXT_ESTRATEGIA_3
                                )
                            ) begin

                                overlay_valid_o = 1'b1;

                                overlay_r_o = 4'hF;
                                overlay_g_o = 4'hD;
                                overlay_b_o = 4'h0;

                            end

                        end


                        // =====================================
                        // TURNO J2
                        // =====================================

                        else begin

                            if (
                                text_pixel(
                                    x_i,
                                    y_i,
                                    224,
                                    370,
                                    16,
                                    TXT_TURNO_J2
                                )
                            ) begin

                                overlay_valid_o = 1'b1;

                                overlay_r_o = 4'hF;
                                overlay_g_o = 4'h2;
                                overlay_b_o = 4'h2;

                            end


                            // Texto del turno PC, separado en 3 lineas.
                            if (
                                text_pixel(x_i, y_i, 194, 398, 21, TXT_J2_ESTRATEGIA) ||
                                text_pixel(x_i, y_i, 206, 420, 19, TXT_J2_CALIBRA) ||
                                text_pixel(x_i, y_i, 206, 442, 19, TXT_J2_ATACA)
                            ) begin
                                overlay_valid_o = 1'b1;
                                overlay_r_o = 4'hF;
                                overlay_g_o = 4'hD;
                                overlay_b_o = 4'h0;
                            end

                        end

                    end

                endcase

            end


            // =================================================
            // GAME OVER
            // =================================================

            else if (
                ui_phase_i ==
                PHASE_GAME_OVER
            ) begin

                if (
                    text_pixel(
                        x_i,
                        y_i,
                        242,
                        370,
                        13,
                        TXT_FIN
                    )
                ) begin

                    overlay_valid_o = 1'b1;

                    overlay_r_o = 4'hF;
                    overlay_g_o = 4'hF;
                    overlay_b_o = 4'hF;

                end


                // =============================================
                // J1 GANA
                // =============================================

                if (
                    ui_winner_i ==
                    WINNER_J1
                ) begin

                    if (
                        text_pixel(
                            x_i,
                            y_i,
                            272,
                            410,
                            8,
                            TXT_VICTORIA
                        )
                    ) begin

                        overlay_valid_o = 1'b1;

                        overlay_r_o = 4'h0;
                        overlay_g_o = 4'hF;
                        overlay_b_o = 4'h3;

                    end

                end


                // =============================================
                // J2 GANA
                // =============================================

                else if (
                    ui_winner_i ==
                    WINNER_J2
                ) begin

                    if (
                        text_pixel(
                            x_i,
                            y_i,
                            278,
                            410,
                            7,
                            TXT_DERROTA
                        )
                    ) begin

                        overlay_valid_o = 1'b1;

                        overlay_r_o = 4'hF;
                        overlay_g_o = 4'h2;
                        overlay_b_o = 4'h2;

                    end

                end

            end

        end

    end


endmodule