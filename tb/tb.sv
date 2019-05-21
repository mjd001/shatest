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
logic [31:0] DUT_HASH_MON [0:7];


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

integer rem_msg_blks;
integer rem_word_count;

integer msg_index;
integer RTL_LOOP;

string str1;

integer ptr;

logic  test_reset_n;
logic [7:0] test_points;

logic [31:0] msg_bit_cnt;

wire waitrequest_n;
integer wc;  
logic [31:0] tmp_msg_sch_array[0:63];
logic [31:0] tmp_msg_sch_array_extended[0:63];
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
assign  DUT_HASH_MON[0] = dut.Core_Interface.SHA_inst.H_reg_0; 

// Hash Register 1
assign  DUT_HASH_MON[1] = dut.Core_Interface.SHA_inst.H_reg_1;

// Hash Register 2
assign  DUT_HASH_MON[2] = dut.Core_Interface.SHA_inst.H_reg_2;

// Hash Register 3
assign  DUT_HASH_MON[3] = dut.Core_Interface.SHA_inst.H_reg_3;

// Hash Register 4
assign  DUT_HASH_MON[4] = dut.Core_Interface.SHA_inst.H_reg_4;

// Hash Register 5
assign  DUT_HASH_MON[5] = dut.Core_Interface.SHA_inst.H_reg_5;

// Hash Register 6
assign  DUT_HASH_MON[6] = dut.Core_Interface.SHA_inst.H_reg_6;

// Hash Register 7
assign  DUT_HASH_MON[7] = dut.Core_Interface.SHA_inst.H_reg_7;

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




/******************************************************
   Wait for TB reset to de-assert
******************************************************/
wait(reset_n == 1);
repeat (2) @ (posedge clk);


for (test_cntr = 1; test_cntr < 260; test_cntr++)
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

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
/*******************************************************************

   END:  MAIN TEST PROCESS

********************************************************************/
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\









/*******************************************************************
  TASK:   SHA256 Calculation - Data expected from the DUT
          -  Pass the length of test data in bytes
          -  Calculate the SHA256 HASH for the test data
          -  Compare calulation with DUT result
********************************************************************/
task  test_loop;
   input integer PARAM1;
   logic [31:0] msg_sch_calc[][];
   logic [31:0] hash_calc[][];

begin  

// Set up time stamp format
$timeformat(-6, 3, " us", 5);
  
// Init scratch variables 
i = 0;   j = 0;   k = 0;   n = 0;


ptr = 0;

//Init error counter
err = 0;


//Console Display
$display ("SHA256 Core TEST - Byte count = %0d:  START @(%0t)", PARAM1, $realtime );


$sformat(str1, "test_results_%0d.dat",PARAM1); //Open test results output file, append byte count to file name.
TESTFILE = $fopen(str1, "w");

//$fwrite(TESTFILE," Current System Time is %s\n",get_time());

/****************************************************************************
BEGIN: SHA256 CALCULATION  - Refer to NIST Pub. FIPS-180

SHA256 divides the given message into an integer quantity of fixed size 
message blocks consisting of 16 words or 64 bytes. Each message block is 
"expanded" from 16 words to 64 words which is then hashed to produce an array 
8 words (HASH[0:7]). The process is repeated sequentially for each message 
block with the previous hash added. All addition is modulo 2^32.

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


// Seed value for test data
gen_data = 32'h12345678;

// Simple ROR PRNG generates test data
for (y = 0; y < 4096; y++) begin
   gen_data              =  {gen_data[0], gen_data[31:1]};
   test_msg_block[y]     =   gen_data;        // SW calculation
   DUT_test_msg_block[y] =   gen_data;        // Save a copy for DUT
   end

/* Number of bytes in message (a non-zero natural number) */

//for (x=1; x < 248; x++) begin // 256 bytes minus 8 bytes in last blocks word 14 and 15 (bit size)
/*************************************************
  Extract the nessesary data for this test data
*************************************************/
x               =    PARAM1;                             // <- SET BYTE COUNT FOR ENTIRE TEST HERE  Range [1:N]               

ByteSent        =    x - 1;                              // Byte count value Range [0:N-1] 

msg_bytes_abs   =    x;                                  // Byte count value Range [1:N] 

