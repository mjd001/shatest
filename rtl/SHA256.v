/**********************************************************************
SHA-256 Core logic Module
- mjd 1/17/2019

NIST Publication Number:  FIPS 180-4  Secure Hash Standard (08/2015)
**********************************************************************/

module SHA256
   ( input      clk,
     input      reset_n,
     output   reg   [11:0]    RAM_RD_ADDR_SHA,
     output   reg   [11:0]    RAM_WR_ADDR_SHA,
     output   reg             RAM_WR_SHA,
     output   reg   [31:0]    Digest_OUT,
     output   reg             RAM4K_SEL,
     output          [7:0]    test_sig,
     input          [31:0]    RAM_Data,
     input          [15:0]    msg_byte_cnt,
     output   reg             sys_busy,     
     input                    HASH_PROC_GO  );

/**************************************************
     Message Schedule and Hash signals
**************************************************/
// Controller State machine outputs
reg            ld_meta;
//reg            sys_busy;
reg            start_sha_proc;
//reg            RAM4K_SEL;
reg            dec_msg_blocks;
reg            init_H;
reg   [2:0]    waits_CTRL;
reg   [2:0]    thread_CTRL;

reg   [3:0]    SHA_CTRL_SM;
//reg  [11:0]    RAM_WR_ADDR_SHA;
reg   [2:0]    HSEL;
//reg            RAM_WR_SHA;
reg   [2:0]    dat_sw_sel;

reg [1:0]  dat_sw_ref_cntr;
reg go_dat_sw_ref_cntr;

// Process state Machine outputs
reg            INC_SRC_RAM_ADDR;
reg   [5:0]    MSG_SCHED_RAM_WR_ADDR;
reg            msg_sch_ram_addr_src;
reg            MSG_SCHED_DATA_SOURCE;   
reg            MSG_SCHED_RAM_WE;
reg            update_H;
reg            init_WV;
reg            update_Working_Var;
reg            sha_sm_busy;
reg   [2:0]    waits;
reg   [3:0]    SHA_PROC_STATE;

reg            first_block_done;

/**************************************************
     Message description data
**************************************************/
reg   [17:0]    msg_bit_len;   // Bit count 
reg   [15:0]    num_msg_blks;  // Number of M(n)blocks
reg   [1:0]     byte_position; // which byte of the last word is the last bit in?
//reg   [15:0]    msg_byte_cnt;     // Set max for 65535 bytes
wire  [15:0]    msg_byte_cnt_ZIndex;
//reg   [11:0]    RAM_RD_ADDR_SHA;
reg   [15:0]    msg_byte_offset;
reg    [3:0]    track_ptr;
reg    [3:0]    waits_r;
reg   [15:0]    final_blk_wrd_cnt;

wire [31:0]   RAM_Data_OUT_p;


// Constant RAM
wire   [5:0]     K_const_ROM_addr;
wire   [31:0]    K_const_ROM_data;

// Message Schedule
wire   [5:0]     T_addr_sub_2;
wire   [5:0]     T_addr_sub_7;
wire   [5:0]     T_addr_sub_15;
wire   [5:0]     T_addr_sub_16;

wire   [31:0]    ROR_WT1_17;
wire   [31:0]    ROR_WT1_19;

wire   [31:0]    ROR_WT2_7;
wire   [31:0]    ROR_WT2_18;

wire   [31:0]    WPT1;
wire   [31:0]    WPT2;
reg    [31:0]    MSG_SCHED_LOGIC_OUT;
wire   [31:0]    MSG_SCHED_RAM_DAT_IN;

// Hash Process        
wire   [31:0]    T1_ROR_E_6;
wire   [31:0]    T1_ROR_E_11;
wire   [31:0]    T1_ROR_E_25;

wire   [31:0]    T1_ROR;
wire   [31:0]    T1_EFG;

wire   [31:0]    SHR_WT1_10;
wire   [31:0]    SHR_WT2_3;


wire   [31:0]    T2_ROR_A_2;
wire   [31:0]    T2_ROR_A_13;
wire   [31:0]    T2_ROR_A_22;
                 
wire   [31:0]    T2_ROR;
wire   [31:0]    T2_ABC;
                 
wire   [31:0]    T1;
wire   [31:0]    T2;
       
wire   [31:0]    dat_o_2;
wire   [31:0]    dat_o_7;
wire   [31:0]    dat_o_15;
wire   [31:0]    dat_o_16;

// Working Variables
reg    [31:0]    a_reg;
reg    [31:0]    b_reg;
reg    [31:0]    c_reg;
reg    [31:0]    d_reg;
reg    [31:0]    e_reg;
reg    [31:0]    f_reg;
reg    [31:0]    g_reg;
reg    [31:0]    h_reg;

// Hash Registers   
reg    [31:0]    H_reg_0;
reg    [31:0]    H_reg_1;
reg    [31:0]    H_reg_2;
reg    [31:0]    H_reg_3;
reg    [31:0]    H_reg_4;
reg    [31:0]    H_reg_5;
reg    [31:0]    H_reg_6;
reg    [31:0]    H_reg_7;

//reg    [31:0]    Digest_OUT;

