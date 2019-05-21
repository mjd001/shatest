set_global_assignment -entity "MULT_ADD1" -library "lib_MULT_ADD1" -name IP_TOOL_NAME "altera_mult_add"
set_global_assignment -entity "MULT_ADD1" -library "lib_MULT_ADD1" -name IP_TOOL_VERSION "16.1"
set_global_assignment -entity "MULT_ADD1" -library "lib_MULT_ADD1" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_MULT_ADD1" -name SPD_FILE [file join $::quartus(sip_path) "MULT_ADD1.spd"]

set_global_assignment -library "lib_MULT_ADD1" -name MISC_FILE [file join $::quartus(sip_path) "MULT_ADD1_sim/MULT_ADD1.v"]
