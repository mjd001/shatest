//======================================================================
//
// sha256_k_constants.v
//======================================================================

module sha256_k_constants(
                          input wire  [5 : 0] addr,
                          output wire [31 : 0] K
                         );

  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0] tmp_K;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign K = tmp_K;


  //----------------------------------------------------------------
  // addr_mux
  //----------------------------------------------------------------
  always @*
    begin : addr_mux
      case(addr)
        6'h00: tmp_K <= 32'h428a2f98;
        6'h01: tmp_K <= 32'h71374491;
        6'h02: tmp_K <= 32'hb5c0fbcf;
        6'h03: tmp_K <= 32'he9b5dba5;
        6'h04: tmp_K <= 32'h3956c25b;
        6'h05: tmp_K <= 32'h59f111f1;
        6'h06: tmp_K <= 32'h923f82a4;
        6'h07: tmp_K <= 32'hab1c5ed5;
        6'h08: tmp_K <= 32'hd807aa98;
        6'h09: tmp_K <= 32'h12835b01;
        6'h0A: tmp_K <= 32'h243185be;
        6'h0B: tmp_K <= 32'h550c7dc3;
        6'h0C: tmp_K <= 32'h72be5d74;
        6'h0D: tmp_K <= 32'h80deb1fe;
        6'h0E: tmp_K <= 32'h9bdc06a7;
        6'h0F: tmp_K <= 32'hc19bf174;
        6'h10: tmp_K <= 32'he49b69c1;
        6'h11: tmp_K <= 32'hefbe4786;
        6'h12: tmp_K <= 32'h0fc19dc6;
        6'h13: tmp_K <= 32'h240ca1cc;
        6'h14: tmp_K <= 32'h2de92c6f;
        6'h15: tmp_K <= 32'h4a7484aa;
        6'h16: tmp_K <= 32'h5cb0a9dc;
        6'h17: tmp_K <= 32'h76f988da;
        6'h18: tmp_K <= 32'h983e5152;
        6'h19: tmp_K <= 32'ha831c66d;
        6'h1A: tmp_K <= 32'hb00327c8;
        6'h1B: tmp_K <= 32'hbf597fc7;
        6'h1C: tmp_K <= 32'hc6e00bf3;
        6'h1D: tmp_K <= 32'hd5a79147;
        6'h1E: tmp_K <= 32'h06ca6351;
        6'h1F: tmp_K <= 32'h14292967;
        6'h20: tmp_K <= 32'h27b70a85;
        6'h21: tmp_K <= 32'h2e1b2138;
        6'h22: tmp_K <= 32'h4d2c6dfc;
        6'h23: tmp_K <= 32'h53380d13;
        6'h24: tmp_K <= 32'h650a7354;
        6'h25: tmp_K <= 32'h766a0abb;
        6'h26: tmp_K <= 32'h81c2c92e;
        6'h27: tmp_K <= 32'h92722c85;
        6'h28: tmp_K <= 32'ha2bfe8a1;
        6'h29: tmp_K <= 32'ha81a664b;
        6'h2A: tmp_K <= 32'hc24b8b70;
        6'h2B: tmp_K <= 32'hc76c51a3;
        6'h2C: tmp_K <= 32'hd192e819;
        6'h2D: tmp_K <= 32'hd6990624;
        6'h2E: tmp_K <= 32'hf40e3585;
        6'h2F: tmp_K <= 32'h106aa070;
        6'h30: tmp_K <= 32'h19a4c116;
        6'h31: tmp_K <= 32'h1e376c08;
        6'h32: tmp_K <= 32'h2748774c;
        6'h33: tmp_K <= 32'h34b0bcb5;
        6'h34: tmp_K <= 32'h391c0cb3;
        6'h35: tmp_K <= 32'h4ed8aa4a;
        6'h36: tmp_K <= 32'h5b9cca4f;
        6'h37: tmp_K <= 32'h682e6ff3;
        6'h38: tmp_K <= 32'h748f82ee;
        6'h39: tmp_K <= 32'h78a5636f;
        6'h3A: tmp_K <= 32'h84c87814;
        6'h3B: tmp_K <= 32'h8cc70208;
        6'h3C: tmp_K <= 32'h90befffa;
        6'h3D: tmp_K <= 32'ha4506ceb;
        6'h3E: tmp_K <= 32'hbef9a3f7;
        6'h3F: tmp_K <= 32'hc67178f2;
		  default: tmp_K <= 32'h00000000;
      endcase // case (addr)
    end // block: addr_mux
endmodule // sha256_k_constants

//======================================================================
// sha256_k_constants.v
//======================================================================
