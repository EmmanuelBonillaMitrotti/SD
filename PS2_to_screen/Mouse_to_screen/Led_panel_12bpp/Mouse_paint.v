// Módulo: Mouse_paint
// Descripción: Maneja el cursor del mouse y pinta cuando se presiona click izquierdo
// - Cursor negro que se mueve sin dejar rastro (solo muestra posición actual)
// - Al presionar click izquierdo, pinta permanentemente en negro
module Mouse_paint #(
    parameter X_MAX = 63,         
    parameter Y_MAX = 63,         
    parameter IMG_WIDTH = 16'd64, 
    parameter IMG_DIV = 32,       
    parameter CURSOR_COLOR = 12'h000,  // Color del cursor (negro)
    parameter PAINT_COLOR = 12'h00F    // Color de pintado (azul oscuro)
)(
    input              clk,
    input              reset,      
    input [8:0]        PS2_Xdata,
    input [8:0]        PS2_Ydata,
    input              btn_left,     // Botón izquierdo para pintar
    input  [11:0]      b_rdata0,
    input  [11:0]      b_rdata1,
    output reg         wr0,
    output reg         wr1,
    output reg [11:0]  wdata,
    output reg [11:0]  address
);

reg [2:0] estado; 
localparam START        = 3'b000;
localparam START_MULT   = 3'b001; 
localparam WAIT_MULT    = 3'b010; 
localparam RESTORE      = 3'b011; 
localparam PAINT_CURSOR = 3'b100;
localparam PAINT_PERM   = 3'b101;  // Pintar permanente

reg [11:0] dir_anterior; 
reg        mem_anterior; 
reg [6:0] x_fin, y_fin, y_offset;
reg       sel_mem_actual;
reg       painting;      // Flag: estamos pintando permanente

// Cálculo de valor final de X,Y
always @(*) begin
    if (PS2_Xdata > X_MAX)
        x_fin = X_MAX;
    else if (PS2_Xdata < 0)
        x_fin = 0;
    else
        x_fin = PS2_Xdata;

    if (PS2_Ydata > Y_MAX)
        y_fin = Y_MAX;
    else if (PS2_Ydata < 0)
        y_fin = 0;
    else
        y_fin = PS2_Ydata;

    sel_mem_actual = (y_fin > IMG_DIV);

    if (sel_mem_actual)
        y_offset = y_fin - (IMG_DIV + 1);
    else
        y_offset = y_fin;
end

reg init_mult;
wire done_mult;
wire [31:0] result_mult;
wire [11:0] y_mult_result = result_mult[11:0]; 
wire [11:0] dir_actual = y_mult_result + x_fin; 
wire movimiento_detectado = (dir_actual != dir_anterior) && (estado == START);

// Módulo de multiplicación
mult u_multiplier (
    .clk    (clk),
    .reset  (reset),
    .init   (init_mult),             
    .op_A   ({9'b0, y_offset}),      
    .op_B   (IMG_WIDTH),             
    .result (result_mult),           
    .done   (done_mult)              
);

// Máquina de estados
always @(posedge clk) begin
    wr0 <= 0;
    wr1 <= 0;
    init_mult <= 0;
    
    if (reset) begin
        estado <= START;
        dir_anterior <= 12'h0;
        mem_anterior <= 1'b0;
        painting <= 1'b0;
    end else begin
        
        case (estado)
            START: begin
                if (movimiento_detectado) begin
                    painting <= btn_left;  // Guardar si estamos pintando
                    estado <= START_MULT; 
                end
            end

            START_MULT: begin
                init_mult <= 1;
                estado <= WAIT_MULT;
            end

            WAIT_MULT: begin
                if (done_mult) begin
                    estado <= RESTORE;
                end else begin
                    estado <= WAIT_MULT; 
                end
            end

            RESTORE: begin 
                // Restaurar solo si NO estábamos pintando en esa posición
                address <= dir_anterior; 
                
                if (mem_anterior == 0) begin 
                    wdata <= b_rdata0; 
                    wr0 <= 1;
                end 
                else begin 
                    wdata <= b_rdata1;
                    wr1 <= 1;
                end
                
                // Si estamos pintando, ir a pintar permanente
                if (painting) begin
                    estado <= PAINT_PERM;
                end else begin
                    estado <= PAINT_CURSOR;
                end
            end

            PAINT_PERM: begin
                // Pintar permanente en el backup (para que persista)
                // Esto modifica B_MEM para que el color quede fijo
                address <= dir_actual;
                wdata <= PAINT_COLOR;
                
                if (sel_mem_actual == 0) begin 
                    wr0 <= 1;
                end 
                else begin 
                    wr1 <= 1;
                end

                dir_anterior <= dir_actual;
                mem_anterior <= sel_mem_actual;
                
                estado <= PAINT_CURSOR;
            end

            PAINT_CURSOR: begin 
                // Pintar cursor (temporal, se restaurará al moverse)
                address <= dir_actual; 
                wdata <= CURSOR_COLOR; 
                
                if (sel_mem_actual == 0) begin 
                    wr0 <= 1;
                end 
                else begin 
                    wr1 <= 1;
                end

                dir_anterior <= dir_actual;
                mem_anterior <= sel_mem_actual;
                
                estado <= START; 
            end
            
            default: estado <= START;
        endcase
    end
end

endmodule
