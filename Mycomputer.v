//top level
module MyComputer(
			input CLOCK_50,
			input [3:0] KEY,
			input [9:0] SW,
			
			output [9:0] LEDR,
			output [6:0] HEX0,
			output [6:0] HEX1,
			output [6:0] HEX2,
			output [6:0] HEX3,
			output [6:0] HEX4,
			output [6:0] HEX5
			);
			
			wire Reset, eno;
			wire [7:0] IP;
			wire [7:0] Dout;
			
			//connect debouncer
			Debouncer DB(.clk(CLOCK_50),
							.Debouncer_in(SW[9]),
							.Debouncer_out(Reset)
							);
			
			//Display connect
			Disp2cNum Dis(.x(Dout),
							.enable(eno),
							.H0(HEX0),
							.H1(HEX1),
							.H2(HEX2),
							.H3(HEX3)
							);
			
			DispHex DH(.x(IP),
						.enable(eno),
						.H4(HEX4),
						.H5(HEX5)
						);
			
			//CPU
			CPU CP(.Din(SW[7:0],
					.sample(~KEY[3]),
					.Clock(CLOCK_50),
					.Reset(Reset),
					.Turbo(SW[8]),
					.Btns(～KEY[2:0]),
					.Dout(Dout),
					.IP(IP),
					.GPO(LEDR[5:0]),
					.Debug(LEDR[9;6]),
					.Dval(eno)
					);
	
	endmodule