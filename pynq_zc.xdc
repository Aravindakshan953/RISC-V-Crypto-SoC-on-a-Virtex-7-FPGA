set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports { CLK125MHZ }]

# Buttons
set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports { BTN[0] }]
set_property -dict { PACKAGE_PIN D20 IOSTANDARD LVCMOS33 } [get_ports { BTN[1] }]
set_property -dict { PACKAGE_PIN L20 IOSTANDARD LVCMOS33 } [get_ports { BTN[2] }]
set_property -dict { PACKAGE_PIN L19 IOSTANDARD LVCMOS33 } [get_ports { BTN[3] }]

# Switches
set_property -dict { PACKAGE_PIN M20 IOSTANDARD LVCMOS33 } [get_ports { SW[0] }]
set_property -dict { PACKAGE_PIN M19 IOSTANDARD LVCMOS33 } [get_ports { SW[1] }]

# LEDs
set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports { LED[0] }]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { LED[1] }]
set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports { LED[2] }]
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { LED[3] }]

# JB Header Pins
set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS33 } [get_ports { JB[0] }]
set_property -dict { PACKAGE_PIN Y14 IOSTANDARD LVCMOS33 } [get_ports { JB[1] }]
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { JB[2] }]
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { JB[3] }]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports { JB[4] }]
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } [get_ports { JB[5] }]
set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports { JB[6] }]
set_property -dict { PACKAGE_PIN W13 IOSTANDARD LVCMOS33 } [get_ports { JB[7] }]

#======================================================================
# 2. I/O ELECTRICAL PROPERTIES
#======================================================================
# LEDs: Low drive + slow slew for reduced dynamic power
set_property DRIVE 4 [get_ports {LED[*]}]
set_property SLEW SLOW [get_ports {LED[*]}]

# JB Header: Low drive + slow slew (optimized for signal integrity/power balance)
set_property DRIVE 4 [get_ports {JB[*]}]
set_property SLEW SLOW [get_ports {JB[*]}]

#======================================================================
# 3. TIMING CONSTRAINTS
#======================================================================
# Primary Clock Definition
# 125MHz clock (8ns period) from CLK125MHZ input
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} [get_ports CLK125MHZ]
set_input_jitter [get_clocks sys_clk_pin] 0.010

# Clock Uncertainty for setup timing
set_clock_uncertainty -setup 0.200 [get_clocks sys_clk_pin]

#======================================================================
# 4. TIMING EXCEPTIONS
#====================================================================#
# Asynchronous inputs (buttons/switches) - synchronized in RTL
set_false_path -from [get_ports {{BTN[*]} {SW[*]}}]

# Observation-only outputs (LEDs/JB) - no timing requirements
set_false_path -to [get_ports {{LED[*]} {JB[*]}}]

#======================================================================
# 5. SYNCHRONIZER OPTIMIZATION
#======================================================================
# Async register properties for synchronizer flip-flops (metastability protection)
set_property ASYNC_REG true [get_cells -quiet {{btn0_sync_reg[*]} {btn1_sync_reg[*]} {sw0_sync_reg[*]} {sw1_sync_reg[*]}}]

#======================================================================
# 6. POWER AND OPERATING CONDITIONS
#======================================================================
# Process, temperature, and power budget settings
set_operating_conditions -process typical
set_operating_conditions -design_power_budget 5.0
set_operating_conditions -junction_temp 50.0
set_operating_conditions -ambient_temp 25.0
set_operating_conditions -airflow 0 -heatsink none

#======================================================================
# 7. SWITCHING ACTIVITY FOR POWER ANALYSIS
#======================================================================
# Button/switch inputs: human interface activity
set_switching_activity -toggle_rate 0.500 -static_probability 0.500 [get_ports {{BTN[*]} {SW[*]}}]

# LED outputs: observation indicators
set_switching_activity -toggle_rate 1.000 -static_probability 0.500 [get_ports {LED[*]}]

# JB Header: higher activity for potential communication interfaces
set_switching_activity -toggle_rate 10.000 -static_probability 0.500 [get_ports {JB[*]}]

# Default switching activity for unspecified nets
set_switching_activity -default_toggle_rate 12.5 -default_static_probability 0.5
set_switching_activity -deassert_resets

#======================================================================
# 8. OUTPUT LOADING
#======================================================================
# Conservative output loading for signal integrity
set_load 5.000 [all_outputs]
set_property LOAD 5 [get_ports {JB[0]}]
set_property LOAD 5 [get_ports {JB[1]}]
set_property LOAD 5 [get_ports {JB[2]}]
set_property LOAD 5 [get_ports {JB[3]}]
set_property LOAD 5 [get_ports {JB[4]}]
set_property LOAD 5 [get_ports {JB[5]}]
set_property LOAD 5 [get_ports {JB[6]}]
set_property LOAD 5 [get_ports {JB[7]}]
set_property LOAD 5 [get_ports {LED[0]}]
set_property LOAD 5 [get_ports {LED[1]}]
set_property LOAD 5 [get_ports {LED[2]}]
set_property LOAD 5 [get_ports {LED[3]}]

#======================================================================
# 9. BITSTREAM OPTIONS
#======================================================================
# Enable bitstream compression to reduce configuration time and storage
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

#======================================================================
# 10. TIMING VALIDATION
#======================================================================
# Perform timing checks and report exceptions
check_timing -verbose
report_exceptions
