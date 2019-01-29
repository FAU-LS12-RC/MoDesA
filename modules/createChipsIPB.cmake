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
#  @date    09 September 2018                                                      
#  @version 0.1                                                                  
#  @brief   cmake module to create Chips softcore processor IP block 
#                                                                                
##

FOREACH(dir IN LISTS CMAKE_MODULE_PATH)
  IF(IS_DIRECTORY ${dir}/../lib/chipsScripts)
    SET(chipsScripts_DIR ${dir}/../lib/chipsScripts)
  ENDIF()
ENDFOREACH()
IF(NOT DEFINED chipsScripts_DIR)
  MESSAGE(FATAL_ERROR "Can't find chipsScripts directory!")
ENDIF()

FUNCTION(createChipsIPB modelName ipbName ipRepo)
  SET(modelName ${modelName})
  SET(ipbName ${ipbName})
  SET(ipRepo ${ipRepo})
  SET(src_path ${CMAKE_BINARY_DIR}/${modelName}_chip/${ipbName}) # path to src files
  SET(chips_solution ${PROJECT_BINARY_DIR}/${ipbName}_chip)
  
  INCLUDE_DIRECTORIES(
    ${src_path} # path to src files
    )
  LINK_DIRECTORIES(
    )

  ADD_CUSTOM_COMMAND(OUTPUT
    ${chips_solution}/src/${ipbName}.v
    COMMAND ${chipsScripts_DIR}/bin/chipsc ${src_path}/${ipbName}.cpp -o ${ipbName}_chip -O3 --make-project --ip ${ipbName}
    IMPLICIT_DEPENDS CXX
    ${src_path}/${ipbName}.cpp
  ) 
  ADD_CUSTOM_TARGET(${ipbName}_chip ALL 
    DEPENDS ${chips_solution}/src/${ipbName}.v
  )
  ADD_CUSTOM_COMMAND(TARGET ${ipbName}_chip POST_BUILD
  # create ip_repo
  COMMAND ${CMAKE_COMMAND} -E make_directory ${ipRepo}/${ipbName}
  # copy generated chip to ip-repo
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_BINARY_DIR}/${ipbName} ${ipRepo}/${ipbName} 
  COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/${ipbName}
  COMMENT "Copy generated IP-Block into IP-Repo ${ip_repo}"
  )
ENDFUNCTION()
