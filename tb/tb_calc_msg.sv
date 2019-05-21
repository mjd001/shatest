/******************************************************************************
SHA-256 Hash algorithm system test
- mjd 1/17/2019

NIST FIPS PUB 180-4 (3/2012)
- SHA-256 message block contains 512 bits or sixteen X 32 bit words (64 bytes)



Avalon Bus[13:0]        32 bit Words            Description
----------------------------------------------------------------------------
0x0000 : 0x018C            100                  E-Matrix


******************************************************************************/
`timescale 1ns/1ps

//Test Data
//`include "tb_test1.vh"

import EMTest::*;
//module tb (/*AUTOARG*/ ) ;
module tb (/*AUTOARG*/ ) ;


integer TESTFILE;


// Scratch variables
integer i, j, k;
integer done;
integer x, y, z;
integer m, n, p;

integer test_cntr;

// Time var
realtime t1, t2;


// Global clock and reset
logic            clk;  
logic            reset_n; 

// Test signal
logic    blip;


// Avalon bus interfce signals
logic [31:0] AVAAddr;  
logic [31:0] AVAData;
logic [13:0] address;
logic write;
logic read;
logic [31:0] writedata;
logic [31:0] readdata;
logic        lock;
logic [1:0] response;

logic [31:0] DUT_HASH [0:7];


// Error counter
integer err;

// Locals
logic [31:0] msg_blocks;
logic [31:0] msg_sch[0:63];
logic [31:0] working_variables[0:63];


// Hash initial values  (FIPS 180-4 5.3.3)
logic [31:0] HASH_ini[0:7] = '{32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a, 32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19 };
                               
                               
logic [31:0] test_msg_block[0:4095];
logic [31:0] DUT_test_msg_block[0:4095];

                                                             
logic [31:0] DUT_MSG_BLK_1[0:63];
logic [31:0] DUT_MSG_BLK_2[0:63];
logic [31:0] DUT_MSG_BLK_3[0:63];
logic [31:0] DUT_MSG_BLK_4[0:63];
                               
logic [31:0] HASH[0:7];
logic [31:0] TB_HASH[0:7];

logic [31:0] ROR_WT1_17;         
logic [31:0] ROR_WT1_19;        
logic [31:0] SHR_WT1_10;         
                   
logic [31:0] ROR_WT2_7;          
logic [31:0] ROR_WT2_18;         
logic [31:0] SHR_WT2_3;          
                
logic [31:0] WPT1;               
logic [31:0] WPT2;               
logic [31:0] MSG_SCHED_LOGIC_OUT;

logic [5:0] K_addr;
logic [31:0] K_val;
logic [31:0] msg_word_picked;


logic [31:0] T1_ROR_E_6; 
logic [31:0] T1_ROR_E_11;
logic [31:0] T1_ROR_E_25;

logic [31:0] T1_ROR;     
logic [31:0] T1_EFG;    

logic [31:0] T1;         

logic [31:0] T2_ROR_A_2; 
logic [31:0] T2_ROR_A_13;
logic [31:0] T2_ROR_A_22;

logic [31:0] T2_ROR;     
logic [31:0] T2_ABC;     

logic [31:0] T2;

logic [31:0] a_reg;
logic [31:0] b_reg;
logic [31:0] c_reg;
logic [31:0] d_reg;
logic [31:0] e_reg;
logic [31:0] f_reg;
logic [31:0] g_reg;
logic [31:0] h_reg;

/******************************************
*      DUT Probe/Monitor signals
******************************************/
logic DUT_update_Working_Var;          //
logic DUT_clk;                         // DUT system clock
logic DUT_MSG_SCHED_RAM_WE;            // Message scedule RAM Write Enable
logic [31:0] DUT_RAM_Data_OUT_p;       // RAM data select mux out
logic [17:0] DUT_msg_bit_len;          // Meta: Number of message bits
logic DUT_HASH_PROC_GO;                // Message processing start (top)
logic DUT_start_sha_proc;              // SHA control state machine start signal
logic DUT_sha_sm_busy;                 // SHA Process State machine busy status
logic [2:0] DUT_SHA_CTRL_SM;           // SHA control state machine state
logic [15:0] DUT_num_msg_blks;         // Number of message blocks remaining to be processed
logic [3:0] DUT_track_ptr;             // Current Track Pointer location
logic [1:0] DUT_byte_position;         // Byte position of last data byte in last 32 bit word
logic [31:0] DUT_RAM_Data_IN;          // 4K RAM Data in port
logic [11:0] DUT_RAM_RD_Addr;          // 4K RAM Read address port
logic [11:0] DUT_RAM_WR_Addr;          // 4K RAM Write address port
logic [31:0] DUT_RAM_Data_OUT;         // 4K RAM Data out port
logic [3:0] DUT_dat_sw_sel;            // 4K RAM Data out to SHA process select
logic [3:0] DUT_SHA_PROC_STATE;        // SHA Processing state machine.
logic [12:0] DUT_MSG_SCHED_RAM_WR_ADDR;// Message schedule RAM base address
logic [31:0] K_const_ROM_data;         // K Constants ROM Data
logic [5:0] DUT_T_addr_sub_2;          // Message schedule RAM base address minus two
logic [5:0] DUT_T_addr_sub_7;          // Message schedule RAM base address minus seven
logic [5:0] DUT_T_addr_sub_15;         // Message schedule RAM base address minus fifteen
logic [5:0] DUT_T_addr_sub_16;         // Message schedule RAM base address minus sixteen
logic [31:0] DUT_msg_word_picked;
logic [31:0] DUT_MSG_SCHED_RAM_DAT_IN; // Message schedule input RAM data
logic DUT_MSG_SCHED_DATA_SOURCE;       // Message Schedule RAM 1 to 4 input data source select
logic [31:0] DUT_dat_o_2;              // Message schedule RAM #1 data output
logic [31:0] DUT_dat_o_7;              // Message schedule RAM #2 data output
logic [31:0] DUT_dat_o_15;             // Message schedule RAM #3 data output
logic [31:0] DUT_dat_o_16;             // Message schedule RAM #4 data output
logic [31:0] DUT_ROR_WT1_17;           // Rotate Right Message schedule RAM data #1 17 bits
logic [31:0] DUT_ROR_WT1_19;           // Rotate Right Message schedule RAM data #1 19 bits
logic [31:0] DUT_SHR_WT1_10;           // Shift Right Message schedule RAM #1 10 bits
logic [31:0] DUT_ROR_WT2_7;            // Rotate Right Message schedule RAM data #3 7 bits
logic [31:0] DUT_ROR_WT2_18;           // Rotate Right Message schedule RAM data #3 18 bits
logic [31:0] DUT_SHR_WT2_3;            // Shift Right Message schedule RAM #3 10 bits
logic [31:0] DUT_WPT1;                 // Message Schedule intermediate value #1
logic [31:0] DUT_WPT2;                 // Message Schedule intermediate value #2
logic [31:0] DUT_MSG_SCHED_LOGIC_OUT;  // Message Schedule calculation
logic [31:0] DUT_T1_ROR_E_6;           // SHA256 T1 Process rotate right e_reg 6
logic [31:0] DUT_T1_ROR_E_11;          // SHA256 T1 Process rotate right e_reg 11
logic [31:0] DUT_T1_ROR_E_25;          // SHA256 T1 Process rotate right e_reg 25
logic [31:0] DUT_T1_ROR;               // SHA256 T1 Process XOR of e_reg rotates
logic [31:0] DUT_T1_EFG;               // SHA256 T1 Process XOR of e_reg rotates
logic [31:0] DUT_T1;                   // SHA256 sum of T1_ROR and DUT_T1_EFG
logic [31:0] DUT_T2_ROR_A_2;           // SHA256 T2 Process rotate right a_reg 2
logic [31:0] DUT_T2_ROR_A_13;          // SHA256 T2 Process rotate right a_reg 13 
logic [31:0] DUT_T2_ROR_A_22;          // SHA256 T2 Process rotate right a_reg 22
logic [31:0] DUT_T2_ROR;               // SHA256 T2 Process XOR a_reg 2  
logic [31:0] DUT_T2_ABC;               // SHA256 T2 Process XOR's a_reg, b_reg and c_reg sums                     
logic [31:0] DUT_T2;                   // SHA256 T2 sum DUT_T2_ROR and DUT_T2_ABC  
                            
logic [31:0] DUT_a_reg;                // Working Variable "A" Register
logic [31:0] DUT_b_reg;                // Working Variable "B" Register
logic [31:0] DUT_c_reg;                // Working Variable "C" Register
logic [31:0] DUT_d_reg;                // Working Variable "D" Register
logic [31:0] DUT_e_reg;                // Working Variable "E" Register
logic [31:0] DUT_f_reg;                // Working Variable "F" Register
logic [31:0] DUT_g_reg;                // Working Variable "G" Register
logic [31:0] DUT_h_reg;                // Working Variable "H" Register

logic [31:0] DUT_H_reg_0;              // Hash Register 0
logic [31:0] DUT_H_reg_1;              // Hash Register 1
logic [31:0] DUT_H_reg_2;              // Hash Register 2
logic [31:0] DUT_H_reg_3;              // Hash Register 3
logic [31:0] DUT_H_reg_4;              // Hash Register 4
logic [31:0] DUT_H_reg_5;              // Hash Register 5
logic [31:0] DUT_H_reg_6;              // Hash Register 6
logic [31:0] DUT_H_reg_7;              // Hash Register 7
logic [31:0] DUT_init_H;               // Hash Registers init
logic [31:0] DUT_update_H;             // Hash Registers update values

