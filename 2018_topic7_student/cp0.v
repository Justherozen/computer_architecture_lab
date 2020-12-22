`include "define.vh"

module cp0 (
    input wire clk, // main clock
    // operations (read in ID stage and write in EXE stage)
    input wire [1:0] oper, // CP0 operation type
    input wire [4:0] addr_r, // read address
    output wire [31:0] data_r, // read data
    input wire [4:0] addr_w, // write address
    input wire [31:0] data_w, // write data
    // exceptions (check exceptions in MEM stage)
    input wire rst, // synchronous reset
    input wire if_rst,
    input wire if_en,
    input wire ir_en, // interrupt enable
    input wire ir_in, // external interrupt input
    input wire [31:0] ret_addr, // target instruction address to store when interrupt occurred
    output reg ir,
    output reg ir_valid,
    output reg ir_wait,
    output reg jump_en, // force jump enable signal when interrupt authorised or ERET occurred
    output reg [31:0] jump_addr // target instruction address to jump to
    );
	`include "mips_define.vh"

    reg [31:0] regs[31:0];

    // interrupt determination
    wire eret;

    reg ir_in_previous = 0;

    assign eret = (oper == EXE_CP0_ERET);
    always @(posedge clk) begin
        if (rst) begin
            ir_valid = 1;
            ir_wait = 0;
            ir_in_previous = 0;
        end else begin
            if (eret)
                ir_valid = 1;
            else if (ir)
                ir_valid = 0; // prevent exception reenter
            if (ir_in && !ir_in_previous)
                ir_wait = 1;
            else if (eret)
                ir_wait = 0;
            ir_in_previous = ir_in;
        end
        ir = ir_en & ir_wait & ir_valid;
    end

    // // Exception Handler Base Register
    // always @(posedge clk) begin
    //
    // end
    //
    // // Exception Program Counter Register
    // always @(posedge clk) begin
    //     //����
    // end
    assign data_r = regs[addr_r];
    // always @(posedge clk) begin
    //     data_r = regs[addr_r];
    // end

    // jump determination
    always @(posedge clk) begin
        if (if_rst) begin
            jump_addr = 0;
            jump_en = 0;
        end else begin
            if (oper == EXE_CP0_ERET) begin //eret
                jump_addr = regs[CP0_EPCR];
                jump_en = 1;
            end else if (oper == EXE_CP_STORE) begin
                regs[addr_w] = data_w;
            end else if (ir) begin //external interrupt
                jump_addr = regs[CP0_EHBR];
                jump_en = 1;
            end else begin
                if (if_en) begin
                    jump_en = 0;
                    jump_addr = 32'b0;
                end
                
            end
        end 

        if(ir)                 
            regs[CP0_EPCR] = ret_addr;

    
	 
        if(rst) begin 
            regs[CP0_TCR] = 0;
        end else begin
        regs[CP0_TCR] = regs[CP0_TCR] + 1;
        end

    end

endmodule
