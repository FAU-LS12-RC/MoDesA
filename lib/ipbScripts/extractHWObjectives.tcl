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
#  @date    21 Jan 2019                                                      
#  @version 0.1                                                                  
#  @brief   tcl script to write HW objectives into hw_objectives.tcl file 
#                                                                                
##

# get folder from ip repository
set subdirs [glob -directory $VIVADOHLSIPPATHS -type d *]

# create a html table with hw objectives if we have at least one IPB
if {[string length $subdirs] != 0} {
# create file for hw objectives in terms of latency and resources
set wfp [open "${BUILDDIR}/hw_objectives.html" w]

# write table header
puts $wfp "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
puts $wfp "<h3>MoDesA HLS HW Profiling Report for ${MODELNAME} </h3>"
puts $wfp "<img src=\"${BUILDDIR}/model.jpg\" alt=\"Simulink Model ${MODELNAME} \">"
puts $wfp "<br>"
puts $wfp "<Fig. 1 Simulink Model ${MODELNAME} for actor profiling"
puts $wfp "<br>"
puts $wfp "<br>"
puts $wfp "<br>"
puts $wfp "<table>"
puts $wfp "<tr>"
puts $wfp "<td bgcolor=\"#444444\"><font color=\"#FFFFFF\"><b>Target Clock Period:</b></font></td>"
puts $wfp "<td><b>${PERIOD} ns</b></td>"
puts $wfp "</tr>"
puts $wfp "</table>"
puts $wfp "<br>"
puts $wfp "<table>"
puts $wfp "<tr>"
puts $wfp "<td bgcolor=\"#444444\"><font color=\"#FFFFFF\"><b>${MODELNAME} IPBs</b></font></td>"
puts $wfp "<td><b>best-case (clk)</b></td>"
puts $wfp "<td><b>worst-case (clk)</b></td>"
puts $wfp "<td><b>average-case (clk)</b></td>"
puts $wfp "<td><b>LUT</b></td>"
puts $wfp "<td><b>FF</b></td>"
puts $wfp "<td><b>BRAM</b></td>"
puts $wfp "<td><b>DSP</b></td>"
puts $wfp "</tr>"


foreach dir $subdirs {
  set file [glob -directory $dir -type f *{auxiliary.xml}*]
  puts "found IPB auxiliary file $file"
  # Read the auxiliary file
  set fid [open $file]
  set filecontent [read $fid]
  close $fid
  set filelines [split $filecontent "\n"]

  foreach newl $filelines {
    if {[string first "<xd:acceleratorMap" $newl] != -1} {
      regexp -all {functionName="(.*?)"} $newl -> blk_name 
      puts $wfp "<tr>"
      puts $wfp "<td><b>${blk_name}</b></td>"
    } elseif {[string first "<xd:latencyEstimates" $newl] != -1} {
      regexp -all {best-case="(.*?)"} $newl -> bestcase 
      regexp -all {worst-case="(.*?)"} $newl -> worstcase 
      regexp -all {average-case="(.*?)"} $newl -> averagecase 
      puts $wfp "<td>${bestcase}</td>"
      puts $wfp "<td>${worstcase}</td>"
      puts $wfp "<td>${averagecase}</td>"
    } elseif {[string first "<xd:resourceEstimates" $newl] != -1} {
      regexp -all {LUT="(.*?)"} $newl -> lut
      regexp -all {FF="(.*?)"} $newl -> ff
      regexp -all {BRAM="(.*?)"} $newl -> bram
      regexp -all {DSP="(.*?)"} $newl -> dsp 
      puts $wfp "<td>${lut}</td>"
      puts $wfp "<td>${ff}</td>"
      puts $wfp "<td>${bram}</td>"
      puts $wfp "<td>${dsp}</td>"
      puts $wfp "</tr>"
    }
  }
}  

puts $wfp "</table>"
# close hw_objectives file
close $wfp
}
