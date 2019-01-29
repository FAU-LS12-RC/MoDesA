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
%  @brief   class that encapsulates the information of a simulink block
%	    and defines an actor
%
%%

classdef actor < blk_actor
    
    properties 
    end
    
    methods
        %==================================================================
        %| method that receives the model_name
        %| and extracts the information of the current model
        %==================================================================
        function obj = actor(block_hierarchy)
            obj = obj@blk_actor(block_hierarchy);
            newline = sprintf('\n');
            obj.file_dir = [pwd  '/' strrep(strrep(obj.blk_hierarchy,newline,''),' ','_')];
            obj.type = get_param([obj.blk_hierarchy],'BlockType');
            obj.id   = sscanf(Simulink.ID.getSID(obj.blk_hierarchy), [obj.model_name ':%d']);  % get current blk id
        end
        
        %==================================================================
        %| method that receive the model and the object to generate the code 
        %==================================================================     
        function ret = actor_code_generation(model_name, obj, params, values)
            ret = obj;         
            if ~strcmp(obj.type,'Inport') && ~strcmp(obj.type,'Outport')
                ret = analyse_block_from_model(model_name, obj, params, values);
            end 
        end
        
        function obj = generate_folder(obj)
            if ~strcmp(obj.type,'Inport') && ~strcmp(obj.type,'Outport')...
                && contains(get_param(obj.blk_hierarchy,'Tag'),'hw')
                mkdir(obj.file_dir);
            end
        end
        
        function output = extract_connections_actors(obj,fix_port)
            output = obj;
            parent_hrk = get_param(obj.blk_hierarchy,'Parent');
            handle     = get_param(obj.blk_hierarchy,'Handle');
            output = extract_lines_from_subgraph( parent_hrk,handle,output,fix_port );
        end

        %==================================================================
        %| method that removes the rtwtypes includes in all the files and
        %| exchanges it with data_types.hpp
        %==================================================================
        function remove_rtwtypes(obj,dir,relativePath)
            prefix = '';
            if ~isempty(obj.source_file)
                if strcmp(relativePath,'on')
                    diff = strrep([dir '/' obj.blk_name],obj.base_folder,'');
                    n = count_character_string(diff,'/');
                    for i=1:n-1
                        prefix = [prefix '../'];
                    end
                end
                replace_string_source_code(obj.file_dir,'#include "rtwtypes.h"',['#include "' prefix 'data_types.hpp"']);
            end
        end
    end
end
