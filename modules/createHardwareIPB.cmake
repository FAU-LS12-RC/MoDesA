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
#  @brief   cmake module to create VIVADO_HLS ip block 
#                                                                                
##

FOREACH(dir IN LISTS CMAKE_MODULE_PATH)
  IF(IS_DIRECTORY ${dir}/../lib/ipbScripts)
    SET(ipbScripts_DIR ${dir}/../lib/ipbScripts)
  ENDIF()
ENDFOREACH()
IF(NOT DEFINED ipbScripts_DIR)
  MESSAGE(FATAL_ERROR "Can't find ipbScripts directory!")
ENDIF()

FUNCTION(createHardwareIPB modelName ipbName ipRepo)
  SET(modelName ${modelName})
  SET(ipbName ${ipbName})
  SET(ipRepo ${ipRepo})
  SET(src_path ${CMAKE_BINARY_DIR}/${modelName}_hw/${ipbName}) # path to src files
  SET(vivado_hls_solution ${PROJECT_BINARY_DIR}/VivadoHLS_${ipbName}/solution1)

  IF(NOT DEFINED CMAKE_FLAGS_RELEASE)
    SET(CMAKE_FLAGS_RELEASE "-Wall -O2 -DNDEBUG")
  ENDIF(NOT DEFINED CMAKE_FLAGS_RELEASE)
  IF(NOT DEFINED CMAKE_FLAGS_DEBUG)
    SET(CMAKE_FLAGS_DEBUG "-Wall -ggdb")
  ENDIF(NOT DEFINED CMAKE_FLAGS_DEBUG)

  IF(testbench)
    SET(__testbench__ ON)
  ENDIF(testbench)

  SET(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${CMAKE_FLAGS_RELEASE}")
  SET(CMAKE_C_FLAGS_RELEASE   "${CMAKE_C_FLAGS_RELEASE} ${CMAKE_FLAGS_RELEASE}")
  SET(CMAKE_CXX_FLAGS_DEBUG   "${CMAKE_CXX_FLAGS_DEBUG} ${CMAKE_FLAGS_DEBUG}")
  SET(CMAKE_C_FLAGS_DEBUG     "${CMAKE_C_FLAGS_DEBUG} ${CMAKE_FLAGS_DEBUG}")

  INCLUDE_DIRECTORIES(
    ${src_path} # path to src files
    )
  LINK_DIRECTORIES(
    )

  GET_PROPERTY(INCLUDE_LIST DIRECTORY ${PROJECT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
  SET(include_flags "")
  FOREACH(include_dir ${INCLUDE_LIST})
    SET(include_flags "${INCLUDE_FLAGS} -I${INCLUDE_DIR}")
  ENDFOREACH(include_dir)
  CONFIGURE_FILE(${ipbScripts_DIR}/VivadoHLS.tcl.in ${PROJECT_BINARY_DIR}/VivadoHLS_${ipbName}.tcl @ONLY)

  ADD_CUSTOM_COMMAND(OUTPUT
    ${vivado_hls_solution}/syn/vhdl/${ipbName}.vhd
    COMMAND vivado_hls -f VivadoHLS_${ipbName}.tcl
    #COMMAND vivado_hls -p VivadoHLS_${ipbName} #use -p option to open generated project
    IMPLICIT_DEPENDS CXX
    ${src_path}/${ipbName}.cpp
    )
  ADD_CUSTOM_TARGET(VivadoHLS_${ipbName} ALL 
    DEPENDS ${vivado_hls_solution}/syn/vhdl/${ipbName}.vhd
    )
  ADD_CUSTOM_COMMAND(TARGET VivadoHLS_${ipbName} POST_BUILD
    # exchange logo of IP-Blocks
    COMMAND ${CMAKE_COMMAND} -E remove -f ${vivado_hls_solution}/impl/ip/misc/logo.png
    COMMAND ${CMAKE_COMMAND} -E copy ${ipbScripts_DIR}/logo.png ${vivado_hls_solution}/impl/ip/misc/
    # create ip_repo
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ipRepo}/${ipbName}
    # copy generated ipb to ip-repo
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${vivado_hls_solution}/impl/ip ${ipRepo}/${ipbName} 
    COMMENT "Copy generated IP-Block into IP-Repo ${ip_repo}"
    )

  IF(testbench) # generate C-Testbench
    ADD_EXECUTABLE(${ipbName} 
      ${src_path}/dummy.cpp
      ${src_path}/${ipbName}.cpp
      )
    SET_TARGET_PROPERTIES(${ipbName} PROPERTIES
      COMPILE_FLAGS "-Wall -fPIC -Wno-unknown-pragmas"
      LINK_FLAGS "-fPIC "
      )
    TARGET_LINK_LIBRARIES(${ipbName}
      ${LIBRARIES_FROM_REFERENCES}
      ${EXTERNAL_LIBS}
      )
  ENDIF()
ENDFUNCTION()
