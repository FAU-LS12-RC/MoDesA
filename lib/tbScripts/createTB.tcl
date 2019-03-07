##
# -------------------------------------------------------------------------  
#   Copyright (c) 2017 Hardware-Software-Co-Design, Friedrich-
#   Alexander-Universitaet Erlangen-Nuernberg (FAU), Germany.
#   All rights reserved.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
# ------------------------------------------------------------------------- 
#                                                                                
#  @author  Benjamin Hackenberg Streit Franz-Josef 
#  @mail    franz-josef.streit@fau.de                                                   
#  @date    20 June 2018                                                      
#  @version 0.1                                                                  
#  @brief   tcl script to automate rtl testbench generation 
#                                                                                
##

#initialize all parameters with empty strings 
set stimuli_in      ""
set stimuli_out     ""
set cnt_in          ""                 
set cnt_out         ""                
set input1          ""                 
set input2          ""                 
set input3          ""                 
set output1         ""                
set output2         ""                
set output3         ""                
set PERIOD          ""            
set frame_sizes_in  ""       
set frame_sizes_out ""     
set var_data_read   ""        
set file_in         ""              
set read1           ""                
set read2           ""                
set check_idle      ""           
set file_out        ""             
set write1          ""               
set write2          ""               
set write3          ""               
set var_data_write  "" 

#load template file for TB
set template_path "../lib/tbScripts/testbench.vhd.in"
set template_file [open $template_path r]

#load file
set tb_path "$proj_dir/$PROJNAME.sim/test_design_1.vhd"
set tb_file [open $tb_path w]

set num_inports [llength $tb_inports]
set num_outports [llength $tb_outports]

   # get real interface names from block design
set in_ports [lsort -dictionary [get_bd_intf_ports -filter {NAME =~ "*inputArg*"}]]
set out_ports [lsort -dictionary [get_bd_intf_ports -filter {NAME =~ "*outputArg*"}]]

set counter_init_in 0
set counter_init_out 0

# to remember
# tb_inports 0 = name
# tb_inports 1 = frame_size
# tb_inports 2 = port_size in byte


#set frame sizes for multiple in and out ports
for {set i 0} {$i < $num_inports} {incr i} {
    #set input path for stimuli files
    append stimuli_in "FILE_IN${i}: string := \"$BUILDDIR/stimuli/input$i/0.hex\";\n"
    # set real interface names from block design
    lset tb_inports ${i} 0 [string trimleft [lindex $in_ports ${i}] "/"]
    lset tb_inports ${i} 2 [get_property CONFIG.TDATA_NUM_BYTES [get_bd_intf_pins [lindex $tb_inports ${i} 0]]]
    # set init values depending on byte size e.g. 0x0000 for 2 bytes
    set tmp "00"
    for {set j 1} {$j < [lindex $tb_inports $i 2]} {incr j} {
      set tmp "00$tmp"
    }
    lappend signal_in_init $tmp
    set tmp "00"

    set frame_sizes_in_text "constant FRAME_SIZE_IN${i} : integer := [lindex $tb_inports $i 1];\n"
    append frame_sizes_in $frame_sizes_in_text
    set cnt_in_text "signal cnt_in${i} : integer range 0 to FRAME_SIZE_IN${i} := 0;\n"
    append cnt_in $cnt_in_text
    set input1_text "[lindex $tb_inports $i 0]_tdata : in STD_LOGIC_VECTOR ([expr 8 * [lindex $tb_inports $i 2] - 1] downto 0);\n[lindex $tb_inports $i 0]_tready : out STD_LOGIC;\n[lindex $tb_inports $i 0]_tvalid : in STD_LOGIC;\n"
    append input1 $input1_text
    set input2_text "signal [lindex $tb_inports $i 0]_tdata : STD_LOGIC_VECTOR ([expr 8 * [lindex $tb_inports $i 2] - 1] downto 0) := x\"[lindex $signal_in_init $counter_init_in]\";\nsignal [lindex $tb_inports $i 0]_tready : STD_LOGIC;\nsignal [lindex $tb_inports $i 0]_tvalid : STD_LOGIC := '0';\n"
    append input2 $input2_text
    incr counter_init_in
    set input3_text "[lindex $tb_inports $i 0]_tdata => [lindex $tb_inports $i 0]_tdata,\n\t\t[lindex $tb_inports $i 0]_tready => [lindex $tb_inports $i 0]_tready,\n\t\t[lindex $tb_inports $i 0]_tvalid => [lindex $tb_inports $i 0]_tvalid,\n"
    append input3 $input3_text
    set var_data_read_text "variable data_read${i} : std_logic_vector([expr 8 * [lindex $tb_inports $i 2] - 1] downto 0);\n"
    append var_data_read $var_data_read_text
    #compose strings to write data in process to all input ports
    set file_in_text "file file_in${i} : text is in FILE_IN${i};\n"
    append file_in $file_in_text
    set read1_text "[lindex $tb_inports $i 0]_tvalid <= '0';\n\t\t[lindex $tb_inports $i 0]_tdata <= x\"[lindex $signal_in_init $i]\";\n\t\tcnt_in${i} <= 0;"
    append read1 $read1_text
    #@read2@
    set read2_text "if([lindex $tb_inports $i 0]_tready = '1') then\n\t\t\tif(not endfile(file_in${i})) then\n\t\t\t\treadline(file_in${i}, line_num);\n\t\t\t\thread(line_num, data_read${i});\n\t\t\t\t[lindex $tb_inports $i 0]_tdata <= data_read${i};\n\t\t\t\t[lindex $tb_inports $i 0]_tvalid <= '1'; \n\t\t\t\tcnt_in${i} <= cnt_in${i}+1;\n\t\t\telse\n\t\t\t\t[lindex $tb_inports $i 0]_tdata <= x\"[lindex $signal_in_init $i]\";\n\t\t\t\t[lindex $tb_inports $i 0]_tvalid <= '0';\n\t\t\tend if;\n\t\tend if;"
    append read2 $read2_text
    set check_idle_text "\tif (cnt_in${i} = FRAME_SIZE_IN${i}) then\n\t\t\tstateSTIMULI <= IDLE;\n\t\tend if;"
    append check_idle $check_idle_text
}

