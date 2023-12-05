`timescale 1 ns/1 ps
module tb();

reg clk = 1'b0;

always #1 clk = ~ clk;

main dut (clk);

endmodule 