word_count      =    {2'b00, ByteSent[31:2]};            // Word count Range [0:W-1]

byte_slot       =    ByteSent % 4;                       // Byte lane location M[0:W-1] Byte[0:3]

msg_blocks      =    {6'b00_0000, ByteSent[31:6]} + 1;   // Number of message blocks [1:M]

msg_bit_cnt     =    {msg_bytes_abs[28:0], 3'b000};      // Message bit count [8*1 : 8*N]

/***************************************************************************
  Create a hash and message array to capture the state of each round
  for evaluation against the DUT's result later. An extra message and
  hash array is added for a possible overflow condition.
***************************************************************************/
msg_sch_calc = new[msg_blocks + 1];    // Message Schedule for M[n]
hash_calc    = new[msg_blocks + 2];    // Halc calculation for M[n]

foreach(msg_sch_calc[i])  
   msg_sch_calc[i] = new[64];
   
foreach(hash_calc[i])     
   hash_calc[i] = new[8];

/*********************************************************
 Initialize hash array per FIPS-180 sec 6.2.2
*********************************************************/
for (i = 0; i < 8; i++) begin
   hash_calc[0][i] = HASH_ini[i]; // First ROW
   end

/*********************************************************
 Report the constant values for this test message
*********************************************************/
$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "SHA256 Constants for M:\n");
$fwrite (TESTFILE, "-----------------------\n");
$fwrite (TESTFILE, "Set Byte Count = %0d \n", x);
$fwrite (TESTFILE, "Word Range = W[0:%0d] \n", word_count);
$fwrite (TESTFILE, "Last Byte Location = Msg Block[%0d], Word[%0d], Byte[%0d] \n", msg_blocks, (word_count % 16), byte_slot);
$fwrite (TESTFILE, "Message Block Range M[0:%0d] \n", msg_blocks);
$fwrite (TESTFILE, "Message bit count = %0d (0x%08h) \n", msg_bit_cnt, msg_bit_cnt);

/*********************************************************
 Report the message data currently being worked on
*********************************************************/
$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "Message Data Set M:\n");
$fwrite (TESTFILE, "-------------------\n");
for (i = 0; i < word_count + 1; i++) 
   begin
      if ( i < 8 ) begin
         $fwrite(TESTFILE, " %08h  ", test_msg_block[i] );
         end
      else if (( i >= 8 ) & ( i % 8 == 0 )) begin
         $fwrite(TESTFILE, "\n %08h  ", test_msg_block[i] );
         end
      else begin
         $fwrite(TESTFILE, " %08h  ", test_msg_block[i] );
         end
      end         
$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "-----------------\n");

/*************************************************
   Adjust the word count variable to these one
   indexed this will make testing easier
*************************************************/
wc  =  word_count + 1'b1; // Change to 1 index
n   =  wc;                // Copy
rem_word_count  =   wc;


