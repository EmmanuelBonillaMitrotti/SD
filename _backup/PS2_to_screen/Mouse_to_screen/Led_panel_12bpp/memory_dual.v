// Memoria de doble puerto para panel LED + Mouse
// Puerto A: Lectura para el panel LED (PIX_ADDR)
// Puerto B: Lectura/Escritura para Mouse_to_screen
module memory_dual#(
    parameter size = 2047,
    parameter width = 11
)(
    input             clk,
    
    // Puerto A - Lectura para panel LED
    input  [width:0]  addr_read,
    input             rd,
    output reg [23:0] rdata,
    
    // Puerto B - Lectura/Escritura para Mouse
    input  [width:0]  addr_write,
    input             wr0,
    input             wr1,
    input  [11:0]     wdata,
    input             paint_permanent,  // Escribir también en backup (pintura permanente)
    output wire [11:0] b_rdata0,
    output wire [11:0] b_rdata1
);

reg [11:0] MEM0 [0:size];
reg [11:0] MEM1 [0:size];
reg [11:0] B_MEM0 [0:size];
reg [11:0] B_MEM1 [0:size];

// Lectura de backup para Mouse_to_screen (usa addr_write)
assign b_rdata0 = B_MEM0[addr_write];
assign b_rdata1 = B_MEM1[addr_write];

initial begin
    $readmemh("./image0.hex", MEM0);
    $readmemh("./image1.hex", MEM1);
    $readmemh("./image0.hex", B_MEM0);
    $readmemh("./image1.hex", B_MEM1);
end

// Escritura de datos en la memoria (Puerto B - Mouse)
always @(posedge clk) begin
    if (wr0) begin 
        MEM0[addr_write] <= wdata;
        if (paint_permanent)
            B_MEM0[addr_write] <= wdata;  // Pintura permanente
    end
    if (wr1) begin 
        MEM1[addr_write] <= wdata;
        if (paint_permanent)
            B_MEM1[addr_write] <= wdata;  // Pintura permanente
    end
end

// Lectura de datos para el panel (Puerto A - Panel LED)
always @(negedge clk) begin
    if (rd) begin
        rdata[23:12] <= MEM0[addr_read];
        rdata[11:0]  <= MEM1[addr_read];
    end
end

endmodule
