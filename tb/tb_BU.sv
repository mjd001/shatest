/******************************************************************************
SHA-256 Hash algorithm

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
module tb (/*AUTOARG*/ ) ;


//import svlib_pkg::*;

// Test Results file descriptor
integer TESTFILE;


// Scratch variables
integer i, j, k;
integer x, y, z;
integer m, n, p;

// Time var
realtime t1, t2;


// Global clock and reset
logic            clk;  
logic            reset_n; 

logic    blip;

// Evaluation logic
logic [31:0] AVAAddr;  
logic [31:0] AVAData;

logic [13:0] address;
logic write;
logic read;

logic [31:0] writedata;
logic [31:0] readdata;

logic [31:0] DUT_HASH [0:7];


logic [1:0] response;

logic        lock;

// Avalon bus Read/Write task
integer err;


// Locals
logic [31:0] msg_block[0:15];
logic [31:0] msg_sch[0:63];
logic [31:0] working_variables[0:63];

  //----------------------------------------------------------------
  // addr_mux
  //----------------------------------------------------------------
logic [31:0] KVal[0:63] ='{
      32'h428a2f98,  // 00
      32'h71374491,  // 01
      32'hb5c0fbcf,  // 02
      32'he9b5dba5,  // 03
      32'h3956c25b,  // 04
      32'h59f111f1,  // 05
      32'h923f82a4,  // 06
      32'hab1c5ed5,  // 07
      32'hd807aa98,  // 08
      32'h12835b01,  // 09
      32'h243185be,  // 10
      32'h550c7dc3,  // 11
      32'h72be5d74,  // 12
      32'h80deb1fe,  // 13
      32'h9bdc06a7,  // 14
      32'hc19bf174,  // 15
      32'he49b69c1,  // 16
      32'hefbe4786,  // 17
      32'h0fc19dc6,  // 18
      32'h240ca1cc,  // 19
      32'h2de92c6f,  // 20
      32'h4a7484aa,  // 21
      32'h5cb0a9dc,  // 22
      32'h76f988da,  // 23
      32'h983e5152,  // 24
      32'ha831c66d,  // 25
      32'hb00327c8,  // 26
      32'hbf597fc7,  // 27
      32'hc6e00bf3,  // 28
      32'hd5a79147,  // 29
      32'h06ca6351,  // 30
      32'h14292967,  // 31
      32'h27b70a85,  // 32
      32'h2e1b2138,  // 33
      32'h4d2c6dfc,  // 34
      32'h53380d13,  // 35
      32'h650a7354,  // 36
      32'h766a0abb,  // 37
      32'h81c2c92e,  // 38
      32'h92722c85,  // 39
      32'ha2bfe8a1,  // 40
      32'ha81a664b,  // 41
      32'hc24b8b70,  // 42
      32'hc76c51a3,  // 43
      32'hd192e819,  // 44
      32'hd6990624,  // 45
      32'hf40e3585,  // 46
      32'h106aa070,  // 47
      32'h19a4c116,  // 48
      32'h1e376c08,  // 49
      32'h2748774c,  // 50
      32'h34b0bcb5,  // 51
      32'h391c0cb3,  // 52
      32'h4ed8aa4a,  // 53
      32'h5b9cca4f,  // 54
      32'h682e6ff3,  // 55
      32'h748f82ee,  // 56
      32'h78a5636f,  // 57
      32'h84c87814,  // 58
      32'h8cc70208,  // 59
      32'h90befffa,  // 60
      32'ha4506ceb,  // 61
      32'hbef9a3f7,  // 62
      32'hc67178f2}; // 63

 
logic [31:0] HASH_ini[0:7] = '{32'h6a09e667,
                               32'hbb67ae85,
                               32'h3c6ef372,
                               32'ha54ff53a,
                               32'h510e527f,
                               32'h9b05688c,
                               32'h1f83d9ab,
                               32'h5be0cd19 };
                               
                               
                               
                               
