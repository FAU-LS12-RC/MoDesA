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
#  @brief   tcl script to adapt the testbench interfaces according to the Vivado 
#           version
#                                                                                
##


set intf_ports [get_bd_intf_ports]

set version_vivado 2018
set version_tb 2017
set testbench ""

#load testbench file for reading
set tb_path "$proj_dir/$PROJNAME.sim/test_design_1.vhd"
set tb_file [open $tb_path r]
set testbench [read $tb_file]
close $tb_file

#check version of vivado
if {[string match "*inputArg*_0*" $intf_ports] || [string match "*outputArg*_0*" $intf_ports]} {	
	set version_vivado 2018
} else {
	set version_vivado 2017
}

#check version of testbench file
if {[string match "*inputArg*_0*" $testbench] || [string match "*outputArg*_0*" $testbench]} {	
	set version_tb 2018
} else {
	set version_tb 2017
}

puts $version_tb
puts $version_vivado
#change testbench file if versions are different
if {$version_vivado == 2018} {	
	if {$version_tb == 2017} {	
		for {set i 1} {$i < [expr [llength $intf_ports] + 1]} {incr i} {
			set inputarg "inputArg${i}_0"
			set outputarg "outputArg${i}_0"
			regsub -all "inputArg${i}" $testbench $inputarg testbench
			regsub -all "outputArg${i}" $testbench  $outputarg testbench
		}
	}
}
if {$version_vivado == 2017} {	
	if {$version_tb == 2018} {	
		for {set i 1} {$i < [expr [llength $intf_ports] + 1]} {incr i} {
			regsub -all "inputArg${i}_0" $testbench "inputArg${i}" testbench
			regsub -all "outputArg${i}_0" $testbench "outputArg${i}"  testbench
		}
	}
} 

#load testbench file for writing
set tb_path "$proj_dir/$PROJNAME.sim/test_design_1.vhd"
set tb_file [open $tb_path w]
puts $tb_file $testbench
close $tb_file