logic  [31:0] ByteSent;
logic  [31:0] gen_data;
logic  [31:0] word_count;
integer byte_slot;
logic  [31:0] msg_bytes_abs;

integer msg_index;
integer BIG_LOOP;

string str1;



logic  test_reset_n;
logic [7:0] test_points;

logic [31:0] msg_bit_cnt;

wire waitrequest_n;
integer wc;  
logic [31:0] msg_sch_array[0:63];
logic [31:0] msg_sch_array_2[0:63];
integer last_word;
integer      extra_msg_blk;

logic [31:0] KVal[0:63] ='{
      32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,  // 00 : 07
      32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,  // 08 : 15
      32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc, 32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,  // 16 : 23
      32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7, 32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,  // 24 : 31
      32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13, 32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,  // 32 : 39
      32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3, 32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,  // 40 : 47
      32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5, 32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,  // 48 : 55
      32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208, 32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2}; // 56 : 63

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

/***********************************************
             MONITORS 
***********************************************/
// Message Schedule RAM 1 to 4
genvar DUT_MSG_ELEM;

for (DUT_MSG_ELEM = 0; DUT_MSG_ELEM < 64; DUT_MSG_ELEM++) 
   begin : Sched_Mem_Monitor_1
     assign DUT_MSG_BLK_1[DUT_MSG_ELEM] = dut.Core_Interface.SHA_inst.sched_mem_1.mem[DUT_MSG_ELEM];
     end

for (DUT_MSG_ELEM = 0; DUT_MSG_ELEM < 64; DUT_MSG_ELEM++) 
   begin : Sched_Mem_Monitor_2
     assign DUT_MSG_BLK_2[DUT_MSG_ELEM] = dut.Core_Interface.SHA_inst.sched_mem_2.mem[DUT_MSG_ELEM];
     end

for (DUT_MSG_ELEM = 0; DUT_MSG_ELEM < 64; DUT_MSG_ELEM++) 
   begin : Sched_Mem_Monitor_3
     assign DUT_MSG_BLK_3[DUT_MSG_ELEM] = dut.Core_Interface.SHA_inst.sched_mem_3.mem[DUT_MSG_ELEM];
     end

for (DUT_MSG_ELEM = 0; DUT_MSG_ELEM < 64; DUT_MSG_ELEM++) 
   begin : Sched_Mem_Monitor_4
     assign DUT_MSG_BLK_4[DUT_MSG_ELEM] = dut.Core_Interface.SHA_inst.sched_mem_4.mem[DUT_MSG_ELEM];
     end

        
assign DUT_update_Working_Var = dut.Core_Interface.SHA_inst.update_Working_Var;								   

// DUT system clock
assign DUT_clk  = dut.Core_Interface.SHA_inst.clk;                         

// Message scedule RAM Write Enable
assign DUT_MSG_SCHED_RAM_WE = dut.Core_Interface.SHA_inst.MSG_SCHED_RAM_WE;

// RAM data select mux out
assign DUT_RAM_Data_OUT_p = dut.Core_Interface.SHA_inst.RAM_Data_OUT_p;

// Meta: Number of message bits
assign DUT_msg_bit_len = dut.Core_Interface.SHA_inst.msg_bit_len;

// Message processing start (top)
assign DUT_HASH_PROC_GO = dut.Core_Interface.SHA_inst.HASH_PROC_GO;

// SHA control state machine start signal
assign DUT_start_sha_proc = dut.Core_Interface.SHA_inst.start_sha_proc;

// SHA Process State machine busy status
assign DUT_sha_sm_busy = dut.Core_Interface.SHA_inst.sha_sm_busy;

// SHA control state machine state
assign DUT_SHA_CTRL_SM = dut.Core_Interface.SHA_inst.SHA_CTRL_SM;

// Number of message blocks remaining to be processed
assign DUT_num_msg_blks = dut.Core_Interface.SHA_inst.num_msg_blks;

//Current Track Pointer location
assign DUT_track_ptr = dut.Core_Interface.SHA_inst.track_ptr;

//Byte position of last data byte in last 32 bit word
assign DUT_byte_position = dut.Core_Interface.SHA_inst.byte_position;

//4K RAM Data in port
assign DUT_RAM_Data_IN = dut.Core_Interface.RAM_Data_IN;

//4K RAM Read address port
assign DUT_RAM_RD_Addr = dut.Core_Interface.RAM_RD_Addr;

//4K RAM Write address port
assign DUT_RAM_WR_Addr = dut.Core_Interface.RAM_WR_Addr;

//4K RAM Data out port
assign DUT_RAM_Data_OUT = dut.Core_Interface.RAM_Data_OUT;

// 4K RAM Data out to SHA process select
assign DUT_dat_sw_sel = dut.Core_Interface.SHA_inst.dat_sw_sel;

// SHA Processing state machine.
assign DUT_SHA_PROC_STATE = dut.Core_Interface.SHA_inst.SHA_PROC_STATE;

// Message schedule RAM base address
assign DUT_MSG_SCHED_RAM_WR_ADDR = dut.Core_Interface.SHA_inst.MSG_SCHED_RAM_WR_ADDR;

// K Constants ROM Data
//assign DUT_K_const_ROM_data = dut.Core_Interface.SHA_inst.K_const_ROM_data;

// Message schedule RAM base address minus two
assign DUT_T_addr_sub_2 =  dut.Core_Interface.SHA_inst.T_addr_sub_2;

// Message schedule RAM base address minus two
assign DUT_T_addr_sub_7 =  dut.Core_Interface.SHA_inst.T_addr_sub_7;

// Message schedule RAM base address minus two
assign DUT_T_addr_sub_15 =  dut.Core_Interface.SHA_inst.T_addr_sub_15;

// Message schedule RAM base address minus two
assign DUT_T_addr_sub_16 =  dut.Core_Interface.SHA_inst.T_addr_sub_16;

// Message schedule input RAM data
assign DUT_MSG_SCHED_RAM_DAT_IN = dut.Core_Interface.SHA_inst.MSG_SCHED_RAM_DAT_IN;

//Message Schedule RAM 1 to 4 input data source select
assign DUT_MSG_SCHED_DATA_SOURCE = dut.Core_Interface.SHA_inst.MSG_SCHED_DATA_SOURCE;

// Message schedule RAM #1 data output - Use this for selected message schedule word in test.
assign DUT_msg_word_picked = dut.Core_Interface.SHA_inst.dat_o_2;

// Message schedule RAM #2 data output
assign DUT_dat_o_7 = dut.Core_Interface.SHA_inst.dat_o_7;

// Message schedule RAM #3 data output
assign DUT_dat_o_15 = dut.Core_Interface.SHA_inst.dat_o_15;

// Message schedule RAM #4 data output
assign DUT_dat_o_16 = dut.Core_Interface.SHA_inst.dat_o_16;

// Rotate Right Message schedule RAM data #1 17 bits
assign DUT_ROR_WT1_17 = dut.Core_Interface.SHA_inst.ROR_WT1_17;

// Rotate Right Message schedule RAM data #1 19 bits
assign DUT_ROR_WT1_19 = dut.Core_Interface.SHA_inst.ROR_WT1_19;

//Shift Right Message schedule RAM #1 10 bits
assign DUT_SHR_WT1_10 = dut.Core_Interface.SHA_inst.SHR_WT1_10;

// Rotate Right Message schedule RAM data #3 7 bits
assign DUT_ROR_WT2_7 = dut.Core_Interface.SHA_inst.ROR_WT2_7;

// Rotate Right Message schedule RAM data #3 18 bits
assign DUT_ROR_WT2_18 = dut.Core_Interface.SHA_inst.ROR_WT2_18;

//Shift Right Message schedule RAM #3 10 bits
assign DUT_SHR_WT2_3 = dut.Core_Interface.SHA_inst.SHR_WT2_3;

// Message Schedule intermediate value #1
assign DUT_WPT1 = dut.Core_Interface.SHA_inst.WPT1;

// Message Schedule intermediate value #2
assign DUT_WPT2 = dut.Core_Interface.SHA_inst.WPT2;

//Message Schedule calculation
assign DUT_MSG_SCHED_LOGIC_OUT = dut.Core_Interface.SHA_inst.MSG_SCHED_LOGIC_OUT;

//SHA256 T1 Process rotate right e_reg 6
assign DUT_T1_ROR_E_6  = dut.Core_Interface.SHA_inst.T1_ROR_E_6;

//SHA256 T1 Process rotate right e_reg 11
assign DUT_T1_ROR_E_11 = dut.Core_Interface.SHA_inst.T1_ROR_E_11;

//SHA256 T1 Process rotate right e_reg 25
assign DUT_T1_ROR_E_25 = dut.Core_Interface.SHA_inst.T1_ROR_E_25;

//SHA256 T1 Process XOR of e_reg rotates
assign DUT_T1_ROR = dut.Core_Interface.SHA_inst.T1_ROR;

//SHA256 T1 Process XOR of e_reg rotates
assign DUT_T1_EFG = dut.Core_Interface.SHA_inst.T1_EFG;

//SHA256 sum of T1_ROR and DUT_T1_EFG
assign DUT_T1 =  dut.Core_Interface.SHA_inst.T1;

