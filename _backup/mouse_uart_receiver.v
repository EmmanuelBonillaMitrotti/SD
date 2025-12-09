//=============================================================================
// Módulo: mouse_uart_receiver
// Descripción: Recibe paquetes de 3 bytes del mouse por UART
//              Formato: [buttons][delta_x][delta_y]
// Autor: Para Tang Primer 25K
//=============================================================================
module mouse_uart_receiver #(
    parameter CLK_FREQ = 50000000,  // Frecuencia del reloj del sistema (50MHz por defecto)
    parameter BAUD     = 9600       // Velocidad del UART (9600 para SoftwareSerial)
) (
    input  wire        clk,         // Reloj del sistema
    input  wire        rst_n,       // Reset activo bajo
    input  wire        uart_rx,     // Pin RX del UART (conectar al TX del Arduino/ESP32)
    
    // Salidas procesadas del mouse
    output reg         btn_left,    // Botón izquierdo
    output reg         btn_right,   // Botón derecho
    output reg         btn_middle,  // Botón central
    output reg  [7:0]  delta_x,     // Movimiento X (con signo, int8_t)
    output reg  [7:0]  delta_y,     // Movimiento Y (con signo, int8_t)
    output reg         data_valid   // Pulso cuando hay datos válidos
);

    //=========================================================================
    // Señales internas de la UART
    //=========================================================================
    wire [7:0] rx_data;
    wire       rx_avail;
    reg        rx_ack;
    
    // Instancia del módulo UART (solo RX, TX no usado)
    uart #(
        .freq_hz(CLK_FREQ),
        .baud(BAUD)
    ) uart_inst (
        .reset(~rst_n),
        .clk(clk),
        .uart_rxd(uart_rx),
        .uart_txd(),           // No usado
        .rx_data(rx_data),
        .rx_avail(rx_avail),
        .rx_error(),           // Opcional: manejar errores
        .rx_ack(rx_ack),
        .tx_data(8'd0),        // No usado
        .tx_wr(1'b0),          // No usado
        .tx_busy()             // No usado
    );

    //=========================================================================
    // Máquina de estados para recibir los 3 bytes
    //=========================================================================
    localparam WAIT_BYTE0 = 2'd0;  // Esperando byte de botones
    localparam WAIT_BYTE1 = 2'd1;  // Esperando byte delta_x
    localparam WAIT_BYTE2 = 2'd2;  // Esperando byte delta_y
    localparam PROCESS    = 2'd3;  // Procesar paquete completo
    
    reg [1:0] state;
    reg [7:0] byte_buffer [0:2];
    
    // Timeout para reiniciar si no llegan bytes completos
    reg [23:0] timeout_counter;
    localparam TIMEOUT_MAX = CLK_FREQ / 10; // 100ms timeout
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= WAIT_BYTE0;
            rx_ack          <= 1'b0;
            data_valid      <= 1'b0;
            btn_left        <= 1'b0;
            btn_right       <= 1'b0;
            btn_middle      <= 1'b0;
            delta_x         <= 8'd0;
            delta_y         <= 8'd0;
            timeout_counter <= 24'd0;
        end else begin
            rx_ack     <= 1'b0;
            data_valid <= 1'b0;
            
            // Contador de timeout
            if (state != WAIT_BYTE0) begin
                if (timeout_counter < TIMEOUT_MAX) begin
                    timeout_counter <= timeout_counter + 1'b1;
                end else begin
                    // Timeout: reiniciar y descartar bytes parciales
                    state           <= WAIT_BYTE0;
                    timeout_counter <= 24'd0;
                end
            end
            
            case (state)
                WAIT_BYTE0: begin
                    timeout_counter <= 24'd0;
                    if (rx_avail) begin
                        byte_buffer[0] <= rx_data;  // Botones
                        rx_ack         <= 1'b1;
                        state          <= WAIT_BYTE1;
                    end
                end
                
                WAIT_BYTE1: begin
                    if (rx_avail) begin
                        byte_buffer[1]  <= rx_data;  // Delta X
                        rx_ack          <= 1'b1;
                        state           <= WAIT_BYTE2;
                        timeout_counter <= 24'd0;
                    end
                end
                
                WAIT_BYTE2: begin
                    if (rx_avail) begin
                        byte_buffer[2]  <= rx_data;  // Delta Y
                        rx_ack          <= 1'b1;
                        state           <= PROCESS;
                        timeout_counter <= 24'd0;
                    end
                end
                
                PROCESS: begin
                    // Extraer datos del paquete
                    btn_left   <= byte_buffer[0][0];
                    btn_right  <= byte_buffer[0][1];
                    btn_middle <= byte_buffer[0][2];
                    delta_x    <= byte_buffer[1];
                    delta_y    <= byte_buffer[2];
                    data_valid <= 1'b1;
                    
                    state <= WAIT_BYTE0;
                end
                
                default: state <= WAIT_BYTE0;
            endcase
        end
    end

endmodule