logic [31:0] test_msg_block[0:15]  =  '{ 32'h61626300,   
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000,
                                         32'h00000000 }; 
/*                                         
logic [31:0] test_msg_block[0:15]  =  '{ 32'h01620000,   
                                         32'h10000000,
                                         32'h20000000,
                                         32'h30000000,
                                         32'h40000000,
                                         32'h50000000,
                                         32'h60000000,
                                         32'h70000000,
                                         32'h80000000,
                                         32'h90000000,
                                         32'ha0000000,
                                         32'hb0000000,
                                         32'hc0000000,
                                         32'hd0000000,
                                         32'he0000000,
                                         32'hf0000000 };
*/                              
                               
logic [31:0] DUT_MSG_BLK_1[0:63];
logic [31:0] DUT_MSG_BLK_2[0:63];
logic [31:0] DUT_MSG_BLK_3[0:63];
logic [31:0] DUT_MSG_BLK_4[0:63];
                               
logic [31:0] HASH[0:7];

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
logic [3:0] DUT_macro_vect;            // EOM Macro Sequence assigned
logic [3:0] DUT_track_ptr;             // Current Track Pointer location
logic [1:0] DUT_byte_position;         // Byte position of last data byte in last 32 bit word
logic [31:0] DUT_RAM_Data_IN;          // 4K RAM Data in port
logic [11:0] DUT_RAM_RD_Addr;          // 4K RAM Read address port
logic [11:0] DUT_RAM_WR_Addr;          // 4K RAM Write address port
logic [31:0] DUT_RAM_Data_OUT;         // 4K RAM Data out port
logic [3:0] DUT_dat_sw_sel;            // 4K RAM Data out to SHA process select
logic [3:0] DUT_SHA_PROC_STATE;        // SHA Processing state machine.
logic [12:0] DUT_SHA_SM_RAM_RD_ADDR;   // SHA Process state machine RAM Read address
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
logic  [31:0] last_word;
integer word_count;
integer byte_slot;
/*******************************************************
SHA-256 Test data
0x61 = 'a'
0x62 = 'b'
0x63 = 'c'
0x80 = appended binary 1


*******************************************************/
logic  test_reset_n;
logic [7:0] test_points;
wire waitrequest_n;

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

/***********************************************
             MONITORS 
***********************************************/

genvar DUT_MSG_ELEM;

for (DUT_MSG_ELEM = 0; DUT_MSG_ELEM < 64; DUT_MSG_ELEM++) 
   begin : Sched_Mem_Monitor_1
     assign DUT_MSG_BLK_1[DUT_MSG_ELEM] = dut.Core_Interface.sched_mem_1.mem[DUT_MSG_ELEM];
     end

for (DUT_MSG_ELEM = 0; DUT_MSG_ELEM < 64; DUT_MSG_ELEM++) 
   begin : Sched_Mem_Monitor_2
     assign DUT_MSG_BLK_2[DUT_MSG_ELEM] = dut.Core_Interface.sched_mem_2.mem[DUT_MSG_ELEM];
     end

for (DUT_MSG_ELEM = 0; DUT_MSG_ELEM < 64; DUT_MSG_ELEM++) 
   begin : Sched_Mem_Monitor_3
     assign DUT_MSG_BLK_3[DUT_MSG_ELEM] = dut.Core_Interface.sched_mem_3.mem[DUT_MSG_ELEM];
     end

for (DUT_MSG_ELEM = 0; DUT_MSG_ELEM < 64; DUT_MSG_ELEM++) 
   begin : Sched_Mem_Monitor_4
     assign DUT_MSG_BLK_4[DUT_MSG_ELEM] = dut.Core_Interface.sched_mem_4.mem[DUT_MSG_ELEM];
     end






        
assign DUT_update_Working_Var = dut.Core_Interface.update_Working_Var;								   

// DUT system clock
assign DUT_clk  = dut.Core_Interface.clk;                         

