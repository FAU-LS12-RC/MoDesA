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
%  @brief This is the initial point of the code generator, at this point, 
%         the model is traversed hierarchically
%
%%

classdef model
    properties 
        mdl_name                 % string that contains the name of the simulink system
        mdl_name_trimmed
        blk_hierarchy_trimmed
        blocks                   % array that contains the top level blocks
        n_blocks                 % holds the number of blocks in the top level
        inputs                   
        outputs                  
        base_folder
        file_dir
    end
    methods 
        %==================================================================
        %| define the constructor that receives the model_name  
        %==================================================================
        function obj = model(model_name)
            obj.mdl_name                    = model_name;
            newline                         = sprintf('\n');
            obj.mdl_name_trimmed            = strrep(strrep(strrep(strrep(obj.mdl_name, '/', '_'),' ','_'),'-','_'),newline,'_');
            obj.blk_hierarchy_trimmed       = obj.mdl_name_trimmed;
            obj.blocks                      = [];
            obj.base_folder                 = pwd;
            obj.file_dir                    = [pwd '/' obj.mdl_name_trimmed];
        end
        %==================================================================
        %| method that extracts the hierarchy from the simulink model  
        %| the hierarchy will be stored in the blocks array
        %==================================================================
        function out = extract_hierarchy(obj)
            out                             = obj;
            load_system(out.mdl_name);
            % load the elements in the top level of the model
            bl                              = get_block_paths(obj.mdl_name);
            % find the blocks and concatenate them with the initial path
            out.n_blocks                    = length(bl);
            % until here the first level of the diagram has been generated
            % the next step is traverse the model in a recursive way
            out.file_dir                    = [pwd  '/' out.mdl_name_trimmed];
            for i=1:out.n_blocks
                tag                         = get_param(bl{i},'Tag');
                % this could be future work to handle subgraphs in model
                if strcmp(tag,'subgraph')
                    out.blocks{i}           = subgraph(bl{i});
                else
                    out.blocks{i}           = actor(bl{i});
                end    
            end
            out.blocks = out.blocks';     
        end
        %==================================================================
        %| method that creates a folder for every HW block  
        %==================================================================
        function generates_folders_model(obj)
            nr_hw_blk_ip = size(find_system(obj.mdl_name_trimmed,'FindAll','on','regexp','on','Tag','^hw_ip')); % search for blocks starting with hw_ip
            nr_hw_blk_chip = size(find_system(obj.mdl_name_trimmed,'FindAll','on','regexp','on','Tag','^hw_chip')); % search for blocks starting with hw_ip
            mkdir([obj.file_dir]);
            if nr_hw_blk_ip(1) > 0 % generate folders if we have at least one hw block
              fprintf('Found HW ip block code generation is starting...\n');
              for i=1:obj.n_blocks
                  generate_folder(obj.blocks{i});
              end
            end  
            if nr_hw_blk_chip(1) > 0 % generate folders if we found at least one hw_chip block in the model
              fprintf('Found HW chips block code generation is starting...\n');
              mkdir([obj.file_dir '_chip']);
            end  
        end
        %==================================================================
        %| method that extracts the connections from the Simulink model   
        %==================================================================
        function output = extract_connections_model(obj,fix_port)
            output = obj;
            for i=1:output.n_blocks
                output.blocks{i} = extract_connections_actors(output.blocks{i},fix_port);
            end
        end
        
        %==================================================================
        %| method that performs the HW code generation
        %==================================================================
        function [output,src_edges,snk_edges,hwsw_edges,swhw_edges,islands_in_model] = generate_code(model_name, obj)
            % verify if the object is a subsystem and traverse it
            output = obj;
            for i=1:obj.n_blocks
                output.blocks{i} = actor_code_generation(model_name, output.blocks{i},'','');
            end
            cd(output.base_folder);
            [src_edges, snk_edges,hwsw_edges,swhw_edges,islands_in_model] = handle_boundaries(obj);
        end
        
        %==================================================================
        %| method that removes the rtwtypes includes in all the files 
        %==================================================================
        function remove_rtwtypes_from_model(obj,RelativePath)
            for i=1:obj.n_blocks
                remove_rtwtypes(obj.blocks{i},obj.file_dir,RelativePath);
            end
        end
    end
    
    methods (Static)
        
    end
end
