module debounce_j1 #(
    parameter int COUNT_MAX = 500_000
)(
    input  logic clk_i,
    input  logic rst_i,
    input  logic signal_i,
    output logic signal_o
);

    logic sync_1;
    logic sync_2;

    integer count;


    // =====================================================
    // SINCRONIZADOR DE 2 FLIP-FLOPS
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            sync_1 <= 1'b0;
            sync_2 <= 1'b0;

        end

        else begin

            sync_1 <= signal_i;
            sync_2 <= sync_1;

        end

    end


    // =====================================================
    // DEBOUNCE
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            signal_o <= 1'b0;
            count    <= 0;

        end

        else begin

            // Si la entrada sincronizada coincide con
            // la salida actual, no hay cambio pendiente.
            if (sync_2 == signal_o) begin

                count <= 0;

            end

            else begin

                // La entrada debe permanecer estable
                // COUNT_MAX ciclos antes de aceptarla.
                if (count == COUNT_MAX - 1) begin

                    signal_o <= sync_2;
                    count    <= 0;

                end

                else begin

                    count <= count + 1;

                end

            end

        end

    end

endmodule