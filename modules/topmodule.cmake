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
#  @date    09 November 2017                                                      
#  @version 0.1                                                                  
#  @brief   cmake topmodule for running MoDesA
#                                                                                
##

function(topmodule synthesis matlab profiling model_name model_path device clk syn_opt)

  # some general settings
  set(CMAKE_C_COMPILER gcc)                                     
  set(CMAKE_CXX_COMPILER g++)  

  message(STATUS "Host platform is: " ${CMAKE_SYSTEM}) 
  message(STATUS "Synthesis is: " ${synthesis})              
  message(STATUS "Matlab code generation is: " ${matlab})           

  include(createHardwareIPB)   
  include(createChipsIPB)   
  include(createBlockdesign)
  include(copyGenFiles)

  # set testbench, ON for C Simulation currently not supported
  set(testbench "off")
  # declare path to ip_repo
  set(ip_repo "${CMAKE_BINARY_DIR}/ip_repo")

  if(matlab)
    if(UNIX)
      execute_process(COMMAND matlab -nodesktop -nojvm -nosplash -logfile matlab_codegen.log -r "cd('../matlab/'),try, modesa_codegen('${model_name}','${model_path}','${profiling}'); catch e, warning('MATLAB %s', e.message), quit, end, quit") 
    endif(UNIX)
    if(WIN32)
      execute_process(COMMAND matlab -nodesktop -nojvm -nosplash -logfile matlab_codegen.log -r "cd('..\matlab\'),try, modesa_codegen('${model_name}','${model_path}','${profiling}'); catch e, warning('MATLAB %s', e.message), quit, end, quit") 
    endif(WIN32)
    # copy generated matlab files
    copyGenFiles(ipb_folders chip_folders ${model_name})
  endif()

  if(synthesis)
    message(STATUS "XILINX_VIVADO: $ENV{XILINX_VIVADO}")
    message(STATUS "XILINX_VIVADO_HLS: $ENV{XILINX_VIVADO_HLS}")
    message(STATUS "start defining IP-CORES from model ${model_name}")
    
    foreach(ipb_folder ${ipb_folders})
      message(STATUS "Configure Hardware IPB-${ipb_folder} with Vivado HLS")
      file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/templates/dummy.cpp" DESTINATION "${CMAKE_BINARY_DIR}/${model_name}_hw/${ipb_folder}")
      # call createHardwareIPB module with parameters   
      createHardwareIPB(${model_name} ${ipb_folder} ${ip_repo})    
    endforeach()

    foreach(chip_folder ${chip_folders})
      message(STATUS "Configure Processor ${chip_folder} with Chips")
      # call createChipsIPB module with parameters   
      createChipsIPB(${model_name} ${chip_folder} ${ip_repo})    
    endforeach()

    message(STATUS "Makefile successfully generated")

    # generate block design only if we previously tagged blocks as hw 
    if(EXISTS "${CMAKE_BINARY_DIR}/${model_name}_hw" OR "${CMAKE_BINARY_DIR}/${model_name}_chip")
      createBlockdesign(${model_name} ${ip_repo})
      message(STATUS "run make all to generate all IP-Blocks")
      message(STATUS "then run make Vivado_${model_name} to create Vivado project")
    endif()
  endif()  
endfunction()
