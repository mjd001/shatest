/***************************************************************
    Support functions forWDSA B10M31 verify package  
***************************************************************/

package EMTest;

function automatic int MINV (input  integer arg_in);
    integer a, b, y, z, i;

    a = 1;
    b = 0;
    y = 32'(arg_in);
    z = 32'h7FFFFFFF;


    while(1) begin

        i = 31;
        while(!(y & 1)) begin
            y >>= 1;
            i--;
        end

        a = ((a << i) | (a >> (31-i))) & 32'h7FFFFFFF;

        if(y == 1) begin
            return a;
        end

        i = a;
        a = (a + b) % 32'h7FFFFFFF;
        b = i;

        i = y;
        y = y + z;
        z = i;
    end
endfunction


/*-------------------------------------------------------------------------------*/

function automatic void msg_sched( input   integer        last_word_loc, //[0:15]:
                                   inout   logic   [31:0] msg_sch_array[0:63],
                                   output  logic   [31:0] msg_sch_array_2[0:63],
                                   input   integer        byte_slot,
                                   input   logic   [31:0] msg_bit_cnt,
                                   input   logic   [31:0] msg_blocks,
                                   input   integer        FP,
                                   output  integer        extra_msg_blk
                                   );

integer i, j, k, z;

logic [31:0] msg_sch_exp[0:63];
logic [31:0] ROR_WT1_17;         
logic [31:0] ROR_WT1_19;        
logic [31:0] SHR_WT1_10;         
logic [31:0] ROR_WT2_7;          
logic [31:0] ROR_WT2_18;         
logic [31:0] SHR_WT2_3;          
logic [31:0] WPT1;               
logic [31:0] WPT2;               
logic [31:0] MSG_SCHED_LOGIC_OUT;
logic [31:0] extra_msg_sch_array[0:63];


// Clear scratch message array
for (i = 0; i < 64; i++)  begin
   msg_sch_exp[i] = 32'h0000_0000;
   end

// Flag partial block required
extra_msg_blk = 0;