rem_msg_blks   =    msg_blocks;
/********************************************************************
 Hash the message in software to create expected results when we
 test the DUT.
********************************************************************/
for (m = 0; m < msg_blocks; m++)
  begin

    // Set scratch message schedule array to zero
   for (i = 0; i < 64; i++)  begin  tmp_msg_sch_array[i] = 32'h0000_0000;  end


   /*--------------------------------------------------------
    * Copy up to 16 words from the test array to 
    * the current message block from the test array. 
    *--------------------------------------------------------*/
   for (i = 0; i < 16; i++)   begin
      msg_sch_calc[m-0][i] = test_msg_block[i + ((m-0)*16)];
      tmp_msg_sch_array[i] = test_msg_block[i + ((m-0)*16)];
      wc--;
      if (wc == 0) break; 
      end 

   rem_msg_blks--;
   
   ptr++;
   
  /*------------------------------------
   * Report the message block
   *----------------------------------*/
  $fwrite(TESTFILE, "\n");
  $fwrite(TESTFILE, "MESSAGE M[%0d]: \n", m-0 );
  $fwrite(TESTFILE, "----------------\n");
  for (i = 0; ((i < 16) & (n != 0)); i++)
     begin
        if (i < 8 ) begin
           $fwrite(TESTFILE, " %08h  ", msg_sch_calc[m-0][i] );
           n--;
           end
        else if ((i >=8) & (i%8 == 0)) begin   // LF/CR
           $fwrite(TESTFILE, "\n %08h  ", msg_sch_calc[m-0][i] );
           n--; 
           end
        else begin
           $fwrite(TESTFILE, " %08h  ", msg_sch_calc[m-0][i] );
           n--; 
           end
        end         

  /*--------------------------------------------
   * Begin the message block schedule process
   *-------------------------------------------*/
  
   // Given test test information above calculate the message schedule
   // for this set of words
   msg_sched( (i-1),                          // input   integer      last_word_loc, 
              tmp_msg_sch_array,              // inout   logic [31:0] tmp_msg_sch_array[0:63],
              tmp_msg_sch_array_extended,     // output  logic [31:0] tmp_msg_sch_array_extended[0:63],
              byte_slot,                      // input   integer      byte_slot,
              msg_bit_cnt,                    // input   logic [31:0] msg_bit_cnt,
              rem_msg_blks,                   // input   logic [31:0] msg_blocks,
              TESTFILE,                       // input   integer      FP,
              extra_msg_blk                   // output  integer      extra_msg_blk
                              );
                               
  // Report the calculated message schedule
  $fwrite(TESTFILE, "\n\n");   
  $fwrite(TESTFILE, "MESSAGE SCHEDULE FOR M[%0d]:  \n", m-0 );
  $fwrite(TESTFILE, "------------------------------\n");
  for (i = 0; i < 64; i++) 
     begin
        if (i < 8) begin
           $fwrite(TESTFILE, " %08h  ", tmp_msg_sch_array[i] );
           end
        else if ((i >=8) & (i%8 == 0)) begin
           $fwrite(TESTFILE, "\n %08h  ", tmp_msg_sch_array[i] );
           end
        else begin
           $fwrite(TESTFILE, " %08h  ", tmp_msg_sch_array[i] );
           end
        end         

  // Copy result to matrix
  for (i = 0; i < 64; i++) 
     begin
       msg_sch_calc[m-0][i]  =  tmp_msg_sch_array[i];
       end


  /*--------------------------------------------
   * Next begin the hash function
   *-------------------------------------------*/
  // Copy the current hash state to this scratch array         
   for (i = 0; i < 8; i++) begin
     HASH[i] = hash_calc[m-0][i];
     end

   //Calculate hash from current state of message schedule and hash array
   hash_proc( tmp_msg_sch_array,    // input logic [31:0] msg_sch[0:63],
              HASH              );  // inout logic [31:0] HASH [0:7]


  // Save the hash state in the next row of the matrix
  for (i = 0; i < 8; i++) begin
      hash_calc[m+1][i] = HASH[i];
      end

  // Report the hash state
  $fwrite(TESTFILE, "\n\n");
  $fwrite(TESTFILE, "HASH CALCULATION FOR M[%0d]:   \n", (m-0) );
  $fwrite(TESTFILE, "-------------------------------\n");
  for (i = 0; i < 8; i++) begin
     $fwrite(TESTFILE, "HASH[%0d]:  %08h\n", i, HASH[i]);
     end



   /*---------------------------------------------------------------------------------
    * If we are on the last hash block and it's byte count is 56 or greater
    * the message schedule function will set a flag and fill an the  extra message
    * arrayan. This block needs to be hashed and added to the previous
    *-------------------------------------------------------------------------------*/
   $fwrite(TESTFILE, "\n");
   if (extra_msg_blk) begin
      $fwrite(TESTFILE, "EXTENDED MESSAGE SCHEDULE FOR M[%0d]:  \n", (m-0) );
      $fwrite(TESTFILE, "---------------------------------------\n");
      for (i = 0; i < 64; i++)
         begin
            if (i < 8 ) begin
              $fwrite(TESTFILE, " %08h  ", tmp_msg_sch_array_extended[i] );
              end
            else if ((i >= 8) & (i % 8 == 0)) begin
              $fwrite(TESTFILE, "\n %08h  ", tmp_msg_sch_array_extended[i] );
              end
            else begin
              $fwrite(TESTFILE, " %08h  ", tmp_msg_sch_array_extended[i] );
              end
        end

      // Make a copy array, again
      for (i = 0; i < 8; i++) begin
         HASH[i] = hash_calc[m+1][i];
         end

      // Call hash function
      hash_proc( tmp_msg_sch_array_extended,  HASH);

      // Copy the extended hash to the extra block we allocated
      for (i = 0; i < 64; i++) begin
         msg_sch_calc[m+1][i] = tmp_msg_sch_array_extended[i];
         end

      // Copy the extended hash to the extra block we allocated
      for (i = 0; i < 8; i++) begin
         hash_calc[m+2][i] = HASH[i];
         end
      ptr++;
      end

end // FOR LOOP


$fwrite (TESTFILE, "\n\n");
$fwrite (TESTFILE, "SHA256 Hash Calculation for M:\n");
$fwrite (TESTFILE, "------------------------------\n");
for (i = 0; i < 8; i++) begin
   if (extra_msg_blk) begin
      $fwrite (TESTFILE, "HASH[%0d] = %08h\n", i, hash_calc[m+1][i]);
      end
   else begin
      $fwrite (TESTFILE, "HASH[%0d] = %08h\n", i, hash_calc[m][i]);
      end
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
    ----->   END:  RTL TEST PROCESS     <-----  
