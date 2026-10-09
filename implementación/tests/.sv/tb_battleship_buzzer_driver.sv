`timescale 1ns/1ps

module tb_battleship_buzzer_driver;

    localparam integer CLK_FREQ = 10_000;

    logic        clk_i;
    logic        rst_i;
    logic [31:0] buzzer_data_i;
    logic        buzzer_o;


    battleship_buzzer_driver #(
        .CLK_FREQ(CLK_FREQ)
    ) dut (
        .clk_i         (clk_i),
        .rst_i         (rst_i),
        .buzzer_data_i (buzzer_data_i),
        .buzzer_o      (buzzer_o)
    );


    // Clock de 10 kHz
    initial begin
        clk_i = 0;
        forever #50_000 clk_i = ~clk_i;
    end


    task automatic probar_sonido(
        input logic [2:0] codigo,
        input string nombre
    );

        begin

            $display("");
            $display("==============================");
            $display("SONIDO: %s", nombre);
            $display("CODIGO: %03b", codigo);
            $display("==============================");

            // Apagar primero
            buzzer_data_i = 32'd0;

            repeat (3)
                @(posedge clk_i);

            // Activar sonido
            buzzer_data_i[2:0] = codigo;

            // Esperar inicio
            wait(dut.playing == 1'b1);

            $display(
                "Inicio en t = %0t",
                $time
            );

            // Esperar final
            wait(dut.playing == 1'b0);

            $display(
                "Fin en t = %0t",
                $time
            );

            // Volver a 000
            buzzer_data_i = 32'd0;

            repeat (5)
                @(posedge clk_i);

        end

    endtask


    initial begin

        rst_i         = 1'b1;
        buzzer_data_i = 32'd0;

        repeat (5)
            @(posedge clk_i);

        rst_i = 1'b0;

        repeat (3)
            @(posedge clk_i);


        // 001 - Inicio
        probar_sonido(
            3'b001,
            "INICIO DE PARTIDA"
        );


        // 010 - Impacto
        probar_sonido(
            3'b010,
            "DISPARO CON IMPACTO"
        );


        // 011 - Fallo
        probar_sonido(
            3'b011,
            "DISPARO CON FALLO"
        );


        // 100 - Barco hundido
        probar_sonido(
            3'b100,
            "BARCO HUNDIDO"
        );


        // 101 - Colocación inválida
        probar_sonido(
            3'b101,
            "COLOCACION INVALIDA"
        );


        // 110 - Victoria
        probar_sonido(
            3'b110,
            "VICTORIA"
        );


        // 111 - Cambio de jugador
        probar_sonido(
            3'b111,
            "CAMBIO DE JUGADOR"
        );


        $display("");
        $display("==============================");
        $display("TODOS LOS SONIDOS PROBADOS");
        $display("==============================");

        #1_000_000;

        $finish;

    end

endmodule