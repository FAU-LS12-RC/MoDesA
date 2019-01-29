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
%  @brief   father class that encapsulates the information and parameters 
%           of a block in an actor
%
%
%% 

classdef blk_actor
    
    properties 
        blk_hierarchy                % block hierarchy in the model
        blk_hierarchy_trimmed        % trimmed, erase the blank spaces and the break lines 
        blk_name                     % block name
        model_name                   % model name
        source_file                  % parameter to hold sourve file name
        header_file                  % parameter to hold header file name
        % This attributes are necessary to instantiate the network in the
        % subsystem hierarchy
        inputs                       % inputs
        outputs                      % outputs
        % These fields are necessary if the current block is a subsystem
        blocks                       % array that contains the top blocks
        n_blocks                     % holds the number of blocks in the top level
        base_folder
        file_dir
        type
        port_src                     % saves the source port 
        actor_dst                    % saves the destination actor
        port_dst                     % saves the destination port of the actor
        ids_dst
        id
        % These parameters for the rate transition
        input_sample
        output_sample
        is_MRN1
        is_MR1N
        % this flag indicate when an object has been wrapped
        isWrapped
    end
    
    methods
        %==================================================================
        %| method to define an actor block
        %==================================================================
        function obj = blk_actor(block_hierarchy)
            obj.base_folder             = pwd;
            obj.blk_hierarchy           = block_hierarchy;
            obj.model_name              = gcs; % get name of current Simulink system/model
            % trim the blk hierarchy
            newline = sprintf('\n');
            
            obj.blk_hierarchy_trimmed   = strrep(strrep(strrep(strrep(obj.blk_hierarchy, '/', '_'),' ','_'),'-','_'),newline,'_');
            obj.blk_name                = lower(get_param(block_hierarchy,'Name'));
            obj.isWrapped               = 0;
            % verify that the name corresponds to a valid C variable
            variable = '^[a-zA-Z_$][a-zA-Z_$0-9]*$';
            res = regexp(obj.blk_name, variable);
            if(length(res)==0)
            % the variable name is not correct, we have to correct it
                % use _ instead spaces, - , /
                newline = sprintf('\n');
                bname   = strrep(strrep(strrep(strrep(obj.blk_name, '/', '_'),' ','_'),'-','_'),newline,'_');
                number = '^(0|[1-9][0-9]*)$';
                if (regexp(bname(1),number))
                    % this means that the strings begins with a number
                    bname = ['_' bname];
                end
                obj.blk_name = lower(bname);
            end
            %check if name is not a reserved word
            obj.blk_name                = check_reserved_word(obj.blk_name);
            ports                       = get_param(obj.blk_hierarchy,'Ports');
            obj.inputs                  = ports(1);
            obj.outputs                 = ports(2);
            obj.is_MRN1                 = 0;
            obj.is_MR1N                 = 0;
        end
    end
end
