`timescale 1ns/1ps

module tb_battleship_vga_ram;

    logic clk_i       = 0;
    logic clk_pixel_i = 0;

    logic [8:0]  cpu_addr_i;
    logic [31:0] cpu_wdata_i;
    logic        cpu_we_i;
    logic [31:0] cpu_rdata_o;

    logic [8:0]  video_addr_i;
    logic [31:0] video_rdata_o;

    integer errors = 0;


    battleship_vga_ram dut (
        .clk_i,
        .cpu_addr_i,
        .cpu_wdata_i,
        .cpu_we_i,
        .cpu_rdata_o,

        .clk_pixel_i,
        .video_addr_i,
        .video_rdata_o
    );


    // 100 MHz
    always #5 clk_i = ~clk_i;

    // 25 MHz
    always #20 clk_pixel_i = ~clk_pixel_i;


    task cpu_write(
        input logic [8:0] addr,
        input logic [31:0] data
    );
        begin

            @(negedge clk_i);

            cpu_addr_i  = addr;
            cpu_wdata_i = data;
            cpu_we_i    = 1;

            @(negedge clk_i);

            cpu_we_i = 0;

        end
    endtask


    task check_cpu(
        input logic [8:0] addr,
        input logic [31:0] expected,
        input string name
    );
        begin

            @(negedge clk_i);
            cpu_addr_i = addr;

            @(posedge clk_i);
            #1;

            if (cpu_rdata_o === expected)
                $display("PASS: %s", name);
            else begin
                $display("ERROR: %s", name);
                errors++;
            end

        end
    endtask


    task check_video(
        input logic [8:0] addr,
        input logic [31:0] expected,
        input string name
    );
        begin

            @(negedge clk_pixel_i);
            video_addr_i = addr;

            @(posedge clk_pixel_i);
            #1;

            if (video_rdata_o === expected)
                $display("PASS: %s", name);
            else begin
                $display("ERROR: %s", name);
                errors++;
            end

        end
    endtask


    initial begin

        cpu_addr_i   = 0;
        cpu_wdata_i  = 0;
        cpu_we_i     = 0;
        video_addr_i = 0;


        // Primera posición
        cpu_write(
            9'd0,
            32'h0000_0001
        );

        check_cpu(
            9'd0,
            32'h0000_0001,
            "CPU palabra 0"
        );

        check_video(
            9'd0,
            32'h0000_0001,
            "VGA palabra 0"
        );


        // Último tile de una cuadrícula 20x15
        cpu_write(
            9'd299,
            32'h0000_0003
        );

        check_video(
            9'd299,
            32'h0000_0003,
            "VGA tile 299"
        );


        // Última palabra disponible
        cpu_write(
            9'd511,
            32'hDEAD_BEEF
        );

        check_cpu(
            9'd511,
            32'hDEAD_BEEF,
            "Ultima palabra"
        );


        if (errors == 0)
            $display("\nTODAS LAS PRUEBAS PASARON");
        else
            $display("\nERRORES: %0d", errors);

        $finish;

    end

endmodule