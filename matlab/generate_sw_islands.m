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
%  @author  Streit Franz-Josef
%  @mail    franz-josef.streit@fau.de                                                   
%  @date    19 November 2017
%  @version 0.1
%  @brief   This function returns a list of sw islands. Each entry of that list
%           contains all the blocks of an island for software-only execution
%
%%

function islands_in_model = generate_sw_islands(model)

% get all blocks from the model
[blocks] = get_block_paths(model);

% Here we extract all those blocks that have the 'sw_bound' as Tag property
tmp_blocks = {};
for j=1:length(blocks)
    % extract all software boundaries
    idx = strcmp(get_param(blocks,'Tag'), ['sw_bound_' num2str(j)]);
    % add block to list if any idx is one
    if any(idx(:))
        tmp_blocks{end+1} = blocks{idx};
    end
end

tmp_islands_in_model = {};
name_island = {};

% Now we create the island_list
for i=1:length(tmp_blocks)
    island = {};
    % Each software bound becomes an init element in the island
    island{end+1} = tmp_blocks{i};
    name_island{end+1} = [get_param(tmp_blocks{i},'Name') '_sw'];
    island = write_into_island(island,model,1);
    tmp_islands_in_model{end+1} = island;
end

%Then next we need to verify that there are no repeated islands
tmp_islands = tmp_islands_in_model;
tmp_islands_in_model = {};

if ~isempty(tmp_islands)
    tmp_islands_in_model{end+1} = tmp_islands{1};
else
    % if islands are empty we are a sw only model and can return after
    % code generation
    paths           = get_block_paths(model);
    varSize_outport={};
    for j=1:length(paths)
        port_handles = get_param(paths{j},'PortHandles');
        % it is necessary to compile the block to get more information about the
        % ports
        cmd = [model '([],[],[],''compile'')'];
        eval(cmd);
        varSize_outport{end+1} = get_param(port_handles.Outport,'CompiledPortDimensionsMode');
        cmd = [model '([],[],[],''term'')'];                           % terminate compilation
        eval(cmd);
    end
    
    % verticalize cell array because it can be a nested cell array
    varSize_outport = vertcat(varSize_outport{:});
    % delete empty elements from cell array
    varSize_outport = varSize_outport(~cellfun('isempty',varSize_outport));
    % we can only set specific C functin arguments if we have no variable size outputs
    if~(any(cell2mat(varSize_outport(:))))
        a               = RTW.ModelSpecificCPrototype;
        blocks = {};
        % configure the input and output arguments
        for j=1:length(paths)
            blocks{end+1} = paths{j};
            if strcmp(get_param(paths{j},'BlockType'),'Inport')
                addArgConf(a,get_param(paths{j},'Name'),'Pointer',get_param(paths{j},'Name'), 'none');
            elseif strcmp(get_param(paths{j},'BlockType'),'Outport')
                addArgConf(a,get_param(paths{j},'Name'),'Pointer',get_param(paths{j},'Name'), 'none');
            end
        end
        
        setFunctionName(a,[model '_step'],'step');
        setFunctionName(a,[model '_init'],'init');
        
        attachToModel(a,model);
    end
    
    sw_config(model);
    
    folder_sf = get_last_created_dir();
    
    mkdir(model);
    delete([folder_sf '/ert_main.c']);
    delete([folder_sf '/rtwtypes.h']);
    
    movefile([folder_sf '/*.h'], model);
    movefile([folder_sf '/*.c'], model);
    
    movefile([model '/' model '.h'],[model '/' model '.hpp'])
    movefile([model '/' model '.c'],[model '/' model '.cpp'])
    
    replace_string_source_code(model,'#include "rtwtypes.h"','#include "data_types.hpp"');
    replace_string_source_code(model, [model '.h'],[model '.hpp']);
    
    rmdir(folder_sf,'s');
    close_system(model,1);
    % delete temporal sw island model
    delete([model '.slx']);
    
    % pack island information into struct and return it
    islands_in_model = struct('name_island',model,'blocks',{blocks});
    return;
end

tmp_name_island       = name_island;
name_island           = {};

if ~isempty(tmp_name_island)
    name_island{end+1} = tmp_name_island{1};
else
    disp('variable tmp_name_island is empty !!!');
end

for i=2:length(tmp_islands)
    [tmp_islands_in_model,name_island] = add_island_in_list(...
        tmp_islands_in_model,tmp_islands{i},name_island,...
        tmp_name_island{i});
end

