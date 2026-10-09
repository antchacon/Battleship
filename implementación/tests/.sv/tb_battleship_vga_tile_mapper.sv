`timescale 1ns/1ps

module tb_battleship_vga_tile_mapper;

    logic clk_pixel_i = 0;
    logic rst_i;

    logic [9:0] x_i;
    logic [9:0] y_i;
    logic       video_active_i;

    logic [31:0] tile_data_i;

    logic [8:0] video_addr_o;

    logic [9:0] x_o;
    logic [9:0] y_o;
    logic       video_active_o;

    logic [2:0] tile_state_o;

    integer errors = 0;


    battleship_vga_tile_mapper dut (
        .clk_pixel_i,
        .rst_i,

        .x_i,
        .y_i,
        .video_active_i,

        .tile_data_i,

        .video_addr_o,

        .x_o,
        .y_o,
        .video_active_o,

        .tile_state_o
    );


    always #20 clk_pixel_i = ~clk_pixel_i;


    task check_addr(
        input logic [9:0] x,
        input logic [9:0] y,
        input logic [8:0] expected,
        input string name
    );
        begin

            x_i = x;
            y_i = y;
            video_active_i = 1;

            #1;

            if (video_addr_o == expected)
                $display("PASS: %s", name);

            else begin

                $display(
                    "ERROR: %s | esperado=%0d recibido=%0d",
                    name,
                    expected,
                    video_addr_o
                );

                errors++;

            end

        end
    endtask


    initial begin

        rst_i          = 1;
        x_i            = 0;
        y_i            = 0;
        video_active_i = 0;
        tile_data_i    = 0;

        repeat(2) @(posedge clk_pixel_i);

        rst_i = 0;


        // Tile 0
        check_addr(
            10'd0,
            10'd0,
            9'd0,
            "Pixel 0,0"
        );


        // Sigue siendo tile 0
        check_addr(
            10'd31,
            10'd31,
            9'd0,
            "Pixel 31,31"
        );


        // Tile 1
        check_addr(
            10'd32,
            10'd0,
            9'd1,
            "Tile columna 1"
        );


        // Primera columna de segunda fila
        check_addr(
            10'd0,
            10'd32,
            9'd20,
            "Tile fila 1"
        );


        // Tile final visible = 299
        check_addr(
            10'd639,
            10'd479,
            9'd299,
            "Ultimo tile visible"
        );


        // Fuera de zona visible
        video_active_i = 0;
        #1;

        if (video_addr_o == 0)
            $display("PASS: Zona no visible");
        else begin
            $display("ERROR: Zona no visible");
            errors++;
        end


        // Comprobar retardo y estado
        x_i            = 100;
        y_i            = 200;
        video_active_i = 1;
        tile_data_i    = 32'h0000_0003;

        @(posedge clk_pixel_i);
        #1;

        if (
            x_o == 100 &&
            y_o == 200 &&
            video_active_o == 1 &&
            tile_state_o == 3'b011
        )
            $display("PASS: Alineacion tile");
        else begin
            $display("ERROR: Alineacion tile");
            errors++;
        end


        if (errors == 0)
            $display("\nTODAS LAS PRUEBAS PASARON");
        else
            $display("\nERRORES: %0d", errors);


        $finish;

    end

endmodule