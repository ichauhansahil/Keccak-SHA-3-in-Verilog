`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2024 21:08:23
// Design Name: 
// Module Name: Theta
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


module Keccak #(parameter integer N = 224,
                parameter integer C = 2 * N,
                parameter integer r = 1600 - C)
                (
input [63:0]din,

input clk,
input   Reset,
output reg [N-1:0]Hash
    );
    
reg reset;
reg[0:1599]reg_data;
reg[1599:0]dout;
reg permutation_started;
reg  [63:0]d_register[4:0][4:0];
reg  [63:0]xor_register[4:0][4:0];
reg  [63:0]round_in[4:0][4:0];
wire [63:0]theta_in[4:0][4:0];
wire [63:0]theta_out[4:0][4:0];
wire [63:0]rho_in[4:0][4:0];
wire [63:0]rho_out[4:0][4:0];
wire [63:0]pi_in[4:0][4:0];
wire [63:0]pi_out[4:0][4:0];
wire [63:0]chi_in[4:0][4:0];
wire [63:0]chi_out[4:0][4:0];
wire [63:0]iota_in[4:0][4:0];
wire [63:0]iota_out[4:0][4:0];

wire [63:0]round_constant_signal;
reg [4:0]counter_nr_rounds;
wire sum_sheet[4:0][63:0];
reg [4:0]cycle_count;
reg [7:0]u;
reg [6:0]v;
reg [6:0]w;
reg [6:0]row;
reg [6:0]col;
wire [0:r]padded_data;
wire din_length;
wire  num_zeros;

always @ (posedge clk)  
begin 
     reset=Reset;
end



//padding module{
//  assign padded_data = 1152'h4E8616AE3660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001;
  
  assign padded_data = 1152'hCE8616963660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001;



always @(posedge clk or posedge reset) begin
    if (reset) begin
        reg_data <= 1600'b0;
    end else begin
        reg_data <= {padded_data, 448'b0}; // Align padded_data within reg_data
    end
end

always @(posedge clk) begin
    if (reset) begin 
        cycle_count <= 2'b0;
    end else begin
        if (cycle_count == 2'b11) begin
            cycle_count <= 2'b00;  // Reset to 1 when cycle_count is 3
        end else begin
        if (permutation_started)
            cycle_count <= cycle_count + 1;
        end
    end
end

//for the round constant
always @ (posedge clk) begin
    if (reset) begin
         counter_nr_rounds<=0;
    end
if (cycle_count==3) begin 
counter_nr_rounds<=1;
counter_nr_rounds<=counter_nr_rounds+1;
    end else begin
        if (counter_nr_rounds == 5'b11001) begin
        counter_nr_rounds<=0;
        reset<=1;
        permutation_started<=0;
        cycle_count<=0;
      
    end
end end 

//permutation Started

always @ (posedge clk) begin
if (~reset && (cycle_count==0) && (counter_nr_rounds == 0)) begin
permutation_started<=1;
end else begin 
if (counter_nr_rounds == 5'b11000) begin
permutation_started<=0;
end end 
end 





//round

always @ (posedge clk) begin
if (~reset && (cycle_count==3)) begin
    for (u = 0; u < 5; u = u + 1) begin
    for (v = 0; v < 5; v = v + 1) begin
    for (w = 0; w < 64; w = w + 1) begin
    xor_register[u][v][w] <= iota_out[u][v][w];
    end end end end 
   
end

//reset and looop for 24 round
always @ (posedge clk or negedge reset) 
begin
    if (reset) begin
        for (u = 0; u < 5; u = u + 1) begin
        for (v = 0; v < 5; v = v + 1) begin
        for (w = 0; w < 64; w = w + 1) begin
        d_register[u][v][w] <= 0;
        end end end end

end 
 
round_constants sexy(
    .round_number(counter_nr_rounds),
    .round_constant_signal_out(round_constant_signal));

            
// Rate Part
always @ (posedge clk)
begin
    if (~reset && (counter_nr_rounds == 0) && (cycle_count==0)) begin
        // Assign round_in for col 0 and 1
        for (row = 0; row <= 3; row = row + 1) begin : sa5
        for (col = 0; col <= 1; col = col + 1) begin : sa4
           
                for (u = 0; u <= 63; u = u + 1) begin : sa6
                    round_in[col][row][u] <= reg_data[(col*64*5) + (row*64) + u];
                end
            end
        end
        
        // Assign round_in for col 0, row 4 (special case)
        for (u = 0; u <= 63; u = u + 1) begin : sa6_special
            round_in[0][4][u] <= reg_data[(0*64*5) + (4*64) + u];
        end
    end
end

// Capacity Part
always @ (posedge clk)
begin
    if (~reset && (counter_nr_rounds == 0) && (cycle_count==0)) begin
        // Assign round_in for col 2, 3, 4
         for (row = 0; row <= 4; row = row + 1) begin : sa8
        for (col = 2; col <= 4; col = col + 1) begin : sa7
           
                for (u = 0; u <= 63; u = u + 1) begin : sa9
                    round_in[col][row][u] <= reg_data[(col*64*5) + (row*64) + u];
                end
            end
        end
        
        // Special case for round_in[4][1]
        for (u = 0; u <= 63; u = u + 1) begin : sa9_special
            round_in[1][4][u] <= reg_data[(1*64*5) + (4*64) + u];
        end
    end
end


// xor_register

//// r=512
//always @ (posedge clk)
//begin
//    if (~reset && (counter_nr_rounds == 0)) begin
//        // Compute xor_register for col 0 and 1, rows 0 to 3
        
//            for (u = 0; u <= 63; u = u + 1) begin : sa1
//                for (row = 0; row <= 3; row = row + 1) begin : sa2
//                    xor_register[row][0][u] <= round_in[row][0][u] ^ d_register[row][0][u];
//                     xor_register[row][1][u] <= round_in[row][1][u] ^ d_register[row][1][u];
             
//            end
//        end
        
//        // Compute xor_register for col 0, row 4 (special case)
//        for (u = 0; u <= 63; u = u + 1) begin : sa1_special
//            xor_register[4][0][u] <= round_in[4][0][u] ^ d_register[4][0][u];
//        end
        
//        // Copy round_in to xor_register for col 2, 3, 4, all rows
//        for (col = 2; col <= 4; col = col + 1) begin : sa3
//            for (row = 0; row <= 4; row = row + 1) begin : sa4
//                for (u = 0; u <= 63; u = u + 1) begin : sa5
//                    xor_register[row][col][u] <= round_in[row][col][u];
//                end
//            end
//        end
        
//        // Compute xor_register for col 1, row 4 (special case)
//        for (u = 0; u <= 63; u = u + 1) begin : sa1_special_1
//            xor_register[4][1][u] <= round_in[4][1][u];
//        end
//    end
//end

// xor_register
always @ (posedge clk)
begin
    if (~reset && (counter_nr_rounds == 0)) begin
        case (N)
            512: begin
                // Compute xor_register for col 0 and 1, rows 0 to 3
                for (u = 0; u <= 63; u = u + 1) begin : sa1
                    for (row = 0; row <= 3; row = row + 1) begin : sa2
                        xor_register[row][0][u] <= round_in[row][0][u] ^ d_register[row][0][u];
                        xor_register[row][1][u] <= round_in[row][1][u] ^ d_register[row][1][u];
                    end
                end
                
                // Compute xor_register for col 0, row 4 (special case)
                for (u = 0; u <= 63; u = u + 1) begin : sa1_special
                    xor_register[4][0][u] <= round_in[4][0][u] ^ d_register[4][0][u];
                end
                
                // Copy round_in to xor_register for col 2, 3, 4, all rows
                for (col = 2; col <= 4; col = col + 1) begin : sa3
                    for (row = 0; row <= 4; row = row + 1) begin : sa4
                        for (u = 0; u <= 63; u = u + 1) begin : sa5
                            xor_register[row][col][u] <= round_in[row][col][u];
                        end
                    end
                end
                
                // Compute xor_register for col 1, row 4 (special case)
                for (u = 0; u <= 63; u = u + 1) begin : sa1_special_1
                    xor_register[4][1][u] <= round_in[4][1][u];
                end
            end

            224: begin
                // Compute xor_register for col 0 and 1, rows 0 to 3
                for (u = 0; u <= 63; u = u + 1) begin : sa1224
                    for (col = 0; col <= 2; col = col + 1) begin : sa3224
                        for (row = 0; row <= 4; row = row + 1) begin : sa2224
                            xor_register[row][col][u] <= round_in[row][col][u] ^ d_register[row][col][u];
                        end
                    end
                end

                // Compute xor_register for col 3, rows 0 to 2
                for (u = 0; u <= 63; u = u + 1) begin : sa122z4
                    for (row = 0; row <= 2; row = row + 1) begin : sa2224
                        xor_register[row][3][u] <= round_in[row][3][u] ^ d_register[row][3][u];
                    end
                end

                // Copy round_in to xor_register for col 4, all rows
                for (row = 0; row <= 4; row = row + 1) begin : sa4224
                    for (u = 0; u <= 63; u = u + 1) begin : sa5224
                        xor_register[row][4][u] <= round_in[row][4][u];
                    end
                end

                // Compute xor_register for col 3, rows 3 and 4 (special case)
                for (u = 0; u <= 63; u = u + 1) begin : sa1_special_1224
                    xor_register[4][3][u] <= round_in[4][3][u];
                    xor_register[3][3][u] <= round_in[3][3][u];
                end
            end

            256: begin
                // Compute xor_register for col 0 and 1, rows 0 to 3
                for (u = 0; u <= 63; u = u + 1) begin : sa1256
                    for (col = 0; col <= 2; col = col + 1) begin : sa3256
                        for (row = 0; row <= 4; row = row + 1) begin : sd256
                            xor_register[row][col][u] <= round_in[row][col][u] ^ d_register[row][col][u];
                        end
                    end
                end

                // Compute xor_register for col 3, rows 0 and 1
                for (u = 0; u <= 63; u = u + 1) begin : sa122z4d
                    for (row = 0; row <= 1; row = row + 1) begin : sa2256
                        xor_register[row][3][u] <= round_in[row][3][u] ^ d_register[row][3][u];
                    end
                end

                // Copy round_in to xor_register for col 4, all rows
                for (row = 0; row <= 4; row = row + 1) begin : sa4224d
                    for (u = 0; u <= 63; u = u + 1) begin : sa5224d
                        xor_register[row][4][u] <= round_in[row][4][u];
                    end
                end

                // Compute xor_register for col 3, rows 2, 3, and 4 (special case)
                for (u = 0; u <= 63; u = u + 1) begin : sa1_special_1224d
                    xor_register[4][3][u] <= round_in[4][3][u];
                    xor_register[3][3][u] <= round_in[3][3][u];
                    xor_register[2][3][u] <= round_in[2][3][u];
                end
            end

            384: begin
                // Compute xor_register for col 0 and 1, rows 0 to 3
                for (u = 0; u <= 63; u = u + 1) begin : sa1384
                    for (col = 0; col <= 1; col = col + 1) begin : sa3384
                        for (row = 0; row <= 4; row = row + 1) begin : sd256384
                            xor_register[row][col][u] <= round_in[row][col][u] ^ d_register[row][col][u];
                        end
                    end
                end

                // Compute xor_register for col 2, rows 0 to 2
                for (u = 0; u <= 63; u = u + 1) begin : sa122z4dss
                    for (row = 0; row <= 2; row = row + 1) begin : sa2256s
                        xor_register[row][2][u] <= round_in[row][2][u] ^ d_register[row][2][u];
                    end
                end

                // Copy round_in to xor_register for col 3 and 4, all rows
                for (row = 0; row <= 4; row = row + 1) begin : sa4224da
                    for (u = 0; u <= 63; u = u + 1) begin : sa5224da
                        xor_register[row][4][u] <= round_in[row][4][u];
                        xor_register[row][3][u] <= round_in[row][3][u];
                    end
                end

                // Compute xor_register for col 2, rows 3 and 4 (special case)
                for (u = 0; u <= 63; u = u + 1) begin : sa1_special_1224ds
                    xor_register[3][2][u] <= round_in[3][2][u];
                    xor_register[4][2][u] <= round_in[4][2][u];
                end
            end

            default: begin
                // Default behavior (if necessary)
            end
        endcase
    end
end


//output 
always @ (negedge clk) begin 
if (~reset && (counter_nr_rounds == 24)) begin
      for (col = 0; col <= 4; col = col + 1) begin 
            for (row = 0; row <= 4; row = row + 1) begin 
                for (u = 0; u <= 63; u = u + 1) begin 
                   dout[(row*64*5) + (col*64) + u] <= (iota_out[row][col][u]) ; 
                       end end end 
                     end end
                     
                     
always @ (negedge clk) begin 
if (~reset && ~permutation_started) begin
 
                      Hash <= dout;
          
                     end end

           
// Theta
//Connection of round_in=theta_in
genvar y,x,i;
generate
for (x = 0; x < 5; x = x + 1) begin : rot27
        for (y = 0; y < 5; y = y + 1) begin : rou23
                      for (i = 0; i < 64; i = i + 1) begin : round8
                       assign theta_in[x][y][i] = xor_register[x][y][i];
                end
            end
        end
endgenerate

//compute the sum of the columns
generate
    for (x = 0; x <= 4; x = x + 1) begin: xx
        for (y = 0; y <= 63; y = y + 1) begin: xx1
            assign sum_sheet[x][y] = theta_in[0][x][y] ^ theta_in[1][x][y] ^ theta_in[2][x][y] ^ theta_in[3][x][y] ^ theta_in[4][x][y];
        end
    end
endgenerate


// Theta generation for columns 1 to 3
    generate
        for (y = 0; y < 5; y = y + 1) begin : gen_theta_cols
            for (x = 1; x <= 3; x = x + 1) begin : gen_theta_cols_inner
                assign theta_out[y][x][0] = theta_in[y][x][0] ^ sum_sheet[x-1][0] ^ sum_sheet[x+1][63];
                for (i = 1; i < 64; i = i + 1) begin : gen_theta_cols_inner_inner
                    assign theta_out[y][x][i] = theta_in[y][x][i] ^ sum_sheet[x-1][i] ^ sum_sheet[x+1][i-1];
                end
            end
        end
    endgenerate

    // Theta generation for column 0
    generate
        for (y = 0; y < 5; y = y + 1) begin : gen_theta_col0
            assign theta_out[y][0][0] = theta_in[y][0][0] ^ sum_sheet[4][0] ^ sum_sheet[1][63];
            for (i = 1; i < 64; i = i + 1) begin : gen_theta_col0_inner
                assign theta_out[y][0][i] = theta_in[y][0][i] ^ sum_sheet[4][i] ^ sum_sheet[1][i-1];
            end
        end
    endgenerate

    // Theta generation for column 4
    generate
        for (y = 0; y < 5; y = y + 1) begin : gen_theta_col4
            assign theta_out[y][4][0] = theta_in[y][4][0] ^ sum_sheet[3][0] ^ sum_sheet[0][63];
            for (i = 1; i < 64; i = i + 1) begin : gen_theta_col4_inner
                assign theta_out[y][4][i] = theta_in[y][4][i] ^ sum_sheet[3][i] ^ sum_sheet[0][i-1];
            end
        end
    endgenerate


//Rho Module 

//Connection of rho_in=theta_out
generate
        for (y = 0; y < 5; y = y + 1) begin : rou
            for (x = 0; x < 5; x = x + 1) begin : rot2
                for (i = 0; i < 64; i = i + 1) begin : round
                       assign rho_in[x][y][i] = theta_out[x][y][i];
                end
            end
        end
endgenerate


    generate
      
        for (i = 0; i < 64; i = i + 1) begin: rho_gen
            assign rho_out[0][0][i] = rho_in[0][0][i];
            assign rho_out[0][1][i] = rho_in[0][1][(i + 64 - 1) % 64];
            assign rho_out[0][2][i] = rho_in[0][2][(i + 64 - 62) % 64];
            assign rho_out[0][3][i] = rho_in[0][3][(i + 64 - 28) % 64];
            assign rho_out[0][4][i] = rho_in[0][4][(i + 64 - 27) % 64];

            assign rho_out[1][0][i] = rho_in[1][0][(i + 64 - 36) % 64];
            assign rho_out[1][1][i] = rho_in[1][1][(i + 64 - 44) % 64];
            assign rho_out[1][2][i] = rho_in[1][2][(i + 64 - 6)  % 64];
            assign rho_out[1][3][i] = rho_in[1][3][(i + 64 - 55) % 64];
            assign rho_out[1][4][i] = rho_in[1][4][(i + 64 - 20) % 64];

            assign rho_out[2][0][i] = rho_in[2][0][(i + 64 - 3)  % 64];
            assign rho_out[2][1][i] = rho_in[2][1][(i + 64 - 10) % 64];
            assign rho_out[2][2][i] = rho_in[2][2][(i + 64 - 43) % 64];
            assign rho_out[2][3][i] = rho_in[2][3][(i + 64 - 25) % 64];
            assign rho_out[2][4][i] = rho_in[2][4][(i + 64 - 39) % 64];

            assign rho_out[3][0][i] = rho_in[3][0][(i + 64 - 41) % 64];
            assign rho_out[3][1][i] = rho_in[3][1][(i + 64 - 45) % 64];
            assign rho_out[3][2][i] = rho_in[3][2][(i + 64 - 15) % 64];
            assign rho_out[3][3][i] = rho_in[3][3][(i + 64 - 21) % 64];
            assign rho_out[3][4][i] = rho_in[3][4][(i + 64 - 8)  % 64];

            assign rho_out[4][0][i] = rho_in[4][0][(i + 64 - 18) % 64];
            assign rho_out[4][1][i] = rho_in[4][1][(i + 64 - 2)  % 64];
            assign rho_out[4][2][i] = rho_in[4][2][(i + 64 - 61) % 64];
            assign rho_out[4][3][i] = rho_in[4][3][(i + 64 - 56) % 64];
            assign rho_out[4][4][i] = rho_in[4][4][(i + 64 - 14) % 64];
        end
    endgenerate
 //Connection of Rho_out=pi_in

generate
        for (y = 0; y < 5; y = y + 1) begin : rou67
            for (x = 0; x < 5; x = x + 1) begin : rot2
                for (i = 0; i < 64; i = i + 1) begin : round
                       assign pi_in[x][y][i] = rho_out[x][y][i];
                end
            end
        end
endgenerate


// pi operation
    
 generate
     for (y = 0; y < 5; y = y + 1) begin
     for (x = 0; x < 5; x = x + 1) begin
      for (i = 0; i < 64; i = i + 1) begin
        assign pi_out[(2*x + 3*y) % 5][(0*x + 1*y) % 5][i] = pi_in[y][x][i];
         end end end
 endgenerate

//Connection of pi_out=chi_in

generate
        for (y = 0; y < 5; y = y + 1) begin : pi_out1
            for (x = 0; x < 5; x = x + 1) begin : pi_out2
                for (i = 0; i < 64; i = i + 1) begin : pi_out3
                       assign chi_in[x][y][i]=pi_out[x][y][i];
                end
            end
        end
endgenerate




   // Chi A[x,y,z]= A[x,y,z] ^ [~[A[x+1,y,z] AND (A[x+2,y,z])]]
    generate
             for (x = 0; x < 3; x = x + 1) begin : gen_x
                for (i = 0; i < 64; i = i + 1) begin : gen_i
                   for(y = 0; y <= 4; y=y+1) begin : genc
                       assign chi_out[y][x][i] = chi_in[y][x][i] ^ (~chi_in[y][x+1][i] & chi_in[y][x+2][i]);
                    end
                end
             end   
            for (i = 0; i < 64; i = i + 1) begin : gen_i_4
                for(y = 0; y <= 4; y=y+1) begin : ge
                  assign  chi_out[y][3][i] = chi_in[y][3][i] ^ (~chi_in[y][4][i] & chi_in[y][0][i]);
                  assign  chi_out[y][4][i] = chi_in[y][4][i] ^ (~chi_in[y][0][i] & chi_in[y][1][i]);
                 end
            end
     endgenerate
     
//connection of chi_out and iota_in

generate
        for (y = 0; y < 5; y = y + 1) begin : rou6722
            for (x = 0; x < 5; x = x + 1) begin : rot211
                for (i = 0; i < 64; i = i + 1) begin : round11
                       assign iota_in[y][x][i] = chi_out[y][x][i];
                end
            end
        end
endgenerate

//iota
     
generate
    for(y = 1; y <= 4; y=y+1) begin : iota_
        for(x = 0; x <= 4; x=x+1) begin : iota_1
            for(i = 0; i < 64; i=i+1)begin : iota_2
                assign iota_out[y][x][i] = iota_in[y][x][i];
            end
        end
    end        
endgenerate

generate
    for(x = 1; x <= 4; x=x+1) begin :iota_3
        for(i = 0; i < 64; i=i+1) begin : iota_4
            assign iota_out[0][x][i] = iota_in[0][x][i];
        end
    end    
endgenerate

generate
    for(i = 0; i < 64; i=i+1) begin : iota_5
        assign iota_out[0][0][i] = iota_in[0][0][i] ^ round_constant_signal[i];
    end
endgenerate  




    
    
endmodule