//SHA256 T2 Process rotate right a_reg 2
assign DUT_T2_ROR_A_2  = dut.Core_Interface.SHA_inst.T2_ROR_A_2;

//SHA256 T2 Process rotate right a_reg 13 
assign DUT_T2_ROR_A_13 = dut.Core_Interface.SHA_inst.T2_ROR_A_13;

//SHA256 T2 Process rotate right a_reg 22
assign DUT_T2_ROR_A_22 = dut.Core_Interface.SHA_inst.T2_ROR_A_22;

//SHA256 T2 Process XOR a_reg 2                                            
assign DUT_T2_ROR      = dut.Core_Interface.SHA_inst.T2_ROR;

//SHA256 T2 Process XOR's a_reg, b_reg and c_reg sums     
assign DUT_T2_ABC      = dut.Core_Interface.SHA_inst.T2_ABC;     
             
//SHA256 T2 sum DUT_T2_ROR and DUT_T2_ABC              
assign DUT_T2          = dut.Core_Interface.SHA_inst.T2;         

// Working Variable "A" Register
assign  DUT_a_reg = dut.Core_Interface.SHA_inst.a_reg;

// Working Variable "B" Register
assign  DUT_b_reg = dut.Core_Interface.SHA_inst.b_reg;

// Working Variable "C" Register
assign  DUT_c_reg = dut.Core_Interface.SHA_inst.c_reg;

// Working Variable "D" Register
assign  DUT_d_reg = dut.Core_Interface.SHA_inst.d_reg;

// Working Variable "E" Register
assign  DUT_e_reg = dut.Core_Interface.SHA_inst.e_reg;

// Working Variable "F" Register
assign  DUT_f_reg = dut.Core_Interface.SHA_inst.f_reg;

// Working Variable "G" Register
assign  DUT_g_reg = dut.Core_Interface.SHA_inst.g_reg;

// Working Variable "H" Register
assign  DUT_h_reg = dut.Core_Interface.SHA_inst.h_reg;

// Hash Register 0
assign  DUT_H_reg_0 = dut.Core_Interface.SHA_inst.H_reg_0;

// Hash Register 1
assign  DUT_H_reg_1 = dut.Core_Interface.SHA_inst.H_reg_1;

// Hash Register 2
assign  DUT_H_reg_2 = dut.Core_Interface.SHA_inst.H_reg_2;

// Hash Register 3
assign  DUT_H_reg_3 = dut.Core_Interface.SHA_inst.H_reg_3;

// Hash Register 4
assign  DUT_H_reg_4 = dut.Core_Interface.SHA_inst.H_reg_4;

// Hash Register 5
assign  DUT_H_reg_5 = dut.Core_Interface.SHA_inst.H_reg_5;

// Hash Register 6
assign  DUT_H_reg_6 = dut.Core_Interface.SHA_inst.H_reg_6;

// Hash Register 7
assign  DUT_H_reg_7 = dut.Core_Interface.SHA_inst.H_reg_7;

// Hash Registers init
assign  DUT_init_H   = dut.Core_Interface.SHA_inst.init_H;

// Hash Registers update values
assign  DUT_update_H = dut.Core_Interface.SHA_inst.update_H;

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

/***********************************************
   System Clock: 50 MHz w/50% duty cycle
***********************************************/
initial begin
    clk = 1;
    forever
      #10ns clk = ~clk;
end


/***********************************************
   System Reset: 
***********************************************/
initial begin
    reset_n     <=   1'b0;
    #50 reset_n <=   1'b1;
end


/**********************************************************
   DUT interface
   - Avalon bus w/12 bit Address, 32 bit data
**********************************************************/
SHA256_top dut(
     .TST_OUT(),
     .clk(clk),                        // input
     .reset_n(reset_n & test_reset_n), // input
     .address(address),                // input   [11:00]
     .lock(lock),                      // input  
     .read(read),                      // input
     .readdata(readdata),              // output  [31:00]
     .response(response),              // output    [1:0]
     .waitrequest_n(waitrequest_n),                 // output
     .write(write),                    // input
     .writedata(writedata),            // input   [31:00]
     .test_bus(test_points)
);

//typedef packet#() packet4_t[4];
 
/**********************************************************
   Avalon RD/WR Interface tasks
**********************************************************/
  //Avalon Slave Write
   task BUS_WR;
      input [31:0] wr_add;
      input [31:0] wr_data;
      begin
         @ (posedge clk);
         //address <= wr_add[13:0];
         address <= wr_add[15:2]; // Changed for Nios interface
         write   <= 1'b1;
         read    <= 1'b0;
         writedata <= wr_data;
         #1 lock <= 1'b0;
         while (waitrequest_n == 0)
           begin
            //@ (posedge clk);
            #1;
           end
         write <= 1'b0;
         read  <= 1'b0;
         @ (posedge clk);
      end
   endtask //AVALON_WR
  

//  Avalon Slave Read
   task BUS_RD;
      input [31:0] addr;
      output [31:0] data;
      begin
         #1;
         @ (posedge clk);
         //address <= addr[13:0]; 
         address <= addr[15:2]; // Changed for Nios interface
         write   <= 1'b0;
         read    <= 1'b1;
         #1 lock <= 1'b0;
         while (waitrequest_n == 0) // from slave
           begin
            @ (posedge clk);
           end
         read  <= 1'b0;
         #1 data  <= readdata;
         @ (posedge clk);
      end
   endtask // AVALON_RD


//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
/*******************************************************************

   BEGIN:  MAIN TEST PROCESS

********************************************************************/
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

initial begin
test_reset_n = 1'b1;

for (test_cntr = 50; test_cntr < 127; test_cntr++)
   begin
      test_loop(test_cntr);
      // Local DUT reset control
       test_reset_n = 1'b0;
       #50;
       test_reset_n = 1'b1;
       #50;       
      end      
   $stop();
end











task  test_loop; 
   input integer PARAM1; 
   logic [31:0] msg_sch_calc[][0:63];
   logic [31:0] hash_calc[][0:7];

begin  

// Set up time stamp format
$timeformat(-6, 3, " us", 5);
  
// Init scratch variables 
i = 0;   j = 0;   k = 0;   n = 0;


//Init error counter
err = 0;

// Generic done bit
done = 0;

// RTL Processing loop
BIG_LOOP = 0;
#1;

//Console Display
$display ("SHA256 Core TEST - Byte count = %0d:  START @(%0t)", PARAM1, $realtime );


$sformat(str1, "test_results_%0d.dat",PARAM1);

//Open test results output file.
TESTFILE = $fopen(str1, "w");


$fwrite(TESTFILE,"-----------------------------------------------------\n");
$fwrite(TESTFILE,"-                                                   -\n");
$fwrite(TESTFILE,"-        BEGIN  SHA256 VERIFICATION TEST            -\n");
$fwrite(TESTFILE,"-                                                   -\n");
$fwrite(TESTFILE,"-----------------------------------------------------\n");
$fwrite(TESTFILE, "\n");

//$fwrite(TESTFILE," Current System Time is %s\n",get_time());

/******************************************************
   Wait for reset to de-assert
******************************************************/
wait(reset_n == 1);
repeat (2) @ (posedge clk);

/****************************************************************************
BEGIN: SHA256 CALCULATION  - Refer to NIST Pub. FIPS-180

SHA256 divides a given message into an integer quantity of fixed size message
blocks of 16 words or 64 bytes. Each message block is "expanded" from 16 words 
to 64 words which is then hashed to produce an array 8 words (HASH[0:7]). The 
process is repeated sequentially for each message block with the previous hash 
added. All addition is modulo 2^32.

Message Formatting
-------------------
Given a message M, format it into n message blocks consisting of 16, 32 bit
words or 64 bytes. Word data is big endian ordered.

If the last block, M(n), contains less than 56 bytes then the final byte + 1
will contain 0x80 (required '1' appendage for last byte) and zero padding
through byte 56. 

Of the specified 8 bytes alloted for message bit size count, only the last 
4 bytes [60:64] will contain the bit count of the message for this 
implementation.

If the last message block M(n) contains 56 to 63 bytes, 0x80 is appended 
and the remaining bytes are zero-padding. In this case extra block M(n+1) 
is created. M(n+1) is zero padded up to its last 4 bytes, [60:64], will 
contain the bit count. 

If M(n) uses all 64 bytes, the first byte of M(n+1) first byte is set to 
0x80. M(n+1) is zero padded up to its last 4 bytes [60:64], which will 
contain the bit count.


Messsage Schedule Generation
----------------------------
Each message block of M is expanded from 16 words to 64 words algorithmically.


SHA256 Hash Generation
----------------------   
Upon completion of the message schedule expansion, it's result is processed
into final or intermediate eight word hash result. 

****************************************************************************/
$fwrite(TESTFILE,"-----------------------------------------------------------\n");
$fwrite(TESTFILE,"- 1) Generate Test Data from PRNG source                  -\n");
$fwrite(TESTFILE,"- 2) Calculate SHA256 HASH and obtain known good result   -\n");
$fwrite(TESTFILE,"- 3) Use test data for DUT testing                        -\n");
$fwrite(TESTFILE,"- 4) Read Hash from DUT and compare known good result     -\n");
$fwrite(TESTFILE,"-----------------------------------------------------------\n");