// Format data into message block 
for (i = 0; i < 16; i++) begin
  
  if ((i == last_word_loc) & (msg_blocks == 0)) begin

    if (last_word_loc <= 12 ) begin
       if ( byte_slot == 0 ) begin
          msg_sch_exp[i]  =  {msg_sch_array[i][31:24], 24'h800000};
          k         = last_word_loc + 1;
          end
       else if (byte_slot == 1) begin
          msg_sch_exp[i]  =  {msg_sch_array[i][31:16], 16'h8000};
          k         = last_word_loc + 1;
          end
       else if (byte_slot == 2) begin
          msg_sch_exp[i]  =  {msg_sch_array[i][31:8], 8'h80};
          k         = last_word_loc + 1;
          end
       else if (byte_slot == 3) begin
          msg_sch_exp[i]      =  msg_sch_array[i];   // +1
          msg_sch_exp[i+1]    =  32'h80000000;       // +2
          k         = last_word_loc + 2;
          end
       for (j = k; j < 15; j++) begin
          msg_sch_exp[j]  =  32'h00000000;
          end
          msg_sch_exp[j] = msg_bit_cnt; // Append Bit count
          i = j;
       end


     else if (last_word_loc == 13) begin
       if (byte_slot == 0) begin
          msg_sch_exp[i]     =  {msg_sch_array[i][31:24], 24'h800000}; //13
          msg_sch_exp[i+1]   =  32'h00000000;                          //14
          msg_sch_exp[i+2]   =  msg_bit_cnt;                           //15
          i+=3;
          end
       else if (byte_slot == 1) begin
          msg_sch_exp[i]    =  {msg_sch_array[i][31:16], 16'h8000}; //13
          msg_sch_exp[i+1]  =  32'h00000000;                      //14  
          msg_sch_exp[i+2]  =  msg_bit_cnt;                       //15
          i+=3;
          end
       else if (byte_slot == 2) begin
          msg_sch_exp[i]    =  {msg_sch_array[i][31:8], 8'h80}; //13
          msg_sch_exp[i+1]  =  32'h00000000;                    //14
          msg_sch_exp[i+2]  =  msg_bit_cnt;                     //15
          i+=3;
          end
       else if (byte_slot == 3) begin          
          extra_msg_blk     =  1;    // Set extra message blcok status
          msg_sch_exp[i]    =  msg_sch_array[i];  // 13
          msg_sch_exp[i+1]  =  32'h80000000;      // 14
          msg_sch_exp[i+2]  =  32'h00000000;      // 15
          i+=3;
          // Extra block
          for (j = 0; j < 15; j++) begin
             extra_msg_sch_array[j]  =  32'h00000000;
             end
           extra_msg_sch_array[j] = msg_bit_cnt;   // Append Bit count
          end      
       end


     else if (last_word_loc == 14) begin
        extra_msg_blk     =  1;    // Set extra message block status
        msg_sch_exp[i] = (byte_slot == 0) ?  {msg_sch_array[i][31:24], 24'h800000} : // 14
                         (byte_slot == 1) ?  {msg_sch_array[i][31:16], 16'h8000}   :
                         (byte_slot == 2) ?  {msg_sch_array[i][31:8],   8'h80}     :
                         (byte_slot == 3) ?   msg_sch_array[i] : 32'h00000000;
        msg_sch_exp[i+1] = (byte_slot == 3) ? 32'h80000000: 32'h00000000; // 15
        i+=2;
        for (j=0; j < 15; j++) begin
           extra_msg_sch_array[j] =  32'h00000000;
           end
        extra_msg_sch_array[j] = msg_bit_cnt;   // Append Bit count
        end
        
        
     else if (last_word_loc == 15) begin
        extra_msg_blk     =  1;    // Set extra message blcok status
        msg_sch_exp[i] = (byte_slot == 0) ?  {msg_sch_array[i][31:24], 24'h800000} : // 15
                         (byte_slot == 1) ?  {msg_sch_array[i][31:16], 16'h8000}   :
                         (byte_slot == 2) ?  {msg_sch_array[i][31:8],   8'h80}     :
                         (byte_slot == 3) ?   msg_sch_array[i] : 32'h00000000;
        i++;
        for (j=0; j < 15; j++) begin
           extra_msg_sch_array[j] = ((byte_slot == 3) & (j == 0)) ?  32'h80000000 : 32'h00000000 ;
           end
        extra_msg_sch_array[j] = msg_bit_cnt;   // Append Bit count
     end
   end
   
   else begin
      msg_sch_exp[i] = msg_sch_array[i]; 
      end     
  
end  //FOR LOOP



// Calculate message schedule for the first block   
    for (i = 16; i < 64; i++)
       begin
         ROR_WT1_17            = {msg_sch_exp[i-2][16:0], msg_sch_exp[i-2][31:17]};
         ROR_WT1_19            = {msg_sch_exp[i-2][18:0], msg_sch_exp[i-2][31:19]};
         SHR_WT1_10            = {10'h000, msg_sch_exp[i-2][31:10]};
         
         ROR_WT2_7             = {msg_sch_exp[i-15][6:0], msg_sch_exp[i-15][31:7]};
         ROR_WT2_18            = {msg_sch_exp[i-15][17:0], msg_sch_exp[i-15][31:18]};
         SHR_WT2_3             = {3'b000, msg_sch_exp[i-15][31:3]};
                               
         WPT1    = msg_sch_exp[i-7]  + (ROR_WT1_17 ^ ROR_WT1_19 ^ SHR_WT1_10);
         WPT2    = msg_sch_exp[i-16] + (ROR_WT2_7  ^ ROR_WT2_18 ^ SHR_WT2_3);
      
         MSG_SCHED_LOGIC_OUT   =    WPT1 + WPT2;
         
         msg_sch_exp[i] = MSG_SCHED_LOGIC_OUT;
         end

// Copy the result to the interface array
   for (i = 0; i < 64; i++) begin
      msg_sch_array[i] = msg_sch_exp[i];
      end


// Do last/extra block if nessesary
if (extra_msg_blk) begin
   for (i = 0; i < 16; i++) begin
      msg_sch_exp[i]  =  extra_msg_sch_array[i];
      end

// Calculate message schedule for the second (last) block
    for (i = 16; i < 64; i++)
       begin
         ROR_WT1_17            = {msg_sch_exp[i-2][16:0], msg_sch_exp[i-2][31:17]};
         ROR_WT1_19            = {msg_sch_exp[i-2][18:0], msg_sch_exp[i-2][31:19]};
         SHR_WT1_10            = {10'h000, msg_sch_exp[i-2][31:10]};
         
         ROR_WT2_7             = {msg_sch_exp[i-15][6:0], msg_sch_exp[i-15][31:7]};
         ROR_WT2_18            = {msg_sch_exp[i-15][17:0], msg_sch_exp[i-15][31:18]};
         SHR_WT2_3             = {3'b000, msg_sch_exp[i-15][31:3]};
                               
         WPT1    = msg_sch_exp[i-7]  + (ROR_WT1_17 ^ ROR_WT1_19 ^ SHR_WT1_10);
         WPT2    = msg_sch_exp[i-16] + (ROR_WT2_7  ^ ROR_WT2_18 ^ SHR_WT2_3);
      
         MSG_SCHED_LOGIC_OUT   =    WPT1 + WPT2;
         
         msg_sch_exp[i] = MSG_SCHED_LOGIC_OUT;
         end

// Copy the result to the interface array
   for (i = 0; i < 64; i++) begin
      msg_sch_array_2[i] = msg_sch_exp[i];
      end
      
end

endfunction



function automatic void hash_proc( input logic [31:0] msg_sch[0:63],
                                   inout logic [31:0] HASH [0:7]
                                    );


//----------------------------------------------------------------
// SHA-256 Constants (FIPS 180-4 sec. 4.2.2)
//----------------------------------------------------------------
logic [31:0] KVal[0:63] ='{
      32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,  // 00 : 07
      32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,  // 08 : 15
      32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc, 32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,  // 16 : 23
      32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7, 32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,  // 24 : 31
      32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13, 32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,  // 32 : 39
      32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3, 32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,  // 40 : 47
      32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5, 32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,  // 48 : 55
      32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208, 32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2}; // 56 : 63



integer j;

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

logic [31:0] K_val;
logic [31:0] T2;

logic [31:0] a_reg;
logic [31:0] b_reg;
logic [31:0] c_reg;
logic [31:0] d_reg;
logic [31:0] e_reg;
logic [31:0] f_reg;
logic [31:0] g_reg;
logic [31:0] h_reg;



    a_reg  =  HASH[0];
    b_reg  =  HASH[1];
    c_reg  =  HASH[2];
    d_reg  =  HASH[3];
    e_reg  =  HASH[4];
    f_reg  =  HASH[5];
    g_reg  =  HASH[6];
    h_reg  =  HASH[7];


    // Hash Computation
    for (j = 0; j < 64; j++) begin
    /**************************************************
       T1 part
    **************************************************/  
        K_val       =  KVal[j];
        msg_word_picked = msg_sch[j];
    
    /**************************************************
       T1 part
    **************************************************/  
        T1_ROR_E_6  = {e_reg[5:0]  ,e_reg[31:6]};   // ROR(6)
        T1_ROR_E_11 = {e_reg[10:0] ,e_reg[31:11]};  // ROR(11)
        T1_ROR_E_25 = {e_reg[24:0] ,e_reg[31:25]};  // ROR(25)

        T1_ROR      = T1_ROR_E_6 ^ T1_ROR_E_11 ^ T1_ROR_E_25;
        T1_EFG      = ((e_reg & f_reg) ^ (~e_reg & g_reg));
        T1          =  h_reg + T1_ROR + T1_EFG + msg_word_picked + K_val; // Hash process PT 1 output       

    /**************************************************
       T2 part
    **************************************************/  
        T2_ROR_A_2  = {a_reg[1:0]  ,a_reg[31:2]};
        T2_ROR_A_13 = {a_reg[12:0] ,a_reg[31:13]};
        T2_ROR_A_22 = {a_reg[21:0] ,a_reg[31:22]};

        T2_ROR      =  T2_ROR_A_2      ^  T2_ROR_A_13    ^   T2_ROR_A_22;
        T2_ABC      = ((a_reg & b_reg) ^ (a_reg & c_reg) ^ (b_reg & c_reg));
        T2          =  T2_ROR + T2_ABC;              

    /**************************************************
       Update working variables 
       Note ordered blocking assignments
    **************************************************/  
         h_reg =  g_reg;
         g_reg =  f_reg;
         f_reg =  e_reg;
         e_reg =  d_reg + T1;
         d_reg =  c_reg;
         c_reg =  b_reg;
         b_reg =  a_reg;
         a_reg =  T1 + T2;

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

endfunction



























	
function automatic void walnut_emul( input  logic [31:0] EMatrix [0:9][0:9], 
                                     input  logic [3:0]  PermArray[0:9],
									 input  logic [4:0]  sig_braid[0:5000],
									 input  integer      sig_len,
									 input  logic [31:0] T_Values[0:9],
                                     output logic [31:0] EMultiply_Result [0:9][0:9],
                                     output logic [4:0] Permutation_Result [0:9]);

integer i, j;
integer counter;
integer abs_AG;
integer sign;
integer temp;

integer  WE_FILE = $fopen("WEMULtest_results.dat", "w"); 

logic [3:0]  PermArray_Prev[0:9];

longint C1, C2, C3;


   $fwrite( WE_FILE, "INIT E-Matrix\n");		
   $fwrite( WE_FILE, "-------------\n");
   
   for (i=0; i<10; i++) begin
      for (j=0; j<10; j++) begin
         $fwrite( WE_FILE, "  %08h  ", EMatrix[i][j]);
          end
		 $fwrite( WE_FILE, "\n");
	  end
	  
   $fwrite( WE_FILE, "\n\n");
   $fwrite( WE_FILE, "----------------------------------------------------------------------------------------------------------------------\n");
   $fwrite( WE_FILE, "E-Multiply Process for %0d AG's\n",sig_len );		
   
   
   for (counter = 0; counter < sig_len; counter++)
     begin
      sign = sig_braid[counter][4]; 
      abs_AG = 32'(sig_braid[counter][3:0]);
      
	  // Save current permutation
	  for (i = 0; i < 10; i++) begin
         PermArray_Prev[i] = PermArray[i]; 
		 end
  
      if(sign == 0) begin  // Positive AG
           C1 = T_Values[(PermArray[abs_AG])];
           C2 =  32'h7FFFFFFF - C1;
           C3 = 1'h1;
           end
      else begin   // Negative AG
           C1 =  1'h1;
           C2 =  32'h7FFFFFFF - MINV(T_Values[PermArray[abs_AG+1][3:0]]);
           C3 =  32'h7FFFFFFF - C2;
           end
  
      if (abs_AG != 0) begin
         for(j=0; j<10; j++) begin
              EMatrix[j][abs_AG-1] =  (EMatrix[j][abs_AG-1] + ( 64'(EMatrix[j][abs_AG] * C1) %  32'h7fffffff))  % 32'h7fffffff;
              end
		 end

        for(j=0; j<10; j++) begin
            EMatrix[j][abs_AG + 1] = (EMatrix[j][abs_AG+1] + ( 64'(EMatrix[j][abs_AG] * C3) %   32'h7fffffff))  % 32'h7fffffff;
            end

        for(j=0; j<10; j++) begin
            EMatrix[j][abs_AG] = ((EMatrix[j][abs_AG] * C2) %  32'h7fffffff);
            end
			
			
		// Swap  
        temp                     =       PermArray[abs_AG];
        PermArray[abs_AG]        =       PermArray[abs_AG  +  1];
        PermArray[abs_AG  +  1]  =       temp;

        $fwrite( WE_FILE, "----------------------------------------------------------------------------------------------------------------------\n");
		$fwrite( WE_FILE, "E-Matrix for AG 0x%02h - ROUND %0d: \n\n", sig_braid[counter], counter+1);	

        if (sign == 0) begin
		     $fwrite( WE_FILE, "T-Value = %08h\n", C1);
		     end
        else begin			 
		     $fwrite( WE_FILE, "Inverse T-Value = %08h\n", MINV(T_Values[PermArray[abs_AG+1][3:0]]));
		     end
			 
			 
		for (i = 0; i < 10; i++) begin
		   for (j = 0; j < 10; j++) begin
		      $fwrite( WE_FILE, "  %08h  ", EMatrix[i][j]);
			  end
		      $fwrite( WE_FILE, "\n");
		    end

		$fwrite( WE_FILE, "\n\n");

        
		$fwrite( WE_FILE, "Index:    ");
        for (j=0; j<10; j++) begin
           $fwrite( WE_FILE, "  %0d  ", j);
           end

		$fwrite( WE_FILE, "\n");

		$fwrite( WE_FILE, "----------------------------------------------------------\n");
		
		$fwrite( WE_FILE, "Previous: ");		
		for (j=0; j<10; j++) begin
           $fwrite( WE_FILE, "  %0h  ", PermArray_Prev[j]);
           end

		$fwrite( WE_FILE, "\n");
		
		$fwrite( WE_FILE, "Swapped:  ");					  
		for (j=0; j<10; j++) begin
		      $fwrite( WE_FILE, "  %0h  ", PermArray[j]);
			  end

		$fwrite( WE_FILE, "\n\n");
			
		
      end
	  
// Ouput Result
for (i = 0; i < 10; i++) begin
   for (j = 0; j < 10; j++) begin
     EMultiply_Result[i][j] = EMatrix[i][j];
     end
   end

for (i = 0; i < 10; i++) begin
    Permutation_Result[i] = PermArray[i];
	end
    
$fwrite( WE_FILE, "Extracted Signature Braid:  \n");					      
for (i = 0; i < sig_len; i++) begin
    $fwrite( WE_FILE, "  0x%02h  ", sig_braid[i]);
        if ((i%20 == 0)) begin
            $fwrite( WE_FILE, "\n");
			end
end
	
	
	
	//  End
	$fclose(WE_FILE);

   
endfunction


function automatic void MatrixMultiply ( input   logic [31:0] Matrix_1 [0:9][0:9],   
                                         input   logic [31:0] Matrix_2 [0:9][0:9], 
                                         output  logic [31:0] MM_RESULT[0:9][0:9]  
							            );         

integer i, j, k;

logic [31:0] SUM;

SUM = 32'h0000_0000;

for (i = 0; i < 10; i++) begin
   for (j = 0; j < 10; j++) begin
      for (k = 0; k < 10; k++) begin
        MM_RESULT[i][j] = SUM + (Matrix_1[i][k] * Matrix_2[k][j] % 32'h7fff_ffff) % 32'h7fff_ffff;
        end
	  MM_RESULT[i][j] = SUM;
	  SUM             = 32'h0000_0000;
	  end
   end

return;
endfunction

/******************************************************************************
   E-Multiplication Round verification - Three column multiply check
   
   T-Values (10 words)         SIGNATURE[102:111] 
   Inverse T-Values (10 words) SIGNATURE[112:121] 

   Modulus = 0x7FFF_FFFF
   
   Positive AG
   -----------
   C1' = (TVAL*C2) + C1
   C2' = -1 * (TVal * C2)
   C3' = C2 + C3
   
   Negative AG
   -----------
   C1' = C1 + C2
   C2' = -1 * (INV_TVAL * C2)
   C3' = (INV_TVAL * C2) + C3
  
******************************************************************************/
function automatic int EMVerify( input  logic [31:0] EMatrix_copy [0:9][0:9],  // Previous E-Matrix
                                  input  logic [31:0] EMatrix [0:9][0:9],       // Current E-Matrix
				                  input  logic [3:0]  PermArray_copy[0:9] ,     // Previous Premutation
				                  input  logic [3:0]  PermArray[0:9],           // Current Permutation
				                  input  logic [3:0]  AG,                       // Artin Generator
								  input  logic        sign,
								  input  logic [31:0] SIGNATURE[],              // Read-only
								  //output integer      err_count,
								  integer             file_handle);             // Artin Generator

integer i;
integer err = 0;
longint x, y, z;

longint TVal;
integer perm_out;

longint Col_1[10];
longint Col_2[10];
longint Col_2_prod[10];
longint Col_3[10];

integer abs_AG = 32'(AG); //cast unpacked logic to 32 bit packed integer

/******************************************************
      Get preliminary data
*******************************************************/
//Get T-Value pointer
perm_out = (sign) ? PermArray_copy[abs_AG + 1] :  PermArray_copy[abs_AG];


// Assign T-Value, reference SIGNATURE array for T-Value / Inverse
//                     Negative             Positive
TVal = (sign) ? SIGNATURE[perm_out + 112] : SIGNATURE[perm_out + 102];


/******************************************************
     Perfom Three column E-Multiply
*******************************************************/
//Get the product of the T-Value and the column pointer
for (i = 0; i < 10; i++)
  begin
      Col_2_prod[i] = (TVal * EMatrix_copy[i][abs_AG]) % 32'h7fff_ffff;
  end

// Column 1 (AG - 1), if AG > 0
if (abs_AG > 0) begin
   for (i = 0; i < 10; i++)
     begin
	     Col_1[i] = (sign) ? (EMatrix_copy[i][abs_AG - 1] + EMatrix_copy[i][abs_AG]) % 32'h7fffffff:         //Negative      C1' = C1 + C2
		                     (Col_2_prod[i]  + EMatrix_copy[i][abs_AG - 1])  % 32'h7fffffff;                 //Positive      C1' = (TVAL * C2) + C1
		 Col_1[i] = (Col_1[i] == 32'h7fff_ffff) ? 32'h0000_0000 : Col_1[i];
	 end
end
// Column 3
for (i = 0; i < 10; i++)
   begin
	  Col_3[i] = (sign) ?  (EMatrix_copy[i][abs_AG + 1] + Col_2_prod[i])            % 32'h7fffffff:   //Negative      C3' = (INV TVAL * C2) + C3
		                   (EMatrix_copy[i][abs_AG + 1] + EMatrix_copy[i][abs_AG])  % 32'h7fffffff;   //Positive      C3' = C2 + C3
										   
      Col_3[i] = (Col_3[i] == 32'h7fff_ffff) ? 32'h0000_0000 : Col_3[i];

   end

// Column 2 - Negate product C2 and stores as C2
for (i = 0; i < 10; i++)
   begin
     Col_2[i]   =  32'h7fffffff -  Col_2_prod[i] ;
	 Col_2[i] = (Col_2[i] == 32'h7fff_ffff) ? 32'h0000_0000 : Col_2[i];

   end 
   
/******************************************************
      Compare E-Matrix results
*******************************************************/
		  
$fwrite(file_handle,"\nCHECK E-Multiply\n");	

//$fwrite(file_handle,"Artin Generator =  %0d\n",abs_AG );	

if (abs_AG >= 1) begin
    //$fwrite(file_handle,"Column %d     %d     %d      \n", abs_AG-1,    abs_AG,   abs_AG+1 );	
	for (i=0; i < 10; i++)
      begin
		if (Col_1[i] != EMatrix [i][abs_AG-1]) begin
		    $fwrite(file_handle,"Error: Row %0d, Column %0d  -  Expected: %08h  Actual: %08h  \n", i, (abs_AG - 1), Col_1[i], EMatrix[i][abs_AG-1] );
			err++;
            end
		if (Col_2[i] != EMatrix [i][abs_AG]) begin
		    $fwrite(file_handle,"Error: Row %0d, Column %0d  -  Expected: %08h  Actual: %08h  \n", i, abs_AG, Col_2[i], EMatrix[i][abs_AG] );
			err++;
            end
		if (Col_3[i] != EMatrix [i][abs_AG+1]) begin
		    $fwrite(file_handle,"Error: Row %0d, Column %0d  -  Expected: %08h  Actual: %08h   \n", i, (abs_AG + 1), Col_3[i], EMatrix[i][abs_AG+1] );
			err++;
            end
      end    
    end
else begin
	for (i=0; i < 10; i++)
      begin
		if (Col_2[i] != EMatrix [i][abs_AG]) begin
		    $fwrite(file_handle,"Error: Row %0d, Column %0d  -  Expected: %08h  Actual: %08h \n", i, abs_AG, Col_2[i], EMatrix[i][abs_AG] );
			err++;
            end
		if (Col_3[i] != EMatrix [i][abs_AG+1]) begin
		    $fwrite(file_handle,"Error: Row %0d, Column %0d  -  Expected: %08h  Actual: %08h  \n", i, (abs_AG + 1), Col_3[i], EMatrix[i][abs_AG+1] );
			err++;
            end
      end    
    end

	
//input logic [3:0]  PermArray_copy[0:9] ,     // Previous Premutation
//input logic [3:0]  PermArray[0:9],           // Current Permutation
      if  (PermArray_copy[abs_AG] != PermArray[abs_AG + 1]) begin
               $fwrite(file_handle,"Error: Permutation locations %0d and %0d not swapped \n", abs_AG, abs_AG + 1,  );
               err++;
			   end

 

								  
// Return error count update
	if (err == 0) begin
       $fwrite(file_handle,"E-Multiply Round check OK\n" );
	   end

    return err;
	
endfunction


/**********************************************************
   System time
**********************************************************/
/*
  function string get_time();
    int    file_pointer;
     
    //Stores time and date to file sys_time
    $system("date +%X--%x > sys_time");
    //Open the file sys_time with read access
    file_pointer = $fopen("sys_time","r");
    //assign the value from file to variable
    $fscanf(file_pointer,"%s",get_time);
    //close the file
    $fclose(file_pointer);
    $system("rm sys_time");
  endfunction
 */



endpackage