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
%  @date    09 November 2017
%  @version 0.1
%  @brief   This functions handles the boundaries of HW/SW islands
%
%%

function [src_edges,snk_edges,hwsw_edges,swhw_edges,islands_in_model] = handle_boundaries(model)

bl = model;
% creates a copy of the original model for software generation
model_name = [bl.mdl_name '_sw'];
try
    file_loc = [bl.mdl_name '.slx'];
    copyfile(file_loc,[model_name '.slx']);
catch
    warning('No slx file founded');
end

load_system(model_name);

% then we obtain the paths of the blocks in the model
paths = get_block_paths(model_name);
% variables for every kind of domain edge
hwsw_edges = {};
swhw_edges = {};
src_edges = {};
snk_edges = {};

order = 1; %define order of sw islands

% now we itterate over all blocks in the model and check for boundaries
for i = 1: length(paths)
    tag   = get_param(paths{i},'Tag');
    if strcmp(tag,'sw') % check if we are a sw block
        blk_name     = get_param(paths{i},'Name'); % get current blk name
        port_handles = get_param(paths{i},'PortHandles');
        
        outport_line = get_param(port_handles.Outport,'Line'); % get output connections
        inport_line  = get_param(port_handles.Inport,'Line'); % get input connections
        
        % it is necessary to compile the block to get more information about the
        % ports
        cmd = [model_name '([],[],[],''compile'')'];
        eval(cmd);
        % extract dimensions, data_types complex information of the port
        dimensions_inport = get_param(port_handles.Inport, 'CompiledPortDimensions');
        data_types_inport = get_param(port_handles.Inport, 'CompiledPortDataType');
        complex_ports_inport = get_param(port_handles.Inport, 'CompiledPortComplexSignal');
        sample_time_inport = get_param(port_handles.Inport, 'CompiledSampleTime');
        varSize_inport = get_param(port_handles.Inport,'CompiledPortDimensionsMode');
        dimensions_outport = get_param(port_handles.Outport, 'CompiledPortDimensions');
        data_types_outport = get_param(port_handles.Outport, 'CompiledPortDataType');
        complex_ports_outport = get_param(port_handles.Outport, 'CompiledPortComplexSignal');
        sample_time_outport = get_param(port_handles.Inport, 'CompiledSampleTime');
        varSize_outport = get_param(port_handles.Outport,'CompiledPortDimensionsMode');
        cmd = [model_name '([],[],[],''term'')'];                           % terminate compilation
        eval(cmd);
        
        if ~isempty(outport_line)
            nr_outports = size(outport_line);
            if(nr_outports(1)~=1)                                           % matlab uses cell array so we have to convert it first
                data_types_outport = char(data_types_outport);              % convert to non cell object
                complex_ports_outport = cell2mat(complex_ports_outport);    % convert to non cell object
                varSize_outport = cell2mat(varSize_outport);                % convert to non cell object
                outport_line = cell2mat(outport_line);                      % convert to non cell object
            else
                dimensions_outport = num2cell(dimensions_outport);          % convert to non cell object
            end
            for j=1:nr_outports(1)
                dstport = get_param(outport_line(j), 'Dstporthandle');      % get connected dst ports
                srcport = get_param(outport_line(j), 'Srcporthandle');      % get our own port handles 
                srcport_properties = get(srcport);
                dstport_properties = get(dstport);
                tag_dst_blk = get_param(dstport_properties.Parent,'Tag');
                if contains(tag_dst_blk,'hw')                               % check if our snk_blk is in hw
                    set_param(paths{i},'Tag',['sw_bound_' num2str(order)]); % declare block as sw_bound
                    order = order+1;
                    swhw_edges{end+1} = domain_channel(model_name,blk_name,srcport_properties.PortNumber,round(dstport),dimensions_outport(j,:),data_types_outport(j,:),complex_ports_outport(j,:),varSize_outport(j,:));
                elseif isempty(tag_dst_blk)                                 % if empty then our dst_blk is a sink block
                    snk_edges{end+1} = domain_channel(model_name,blk_name,srcport_properties.PortNumber,round(dstport),dimensions_outport(j,:),data_types_outport(j,:),complex_ports_outport(j,:),varSize_outport(j,:));
                end
            end
        end
        if ~isempty(inport_line)
            nr_inports = size(inport_line);
            if(nr_inports(1)~=1)                                            % matlab uses cell array so we have to convert it first
                data_types_inport = char(data_types_inport);                % convert to non cell object
                complex_ports_inport = cell2mat(complex_ports_inport);      % convert to non cell object
                varSize_inport = cell2mat(varSize_inport);                  % convert to non cell object
                inport_line = cell2mat(inport_line);                        % convert to non cell object
            else
                dimensions_inport = num2cell(dimensions_inport);            % convert to a cell object
            end
            for j=1:nr_inports(1)
                srcport = get_param(inport_line(j), 'Srcporthandle');       % get connected src ports
                dstport = get_param(inport_line(j), 'Dstporthandle');       % get our own port handles 
                srcport_properties = get(srcport);
                dstport_properties = get(dstport);
                tag_src_blk = get_param(srcport_properties.Parent,'Tag');   % get tag of src_blk
                if isempty(tag_src_blk)
                    src_edges{end+1} = domain_channel(model_name,blk_name,dstport_properties.PortNumber,round(srcport),dimensions_inport(j,:),data_types_inport(j,:),complex_ports_inport(j,:),varSize_inport(j,:));
                elseif contains(tag_src_blk,'hw')
                    set_param(paths{i},'Tag',['sw_bound_' num2str(order)]); % declare block as sw_bound
                    order = order+1;
                    hwsw_edges{end+1} = domain_channel(model_name,blk_name,dstport_properties.PortNumber,round(srcport),dimensions_inport(j,:),data_types_inport(j,:),complex_ports_inport(j,:),varSize_inport(j,:)); 
                end
            end
        end
    end