/**************************************************
   Hash Initial Values (FIPS-180-4 sec. 5.3.4)
**************************************************/
localparam H0 = 32'h6a09e667;
localparam H1 = 32'hbb67ae85;
localparam H2 = 32'h3c6ef372;
localparam H3 = 32'ha54ff53a;
localparam H4 = 32'h510e527f;
localparam H5 = 32'h9b05688c;
localparam H6 = 32'h1f83d9ab;
localparam H7 = 32'h5be0cd19;



/******************************************************************************
                                  BEGIN
   ---------------------->>>     SHA-256     <<<----------------------
                                  LOGIC
******************************************************************************/  

/******************************************************************************
    BEGIN: Derive message process data from message byte count
******************************************************************************/
assign test_sig = 8'h00;   // HW debug acccess

always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
     msg_bit_len     <=   18'h00000;    
     msg_byte_offset <=   16'h0000;
     end
   else if (ld_meta) begin
     msg_bit_len     <=    {msg_byte_cnt[14:0], 3'b000};   // Derive number of bits in message from byte count (.GTE. 1)
     msg_byte_offset <=     msg_byte_cnt - 1'b1;     // Change message byte count from 1 index to zero index
     end
end


// Message byte count is 1 indexed
// Assign two bit zero indexed byte position
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
     byte_position   <=    2'b00;
     end     
   else if (ld_meta) begin
      if (msg_byte_cnt[1:0] == 2'b01) begin      // 1
         byte_position   <=    2'b00;            // byte slot zero
         end
      else if (msg_byte_cnt[1:0] == 2'b10) begin //2
         byte_position   <=    2'b01;            // byte slot one
         end
      else if (msg_byte_cnt[1:0] == 2'b11) begin // 3
         byte_position   <=    2'b10;            // byte slot two
         end
      else if (msg_byte_cnt[1:0] == 2'b00) begin // 4
         byte_position   <=    2'b11;            // byte zlot 
         end
   end
end


// zero index assignment.
assign msg_byte_cnt_ZIndex   =  msg_byte_cnt - 1'b1;


// Number of message blocks (1 indexed)
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      num_msg_blks   <=    16'h0000;
      end
   else if (ld_meta) begin
      num_msg_blks   <=    {6'b000000, msg_byte_cnt_ZIndex[15:6]}; //Derive # of SHA256 message blocks expected
      end
   else if (dec_msg_blocks) begin
      num_msg_blks   <=    num_msg_blks - 1'b1;  // Controller SM decrement's count 
      end
end


always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
       dat_sw_ref_cntr     <= 2'b00;
       go_dat_sw_ref_cntr  <= 1'b0;
       end
   else if (ld_meta) begin
      dat_sw_ref_cntr       <= dat_sw_ref_cntr + 1'b1;
      go_dat_sw_ref_cntr    <= 1'b1;
      end
   else begin
      if (dat_sw_ref_cntr == 2'b10) begin
         dat_sw_ref_cntr       <= 2'b00;
         end
      else begin
         if (go_dat_sw_ref_cntr) begin
            dat_sw_ref_cntr       <= dat_sw_ref_cntr + 1'b1;
            end
         end 
      end
end

// Put Reference location within the message block along side 
// the 
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
     RAM_RD_ADDR_SHA   <= 12'h000;    // 4K RAM Read address
     track_ptr         <=    4'h0;    // Location/Reference within block (M index)
     waits_r           <=    3'b000;
     end
   else if (HASH_PROC_GO) begin  // Signal to commence SHA256 process
     RAM_RD_ADDR_SHA   <= 12'h000;     // Reset the RAM address to begining
     track_ptr         <=    4'h0;     // SHA256 Message block word index [0:15]
     //waits_r           <=    3'b001;   // Insert one clock wait state
     end
   else if (INC_SRC_RAM_ADDR == 1'b1) begin
     RAM_RD_ADDR_SHA   <= RAM_RD_ADDR_SHA + 1'b1;
     track_ptr         <= track_ptr       + 1'b1;     // Location within block (M index)   
     //waits_r           <=    3'b001;
     end
   else begin
       waits_r <= {1'b0, waits_r[2:1]};
   end
end


// Derive # of 32 bit words in the message
// decrement word count, ensure non-negative
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      final_blk_wrd_cnt <= 16'h0000;
      end
   else if (ld_meta) begin
      final_blk_wrd_cnt <= {2'b00, msg_byte_cnt_ZIndex[15:2]};
      //final_blk_wrd_cnt <= {2'b00, msg_byte_cnt[15:2]};
      end
//   else if ((INC_SRC_RAM_ADDR == 1'b1) & (|final_blk_wrd_cnt))  begin 
//         final_blk_wrd_cnt <= final_blk_wrd_cnt - 1'b1;
//         end
   end
/******************************************************************************
    END:    Load message data
******************************************************************************/

/**************************************************************************
BEGIN SHA-256 - Interface Controller
------------------------------------
- Interfaces with bus agent
- Run hash processing logic on message block
- Track number of message blocks to process
- Track available RAM memory, reset pointer at start

Process
- User Loads 4096 X 32 RAM with Message, starting address
  is 0x0000.
- User writes length of message (bytes) to location 0x3F10
- User sets or clears endian bit (0 = Little) at location 0x3F14
- User writes start bit(0) to location 0x3F20, Logic asserts busy status. 
- User polls busy bit at location 0x3F20, bit 1.

**************************************************************************/
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      ld_meta          <=  1'b0;       // Load meta data 
      sys_busy         <=  1'b0;       // busy status
      start_sha_proc   <=  1'b0;       // Signal start to process SM
      RAM4K_SEL        <=  1'b0;       // Takes control of 4K RAM
      dec_msg_blocks   <=  1'b0;       // Decrements count of message blocks
      init_H           <=  1'b0;       // Load initial Hash values 1=true
      waits_CTRL       <=  3'b000;     // State wait shift register
      thread_CTRL      <=  3'b000;     // Zero padding tracking
      SHA_CTRL_SM      <=  4'b0000;    // State machine variable
      RAM_WR_ADDR_SHA  <= 12'h000;     // 4K RAM write address
      HSEL             <=  3'b000;     // Hash digest word select (for 4K RAM store)
      RAM_WR_SHA       <=  1'b0;       // 4K Write enable
      first_block_done <=  1'b0;
      dat_sw_sel       <=  3'b000;     // Msg Data
      end

/*****************************************************************
  STATE 0: Init/Idle.  Wait for host signal
         - Load metadata
         - Assert busy
*****************************************************************/
   else if (SHA_CTRL_SM == 4'b0000) begin
      if (HASH_PROC_GO) begin 
         RAM4K_SEL        <=  1'b1;        // RAM control 
         first_block_done <=  1'b0;        // Clear first block flag
         thread_CTRL      <=  3'b000;      // set to null
         ld_meta          <=  1'b1;        // Load meta data 
         init_H           <=  1'b1;        // Initialize Hash Table
         sys_busy         <=  1'b1;        // Set Busy status
         dat_sw_sel       <=  3'b000;      // Set mux: Msg Sch RAM <-  RAM
         waits_CTRL       <=  3'b000;      // Isert 1 clock wait state
         SHA_CTRL_SM      <=  4'b0001;
         end 
      end

/***************************************************************
  STATE 1: Message meta data is loaded. 
***************************************************************/
   else if ((SHA_CTRL_SM == 4'b0001) & (waits_CTRL == 3'b000)) begin
      ld_meta          <=  1'b0; 
      init_H           <=  1'b0;  
      start_sha_proc   <=  1'b1;          // Kick off SHA256 state machine
      dec_msg_blocks   <=  1'b0;
      SHA_CTRL_SM      <=  4'b0010;     
      end

/*************************************************************************
  STATE 2: Last Message Block : Generate a descriptor for last block
  
  SHA256 requires completed message blocks for correct processing.
  The last message block must contain: 
  - The bit length in the last two words (8 bytes) of the last block. 
  - Also, a binary '1' is to be appended to the last bit of the last 
    byte (This implementations uses 0x80).
  - Between the binary '1' appendage and the bit size field, the data 
    is zero padded. 
*************************************************************************/
   else if (SHA_CTRL_SM == 4'b0010) begin
      start_sha_proc   <=  1'b0;
      // We're on last message block and last word, finish up
      if ((num_msg_blks == 16'h0000) & (final_blk_wrd_cnt[3:0] == track_ptr)) begin

         if (track_ptr == 4'hF) begin
            SHA_CTRL_SM      <=  4'b0110;
            thread_CTRL      <=  3'b100;    // came from F
            if (byte_position == 2'b00) begin
               dat_sw_sel       <=  3'b011;       // (61) {RAM_Data[31:24],  8'h80}
               end
            else if (byte_position == 2'b01) begin
               dat_sw_sel       <=  3'b010;       // (62) {RAM_Data[31:16],  16'h8000}
               end
            else if (byte_position == 2'b10) begin
               dat_sw_sel       <=  3'b001;       // (63) {RAM_Data[31:8],    24'h800000}
               end
            else if (byte_position == 2'b11) begin
               dat_sw_sel        <= 3'b000;       // (64)  RAM_Data
               end
            end

         else if (track_ptr == 4'hE) begin
            thread_CTRL      <=  3'b010;    // came from E
            SHA_CTRL_SM      <=  4'b0110;
            if (byte_position == 2'b00) begin
               dat_sw_sel        <=  3'b011;         // (57) {RAM_Data[31:24],  8'h80}
               end
            else if (byte_position == 2'b01) begin
               dat_sw_sel       <=  3'b010;         // (58) {RAM_Data[31:16],  16'h8000}
               end
            else if (byte_position == 2'b10) begin
               dat_sw_sel       <=  3'b001;         // (59) {RAM_Data[31:8],    24'h800000}
               end
            else if (byte_position == 2'b11) begin
               dat_sw_sel        <=  3'b000;        // (60)  RAM_Data
               end
            end

         //else if (((track_ptr == 4'hD) & (byte_position == 2'b11)) & (dat_sw_ref_cntr == 2'b00)) begin 
         else if ((track_ptr == 4'hD) & (byte_position == 2'b11)) begin 
               thread_CTRL      <=  3'b001;    // came from D
               SHA_CTRL_SM      <=  4'b0110;  
               dat_sw_sel       <=  3'b000;         // (56) RAM_Data[31:0]
               end

         else begin  // Any other word 
               SHA_CTRL_SM      <=  4'b0011;
               if (byte_position == 2'b00)  begin
                  dat_sw_sel       <=  3'b011;    // {RAM_Data[31:24],  8'h80}
                  end
               else if (byte_position == 2'b01) begin
                  dat_sw_sel       <=  3'b010;    // {RAM_Data[31:16],  16'h8000}
                  end
               else if (byte_position == 2'b10) begin
                  dat_sw_sel       <=  3'b001;    // {RAM_Data[31:8],    24'h800000}
                  end
//               else if ((byte_position == 2'b11) & (dat_sw_ref_cntr == 2'b00)) begin
               else if (byte_position == 2'b11) begin
                  dat_sw_sel        <= 3'b000;    // RAM_Data
                  end
               end
        end

     // Not at last message block yet
     else if (|num_msg_blks) begin 
        SHA_CTRL_SM       <= 4'b1001;
        end

  end

/*********************************************
  STATE 3: Zero Padding 
*********************************************/
   else if (SHA_CTRL_SM == 4'b0011) begin
      if (MSG_SCHED_RAM_WE) begin
         if (byte_position == 2'b11) begin
            dat_sw_sel        <= 3'b100;      //  32'h80000000
            first_block_done  <= 1'b1;
            SHA_CTRL_SM       <= 4'b0100;
            end
         else begin
            dat_sw_sel        <= 3'b110;      //  32'h00000000
            SHA_CTRL_SM       <= 4'b0100;
            end
         end
   end
   
/********************************************
  STATE 4: Insert Bit count here
********************************************/
   else if (SHA_CTRL_SM == 4'b0100) begin
      if (MSG_SCHED_RAM_WE) begin
        if (MSG_SCHED_RAM_WR_ADDR == 6'hE) begin
            dat_sw_sel        <= 3'b101;      //  {19'h00000, msg_bit_len}
            SHA_CTRL_SM       <= 4'b1001;
            end
        else begin
           if ((byte_position == 2'b11) & (first_block_done == 1'b0)) begin
              dat_sw_sel        <= 3'b100;      //  32'h80000000
              first_block_done  <= 1'b1;
              end
           else begin
              dat_sw_sel        <= 3'b110;      //  32'h00000000
              end
        end
     end
  end
   
   
/********************************************
  STATE 5: Normal end
********************************************/
   else if (SHA_CTRL_SM == 4'b0101) begin
      if (track_ptr == 4'hF) begin         
         dat_sw_sel        <= 3'b101;      //  {19'h00000, msg_bit_len}
         SHA_CTRL_SM       <= 4'b1001;
         end
   end

/********************************************
  STATE 6: Extra message block
********************************************/
   else if (SHA_CTRL_SM == 4'b0110) begin
  
     if (track_ptr == 4'hE) begin
         if (thread_CTRL == 3'b001) begin // Came from D
            dat_sw_sel       <=    3'b100;   //32'h80000000  
            end
         end

     else if (track_ptr == 4'hF) begin
        if (msg_byte_cnt[5:0] == 6'h00) begin   
           dat_sw_sel   <=  3'b000;       //
           SHA_CTRL_SM  <=  4'b0111;
           end
         else begin
            if (thread_CTRL == 3'b001) begin  // Came from D 
               dat_sw_sel   <=  3'b110;       //32'h00000000
               SHA_CTRL_SM  <=  4'b0111;
               end
            else if (thread_CTRL == 3'b010) begin  // Came from E
               if (byte_position == 2'b11) begin
                  dat_sw_sel       <=    3'b100;   //32'h80000000 
                  SHA_CTRL_SM      <=  4'b0111;
                  end
               else begin
                  dat_sw_sel       <=  3'b110;   //32'h00000000     
                  SHA_CTRL_SM      <=  4'b0111;
                  end                  
               end
            else if (thread_CTRL == 3'b100) begin // Came from F
               if (MSG_SCHED_RAM_WE) begin   
                  SHA_CTRL_SM      <=  4'b0111;               
                  end
               end
            end 
        end   
    end
/********************************************
  STATE 7: Wait to finish hash
********************************************/
   else if (SHA_CTRL_SM == 4'b0111) begin
      if (sha_sm_busy == 1'b0) begin
         if (msg_byte_cnt[5:0] == 6'h00) begin   // last byte is right on 64 byte or 1 block boundary
            dat_sw_sel       <=   3'b100;      // 32'h80000000 - first word of extended block
            end
         else begin
            dat_sw_sel       <=   3'b110;      // 32'h00000000 - 
            end
         start_sha_proc      <=   1'b1;
         SHA_CTRL_SM         <=   4'b1000;
         end
   end

/********************************************
  STATE 8: Message length word
********************************************/
   else if (SHA_CTRL_SM == 4'b1000) begin
      start_sha_proc      <=  1'b0;
      if (track_ptr == 4'hF) begin
         dat_sw_sel        <= 3'b101;      //  {19'h00000, msg_bit_len}
         SHA_CTRL_SM       <= 4'b1001;
         end
      else if ((track_ptr == 4'h0) & (msg_byte_cnt[5:0] == 6'h00)) begin
         dat_sw_sel       <=   3'b100;      // 32'h80000000
         end
      else begin
         dat_sw_sel        <= 3'b110;      //  {32'h0000_0000}
         end
   end


/********************************************
  STATE 9: Wait for hash process to 
           complete
********************************************/
   else if (SHA_CTRL_SM == 4'b1001) begin
      if (sha_sm_busy ==  1'b0) begin 
         if (|num_msg_blks) begin   // Last block? 
           dat_sw_sel       <=   3'b000;      // Msg RAM <-  RAM
           dec_msg_blocks   <=   1'b1;
           first_block_done <=   1'b1;
           SHA_CTRL_SM      <=   4'b0001;
           end
         else begin   // Done, copy hash into RAM for mater to read
            RAM_WR_ADDR_SHA  <=  12'h000;   // Offset address 
            RAM_WR_SHA       <=   1'b1;
            HSEL             <=   3'b000;
            dat_sw_sel       <=   3'b000;      // Msg RAM <-  RAM
            SHA_CTRL_SM      <=   4'b1010;
           end
         end
      end

/********************************************
  STATE 10 : Copy result (1)
********************************************/
   else if (SHA_CTRL_SM == 4'b1010) begin
      HSEL             <=   HSEL + 1'b1;
      RAM_WR_ADDR_SHA  <=   RAM_WR_ADDR_SHA + 1'b1;
      SHA_CTRL_SM      <=   4'b1011;
      end

/********************************************
  STATE 11 : Copy result (2)
********************************************/
   else if (SHA_CTRL_SM == 4'b1011) begin
      if (HSEL == 3'b111) begin
         sys_busy         <=   1'b0;        // Clear Busy status
         RAM_WR_ADDR_SHA  <=  12'h000;   // Offset address 
         RAM_WR_SHA       <=   1'b0;
         HSEL             <=   3'b000;
         RAM4K_SEL        <=   1'b0;        // Bus interface 
         SHA_CTRL_SM      <=   4'b0000;
         end
      else begin
         SHA_CTRL_SM      <=   4'b1010;
         end
      end

/***********************************************
   DEFAULT
***********************************************/
   else begin
      start_sha_proc   <=   1'b0;
      waits_CTRL       <=  {1'b0, waits_CTRL[2:1]};
      end
end
/***********************************************
   END:   SHA-256 - Interface Controller
***********************************************/


/****************************************************
RAM to MSG RAM Data Mux
-----------------------
This logic provides the data path from RAM as well 
as generating zero padding and appending bit count
to last message block.
****************************************************/
assign RAM_Data_OUT_p = (dat_sw_sel == 3'b000) ?  RAM_Data :                      // Normal (RAM read -> Msg Sch RAM write)
                        (dat_sw_sel == 3'b001) ? {RAM_Data[31:8],        8'h80}:  // MASK: Last byte is in slot 2 of current word
                        (dat_sw_sel == 3'b010) ? {RAM_Data[31:16],    16'h8000}:  // MASK: Last byte is in slot 1 of current word
                        (dat_sw_sel == 3'b011) ? {RAM_Data[31:24],  24'h800000}:  // MASK: Last byte is in slot 0 of current word
                        (dat_sw_sel == 3'b100) ? 32'h80000000:                        // Last byte blot 3 of previous word 
                        (dat_sw_sel == 3'b101) ? {2'b00, 12'h000, msg_bit_len}:            // Append Bit length (last 4 bytes for this application)
                        (dat_sw_sel == 3'b110) ? 32'h00000000 :  32'h00000000;        // Insert Zero Pad word


/*************************************************************************
BEGIN: SHA256 Process state machine
-----------------------------------
Start:
- Load Initial Hash values from hash ROM
- Load Working Variables from the hash table
- Reset Message Scheduler RAM address 

Message Schedule:
- Select 4K RAM as input to Message Scheduler RAM
- Load sixteen message words [0:15] into Message Scheduler RAM from 
  4K RAM
- When done, select Message Schedule logic output. The result 
  will be looped back to as input to Message Scheduler RAM
  location [16:63]
- At message scheduler RAM address [63] Reset Message Scheduler 
  RAM address 

Hash Process:
- The message schedule RAM contents, pre-defined constants and
  working registers will be inputs to this process.
- Index constants table and and message schedule RAM, accumulate
  results in working variable registers.
- When Message Scheduler RAM address finishes address 64 stop
- Compute and store intermediate hash value.

*************************************************************************/
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      INC_SRC_RAM_ADDR                 <=    1'b0;      // Increment Message Schedule RAM pointer
      MSG_SCHED_RAM_WR_ADDR            <=    6'b000000;
      msg_sch_ram_addr_src             <=    1'b0;      // Select Message Schedule RAM address type: 1=offset, 0=normal
      MSG_SCHED_DATA_SOURCE            <=    1'b0;      // Select Message Scheduler RAM data source (1=RAM, 0=MSG_SCHED_LOGIC_OUT)
      MSG_SCHED_RAM_WE                 <=    1'b0;      // Message Schedule RAM write enable
      update_H                         <=    1'b0;      // Add final working value to current hash
      init_WV                          <=    1'b0;      // Init Working Values
      update_Working_Var               <=    1'b0;      // Update working values 1=true
      sha_sm_busy                      <=    1'b0;      // SHA256 in process      
      waits                            <=    3'b000;    // wait states
      SHA_PROC_STATE                   <=    4'b0000;   // State machine state pointer
      end

/********************************************
  STATE 0: IDLE - SHA256 entry
********************************************/
   else if (SHA_PROC_STATE == 4'b0000) begin
      if (start_sha_proc == 1'b1) begin  // Start signal from control SM
         msg_sch_ram_addr_src      <=     1'b0;    // Use MS RAM address with no offset
         MSG_SCHED_DATA_SOURCE     <=     1'b1;    // 4K RAM is used as data input       
         MSG_SCHED_RAM_WE          <=     1'b0;    // Message Schedule parallel RAM #1 write enable
         sha_sm_busy               <=     1'b1;    // Assert busy bit
         init_WV                   <=     1'b1;    // Init hash working variables 
         waits                     <=     3'b000;  // delay one clock    
         SHA_PROC_STATE            <=     4'b0001;
         end
   end

/*************************************************
  STATE 1: Load Message Schedule RAM[0:15] with
  message block from 4K RAM
*************************************************/
   else if ((SHA_PROC_STATE == 4'b0001) & (waits == 3'b000))  begin
         init_WV                    <=  1'b0;
         if (MSG_SCHED_RAM_WR_ADDR == 12'h00f) begin
            msg_sch_ram_addr_src       <=  1'b1;        // Change to address offsets
            INC_SRC_RAM_ADDR           <=  1'b1;
            MSG_SCHED_RAM_WE           <=  1'b1;        // Message Schedule parallel RAM #1 write enable
            SHA_PROC_STATE             <=  4'b0011;
            end
         else begin
            MSG_SCHED_RAM_WE           <=  1'b1;        // Message Schedule parallel RAM #1 write enable
            INC_SRC_RAM_ADDR           <=  1'b1;
            SHA_PROC_STATE             <=  4'b0010;
            end
      end

/*************************************************
  STATE 2: Load Message Schedule RAM [0:15] with
  M(N).
*************************************************/
   else if (SHA_PROC_STATE == 4'b0010) begin
         MSG_SCHED_RAM_WE         <=  1'b0;                      
         INC_SRC_RAM_ADDR         <=  1'b0;
         MSG_SCHED_RAM_WR_ADDR    <=  MSG_SCHED_RAM_WR_ADDR + 1'b1;
         SHA_PROC_STATE           <=  4'b1110;                   
         end

/******************************************************
  STATE 14: Replace this state with a delay
******************************************************/         
   else if (SHA_PROC_STATE == 4'b1110) begin   
        SHA_PROC_STATE           <=  4'b0001;
        end

/******************************************************
  STATE 3: Calculate message schedule (1)
******************************************************/
   else if ((SHA_PROC_STATE == 4'b0011) &  (waits == 3'b000))   begin
      MSG_SCHED_RAM_WE         <=  1'b0;
      INC_SRC_RAM_ADDR         <=  1'b0;
      init_WV                  <=  1'b0;           // Init working variables here
      MSG_SCHED_DATA_SOURCE    <=  1'b0;           // Switch from 4K RAM to MS RAM
      if (MSG_SCHED_RAM_WR_ADDR  == 6'h3F)  begin  
         SHA_PROC_STATE        <=  4'b0101;        // Go to Hash process state
         MSG_SCHED_RAM_WR_ADDR <=  6'b000000;
         MSG_SCHED_RAM_WE      <=  1'b0;
         end
      else begin
         MSG_SCHED_RAM_WR_ADDR <=  MSG_SCHED_RAM_WR_ADDR + 1'b1;
         MSG_SCHED_RAM_WE      <=  1'b0;
         SHA_PROC_STATE        <=  4'b0100;    // Go to Hash process state
      end
   end

/******************************************************
  STATE 4: Calculate message schedule (2) 
******************************************************/
   else if (SHA_PROC_STATE == 4'b0100) begin
        SHA_PROC_STATE             <=  4'b1100;    // Go to Hash process state
     end 

/******************************************************
  STATE 4b: Calculate message schedule (2) 
******************************************************/
   else if (SHA_PROC_STATE == 4'b1100) begin
        MSG_SCHED_RAM_WE           <=  1'b1;
        waits                      <=  3'b000;
        SHA_PROC_STATE             <=  4'b0011;    // Go to Hash process state
     end   

/********************************************************
  STATE 5: Done creating Message Schedule, reset the RAM
           address and return to normal mode
********************************************************/
   else if (SHA_PROC_STATE == 4'b0101) begin
     msg_sch_ram_addr_src     <=  1'b0;         // Change address back to normal
     SHA_PROC_STATE           <=  4'b0110;      // Go to Hash process state
     end   

/******************************************************
  STATE 6: De-assert Reset
******************************************************/
   else if (SHA_PROC_STATE == 4'b0110) begin
      SHA_PROC_STATE           <=  4'b0111;
      end

/*************************************************
  STATE 7: Hash Function (1)
*************************************************/
   else if (SHA_PROC_STATE == 4'b0111) begin
      update_Working_Var       <=  1'b1;         // Update working variables         
      SHA_PROC_STATE           <=  4'b1000;
      end

/*************************************************
  STATE 8: Hash Function (2)
*************************************************/
   else if (SHA_PROC_STATE == 4'b1000) begin
      update_Working_Var    <=  1'b0;                   
      if (MSG_SCHED_RAM_WR_ADDR  == 6'h3F) begin
         update_H              <=  1'b1;         //Update Hash 
         SHA_PROC_STATE        <=  4'b1011;      //And finish the message
         end
      else begin
         MSG_SCHED_RAM_WR_ADDR    <=  MSG_SCHED_RAM_WR_ADDR + 1'b1;
         SHA_PROC_STATE           <=  4'b1001;
         end
   end

/*************************************************
  STATE 9: Change address from offsets to normal
*************************************************/
   else if (SHA_PROC_STATE == 4'b1001) begin
      msg_sch_ram_addr_src     <=  1'b0;        
      SHA_PROC_STATE           <=  4'b1010;
      end

/*************************************************
  STATE 10:Update Working Variables for next round  
*************************************************/
   else if (SHA_PROC_STATE == 4'b1010) begin
      update_Working_Var    <=  1'b1;                 
      SHA_PROC_STATE        <=  4'b1000;
      end

/*************************************************
  STATE 11: Finish and go to idle
*************************************************/
   else if (SHA_PROC_STATE == 4'b1011) begin
      update_H              <=  1'b0;
      MSG_SCHED_RAM_WR_ADDR <=  6'b000000;
      MSG_SCHED_RAM_WE      <=  1'b0;
      update_Working_Var    <=  1'b0;         // Deassert
      sha_sm_busy           <=  1'b0;
      SHA_PROC_STATE        <=  4'b0000;
      end

/*************************************************
  Default:
*************************************************/
   else begin
      waits   <=  {1'b0, waits[2:1]};
   end

end
/*************************************************
       END SHA256 PROCESS SM 
*************************************************/

/***************************************
  Constants ROM (FIPS-180-4 sec. 4.2.2)
***************************************/
sha256_k_constants  K_VAL
(
     .addr(K_const_ROM_addr),  //IN [5:0]
     .K(K_const_ROM_data)      //OUT[31:0]
);

assign K_const_ROM_addr = MSG_SCHED_RAM_WR_ADDR;

/**********************************************
   Calculate message schedule addresses
   for parallel message schedule RAMs
**********************************************/
assign T_addr_sub_2  = (msg_sch_ram_addr_src)  ? (MSG_SCHED_RAM_WR_ADDR - 6'h02) : MSG_SCHED_RAM_WR_ADDR;
assign T_addr_sub_7  = (msg_sch_ram_addr_src)  ? (MSG_SCHED_RAM_WR_ADDR - 6'h07) : MSG_SCHED_RAM_WR_ADDR;
assign T_addr_sub_15 = (msg_sch_ram_addr_src)  ? (MSG_SCHED_RAM_WR_ADDR - 6'h0F) : MSG_SCHED_RAM_WR_ADDR;
assign T_addr_sub_16 = (msg_sch_ram_addr_src)  ? (MSG_SCHED_RAM_WR_ADDR - 6'h10) : MSG_SCHED_RAM_WR_ADDR;

/*************************************************
    Select source data for message scheduler
    RAM input
    1 = 4096 RAM
    0 = Wt calculation 
*************************************************/
assign MSG_SCHED_RAM_DAT_IN = (MSG_SCHED_DATA_SOURCE) ? RAM_Data_OUT_p : MSG_SCHED_LOGIC_OUT;


/*************************************** 
  Message schedule RAM 
  Parallel RAMs 64 locations X 32 bits
***************************************/
ram_infer_sha sched_mem_1 //(T-2)
(
  .data(MSG_SCHED_RAM_DAT_IN),         // IN [31:0]
  .read_addr(T_addr_sub_2),            // IN [5:0]
  .write_addr(MSG_SCHED_RAM_WR_ADDR),  // IN [5:0]
  .we(MSG_SCHED_RAM_WE),               // IN
  .clk(clk),                           // IN
  .q(dat_o_2)                          // OUT [31:0]
);

ram_infer_sha sched_mem_2 //(T-7)
(
  .data(MSG_SCHED_RAM_DAT_IN),           // IN [31:0]
  .read_addr(T_addr_sub_7),              // IN [5:0]
  .write_addr(MSG_SCHED_RAM_WR_ADDR),    // IN [5:0]
  .we(MSG_SCHED_RAM_WE),                 // IN
  .clk(clk),                             // IN
  .q(dat_o_7)                            // OUT [31:0]
);

ram_infer_sha sched_mem_3 //(T-15)
(
  .data(MSG_SCHED_RAM_DAT_IN),          // IN [31:0]
  .read_addr(T_addr_sub_15),            // IN [5:0]
  .write_addr(MSG_SCHED_RAM_WR_ADDR),   // IN [5:0]
  .we(MSG_SCHED_RAM_WE),                // IN
  .clk(clk),                            // IN
  .q(dat_o_15)                          // OUT [31:0]
);

ram_infer_sha sched_mem_4 //(T-16)
(
  .data(MSG_SCHED_RAM_DAT_IN),          //  IN [31:0]
  .read_addr(T_addr_sub_16),            //  IN [5:0]
  .write_addr(MSG_SCHED_RAM_WR_ADDR),   //  IN [5:0]
  .we(MSG_SCHED_RAM_WE),                //  IN
  .clk(clk),                            //  IN
  .q(dat_o_16)                          // OUT [31:0]
);

/**************************************************
     Message Schedule pt. 1 Rotate and Shift
**************************************************/ 
assign ROR_WT1_17 = {dat_o_2[16:0] ,dat_o_2[31:17]};
assign ROR_WT1_19 = {dat_o_2[18:0] ,dat_o_2[31:19]};
assign SHR_WT1_10 = {10'h000 ,dat_o_2[31:10]};

/**************************************************
     Message Schedule pt. 2 Rotate and Shift
**************************************************/ 
assign ROR_WT2_7  = {dat_o_15[6:0] ,dat_o_15[31:7]};
assign ROR_WT2_18 = {dat_o_15[17:0] ,dat_o_15[31:18]};
assign SHR_WT2_3  = {3'b000 ,dat_o_15[31:3]};

/**************************************************
 Message Schedule pt. 3 
**************************************************/  
assign WPT1  =  dat_o_7  + (ROR_WT1_17 ^ ROR_WT1_19 ^ SHR_WT1_10);
assign WPT2  =  dat_o_16 + (ROR_WT2_7  ^ ROR_WT2_18 ^ SHR_WT2_3);

/**************************************************
 Message Schedule add both parts 
**************************************************/  
always @(posedge clk or negedge reset_n) begin 
  if (~reset_n) begin
     MSG_SCHED_LOGIC_OUT <= 32'h0000_0000;
     end
  else begin
     MSG_SCHED_LOGIC_OUT <=  WPT1 + WPT2; // Message Schedule output
     end
end

/**************************************************
   SHA 256 message block process
   T1 part
**************************************************/  
assign T1_ROR_E_6  = {e_reg[5:0]  ,e_reg[31:6]};   //ROR(6)
assign T1_ROR_E_11 = {e_reg[10:0] ,e_reg[31:11]};  //ROR(11)
assign T1_ROR_E_25 = {e_reg[24:0] ,e_reg[31:25]};  //ROR(25)

assign T1_ROR      = T1_ROR_E_6 ^ T1_ROR_E_11 ^ T1_ROR_E_25;
assign T1_EFG      = ((e_reg & f_reg) ^ (~e_reg & g_reg));

assign T1 =  h_reg + T1_ROR + T1_EFG + dat_o_2 + K_const_ROM_data; // Hash process PT 1 output       

/**************************************************
   SHA 256 message block process
   T2 part
**************************************************/  
assign T2_ROR_A_2  = {a_reg[1:0]  ,a_reg[31:2]};
assign T2_ROR_A_13 = {a_reg[12:0] ,a_reg[31:13]};
assign T2_ROR_A_22 = {a_reg[21:0] ,a_reg[31:22]};

assign T2_ROR      =  T2_ROR_A_2 ^ T2_ROR_A_13 ^ T2_ROR_A_22;
assign T2_ABC      = ((a_reg & b_reg) ^ (a_reg & c_reg) ^ (b_reg & c_reg));

assign T2          = T2_ROR + T2_ABC;              // Hash process PT 2 output


/**************************************************
  Working Variables
**************************************************/                          
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin
      a_reg <= 32'h0;
      b_reg <= 32'h0;
      c_reg <= 32'h0;
      d_reg <= 32'h0;
      e_reg <= 32'h0;
      f_reg <= 32'h0;
      g_reg <= 32'h0;
      h_reg <= 32'h0;
      end
   else if (init_WV) begin // Init working variables 
      a_reg <=  H_reg_0;
      b_reg <=  H_reg_1;
      c_reg <=  H_reg_2;
      d_reg <=  H_reg_3;
      e_reg <=  H_reg_4;
      f_reg <=  H_reg_5;
      g_reg <=  H_reg_6;
      h_reg <=  H_reg_7;
      end
   else if (update_Working_Var) begin // Update as part of hash process 
      a_reg <=  T1 + T2;    //Hash process part 1 and 2
      b_reg <=  a_reg;
      c_reg <=  b_reg;
      d_reg <=  c_reg;
      e_reg <=  d_reg + T1;
      f_reg <=  e_reg;
      g_reg <=  f_reg;
      h_reg <=  g_reg;
      end
end


/**************************************************
  Update intermediate hash value
**************************************************/                            
always @(posedge clk or negedge reset_n) begin
   if (reset_n == 1'b0) begin                    
      H_reg_0 <=  32'h0;
      H_reg_1 <=  32'h0;
      H_reg_2 <=  32'h0;
      H_reg_3 <=  32'h0;
      H_reg_4 <=  32'h0;
      H_reg_5 <=  32'h0;
      H_reg_6 <=  32'h0;
      H_reg_7 <=  32'h0;
      end
   else if (init_H) begin                    
      H_reg_0 <=  H0;
      H_reg_1 <=  H1;
      H_reg_2 <=  H2;
      H_reg_3 <=  H3;
      H_reg_4 <=  H4;
      H_reg_5 <=  H5;
      H_reg_6 <=  H6;
      H_reg_7 <=  H7;
      end
   else if (update_H) begin
      H_reg_0 <=  H_reg_0 + a_reg;
      H_reg_1 <=  H_reg_1 + b_reg;
      H_reg_2 <=  H_reg_2 + c_reg;
      H_reg_3 <=  H_reg_3 + d_reg;
      H_reg_4 <=  H_reg_4 + e_reg;
      H_reg_5 <=  H_reg_5 + f_reg;
      H_reg_6 <=  H_reg_6 + g_reg;
      H_reg_7 <=  H_reg_7 + h_reg;
      end
end 
                         
// Hash digest data path to RAM
always @(*) begin 
   case (HSEL)
      3'b000   :  Digest_OUT <= H_reg_0;
      3'b001   :  Digest_OUT <= H_reg_1;
      3'b010   :  Digest_OUT <= H_reg_2;
      3'b011   :  Digest_OUT <= H_reg_3;
      3'b100   :  Digest_OUT <= H_reg_4;
      3'b101   :  Digest_OUT <= H_reg_5;
      3'b110   :  Digest_OUT <= H_reg_6;
      3'b111   :  Digest_OUT <= H_reg_7;
   endcase
end                                      
                         
                         
                         
endmodule






        
     