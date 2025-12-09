//=============================================================================
// Módulo Top: mouse_uart_top
// Descripción: Top module para recibir datos del mouse por UART
//              y mostrar estado en LED
// Target: Tang Primer 25K
//=============================================================================
module mouse_uart_top (
    input  wire        clk,         // Reloj 50MHz
    input  wire        rst_n,       // Reset activo bajo (botón)
    input  wire        uart_rx,     // UART RX (pin B2)
    
    // LED para debug
    output wire        led_left     // LED indica botón izquierdo o actividad
);

    // Señales del receptor de mouse
    wire       btn_left;
    wire       btn_right;
    wire       btn_middle;
    wire [7:0] delta_x;
    wire [7:0] delta_y;
    wire       data_valid;
    
    // Contador para LED de actividad
    reg [23:0] valid_counter;
    
    // Instancia del receptor UART del mouse
    mouse_uart_receiver #(
        .CLK_FREQ(50000000),  // 50MHz
        .BAUD(9600)           // 9600 baud (SoftwareSerial)
    ) mouse_rx (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_middle(btn_middle),
        .delta_x(delta_x),
        .delta_y(delta_y),
        .data_valid(data_valid)
    );
    
    // LED de actividad: parpadea cuando llegan datos o botón izquierdo presionado
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_counter <= 24'd0;
        end else begin
            if (data_valid) begin
                valid_counter <= 24'd5000000; // ~100ms a 50MHz
            end else if (valid_counter > 0) begin
                valid_counter <= valid_counter - 1'b1;
            end
        end
    end
    
    // LED encendido si: hay actividad O botón izquierdo presionado
    assign led_left = (valid_counter > 0) | btn_left;

endmodule
