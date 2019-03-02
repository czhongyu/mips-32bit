`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/05/26 21:59:57
// Design Name: 
// Module Name: datapath
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


module datapath(
    input clk,reset,
    input memtoregE,memtoregM,memtoregW,
    input pcsrcD,branchD,
    input [1:0] alusrcaE,alusrcbE,
    input [1:0] regdstE,
    input regwriteE,regwriteM,regwriteW,
    input [1:0] jumpD,
    input [3:0] alucontrolE,
    output cmpD,
    output [31:0] pcF,
    input [31:0] instrF,
    output [31:0] aluoutM,writedataM,
    input [31:0] readdataM,
    output [5:0] opD,functD,
    output flushE,
    output [15:0] led,
    input beep,
    input extend,
    input [2:0] cmpcontrolD,
    input dready,iready,
    input [9:0] sw,
    output reg [31:0] t,
    output reg [7:0] disop
    );
    
    wire forwardaD,forwardbD;
    wire [1:0] forwardaE,forwardbE;
    wire stallF,stallD;
    wire [4:0] rsD,rtD,rdD,rsE,rtE,rdE;
    wire [4:0] saD,saE;//instrD[10:6]
    wire [4:0] writeregE,writeregM,writeregW;
    wire flushD;
    wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD;
    wire [31:0] signimmD,signimmE,signimmshD;
    wire [31:0] srcaD,srca2D,srcaE,srca2E,srca3E;
    wire [31:0] srcbD,srcb2D,srcbE,srcb2E,srcb3E;
    wire [31:0] pcplus4D,instrD;
    wire [31:0] pcplus4E;
    wire [31:0] aluoutE,aluoutW;
    wire [31:0] readdataW,resultW;
    
    wire [31:0] trf;
    
    //hazard detection
    hazard h(rsD,rtD,rsE,rtE,
             writeregE,writeregM,writeregW,
             regwriteE,regwriteM,regwriteW,
             memtoregE,memtoregM,branchD,
             forwardaD,forwardbD,forwardaE,forwardbE,
             stallF,stallD,flushE,
             jumpD,
             led,beep);
             
    //next PC logic (operates in fetch & decode)
    mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);
    mux3 #(32) pcmux(pcnextbrFD,
                     {pcF[31:28],instrD[25:0],2'b00},
                     srca2D,
                     jumpD,pcnextFD);
                     
               
    //fetch
    flopenr #(32) pcFreg(clk,reset,(~stallF)&dready&iready,pcnextFD,pcF);
    adder pcaddF(pcF,32'b100,pcplus4F);
    
    //decode
    flopenr #(32) pcplus4Dreg(clk,reset,(~stallD)&dready&iready,pcplus4F,pcplus4D);
    flopenrc #(32) instrDreg(clk,reset,(~stallD)&dready&iready,flushD,instrF,instrD);
    signext se(instrD[15:0],extend,signimmD);
    sl2 immsh(signimmD[29:0],signimmshD);
    adder pcaddD(pcplus4D,signimmshD,pcbranchD);
    mux2 #(32) forwardaDmux(srcaD,aluoutM,forwardaD,srca2D);
    mux2 #(32) forwardbDmux(srcbD,aluoutM,forwardbD,srcb2D);
    compare compare(srca2D,srcb2D,cmpcontrolD,rtD,cmpD);
    
    //saD = instrD[10:6]
    assign {opD,rsD,rtD,rdD,saD,functD}=instrD;
    
    assign flushD=pcsrcD|jumpD[1]|jumpD[0];
    
    //register file (operates in decode & writeback)
    regfile rf(clk,regwriteW,rsD,rtD,writeregW,
               resultW,srcaD,srcbD,
               sw[4:0],trf);
    
    //execute
    flopenrc #(32) srcaEreg(clk,reset,dready,flushE,srcaD,srcaE);
    flopenrc #(32) srcbEreg(clk,reset,dready,flushE,srcbD,srcbE);
    flopenrc #(32) signimmEreg(clk,reset,dready,flushE,signimmD,signimmE);
    flopenrc #(5) rsEreg(clk,reset,dready,flushE,rsD,rsE);
    flopenrc #(5) rtEreg(clk,reset,dready,flushE,rtD,rtE);
    flopenrc #(5) rdEreg(clk,reset,dready,flushE,rdD,rdE);
    flopenrc #(5) saEreg(clk,reset,dready,flushE,saD,saE);
    flopenrc #(32) pcplus4Ereg(clk,reset,dready,flushE,pcplus4D,pcplus4E);
    
    mux3 #(32) forwardaEmux(srcaE,resultW,aluoutM,forwardaE,srca2E);
    mux3 #(32) forwardbEmux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
    
    mux4 #(32) srcamux(srca2E,{27'b0,saE},pcplus4E,32'b10000,alusrcaE,srca3E);
    mux3 #(32) srcbmux(srcb2E,signimmE,32'b100,alusrcbE,srcb3E);
    
    alu alu(srca3E,srcb3E,alucontrolE,aluoutE);
    mux3 #(5) wrmux(rtE,rdE,5'b11111,regdstE,writeregE);
    
    //memory
    flopenr #(32) writedataMreg(clk,reset,dready,srcb2E,writedataM);
    flopenr #(32) aluoutMreg(clk,reset,dready,aluoutE,aluoutM);
    flopenr #(5) writeregMreg(clk,reset,dready,writeregE,writeregM);
    
    //write back
    flopenr #(32) aluoutWreg(clk,reset,dready,aluoutM,aluoutW);
    flopenr #(32) readdataWreg(clk,reset,dready,readdataM,readdataW);
    flopenr #(5) writeregWreg(clk,reset,dready,writeregM,writeregW);
    mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
    
    //display
    parameter ZERO=8'b0;
    parameter ONE=8'b1;
    parameter TWO=8'b11;
    parameter EIGHT=8'b11111111;
    always@(*)
    begin
        case(sw[9:7])
        3'b000:
        //F stage
            case(sw[6:0])
            7'b1:begin t<=pcplus4F;disop<=EIGHT;end
            7'b10:begin t<=pcbranchD;disop<=EIGHT;end
            7'b11:begin t<=pcnextbrFD;disop<=EIGHT;end
            7'b100:begin t<={pcF[31:28],instrD[25:0],2'b00};disop<=EIGHT;end
            7'b101:begin t<=pcnextFD;disop<=EIGHT;end
            7'b110:begin t<=pcF;disop<=EIGHT;end
            7'b111:begin t<=pcplus4F;disop<=EIGHT;end
            7'b1000:begin t<=instrF;disop<=EIGHT;end
        //D stage
            7'b1001:begin t<=pcplus4D;disop<=EIGHT;end
            7'b1010:begin t<=instrD;disop<=EIGHT;end
            7'b1011:begin t<=signimmD;disop<=EIGHT;end
            7'b1100:begin t<=signimmshD;disop<=EIGHT;end
            7'b1101:begin t<=pcbranchD;disop<=EIGHT;end
            7'b1110:begin t<=srcaD;disop<=EIGHT;end
            7'b1111:begin t<=srcbD;disop<=EIGHT;end
            7'b10000:begin t<=srca2D;disop<=EIGHT;end
            7'b10001:begin t<=srcb2D;disop<=EIGHT;end
            7'b10010:begin t<=cmpD;disop<=ONE;end
            7'b10011:begin t<=flushD;disop<=ONE;end
        //E stage:
            7'b10100:begin t<=srcaE;disop<=EIGHT;end
            7'b10101:begin t<=srcbE;disop<=EIGHT;end
            7'b10110:begin t<=srca2E;disop<=EIGHT;end
            7'b10111:begin t<=srcb2E;disop<=EIGHT;end
            7'b11000:begin t<=signimmE;disop<=EIGHT;end
            7'b11001:begin t<=rsE;disop<=TWO;end
            7'b11010:begin t<=rtE;disop<=TWO;end
            7'b11011:begin t<=rdE;disop<=TWO;end
            7'b11100:begin t<=saE;disop<=TWO;end
            7'b11101:begin t<=pcplus4E;disop<=EIGHT;end
            7'b11110:begin t<=srca3E;disop<=EIGHT;end
            7'b11111:begin t<=srcb3E;disop<=EIGHT;end
            7'b100000:begin t<=aluoutE;disop<=EIGHT;end
            7'b100001:begin t<=writeregE;disop<=TWO;end
        //M stage
            7'b100010:begin t<=writedataM;disop<=EIGHT;end
            7'b100011:begin t<=aluoutM;disop<=EIGHT;end
            7'b100100:begin t<=writeregM;disop<=TWO;end
            7'b100101:begin t<=readdataM;disop<=EIGHT;end
        //W stage
            7'b100110:begin t<=aluoutW;disop<=EIGHT;end
            7'b100111:begin t<=readdataW;disop<=EIGHT;end
            7'b101000:begin t<=writeregW;disop<=TWO;end
            7'b101001:begin t<=resultW;disop<=EIGHT;end
            default:begin t<=32'b0;disop<=ZERO;end
            endcase
        //regfile
        3'b001:
            if(sw[6]|sw[5]) begin t<=32'b0;disop<=ZERO;end
            else begin t<=trf;disop<=EIGHT;end
        default:begin t<=32'b0;disop<=ZERO;end
        endcase
    end
    
endmodule