% ONCE WE KNOW THE CLUSTERS IN THE MODEL, WE PROCEED TO CREATE A
% NEW MODEL FOR EACH CLUSTER AND GENERATE THE CODE
for i=1:length(tmp_islands_in_model)
    new_island_model = name_island{i};
    % first we made a copy of the original model
    copyfile([model '.slx'],[new_island_model '.slx']);
    
    load_system(new_island_model);
    
    paths = get_block_paths(new_island_model);
    varSize_outport={};
    for j=1:length(paths)
        if ~isinList(tmp_islands_in_model{i},strrep(paths{j},new_island_model,model))
            delete_block(paths{j});
        end
    end
    
    delete_unconnected_lines(new_island_model);
    save_system(new_island_model);
    
    paths = get_block_paths(new_island_model);
    for j=1:length(paths)
        port_handles = get_param(paths{j},'PortHandles');
        % it is necessary to compile the block to get more information about the
        % ports
        cmd = [new_island_model '([],[],[],''compile'')'];
        eval(cmd);
        varSize_outport{end+1} = get_param(port_handles.Outport,'CompiledPortDimensionsMode');
        cmd = [new_island_model '([],[],[],''term'')'];                           % terminate compilation
        eval(cmd);
    end
    % verticalize cell array because it can be a nested cell array
    varSize_outport = vertcat(varSize_outport{:});
    % delete empty elements from cell array
    varSize_outport = varSize_outport(~cellfun('isempty',varSize_outport));
    % we can only set specific C functin arguments if we have no variable size outputs
    if~(any(cell2mat(varSize_outport(:))))
        a               = RTW.ModelSpecificCPrototype;
        % configure the input and output arguments
        for k=1:length(paths)
            if strcmp(get_param(paths{k},'BlockType'),'Inport')
                addArgConf(a,get_param(paths{k},'Name'),'Pointer',get_param(paths{k},'Name'), 'none');
            elseif strcmp(get_param(paths{k},'BlockType'),'Outport')
                addArgConf(a,get_param(paths{k},'Name'),'Pointer',get_param(paths{k},'Name'), 'none');
            end
        end
        
        setFunctionName(a,[new_island_model '_step'],'step');
        setFunctionName(a,[new_island_model '_init'],'init');
        
        attachToModel(a,new_island_model);
    end
    
    try
        sw_config(new_island_model);
    catch e
        close_system(new_island_model,1);
        delete([new_island_model '.slx']);
        warning('%s sw island code generation failed with error code %s\n',new_island_model,e.message);
    end
    
    folder_sf = get_last_created_dir();
    
    mkdir(new_island_model);
    delete([folder_sf '/ert_main.c']);
    delete([folder_sf '/rtwtypes.h']);
    
    movefile([folder_sf '/*.h'], new_island_model);
    movefile([folder_sf '/*.c'], new_island_model);
    
    movefile([new_island_model '/' new_island_model '.h'],[new_island_model '/' new_island_model '.hpp'])
    movefile([new_island_model '/' new_island_model '.c'],[new_island_model '/' new_island_model '.cpp'])
    
    replace_string_source_code(new_island_model,'#include "rtwtypes.h"','#include "data_types.hpp"');
    replace_string_source_code(new_island_model, [new_island_model '.h'],[new_island_model '.hpp']);
    
    rmdir(folder_sf,'s');
    close_system(new_island_model,1);
    % delete temporal island model
    delete([new_island_model '.slx']);
    
end
delete([model '.slx']);
% pack island information into struct and return it
islands_in_model = struct('name_island',name_island,'blocks',tmp_islands_in_model);
end

% This function is similar to a write operation in a set, the differences
% are the input parameters, the first one is a list of cell arrays and the
% second one is a cell array
function [list_out,list_out_names] = add_island_in_list(list,island,list_names,name)

for i=1:length(list)
    current_element = list{i};
    [element_in_list] = verifiy_equality_island(island,current_element);
    
    if ~element_in_list
        list{end+1} = island;
        list_names{end+1} = name;
    end
end
list_out = list;
list_out_names = list_names;
end

function [result] = verifiy_equality_island(island1,island2)

if length(island1) == length(island2)
    for i=1:length(island1)
        bool_value = false;
        for j=1:length(island1)
            if strcmp(island1{i},island2{j})
                bool_value = true;
            end
        end
        if bool_value == false
            break;
        end
    end
    
    if bool_value == false
        result = false;
    else
        result = true;
    end
else
    result = false;
end
end

% THIS IS THE CORE of the island software generation function, it receives
% a island, the model, and the currrent element in the island
% For the current element, we obtain all the incoming/outgoing blocks from
% the current element and we add them into the island.
% We stop when we have visited all the elements in the island and we
% cannot add more elements
function [island_res] = write_into_island(island,model,cur_elem)
handle_value     = get_param(island{cur_elem},'Handle');
[dst_blocks]     = get_destination_blocks(model,handle_value);

[island_res] = write_into_set(island,dst_blocks);

if length(island_res) ~= cur_elem
    island_res = write_into_island(island_res,model,cur_elem+1);
end
end

% This function performs a set writing operation, we receive a set and a
% new element will be inserted. If the element is not in the set, we insert
% it
function [result_list] = write_into_set(set,new_elements)
result_list = set;

for i=1:length(new_elements)
    [inList] = isinList(result_list,new_elements{i});
    if ~inList
        result_list{end+1} = new_elements{i};
    end
end
end

% This boolean function only verifies if a string value is in a cell array
function [inList] = isinList(List,value)
inList = false;
for i=1:length(List)
    if strcmp(List{i},value)
        inList = true;
        break;
    end
end
end


% This function receives a model and the handle of a block then
% returns the list of all the incomming/outgoing blocks from the
% source_handle
function [dst_ports] = get_destination_blocks(model,source_handle)
lines = get_param(model,'Lines');
dst_ports = {};

for i=1:length(lines)
    if lines(i).SrcBlock == source_handle
        dst_ports{end+1} = getfullname(lines(i).DstBlock);
    end
    if lines(i).DstBlock == source_handle
        dst_ports{end+1} = getfullname(lines(i).SrcBlock);
    end
end
end
