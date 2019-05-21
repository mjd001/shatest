/**********************************************************************
SHA-256 Core logic Module
- mjd 1/17/2019

NIST Publication Number:  FIPS 180-4  Secure Hash Standard (08/2015)


SHA-256 - Data Structure
------------------------
A message, M, consists of one or more blocks M(n)
Each M(n)consists of 512 bits or sixteen, 32 bit words or 64 bytes
Each 32 bit word is ordered big endian - for N words containing
n bytes i.e.:
         [31..........................0]                                   
Word 1: {byte 0, byte 1, byte 2, byte 3}
Address:    3       2       1       0

Word 2: {byte 4, byte 5, byte 6, byte 7}
Address:    7       6       5       4

...

Word N: {byte(n-3), byte(n-2), byte(n-1), byte(n)} 
Address:   Last      Last-2     Last-1     Last-3
-------------------------------------------------------------------------

If M(last) block: 
- Last block must contain 512 bits
  -> Last 8 bytes of this block contain number of bits in message
  -> A binary '1' is concatenated to the last bit of the message.
  -> Last block zero paddded with k bits, where L + 1 + k = 448 % 512
  -> "L" will be 0x80 (byte granularity)

Note: If last block message size is .GT. 55 bytes it wont fit the bit 
      count and last bit ("L"). In this case L is appended and zero
      padding continues to the end of the block. A next block is created
      and zero padded for 56 bytes, the 8 byte message bit count is 
      stored there.
      
**************************************************************************/
`timescale 1ns / 1ps

module SHA256_core 
     (  output reg[31:0]  STATUS_RD_REG,   
        output    [31:0]  AVALON_RD_REG,   
        input             RAM_WR_CYCLE,    
        input             RAM_READ_CYCLE,  
        input             Command_WR_cycle,
        input             Status_RD_cycle, 
        input     [31:0]  AVA_reg_wr_data, 
        input     [11:0]  AVA_reg_address, 
        output            SLAVE_READY,     
        input             clk ,            
        input             reset_n,         
        output    [7:0]   test_sig         
        );

/*******************************
  RAM State Machine signals
*******************************/                                    
reg             RAM_bus_cycle;
reg             CMD_RDY;
reg             STATUS_RD_done;
reg             RAM_RD_done;
wire   [31:0]   RAM_Data_OUT;
wire   [31:0]   RAM_Data_IN_AVA;
reg     [7:0]   CMD_reg;
reg     [1:0]   CMD_state;
reg     [1:0]   status_state;
reg     [3:0]   waits_AVA;
reg    [11:0]   RAM_RD_Addr;
reg    [11:0]   RAM_WR_Addr;
reg             RAM_WR_ENA;
reg    [31:0]   RAM_Data_IN;
reg             RAM_WR_ENA_SM;
reg     [2:0]   RAM_State;
reg     [1:0]   RAM_byte_addr;
reg     [2:0]   ram_rd_sm;

reg [15:0] msg_byte_cnt;

wire data_end;
wire sys_busy;
wire RAM4K_SEL;
wire [11:0] RAM_RD_ADDR_SHA;
wire [11:0] RAM_WR_ADDR_SHA;
wire RAM_WR_SHA;
wire [31:0] Digest_OUT;


/**************************************************
     State machine signals
**************************************************/
wire HASH_PROC_GO;

/******************************************************************************
  BEGIN:       AVALON BUS INTERFACE LOGIC
******************************************************************************/
assign SLAVE_READY  = (~RAM_bus_cycle & RAM_WR_CYCLE) |    // RAM write comple
                      (CMD_RDY)                       |    // Command received
                      (STATUS_RD_done)                |    // Status register data is ready
                      (RAM_RD_done);                       // Read cycle complete

assign AVALON_RD_REG   = RAM_Data_OUT;                     // Data read from RAM  

assign RAM_Data_IN_AVA = AVA_reg_wr_data;

/******************************************************************************
        Avalon bus write operation logic
        CMD_reg[0] = 1 - Start Multiply
        Message bytes count
******************************************************************************/  
always @(posedge clk or negedge reset_n) begin      
  if (~reset_n) begin
    CMD_RDY       <=  1'b0;    // Signal to complete bus access
    CMD_reg       <=  8'h00;
    CMD_state     <=  2'b00;
    msg_byte_cnt  <=  16'h0000;
    end
  else if ((Command_WR_cycle) & (CMD_state == 2'b00)) begin
    if (AVA_reg_address[7:0] == 8'hC0) begin       // Command Register
       CMD_reg       <=   AVA_reg_wr_data[7:0];
       CMD_RDY       <=   1'b0;
       CMD_state     <=   2'b01;
       end
      else if (AVA_reg_address[7:0] == 8'hC1) begin  // Message byte count
        msg_byte_cnt  <=   AVA_reg_wr_data[15:0];
        CMD_RDY       <=   1'b0;
        CMD_state     <=   2'b01;
        end
     end
  else if (CMD_state == 2'b01) begin  // Busy state for multiply
    CMD_RDY       <=  1'b1;
    CMD_state     <=  2'b10;
    end
  else if (CMD_state == 2'b10) begin  // End state clear
    CMD_reg       <=  8'h00;
    if (~Command_WR_cycle) begin
       CMD_state     <=   2'b00;
       CMD_RDY       <=   1'b0;
       end
    end
end

// Command bit
assign HASH_PROC_GO = CMD_reg[0];

/******************************************************************************
   Avalon bus read operation
   Read Status [0:3] and respond to bus controller
******************************************************************************/  

assign data_end = 1'b0; // ToDo: This signal will tell host local RAM is empty, implement it

always @(posedge clk or negedge reset_n) begin      
  if(~reset_n) begin
     STATUS_RD_REG        <=      32'h00000000;
     STATUS_RD_done       <=      1'b0;
     status_state         <=      2'b00;
     waits_AVA            <=      4'h0;
     end
  else if (status_state == 2'b00) begin
     if (Status_RD_cycle) begin 
       case (AVA_reg_address[2:0])
         3'b000:       STATUS_RD_REG        <=      {20'h00000, 8'h00, data_end, 2'b00, sys_busy }; // Place holder value
         3'b001:       STATUS_RD_REG        <=      {32'h00000000};
         3'b010:       STATUS_RD_REG        <=       32'hdeadbeef;
         3'b011:       STATUS_RD_REG        <=       32'hfeedface;
         3'b100:       STATUS_RD_REG        <=       32'habc123ef;
         default:      STATUS_RD_REG        <=       32'ha1b2c3d4;
       endcase
        STATUS_RD_done       <=      1'b0;
        status_state         <=      2'b01;
        end
     else begin

        STATUS_RD_done       <=      1'b0;
        end
     end
  else if (status_state == 2'b01) begin
     waits_AVA <= {waits_AVA[2:0], 1'b1} ;
     if (waits_AVA[3] == 1'b1) begin
         status_state         <=      2'b10;
         end
     end
  else if (status_state == 2'b10) begin
     waits_AVA               <=      4'h0;
     status_state            <=      2'b11;
     end
  else if (status_state == 2'b11) begin
     STATUS_RD_done       <=      1'b1;
     status_state         <=      2'b00;
     end
end  
/******************************************************************************
    END: AVALON BUS CONTROLLER INTERFACE SIGNAL LOGIC
******************************************************************************/

/******************************************************************************
    BEGIN:    RAM IP Core:  4096 x 32 IP RAM and interface logic 
******************************************************************************/
RAM2Pv1 RAM4096X32 
  ( .aclr(~reset_n),          //  IN
    .clock(clk),              //  IN
    .data(RAM_Data_IN),       //  IN [31:0]
    .rdaddress(RAM_RD_Addr),  //  IN [11:0]
    .wraddress(RAM_WR_Addr),  //  IN [11:0]
    .wren(RAM_WR_ENA),        //  IN
    .q(RAM_Data_OUT));        // OUT [31:0]

/******************************************************************************
     RAM IP Core:  Input Access Logic
     - Avalon Bus master read/write
******************************************************************************/
always @(*) begin
case (RAM4K_SEL) 
   // Avalon bus interface
   1'b0:  begin
               RAM_RD_Addr   <=   AVA_reg_address; // read or write
               RAM_WR_Addr   <=   AVA_reg_address;
               RAM_WR_ENA    <=   RAM_WR_ENA_SM;           
               RAM_Data_IN   <=   RAM_Data_IN_AVA;
               end

   // Read M(n) from RAM       
   1'b1:  begin
               RAM_RD_Addr   <=   RAM_RD_ADDR_SHA;    
               RAM_WR_Addr   <=   RAM_WR_ADDR_SHA;            
               RAM_WR_ENA    <=   RAM_WR_SHA;                 
               RAM_Data_IN   <=   Digest_OUT;         // reg [32:0] Digest_OUT 
               end
  default: begin
               RAM_RD_Addr   <=   12'h000;
               RAM_WR_Addr   <=   12'h000;
               RAM_WR_ENA    <=    1'b0;           
               RAM_Data_IN   <=   32'h0000_0000;
               end
  endcase 
end 

/******************************************************************************
   MASTER WRITE - RAM Interface state machine Avalon bus master write cycle
******************************************************************************/
always @(posedge clk or negedge reset_n) begin      
  if(~reset_n) begin
      RAM_WR_ENA_SM          <=   1'b0;           // RAM Write Enable
      RAM_State              <=   3'b000;         // State pointer
      RAM_byte_addr          <=   2'b00;
      RAM_bus_cycle          <=   1'b0;
      end   
/******************************************************************************
  RAM SM: Idle State
******************************************************************************/
  else if (RAM_State  ==   3'b000) begin
     if (RAM_WR_CYCLE == 1'b1) begin
        RAM_State            <=  3'b001;
        RAM_WR_ENA_SM        <=  1'b1;    // RAM Write Enable
        RAM_bus_cycle        <=  1'b1;
        end
    end
/******************************************************************************
  RAM SM: Avalon Bus writes to RAM
******************************************************************************/                              
  else if ( RAM_State  ==   3'b001)  begin
     if (RAM_byte_addr == 2'b10) begin
        RAM_State          <=  3'b111;
        RAM_bus_cycle      <=  1'b0;
        end
     else begin
        RAM_byte_addr   <=  RAM_byte_addr + 1'b1;
        RAM_State       <=  3'b001;
        end
     end
/******************************************************************************
  RAM SM: Finish state
******************************************************************************/                                  
  else if (RAM_State  ==   3'b111) begin  //End state
        RAM_WR_ENA_SM          <=     1'b0;
        RAM_byte_addr          <=    2'b00;    // Reset
        RAM_State              <=   3'b000;
        end
end
/******************************************************************************
            END:     RAM READ/WRITE STATE MACHINE
******************************************************************************/

/******************************************************************************
   MASTER READ - Avalon bus master read cycle
                 Slave read done timing
******************************************************************************/
always @(posedge clk or negedge reset_n) begin
  if(~reset_n) begin
      RAM_RD_done    <= 1'b0;
      ram_rd_sm      <= 3'b000;
      end
  else if (ram_rd_sm == 3'b000) begin
     if (RAM_READ_CYCLE) begin
       ram_rd_sm      <= 3'b001;
       end
     end
  else if (ram_rd_sm == 3'b001) begin
       ram_rd_sm      <= 3'b010;
       end
  else if (ram_rd_sm == 3'b010) begin
       RAM_RD_done    <= 1'b1;
       ram_rd_sm      <= 3'b011;
       end
  else if (ram_rd_sm == 3'b011) begin
       RAM_RD_done    <= 1'b0;
       if (~RAM_READ_CYCLE) begin   //Wait until Read cycle is done before returning
           ram_rd_sm      <= 3'b000;
           end
       end
end
/******************************************************************************
    END:    RAM IP Core:  4096 x 32 IP RAM and Bus interface logic 
******************************************************************************/

SHA256 SHA_inst
   (  .clk(clk),                          // input
      .reset_n(reset_n),                  // input
      .RAM_RD_ADDR_SHA(RAM_RD_ADDR_SHA),  // output  [11:0]
      .RAM_WR_ADDR_SHA(RAM_WR_ADDR_SHA),  // output  [11:0]   
      .RAM_WR_SHA(RAM_WR_SHA),            // output
      .Digest_OUT(Digest_OUT),            // output  [31:0]
      .RAM4K_SEL(RAM4K_SEL),              // output
      .test_sig(test_sig),                // output   [7:0] 
      .RAM_Data(RAM_Data_OUT),            // input   [31:0]
      .sys_busy(sys_busy),                // output
      .msg_byte_cnt(msg_byte_cnt),        // input [15:0]
      .HASH_PROC_GO(HASH_PROC_GO));       // input




endmodule

















