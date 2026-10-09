`timescale 1ns/1ps

module tb_battleship_vga_renderer;

    logic       video_active_i;
    logic [2:0] tile_state_i;

    logic [3:0] vga_r_o;
    logic [3:0] vga_g_o;
    logic [3:0] vga_b_o;

    integer errors = 0;


    battleship_vga_renderer dut (
        .video_active_i,
        .tile_state_i,
        .vga_r_o,
        .vga_g_o,
        .vga_b_o
    );


    task check_color(
        input logic [2:0] state,
        input logic [3:0] r,
        input logic [3:0] g,
        input logic [3:0] b,
        input string name
    );
        begin

            tile_state_i   = state;
            video_active_i = 1;

            #1;

            if (
                vga_r_o == r &&
                vga_g_o == g &&
                vga_b_o == b
            )
                $display("PASS: %s", name);

            else begin

                $display("ERROR: %s", name);
                errors++;

            end

        end
    endtask


    initial begin

        video_active_i = 0;
        tile_state_i   = 0;


        // Agua
        check_color(
            3'b000,
            4'h0, 4'h0, 4'hF,
            "Agua"
        );


        // Barco
        check_color(
            3'b001,
            4'h0, 4'hF, 4'h0,
            "Barco"
        );


        // Impacto
        check_color(
            3'b010,
            4'hF, 4'h0, 4'h0,
            "Impacto"
        );


        // Fallo
        check_color(
            3'b011,
            4'hF, 4'hF, 4'hF,
            "Fallo"
        );


        // Fuera del área visible
        video_active_i = 0;
        tile_state_i   = 3'b001;

        #1;

        if (
            vga_r_o == 0 &&
            vga_g_o == 0 &&
            vga_b_o == 0
        )
            $display("PASS: Zona no visible");

        else begin
            $display("ERROR: Zona no visible");
            errors++;
        end


        if (errors == 0)
            $display("\nTODAS LAS PRUEBAS PASARON");
        else
            $display("\nERRORES: %0d", errors);

        $finish;

    end

endmodule