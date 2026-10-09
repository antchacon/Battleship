module uart_peripheral #(
    parameter int CLK_FREQ  = 100_000_000,
    parameter int BAUD_RATE = 115200
)(
    input  logic        clk_i,
    input  logic        rst_i,

    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    input  logic        uart_rx_i,
    output logic        uart_tx_o
);


    // =====================================================
    // PARÁMETROS UART
    // =====================================================

    localparam int BIT_CLKS  = CLK_FREQ / BAUD_RATE;
    localparam int HALF_CLKS = BIT_CLKS / 2;


    // =====================================================
    // MAPA DE REGISTROS
    //
    // 00 = CONTROL
    // 01 = DATA_TX
    // 10 = DATA_RX
    // =====================================================

    localparam logic [1:0] CONTROL = 2'b00;
    localparam logic [1:0] DATA_TX = 2'b01;
    localparam logic [1:0] DATA_RX = 2'b10;


    // =====================================================
    // REGISTROS
    // =====================================================

    logic [7:0] tx_data;
    logic [7:0] rx_data;

    logic tx_busy;
    logic new_rx;


    // =====================================================
    // SINCRONIZADOR RX
    // =====================================================

    logic rx_ff1;
    logic rx_sync;


    // =====================================================
    // TRANSMISOR
    // =====================================================

    logic [9:0] tx_shift;

    integer tx_count;
    integer tx_bit;


    // =====================================================
    // RECEPTOR
    // =====================================================

    typedef enum logic [1:0] {

        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_STOP

    } rx_state_t;


    rx_state_t rx_state;

    logic [7:0] rx_shift;

    integer rx_count;
    integer rx_bit;


    // =====================================================
    // LECTURA DE REGISTROS
    // =====================================================

    always_comb begin

        rdata_o = 32'b0;

        case (addr_i)

            // ---------------------------------------------
            // CONTROL
            //
            // bit 0 = tx_busy
            // bit 1 = new_rx
            // ---------------------------------------------

            CONTROL: begin

                rdata_o[0] = tx_busy;
                rdata_o[1] = new_rx;

            end


            // ---------------------------------------------
            // DATA TX
            // ---------------------------------------------

            DATA_TX: begin

                rdata_o[7:0] = tx_data;

            end


            // ---------------------------------------------
            // DATA RX
            // ---------------------------------------------

            DATA_RX: begin

                rdata_o[7:0] = rx_data;

            end


            default: begin

                rdata_o = 32'b0;

            end

        endcase

    end


    // =====================================================
    // SALIDA UART TX
    // =====================================================

    assign uart_tx_o =
        tx_busy
        ? tx_shift[0]
        : 1'b1;


    // =====================================================
    // LÓGICA PRINCIPAL
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            // ---------------------------------------------
            // RX
            // ---------------------------------------------

            rx_ff1  <= 1'b1;
            rx_sync <= 1'b1;


            // ---------------------------------------------
            // REGISTROS
            // ---------------------------------------------

            tx_data <= 8'b0;
            rx_data <= 8'b0;

            tx_busy <= 1'b0;
            new_rx  <= 1'b0;


            // ---------------------------------------------
            // TX
            // ---------------------------------------------

            tx_shift <= 10'h3FF;

            tx_count <= 0;
            tx_bit   <= 0;


            // ---------------------------------------------
            // RX FSM
            // ---------------------------------------------

            rx_state <= RX_IDLE;

            rx_shift <= 8'b0;

            rx_count <= 0;
            rx_bit   <= 0;

        end

        else begin

            // =================================================
            // SINCRONIZACIÓN RX
            // =================================================

            rx_ff1  <= uart_rx_i;
            rx_sync <= rx_ff1;


            // =================================================
            // ESCRITURA DE REGISTROS MMIO
            // =================================================

            if (write_enable_i) begin

                // ---------------------------------------------
                // DATA TX
                //
                // addr = 01
                // ---------------------------------------------

                if (addr_i == DATA_TX) begin

                    tx_data <= wdata_i[7:0];

                end


                // ---------------------------------------------
                // CONTROL
                //
                // addr = 00
                // ---------------------------------------------

                if (addr_i == CONTROL) begin

                    // -----------------------------------------
                    // bit 1 = 1
                    // limpiar bandera new_rx
                    // -----------------------------------------

                    if (wdata_i[1]) begin

                        new_rx <= 1'b0;

                    end


                    // -----------------------------------------
                    // bit 0 = 1
                    // comenzar transmisión
                    // -----------------------------------------

                    if (
                        wdata_i[0] &&
                        !tx_busy
                    ) begin

                        // UART:
                        //
                        // START = 0
                        // DATA  = 8 bits LSB first
                        // STOP  = 1

                        tx_shift <= {
                            1'b1,
                            tx_data,
                            1'b0
                        };

                        tx_busy  <= 1'b1;

                        tx_count <= 0;
                        tx_bit   <= 0;

                    end

                end

            end


            // =================================================
            // TRANSMISOR UART
            // =================================================

            if (tx_busy) begin

                if (
                    tx_count ==
                    BIT_CLKS - 1
                ) begin

                    tx_count <= 0;

                    tx_shift <= {
                        1'b1,
                        tx_shift[9:1]
                    };


                    if (tx_bit == 9) begin

                        tx_busy <= 1'b0;
                        tx_bit  <= 0;

                    end

                    else begin

                        tx_bit <= tx_bit + 1;

                    end

                end

                else begin

                    tx_count <=
                        tx_count + 1;

                end

            end


            // =================================================
            // RECEPTOR UART
            // =================================================

            case (rx_state)

                // ---------------------------------------------
                // ESPERAR START BIT
                // ---------------------------------------------

                RX_IDLE: begin

                    rx_count <= 0;
                    rx_bit   <= 0;

                    if (!rx_sync) begin

                        rx_state <= RX_START;

                    end

                end


                // ---------------------------------------------
                // CONFIRMAR START BIT
                // ---------------------------------------------

                RX_START: begin

                    if (
                        rx_count ==
                        HALF_CLKS - 1
                    ) begin

                        rx_count <= 0;

                        if (!rx_sync) begin

                            rx_state <= RX_DATA;

                        end

                        else begin

                            rx_state <= RX_IDLE;

                        end

                    end

                    else begin

                        rx_count <=
                            rx_count + 1;

                    end

                end


                // ---------------------------------------------
                // RECIBIR 8 BITS
                // ---------------------------------------------

                RX_DATA: begin

                    if (
                        rx_count ==
                        BIT_CLKS - 1
                    ) begin

                        rx_count <= 0;

                        rx_shift[rx_bit]
                            <= rx_sync;


                        if (rx_bit == 7) begin

                            rx_bit   <= 0;
                            rx_state <= RX_STOP;

                        end

                        else begin

                            rx_bit <=
                                rx_bit + 1;

                        end

                    end

                    else begin

                        rx_count <=
                            rx_count + 1;

                    end

                end


                // ---------------------------------------------
                // STOP BIT
                // ---------------------------------------------

                RX_STOP: begin

                    if (
                        rx_count ==
                        BIT_CLKS - 1
                    ) begin

                        rx_count <= 0;


                        if (rx_sync) begin

                            rx_data <= rx_shift;

                            new_rx <= 1'b1;

                        end


                        rx_state <= RX_IDLE;

                    end

                    else begin

                        rx_count <=
                            rx_count + 1;

                    end

                end


                default: begin

                    rx_state <= RX_IDLE;

                end

            endcase

        end

    end

endmodule