module FPU(clk, A, B, opcode, O,flags);

	input clk;
	input [31:0] A, B;
	input [1:0] opcode;
	output [31:0] O;
	output [6:0] flags;
	
	wire [31:0] O;
	wire [7:0] a_exponent;
	wire [23:0] a_mantissa;
	wire [7:0] b_exponent;
	wire [23:0] b_mantissa;

	reg        o_sign;
	reg [7:0]  o_exponent;
	reg [24:0] o_mantissa;


	reg [31:0] adder_a_in;
	reg [31:0] adder_b_in;
	wire [31:0] adder_out;

	reg [31:0] multiplier_a_in;
	reg [31:0] multiplier_b_in;
	wire [31:0] multiplier_out;
	
	reg Z,S,NaN_A,NaN_B,inf_A,inf_B,NOP;

	assign O[31] = o_sign;
	assign O[30:23] = o_exponent;
	assign O[22:0] = o_mantissa[22:0];

	assign a_sign = A[31];
	assign a_exponent[7:0] = A[30:23];
	assign a_mantissa[23:0] = {1'b1, A[22:0]};

	assign b_sign = B[31];
	assign b_exponent[7:0] = B[30:23];
	assign b_mantissa[23:0] = {1'b1, B[22:0]};
	
	assign flags[0]=inf_B;
	assign flags[1]=inf_A;

	assign flags[2]=NaN_B;
	assign flags[3]=NaN_A;
	assign flags[4]=S;
	assign flags[5]=Z;
	assign flags[6]=NOP;
	
	adder A1
	(
		.a(adder_a_in),
		.b(adder_b_in),
		.out(adder_out)
	);
	multiplier M1
	(
		.a(multiplier_a_in),
		.b(multiplier_b_in),
		.out(multiplier_out)
	);


	always @ (*)
	begin
		if (opcode[1]==0 && opcode[0]==0) 
		begin
			NOP=0;
			//If a is NaN or b is zero return a
			if ((a_exponent == 255 && a_mantissa != 0) || (b_exponent == 0) && (b_mantissa == 0)) 
				begin
					o_sign = a_sign;
					o_exponent = a_exponent;
					o_mantissa = a_mantissa;
				//If b is NaN or a is zero return b
				end 
			else if ((b_exponent == 255 && b_mantissa != 0) || (a_exponent == 0) && (a_mantissa == 0)) 
				begin
					o_sign = b_sign;
					o_exponent = b_exponent;
					o_mantissa = b_mantissa;
				//if a or b is inf return inf
				end 
			else if ((a_exponent == 255) || (b_exponent == 255)) 
				begin
					o_sign = a_sign ^ b_sign;

					o_exponent = 255;
					o_mantissa = 0;
				end 
			else 
				begin // Passed all corner cases

					adder_a_in = A;
					adder_b_in = B;
					o_sign = adder_out[31];
					o_exponent = adder_out[30:23];
					o_mantissa = adder_out[22:0];
				end
		end

		else if (opcode[1]==0 && opcode[0]==1) 
		begin
			NOP=0;
			//If a is NaN or b is zero return a
			if(A==B)
				begin
					o_exponent=0;
					o_mantissa[22:0]=0;
					o_sign=0;
				end
			else
			begin
			if ((a_exponent == 255 && a_mantissa != 0) || (b_exponent == 0) && (b_mantissa == 0)) 
				begin
					o_sign = a_sign;
					o_exponent = a_exponent;
					o_mantissa = a_mantissa;
				//If b is NaN or a is zero return b
				end 
			else if ((b_exponent == 255 && b_mantissa != 0) || (a_exponent == 0) && (a_mantissa == 0)) 
				begin
					o_sign = b_sign;
					o_exponent = b_exponent;
					o_mantissa = b_mantissa;
				//if a or b is inf return inf
				end 
			else if ((a_exponent == 255) || (b_exponent == 255)) 
				begin
					o_sign = a_sign ^ b_sign;
					o_exponent = 255;
					o_mantissa = 0;
				end 
			else 
				begin // Passed all corner cases
					adder_a_in = A;

					adder_b_in = {~B[31], B[30:0]};
					o_sign = adder_out[31];
					o_exponent = adder_out[30:23];
					o_mantissa = adder_out[22:0];
				end
		end
		end

		else if(opcode[1]==1 && opcode[0]==0) 
		begin //Multiplication
			NOP=0;
			//If a is NaN return NaN
			if (a_exponent == 255 && a_mantissa != 0) 
				begin
					o_sign = a_sign;
					o_exponent = 255;
					o_mantissa = a_mantissa;
				//If b is NaN return NaN
				end 
			else if (b_exponent == 255 && b_mantissa != 0) 
				begin
					o_sign = b_sign;
					o_exponent = 255;
					o_mantissa = b_mantissa;
				//If a or b is 0 return 0
				end 
			else if ((a_exponent == 0) && (a_mantissa == 0) || (b_exponent == 0) && (b_mantissa == 0)) 
				begin
					o_sign = a_sign ^ b_sign;
					o_exponent = 0;
					o_mantissa = 0;
				//if a or b is inf return inf
				end 
			else if ((a_exponent == 255) || (b_exponent == 255)) 
				begin
					o_sign = a_sign;
					o_exponent = 255;
					o_mantissa = 0;

				end 
			else 
				begin // Passed all corner cases
					multiplier_a_in = A;
					multiplier_b_in = B;
					o_sign = multiplier_out[31];
					o_exponent = multiplier_out[30:23];
					o_mantissa = multiplier_out[22:0];
				end
		end
		else if(opcode[0]==1 && opcode[1]==1)
			begin
				NOP=1;
			end
	end
	always@(posedge clk)
	begin
		if(a_exponent == 255 && a_mantissa[22:0] != 0)
			NaN_A=1;
		else 
			NaN_A=0;
		if(b_exponent == 255 && b_mantissa[22:0] != 0)
			NaN_B=1;
		else
			NaN_B=0;
		if(b_exponent == 255 && b_mantissa[22:0] == 0)
			inf_B=1;
		else
			inf_B=0;
		if(a_exponent == 255 && a_mantissa[22:0] == 0)
			inf_A=1;
		else
			inf_A=0;
		if(o_sign==1)
			S=1;
		else
			S=0;
		if(o_exponent==8'b0 && o_mantissa[22:0]==0)
			Z=1;
		else
			Z=0;	
	end
endmodule