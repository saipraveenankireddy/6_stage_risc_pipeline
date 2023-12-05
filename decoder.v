module decoder(inst,reg_write_en,reg_write_add,reg_add1,reg_add2,alu_ctrl,nand_ctrl);

input [15:0] inst;
output reg [7:0] reg_write_en;
output reg [2:0] reg_add1,reg_add2,reg_write_add;
output reg [2:0] alu_ctrl,nand_ctrl;


wire [7:0] imm = inst[7:0] ;
wire [1:0] flags = inst[1:0];
wire [2:0] RA = inst[11:9];  
wire [2:0] RB = inst[8:6];
wire [2:0] RC 	= inst[5:3];
wire [3:0] opcode = inst[15:12];
wire compl = inst[2];
always@(*)
begin
	alu_ctrl = 3'bz;
	nand_ctrl = 3'bz;
	reg_write_en = 8'b00000000;
	reg_add1=3'b000;
	reg_add2=3'b000;
	case(opcode)
		4'b0000: begin 
					reg_add1 = RA; reg_write_add = RB ;reg_write_en[RB] =1'b1; 
									end 
					
		4'b0001:begin
					reg_add1 = RA;reg_add2=RB;reg_write_add = RC; reg_write_en[RC] =1'b1;
					if(compl == 0) begin 
					if(flags==2'b00)	 	alu_ctrl = 3'b000;		//ADD
					else if(flags == 2'b10) alu_ctrl = 3'b010;	//ADC
					else if(flags == 2'b01) alu_ctrl = 3'b001;	//ADZ
					else		 alu_ctrl=3'b011; //AWC			
					end
					else begin
						if(flags==2'b00) 		alu_ctrl = 3'b100;		//ACA
					else if(flags == 2'b10) alu_ctrl = 3'b110;	//ACC
					else if(flags == 2'b01) alu_ctrl = 3'b101;	//ACZ
					else alu_ctrl=3'b111; //ACW
					end
					end
		
		4'b0010: begin	
						reg_add1 = RA;reg_add2=RB;reg_write_add = RC; reg_write_en[RC] =1'b1;
		
					if(compl==0) begin
						if(flags ==2'b00) 		nand_ctrl = 3'b000;			//NDU
						else if(flags ==2'b10) nand_ctrl = 3'b010;		//NDC
						else if(flags ==2'b01) nand_ctrl = 3'b001;	//NDZ
					end 
					else begin	
						if(flags ==2'b00) nand_ctrl = 3'b100;		//NCU
						else if(flags ==2'b10) nand_ctrl = 3'b110;		//NCC
						else if(flags ==2'b01) nand_ctrl = 3'b101;	//NCZ
					end
					end
					
			4'b0011: begin  	reg_write_add =RA; end		//LLI
			4'b0100:	begin		reg_write_add = RA; reg_add1= RB; reg_write_en[RA] =1'b1; end    //LW
			4'b0101: begin		reg_add1 = RA; reg_add2 = RB;  end 		//SW
			4'b0110:	begin	   reg_add1 = RA;   end //LM AND LMF  
			4'b0111:	begin	   reg_add1 = RA	;	end  //SM and SMF
			
			4'b1000:	begin		reg_add1 = RA; reg_add2 = RB;		    end   //BEQ
			4'b1001:	begin    reg_add1 =RA; reg_add2 =RB;  end    //BLT
			
			4'b1010:begin		reg_add1 = RA; reg_add2 =RB;			end		//BLE
			
			4'b1100:begin		reg_write_add = RA;		end			//JAL
			4'b1101:begin		reg_write_add =RA;			end 		//JLR
			4'b1111:begin		reg_add1= RA;			end 			//JRL
		endcase 
end
endmodule

					