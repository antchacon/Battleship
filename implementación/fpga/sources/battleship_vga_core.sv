module battleship_vga_core (
    input  logic        clk_i,
    input  logic        clk_pixel_i,
    input  logic        rst_i,

    // =====================================================
    // PUERTO CPU
    // =====================================================

    input  logic [8:0]  cpu_addr_i,
    input  logic [31:0] cpu_wdata_i,
    input  logic        cpu_we_i,
    output logic [31:0] cpu_rdata_o,


    // =====================================================
    // ESTADO DE INTERFAZ
    // =====================================================

    input  logic [1:0]  ui_phase_i,
    input  logic        ui_turn_i,
    input  logic [3:0]  ui_notice_i,
    input  logic [1:0]  ui_winner_i,
    input  logic        ui_j2_ready_i,


    // =====================================================
    // VGA
    // =====================================================

    output logic        hsync_o,
    output logic        vsync_o,

    output logic [3:0]  vga_r_o,
    output logic [3:0]  vga_g_o,
    output logic [3:0]  vga_b_o
);


    // =====================================================
    // TIMING VGA
    // =====================================================

    logic [9:0] timing_x;
    logic [9:0] timing_y;

    logic timing_active;

    logic hsync_raw;
    logic vsync_raw;


    // =====================================================
    // MEMORIA VGA
    // =====================================================

    logic [8:0]  video_addr;
    logic [31:0] video_rdata;


    // =====================================================
    // SALIDAS DEL TILE MAPPER
    // =====================================================

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;

    logic video_active;

    logic [2:0] tile_state;


    // =====================================================
    // CURSOR
    // =====================================================

    logic [8:0] cursor_addr_cpu;
    logic       cursor_valid_cpu;

    logic [8:0] cursor_addr_meta;
    logic [8:0] cursor_addr_pixel;

    logic cursor_valid_meta;
    logic cursor_valid_pixel;

    logic [8:0] video_addr_d;

    logic cursor_here;


    // =====================================================
    // DATO QUE REALMENTE SE GUARDA EN RAM VGA
    // =====================================================

    logic [31:0] ram_cpu_wdata;


    // =====================================================
    // SINCRONIZACION DE LA INTERFAZ
    // 100 MHz -> 25 MHz
    // =====================================================

    logic [1:0] ui_phase_meta;
    logic [1:0] ui_phase_pixel;

    logic ui_turn_meta;
    logic ui_turn_pixel;

    logic [3:0] ui_notice_meta;
    logic [3:0] ui_notice_pixel;

    logic [1:0] ui_winner_meta;
    logic [1:0] ui_winner_pixel;

    logic ui_j2_ready_meta;
    logic ui_j2_ready_pixel;


    // =====================================================
    // CAPTURA DE LA POSICION DEL CURSOR
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            cursor_addr_cpu  <= 9'd0;
            cursor_valid_cpu <= 1'b0;

        end

        else begin

            // =============================================
            // Cuando el firmware limpia la pantalla desde
            // la dirección 0 se elimina el cursor anterior.
            // =============================================

            if (
                cpu_we_i &&
                (cpu_addr_i == 9'd0) &&
                (cpu_wdata_i[2:0] == 3'd0)
            ) begin

                cursor_valid_cpu <= 1'b0;

            end


            // =============================================
            // 4 = cursor sobre agua
            // 5 = cursor sobre barco
            // =============================================

            if (
                cpu_we_i &&
                (
                    (cpu_wdata_i[2:0] == 3'd4) ||
                    (cpu_wdata_i[2:0] == 3'd5)
                )
            ) begin

                cursor_addr_cpu  <= cpu_addr_i;
                cursor_valid_cpu <= 1'b1;

            end

        end

    end


    // =====================================================
    // NO GUARDAR EL CURSOR COMO ESTADO PERMANENTE
    //
    // Si el CPU escribe:
    //
    // 4 -> RAM guarda agua
    // 5 -> RAM guarda barco
    //
    // El cursor se maneja aparte.
    // =====================================================

    always_comb begin

        ram_cpu_wdata = cpu_wdata_i;


        case (cpu_wdata_i[2:0])

            3'd4: begin

                ram_cpu_wdata[2:0] = 3'd0;

            end


            3'd5: begin

                ram_cpu_wdata[2:0] = 3'd1;

            end


            default: begin

                ram_cpu_wdata[2:0] =
                    cpu_wdata_i[2:0];

            end

        endcase

    end


    // =====================================================
    // SINCRONIZACION AL RELOJ DE PIXEL
    // =====================================================

    always_ff @(posedge clk_pixel_i) begin

        if (rst_i) begin

            cursor_addr_meta   <= 9'd0;
            cursor_addr_pixel  <= 9'd0;

            cursor_valid_meta  <= 1'b0;
            cursor_valid_pixel <= 1'b0;

            video_addr_d <= 9'd0;


            ui_phase_meta  <= 2'd0;
            ui_phase_pixel <= 2'd0;


            ui_turn_meta  <= 1'b0;
            ui_turn_pixel <= 1'b0;


            ui_notice_meta  <= 4'd0;
            ui_notice_pixel <= 4'd0;


            ui_winner_meta  <= 2'd0;
            ui_winner_pixel <= 2'd0;


            ui_j2_ready_meta  <= 1'b0;
            ui_j2_ready_pixel <= 1'b0;

        end

        else begin

            // =============================================
            // CURSOR
            // =============================================

            cursor_addr_meta <=
                cursor_addr_cpu;

            cursor_addr_pixel <=
                cursor_addr_meta;


            cursor_valid_meta <=
                cursor_valid_cpu;

            cursor_valid_pixel <=
                cursor_valid_meta;


            video_addr_d <=
                video_addr;


            // =============================================
            // ESTADO UI
            // =============================================

            ui_phase_meta <=
                ui_phase_i;

            ui_phase_pixel <=
                ui_phase_meta;


            ui_turn_meta <=
                ui_turn_i;

            ui_turn_pixel <=
                ui_turn_meta;


            ui_notice_meta <=
                ui_notice_i;

            ui_notice_pixel <=
                ui_notice_meta;


            ui_winner_meta <=
                ui_winner_i;

            ui_winner_pixel <=
                ui_winner_meta;


            ui_j2_ready_meta <=
                ui_j2_ready_i;

            ui_j2_ready_pixel <=
                ui_j2_ready_meta;

        end

    end


    // =====================================================
    // DETECTAR SI EL PIXEL ACTUAL PERTENECE AL CURSOR
    // =====================================================

    assign cursor_here =
        cursor_valid_pixel &&
        (video_addr_d == cursor_addr_pixel);


    // =====================================================
    // PARPADEO DEL CURSOR
    // =====================================================

    logic [23:0] blink_counter;
    logic        blink;


    always_ff @(posedge clk_pixel_i) begin

        if (rst_i) begin

            blink_counter <= 24'd0;

        end

        else begin

            blink_counter <=
                blink_counter + 1'b1;

        end

    end


    assign blink =
        blink_counter[23];


    // =====================================================
    // RAM VGA
    // =====================================================

    battleship_vga_ram vga_ram (

        .clk_i          (clk_i),

        .cpu_addr_i     (cpu_addr_i),
        .cpu_wdata_i    (ram_cpu_wdata),
        .cpu_we_i       (cpu_we_i),
        .cpu_rdata_o    (cpu_rdata_o),

        .clk_pixel_i    (clk_pixel_i),

        .video_addr_i   (video_addr),
        .video_rdata_o  (video_rdata)

    );


    // =====================================================
    // TEMPORIZACION VGA
    // =====================================================

    battleship_vga_timing timing (

        .clk_pixel_i    (clk_pixel_i),
        .rst_i          (rst_i),

        .hsync_o        (hsync_raw),
        .vsync_o        (vsync_raw),

        .video_active_o (timing_active),

        .x_o            (timing_x),
        .y_o            (timing_y)

    );


    // =====================================================
    // PIXEL -> TILE
    // =====================================================

    battleship_vga_tile_mapper mapper (

        .clk_pixel_i    (clk_pixel_i),
        .rst_i          (rst_i),

        .x_i            (timing_x),
        .y_i            (timing_y),

        .video_active_i (timing_active),

        .tile_data_i    (video_rdata),

        .video_addr_o   (video_addr),

        .x_o            (pixel_x),
        .y_o            (pixel_y),

        .video_active_o (video_active),

        .tile_state_o   (tile_state)

    );


    // =====================================================
    // RENDERER ORIGINAL
    //
    // Este sigue dibujando:
    //
    // agua
    // barcos
    // X
    // O
    // cursor
    // =====================================================

    logic [3:0] base_r;
    logic [3:0] base_g;
    logic [3:0] base_b;


    battleship_vga_renderer renderer (

        .video_active_i (video_active),

        .x_i            (pixel_x),
        .y_i            (pixel_y),

        .tile_state_i   (tile_state),

        .blink_i        (blink),
        .cursor_here_i  (cursor_here),

        .vga_r_o        (base_r),
        .vga_g_o        (base_g),
        .vga_b_o        (base_b)

    );


    // =====================================================
    // CAPA DE TEXTO
    // =====================================================

    logic overlay_valid;

    logic [3:0] overlay_r;
    logic [3:0] overlay_g;
    logic [3:0] overlay_b;


    battleship_vga_text_overlay text_overlay (

        .video_active_i (
            video_active
        ),

        .x_i (
            pixel_x
        ),

        .y_i (
            pixel_y
        ),


        .ui_phase_i (
            ui_phase_pixel
        ),

        .ui_turn_i (
            ui_turn_pixel
        ),

        .ui_notice_i (
            ui_notice_pixel
        ),

        .ui_winner_i (
            ui_winner_pixel
        ),

        .ui_j2_ready_i (
            ui_j2_ready_pixel
        ),


        .overlay_valid_o (
            overlay_valid
        ),

        .overlay_r_o (
            overlay_r
        ),

        .overlay_g_o (
            overlay_g
        ),

        .overlay_b_o (
            overlay_b
        )

    );


    // =====================================================
    // MEZCLA FINAL
    //
    // Si existe un pixel de texto:
    //      mostrar texto
    //
    // De lo contrario:
    //      mostrar tablero normal
    //
    // Se usan assign para evitar el problema de sintaxis
    // que aparecía en el bloque always_comb anterior.
    // =====================================================

    assign vga_r_o =
        overlay_valid
        ? overlay_r
        : base_r;


    assign vga_g_o =
        overlay_valid
        ? overlay_g
        : base_g;


    assign vga_b_o =
        overlay_valid
        ? overlay_b
        : base_b;


    // =====================================================
    // HSYNC / VSYNC
    // =====================================================

    always_ff @(posedge clk_pixel_i) begin

        if (rst_i) begin

            hsync_o <= 1'b1;
            vsync_o <= 1'b1;

        end

        else begin

            hsync_o <= hsync_raw;
            vsync_o <= vsync_raw;

        end

    end


endmodule