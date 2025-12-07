//=============================================================================
// Módulo Top: paint_uart_top
// Descripción: Integra receptor UART del mouse con panel LED
//              Recibe datos X,Y del mouse por UART y pinta en el panel
// Target: Tang Primer 25K
//=============================================================================
module paint_uart_top (
    input  wire        clk,         // Reloj 50MHz
    input  wire        rst,         // Reset activo alto (botón)
    input  wire        uart_rx,     // UART RX (pin B2) - desde Arduino
    
    // Señales del panel LED
    output wire        LP_CLK,
    output wire        LATCH,
    output wire        NOE,
    output wire [4:0]  ROW,
    output wire [2:0]  RGB0,
    output wire [2:0]  RGB1
);

    //=========================================================================
    // Parámetros
    //=========================================================================
    parameter NUM_COLS = 64;
    parameter NUM_ROWS = 64;
    parameter NUM_PIXELS = NUM_COLS * NUM_ROWS;
    parameter HALF_SCREEN = NUM_PIXELS / 2;
    parameter BIT_DEPTH = 4;
    parameter DELAY = 10;
    
    //=========================================================================
    // Señales internas
    //=========================================================================
    
    // Del receptor UART
    wire       btn_left;
    wire       btn_right;
    wire       btn_middle;
    wire [7:0] uart_delta_x;
    wire [7:0] uart_delta_y;
    wire       data_valid;
    
    // Posición acumulada del mouse (9 bits para PS2_Xdata, PS2_Ydata)
    reg signed [8:0] pos_x;
    reg signed [8:0] pos_y;
    
    // Señales de Mouse_to_screen hacia memoria
    wire        wr0, wr1;
    wire [11:0] wdata;
    wire [11:0] m2s_address;
    wire [11:0] b_rdata0, b_rdata1;
    
    // Señales del controlador del panel LED
    wire        w_ZR, w_ZC, w_ZD, w_ZI;
    wire        w_LD, w_SHD;
    wire        w_RST_R, w_RST_C, w_RST_D, w_RST_I;
    wire        w_INC_R, w_INC_C, w_INC_D, w_INC_I;
    wire [10:0] count_delay;
    wire [10:0] delay;
    wire [1:0]  index;
    wire [5:0]  COL;
    wire        PX_CLK_EN;
    wire        tmp_noe, tmp_latch;
    
    // Direcciones de memoria
    wire [10:0] PIX_ADDR;
    wire [23:0] mem_rdata;
    
    // Reloj dividido para el panel
    reg         clk1;
    reg [4:0]   clk_counter;
    
    //=========================================================================
    // Divisor de reloj para el panel LED
    //=========================================================================
    always @(posedge clk) begin
        if (rst) begin
            clk_counter <= 0;
            clk1 <= 0;
        end else begin
            if (clk_counter == 2) begin
                clk1 <= ~clk1;
                clk_counter <= 0;
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end
    
    //=========================================================================
    // Receptor UART del mouse
    //=========================================================================
    mouse_uart_receiver #(
        .CLK_FREQ(50000000),
        .BAUD(9600)
    ) uart_mouse (
        .clk(clk),
        .rst_n(~rst),
        .uart_rx(uart_rx),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_middle(btn_middle),
        .delta_x(uart_delta_x),
        .delta_y(uart_delta_y),
        .data_valid(data_valid)
    );
    
    //=========================================================================
    // Acumulador de posición del mouse
    //=========================================================================
    localparam signed [8:0] POS_MIN = 9'd0;
    localparam signed [8:0] POS_MAX = 9'd63;
    
    wire signed [8:0] delta_x_signed = $signed(uart_delta_x);
    wire signed [8:0] delta_y_signed = $signed(uart_delta_y);
    
    always @(posedge clk) begin
        if (rst) begin
            pos_x <= 9'd32;
            pos_y <= 9'd32;
        end else if (data_valid) begin
            // Acumular delta X
            if (pos_x + delta_x_signed > POS_MAX)
                pos_x <= POS_MAX;
            else if (pos_x + delta_x_signed < POS_MIN)
                pos_x <= POS_MIN;
            else
                pos_x <= pos_x + delta_x_signed;
            
            // Acumular delta Y (invertido)
            if (pos_y - delta_y_signed > POS_MAX)
                pos_y <= POS_MAX;
            else if (pos_y - delta_y_signed < POS_MIN)
                pos_y <= POS_MIN;
            else
                pos_y <= pos_y - delta_y_signed;
        end
    end
    
    //=========================================================================
    // Mouse_to_screen: Convierte posición a dirección de memoria
    //=========================================================================
    Mouse_to_screen #(
        .X_MAX(63),
        .Y_MAX(63),
        .IMG_WIDTH(16'd64),
        .IMG_DIV(32),
        .PIXEL_COLOR(12'h000)
    ) mouse_painter (
        .clk(clk),
        .reset(rst),
        .PS2_Xdata(pos_x),
        .PS2_Ydata(pos_y),
        .b_rdata0(b_rdata0),
        .b_rdata1(b_rdata1),
        .wr0(wr0),
        .wr1(wr1),
        .wdata(wdata),
        .address(m2s_address)
    );
    
    //=========================================================================
    // Memoria de doble puerto
    // Puerto A (addr_read): Lectura para panel LED usando PIX_ADDR
    // Puerto B (addr_write): Lectura/Escritura para Mouse_to_screen
    //=========================================================================
    assign PIX_ADDR = {ROW, COL};
    
    memory_dual #(
        .size(HALF_SCREEN - 1),
        .width($clog2(NUM_PIXELS) - 2)
    ) frame_buffer (
        .clk(clk),
        // Puerto A - Lectura para panel LED
        .addr_read(PIX_ADDR),
        .rd(1'b1),
        .rdata(mem_rdata),
        // Puerto B - Lectura/Escritura para Mouse
        .addr_write(m2s_address[10:0]),
        .wr0(wr0),
        .wr1(wr1),
        .wdata(wdata),
        .b_rdata0(b_rdata0),
        .b_rdata1(b_rdata1)
    );
    
    //=========================================================================
    // Controlador del panel LED
    //=========================================================================
    assign LP_CLK = clk1 & PX_CLK_EN;
    assign LATCH = ~tmp_latch;
    assign NOE = tmp_noe;
    
    count #(.width(4)) count_row (
        .clk(clk1), .reset(w_RST_R), .inc(w_INC_R), .outc(ROW), .zero(w_ZR)
    );
    
    count #(.width(5)) count_col (
        .clk(clk1), .reset(w_RST_C), .inc(w_INC_C), .outc(COL), .zero(w_ZC)
    );
    
    count #(.width(10)) cnt_delay (
        .clk(clk1), .reset(w_RST_D), .inc(w_INC_D), .outc(count_delay)
    );
    
    count #(.width(1)) count_index (
        .clk(clk1), .reset(w_RST_I), .inc(w_INC_I), .outc(index), .zero(w_ZI)
    );
    
    lsr_led #(.init_value(DELAY), .width(10)) lsr_led0 (
        .clk(clk1), .load(w_LD), .shift(w_SHD), .s_A(delay)
    );
    
    comp_4k #(.width(10)) compa (
        .in1(delay), .in2(count_delay), .out(w_ZD)
    );
    
    mux_led mux0 (
        .in0(mem_rdata), .out0({RGB0, RGB1}), .sel(index)
    );
    
    ctrl_lp4k ctrl0 (
        .clk(clk1), .rst(rst), .init(1'b1),
        .ZR(w_ZR), .ZC(w_ZC), .ZD(w_ZD), .ZI(w_ZI),
        .RST_R(w_RST_R), .RST_C(w_RST_C), .RST_D(w_RST_D), .RST_I(w_RST_I),
        .INC_R(w_INC_R), .INC_C(w_INC_C), .INC_D(w_INC_D), .INC_I(w_INC_I),
        .LD(w_LD), .SHD(w_SHD),
        .LATCH(tmp_latch), .NOE(tmp_noe), .PX_CLK_EN(PX_CLK_EN)
    );

endmodule