// Message scedule RAM Write Enable
assign DUT_MSG_SCHED_RAM_WE = dut.Core_Interface.MSG_SCHED_RAM_WE;

// RAM data select mux out
assign DUT_RAM_Data_OUT_p = dut.Core_Interface.RAM_Data_OUT_p;

// Meta: Number of message bits
assign DUT_msg_bit_len = dut.Core_Interface.msg_bit_len;

// Message processing start (top)
assign DUT_HASH_PROC_GO = dut.Core_Interface.HASH_PROC_GO;

// SHA control state machine start signal
assign DUT_start_sha_proc = dut.Core_Interface.start_sha_proc;

// SHA Process State machine busy status
assign DUT_sha_sm_busy = dut.Core_Interface.sha_sm_busy;

// SHA control state machine state
assign DUT_SHA_CTRL_SM = dut.Core_Interface.SHA_CTRL_SM;

// Number of message blocks remaining to be processed
assign DUT_num_msg_blks = dut.Core_Interface.num_msg_blks;

// EOM Macro Sequence assigned
assign DUT_macro_vect =  dut.Core_Interface.macro_vect;

//Current Track Pointer location
assign DUT_track_ptr = dut.Core_Interface.track_ptr;

//Byte position of last data byte in last 32 bit word
assign DUT_byte_position = dut.Core_Interface.byte_position;

//4K RAM Data in port
assign DUT_RAM_Data_IN = dut.Core_Interface.RAM_Data_IN;

//4K RAM Read address port
assign DUT_RAM_RD_Addr = dut.Core_Interface.RAM_RD_Addr;

//4K RAM Write address port
assign DUT_RAM_WR_Addr = dut.Core_Interface.RAM_WR_Addr;

//4K RAM Data out port
assign DUT_RAM_Data_OUT = dut.Core_Interface.RAM_Data_OUT;

// 4K RAM Data out to SHA process select
assign DUT_dat_sw_sel = dut.Core_Interface.dat_sw_sel;

// SHA Processing state machine.
assign DUT_SHA_PROC_STATE = dut.Core_Interface.SHA_PROC_STATE;

// SHA Process state machine RAM Read address
assign DUT_SHA_SM_RAM_RD_ADDR = dut.Core_Interface.SHA_SM_RAM_RD_ADDR;

// Message schedule RAM base address
assign DUT_MSG_SCHED_RAM_WR_ADDR = dut.Core_Interface.MSG_SCHED_RAM_WR_ADDR;

// K Constants ROM Data
//assign DUT_K_const_ROM_data = dut.Core_Interface.K_const_ROM_data;

// Message schedule RAM base address minus two
assign DUT_T_addr_sub_2 =  dut.Core_Interface.T_addr_sub_2;

// Message schedule RAM base address minus two
assign DUT_T_addr_sub_7 =  dut.Core_Interface.T_addr_sub_7;

// Message schedule RAM base address minus two
assign DUT_T_addr_sub_15 =  dut.Core_Interface.T_addr_sub_15;

// Message schedule RAM base address minus two
assign DUT_T_addr_sub_16 =  dut.Core_Interface.T_addr_sub_16;

// Message schedule input RAM data
assign DUT_MSG_SCHED_RAM_DAT_IN = dut.Core_Interface.MSG_SCHED_RAM_DAT_IN;

//Message Schedule RAM 1 to 4 input data source select
assign DUT_MSG_SCHED_DATA_SOURCE = dut.Core_Interface.MSG_SCHED_DATA_SOURCE;

// Message schedule RAM #1 data output - Use this for selected message schedule word in test.
assign DUT_msg_word_picked = dut.Core_Interface.dat_o_2;

// Message schedule RAM #2 data output
assign DUT_dat_o_7 = dut.Core_Interface.dat_o_7;

// Message schedule RAM #3 data output
assign DUT_dat_o_15 = dut.Core_Interface.dat_o_15;

// Message schedule RAM #4 data output
assign DUT_dat_o_16 = dut.Core_Interface.dat_o_16;

