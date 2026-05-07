module top (
    input XTAL_IN,
    input nRST,
    output LCD_CLK,
    output LCD_HSYNC,
    output LCD_VSYNC,
    output LCD_DEN,
    output [4:0] LCD_R,
    output [5:0] LCD_G,
    output [4:0] LCD_B
);

assign LCD_CLK = XTAL_IN;

reg [9:0] x;
reg [9:0] y;

always @(posedge XTAL_IN or negedge nRST)begin
    if(!nRST)begin
        x<=0;
        y<=0;
    end else begin
        if(x==799) begin
            x<=0;
            if(y==524)
                y<=0;
            else
                y<= y + 1;
        end else begin
            x<= x+1;
        end
    end
end

wire hsync = (x<41);
wire vsync = (y<10);

wire signed [11:0] px = x - 43;
wire signed [11:0] py = y - 12;

wire visible = (px >=0 && px < 480 &&
                py >=0 && py < 272);

reg vis_d;
always @(posedge XTAL_IN)begin
    vis_d <=visible;
end

//========== SHAPES ==============

reg in_rect;
reg in_circle;
reg in_ellipse;
reg in_ring;
reg in_line;

//rectangle
wire rect_c = (px >= 20 && px < 80 &&
                py >=20 && py < 60);

//circle
wire signed [11:0] dx_c = px - 140;
wire signed [11:0] dy_c = py - 80;
wire [23:0] circle_dist = dx_c*dx_c +dy_c*dy_c;
wire circle_c = (circle_dist < 24'd400);

//ellipse
wire signed [11:0] dx_e = px - 260;
wire signed [11:0] dy_e = py - 100;
wire signed [23:0] dx2_e = dx_e * dx_e;
wire signed [23:0] dy2_e = dy_e * dy_e;

wire [23:0] ellipse_val = (dx2_e << 2) + (dy2_e * 9);
wire ellipse_c = (ellipse_val < 24'h3600);

//rign
localparam signed [11:0] RING_X = 320;
localparam signed [11:0] RING_Y = 170;
localparam signed [11:0] RING_R = 50;

wire signed [12:0] dx_r = px - RING_X;
wire signed [12:0] dy_r = py - RING_Y;

wire [23:0] dist_sq = dx_r*dx_r + dy_r*dy_r;
wire [23:0] r_sq= RING_R * RING_R;
wire signed [24:0] diff = dist_sq - r_sq;

wire ring_c = (diff >= -40) && (diff <= 40);

//line
localparam signed [11:0] AX = 60;
localparam signed [11:0] AY = 120;
localparam signed [11:0] BX = 200;
localparam signed [11:0] BY = 180;

wire signed [12:0] dx = BX-AX;
wire signed [12:0] dy = BY-AY;

wire signed [24:0] line_val= (px - AX) * dy 
                            - (py - AY) * dx;
wire signed [24:0] proj=    (px - AX) * dx 
                            + (py - AY) * dy;

wire signed [24:0] len_sq = dx*dx + dy*dy;

wire line_c =   (line_val < 90 && line_val> -90)
                && (proj >= 0) && (proj <= len_sq);



always @(posedge XTAL_IN)begin
    in_rect <= rect_c;
    in_circle <= circle_c;
    in_ellipse <= ellipse_c;
    in_ring <= ring_c;
    in_line <= line_c;
end


wire [15:0] color = 
    in_line         ?   16'h0000     :
    in_ring         ?   16'h780f    :
    in_circle       ?   16'h001f    :
    in_ellipse      ?   16'hfc40    :
    in_rect         ?   16'hf800    :
                        16'h07e0;

reg [15:0] pixel_d;

always @(posedge XTAL_IN)begin
    pixel_d <= color;
end

assign LCD_R = vis_d ? pixel_d[15:11] : 0;
assign LCD_G = vis_d ? pixel_d[10:5] : 0;
assign LCD_B = vis_d ? pixel_d[4:0] : 0;

assign LCD_DEN = vis_d;
assign LCD_HSYNC = hsync;
assign LCD_VSYNC = vsync;


endmodule