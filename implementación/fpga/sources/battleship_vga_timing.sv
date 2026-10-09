module battleship_vga_timing #(
    parameter int H_VISIBLE = 640,
    parameter int H_FRONT   = 16,
    parameter int H_SYNC    = 96,
    parameter int H_BACK    = 48,

    parameter int V_VISIBLE = 480,
    parameter int V_FRONT   = 10,
    parameter int V_SYNC    = 2,
    parameter int V_BACK    = 33
)(
    input  logic       clk_pixel_i,
    input  logic       rst_i,

    output logic       hsync_o,
    output logic       vsync_o,
    output logic       video_active_o,

    output logic [9:0] x_o,
    output logic [9:0] y_o
);

    localparam int H_TOTAL =
        H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    localparam int V_TOTAL =
        V_VISIBLE + V_FRONT + V_SYNC + V_BACK;


    logic [9:0] h_count;
    logic [9:0] v_count;


    // =====================================================
    // CONTADORES
    // =====================================================

    always_ff @(posedge clk_pixel_i) begin

        if (rst_i) begin

            h_count <= 0;
            v_count <= 0;

        end

        else begin

            if (h_count == H_TOTAL - 1) begin

                h_count <= 0;

                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;

            end

            else begin

                h_count <= h_count + 1;

            end

        end

    end


    // =====================================================
    // COORDENADAS
    // =====================================================

    assign x_o = h_count;
    assign y_o = v_count;


    // =====================================================
    // ZONA VISIBLE
    // =====================================================

    assign video_active_o =
        (h_count < H_VISIBLE) &&
        (v_count < V_VISIBLE);


    // =====================================================
    // HSYNC - ACTIVO EN BAJO
    // =====================================================

    assign hsync_o = ~(
        (h_count >= H_VISIBLE + H_FRONT) &&
        (h_count <  H_VISIBLE + H_FRONT + H_SYNC)
    );


    // =====================================================
    // VSYNC - ACTIVO EN BAJO
    // =====================================================

    assign vsync_o = ~(
        (v_count >= V_VISIBLE + V_FRONT) &&
        (v_count <  V_VISIBLE + V_FRONT + V_SYNC)
    );

endmodule