// Rotate Right Message schedule RAM data #1 17 bits
assign DUT_ROR_WT1_17 = dut.Core_Interface.ROR_WT1_17;

// Rotate Right Message schedule RAM data #1 19 bits
assign DUT_ROR_WT1_19 = dut.Core_Interface.ROR_WT1_19;

//Shift Right Message schedule RAM #1 10 bits
assign DUT_SHR_WT1_10 = dut.Core_Interface.SHR_WT1_10;

// Rotate Right Message schedule RAM data #3 7 bits
assign DUT_ROR_WT2_7 = dut.Core_Interface.ROR_WT2_7;

// Rotate Right Message schedule RAM data #3 18 bits
assign DUT_ROR_WT2_18 = dut.Core_Interface.ROR_WT2_18;

//Shift Right Message schedule RAM #3 10 bits
assign DUT_SHR_WT2_3 = dut.Core_Interface.SHR_WT2_3;

// Message Schedule intermediate value #1
assign DUT_WPT1 = dut.Core_Interface.WPT1;

// Message Schedule intermediate value #2
assign DUT_WPT2 = dut.Core_Interface.WPT2;

//Message Schedule calculation
assign DUT_MSG_SCHED_LOGIC_OUT = dut.Core_Interface.MSG_SCHED_LOGIC_OUT;

//SHA256 T1 Process rotate right e_reg 6
assign DUT_T1_ROR_E_6  = dut.Core_Interface.T1_ROR_E_6;

//SHA256 T1 Process rotate right e_reg 11
assign DUT_T1_ROR_E_11 = dut.Core_Interface.T1_ROR_E_11;

//SHA256 T1 Process rotate right e_reg 25
assign DUT_T1_ROR_E_25 = dut.Core_Interface.T1_ROR_E_25;

//SHA256 T1 Process XOR of e_reg rotates
assign DUT_T1_ROR = dut.Core_Interface.T1_ROR;

//SHA256 T1 Process XOR of e_reg rotates
assign DUT_T1_EFG = dut.Core_Interface.T1_EFG;

//SHA256 sum of T1_ROR and DUT_T1_EFG
assign DUT_T1 =  dut.Core_Interface.T1;

//SHA256 T2 Process rotate right a_reg 2
assign DUT_T2_ROR_A_2  = dut.Core_Interface.T2_ROR_A_2;

//SHA256 T2 Process rotate right a_reg 13 
assign DUT_T2_ROR_A_13 = dut.Core_Interface.T2_ROR_A_13;

//SHA256 T2 Process rotate right a_reg 22
assign DUT_T2_ROR_A_22 = dut.Core_Interface.T2_ROR_A_22;

//SHA256 T2 Process XOR a_reg 2                                            
assign DUT_T2_ROR      = dut.Core_Interface.T2_ROR;

//SHA256 T2 Process XOR's a_reg, b_reg and c_reg sums     
assign DUT_T2_ABC      = dut.Core_Interface.T2_ABC;     
             
//SHA256 T2 sum DUT_T2_ROR and DUT_T2_ABC              
assign DUT_T2          = dut.Core_Interface.T2;         

// Working Variable "A" Register
assign  DUT_a_reg = dut.Core_Interface.a_reg;

// Working Variable "B" Register
assign  DUT_b_reg = dut.Core_Interface.b_reg;

// Working Variable "C" Register
assign  DUT_c_reg = dut.Core_Interface.c_reg;

// Working Variable "D" Register
assign  DUT_d_reg = dut.Core_Interface.d_reg;

// Working Variable "E" Register
assign  DUT_e_reg = dut.Core_Interface.e_reg;

// Working Variable "F" Register
assign  DUT_f_reg = dut.Core_Interface.f_reg;

// Working Variable "G" Register
assign  DUT_g_reg = dut.Core_Interface.g_reg;

// Working Variable "H" Register
assign  DUT_h_reg = dut.Core_Interface.h_reg;

