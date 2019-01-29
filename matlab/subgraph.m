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
%  @author Martin Letras, Streit Franz-Josef
%  @mail    franz-josef.streit@fau.de                                                   
%  @date   09 November 2017
%  @version 0.1
%  @brief class that encapsulates the information and parameters of a block
%
%
%%

classdef subgraph < blk_actor
    
    methods
        %==================================================================
        %| method that receives the model_name
        %| and extracts the information of the current model
        %==================================================================
        function obj = subgraph(block_hierarchy)
            % call the father class constructor
            obj                         = obj@blk_actor(block_hierarchy);
            bl                          = get_block_paths(block_hierarchy);
            n_bls                       = length(bl);
            fprintf('Traverse subsystem %s \n',obj.blk_hierarchy);
            obj.n_blocks                = n_bls;     
            newline                     = sprintf('\n');
            obj.file_dir                = [pwd  '/' strrep(strrep(obj.blk_hierarchy,newline,''),' ','_')];
            for i=1:obj.n_blocks
                tag                     = get_param(bl{i},'Tag');
                tam                     = length(get_block_paths(bl{i}));
                if (strcmp(tag,'subgraph') && tam>0)
                    fprintf('Type subsystem %s\n',bl{i});
                    obj.blocks{i}       = subgraph(bl{i});
                else
                    fprintf('Type block %s\n',bl{i});
                    obj.blocks{i}       = actor(bl{i});
                end
            end
            obj.id                      = sscanf(Simulink.ID.getSID(obj.blk_hierarchy), [obj.model_name ':%d']);  % get current blk id
            obj.blocks                  = obj.blocks';
        end
        %==================================================================
        %| method that extracts the connections of the blocks inside the
        %| subgraph
        %==================================================================
        function output = extract_connections_actors(obj,fix_port)
            output                      = obj;
            parent_hrk                  = get_param(obj.blk_hierarchy,'Parent');
            handle                      = get_param(obj.blk_hierarchy,'Handle');
            for i=1:output.n_blocks
                output.blocks{i}        = extract_connections_actors(output.blocks{i},fix_port);
            end
            % here we connect all the objects present in a subgraph
            output                      = extract_lines_from_subgraph( parent_hrk,handle,output ,fix_port);
        end
        %==================================================================
        %| method that removes the rtwtypes includes in all the files
        %==================================================================
        function remove_rtwtypes(obj,relativePath)
            for i=1:obj.n_blocks
                remove_rtwtypes(obj.blocks{i},relativePath);
            end
            prefix                      = '';
            if ~isempty(obj.source_file)
                if strcmp(relativePath,'on')
                    diff                = strrep(obj.file_dir,obj.base_folder,'');
                    n                   = count_caracter_string(diff,'/');
                    for i=1:n-1
                        prefix          = [prefix '../'];
                    end
                end
                
                % ignore the prefix
                replace_string_source_code(obj.file_dir,'#include "rtwtypes.h"','#include "data_types.hpp"'); 
            end
        end 
        %==================================================================
        %| method that returns all the lines connected to the specified port
        %==================================================================
        function [n,in] = seek_src_ports(obj,port)
            tam                     = length(obj.port_src);
            counter                 = 0 ;
            index                   = [];
            for i=1:tam
                C = strsplit(obj.port_src{i},'.');
                if strcmp(C{1},port)
                    counter         = counter + 1;
                    index(end+1)    = i;
                end
            end
            n                       = counter;
            in                      = index;
        end
         
        %==================================================================
        %|  method that generates C code using the Simulink coder
        %|  This code is generated only for atomic blocks
        %|  and extracts parameters like port type and size of subsystems
        %|  the third parameter is the parameter extraction from the
        %|  subsystem
        %==================================================================
        function ret = actor_code_generation(model_name,obj,params,values)
            % verify if the object is a subsystem and traverse it
            ret                     = obj;
                fprintf('Traverse subsystem %s... \n',obj.blk_name);    
                % also generate the code for the subsystem block
                
                % defines the masked variable and declares it in the current
                % workspace
                data                = params;
                vals                = values;
                if(strcmp(get_param(obj.blk_hierarchy,'Mask'),'on'))
                    dt              = '';
                    dt              = get_param(obj.blk_hierarchy,'MaskPropertyNameString');
                    data            = [data '|' dt];
                    
                    vl              = ''; 
                    vl              = get_param(obj.blk_hierarchy,'MaskValueString');
                    vals            = [vals '|' vl];
                end
                for i=1:ret.n_blocks
                    % Recursive call to code_generation
                    ret.blocks{i}   = actor_code_generation(model_name, ret.blocks{i},data,vals);
                end
                
                ret = analyse_block_from_model(model_name, ret, data,vals);
                cd(ret.base_folder);
        end
       
      
       function generate_folder(obj)
            mkdir(obj.file_dir);
            for i=1:obj.n_blocks
                generate_folder(obj.blocks{i});
            end
        end
       
       %===================================================================
       %| method that returns the validated name of the son
       %===================================================================
      function [name,found] = get_son_hierarchy(obj, son_hierarchy)
           name                     = obj.blocks{1};
           found                    = false;
           for i=1:obj.n_blocks
               if(strcmp(son_hierarchy,obj.blocks{i}.blk_hierarchy))
                   name             = obj.blocks{i};
                   found            = true;
                   break;
               end
           end
      end
    end
end
