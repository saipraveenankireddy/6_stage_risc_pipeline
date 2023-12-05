module main(clk);
input clk;

reg [15:0] PC=16'd0;
reg  [15:0] inst;
wire [7:0] reg_write_en;
wire [2:0] reg_write_add;
wire [2:0] reg_add1,reg_add2,alu_ctrl,nand_ctrl;
reg [15:0] reg_data1,reg_data2;
reg [15:0] reg_write_data;
wire [15:0] data_out;

reg [31:0] ifid;
reg [78:0] idreg;
reg [104:0] regex;
reg [146:0] exmem;
reg [146:0] memwb;

reg if_tak=0;
reg id_tak=0;
reg reg_tak=0;
reg ex_tak=0;
reg mem_tak=0;
reg wb_tak=0;
reg new_i=1'b0;
reg cond =1'b0;


reg [15:0] mem_data;
reg cout=1'b0;
reg zout=1'b0;


wire [15:0] mem_add;



reg [15:0] instr_mem [0:511];
reg [15:0] reg_file [0:7];
reg [15:0] data_mem [0:511];
reg [15:0] reg_file1 [0:7];


initial begin
  $readmemh("m1.hex", instr_mem);
end

initial begin
	 $readmemh("data.hex", reg_file);
end
initial begin
	$readmemh("data.hex",data_mem);
end



