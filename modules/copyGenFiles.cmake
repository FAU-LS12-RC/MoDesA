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
#  @author Streit Franz-Josef                                                    
#  @mail    franz-josef.streit@fau.de                                                   
#  @date   09 November 2017                                                      
#  @version 0.1                                                                  
#  @brief cmake module to get subdirectories of generated model                
#                                                                                
##

function(copyGenFiles ipb_folders chip_folders model)
  if(matlab)
    set(__matlab__ on)
  endif(matlab)

  # find all generated folders of the given model and copy them into build folder
  # afterwards copy template files into it

  if(matlab)
    set(matlab_dir "${CMAKE_CURRENT_SOURCE_DIR}/matlab")
    file(GLOB folders RELATIVE ${matlab_dir} ${matlab_dir}/${model}*[_hw,_sw,_chip])
    foreach(folders ${folders})
      if(EXISTS "${CMAKE_BINARY_DIR}/${folders}")
        # delete the folder if already exist
        file(REMOVE_RECURSE ${CMAKE_BINARY_DIR}${folders})
      endif()  
      file(RENAME ${matlab_dir}/${folders} ${CMAKE_BINARY_DIR}/${folders})
      file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/templates/data_types.cpp" DESTINATION "${CMAKE_BINARY_DIR}/${folders}")
      file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/templates/data_types.hpp" DESTINATION "${CMAKE_BINARY_DIR}/${folders}")
    endforeach()  
  endif()

  if(EXISTS "${CMAKE_BINARY_DIR}/${model}_hw")
    set(curdir "${CMAKE_BINARY_DIR}/${model}_hw")
    # then create list of given subdirectories within the model folder
    file(GLOB children RELATIVE ${curdir} ${curdir}/*)
    set(dirlist "")
    foreach(child ${children})
      if(IS_DIRECTORY ${curdir}/${child})
        message(STATUS "found ${child}")
        list(APPEND dirlist ${child})
      endif()
    endforeach()
    set(${ipb_folders} ${dirlist} PARENT_SCOPE)
  else()
    message(STATUS "No folder ${model}_hw")
  endif() 

  if(EXISTS "${CMAKE_BINARY_DIR}/${model}_chip")
    set(curdir "${CMAKE_BINARY_DIR}/${model}_chip")
    # then create list of given subdirectories within the model folder
    file(GLOB children RELATIVE ${curdir} ${curdir}/*)
    set(dirlist "")
    foreach(child ${children})
      if(IS_DIRECTORY ${curdir}/${child})
        message(STATUS "found ${child}")
        list(APPEND dirlist ${child})
      endif()
    endforeach()
    set(${chip_folders} ${dirlist} PARENT_SCOPE)
  else()
    message(STATUS "No folder ${model}_chip")
  endif()

  # If stimuli folder was generated copy it to build folder
  if(EXISTS "${matlab_dir}/stimuli")
    message(STATUS "found and copied stimuli data")
    file(RENAME ${matlab_dir}/stimuli ${CMAKE_BINARY_DIR}/stimuli)
  endif()
  
  # If stimuli folder was generated copy it to build folder
  if(EXISTS "${matlab_dir}/profile")
    message(STATUS "found and copied profile data")
    file(RENAME ${matlab_dir}/profile ${CMAKE_BINARY_DIR}/profile)
  endif()

  # If application graph was generated copy it to build folder
  if(EXISTS "${matlab_dir}/app_graph.txt")
    message(STATUS "found and copied application graph")
    file(RENAME ${matlab_dir}/app_graph.txt ${CMAKE_BINARY_DIR}/app_graph.txt)
  endif()

  # If model image was generated copy it to build folder
  if(EXISTS "${matlab_dir}/model.jpg")
    message(STATUS "found and copied model image")
    file(RENAME ${matlab_dir}/model.jpg ${CMAKE_BINARY_DIR}/model.jpg)
  endif()
endfunction()