************************************************/  

/***********************************************
 RTL LOOP: This verifies the DUT processing
           of the message blocks.
************************************************/  
for (RTL_LOOP = 0; RTL_LOOP < (msg_blocks + extra_msg_blk) ; RTL_LOOP++)
begin     

  wait (DUT_sha_sm_busy == 1'b1);
  wait (DUT_sha_sm_busy == 1'b0);

  $fwrite (TESTFILE, "\n");
  $fwrite (TESTFILE, "Message schedule block %0d Actual vs Expected\n", RTL_LOOP);
  $fwrite (TESTFILE, "---------------------------------------------\n");

  for (i = 0; i < 64; i++) 
     begin
        if (DUT_MSG_BLK_1[i] == msg_sch_calc[RTL_LOOP][i]) begin
           $fwrite (TESTFILE, "OK: MSG BLK [%0d], MSG SCH RAM[%0d] = %08h \n", RTL_LOOP, i, msg_sch_calc[RTL_LOOP][i] );
           end
        else begin 
           $fwrite (TESTFILE, "FAIL: MSG BLK [%0d], MSG SCH RAM[%0d] - ACTUAL: %08h,  EXPECTED: %08h \n", RTL_LOOP, i, DUT_MSG_BLK_1[i], msg_sch_calc[RTL_LOOP][i]);
           err++;
           end
        end


  $fwrite (TESTFILE, "\n");
  $fwrite (TESTFILE, "Message schedule block %0d Actual vs Expected\n", RTL_LOOP);
  $fwrite (TESTFILE, "---------------------------------------------\n");
for (i = 0; i < 8; i++)
   begin 
      if (DUT_HASH_MON[i] == hash_calc[RTL_LOOP+1][i]) begin
         $fwrite (TESTFILE, "OK: HASH[%0d], = %08h \n", i, hash_calc[RTL_LOOP][i]);
         end
      else begin
         $fwrite (TESTFILE, "FAIL: HASH[%0d], Actual = %08h , Expected = %08h \n", i, DUT_HASH_MON[i], hash_calc[RTL_LOOP][i]);
         err++;
         end
    end
end //FOR      
/***********************************************
      ------>     END RTL LOOP     <------
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
//$fwrite (TESTFILE, "\n");
//for (i = 0; i < 200; i++) begin
//   #1; 
//   if (DUT_sha_sm_busy == 1'b1) begin
//      $fwrite (TESTFILE, "PASS: sha_sm_busy ASSERTED @(%0t)\n", $time);
//      break;
//      end
//end


// Test if assertion window is exceeded
//if (i == 200) begin
//      $fwrite (TESTFILE, "FAIL: sha_sm_busy NOT ASSERTED @(%0t)\n", $time);
//      $stop();
//      end

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

// Adjust pointer

$fwrite(TESTFILE, "\n\nDUT SHA256 Results  @(%0t)       \n",  $realtime);
$fwrite(TESTFILE,     "---------------------------------\n");



$fwrite(TESTFILE,"\nTest Bench Hash Result (SW Calculated):\n");
$fwrite(TESTFILE,  "---------------------------------------\n");
for (i = 0; i < 8; i++) 
   begin
      TB_HASH[i]  =  hash_calc[ptr][i];
      $fwrite(TESTFILE,"TB Hash[%0d] = 0x%08h\n", i, TB_HASH[i]);
end



$fwrite(TESTFILE,"\nDUT Hash Result (Avalon Bus):\n");
$fwrite(TESTFILE,  "-----------------------------\n");
for (i = 0; i < 8; i++) 
   begin
      $fwrite(TESTFILE,"DUT Hash[%0d] = 0x%08h\n", i, DUT_HASH[i]);
end
   

$fwrite(TESTFILE,"\nDUT Hash Result (probe):\n");
$fwrite(TESTFILE,  "------------------------\n");
for (i = 0; i < 8; i++) 
   begin
      $fwrite(TESTFILE,"DUT Memory Array Hash[%0d] = 0x%08h\n", i, HASH[i]);
end


$fwrite(TESTFILE,"\nHash Result Comparison:\n");
$fwrite(TESTFILE,  "-----------------------\n");
for (i = 0; i < 8; i++)  begin
      if (((HASH[i] == DUT_HASH_MON[i]) & (HASH[i] == TB_HASH[i])) & (DUT_HASH_MON[i] == TB_HASH[i]))
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


//delete matrices
hash_calc.delete();
msg_sch_calc.delete();



end
endtask







  
  
endmodule
