/********************************************************************

SHA-256 IP interface to Altera Avalon bus

********************************************************************/
`timescale 1ns/1ps

module SHA256_top(
   TST_OUT,                 // OUT         
   clk,                     // IN
   reset_n,                 // IN
   address,                 // IN  [13:0] 
   lock,                    // IN   
   read,                    // IN 
   readdata,                // OUT [31:0] 
   response,                // OUT  [1:0]
   waitrequest_n,           // OUT 
   write,                   // IN 
   writedata,               // IN  [31:0] 
   test_bus                 // IN  [7:0] 
);

output   reg        TST_OUT;
input               clk;           // System Clock
input               reset_n;       // System Reset

input    [13:0]     address;       // Avalon address bus
input               lock;          // Avalon lock signal
input               read;          // Avalon read signal
output   [31:0]     readdata;      // Avalon read data bus
output   [1:0]      response;      // Avalon slave response/status
output              waitrequest_n; // Avalon slave request
input               write;         // Avalon write signal
input    [31:0]     writedata;     // Avalon write data bus
output   [7:0]      test_bus;       
/******************************************************
Avalon Bus Interface signals
******************************************************/  
reg     [31:0]    readdata;
wire    [13:0]    address;
wire              read;
wire              write;
wire              lock;
wire    [1:0]     response;
wire              waitrequest_n;

wire              st1;
wire              st2;
wire              st3;

wire    [7:0]     test_bus_int;

reg               waitrequest_n_q;   

reg     [1:0]     AVALON_STATE;
reg     [1:0]     AVALON_NEXT_STATE;
reg     [3:0]     wait_signal;
reg               start_proc;

wire              SLAVE_READY;

reg              RAM_WR_CYCLE;
reg              RAM_READ_CYCLE;
reg              Command_WR_cycle;
reg              Status_RD_cycle;

reg     [31:0]    AVA_reg_wr_data;
reg     [11:0]    AVA_reg_address;
wire    [31:0]    AVALON_RD_REG;
wire    [31:0]    STATUS_RD_REG;

/******************************************************
              AVALON BUS INTERFACE LOGIC 
******************************************************/  
localparam  AVALON_IDLE   =  2'b00;
localparam  AVALON_READ   =  2'b01;
localparam  AVALON_WRITE  =  2'b10;   
localparam  AVALON_END    =  2'b11;   

assign response      =  2'b00;
assign waitrequest_n = ~((read | write) & (waitrequest_n_q)) &  //Initial State
                        ~(st1 | st2) |  st3;

assign st1 = (AVALON_STATE == 2'b01) ? 1'b1 : 1'b0;
assign st2 = (AVALON_STATE == 2'b10) ? 1'b1 : 1'b0;
assign st3 = (AVALON_STATE == 2'b11) ? 1'b1 : 1'b0;

// State sequencer   
always @(posedge clk or negedge reset_n) begin
  if(~reset_n) begin
    AVALON_STATE <= AVALON_IDLE;
    wait_signal <= 4'b0000;
    end
  else begin
    AVALON_STATE <= AVALON_NEXT_STATE;
    wait_signal     <= {wait_signal[2:0], start_proc}; //use start_proc as delay reference 
    end
end

// State case logic   
always @* begin
   case(AVALON_STATE)
     AVALON_IDLE: begin // no commands received
       waitrequest_n_q   <=   1'b1;
       start_proc <= 1'b0;
       if(read) begin
          AVALON_NEXT_STATE   <=   AVALON_READ;                  
          end
       else if(write) begin
         AVALON_NEXT_STATE    <=   AVALON_WRITE;                
          end                
       else 
          AVALON_NEXT_STATE   <=   AVALON_IDLE;                  
    end
    AVALON_READ: begin // received read or write
      waitrequest_n_q <= 1'b0; // asserted
      start_proc <= 1'b1;
      if (SLAVE_READY & wait_signal[2]) begin
         AVALON_NEXT_STATE   <=   AVALON_END;                                  
         end
      else begin      
         AVALON_NEXT_STATE   <=   AVALON_READ;
         end
      end                                                    
    AVALON_WRITE: begin
      waitrequest_n_q <= 1'b0; // asserted
      start_proc <= 1'b1;
      if (SLAVE_READY & wait_signal[1]) begin
         AVALON_NEXT_STATE   <=   AVALON_END;
         end
      else begin
         AVALON_NEXT_STATE   <=   AVALON_WRITE;
         end                
      end                                                    
    AVALON_END: begin
      waitrequest_n_q     <=    1'b1;                     
      AVALON_NEXT_STATE   <=    AVALON_IDLE;
      start_proc <= 1'b0;
    end                       
    default: begin
      AVALON_NEXT_STATE   <=   AVALON_IDLE;
      waitrequest_n_q     <=   1'b1;
      start_proc <= 1'b0;
    end
   endcase // case (AVALON_STATE)
end // always @ *


// Address Decode 3F00
always @(posedge clk or negedge reset_n) begin      
  if(~reset_n) begin
        Status_RD_cycle   <=  1'b0;
        RAM_READ_CYCLE    <=  1'b0;
        Command_WR_cycle  <=  1'b0;
        RAM_WR_CYCLE      <=  1'b0;
        end
   else if (AVALON_STATE == AVALON_WRITE) begin
      if (address[11:6] == 6'h3F) begin  // Command Register Space 0x3F000 to 0x3FFFF
        Command_WR_cycle <=  1'b1;
        RAM_WR_CYCLE     <=  1'b0;
        end
      else begin           
         Command_WR_cycle <=  1'b0;
         RAM_WR_CYCLE     <=  1'b1;
         end
      end
   else if (AVALON_STATE == AVALON_READ) begin
     if (address[11:6] == 6'h3F) begin  // Status Register Space set to 0x3F
        Status_RD_cycle  <=  1'b1;
        RAM_READ_CYCLE   <=  1'b0;
        end
     else begin
        Status_RD_cycle  <=  1'b0;
        RAM_READ_CYCLE   <=  1'b1;
        end
    end
   else begin
        Status_RD_cycle   <=  1'b0;
        RAM_READ_CYCLE    <=  1'b0;
        Command_WR_cycle  <=  1'b0;
        RAM_WR_CYCLE      <=  1'b0;
        end
end


//Register in Avalon address shorten register to register delay     
always @(posedge clk or negedge reset_n) begin      
  if(~reset_n) begin
     AVA_reg_address <= 12'h000;
     end
  else if ( write | read ) begin
     AVA_reg_address <= address[11:0]; // 32 bit access only
     end
end


//Register in Avalon write bus data to shorten register to register delay
always @(posedge clk or negedge reset_n) begin      
  if(~reset_n) begin
     AVA_reg_wr_data <= 32'h00000000;
     end
  else if (write) begin
     AVA_reg_wr_data <= writedata;
     end
end


//Read process
always @(posedge clk or negedge reset_n) begin      
  if(~reset_n) begin
     readdata          <= 32'h00000000;
     end
  else if ( read ) begin
     if (Status_RD_cycle) begin
        readdata          <=   STATUS_RD_REG; //Status Register
        end
     else if (RAM_READ_CYCLE) begin
        readdata <= AVALON_RD_REG;
        end
  end
end


always @(posedge clk or negedge reset_n) begin      
  if(~reset_n) begin
        TST_OUT           <=  1'b1;
         end
//  else if (read | write) begin
    else if (AVALON_STATE == AVALON_READ ) begin
       TST_OUT <= ~TST_OUT;
        end
    end

    
/***********************************************
  Test
***********************************************/    
assign test_bus[0] = lock;  
assign test_bus[1] = read;  
assign test_bus[2] = waitrequest_n; 
assign test_bus[3] = write; 
assign test_bus[4] = test_bus_int[4];   
assign test_bus[5] = test_bus_int[5];   
assign test_bus[6] = test_bus_int[6];   
assign test_bus[7] = test_bus_int[7];   


SHA256_core Core_Interface  
     (  .STATUS_RD_REG(STATUS_RD_REG),          // OUT [31:0]
        .AVALON_RD_REG(AVALON_RD_REG),          // OUT [31:0]
        .RAM_WR_CYCLE(RAM_WR_CYCLE),            //  IN
        .RAM_READ_CYCLE(RAM_READ_CYCLE),        //  IN
        .Command_WR_cycle(Command_WR_cycle),    //  IN
        .Status_RD_cycle(Status_RD_cycle),      //  IN
        .AVA_reg_wr_data(AVA_reg_wr_data),      //  IN [31:0]
        .AVA_reg_address(AVA_reg_address),      //  IN [11:0]
        .SLAVE_READY(SLAVE_READY),              // OUT
        .clk(clk),                              //  IN
        .reset_n(reset_n),                      //  IN
        .test_sig(test_bus_int)                 // OUT [7:0]
        );

endmodule
/******************************************************

          END AVALON BUS INTERFACE LOGIC
          
******************************************************/  