end
% since we obtained all the informations of the domain boundaries
% we can now delete all hw and snk/src blocks from the model
for i=1:length(paths)
    tag = get_param(paths{i},'Tag');
    if (isempty(tag) || contains(tag,'hw'))
        delete_block(paths{i});
    end
end
delete_unconnected_lines(model_name);
delete_unconnected_inputs(model_name);
delete_unconnected_outputs(model_name);

% create new inputs for the deleted data_srcs and hwsw edges
create_new_input_ports({src_edges{:} hwsw_edges{:}}); % concatenate a elements of cell arrays to connect all input edges
% create new outputs for the deleted data_snks and swhw edges
create_new_output_ports({snk_edges{:} swhw_edges{:}}); % concatenate a elements of cell arrays to connect all output edges

save_system(model_name);
paths           = get_block_paths(model_name);
a               = RTW.ModelSpecificCPrototype;
% configure the input and output arguments
for i=1:length(paths)
    if strcmp(get_param(paths{i},'BlockType'),'Inport')
        addArgConf(a,get_param(paths{i},'Name'),'Pointer',get_param(paths{i},'Name'), 'none');
    elseif strcmp(get_param(paths{i},'BlockType'),'Outport')
        addArgConf(a,get_param(paths{i},'Name'),'Pointer',get_param(paths{i},'Name'), 'none');
    end
end

setFunctionName(a,[model_name '_step'],'step');
setFunctionName(a,[model_name '_init'],'init');

attachToModel(a,model_name);

% perform SW code generation if we have at leas one sw block
nr_blk = size(find_system(model_name));
if nr_blk(1) > 1
    fprintf('Code Generation for SW is starting...\n');
    
    %Here we obtain the islands
    islands_in_model = generate_sw_islands(model_name);
    
    fprintf("\n### THESE ARE THE SW-ISLANDS\n");
    
    for j=1:length(islands_in_model)
        fprintf("### Cluster %d: %s contains ...\n",j,islands_in_model(j).name_island);
        for k=1:length(islands_in_model(j).blocks)
            fprintf("\t %s\n",islands_in_model(j).blocks{k});
        end
    end
    
    if ~exist(model_name,'dir')
        mkdir(model_name);
        % We move the code generated for the islands into the model_sw folder
        for j=1:length(islands_in_model)
            movefile(islands_in_model(j).name_island,model_name);
        end
    end
else
    % return an empty string if hw only
    islands_in_model = '';
end

if ~isempty(src_edges)
    tmp_blk_name = '';
    a=1;
    
    fprintf("\n### FOUND DATA SRC EDGES\n");
    for j=1:length(src_edges)
        % if we are still on the same block increment port count variable
        if strcmp(src_edges{j}.blk_name,tmp_blk_name) % if we are on a different block reset port count variable
            a=a+1;
        else
            a=1;
        end
        fprintf("\t SRC Edge at Inport %d of block %s_%s \n",a,src_edges{j}.blk_name,num2str(src_edges{j}.id));
        tmp_blk_name = src_edges{j}.blk_name;
    end
end

if ~isempty(hwsw_edges)
    tmp_blk_name = '';
    a=1;
    
    fprintf("\n### FOUND HW/SW EDGES\n");
    for j=1:length(hwsw_edges)
        % if we are still on the same block increment port count variable
        if strcmp(hwsw_edges{j}.blk_name,tmp_blk_name) % if we are on a different block reset port count variable
            a=a+1;
        else
            a=1;
        end
        fprintf("\t HW/SW Edge at Inport %d of block %s_%s \n",a,hwsw_edges{j}.blk_name,num2str(hwsw_edges{j}.id));
        tmp_blk_name = hwsw_edges{j}.blk_name;
    end
end