// Hash Register 0
assign  DUT_H_reg_0 = dut.Core_Interface.H_reg_0;

// Hash Register 1
assign  DUT_H_reg_1 = dut.Core_Interface.H_reg_1;

// Hash Register 2
assign  DUT_H_reg_2 = dut.Core_Interface.H_reg_2;

// Hash Register 3
assign  DUT_H_reg_3 = dut.Core_Interface.H_reg_3;

// Hash Register 4
assign  DUT_H_reg_4 = dut.Core_Interface.H_reg_4;

// Hash Register 5
assign  DUT_H_reg_5 = dut.Core_Interface.H_reg_5;

// Hash Register 6
assign  DUT_H_reg_6 = dut.Core_Interface.H_reg_6;

// Hash Register 7
assign  DUT_H_reg_7 = dut.Core_Interface.H_reg_7;

// Hash Registers init
assign  DUT_init_H   = dut.Core_Interface.init_H;

// Hash Registers update values
assign  DUT_update_H = dut.Core_Interface.update_H;

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

// Set up time stamp format
$timeformat(-6, 3, " us", 5);
  
// Init scratch variables
i = 0;   j = 0;   k = 0;
test_reset_n = 1'b1;

//Init error counter
err = 0;

// Number of bytes in Message
ByteSent = 32'h0000_0037;
#1;


//Console 
$display ("SHA256 Core TEST:   %0d cumulative errors @(%0t)\n", err,  $realtime);

//Open output file and print banner
TESTFILE = $fopen("test_results.dat", "w"); 
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


/******************************************************
   Banner
******************************************************/
$fwrite(TESTFILE, "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*\n");
$fwrite(TESTFILE, "*                 BEGIN: SHA256 HASH PROCESS                *\n");
$fwrite(TESTFILE, "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*\n");
$fwrite(TESTFILE, "\n");


/**************************************************
* Calculate where binary 1 will be appended
**************************************************/
//Number of bytes in message

// Calculate # of 32 bit words in message (1 indexed)
   if (ByteSent < 4 ) begin
      word_count = 1;
      end
   else begin
      word_count = (ByteSent/4) + 1;
      end

   byte_slot = (ByteSent-1) % 4;  
	  
/***************************************************
*  We've calculated the location of the required 
*  binary '1' bit which will be the msb of the 
*  last byte slot + 1 location. Here we insert 
*  this value (0x80) and copy test data to the test array
***************************************************/

i = 1; // Test message data index

// Start of Message memory
AVAAddr = 32'h0000_0000;

