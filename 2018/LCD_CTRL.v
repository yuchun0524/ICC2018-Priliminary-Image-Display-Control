module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output reg [5:0] IROM_A;
output reg IRAM_valid;
output reg [7:0] IRAM_D;
output reg [5:0] IRAM_A;
output reg busy;
output reg done;
reg   [7:0]buffer[63:0];
reg   [5:0]point;
reg   valid;
reg   state;
reg   zero;
wire  [9:0]average = ((buffer[point] + buffer[point + 1]) + (buffer[point + 8] + buffer[point + 9])) >> 2;
wire  [7:0]cmp0 = (buffer[point] > buffer[point + 1])?buffer[point]:buffer[point + 1];
wire  [7:0]cmp1 = (buffer[point + 8] > buffer[point + 9])?buffer[point + 8]:buffer[point + 9];
wire  [7:0]cmp2 = (buffer[point] < buffer[point + 1])?buffer[point]:buffer[point + 1];
wire  [7:0]cmp3 = (buffer[point + 8] < buffer[point + 9])?buffer[point + 8]:buffer[point + 9];
wire  [7:0]maxValue = (cmp0 > cmp1)?cmp0:cmp1;
wire  [7:0]minValue = (cmp2 < cmp3)?cmp2:cmp3; 
integer i;
parameter write = 4'd0,
          up = 4'd1,
          down = 4'd2,
          left = 4'd3,
          right = 4'd4,
          max = 4'd5,
          min = 4'd6,
          avg = 4'd7,
          ccwr = 4'd8,
          cwr = 4'd9,
          mx = 4'd10,
          my = 4'd11;
always@(posedge clk)
begin
  if(reset)
    begin
      IROM_rd <= 1'b1;
      IROM_A <= 6'd0;
      IRAM_valid <= 1'b0;
      IRAM_D <= 8'd0;
      IRAM_A <= 6'd0;
      busy <= 1'b1;
      done <= 1'b0;  
      zero <= 1'b1;
      state <= 1'b0;
      for(i = 0; i < 64; i = i + 1)
        buffer[i] <= 8'd0;
      point <= 6'd27;
      valid <= 1'b0;
    end
  else
    begin
      case(state)
        1'b0:begin
          buffer[IROM_A] <= IROM_Q;
          if(IROM_A == 6'd63)
            begin
              IROM_rd <= 1'b0;
              busy <= 1'b0;
              state <= 1'b1;
            end
          else
            begin
              IROM_A <= IROM_A + 1;             
            end
        end
        1'b1:begin
          if(cmd_valid)
            begin
              case(cmd)
                write:begin
                  valid <= 1'b1;
                  IRAM_valid <= 1'b1;
                  busy <= 1'b1;
                end
                up:begin
                  valid <= 1'b0;
                  if(point <= 6)
                    point <= point;
                  else
                    point <= point - 8;
                end
                down:begin
                  valid <= 1'b0;
                  if(point <= 54 && point >= 48)
                    point <= point;
                  else
                    point <= point + 8;
                end
                left:begin     
                  valid <= 1'b0;
                  if(point[2:0] == 3'b000)
                    point <= point;
                  else
                    point <= point - 1;
                end
                right:begin
                  valid <= 1'b0;
                  if(point[2:0] == 3'b110)
                    point <= point;
                  else
                    point <= point + 1;
                end
                max:begin
                  valid <= 1'b0;
                  buffer[point] <= maxValue;
                  buffer[point + 1] <= maxValue;
                  buffer[point + 8] <= maxValue;
                  buffer[point + 9] <= maxValue;
                end
                min:begin
                  valid <= 1'b0;
                  buffer[point] <= minValue;
                  buffer[point + 1] <= minValue;
                  buffer[point + 8] <= minValue;
                  buffer[point + 9] <= minValue;
                end
                avg:begin
                  valid <= 1'b0;
                  buffer[point] <= average;
                  buffer[point + 1] <= average;
                  buffer[point + 8] <= average;
                  buffer[point + 9] <= average;
                end
                ccwr:begin
                  valid <= 1'b0;
                  buffer[point] <= buffer[point + 1];
                  buffer[point + 1] <= buffer[point + 9];
                  buffer[point + 8] <= buffer[point];
                  buffer[point + 9] <= buffer[point + 8];
                end
                cwr:begin
                  valid <= 1'b0;
                  buffer[point] <= buffer[point + 8];
                  buffer[point + 1] <= buffer[point];
                  buffer[point + 8] <= buffer[point + 9];
                  buffer[point + 9] <= buffer[point + 1];
                end
                mx:begin
                  valid <= 1'b0;  
                  buffer[point] <= buffer[point + 8];
                  buffer[point + 1] <= buffer[point + 9];
                  buffer[point + 8] <= buffer[point];
                  buffer[point + 9] <= buffer[point + 1];           
                end
                my:begin
                  valid <= 1'b0;
                  buffer[point] <= buffer[point + 1];
                  buffer[point + 1] <= buffer[point];
                  buffer[point + 8] <= buffer[point + 9];
                  buffer[point + 9] <= buffer[point + 8];
                end
                default:begin
                  valid <= 1'b0;
                end
              endcase
            end
          else
            begin
              if(valid)
                begin
                  if(zero)
                    begin
                      zero <= 1'b0;
                      IRAM_D <= buffer[0];
                    end
                  else
                    begin
                      IRAM_D <= buffer[IRAM_A + 1];
                      if(IRAM_A == 6'd63)
                        begin
                          busy <= 1'b0;
                          done <= 1'b1;
                          valid <= 1'b0;
                        end
                      else
                        begin
                          IRAM_A <= IRAM_A + 1;
                        end
                    end             
                end
              else
                begin
                  IRAM_A <= IRAM_A;
                end
            end
        end
        default:begin
          state <= state;
        end
      endcase
    end
end
endmodule