for {set i 0} {$i < $num_outports} {incr i} {
    # create directories for output files per outport
    file mkdir "$BUILDDIR/stimuli/output$i"
    append stimuli_out "FILE_OUT${i}: string := \"$BUILDDIR/stimuli/output$i/0.hex\";\n"
    # set real interface names from block design
    lset tb_outports ${i} 0 [string trimleft [lindex $out_ports ${i}] "/"]
    lset tb_outports ${i} 2 [get_property CONFIG.TDATA_NUM_BYTES [get_bd_intf_pins [lindex $tb_outports ${i} 0]]]
    # set init values depending on byte size e.g. 0x0000 for 2 bytes
    set tmp "00"
    for {set j 1} {$j < [lindex $tb_outports $i 2]} {incr j} {
      set tmp "00$tmp"
    }
    lappend signal_out_init $tmp
    set tmp "00"

    set frame_sizes_out_text "constant FRAME_SIZE_OUT${i} : integer := [lindex $tb_outports $i 1];\n"
    append frame_sizes_out $frame_sizes_out_text
    set cnt_out_text "signal cnt_out${i} : integer range 0 to FRAME_SIZE_OUT${i} := 0;\n"
    append cnt_out $cnt_out_text
    set output1_text "[lindex $tb_outports $i 0]_tdata : out STD_LOGIC_VECTOR ([expr 8 * [lindex $tb_outports $i 2] - 1] downto 0);\n[lindex $tb_outports $i 0]_tready : in STD_LOGIC;\n[lindex $tb_outports $i 0]_tvalid : out STD_LOGIC;\n"
    append output1 $output1_text
    set output2_text "signal [lindex $tb_outports $i 0]_tdata : STD_LOGIC_VECTOR ([expr 8 * [lindex $tb_outports $i 2] - 1] downto 0) := x\"[lindex $signal_out_init $counter_init_out]\";\nsignal [lindex $tb_outports $i 0]_tready : STD_LOGIC;\nsignal [lindex $tb_outports $i 0]_tvalid : STD_LOGIC := '0';\n"
    append output2 $output2_text
    incr counter_init_out
    set output3_text "[lindex $tb_outports $i 0]_tdata => [lindex $tb_outports $i 0]_tdata,\n\t\t[lindex $tb_outports $i 0]_tready => [lindex $tb_outports $i 0]_tready,\n\t\t[lindex $tb_outports $i 0]_tvalid => [lindex $tb_outports $i 0]_tvalid,\n"
    append output3 $output3_text
    #compose strings to write data in process to all input ports
    set file_out_text "file file_out${i} : text is out FILE_OUT${i};"
    append file_out $file_out_text
    set write1_text "\t[lindex $tb_outports $i 0]_tready <= '0';"
    append write1 $write1_text
    set write2_text "\t[lindex $tb_outports $i 0]_tready <= '1';"
    append write2 $write2_text
    set write3_text "\tif ([lindex $tb_outports $i 0]_tvalid = '1') then\n\t\t\tcnt_out${i} <= cnt_out${i}+1;\n\t\t\thwrite(line_num, [lindex $tb_outports $i 0]_tdata, left, [lindex $tb_outports $i 0]_tdata'length);\n\t\t\twriteline(file_out${i}, line_num);\n\t\tif (cnt_out${i} = (FRAME_SIZE_OUT${i}+1)) then\n\t\t\tcnt_out${i} <= 1;\n\t\tend if;\n\tend if;\n"
    append write3 $write3_text
    set var_data_write_text "variable data_write${i} : std_logic_vector([expr 8 * [lindex $tb_outports $i 2] - 1] downto 0);\n"
    append var_data_write $var_data_write_text
}

set counter_init_in 0
set counter_init_out 0

gets $template_file line
	while {![eof $template_file]} {	

		#output
		regsub -all {@in_files@} $line $stimuli_in line
		regsub -all {@out_files@} $line $stimuli_out line
		
		regsub -all {@cnt_in@} $line $cnt_in line
		regsub -all {@cnt_out@} $line $cnt_out line
		regsub -all {@input1@} $line $input1 line
		regsub -all {@input2@} $line $input2 line
		regsub -all {@input3@} $line $input3 line
		regsub -all {@output1@} $line $output1 line
		regsub -all {@output2@} $line $output2 line
		regsub -all {@output3@} $line $output3 line		

		regsub -all {@clock_periode@} $line $PERIOD line
		regsub -all {@frame_sizes_in@} $line $frame_sizes_in line
		regsub -all {@frame_sizes_out@} $line $frame_sizes_out line
		regsub -all {@var_data_read@} $line $var_data_read line
		regsub -all {@file_in@} $line $file_in line


		regsub -all {@read1@} $line $read1 line
		regsub -all {@read2@} $line $read2 line
		regsub -all {@check_idle@} $line $check_idle line

		regsub -all {@file_out@} $line $file_out line
		regsub -all {@write1@} $line $write1 line
		regsub -all {@write2@} $line $write2 line
		regsub -all {@write3@} $line $write3 line
		regsub -all {@var_data_write@} $line $var_data_write line

		puts $tb_file $line
		gets $template_file line			
}

close $tb_file
close $template_file