/****************************************************************************
Variable Definitions
--------------------
x:                Number of bytes in message M (a non-zero natural number)
word_count:       Number of words in message M (a zero-indexed natural number)
byte_slot:        Byte location in word of M (0->[31:24], 1->[23:16], 
                  2->[15:8], 3->[7:0]
msg_blocks:       Number of 64 byte message blocks M[0:N]
msg_bit_cnt:      Number of bits in M, Number of bytes X 8

gen_data:         Intermediate test data variable (32 bits)
test_msg_block[]: Array of generated data

i:                Message Block word boundary (0, 16, 32)
j:                Zero paddding variable (word) for current message block

msg_index:        Current message block M(n) in processes
k:                Zero Padding offset from last word to bit field word 

****************************************************************************/
/* Number of bytes in message (a non-zero natural number) */
//for (x=1; x < 248; x++) begin // 256 bytes minus 8 bytes in last blocks word 14 and 15 (bit size)
/*************************************************
    BEGIN:     CONSTANT DATA
*************************************************/
x               =    PARAM1;       // <- SET BYTE COUNT FOR ENTIRE TEST HERE                

ByteSent        =    x - 1;                          // # of message bytes, modify offset 

msg_bytes_abs   =    x;                              // Value of x used to calculate bit count

word_count      =    {2'b00, ByteSent[31:2]};        // Number of 32 bit words 

byte_slot       =    ByteSent % 4;                   // Last byte word slot number

msg_blocks      =    {6'b00_0000, ByteSent[31:6]};   // Number of message blocks 1 indexed

msg_bit_cnt     =    {msg_bytes_abs[28:0], 3'b000};  // Bit count word


msg_sch_calc = new[msg_blocks];
hash_calc    = new[msg_blocks];


// Simple PRNG generates test data
// Seed value for test data
gen_data = 32'h12345678;

for (y = 0; y < 4096; y++) begin
   gen_data              =  {gen_data[0], gen_data[31:1]};
   test_msg_block[y]     =   gen_data;
   DUT_test_msg_block[y] =   gen_data; // Save a copy for DUT
   end


// Report Constants
$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "SHA256 Constants for M:\n");
$fwrite (TESTFILE, "-----------------------\n");
$fwrite (TESTFILE, "Set Byte Count = %0d \n", x);
$fwrite (TESTFILE, "Message Block Range M[0:%0d] \n", msg_blocks);
$fwrite (TESTFILE, "Word Range = W[0:%0d] \n", word_count);
$fwrite (TESTFILE, "Last Byte Location = M[%0d], W[%0d][%0d] \n", msg_blocks, (word_count%16), byte_slot);


// Write out Message block
$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "Message Data Set M:\n");
$fwrite (TESTFILE, "-------------------\n");
for (i = 0; i < word_count + 1; i++) 
   begin
      if (i < 8 ) begin
         $fwrite(TESTFILE, " %08h  ", test_msg_block[i] );
         end
      else if ((i >= 8) & (i % 8 == 0)) begin
         $fwrite(TESTFILE, "\n %08h  ", test_msg_block[i] );
         end
      else begin
         $fwrite(TESTFILE, " %08h  ", test_msg_block[i] );
         end
      end         
$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "-----------------\n");
/*************************************************
    END:     CONSTANT DATA
*************************************************/

// Initialize hash array (FIPS-180 sec 6.2.2)
for (y = 0; y < 8; y++) begin
   HASH[y] = HASH_ini[y];
   end

//Initialize word count variable
wc  =  word_count + 1'b1;

/********************************************************************
 BEGIN:    CALCULATE MESSAGE SCHEDULE AND HASH FOR M(N)
********************************************************************/
k = 0;
n = wc; //Word index tracking variable, down count

for (m = msg_blocks; m >= 0; m--)
  begin


  // Print out the 16 word message block n of M
  $fwrite(TESTFILE, "\n");
  $fwrite(TESTFILE, "MESSAGE M[%0d]: \n", k );
  $fwrite(TESTFILE, "----------------\n");
  for (i = 0; ((i < 16) & (n != 0)); i++) 
     begin
        if (i < 8 ) begin
           $fwrite(TESTFILE, " %08h  ", test_msg_block[i + (k*16)] );
           n--;
           end
        else if ((i >=8) & (i%8 == 0)) begin
           $fwrite(TESTFILE, "\n %08h  ", test_msg_block[i + (k*16)] );
           n--; 
           end
        else begin
           $fwrite(TESTFILE, " %08h  ", test_msg_block[i + (k*16)] );
           n--; 
           end
        end         

   // Clear the message schedule array
   for (i = 0; i < 64; i++) 
      begin
         msg_sch_array[i] = 32'h0000_0000;
         end

   // Copy up to 16 words to test array
   for (i = 0; i < 16; i++) 
      begin
         msg_sch_array[i] = (wc--  >  0) ? test_msg_block[j++] : 32'h0000_0000;
         if (wc == 0) break;
         end 

   // Messsage Schedule calculation function
   msg_sched( i,                   // input   integer      last_word_loc, 
              msg_sch_array,       // inout   logic [31:0] msg_sch_array[0:63],
              msg_sch_array_2,     // output  logic [31:0] msg_sch_array_2[0:63],
              byte_slot,           // input   integer      byte_slot,
              msg_bit_cnt,         // input   logic [31:0] msg_bit_cnt,
              m,                   // input   logic [31:0] msg_blocks,
              TESTFILE,            // input   integer      FP,
              extra_msg_blk        // output  integer      extra_msg_blk
                              );




  // Copy this message block for comparison in RTL test
  for (i=0; i<64; i++) begin
      msg_sch_calc[m][i] = msg_sch_array[i];
      end
      
      
      
  msg_sch_calc[][0:63];
  $fwrite(TESTFILE, "\n\n");   
  $fwrite(TESTFILE, "MESSAGE SCHEDULE FOR M[%0d]:  \n", k );
  $fwrite(TESTFILE, "------------------------------\n");
  for (i = 0; i < 64; i++) 
     begin
        if (i < 8) begin
           $fwrite(TESTFILE, " %08h  ", msg_sch_array[i] );
           end
        else if ((i >=8) & (i%8 == 0)) begin
           $fwrite(TESTFILE, "\n %08h  ", msg_sch_array[i] );
           end
        else begin
           $fwrite(TESTFILE, " %08h  ", msg_sch_array[i] );
           end
        end         
   
   //Hash interation for above message schedule
   hash_proc( msg_sch_array,  //input logic [31:0] msg_sch[0:63],
              HASH            //inout logic [31:0] HASH [0:7]
                            );

  // Copy this message block for comparison in RTL test
  for (i = 0; i < 8; i++) begin
      hash_calc[m][i] = HASH[i];
      end

   $fwrite(TESTFILE, "\n\n");
   $fwrite(TESTFILE, "HASH CALCULATION FOR M[%0d]:  \n", k );
   $fwrite(TESTFILE, "-------------------------------\n");
   for (i = 0; i < 8; i++) begin
      $fwrite(TESTFILE, "HASH[%0d]:  %08h\n", i, HASH[i]);
      end

   $fwrite(TESTFILE, "\n");   
   if (extra_msg_blk) begin
      $fwrite(TESTFILE, "EXTENDED MESSAGE SCHEDULE FOR M[%0d]:  \n", k );
      $fwrite(TESTFILE, "-------------------------------------------\n");
      for (i = 0; i < 64; i++) 
         begin
            if (i < 8 ) begin
              $fwrite(TESTFILE, " %08h  ", msg_sch_array_2[i] );
              end
            else if ((i >= 8) & (i % 8 == 0)) begin
              $fwrite(TESTFILE, "\n %08h  ", msg_sch_array_2[i] );
              end
            else begin
              $fwrite(TESTFILE, " %08h  ", msg_sch_array_2[i] );
              end
        end         
   
      hash_proc( msg_sch_array_2,  HASH);
            
      end
   
k++; // Increment message pointer
end // FOR LOOP


$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "SHA256 Hash Calculation for M:\n");
$fwrite (TESTFILE, "------------------------------\n");
for (i = 0; i < 8; i++)
   begin
   $fwrite (TESTFILE, "HASH[%0d] = %08h\n", i, HASH[i]);
   TB_HASH[i] = HASH[i];
   end

$fwrite (TESTFILE, "\n\n");
/*****************************************************************************
 END:    CALCULATE MESSAGE SCHEDULE AND HASH FOR M(N)
*****************************************************************************/




/*****************************************************************************
BEGIN: DUT Testing
The hash table has been calculated for test data. Next we send the same data 
to the DUT.
*****************************************************************************/
$fwrite (TESTFILE, "----------------------------------------\n");
$fwrite (TESTFILE, "   ----->   BEGIN: RTL TESTING  <-----  \n");
$fwrite (TESTFILE, "----------------------------------------\n");
$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "Write message and message size to DUT...\n\n");

// Modify Byte count
ByteSent   =   ByteSent + 1;

// Point to start of RAM
AVAAddr    =   32'h0000_0000;  // Point to begining of DUT RAM

/************************************************
   Send the test message to DUT over Avalon Bus
************************************************/
for (i = 0; i < word_count + 1; i++)
   begin
    AVAData = DUT_test_msg_block[i];
    BUS_WR(AVAAddr, AVAData);
    AVAAddr += 4;
    @(posedge clk);
    end
