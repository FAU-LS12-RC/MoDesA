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
#  @brief   cmake module to create Block Design 
#                                                                                
##

#INCLUDE(CMakeParseArguments)
#INCLUDE(ExternalProject)

FOREACH(dir IN LISTS CMAKE_MODULE_PATH)
  IF(IS_DIRECTORY ${dir}/../lib/projectScripts)
    SET(projectScripts_DIR ${dir}/../lib/projectScripts)
  ENDIF()
ENDFOREACH()
IF(NOT DEFINED projectScripts_DIR)
  MESSAGE(FATAL_ERROR "Can't find ipbScripts directory")
ENDIF()

FUNCTION(createBlockdesign modelName ipRepo)
  SET(modelName ${modelName})
  SET(ipRepo ${ipRepo})
  SET(build_dir "${PROJECT_BINARY_DIR}")

  CONFIGURE_FILE(${projectScripts_DIR}/Vivado.tcl.in ${PROJECT_BINARY_DIR}/Vivado_${modelName}.tcl @ONLY)

  ADD_CUSTOM_TARGET(Vivado_${modelName}  
    #DEPENDS ${PROJECT_BINARY_DIR}/${ipRepo}
    )
  ADD_CUSTOM_COMMAND(TARGET Vivado_${modelName} POST_BUILD
    COMMAND vivado -source Vivado_${modelName}.tcl &
    COMMENT "Create project Vivado_${modelName}"
    )
ENDFUNCTION()