if ~isempty(swhw_edges)
    tmp_blk_name = '';
    a=1;
    
    fprintf("\n### FOUND SW/HW EDGES\n");
    for j=1:length(swhw_edges)
        % if we are still on the same block increment port count variable
        if strcmp(swhw_edges{j}.blk_name,tmp_blk_name) % if we are on a different block reset port count variable
            a=a+1;
        else
            a=1;
        end
        fprintf("\t SW/HW Edge at Outport %d of block %s_%s \n",a,swhw_edges{j}.blk_name,num2str(swhw_edges{j}.id));
        tmp_blk_name = swhw_edges{j}.blk_name;
    end
end

if ~isempty(snk_edges)
    tmp_blk_name = '';
    a=1;
    
    fprintf("\n### FOUND DATA SNK EDGES\n");
    for j=1:length(snk_edges)
        % if we are still on the same block increment port count variable
        if strcmp(snk_edges{j}.blk_name,tmp_blk_name) % if we are on a different block reset port count variable
            a=a+1;
        else
            a=1;
        end
        
        fprintf("\t SNK Edge at Outport %d of block %s_%s \n",a,snk_edges{j}.blk_name,num2str(snk_edges{j}.id));
        tmp_blk_name = snk_edges{j}.blk_name;
    end
end

close_system(model_name,0);
% 4 — name is a loaded Simulink® model or a Simulink model or library file on your MATLAB search path.
if exist([model_name '.slx'],'file') == 4
    delete([model_name '.slx']);
end
end

function delete_unconnected_inputs(model)
tmp_inports = find_system(model,'BlockType','Inport') ;
inports = {};
for i=1:length(tmp_inports)
    t = strfind(tmp_inports{i},'/');
    if length(t) == 1
        inports{end+1} = tmp_inports{i};
    end
end

for i=1:length(inports)
    port_connectivity = get_param(inports{i},'PortConnectivity');
    if isempty(port_connectivity.DstBlock)
        delete_block(inports{i}) ;
    end
end
end

function delete_unconnected_outputs(model)
tmp_outports = find_system(model,'BlockType','Outport') ;
outports = {};
for i=1:length(tmp_outports)
    t = strfind(tmp_outports{i},'/');
    if length(t) == 1
        outports{end+1} = tmp_outports{i};
    end
end

for i=1:length(outports)
    port_connectivity = get_param(outports{i},'PortConnectivity');
    if isempty(port_connectivity.SrcBlock)
        delete_block(outports{i}) ;
    end
end
end

function create_new_input_ports(edges)

for j=1:length(edges)
        
    % add new inputs to the edge
    add_block('built-in/Inport',[edges{j}.model_name '/In' int2str(j)]);
    [dim_ret,~] = get_port_dim(cell2mat(edges{j}.dimension),1);
    tmp_dim = ['[' num2str(dim_ret) ']'];
    set_param([edges{j}.model_name '/In' int2str(j)], 'PortDimensions', tmp_dim);
    block_pos = get_param([edges{j}.model_name '/In' int2str(j)],'Position');
    x = block_pos(1,1)-j*20;
    y = block_pos(1,2);
    width = block_pos(1,3);
    height = block_pos(1,4);
    % move inport block to the left
    set_param([edges{j}.model_name '/In' int2str(j)],'Position',[x y x+width y+height]);
    % correct the datatype if datatype is a fixed point variable
    if strfind(edges{j}.data_type,'fix') >= 1
        edges{j}.data_type = correct_fixed_point_format(edges{j}.data_type);
    end
    
    set_param([edges{j}.model_name '/In' int2str(j)], 'OutDataTypeStr', edges{j}.data_type);
    if edges{j}.complex == 1
        set_param([edges{j}.model_name '/In' int2str(j)], 'SignalType', 'complex');
    else
        set_param([edges{j}.model_name '/In' int2str(j)], 'SignalType', 'real');
    end
    % connect the new inputs
    add_line(edges{j}.model_name,['In' int2str(j) '/1'], [edges{j}.blk_name '/' int2str(edges{j}.port_nr)],'autorouting','on');
end
end

function create_new_output_ports(edges)

for j=1:length(edges)
       
    % add new outputs to the edge
    add_block('built-in/Outport',[edges{j}.model_name '/Out' int2str(j)]);
    % get port block position
    block_pos = get_param([edges{j}.model_name '/Out' int2str(j)],'Position');
    x = block_pos(1,1)+j*20;
    y = block_pos(1,2);
    width = block_pos(1,3);
    height = block_pos(1,4);
    % move outport block to the right
    set_param([edges{j}.model_name '/Out' int2str(j)],'Position',[x y x+width y+height]);
    % connect the new outputs
    add_line(edges{j}.model_name,[edges{j}.blk_name '/' int2str(edges{j}.port_nr)],['Out' int2str(j) '/1'],'autorouting','on');
end
end