//---------------------------INSTRUCION FETCH UNIT-----------------------------//
always@(posedge clk)
begin
	if((regex[15:12] == 4'b1001 && cond==1) || (regex[15:12] == 4'b1010 &&  cond==1) || (regex[15:12] == 4'b1000 && cond==1))
    begin
	 PC  <= regex[31:16] + ( ({regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5:0]} )) * 2 -16'd1
	 ;
	 inst <= instr_mem[PC];
	 new_i<=0;
	 end

	 else begin
	
	inst <= instr_mem[PC];
	PC <= PC+16'd1;
	new_i<=1'b0;
	end
end



always@(posedge clk)
begin
	if((regex[15:12] == 4'b1001 && cond==1) || (regex[15:12] == 4'b1010 &&  cond==1) ||(regex[15:12] == 4'b1000 && cond==1))
	if_tak<=1;
	else
	if_tak<=new_i;
	ifid[31:16] <= PC;
	ifid[15:0] <= inst;
end

//----------------------DECODER UNIT---------------------------------//

decoder dec1 (ifid[15:0],reg_write_en,reg_write_add,reg_add1,reg_add2,alu_ctrl,nand_ctrl);

always@(posedge clk)
begin	
		if((regex[15:12] == 4'b1001 && cond==1) || (regex[15:12] == 4'b1010 &&  cond==1) ||(regex[15:12] == 4'b1000 && cond==1))
		id_tak<=1;
		else
		id_tak<=if_tak;
		idreg[54:52] <= nand_ctrl;
		idreg[51:49] <= alu_ctrl;
		idreg[48:46] <= reg_write_add;
		idreg[45:43] <= reg_add2;
		idreg[42:40] <= reg_add1;
		idreg[39:32] <= reg_write_en;
		idreg[31:0] <= ifid;
			
end


//----------------------REGISTER READ UNIT------------------------//

always@(*) begin
	if(exmem[48:46] == idreg[42:40]  ) begin
		reg_data1 = exmem[102:87] ; 
		reg_data2 = reg_file[idreg[45:43]]; end 
	
	else if(memwb[48:46] == idreg[42:40] ) begin
			reg_data1 = memwb[102:87];
			reg_data2 = reg_file[idreg[45:43]]; end
	
	else if (exmem[48:46] == idreg[45:43] ) begin
			reg_data2 = exmem[102:87] ;
			reg_data1 = reg_file[idreg[42:40]]; end
	
	else if(memwb[48:46] == idreg[45:43] ) begin
			reg_data2 = memwb[102:87] ;
			reg_data1 = reg_file[idreg[42:40]]; end
	
	else if(regex[48:46] == idreg[45:43]) begin
			reg_data2 = reg_write_data;
			reg_data1 = reg_file[idreg[42:40]]; end
	
	else if(regex[48:46] == idreg[42:40]) begin
			reg_data1 = reg_write_data;
			reg_data2 = reg_file[idreg[45:43]]; end
	else begin
			reg_data1 = reg_file[idreg[42:40]];
			reg_data2 = reg_file[idreg[45:43]]; end
end
		
 


always@(posedge clk)
begin
		if((regex[15:12] == 4'b1001 && cond==1) || (regex[15:12] == 4'b1010 &&  cond==1) ||(regex[15:12] == 4'b1000 && cond==1))
reg_tak<=1;
else
	reg_tak<=id_tak;
	regex[70:55] = reg_data1;
	regex[86:71] = reg_data2; 
	regex[54:0] <= idreg;
end
//-----------------------------------EXECUTION UNIT----------------------//


wire [15:0] inp_bar = ~ reg_data2;

always@(*) begin

cond =1'b0;
	if(regex[15:12] == 4'b0000)	begin				//ADI
		{cout,reg_write_data} = regex[70:55] + {regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5:0]};
			end
	else if(regex[15:12] == 4'b0001)	begin					//ADD
	case(regex[51:49])  
				3'b000:begin	{cout,reg_write_data} = regex[70:55] + regex[86:71]; end
				3'b001:begin	if(exmem[103]) {cout,reg_write_data}= regex[70:55] + regex[86:71]; else reg_write_data = 16'd0; 	end
				3'b010:begin	if(exmem[104]) {cout,reg_write_data} = regex[70:55] + regex[86:71]; else reg_write_data =16'd0; 	end
				3'b011:begin 	{cout,reg_write_data} = regex[70:55] + regex[86:71] + cout;	end
				
				3'b100:begin	{cout,reg_write_data} = regex[70:55] + inp_bar; end
				3'b101:begin	 if(exmem[104]) {cout,reg_write_data} = regex[70:55] + inp_bar; else reg_write_data = 16'd0;  end
				3'b110:begin  if (exmem[103]) {cout,reg_write_data} = regex[70:55] + inp_bar; else reg_write_data=16'd0;  end
				3'b111:begin	{cout,reg_write_data} = regex[70:55] + inp_bar+ cout; end
	endcase
	end
	else if(regex[15:12] == 4'b0010) begin   //NAND
	case(regex[54:52])
			
			3'b000: begin	reg_write_data = ~(regex[70:55] & regex[86:71]); end
			3'b001:begin	 if(exmem[103]) reg_write_data = ~(regex[70:55] & regex[86:71]); else reg_write_data =16'd0; end
			3'b010:begin	 if(exmem[104]) reg_write_data = ~(regex[70:55] & regex[86:71] ); else reg_write_data =16'd0; end
			3'b100:begin	reg_write_data = ~(regex[70:55] & inp_bar) ; end
			3'b110: begin	if(exmem[103]) reg_write_data =~(regex[70:55]  & inp_bar) ; else reg_write_data =16'd0; end
			3'b101: begin	 if(exmem[104]) reg_write_data = ~(regex[70:55] & inp_bar) ; else reg_write_data =16'd0; end
		endcase
		end
	else if(regex[15:12] == 4'b0011) begin		//LLI
			reg_write_data = {7'b0,regex[8:0]};
		end
	else if(regex[15:12] ==  4'b0100) begin	 //LW
			reg_write_data =  regex[70:55] + {regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5:0]};
			end
	
	else if(regex[15:12] == 4'b0101) begin  //SW
			reg_write_data = regex[86:71] + {regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5],regex[5:0]};
	end
	else if(regex[15:12] == 4'b1000) begin
		if(regex[70:55] == regex[86:71]) begin		cond = 1'b1; //BEQ;
		end
	
		end
	else if(regex[15:12] == 4'b1001) begin
			if(regex[70:55] < regex[86:71])
			begin
			cond = 1'b1;												//BLT	
			end
			
		end
	else if(regex[15:12] == 4'b1001) begin
			if(regex[70:55] <= regex[86:71]) begin
			cond =1'b1;													 //BLE
			end
	else if(regex[15:12] == 4'b1100) begin						//JAL
			cond =1'b1;
			reg_write_data = regex[31:16] +16'd1;
			end
	else if(regex[15:12] == 4'b1101) begin						//JLR
			cond = 1'b1;
			reg_write_data = regex[31:16] +16'd1;
			end
	else if(regex[15:12] ==4'b1111) begin 						//JRI
			cond =1'b1;
			end
			
			
			
end
end



assign data_out = reg_write_data;

always@(posedge clk)
begin
		ex_tak<=reg_tak;
		exmem[104] <= zout;
		exmem[103] <= cout;
		exmem[102:87] <= data_out;
		exmem[86:0] <= regex;
end

//----------------MEMORY WRITE BACK UNIT --------- //
always@(*) begin
if(ex_tak==1'b0)
	begin
	if(exmem[15:12] == 4'b0101) 	
			data_mem[exmem[102:87]] = exmem[70:55];
	else if(exmem[15:12] == 4'b0100) 
				mem_data =data_mem[exmem[102:87]];
	else if(exmem[15:12] == 4'b0110) begin
			if(exmem[9])	begin
				if(exmem[7]) reg_file1[0] <= data_mem[exmem[70:55]];
				if(exmem[6]) reg_file1[1] <= data_mem[exmem[70:55] + 16'd1];
				if(exmem[5]) reg_file1[2] <= data_mem[exmem[70:55] + 16'd2];
				if(exmem[4]) reg_file1[3] <= data_mem[exmem[70:55] + 16'd3];
				if(exmem[3]) reg_file1[4] <= data_mem[exmem[70:55] + 16'd4];
				if(exmem[2]) reg_file1[5] <= data_mem[exmem[70:55] + 16'd5];
				if(exmem[1]) reg_file1[6] <= data_mem[exmem[70:55] + 16'd6];
				if(exmem[0]) reg_file1[7] <= data_mem[exmem[70:55] + 16'd7];
		end
		else		begin
				if(exmem[7]) reg_file1[0] <= data_mem[exmem[70:55]];
				if(exmem[6]) reg_file1[1] <= data_mem[exmem[70:55]	+ 16'd1];
				if(exmem[5]) reg_file1[2] <= data_mem[exmem[70:55] + 16'd2];
				if(exmem[4]) reg_file1[3] <= data_mem[exmem[70:55] + 16'd3];
				if(exmem[3]) reg_file1[4] <= data_mem[exmem[70:55]	+ 16'd4];
				if(exmem[2]) reg_file1[5] <= data_mem[exmem[70:55] + 16'd5];
				if(exmem[1]) reg_file1[6] <= data_mem[exmem[70:55] + 16'd6];
				if(exmem[0]) reg_file1[7] <= data_mem[exmem[70:55] + 16'd7];
				
			end
end
		
		
	else if(exmem[15:12] == 4'b0111) begin
			if(exmem[8]) begin
			if(exmem[7])	data_mem[exmem[70:55]] <=  reg_file[0]; 
			if(exmem[6])	data_mem[exmem[70:55]+16'd1] <= reg_file[1]; 
			if(exmem[5])	data_mem[exmem[70:55] +16'd2] <= reg_file[2]; 
			if(exmem[4])	data_mem[exmem[70:55]+16'd3] <= reg_file[3]; 
			if(exmem[3])	data_mem[exmem[70:55]+16'd4] <= reg_file[4]; 
			if(exmem[2])	data_mem[exmem[70:55]+16'd5] <= reg_file[5]; 
			if(exmem[1])	data_mem[exmem[70:55]+16'd6] <= reg_file[6]; 
			if(exmem[0])	data_mem[exmem[70:55]+16'd7] <= reg_file[7]; 
		end
		else		begin
			if(exmem[7])	data_mem[exmem[70:55]] <=  reg_file[0]; 
			if(exmem[6])	data_mem[exmem[70:55]+16'd1] <= reg_file[1]; 
			if(exmem[5])	data_mem[exmem[70:55] + 16'd2] <= reg_file[2]; 
			if(exmem[4])	data_mem[exmem[70:55]+16'd3] <= reg_file[3]; 
			if(exmem[3])	data_mem[exmem[70:55]+16'd4] <= reg_file[4]; 
			if(exmem[2])	data_mem[exmem[70:55]+16'd5] <= reg_file[5]; 
			if(exmem[1])	data_mem[exmem[70:55]+16'd6] <= reg_file[6]; 
			if(exmem[0])	data_mem[exmem[70:55]+16'd7] <= reg_file[7]; 
		end
		
end
end
end



always@(posedge clk)
begin
	mem_tak<=ex_tak;
	memwb[118:103] <= mem_data;
	memwb[102:0] <= exmem;
	
end




reg [7:0] reg_write_enable ;

// -------REGISTER WRITE UNIT --------//
always@(*)
begin
if(mem_tak==1'b0)
begin
reg_write_enable = memwb[39:32];
reg_file[0] = memwb[31:16];	
	if(memwb[15:12] == 4'b0000 || memwb[15:12] == 4'b0001 || memwb[15:12] == 4'b0010 ) begin  	 //ADI
				if(reg_write_enable[memwb[48:46]])
				reg_file[memwb[48:46]] = memwb[102:87];
		end
		else if(memwb[15:12] == 4'b0011) begin											//LLI
				if(reg_write_enable[memwb[48:46]])
				reg_file[memwb[48:46]] = memwb[102:87];
			end	
		else if(memwb[15:12] == 4'b0100)   	
					if(reg_write_enable[memwb[48:46]]) 									//LW 
							reg_file[memwb[48:46]] = memwb[118:103];
					
		else if(memwb[15:12] == 4'b0110) begin  										//LM ,LMF
			if(memwb[9])	begin
				if(memwb[7]) reg_file[0] <= reg_file1[0];
				if(memwb[6]) reg_file[1] <= reg_file1[1];
				if(memwb[5]) reg_file[2] <= reg_file1[2];
				if(memwb[4]) reg_file[3] <= reg_file1[3];
				if(memwb[3]) reg_file[4] <= reg_file1[4];
				if(memwb[2]) reg_file[5] <= reg_file1[5];
				if(memwb[1]) reg_file[6] <= reg_file1[6];
				if(memwb[0]) reg_file[7] <= reg_file1[7];
			end
			else		begin
				if(memwb[7]) reg_file[0] <= reg_file1[0];
				if(memwb[6]) reg_file[1] <= reg_file1[1];
				if(memwb[5]) reg_file[2] <= reg_file1[2];
				if(memwb[4]) reg_file[3] <= reg_file1[3];
				if(memwb[3]) reg_file[4] <= reg_file1[4];
				if(memwb[2]) reg_file[5] <= reg_file1[5];
				if(memwb[1]) reg_file[6] <= reg_file1[6];
				if(memwb[0]) reg_file[7] <= reg_file1[7];
				
			end
			
end
end
end
endmodule
