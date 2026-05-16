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

always @(posedge XTAL_IN or negedge nRST) begin

    if(!nRST) begin
        x <= 0;
        y <= 0;

    end else begin

        if(x == 799) begin
            x <= 0;

            if(y == 524)
                y <= 0;
            else
                y <= y + 1;

        end else begin
            x <= x + 1;
        end
    end
end

wire hsync = (x < 41);
wire vsync = (y < 10);

wire signed [11:0] px = x - 43;
wire signed [11:0] py = y - 12;

wire visible =
    (px >= 0 && px < 480 &&
     py >= 0 && py < 272);

reg vis_d;

always @(posedge XTAL_IN)
    vis_d <= visible;

reg [26:0] rot_div;
reg [8:0] angle;

always @(posedge XTAL_IN or negedge nRST)begin
    if(!nRST)begin
        rot_div <= 0;
        angle <= 0;
    end else begin
        if(rot_div >=27'd4999999)begin
            rot_div <= 0;

            if(angle==359)
                angle <= 0;
            else
                angle <= angle + 1;

        end else begin
            rot_div <= rot_div + 1;
        end
    end
end

localparam SCALE = 2;
localparam TEXT_W = 72;
localparam TEXT_H = 28;
localparam TEXT_X = (480 - TEXT_W)/2;
localparam TEXT_Y = (272 - TEXT_H)/2;
localparam CENTER_X = TEXT_X + TEXT_W/2;
localparam CENTER_Y = TEXT_Y + TEXT_H/2;

reg signed [15:0] sin_mem[0:90];

initial begin
    $readmemh("sin_lut.mem", sin_mem);
end

reg signed [15:0] sin_lut;
reg signed [15:0] cos_lut;

always @(*)begin
    if (angle <= 90)
        sin_lut = sin_mem[angle];
    
    else if (angle <= 180)
        sin_lut = sin_mem[180-angle];

    else if (angle <= 270)
        sin_lut = -sin_mem[angle-180];

    else
        sin_lut = -sin_mem[360-angle];


    if (angle <= 90)
        cos_lut = sin_mem[90-angle];
    
    else if (angle <= 180)
        cos_lut = -sin_mem[angle-90];

    else if (angle <= 270)
        cos_lut = -sin_mem[270-angle];

    else
        cos_lut = sin_mem[angle-270];

end

wire signed [12:0] rx = px - CENTER_X;
wire signed [12:0] ry = py - CENTER_Y;
wire signed [31:0] rot_x_temp = (rx * cos_lut + ry * sin_lut); 
wire signed [31:0] rot_y_temp = (-rx * sin_lut + ry * cos_lut);

wire signed [31:0] rot_x_round = rot_x_temp + 32'sd128;
wire signed [31:0] rot_y_round = rot_y_temp + 32'sd128;
wire signed [12:0] rot_x = rot_x_round >>> 8;
wire signed [12:0] rot_y = rot_y_round >>> 8;
wire signed [12:0] lx = rot_x + TEXT_W/2;
wire signed [12:0] ly = rot_y + TEXT_H/2;

wire inside_text = (lx>=0 && lx < TEXT_W && ly >= 0 && ly < TEXT_H);
wire [11:0] tx = lx >>> SCALE;
wire [11:0] ty = ly >>> SCALE;
wire [2:0] char_x = tx % 6;
wire [2:0] char_y = ty;
wire [1:0] char_id = tx/6;

function font_lookup;

    input [1:0] cid;
    input [2:0] cx;
    input [2:0] cy;

    begin

        font_lookup = 0;

        case(cid)

            0: begin
                case(cy)
                    0: font_lookup = (cx==0 || cx==4);
                    1: font_lookup = (cx==0 || cx==4);
                    2: font_lookup = (cx==0 || cx==4);
                    3: font_lookup = (cx<=4);
                    4: font_lookup = (cx==0 || cx==4);
                    5: font_lookup = (cx==0 || cx==4);
                    6: font_lookup = (cx==0 || cx==4);
                endcase
            end

            1: begin
                case(cy)
                    0: font_lookup = (cx<=4);
                    1: font_lookup = (cx==0);
                    2: font_lookup = (cx==0);
                    3: font_lookup = (cx<=3);
                    4: font_lookup = (cx==0);
                    5: font_lookup = (cx==0);
                    6: font_lookup = (cx<=4);
                endcase
            end

            2: begin
                case(cy)
                    0: font_lookup = (cx==0 || cx==4);
                    1: font_lookup = (cx==0 || cx==4);
                    2: font_lookup = (cx==1 || cx==3);
                    3: font_lookup = (cx==2);
                    4: font_lookup = (cx==2);
                    5: font_lookup = (cx==2);
                    6: font_lookup = (cx==2);
                endcase
            end

            default:
                font_lookup = 0;

        endcase
    end
endfunction

wire font_pixel = inside_text && font_lookup(char_id, char_x, char_y);

reg [15:0] pixel_d;

always @(posedge XTAL_IN) begin

    if(font_pixel)
        pixel_d <= 16'hFFFF;
    else
        pixel_d <= 16'h0010;

end

assign LCD_R = vis_d ? pixel_d[15:11] : 0;
assign LCD_G = vis_d ? pixel_d[10:5]  : 0;
assign LCD_B = vis_d ? pixel_d[4:0]   : 0;

assign LCD_DEN   = vis_d;
assign LCD_HSYNC = hsync;
assign LCD_VSYNC = vsync;

endmodule