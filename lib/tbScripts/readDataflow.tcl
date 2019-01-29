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
#  @author  Streit Franz-Josef                                                     
#  @mail    franz-josef.streit@fau.de                                                   
#  @date    20 June 2018                                                      
#  @version 0.1                                                                  
#  @brief   tcl script to interpret the HW Data-Flow Graph (DFG) 
#                                                                                
##

# Read content of Data-Flow Graph (DFG)
set fid [open ${MODELNAME}_hw/dfg_hw.txt]
set content [read $fid]
close $fid

# Split dfg file into separate lines on newlines
# Add this variable to global namespace
set ::lines [split $content "\n"]
set write_adapter ""
set read_adapter ""
set tb_inports {}
set tb_outports {}
set inport ""
set outport ""

set line_cnt 0
set read_cnt 0
set write_cnt 0

foreach nl $lines { 
  if {[string first "extern->" $nl] != -1} {
    # extract inport name
    set tmp [regexp -all -inline {inputArg[0-9]} $nl] 
    set inport $tmp
    puts "found external input $tmp"
  } elseif {[string first "in_port_dimension=" $nl] != -1} {
    # extract inport dimension
    set tmp [regexp -all -inline {\[(?:[^\\"]|\\.)*\]} $nl] 
    regsub -all {\[|\]|\{|\}} $tmp "" tmp
    lappend inport $tmp
    puts "found in_frame_dimension with value $tmp"
    # delete line from list
    set lines [lreplace $lines $line_cnt $line_cnt]
    incr line_cnt -1
  } elseif {[string first "in_port_byte_size=" $nl] != -1} {
    # extract inport byte size dimension
    set tmp [regexp -all -inline {\[(?:[^\\"]|\\.)*\]} $nl] 
    regsub -all {\[|\]|\{|\}} $tmp "" tmp
    lappend inport $tmp
    lappend tb_inports $inport
    puts "found in_frame_byte_size with value $tmp"
    # delete line from list
    set lines [lreplace $lines $line_cnt $line_cnt]
    incr line_cnt -1
  } elseif {[string first "->extern" $nl] != -1} {
    # extract outport name
    set tmp [regexp -all -inline {outputArg[0-9]} $nl] 
    set outport $tmp
    puts "found external output $tmp"
  } elseif {[string first "out_port_dimension=" $nl] != -1} {
    # extract outport dimension
    set tmp [regexp -all -inline {\[(?:[^\\"]|\\.)*\]} $nl]
    regsub -all {\[|\]|\{|\}} $tmp "" tmp
    lappend outport $tmp
    puts "found out_frame_dimension with value $tmp"
    # delete line from list
    set lines [lreplace $lines $line_cnt $line_cnt]
    incr line_cnt -1
  } elseif {[string first "out_port_byte_size=" $nl] != -1} {
    # extract outport byte size dimension
    set tmp [regexp -all -inline {\[(?:[^\\"]|\\.)*\]} $nl]
    regsub -all {\[|\]|\{|\}} $tmp "" tmp
    lappend outport $tmp
    lappend tb_outports $outport
    puts "found out_frame_byte_size with value $tmp"
    # delete line from list
    set lines [lreplace $lines $line_cnt $line_cnt]
    incr line_cnt -1
  } elseif {[string first "write_adapt" $nl] != -1} {
    # set HW/SW Co-Design
    set hwswdesign "true"
    lappend write_adapter "write_adapt_id_$write_cnt"
    incr write_cnt 
    puts "found write_adapter set id to $write_cnt"
    # delete line from list
    set lines [lreplace $lines $line_cnt $line_cnt]
    incr line_cnt -1
  } elseif {[string first "read_adapt" $nl] != -1} {
    # set HW/SW Co-Design
    set hwswdesign "true"
    lappend read_adapter "read_adapt_id_$read_cnt"
    incr read_cnt 
    puts "found read_adapter set id to $read_cnt"
    # delete line from list
    set lines [lreplace $lines $line_cnt $line_cnt]
    incr line_cnt -1
  }
  incr line_cnt
}

# Debug code
#set tb_inports {{inpurtArg1 1}}
#puts "nr of inports [llength $tb_inports]"
#puts "name of inport [lindex $tb_inports {0 0}]"
#puts "size of inport [lindex $tb_inports {0 1}]"
#puts "byte size of inport [lindex $tb_inports {0 2}]"
#puts "name of inport [lindex $tb_inports {1 0}]"
#puts "size of inport [lindex $tb_inports {1 1}]"
#puts "byte size of inport [lindex $tb_inports {1 2}]"
#puts "nr of outports [llength $tb_outports]"
#puts "name of outport [lindex $tb_outports {0 0}]"
#puts "size of outport [lindex $tb_outports {0 1}]"
#puts "byte size of outport [lindex $tb_outports {0 2}]"