// Send out the test data to the DUT RAM
while (i <= word_count) begin

    AVAData = test_msg_block[i-1];
    BUS_WR(AVAAddr, AVAData);
    AVAAddr += 4;
    @(posedge clk);

   // Load Test
   if (i == word_count) begin  // Last word
      if (byte_slot == 0) begin
         last_word =  {test_msg_block[i-1][31:24], 24'h800000};
         end
      else if (byte_slot == 1) begin
         last_word =  {test_msg_block[i-1][31:16], 16'h8000};
         end
      else if (byte_slot == 2) begin
         last_word =  {test_msg_block[i-1][31:8], 8'h80};
         end
      else if (byte_slot == 3) begin
         last_word =   32'h8000_0000;
         end
      $fwrite (TESTFILE, "TEST001: DATA WRITE COMPLETED @(%0t)\n", $time);
      end

    if (i == word_count) begin
      test_msg_block[i-1]  = last_word;
      test_msg_block[15]   = {ByteSent[28:0], 3'b000};
      end

    i++;

end  
  
/************************************************
*   Write messsage size over Avalon Bus
************************************************/
AVAAddr =  32'h0000_3F04;
AVAData =  ByteSent;
BUS_WR(AVAAddr, AVAData);
$fwrite (TESTFILE, "TEST001: DATA WRITE COMPLETED @(%0t)\n", $time);
@(posedge clk);

/**************************************
*     Start Data Process
**************************************/
$fwrite (TESTFILE, "TEST001: DATA START BIT @(%0t)\n", $time);
fork
    AVAAddr = 32'h0000_3F00;
    AVAData = 32'h0000_0001;
    BUS_WR(AVAAddr, AVAData);
join_none



/*******************************************
*   Verify  Hash processing start window
*******************************************/
for (i = 0; i < 200; i++) begin
   #1; 
   if (DUT_HASH_PROC_GO == 1'b1) begin
      $fwrite (TESTFILE, "TEST001: HASH_PROC_GO ASSERTED @(%0t)\n", $time);
      @(negedge DUT_HASH_PROC_GO);
      break;
      end
end

// Test if assertion window is exceeded
if (i == 200) begin
      $fwrite (TESTFILE, "FAIL TEST001: HASH_PROC_GO NOT ASSERTED @(%0t)\n", $time);
      $stop();
      end

      
      
      
/*******************************************
*   Initialize Working Variable Registers
*******************************************/      
a_reg  =  HASH_ini[0];
b_reg  =  HASH_ini[1];
c_reg  =  HASH_ini[2];
d_reg  =  HASH_ini[3];
e_reg  =  HASH_ini[4];
f_reg  =  HASH_ini[5];
g_reg  =  HASH_ini[6];
h_reg  =  HASH_ini[7];
      
/****************************************************************
*  Message Schedule calculation
*  - Verify Message schedule RAM location 0 to 15 are loaded   
****************************************************************/
for (i = 0; i < 64; i++) begin  // 64 word RAM

   // DUT proc state machine has a word ready to send to processing logic
   if (i < 15) begin  // Load first 16 words (M[N])
      wait (DUT_SHA_PROC_STATE == 4'hE);  // RAM loaded here
      @(negedge clk);
      end
   else if (i == 15) begin  // Load first 16 words (M[N])
      wait (DUT_SHA_PROC_STATE == 4'h4);  // RAM loaded here
      @(negedge clk);
      end
      
   // Compare whats in the DUT's message schedule RAM with what's expected        
   if ((DUT_MSG_BLK_1[i] != test_msg_block[i]) & (i < (ByteSent % 16))) begin
      $fwrite (TESTFILE, "FAIL: MSG SCH RAM LOAD: MSG_BLK[i] -> DUT ACTUAL = 0x%08h  , EXPECTED = 0x%08h\n", i, msg_sch[i], test_msg_block[i]);
      err++;
      end
   else begin // Check if required binary 1 is appended correctly
      if (i == ByteSent % 16) begin // Word 0 to 15
        case (ByteSent % 4) // Bytes 0 to 3
          0:      begin if (DUT_MSG_BLK_1[i][31:24] != 8'h80) begin
                           $fwrite (TESTFILE, "FAIL: DUT_MSG_BLK_1[%0d][31:24] expected 0x80\n", i);
                           err++;
                           end
                        else begin 
                           //$fwrite (TESTFILE, "PASS: MSG SCH RAM LOC[%0d]  =  0X%08h\n", i, msg_sch[i]);
                            //msg_sch[i] = DUT_MSG_BLK_1[i];
                            end
                  end
          1:      begin if (DUT_MSG_BLK_1[i][23:16] != 8'h80) begin
                           $fwrite (TESTFILE, "FAIL: DUT_MSG_BLK_1[%0d][23:16] expected 0x80\n", i);
                           err++;
                           end
                        else begin 
                           //$fwrite (TESTFILE, "PASS: MSG SCH RAM LOC[%0d]  =  0X%08h\n", i, msg_sch[i]);
                           //msg_sch[i] = DUT_MSG_BLK_1[i];
                           end
                  end
          2:      begin if (DUT_MSG_BLK_1[i][15:8] != 8'h80) begin
                           $fwrite (TESTFILE, "FAIL: DUT_MSG_BLK_1[%0d][23:16] expected 0x80\n", i);
                           err++;
                           end
                        else begin 
                           //$fwrite (TESTFILE, "PASS: MSG SCH RAM LOC[%0d]  =  0X%08h\n", i, msg_sch[i]);
                           //msg_sch[i] = DUT_MSG_BLK_1[i];
                           end
                  end
          3:      begin if (DUT_MSG_BLK_1[i][7:0] != 8'h80) begin
                           $fwrite (TESTFILE, "FAIL: DUT_MSG_BLK_1[%0d][7:0] expected 0x80\n", i);
                           err++;
                           end
                        else begin 
                           //$fwrite (TESTFILE, "PASS: MSG SCH RAM LOC[%0d]  =  0X%08h\n", i, msg_sch[i]);
                           //msg_sch[i] = DUT_MSG_BLK_1[i];
                           end
                  end
          default:   $fwrite (TESTFILE, "ILLEGAL STATE\n");
        endcase
      end
   end

   if (i < 15) begin
      wait (DUT_SHA_PROC_STATE == 4'h1);   
      end
   else if (i == 15) begin
      wait (DUT_SHA_PROC_STATE == 4'hC);
      end      

   if (i <= 15) begin  
      msg_sch[i] = DUT_MSG_BLK_1[i]; // Load local test array with DUT
      $fwrite (TESTFILE, "PASS: MSG SCH RAM LOC[%0d]  =  0X%08h\n", i, msg_sch[i]);
      end
         
   // The message schedule is calculated here   
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
    
         ROR_WT2_7             = {msg_sch[i-15][6:0], msg_sch[i-15][31:7]};
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

         wait (DUT_SHA_PROC_STATE == 4'h4);
         @(negedge clk);
         @(negedge clk);

      end

      $fwrite (TESTFILE, "\n");

end  //for 

$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "Message Schedule Calculation Results \n");
$fwrite (TESTFILE, "-------------------------------------\n");

if (err > 0 ) begin
    $fwrite (TESTFILE, "FAIL:     Message schedule compare failed, error count = %0d \n",err);
    end
else begin
    $fwrite (TESTFILE, "PASSED:   Message schedule compare, error count = %0d \n",err); 
    end 
$fwrite (TESTFILE, "\n\n");


for (i = 0; i < 64; i++) begin
   $fwrite (TESTFILE, "MSG RAM[%0d] = 0x%08h\n", i, msg_sch[i]); 
   end
   
/****************************************************************
* END:    Message Schedule calculation
*  - Verify Message schedule RAM location 0 to 15 are loaded   
****************************************************************/


   
   
   
/**************************************
*     HASH CALCULATION
**************************************/

$fwrite (TESTFILE, "----->    Begin Hashing Operation    <-----\n\n");
    
// Initialize Hash Values 
for (i = 0; i < 8; i++) 
   begin
     HASH[i] = HASH_ini[i];
     end     

// Initialize working variables register also     


/**************************************************
   Hash process
**************************************************/  

for (j = 0; j < 64; j++) begin
/**************************************************
   T1 part
**************************************************/  
$fwrite (TESTFILE, "\n----------------\n");

$fwrite (TESTFILE, "Hash Round %0d: \n",j);
$fwrite (TESTFILE, "----------------\n");
$fwrite (TESTFILE, "\n");

    // Working variable update rising edge
	@(posedge DUT_update_Working_Var);

    K_val       =  KVal[j];
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
   T2 part
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

    
    
$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "a_reg  =  %08h \n",a_reg);
$fwrite (TESTFILE, "b_reg  =  %08h \n",b_reg);
$fwrite (TESTFILE, "c_reg  =  %08h \n",c_reg);
$fwrite (TESTFILE, "d_reg  =  %08h \n",d_reg);
$fwrite (TESTFILE, "e_reg  =  %08h \n",e_reg);
$fwrite (TESTFILE, "f_reg  =  %08h \n",f_reg);
$fwrite (TESTFILE, "g_reg  =  %08h \n",g_reg);
$fwrite (TESTFILE, "h_reg  =  %08h \n",h_reg);
   
$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "Error count = %0d\n", err);
    
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

  
      
/**************************************
*    Report Meta data in DUT
**************************************/
$fwrite (TESTFILE, "\n");
$fwrite (TESTFILE, "TEST001: MESSAGE METADATA @(%0t)\n", $time);
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
      $fwrite (TESTFILE, "TEST001: sha_sm_busy ASSERTED @(%0t)\n", $time);
      break;
      end
end


// Test if assertion window is exceeded
if (i == 200) begin
      $fwrite (TESTFILE, "FAIL TEST001: sha_sm_busy NOT ASSERTED @(%0t)\n", $time);
      $stop();
      end

/**************************************
*    SHA256 Process start window
**************************************/
      

/**********************************************
*  Test process busy bit (1 = true)
**********************************************/    
//AVAAddr = 32'h0000_3F00;
//BUS_RD(AVAAddr, AVAData);


// Wait for SHA SM busy to go false
// wait (DUT_sha_sm_busy == 1'b0);
repeat (100) @(posedge clk);





DUT_HASH[0] = DUT_H_reg_0;              // Hash Register 0
DUT_HASH[1] = DUT_H_reg_1;              // Hash Register 1
DUT_HASH[2] = DUT_H_reg_2;              // Hash Register 2
DUT_HASH[3] = DUT_H_reg_3;              // Hash Register 3
DUT_HASH[4] = DUT_H_reg_4;              // Hash Register 4
DUT_HASH[5] = DUT_H_reg_5;              // Hash Register 5
DUT_HASH[6] = DUT_H_reg_6;              // Hash Register 6
DUT_HASH[7] = DUT_H_reg_7;              // Hash Register 7



$fwrite(TESTFILE,"\n");

$fwrite(TESTFILE,"DUT MESSAGE:\n");
$fwrite(TESTFILE,"-----------\n");
$fwrite(TESTFILE,"          BYTE 0        BYTE 1        BYTE 2        BYTE 3\n");
$fwrite(TESTFILE,"-----------------------------------------------------------\n");
for (i = 0; i < 16; i++) 
   begin  
      $fwrite(TESTFILE,"Word %0d:    0x%02h          0x%02h          0x%02h          0x%02h   \n", i,               
                     DUT_MSG_BLK_1[i][31:24],DUT_MSG_BLK_1[i][23:16],DUT_MSG_BLK_1[i][15:8],DUT_MSG_BLK_1[i][7:0]); 
      end




$fwrite(TESTFILE,"\nNumber of Bytes Sent: 0x%08h (%0d) \n", ByteSent, ByteSent);

$fwrite(TESTFILE,"\n\n");
$fwrite(TESTFILE, "DUT SHA256 Results  @(%0t)  \n",  $realtime);
$fwrite(TESTFILE,"-----------------------------\n");
for (i = 0; i < 8; i++) 
   begin
      if (HASH[i] == DUT_HASH[i]) begin
         $fwrite(TESTFILE,"Hash[%0d] = 0x%08h - OK\n", i, HASH[i]);
         end
      else begin
         $fwrite(TESTFILE,"Hash[%0d] -  Expected 0x%08h,  Actual: 0x%08h\n", i, HASH[i], DUT_HASH[i]);    
         err++;
         end
      end

repeat (400) @(posedge clk);

//Console 
$display ("End Test: %0d cumulative errors @(%0t)\n", err,  $realtime);

$fwrite(TESTFILE,"\n");
$fwrite(TESTFILE,"*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*\n");
$fwrite(TESTFILE,"                END TEST                 \n");
$fwrite(TESTFILE,"*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*\n");

$fclose(TESTFILE);

$display ("FINISH:    SHA256 Verification..\n");
$display ("\nCumulative errors: %0d \n\n", err);

$stop();

end

  
  
  
  
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
