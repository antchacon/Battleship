`timescale 1ns/1ps

module tb_battleship_vga_timing;

    localparam int H_VISIBLE = 8;
    localparam int H_FRONT   = 2;
    localparam int H_SYNC    = 2;
    localparam int H_BACK    = 2;

    localparam int V_VISIBLE = 4;
    localparam int V_FRONT   = 1;
    localparam int V_SYNC    = 1;
    localparam int V_BACK    = 1;

    localparam int H_TOTAL =
        H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    localparam int V_TOTAL =
        V_VISIBLE + V_FRONT + V_SYNC + V_BACK;


    logic clk_pixel_i = 0;
    logic rst_i;

    logic hsync_o;
    logic vsync_o;
    logic video_active_o;

    logic [9:0] x_o;
    logic [9:0] y_o;

    integer active_count;
    integer hsync_count;
    integer vsync_count;
    integer errors = 0;


    battleship_vga_timing #(
        .H_VISIBLE(H_VISIBLE),
        .H_FRONT(H_FRONT),
        .H_SYNC(H_SYNC),
        .H_BACK(H_BACK),

        .V_VISIBLE(V_VISIBLE),
        .V_FRONT(V_FRONT),
        .V_SYNC(V_SYNC),
        .V_BACK(V_BACK)
    ) dut (
        .clk_pixel_i,
        .rst_i,
        .hsync_o,
        .vsync_o,
        .video_active_o,
        .x_o,
        .y_o
    );


    always #20 clk_pixel_i = ~clk_pixel_i;


    initial begin

        rst_i = 1;

        active_count = 0;
        hsync_count  = 0;
        vsync_count  = 0;

        repeat(2) @(posedge clk_pixel_i);

        rst_i = 0;


        // Recorrer un frame completo
        repeat(H_TOTAL * V_TOTAL) begin

            @(negedge clk_pixel_i);

            if (video_active_o)
                active_count++;

            if (!hsync_o)
                hsync_count++;

            if (!vsync_o)
                vsync_count++;

        end


        // Zona visible
        if (active_count == H_VISIBLE * V_VISIBLE)
            $display("PASS: Area visible");
        else begin
            $display("ERROR: Area visible");
            errors++;
        end


        // HSYNC
        if (hsync_count == H_SYNC * V_TOTAL)
            $display("PASS: HSYNC");
        else begin
            $display("ERROR: HSYNC");
            errors++;
        end


        // VSYNC
        if (vsync_count == V_SYNC * H_TOTAL)
            $display("PASS: VSYNC");
        else begin
            $display("ERROR: VSYNC");
            errors++;
        end


        // El contador debe volver al inicio
        if ((x_o == 0) && (y_o == 0))
            $display("PASS: Fin de frame");
        else begin
            $display(
                "ERROR: Fin de frame | x=%0d y=%0d",
                x_o,
                y_o
            );
            errors++;
        end


        if (errors == 0)
            $display("\nTODAS LAS PRUEBAS PASARON");
        else
            $display("\nERRORES: %0d", errors);


        $finish;

    end

endmodule
