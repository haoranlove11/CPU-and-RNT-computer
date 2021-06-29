`include "CPU.vh"

// CPU Module
//stage3
module CPU(input [2:0] Btns;
		input [7:0] Din;
		input Sample, Clock, Reset, Turbo;
		output reg [7:0] Dout, IP;
		output reg [5:0] GPO;
		output reg [3:0] Debug;
		output reg Dval;
		);

	//stage12 step1
	wire [7:0] din_safe;
	Synchroniser SNC0(.clk(clock),
					.syn_in(Din[0]),
					.syn_out(din_safe[0])
					);

	Synchroniser SNC1(.clk(clock),
					.syn_in(Din[1]),
					.syn_out(din_safe[1])
					);
	Synchroniser SNC2(.clk(clock),
					.syn_in(Din[2]),
					.syn_out(din_safe[2])
					);
	Synchroniser SNC3(.clk(clock),
					.syn_in(Din[3]),
					.syn_out(din_safe[3])
					);
	Synchroniser SNC4(.clk(clock),
					.syn_in(Din[4]),
					.syn_out(din_safe[4])
					);
	Synchroniser SNC5(.clk(clock),
					.syn_in(Din[5]),
					.syn_out(din_safe[5])
					);
	Synchroniser SNC6(.clk(clock),
					.syn_in(Din[6]),
					.syn_out(din_safe[6])
					);
	Synchroniser SNC7(.clk(clock),
					.syn_in(Din[7]),
					.syn_out(din_safe[7])
					);
	wire [3:0] pb_safe;
	Synchroniser SNC8(.clk(clock),
					.syn_in(Btns[0]),
					.syn_out(pb_safe[0])
					);
	Synchroniser SNC9(.clk(clock),
					.syn_in(Btns[1]),
					.syn_out(pb_safe[1])
					);
	Synchroniser SNC10(.clk(clock),
					.syn_in(Btns[2]),
					.syn_out(pb_safe[2])
					);
	Synchroniser SN11(.clk(clock),
					.syn_in(Btns[3]),
					.syn_out(pb_safe[3])
					);

	//stage12 step3
	genvar i;
	wire [3:0] pb_activated; 
	generate
		for(i=0; i<=3; i=i+1) begin :pb
			DetectFallingEdge dfe(Clock, pb_safe[i], pb_activated[i]);
		end 
	endgenerate
	//stage5 step1
	//clock circuitry(250 ms cycle)
	reg [24:0] cnt;
	localparam CntMax = 25'd12499999;

	always @(posedge) begin
		cnt <= (cnt == CntMax) ? 0:cnt + 1;
	end

	//stage6
	//Synchronise CPU operations when cnt == 0
	wire turbo_safe;
	Synchroniser tbo(Clock, Turbo, turbo_safe);
	wire go =! Reset && ((cnt == 0) || turbo_safe);

	//Program Memory
	wire [34;0] instruction;
	AsyncROM Pmem (IP, instruction);
	//stage5 step3
	//registers
	reg[7:0] Reg [0:31];

	//use these to read the special registers
	wire [7:0] Rgout = Reg[29];
	wire [7:0] Rdout = Reg[30];
	wire [7:0] Rflag = Reg[31];

	//define RFLAG Reg and Din registers
	`define RFLAG Reg[31]
	`define RDINP Reg[28]

	//Connect certain registers to the external world
	assign Dout = Rdout;
	assign GPO = Rgout[5:0];
	assign Dval = Rgout[`Dval];

	assign debug[3] = Rflag[`SHFT];
	assign debug[2] = Rflag[`OFLW];
	assign debug[1] = Rflag[`SMPL];
	assign debug[0] = go;

	function [34:0] set_bit;
			input [7:0] reg_num;
			input [2:0] bit;
			set_bit = {`ACC, `OR, `REG, reg_num, `NUM, 8'b1 << bit, `N8}; 
	endfunction

	function [34:0] clr_bit;
			input [7:0] reg_num;
			input [2:0] bit;
			clr_bit = {`ACC, `AND, `REG, reg_num, `NUM, ~(8'b1 << bit), `N8}; 
	endfunction
	// Instruction Cycle
	wire [3:0] cmd_grp = instruction[34:31];
	wire [2:0] cmd = instruction[30:28];
	wire [1:0] arg1_typ = instruction[27:26];
	wire [7:0] arg1 = instruction[25:18];
	wire [1:0] arg2_typ = instruction[17:16];
	wire [7:0] arg2 = instruction[15:8];
	wire [7:0] addr = instruction[7:0];

	//stage12 step3
	if (Reset) begin
			IP <= 8'b0;
			`RFLAG <= 0;
	end
	else begin
		for(j=0; j<=3; j=j+1)
			if (pb_activated[j]) `RFLAG[j] <= 1;
		if (pb_activated[3]) `RDINP <= din_safe; 
	end

	//stage7 get number
	function [7:0] get_number;
		input [1:0] arg_type;
		input [7:0] arg;
		begin
			case (arg_type)
				`REG: get_number = Reg[arg[4:0]];
				`IND: get_number = Reg[ Reg[arg[4:0]][4:0] ];
				default: get_number = arg;
			endcase
		end
	endfunction

	//stage7 get location
	function [5:0] get_location;
		input [1:0] arg_type;
		input [7:0] arg;
		begin
			case (arg_type)
				`REG: get_location = arg[4:0];
				`IND: get_location = Reg[arg[4:0]][4:0];
				default: get_location = 0;
			endcase
		end
	endfunction

	reg [7:0] cnum;
	reg [7:0] cloc;
	reg [15:0] word;
	reg signed [15:0]s_word;
	reg cond;

	//stage7
	always @(posedge clock) begin
		if (go) begin
			IP <= IP + 8'b1;
			case(cmd_grp)
				`MOV:begin
					cnum = get_number(arg1_typ, arg1);
					case (cmd)
						`SHL: begin
								`RFLAG[`SHFT] <= cnum[7];
								cnum = {cnum[6:0], 1'b0};
						end
						`SHR: begin
								`RFLAG[`SHFT] <= cnum[0];
								cnum = {1'b0, cnum[7:1]};
						end
					endcase
					Reg[ get_location(arg2_typ, arg2) ] <= cnum;
				end
				//stage8
				`ACC: begin
		   			cnum = get_number(arg2_typ, arg2);
					cloc = get_location(arg1_typ, arg1);
					case (cmd)
						`UAD: word = Reg[ cloc ] + cnum;
						`SAD: s_word = $signed( Reg[ cloc ] ) + $signed( cnum );
						`UMT: word = Reg[ cloc ] * cnum;
						`SMT: s_word =  $signed( Reg[ cloc ] ) * $signed( cnum );
						`AND: cnum = Reg[ cloc ] & cnum;
						`OR: cnum = Reg[ cloc ] | cnum;
						`XOR: cnum =Reg[ cloc ] ^ cnum;
					endcase
					if (cmd[2] == 0)
							if (cmd[0] == 0) begin 	
									cnum = word[7:0];
									`RFLAG[`OFLW] <= (word > 255);
							end
							else begin 
									cnum = s_word[7:0];
									`RFLAG[`OFLW] <= ($signed(s_word) > 127 || $signed(s_word)< -128);
							end
					Reg[ cloc ] <= cnum; 
				end
				//stage9
				`JMP: begin
					case (cmd)
						`UNC: cond = 1;//unconditional jump
						`EQ: cond = (get_number(arg1_typ, arg1) == get_number(arg2_typ, arg2) );
						`ULT: cond = (get_number(arg1_typ, arg1) < get_number(arg2_typ, arg2) );
						`SLT: cond = ($signed(get_number(arg1_typ, arg1)) < $signed(get_number(arg2_typ, arg2)) );
						`ULE: cond = (get_number(arg1_typ, arg1) <= get_number(arg2_typ, arg2) );
						`SLE: cond = ($signed(get_number(arg1_typ, arg1)) <= $signed(get_number(arg2_typ, arg2)) );
			   		default: cond = 0;
					endcase
					if (cond) IP  <= addr;
				end
				//stage 10
				`ATC: begin
	   				if (`RFLAG[cmd]) IP <= addr;
						`RFLAG[cmd] <= 0;
				end
			endcase
		end
	end
endmodule

