module battleship_vga_tile_mapper (
    input  logic       clk_pixel_i,
    input  logic       rst_i,

    input  logic [9:0] x_i,
    input  logic [9:0] y_i,
    input  logic       video_active_i,

    input  logic [31:0] tile_data_i,

    output logic [8:0] video_addr_o,

    output logic [9:0] x_o,
    output logic [9:0] y_o,
    output logic       video_active_o,

    output logic [2:0] tile_state_o
);

    logic [4:0] tile_col;
    logic [3:0] tile_row;


    // =====================================================
    // CONVERSION PIXEL -> TILE
    // =====================================================

    always_comb begin

        tile_col = x_i[9:5];
        tile_row = y_i[8:5];

        if (video_active_i)
            video_addr_o = (tile_row * 20) + tile_col;
        else
            video_addr_o = 9'd0;

    end


    // =====================================================
    // RETARDO DE UN CICLO
    // =====================================================

    always_ff @(posedge clk_pixel_i) begin

        if (rst_i) begin

            x_o            <= 10'd0;
            y_o            <= 10'd0;
            video_active_o <= 1'b0;

        end

        else begin

            x_o            <= x_i;
            y_o            <= y_i;
            video_active_o <= video_active_i;

        end

    end


    // =====================================================
    // ESTADO DEL TILE
    // =====================================================

    always_comb begin

        if (video_active_o)
            tile_state_o = tile_data_i[2:0];
        else
            tile_state_o = 3'b000;

    end

endmodule