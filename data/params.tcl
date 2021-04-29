set ::env(CLOCK_PERIOD) "10"
set ::env(CLOCK_PORT) "i_clk"
set ::env(DESIGN_IS_CORE) 0

set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 300 300"

#set ::env(PL_TARGET_DENSITY) 0.1
#set ::env(FP_CORE_UTIL) 1
#set ::env(GLB_RT_MAXLAYER) 5
#set ::env(FP_PDN_CORE_RING) 1
#set ::env(VDD_NETS) [list {vccd} {vdda}]
#set ::env(GND_NETS) [list {vssd} {vssa}]
#set ::env(SYNTH_USE_PG_PINS_DEFINES) "USE_POWER_PINS"
#set ::env(MAGIC_WRITE_FULL_LEF) 1
