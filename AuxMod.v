//Stage2 Synchroniser
module Synchroniser(input clk,
						input wire syn_in,
						output reg	syn_out);

			reg	syn_out_temp; //give a temp syn_out to save syn_out
			//two flip flop
			always @(posedge clk) begin
					syn_out_temp <= syn_in;
					syn_out <= syn_out_temp;
			end
endmodule

//Stage2 Debouncer
module Debouncer(input clk, 
					input wire  Debouncer_in,
					output reg	Debouncer_out);
			
			reg [20:0]max = 21'd1499999;//the maximum number is 1500000
			reg [20;0]cnt = 21'd1;
			wire	synced_Deb_in;
			wire	cont;
			//Synchronise
			Synchroniser SNC(
						.clk(clk),
						.syn_in(Debouncer_in),
						.syn_out(synced_Deb_in)
						);
			assign cont = ~(synced_Deb_in ^ Debouncer_out) | (cnt == max);
			
			always @(posedge clk) begin
				if (cont == 0) begin
					cnt <= cnt + 1;
				end
				else begin
					cnt <= 21'd0;//reset cnt to 0
				end
			end
			
			always @(posedge clk) begin
				if (cnt == max) begin
					Debouncer_out <= ~Debouncer_out;
				end
			end
endmodule

//stage4 Disp2cNum(using hint)
module Disp2cNum(input signed [7:0]x,
			input enable,
			output [6:0]H3, H2, H1, H0
			);
			
			wire neg = (x < 0);
			wire [7:0]ux = neg? -x:x;
			wire [7:0] xo0, xo1, xo2, xo3;
			wire eno0, eno1, eno2, eno3;
			DispDec DisD1(.x(ux),
						.neg(neg),
						.enable(enable),
						.xo(xo0),
						.eno(eno0),
						.segs(H0)
						);

			DispDec DisD2(.x(xo0),
						.neg(neg),
						.enable(eno0),
						.xo(xo1),
						.eno(eno1),
						.segs(H1)
						);

			DispDec DisD3(.x(xo1),
						.neg(neg),
						.enable(eno1),
						.xo(xo2),
						.eno(eno2),
						.segs(H2)
						);

			DispDec DisD4(.x(xo2),
						.neg(neg),
						.enable(eno2),
						.xo(xo3),
						.eno(eno3),
						.segs(H3)
						);
endmodule

module DispDec(input [7:0] x,
			input neg, enable,
			output reg[7:0]xo,
			output reg eno,
			output [6:0] segs
			);
			wire [3:0] digit;
			wire n;
			assign digit = x % 10;
			SSeg converter(digit, n, enable, segs);
			
			always @(*) begin
				xo = x / 10;
				if (n == 0) begin
					n = neg;
				end
				else begin
					n = 0;
				end
			end

			always @(*) begin
				if (enable == 0) | (n == 1) | ((neg == 0) && (xo == 0)) begin
					eno = 0;
				end
				else begin
					eno = 1;
				end
			end
endmodule

//DispHex
module DispHex(input [7:0] x,
			input enable,
			output [6:0] H4,H5
			);
			
			wire neg = 0;
			SSeg SH4(.bin(x[3:0]),
					.neg(neg),
					.enable(enable),
					.segs(H4[6:0])
					);
			SSeg SH5(.bin(x[7:4]),
					.neg(neg),
					.enable(enable),
					.segs(H5[6:0])
					);
endmodule

//stage12 step2
module DetectFallingEdge(input clk
						input syn_in,
						output syn_out
						);
						reg prev;
						always @(posedge clk) begin
							prev <= syn_in;
						assign syn_out = prev ^ in;
						end
endmodule

// Display a Hexadecimal Digit, a Negative Sign, or a Blank, on a 7-segment Display
module SSeg(input [3:0] bin, input neg, input enable, output reg [6:0] segs);
	always @(*)
		if (enable) begin
			if (neg) segs = 7'b011_1111;
			else begin
				case (bin)
					0: segs = 7'b100_0000;
					1: segs = 7'b111_1001;
					2: segs = 7'b010_0100;
					3: segs = 7'b011_0000;
					4: segs = 7'b001_1001;
					5: segs = 7'b001_0010;
					6: segs = 7'b000_0010;
					7: segs = 7'b111_1000;
					8: segs = 7'b000_0000;
					9: segs = 7'b001_1000;
					10: segs = 7'b000_1000;
					11: segs = 7'b000_0011;
					12: segs = 7'b100_0110;
					13: segs = 7'b010_0001;
					14: segs = 7'b000_0110;
					15: segs = 7'b000_1110;
				endcase
			end
		end
		else segs = 7'b111_1111;
endmodule