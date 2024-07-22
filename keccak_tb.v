`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.07.2024 17:25:03
// Design Name: 
// Module Name: keccak_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module keccak_tb_tb;

    reg [63:0] din;
    reg clk;
    reg Reset;
    wire [223:0] Hash;

    // Instantiate the Keccak module
    Keccak dut(
        .din(din),
        .clk(clk),
        .Reset(Reset),
        .Hash(Hash)
    );

    integer file;

    initial begin
        clk = 1;
        #5
        Reset = 1;
        #15
        Reset = 0;
        din = "sahil";
        file = $fopen("dout.txt", "w");
    end 

    always #5 clk = ~clk;

    always @ (posedge clk) begin
        if (~Reset) begin
            // Write reg_data to the file when not in reset
            // Assuming reg_data is defined in the Keccak module and is 1600 bits wide
            $fwrite(file, "%b\n", dut.dout);
        end
    end

    // Close the file when the simulation ends
    initial begin
        #1004; // Adjust the simulation time as needed
//        $fclose(file);
////        $stop;
    end

endmodule