$fwrite (TESTFILE, "-> MESSAGE WRITTEN TO DUT RAM: %0d words [0:%0d] @(%0t)\n\n", word_count+1, word_count, $time);
@(posedge clk);

/************************************************
    Write messsage size over Avalon Bus
************************************************/
AVAAddr =  32'h0000_3F04;
AVAData =  ByteSent;
BUS_WR(AVAAddr, AVAData);
$fwrite (TESTFILE, "-> MESSAGE SIZE SENT: %0d bytes [0:%0d] @(%0t)\n\n",ByteSent, ByteSent-1, $time);
@(posedge clk);

/**********************************************************
* Write processing start bit, a time-out detect is set up 
* here. 
**********************************************************/
$fwrite (TESTFILE, "-> START BIT WRITTEN TO DUT COMMAND REG. @(%0t)\n\n", $time);
fork
    AVAAddr = 32'h0000_3F00;
    AVAData = 32'h0000_0001;
    BUS_WR(AVAAddr, AVAData);
join_none

// Bus Time-out timer
for (i = 0; i < 200; i++) begin
   #1; 
   if (DUT_HASH_PROC_GO == 1'b1) begin
      $fwrite (TESTFILE, "-> HASH_PROC_GO ASSERTED @(%0t)\n", $time);
      @(negedge DUT_HASH_PROC_GO);
      break;
      end
end

// Bus timer exceeded?
if (i == 200) begin
      $fwrite (TESTFILE, "FAIL: HASH_PROC_GO NOT ASSERTED @(%0t)\n", $time);
      $stop();
      end

/***********************************************
    ----->     RTL TEST PROCESS     <-----  
************************************************/  
// Initialize Hash Values 
for (i = 0; i < 8; i++) 
   begin
     HASH[i] = HASH_ini[i];
     end     

/***********************************************
 BIG LOOP: This verifies the DUT processing
           of the message blocks.
************************************************/  
for (BIG_LOOP = 0; BIG_LOOP <= (msg_blocks + extra_msg_blk) ; BIG_LOOP++)
begin     
     /****************************************************************
     *  PART 1 - MESSAGE SCHEDULE CALCULATION
     *  - Verify Message schedule RAM locations 0 to 15 are match 
     *    test bench modeling above.
     *  - Copy the current message block from the DUT's message RAM
     *    to the test bench.
     *  - Cycle verify the message schedule process.
     ****************************************************************/
     $fwrite(TESTFILE, "\n");
     $fwrite(TESTFILE, "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*\n");
     $fwrite(TESTFILE, "*            BEGIN: MESSAGE SCHEDULE CALCULATION            *\n");
     $fwrite(TESTFILE, "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*\n");
     $fwrite(TESTFILE, "\n");
     for (i = 0; i < 64; i++) begin  // The Message schedule RAM is 64 words long, "i" word index

        // Wait for a message word to get loaded in schedule RAM
        if (i < 15) begin  // Load first 16 words (M[N])
           wait (DUT_SHA_PROC_STATE == 4'hE);  // RAM loaded here
           @(negedge clk);
           end
        else if (i == 15) begin  // Last word (M[N]) from RAM to message schedule
           wait (DUT_SHA_PROC_STATE == 4'h4);  // RAM loaded here
           @(negedge clk);
           end

        /***************************************************************************************************
        // Check if this word contains 0x80. The message block contains 64 bytes, if "i" is pointing to 
        // the last byte in the message i + 1 should contain 0x80. If i is 56 to 64, an extra message
        // block is required
        ***************************************************************************************************/
//        if  (((i == ByteSent[31:2] % 16) & (BIG_LOOP == msg_blocks)) & ((ByteSent % 64) <= 56))           
        if  (((i == ByteSent[31:2] % 16) & (i >= 1)) & (BIG_LOOP == msg_blocks))                 
           begin // Word 0 to 15
             case (ByteSent % 4) // Bytes 0 to 3
               0:      begin if (DUT_MSG_BLK_1[i][31:24] != 8'h80) begin
                                $fwrite (TESTFILE, "FAIL: DUT_MSG_BLK_1[%0d][31:24] - Expected 0x80 , Actual 0x%02h \n", i, DUT_MSG_BLK_1[i][31:24]);
                                err++;
                                end end
               1:      begin if (DUT_MSG_BLK_1[i][23:16] != 8'h80) begin
                                $fwrite (TESTFILE, "FAIL: DUT_MSG_BLK_1[%0d][23:16] Expected 0x80 , Actual 0x%02h \n", i, DUT_MSG_BLK_1[i][23:16]);
                                err++;
                                end end
               2:      begin if (DUT_MSG_BLK_1[i][15:8] != 8'h80) begin
                                $fwrite (TESTFILE, "FAIL: DUT_MSG_BLK_1[%0d][23:16] Expected 0x80 , Actual 0x%02h \n", i, DUT_MSG_BLK_1[i][15:8]);
                                err++;
                                end end
               3:      begin if (DUT_MSG_BLK_1[i][7:0] != 8'h80) begin
                                $fwrite (TESTFILE, "FAIL: DUT_MSG_BLK_1[%0d][7:0] Expected 0x80 , Actual 0x%02h \n", i, DUT_MSG_BLK_1[i][7:0]);
                                err++;
                                end end
               default:   $fwrite (TESTFILE, "ILLEGAL STATE\n");
             endcase
           end
        else if ((DUT_MSG_BLK_1[i] != msg_sch_calc[BIG_LOOP][i]) & (i < (ByteSent[31:2] % 16))) begin
           $fwrite (TESTFILE, "FAIL: MSG SCH RAM LOAD: MSG_BLK[%0d] -> DUT ACTUAL = 0x%08h  , EXPECTED = 0x%08h\n", i, msg_sch[i], msg_sch_calc[BIG_LOOP][i]);
           err++;
           end

        // Wait for DUT state machine (ToDo: Time-out cond. needed here too)
        if (i < 15) begin
           wait (DUT_SHA_PROC_STATE == 4'h1);   
           end
        else if (i == 15) begin
           wait (DUT_SHA_PROC_STATE == 4'hC);
           end      

         // Copy the message block M[n] to the test bench as it's loaded into
         // the DUT message schedule RAM. There will be a cycle accurate  
         if (i <= 15) begin  
           if (msg_sch[i] ==  
           msg_sch[i] = DUT_MSG_BLK_1[i]; // Load local test array with DUT data for processing
           end




        // Monitor and verify message schedule is correctly processed.
        // Note         
           if (i > 15 )begin
              ROR_WT1_17            = {msg_sch[i-2][16:0], msg_sch[i-2][31:17]};
              ROR_WT1_19            = {msg_sch[i-2][18:0], msg_sch[i-2][31:19]};
              SHR_WT1_10            = {10'h000, msg_sch[i-2][31:10]};

              if (ROR_WT1_17 != DUT_ROR_WT1_17) begin
                 $fwrite (TESTFILE, "FAIL: MSG SCH[%0d]: ROR_WT1_17 -> DUT ACTUAL: 0x%08h   EXPECTED: 0x%08h\n", i, DUT_ROR_WT1_17, ROR_WT1_17);
                 err++;
                 end
        
              if (ROR_WT1_19 != DUT_ROR_WT1_19) begin
                 $fwrite (TESTFILE, "FAIL: MSG SCH[%0d]: ROR_WT1_19 -> DUT ACTUAL: 0x%08h   EXPECTED: 0x%08h\n", i, DUT_ROR_WT1_19, ROR_WT1_19);
                 err++;
                 end
                 
              if (SHR_WT1_10 != DUT_SHR_WT1_10) begin
                 $fwrite (TESTFILE, "FAIL: MSG SCH[%0d]: SHR_WT1_10 -> DUT ACTUAL: 0x%08h   EXPECTED: 0x%08h\n", i, DUT_SHR_WT1_10, SHR_WT1_10);
                 err++;
                 end
         
              ROR_WT2_7             = {msg_sch[i-15][6:0],  msg_sch[i-15][31:7]};
              ROR_WT2_18            = {msg_sch[i-15][17:0], msg_sch[i-15][31:18]};
              SHR_WT2_3             = {3'b000, msg_sch[i-15][31:3]};
              
              if (ROR_WT2_7 != DUT_ROR_WT2_7) begin
                 $fwrite (TESTFILE, "FAIL: MSG SCH[%0d]: ROR_WT2_7 -> DUT ACTUAL: 0x%08h   EXPECTED: 0x%08h\n", i, DUT_ROR_WT2_7, ROR_WT2_7);
                 err++;
                 end
     
              if (ROR_WT2_18 != DUT_ROR_WT2_18) begin
                 $fwrite (TESTFILE, "FAIL: MSG SCH[%0d]: ROR_WT2_18 -> DUT ACTUAL: 0x%08h   EXPECTED: 0x%08h\n", i, DUT_ROR_WT2_18, ROR_WT2_18);
                 err++;
                 end
              
              if (SHR_WT2_3 != DUT_SHR_WT2_3) begin
                 $fwrite (TESTFILE, "FAIL: MSG SCH[%0d]: SHR_WT2_3 -> DUT ACTUAL: 0x%08h   EXPECTED: 0x%08h\n", i, DUT_SHR_WT2_3, SHR_WT2_3);
                 err++;
                 end
              
              //$fwrite (TESTFILE, "MSG SCH RAM LOC[%0d]: ROR_WT1_7  = 0X%08h, ROR_WT1_18 = 0X%08h, SHR_WT1_3  = 0X%08h\n",i, ROR_WT2_7, ROR_WT2_18, SHR_WT2_3);
                                    
              WPT1    = msg_sch[i-7]  + (ROR_WT1_17 ^ ROR_WT1_19 ^ SHR_WT1_10);
              WPT2    = msg_sch[i-16] + (ROR_WT2_7  ^ ROR_WT2_18 ^ SHR_WT2_3);
     
              if (WPT1 != DUT_WPT1) begin
                 $fwrite (TESTFILE, "FAIL: MSG SCH[%0d]: WPT1 -> DUT ACTUAL: 0x%08h   EXPECTED: 0x%08h\n", i, DUT_WPT1, WPT1);
                 err++;
                 end
     
              if (WPT2 != DUT_WPT2) begin
                 $fwrite (TESTFILE, "FAIL: MSG SCH[%0d]: WPT2 -> DUT ACTUAL: 0x%08h   EXPECTED: 0x%08h\n", i, DUT_WPT2, WPT2);
                 err++;
                 end
     
              MSG_SCHED_LOGIC_OUT   =    WPT1 + WPT2;
              wait (DUT_MSG_SCHED_RAM_WE == 4'h1);   
              @(negedge clk);
     
              if (MSG_SCHED_LOGIC_OUT != DUT_MSG_SCHED_LOGIC_OUT) begin
                 $fwrite (TESTFILE, "FAIL: MSG SCH[%0d]: MSG_SCHED_LOGIC_OUT -> DUT ACTUAL: 0x%08h   EXPECTED: 0x%08h\n", i, DUT_MSG_SCHED_LOGIC_OUT, MSG_SCHED_LOGIC_OUT);
                 err++;
                 end
     
              msg_sch[i] = MSG_SCHED_LOGIC_OUT;
     
              // Finish this round
              if (i < 63) begin // Continue creating message schedule
                 wait (DUT_SHA_PROC_STATE == 4'h4);
                 @(negedge clk);
                 @(negedge clk);
                 end
              else if (i == 63) begin // Done, wait for exit state
                 wait (DUT_SHA_PROC_STATE == 4'h5);
                 @(negedge clk);
                 end
           end
     
     end  //for loop

     $fwrite (TESTFILE, "\n");
     $fwrite (TESTFILE, "DUT Message Schedule Calculation Results \n");
     $fwrite (TESTFILE, "-----------------------------------------\n");
     p = err;
      for (i = 0; i < 64; i++) begin
         if (msg_sch_calc[BIG_LOOP][i] != DUT_MSG_BLK_1[i]) begin
            $fwrite(TESTFILE, "FAIL: Message block %0d , word %0d - Actual: %08h , Expected: %08h\n", BIG_LOOP, i, DUT_MSG_BLK_1[i], msg_sch_calc[BIG_LOOP][i]);
            err++;
            end
         else begin
            $fwrite(TESTFILE, "DUT MSG RAM[%0d] = 0x%08h\n", i, DUT_MSG_BLK_1[i]);
            end
         end         
      if (p == err) begin
         $fwrite(TESTFILE, "PASS: Message schedule calculation and DUT compare \n");
         end

     
     // Report
     $fwrite (TESTFILE, "\n");
     $fwrite (TESTFILE, "Message Schedule Calculation Summary\n");
     $fwrite (TESTFILE, "------------------------------------\n");
     if (err > 0 ) begin
         $fwrite(TESTFILE, "FAIL:     Message schedule compare failed, error count = %0d \n",err);
         end
     else begin
         $fwrite(TESTFILE, "PASSED:   Message schedule compare, error count = %0d \n",err); 
         end 
     $fwrite (TESTFILE, "\n");


     /****************************************************************
     *  END:    Message Schedule calculation
     *  - Verify Message schedule RAM location 0 to 15 are loaded   
     ****************************************************************/


     /*************************************************
     *  BEGIN:    HASH CALCULATION
     *************************************************/
     $fwrite (TESTFILE, "-------------------------------------------\n");
     $fwrite (TESTFILE, "----->    Begin Hashing Operation    <-----\n");
     $fwrite (TESTFILE, "-------------------------------------------\n");
     
     // Initialize Working Variables with previous or initial hash values
     a_reg  =  HASH[0];
     b_reg  =  HASH[1];
     c_reg  =  HASH[2];
     d_reg  =  HASH[3];
     e_reg  =  HASH[4];
     f_reg  =  HASH[5];
     g_reg  =  HASH[6];
     h_reg  =  HASH[7];
     
     // 64 Rounds
     for (j = 0; j < 64; j++) begin 
     
     /**************************************************
       HASH CALC:  T1 part
     **************************************************/  
     $fwrite (TESTFILE, "------------------------------------\n");
     $fwrite (TESTFILE, "--->   Hash Round %0d   <---        \n",j);
     $fwrite (TESTFILE, "------------------------------------\n");
     
         // Working variable update rising edge
     	@(posedge DUT_update_Working_Var);
     
         K_val          =  KVal[j];
         msg_word_picked = msg_sch[j];
     
         $fwrite (TESTFILE, "K Value  =  %08h \n",K_val);
         $fwrite (TESTFILE, "MSG SCH Value  =  %08h \n",msg_word_picked);
         $fwrite (TESTFILE, "\n");
     
         T1_ROR_E_6  = {e_reg[5:0]  ,e_reg[31:6]};   //ROR(6)
         if (T1_ROR_E_6 != DUT_T1_ROR_E_6) begin
             $fwrite (TESTFILE, "ERROR: T1_ROR_E_6  -> Actual: %08h    Expected: %08h\n" ,DUT_T1_ROR_E_6, T1_ROR_E_6);
             $fwrite (TESTFILE, "                       T1_ROR_E_6 = {e_reg[5:0] ,e_reg[31:6]} \n");
             $fwrite (TESTFILE, "                       e_reg[5:0]   -> Actual = 0b%6b,   Expected = 0b%6b  \n",  DUT_e_reg[5:0],   e_reg[5:0]);
             $fwrite (TESTFILE, "                       e_reg[31:6]  -> Actual = 0b%26b,   Expected = 0b%26b  \n",  DUT_e_reg[31:6],  e_reg[31:6]);
             err++;
             end
         
         T1_ROR_E_11 = {e_reg[10:0] ,e_reg[31:11]};  //ROR(11)
         if (T1_ROR_E_11 != DUT_T1_ROR_E_11) begin
             $fwrite (TESTFILE, "ERROR: T1_ROR_E_11  -> Actual: %08h    Expected: %08h\n" ,DUT_T1_ROR_E_11, T1_ROR_E_11);
             $fwrite (TESTFILE, "                       T1_ROR_E_25 = {e_reg[10:0] ,e_reg[31:11]} \n");
             $fwrite (TESTFILE, "                       e_reg[10:0]   -> Actual = 0b%11b,   Expected = 0b%11b  \n",  DUT_e_reg[10:0],   e_reg[10:0]);
             $fwrite (TESTFILE, "                       e_reg[31:11]  -> Actual = 0b%21b,   Expected = 0b%21b  \n",  DUT_e_reg[31:11],  e_reg[31:11]);
             err++;
             end
         
         T1_ROR_E_25 = {e_reg[24:0] ,e_reg[31:25]};  //ROR(25)
         if (T1_ROR_E_25 != DUT_T1_ROR_E_25) begin
             $fwrite (TESTFILE, "ERROR: T1_ROR_E_25  -> Actual: %08h    Expected: %08h\n",DUT_T1_ROR_E_25, T1_ROR_E_25);
             $fwrite (TESTFILE, "                       T1_ROR_E_25 = {e_reg[24:0] ,e_reg[31:25]} \n");
             $fwrite (TESTFILE, "                       e_reg[24:0]   -> Actual = 0b%25b,  Expected = 0b%25b  \n", DUT_e_reg[24:0],   e_reg[24:0]);
             $fwrite (TESTFILE, "                       e_reg[31:25]  -> Actual = 0b%7b,   Expected = 0b%7b  \n",  DUT_e_reg[31:25],  e_reg[31:25]);
             err++;
             end
         
         T1_ROR      = T1_ROR_E_6 ^ T1_ROR_E_11 ^ T1_ROR_E_25;
         if (T1_ROR != DUT_T1_ROR) begin
             $fwrite (TESTFILE, "ERROR: T1_ROR  -> Actual: %08h    Expected: %08h\n" ,DUT_T1_ROR, T1_ROR);
             $fwrite (TESTFILE, "                  T1_ROR  = T1_ROR_E_6 ^ T1_ROR_E_11 ^ T1_ROR_E_25\n");
             $fwrite (TESTFILE, "                  T1_ROR_E_6    -> Actual = %08h, Expected =  %08h\n", DUT_T1_ROR_E_6  , T1_ROR_E_6  );
             $fwrite (TESTFILE, "                  T1_ROR_E_11   -> Actual = %08h, Expected =  %08h\n", DUT_T1_ROR_E_11 , T1_ROR_E_11 );
             $fwrite (TESTFILE, "                  T1_ROR_E_25   -> Actual = %08h, Expected =  %08h\n", DUT_T1_ROR_E_25 , T1_ROR_E_25 );
             err++;
             end
         
         T1_EFG      = ((e_reg & f_reg) ^ (~e_reg & g_reg));
         if (T1_EFG != DUT_T1_EFG) begin
             $fwrite (TESTFILE, "ERROR: T1_EFG  -> Actual: %08h    Expected: %08h\n",DUT_T1_EFG, T1_EFG);
             $fwrite (TESTFILE, "                  T1_EFG  = ((e_reg & f_reg) ^ (~e_reg & g_reg))\n");		
             $fwrite (TESTFILE, "                  e_reg   -> Actual = %08h, Expected =  %08h\n",	 DUT_e_reg ,  e_reg );
             $fwrite (TESTFILE, "                  f_reg   -> Actual = %08h, Expected =  %08h\n",	 DUT_f_reg ,  f_reg );
             $fwrite (TESTFILE, "                  ~e_reg  -> Actual = %08h, Expected =  %08h\n",	~DUT_e_reg , ~e_reg );
             $fwrite (TESTFILE, "                  g_reg   -> Actual = %08h, Expected =  %08h\n",	 DUT_g_reg ,  g_reg );
             err++;
             end
             
         T1          =  h_reg + T1_ROR + T1_EFG + msg_word_picked + K_val; // Hash process PT 1 output       
         if (T1 != DUT_T1) begin
             $fwrite (TESTFILE, "ERROR: T1  -> Actual: %08h    Expected: %08h\n" ,DUT_T1, T1);
             $fwrite (TESTFILE, "              T1 = h_reg + T1_ROR + T1_EFG + msg_word_picked + K_val\n");		
             $fwrite (TESTFILE, "              h_reg           -> Actual = %08h, Expected =  %08h\n", DUT_h_reg, h_reg);
             $fwrite (TESTFILE, "              T1_ROR          -> Actual = %08h, Expected =  %08h\n", DUT_T1_ROR, T1_ROR);
             $fwrite (TESTFILE, "              T1_EFG          -> Actual = %08h, Expected =  %08h\n", DUT_T1_EFG, T1_EFG);
             $fwrite (TESTFILE, "              msg_word_picked -> Actual = %08h, Expected =  %08h\n", DUT_msg_word_picked, msg_word_picked);
             err++;
             end
     
     /**************************************************
        HASH CALC:  T2 part
     **************************************************/  
         T2_ROR_A_2  = {a_reg[1:0]  ,a_reg[31:2]};	
         if (T2_ROR_A_2 != DUT_T2_ROR_A_2) begin
             $fwrite (TESTFILE, "ERROR: T2_ROR_A_2  -> Actual: %08h    Expected: %08h\n" ,DUT_T2_ROR_A_2, T2_ROR_A_2);
     		 $fwrite (TESTFILE, "                       T2_ROR_A_2  = {a_reg[1:0]  ,a_reg[31:2]}\n");
             $fwrite (TESTFILE, "                       a_reg[1:0]   -> Actual = 0b%2b,    Expected = 0b%2b  \n",  DUT_a_reg[1:0],   a_reg[1:0]);
             $fwrite (TESTFILE, "                       a_reg[31:2]  -> Actual = 0b%30b,   Expected = 0b%30b  \n",  DUT_a_reg[31:2],  a_reg[31:2]);
             err++;
             end
         
         T2_ROR_A_13 = {a_reg[12:0] ,a_reg[31:13]};
         if (T2_ROR_A_13 != DUT_T2_ROR_A_13) begin
             $fwrite (TESTFILE, "ERROR: T2_ROR_A_13  -> Actual: %08h    Expected: %08h\n" ,DUT_T2_ROR_A_13, T2_ROR_A_13);
     		 $fwrite (TESTFILE, "                       T2_ROR_A_13  = {a_reg[12:0]  ,a_reg[31:13]}\n");
             $fwrite (TESTFILE, "                       a_reg[12:0]   -> Actual = 0b%13b,    Expected = 0b%13b  \n",  DUT_a_reg[12:0],   a_reg[12:0]);
             $fwrite (TESTFILE, "                       a_reg[31:13]  -> Actual = 0b%19b,    Expected = 0b%19b  \n",  DUT_a_reg[31:13],  a_reg[31:13]);
             err++;
             end
         
         T2_ROR_A_22 = {a_reg[21:0] ,a_reg[31:22]};
         if (T2_ROR_A_22 != DUT_T2_ROR_A_22) begin
             $fwrite (TESTFILE, "ERROR: T2_ROR_A_22  -> Actual: %08h    Expected: %08h\n" ,DUT_T2_ROR_A_22, T2_ROR_A_22);
     		$fwrite (TESTFILE, "                       T2_ROR_A_22  = {a_reg[21:0]  ,a_reg[31:22]}\n");
             $fwrite (TESTFILE, "                       a_reg[21:0]   -> Actual = 0b%23b,    Expected = 0b%23b \n",  DUT_a_reg[21:0],   a_reg[21:0]);
             $fwrite (TESTFILE, "                       a_reg[31:22]  -> Actual = 0b%9b,     Expected = 0b%9b  \n",  DUT_a_reg[31:22],  a_reg[31:22]);
             err++;
             end
     
         T2_ROR      =  T2_ROR_A_2 ^ T2_ROR_A_13 ^ T2_ROR_A_22;
         if (T2_ROR != DUT_T2_ROR) begin
             $fwrite (TESTFILE, "ERROR: T2_ROR  -> Actual: %08h    Expected: %08h\n" ,DUT_T2_ROR, T2_ROR);
     		$fwrite (TESTFILE, "              T2_ROR      =  T2_ROR_A_2 ^ T2_ROR_A_13 ^ T2_ROR_A_22\n");		
             $fwrite (TESTFILE, "              T2_ROR_A_2   -> Actual = %08h,  Expected =  %08h\n", DUT_T2_ROR_A_2, T2_ROR_A_2);
             $fwrite (TESTFILE, "              T2_ROR_A_13  -> Actual = %08h,  Expected =  %08h\n", DUT_T2_ROR_A_13, T2_ROR_A_13);
             $fwrite (TESTFILE, "              T2_ROR_A_22  -> Actual = %08h,  Expected =  %08h\n", DUT_T2_ROR_A_22, T2_ROR_A_22);
             err++;
             end
         
         T2_ABC      = ((a_reg & b_reg) ^ (a_reg & c_reg) ^ (b_reg & c_reg));
         if (T2_ABC != DUT_T2_ABC) begin
             $fwrite (TESTFILE, "ERROR: T2_ABC  -> Actual: %08h    Expected: %08h\n" ,DUT_T2_ABC, T2_ABC);
             $fwrite (TESTFILE, "T2_ABC      = ((a_reg & b_reg) ^ (a_reg & c_reg) ^ (b_reg & c_reg))\n");
             $fwrite (TESTFILE, "              a_reg   -> Actual = %08h,  Expected =  %08h\n", DUT_a_reg, a_reg);
             $fwrite (TESTFILE, "              b_reg   -> Actual = %08h,  Expected =  %08h\n", DUT_b_reg, b_reg);
             $fwrite (TESTFILE, "              c_reg   -> Actual = %08h,  Expected =  %08h\n", DUT_c_reg, c_reg);
             err++;
             end
         
         T2          = T2_ROR + T2_ABC;              // Hash process PT 2 output
         if (T2 != DUT_T2) begin
             $fwrite (TESTFILE, "ERROR: T2  -> Actual: %08h    Expected: %08h\n" ,DUT_T2, T2);
             $fwrite (TESTFILE, "T2          = T2_ROR + T2_ABC\n");
             $fwrite (TESTFILE, "              T2_ROR   -> Actual = %08h,  Expected =  %08h\n", DUT_T2_ROR, T2_ROR);
             $fwrite (TESTFILE, "              T2_ABC   -> Actual = %08h,  Expected =  %08h\n", DUT_T2_ABC, T2_ABC);		
             err++;
             end
         
     // Note ordered blocking assignments
          h_reg =  g_reg;
          g_reg =  f_reg;
          f_reg =  e_reg;
          e_reg =  d_reg + T1;
          d_reg =  c_reg;
          c_reg =  b_reg;
          b_reg =  a_reg;
          a_reg =  T1 + T2;
     
     	@(negedge DUT_update_Working_Var);
         
         if (a_reg != DUT_a_reg) begin
             $fwrite (TESTFILE, "ERROR: a_reg  -> Actual: %08h    Expected: %08h\n" ,a_reg, DUT_a_reg);
             err++;
             end
     
         if (b_reg != DUT_b_reg) begin
             $fwrite (TESTFILE, "ERROR: b_reg  -> Actual: %08h    Expected: %08h\n" ,b_reg, DUT_b_reg);
             err++;
             end
     
         if (c_reg != DUT_c_reg) begin
             $fwrite (TESTFILE, "ERROR: c_reg  -> Actual: %08h    Expected: %08h\n" ,c_reg, DUT_c_reg);
             err++;
             end
     
         if (d_reg != DUT_d_reg) begin
             $fwrite (TESTFILE, "ERROR: d_reg  -> Actual: %08h    Expected: %08h\n" ,d_reg, DUT_d_reg);
             err++;
             end
     
         if (e_reg != DUT_e_reg) begin
             $fwrite (TESTFILE, "ERROR: e_reg  -> Actual: %08h    Expected: %08h\n" ,e_reg, DUT_e_reg);
             err++;
             end
     
         if (f_reg != DUT_f_reg) begin
             $fwrite (TESTFILE, "ERROR: f_reg  -> Actual: %08h    Expected: %08h\n" ,f_reg, DUT_f_reg);
             err++;
             end
     
         if (g_reg != DUT_g_reg) begin
             $fwrite (TESTFILE, "ERROR: g_reg  -> Actual: %08h    Expected: %08h\n" ,g_reg, DUT_g_reg);
             err++;
             end
     
         if (h_reg != DUT_h_reg) begin
             $fwrite (TESTFILE, "ERROR: c_reg  -> Actual: %08h    Expected: %08h\n" ,h_reg, DUT_h_reg);
             err++;
             end
         
     $fwrite (TESTFILE, "a_reg  =  %08h \n",a_reg);
     $fwrite (TESTFILE, "b_reg  =  %08h \n",b_reg);
     $fwrite (TESTFILE, "c_reg  =  %08h \n",c_reg);
     $fwrite (TESTFILE, "d_reg  =  %08h \n",d_reg);
     $fwrite (TESTFILE, "e_reg  =  %08h \n",e_reg);
     $fwrite (TESTFILE, "f_reg  =  %08h \n",f_reg);
     $fwrite (TESTFILE, "g_reg  =  %08h \n",g_reg);
     $fwrite (TESTFILE, "h_reg  =  %08h \n",h_reg);
        
     $fwrite (TESTFILE, "\n");
     $fwrite (TESTFILE, "Cumulative errors = %0d   @(%0t) \n", err, $time);
         
     end
     
     //Update Hash values 
     HASH[0] =  HASH[0]  + a_reg;
     HASH[1] =  HASH[1]  + b_reg;
     HASH[2] =  HASH[2]  + c_reg;
     HASH[3] =  HASH[3]  + d_reg;
     HASH[4] =  HASH[4]  + e_reg;
     HASH[5] =  HASH[5]  + f_reg;
     HASH[6] =  HASH[6]  + g_reg;
     HASH[7] =  HASH[7]  + h_reg;
     
           
     $fwrite (TESTFILE, "\n");
     $fwrite (TESTFILE, "Hash Calculation Results \n");
     $fwrite (TESTFILE, "-------------------------------------\n");
     p = err;
      for (i = 0; i < 8; i++) begin
         if (hash_calc[BIG_LOOP][i] != HASH[i]) begin
            $fwrite (TESTFILE, "FAIL: Msg Block %0d - HASH[%0d]  - Actual: %08h , Expected: %08h\n", BIG_LOOP, i, HASH[i], hash_calc[BIG_LOOP][i]);
            err++;
            end
         else begin
            $fwrite (TESTFILE, "HASH[%0d] = 0x%08h\n", i, HASH[i]);
            end
         end         
      if (p == err) begin
         $fwrite (TESTFILE, "PASS: Hash calculation and DUT compare \n");
         end
     
end //FOR      
/***********************************************
      ------>     END BIG LOOP     <------
************************************************/  


      
/**************************************
*    Report Meta data in DUT
**************************************/
$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "DUT MESSAGE METADATA @(%0t)\n", $time);
$fwrite (TESTFILE, "--------------------------------------\n");
$fwrite (TESTFILE, "DUT Message Bit Length           = (HEX: 0x%05h) \n", DUT_msg_bit_len);
$fwrite (TESTFILE, "DUT LAST BYTE/LAST WORD POSITION = (BIN: b%02b)  \n", DUT_byte_position);
$fwrite (TESTFILE, "DUT NUMBER OF BLOCKS IN MESSAGE  = (BIN: b%02b)  \n", DUT_num_msg_blks);



/**************************************
*    SHA256 Process start window
**************************************/
$fwrite (TESTFILE, "\n");
for (i = 0; i < 200; i++) begin
   #1; 
   if (DUT_sha_sm_busy == 1'b1) begin
      $fwrite (TESTFILE, "PASS: sha_sm_busy ASSERTED @(%0t)\n", $time);
      break;
      end
end


// Test if assertion window is exceeded
if (i == 200) begin
      $fwrite (TESTFILE, "FAIL: sha_sm_busy NOT ASSERTED @(%0t)\n", $time);
      $stop();
      end

/**********************************************
*  Test process busy bit (1 = true)
**********************************************/    
AVAAddr = 32'h0000_3F00;
BUS_RD(AVAAddr, AVAData);

AVAData = 32'h0000_0001;

while (AVAData[0] == 1'b1) begin
   BUS_RD(AVAAddr, AVAData);
   @(posedge clk);
   end



// Read Hash Result 
$fwrite(TESTFILE,"\n");
$fwrite(TESTFILE,"READ HASH RESULT VIA AVALON BUS\n");
$fwrite(TESTFILE,"-------------------------------\n");
i = 0;
for (AVAAddr = 32'h0000_0000; AVAAddr < 32'h0000_0020; AVAAddr += 4)
   begin
      BUS_RD(AVAAddr, AVAData);
      @(posedge clk);
      DUT_HASH[i++] = AVAData;
      $fwrite (TESTFILE, "HASH[%0d]  ADDR: 0x%08h :  0x%08h    \n", i, AVAAddr, AVAData );
      end
repeat (5) @(posedge clk);

$fwrite(TESTFILE,"\nMESSAGE BYTE COUNT: 0x%08h (%0d) \n", ByteSent, ByteSent);


/***************************************************************
Make sure the three hash results concur
- DUT_HASH[] - The DUT hash result result read over the Avalon
               Bus
- HASH[]     - The DUT hash result calculated from the DUT 
               monitors.
- DUT_HASH[] - The hash result calculated by the test bench 
               only.
***************************************************************/ 
$fwrite(TESTFILE, "\n\nDUT SHA256 Results  @(%0t)       \n",  $realtime);
$fwrite(TESTFILE,     "---------------------------------\n");

$fwrite(TESTFILE,"\nTest Bench Hash Result (SW Calculated):\n");
$fwrite(TESTFILE,  "---------------------------------------\n");
for (i = 0; i < 8; i++) 
   begin
      $fwrite(TESTFILE,"TB Hash[%0d] = 0x%08h\n", i, TB_HASH[i]);
end


$fwrite(TESTFILE,"\nDUT Hash Result (Avalon Bus):\n");
$fwrite(TESTFILE,  "-----------------------------\n");
for (i = 0; i < 8; i++) 
   begin
      $fwrite(TESTFILE,"DUT Hash[%0d] = 0x%08h\n", i, DUT_HASH[i]);
end
   

$fwrite(TESTFILE,"\nDUT Monitored Hash Result:\n");
$fwrite(TESTFILE,  "--------------------------\n");
for (i = 0; i < 8; i++) 
   begin
      $fwrite(TESTFILE,"DUT Memory Array Hash[%0d] = 0x%08h\n", i, HASH[i]);
end


$fwrite(TESTFILE,"\nHash Result Comparison:\n");
$fwrite(TESTFILE,  "-----------------------\n");
for (i = 0; i < 8; i++)  begin
      if (((HASH[i] == DUT_HASH[i]) & (HASH[i] == TB_HASH[i])) & (DUT_HASH[i] == TB_HASH[i]))
         begin
            $fwrite(TESTFILE,"Hash[%0d] = 0x%08h - OK\n", i, HASH[i]);
            end
      else begin
         $fwrite(TESTFILE,"FAIL: HASH[%0d] = 0x%08h, DUT HASH[%0d] = 0x%08h, TB HASH[%0d] = 0x%08h\n", i, HASH[i], i, DUT_HASH[i], i, TB_HASH[i]);    
         err++;
         end
end

//repeat (400) @(posedge clk);

//Console 

$fwrite(TESTFILE,"\n");
$fwrite(TESTFILE,"*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*\n");
$fwrite(TESTFILE,"                END TEST                 \n");
$fwrite(TESTFILE,"*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*\n");

$fclose(TESTFILE);

$display ("FINISH:    SHA256 Verification BYTES = %0d  Cumulative errors: %0d  @(%0t)\n", PARAM1, err, $realtime);

end
endtask







  
/**************************************
        FORK/JOIN TEST
**************************************/
/*
fork 
      $fwrite (TESTFILE, "Write start bit...  @(%0t)\n",  $time);
      AVAAddr = 32'h0000_3F00;
      AVAData = 32'h0000_0001;
      BUS_WR(AVAAddr, AVAData);
      #1;
    begin
      @(posedge DUT_HASH_PROC_GO);
      $fwrite (TESTFILE, "HASH_PROC_GO asserted @(%0t)\n", $time);
      disable fork;
     end
    
    begin
      #500; // wait for 300 ns
      $fwrite (TESTFILE, "HASH_PROC_GO failed to assert @(%0t)\n", $time);
      disable fork;
    end 
join_any
*/

/**************************************
*     Test System Status bit
**************************************/
/*
fork
      $fwrite (TESTFILE, "Write start bit...  @(%0t)\n",  $time);
      AVAAddr = 32'h0000_3F00;
      BUS_RD(AVAAddr, AVAData);
      #1;
    begin
      wait (AVAData[0] == 1'b1);
      $fwrite (TESTFILE, "BUSY Asserted by DUT @(%0t)\n", $time);
      disable fork;
     end
    
    begin
      #100; // wait for 100 ns
      $fwrite (TESTFILE, "BUSY NOT Asserted by DUT @(%0t)\n", $time);
      disable fork;
    end 
join_any
*/

  
  
endmodule
