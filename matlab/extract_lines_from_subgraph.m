%% 
% -------------------------------------------------------------------------  
%   Copyright (c) 2017 Hardware-Software-Co-Design, Friedrich-
%   Alexander-Universitaet Erlangen-Nuernberg (FAU), Germany.
%   All rights reserved.
%
%   Licensed under the Apache License, Version 2.0 (the "License");
%   you may not use this file except in compliance with the License.
%   You may obtain a copy of the License at
%
%       http://www.apache.org/licenses/LICENSE-2.0
%
%   Unless required by applicable law or agreed to in writing, software
%   distributed under the License is distributed on an "AS IS" BASIS,
%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%   See the License for the specific language governing permissions and
%   limitations under the License.
% -------------------------------------------------------------------------  
% 
%  @author  Martin Letras, Streit Franz-Josef
%  @mail    franz-josef.streit@fau.de                                                   
%  @date    09 November 2017
%  @version 0.1
%  @brief   Method that extracts the information from the lines in a 
%           recursive way. The implementation of the method is recursive 
%           because, the structure of the branch is defined in a recursive way
%
%%

function [ output ] = extract_lines_from_subgraph( parent,handle,obj,fix_port)
    output               = obj;
    obj.blk_hierarchy
    lines                = get_param(parent,'Lines');
    tam                  = length(lines);
    
    my_lines             = [];
    
    for i=1:tam
        if handle == lines(i).SrcBlock
            my_lines{end+1} = lines(i);
        end
    end
    
    tam                  = length(my_lines);

        for i=1:tam
            source = my_lines{i}.SrcPort;
            if isempty(my_lines{i}.Branch)
               dst_handle = my_lines{i}.DstBlock;
               dst_hierar = getfullname(dst_handle)
               dst_port   = my_lines{i}.DstPort; 
               dst_id     = dst_handle;
               if (strcmp(get_param(dst_hierar,'Tag'),'subgraph') && strcmp(fix_port,'on'))
                   % the destination block is a subsystem and we have to
                   % connect directly with the port
                   if ~strcmp(dst_port,'enable') && ~strcmp(dst_port,'trigger')
                    ports = get_inport_blocks(dst_hierar)
                    dst_hierar = ports{str2num(dst_port)};
                   
                    dst_handle = get_param(dst_hierar,'Handle');
                    dst_port   = '1';
                    dst_id     = dst_handle;
                    
                   end
               %else if (strcmp(get_param(parent,'Tag'),'subgraph') && strcmp(get_param(handle,'BlockType'),'Outport'))
               %    ports = get_inport_blocks(dst_hierar)
               end
               
               output.ids_dst{end+1}    = dst_id;
               output.port_src{end+1}   = source;
               output.port_dst{end+1}   = dst_port;
               output.actor_dst{end+1}  = dst_hierar;
           else
               output = extract_lines_from_branch(output,my_lines{i}.Branch,source); 
           end
        end
    
end

function [ output ] = extract_lines_from_branch(obj,branch,source) 
   output   = obj;
   tam      = length(branch);
   for i=1:tam
       if isempty(branch(i).Branch)
           dst_handle = branch(i).DstBlock;
           dst_hierar = getfullname(dst_handle);
           dst_port   = branch(i).DstPort;
           dst_id     = dst_handle;
           
           output.port_src{end+1}   = source;
           output.port_dst{end+1}   = dst_port;
           output.actor_dst{end+1}  = dst_hierar;
           output.ids_dst{end+1}    = dst_id;
       else
           output = extract_lines_from_branch(output,branch(i).Branch,source);
       end
   end
   
end

function [inports] = get_inport_blocks(hierarchy)
    data = get_block_paths(hierarchy);
    tam = length(data);
    inports =  {};
    for i=1:tam
        if (strcmp(get_param(data{i},'BlockType'),'Inport'))
            inports{end+1} = data{i};
        end
    end
end


