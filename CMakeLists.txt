#################################################################################
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
#  @brief   MoDesA config  
#                                                                                
#                                                                                
#  usage: create a build folder and run CMAKE in this folder with the command: 
#         cmake ..
################################################################################# 

cmake_minimum_required (VERSION 2.6)
project (MoDesA)

# set module path to custom cmake modules                                        
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/modules")

# topmodule is allways required
include(topmodule)

# some general settings
set(CMAKE_C_COMPILER gcc)                                     
set(CMAKE_CXX_COMPILER g++)  

#############################
# MoDesA specific settings
#############################

# set matlab on for matlab code generation 
set(matlab "on")                                                                               
#set synthesis on for synthesis
set(synthesis "on")

#
# declare name and path within of Simulink model
# model need to be in models folder
#

#set(model_name "test_model_hw_only")
#set(model_name "test_model_hw_sw")
set(model_name "test_model_hw_sw_hw_sw")
#set(model_name "test_model_sw_hw")
#set(model_name "test_model_sw_only")

set(model_path "test_model")


# default option to profile sw execution of the model
set(profiling "off")
# default device = ZedBoard
set(device "xc7z020clg484-1")
# default clk = 10 ns = 100MHz
set(clk "10")
# set accurate for synthesis evaluation with Vivado
# default fast just VivadoHLS synthesis
set(syn_opt "fast")

# here we call the topmodule with all the parameters
topmodule(${synthesis} ${matlab} ${profiling} ${model_name} ${model_path} ${device} ${clk} ${syn_opt})
