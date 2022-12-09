module pongFinal(clk, rst, player1,player2, led, VGA_CLK, VGA_VS, VGA_HS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B, HEX0, HEX3);

input clk;
input rst;
input [2:0] player1;
input [2:0] player2;
output [6:0] HEX0, HEX3;
output [17:0] led;

reg ballXdir, ballYdir;
reg border_in;
reg paddle_in;
reg ball_in;
reg brick_in;
reg [5:0] S;
reg [5:0] NS;
reg [7:0]x;
reg [7:0]y;
reg [7:0]paddle_x, paddle_y, paddle_x2, paddle_y2;
reg [7:0]ballX, ballY;
reg [2:0]colour;
reg [7:0] drawMid;
reg [17:0] drawBackground;
reg [7:0] yPaddle;

wire frame;

reg [3:0] L_score;
reg [3:0] R_score;

assign led[5:0] = S;

output VGA_CLK;
output VGA_HS;
output VGA_VS;
output VGA_BLANK_N;
output VGA_SYNC_N;
output [9:0] VGA_R;
output [9:0] VGA_G;
output [9:0] VGA_B;

// VGA inspired by ECE students Deniz and Jose
vga_adapter VGA(
  .resetn(1'b1),
  .clock(clk),
  .colour(colour),
  .x(x),
  .y(y),
  .plot(1'b1),
  .VGA_R(VGA_R),
  .VGA_G(VGA_G),
  .VGA_B(VGA_B),
  .VGA_HS(VGA_HS),
  .VGA_VS(VGA_VS),
  .VGA_BLANK(VGA_BLANK_N),
  .VGA_SYNC(VGA_SYNC_N),
  .VGA_CLK(VGA_CLK));
defparam VGA.RESOLUTION = "160x120";
defparam VGA.MONOCHROME = "FALSE";
defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
defparam VGA.BACKGROUND_IMAGE = "black.mif";

seven_segment left(L_score, HEX0);
seven_segment right(R_score, HEX3);
parameter
	START			   = 6'd0,
	MIDDLE		= 6'd22,
   PADDLE1    = 6'd1,
	PADDLE2	= 6'd2,
   IN_BALL   	= 6'd3,
   IDLE           = 6'd4,
   DEL_PADDLE   = 6'd5,
   UPDATE_PADDLE  = 6'd6,
   DRAW_PADDLE    = 6'd7,
	DEL_PADDLE2   = 6'd8,
   UPDATE_PADDLE2  = 6'd9,
   DRAW_PADDLE2    = 6'd10,
   ERASE_BALL     = 6'd11,
   UPDATE_BALL    = 6'd12,
   DRAW_BALL      = 6'd13,
   WIN_GAME       = 6'd14,
	GAME_OVER		= 6'd15,
	WAIT_FOR_PLAYERS	= 6'd17,
	W_LEFT			= 6'd18,
	W_RIGHT		= 6'd19,
	SCORE_LEFT		= 6'd20,
	SCORE_RIGHT		= 6'd21,
	HEIGHT_MAX		= 8'd120;

always @(posedge clk)
begin

	if ( rst == 1'b0 )
		S <= START;
	else
		S <= NS;
end

always @(*) 
begin
		case (S)
			START:
			begin
				if (drawBackground < 17'b10000000000000000)
					NS = START;
				else
					NS = MIDDLE;
			end
			MIDDLE: 
			begin
			if (drawMid < HEIGHT_MAX)
				NS = MIDDLE;
			else
				NS = PADDLE1;
			end
			PADDLE1:
			begin
				if (yPaddle < 5'b10000)
					NS = PADDLE1;
				else
					NS = PADDLE2;
			end
			PADDLE2:
			begin
				if (yPaddle < 5'b10000)
					NS = PADDLE2;
				else
					NS = IN_BALL;
			end
			IN_BALL: NS = WAIT_FOR_PLAYERS;
			WAIT_FOR_PLAYERS:
			begin
			if ( (~player1[1] || ~player1[2] )|| (~player2[2] || ~player2[1]) )
				NS = IDLE;
			else
				NS = WAIT_FOR_PLAYERS;
			end
			IDLE:
			begin
				if (frame)
					NS = DEL_PADDLE;
				else 
					NS = IDLE;
			end
			DEL_PADDLE:
			begin
				if (yPaddle < 5'b10000)
					NS = DEL_PADDLE;
				else
					NS = UPDATE_PADDLE;
			end
			UPDATE_PADDLE: NS = DRAW_PADDLE;
			DRAW_PADDLE: 
			begin
				if (yPaddle < 5'b10000 )
					NS = DRAW_PADDLE;
				else 
					NS = DEL_PADDLE2;
			end
			DEL_PADDLE2:
			begin
				if (yPaddle < 5'b10000)
					NS = DEL_PADDLE2;
				else
					NS = UPDATE_PADDLE2;
			end
			UPDATE_PADDLE2: NS = DRAW_PADDLE2;
			DRAW_PADDLE2: 
			begin
				if ( yPaddle < 5'b10000 )
					NS = DRAW_PADDLE2;
				else 
					NS = ERASE_BALL;
			end
			ERASE_BALL: NS = UPDATE_BALL;
			UPDATE_BALL:
			begin
				if (ballX <= 8'd0) 
					NS = SCORE_LEFT;
				else if (ballX >= 8'd160) 
					NS = SCORE_RIGHT;
				else
					NS = DRAW_BALL;
			end
			DRAW_BALL: NS = IDLE;
			SCORE_LEFT: 
			begin
				if ( L_score < 3)
					NS = START;
				else
					NS = GAME_OVER;
			end
			SCORE_RIGHT: 
			begin
				if ( R_score < 3)
					NS = START;
				else
					NS = GAME_OVER;
			end
			GAME_OVER: NS = GAME_OVER;
	endcase
end
	

	clock(.clock(clk), .clk(frame));
	

	
always @(posedge clk) 
begin
	border_in <= 1'b0;
	paddle_in <= 1'b0;
	ball_in <= 1'b0;
	brick_in <= 1'b0;
	colour <= 3'b101; 
	x <= 8'd0;
	y <= 8'd0;
	
	if (~rst) begin
		L_score <= 4'd0;
		R_score <= 4'd0;
		drawBackground <= 17'd0;
		yPaddle <= 8'd0;
		drawMid <= 8'd0;
	end
	case (S)
	
		START: 
		begin
			if (drawBackground < 17'b10000000000000000)
			begin
				x <= drawBackground[7:0];
				y <= drawBackground[16:8];
				drawBackground <= drawBackground + 1'b1;
			end 
			else 
			begin
				drawBackground <= 17'd0;
				yPaddle <= 8'd0;
				paddle_x2 <= 8'd150;	
				paddle_y2 <= 8'd52; 	
				paddle_x <= 8'd10;	
				paddle_y <= 8'd52; 
				ballX <= 8'd80;	
				ballY <= 8'd60; 	
			end
		end
		MIDDLE:
		begin
		if (drawMid < HEIGHT_MAX) begin
			x <= 8'd80;
			y <= drawMid;
			drawMid <= drawMid + 8'd2;
			colour <= 3'b101;
		end
		else 
			drawMid <= 8'd0;
		end
		PADDLE2: 
		begin
			if ( yPaddle < 5'b10000)
			begin
				paddle_x2 <= 8'd150;	
				paddle_y2 <= 8'd52; 	
				x <= paddle_x2;		
				y <= paddle_y2 + yPaddle[3:0];
				yPaddle <= yPaddle + 1'b1;
				colour <= 3'b001;
			end 
			else 
			begin
				yPaddle <= 8'b00000000;
			end
		end		
		PADDLE1: 
		begin
			if (yPaddle < 5'b10000)
			begin
				paddle_x <= 8'd10; 
				paddle_y <= 8'd52; 
				x <= paddle_x;		
				y <= paddle_y + yPaddle[3:0]; 
				yPaddle <= yPaddle + 1'b1;
				colour <= 3'b001;
			end 
			else 
			begin
				yPaddle <= 8'd0;
			end
		end
		
		DEL_PADDLE:
		begin
			if ( yPaddle < 5'b10000 ) 
			begin
				x <= paddle_x; 
				y <= paddle_y + yPaddle[3:0];
				yPaddle <= yPaddle + 1'b1;
			end 
			else 
			begin
				yPaddle <= 8'b00000000;
			end
		end
		
		UPDATE_PADDLE: 
		begin
			if (~player1[1] && paddle_y < -8'd152) paddle_y <= paddle_y + 2'd2; 
			if (~player1[2] && paddle_y > 8'd0) paddle_y <= paddle_y - 2'd2; 							
		end
		
		DRAW_PADDLE: 
		begin
			if (yPaddle < 5'b10000) 
			begin
				x <= paddle_x;
				y <= paddle_y + yPaddle[3:0];
				yPaddle<= yPaddle + 1'b1;
				colour <= 3'b100;
			end 
			else 
			begin
				yPaddle <= 8'd0;
			end
		end
		
			
		DEL_PADDLE2:
		begin
			if (yPaddle < 5'b10000) 
			begin
				x <= paddle_x2;
				y <= paddle_y2 + yPaddle[3:0];
				yPaddle <= yPaddle + 1'b1;
			end 
			else 
			begin
				yPaddle <= 8'b00000000;
			end
		end

		UPDATE_PADDLE2: 
		begin
			if (~player2[1] && paddle_y2 < -8'd152) 
				paddle_y2 <= paddle_y2 + 2'd2; 
			if (~player2[2] && paddle_y2 > 8'd0) 
				paddle_y2 <= paddle_y2 - 2'd2; 					
		end
		
		DRAW_PADDLE2: 
		begin
			if (yPaddle < 5'b10000) 
			begin
				x <= paddle_x2;
				y <= paddle_y2 + yPaddle[3:0];
				yPaddle <= yPaddle + 1'b1;
				colour <= 3'b100;
			end 
			else 
			begin
				yPaddle <= 8'b00000000;
			end
		end
		
		IN_BALL: 
		begin
			ballX <= 8'd80;	
			ballY <= 8'd60; 	
			x <= ballX;
			y <= ballY;
			colour <= 3'b010;
		end	
		
		UPDATE_BALL: 
		begin
			if ((ballY == 8'd0) || (ballY == -8'd136))
				ballYdir = ~ballYdir;
			if (~ballXdir)
				ballX <= ballX + 2'd1; 
			else
				ballX <= ballX - 2'd1; 
				
			if (ballYdir) 
				ballY <= ballY + 2'd1; 
			else 
				ballY <= ballY - 2'd1; 
				
			if ((ballX == 8'd0) || (ballX == 8'd160) || ((ballXdir) && (ballX > paddle_x - 8'd1) && 
			   (ballX < paddle_x + 8'd3) && (ballY >= paddle_y) && (ballY <= paddle_y + 8'd15))) 
				ballXdir <= ~ballXdir;
			
			else if (((~ballXdir) && (ballX < paddle_x2 + 8'd1) && 
			   (ballX > paddle_x2 - 8'd3) && (ballY >= paddle_y2) && (ballY <= paddle_y2 + 8'd15)))
				ballXdir <= ~ballXdir;

			

			end
			
			ERASE_BALL: 
		begin
			x <= ballX;
			y <= ballY;
			colour <= 3'b101;
		end
		
		SCORE_LEFT: L_score <= L_score + 4'd1;


		SCORE_RIGHT: R_score <= R_score + 4'd1;
		DRAW_BALL:
		begin
			x <= ballX;
			y <= ballY;
			colour <= 3'b010;
		end
		
		
		
		GAME_OVER: 
		begin
			if (drawBackground < 17'b10000000000000000)
			begin
				x <= drawBackground [7:0];
				y <= drawBackground [16:8];
				drawBackground <= drawBackground + 1'b1;
				colour <= 3'b100;
			end
		end
	endcase
	end

endmodule
	


module clock (
  input clock,
  output clk
);

reg [19:0] frames;
reg frame;

always@(posedge clock)
  begin
    if (frames == 20'b0) begin
      frames = 20'd833332; 
      frame = 1'b1;
    end 
	 
	 else 
	 begin
      frames = frames - 1'b1;
      frame = 1'b0;
    end
  end

assign clk = frame;
endmodule
