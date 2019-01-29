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
%  @brief   This functions generates the hw dataflow graph
%
%%

function [fid_dfg,dimensions_inport,data_types_inport,dimensions_outport,data_types_outport] = generate_dfg_hw(model, blk_properties, fid_dfg)

ports = get_param(blk_properties.hierarchy,'Ports');
port_handles = get_param(blk_properties.hierarchy,'PortHandles');

outport_line = get_param(port_handles.Outport,'Line'); % get output connections
inport_line  = get_param(port_handles.Inport,'Line'); % get input connections

% it is necessary to compile the block to get more information about the
% ports
cmd = [model '([],[],[],''compile'')'];
eval(cmd);
% extract dimensions, data_types complex information of the port
dimensions_inport = get_param(port_handles.Inport, 'CompiledPortDimensions');
data_types_inport = get_param(port_handles.Inport, 'CompiledPortDataType');
complex_ports_inport = get_param(port_handles.Inport, 'CompiledPortComplexSignal');
dimensions_outport = get_param(port_handles.Outport, 'CompiledPortDimensions');
data_types_outport = get_param(port_handles.Outport, 'CompiledPortDataType');
% complex_ports_outport = get_param(port_handles.Outport, 'CompiledPortComplexSignal');
cmd = [model '([],[],[],''term'')']; % terminate compilation
eval(cmd);

if ~isempty(outport_line)
    nr_outports = size(outport_line);
    if(nr_outports(1)~=1) % matlab uses cell array so we have to convert it first
        data_types_outport = char(data_types_outport); % convert to non cell object
        outport_line = cell2mat(outport_line);
    else
        dimensions_outport = num2cell(dimensions_outport); % convert to non cell object
    end
    for j=1:nr_outports(1)
        dstport = get_param(outport_line(j), 'Dstporthandle'); % get connected dst ports
        dstport_properties = get(dstport);
        tag_dst_blk = get_param(dstport_properties.Parent,'Tag');
        if contains(tag_dst_blk,'sw')  % check if we are connected to a sw block
            fprintf(fid_dfg,['%s_hw/outputArg' num2str(j) '->sw\n'],blk_properties.name);
            fprintf(fid_dfg,['out_port_dimension=[' num2str(get_scalar_port_dim(cell2mat(dimensions_outport(j,:)),1)) ']\n']); % write port dimensions for the tb generation
            fprintf(fid_dfg,['out_port_byte_size=[' num2str(get_port_byte_size(char(data_types_outport(j,:)))) ']\n']); % write port byte size for the tb generation
            fprintf(fid_dfg,'write_adapt\n');
        elseif contains(tag_dst_blk,'hw')                         % if not then our dst_blk is a hw block
            name_dst_blk = get_param(dstport_properties.Parent,'Name');
            dst_blk_id   = sscanf(Simulink.ID.getSID([model '/' name_dst_blk]), [model ':%d']);  % get dst blk id
            fprintf(fid_dfg,['%s_hw/outputArg' num2str(j) '->%s_%d_hw/inputArg' num2str(dstport_properties.PortNumber) '\n'],blk_properties.name,lower(name_dst_blk),dst_blk_id);
        else                                                       % otherwise we need external outputs
            fprintf(fid_dfg,['%s_hw/outputArg' num2str(j) '->extern\n'],blk_properties.name);
            fprintf(fid_dfg,['out_port_dimension=[' num2str(get_scalar_port_dim(cell2mat(dimensions_outport(j,:)),1)) ']\n']); % write port dimensions for the tb generation
            fprintf(fid_dfg,['out_port_byte_size=[' num2str(get_port_byte_size(char(data_types_outport(j,:)))) ']\n']); % write port byte size for the tb generation
        end
        % add new outputs to the block
        add_block('built-in/Outport',[blk_properties.name '/Out' int2str(j)]);
        add_line(blk_properties.name,[blk_properties.org_name '/' int2str(j)],['Out' int2str(j) '/1'],'autorouting','on');
    end
end

if ~isempty(inport_line)
    nr_inports = size(inport_line);
    if(nr_inports(1)~=1)  % matlab uses cell array so we have to convert it first
        data_types_inport = char(data_types_inport); % convert to non cell object
        complex_ports_inport = cell2mat(complex_ports_inport); % convert to non cell object
        inport_line = cell2mat(inport_line); % convert to non cell object
    else
        dimensions_inport = num2cell(dimensions_inport); % convert to a cell object    
    end
    for j=1:nr_inports(1)
        srcport = get_param(inport_line(j), 'Srcporthandle');  % get connected src ports
        srcport_properties = get(srcport);
        tag_src_blk = get_param(srcport_properties.Parent,'Tag');       % get tag of src_blk
        if contains(tag_src_blk,'sw')                               % check if our src_blk is a sw boundary
            fprintf(fid_dfg,['sw->' '%s_hw/inputArg' num2str(j) '\n'],blk_properties.name);
            fprintf(fid_dfg,['in_port_dimension=[' num2str(get_scalar_port_dim(cell2mat(dimensions_inport(j,:)),1)) ']\n']); % write port dimension for tb generation
            fprintf(fid_dfg,['in_port_byte_size=[' num2str(get_port_byte_size(char(data_types_inport(j,:)))) ']\n']); % write port byte size for the tb generation
            fprintf(fid_dfg,'read_adapt\n');                             % add read adapter to DFG
        elseif isempty(tag_src_blk)                                     % if empty then it is a data_src
            fprintf(fid_dfg,['extern->' '%s_hw/inputArg' num2str(j) '\n'],blk_properties.name);
            fprintf(fid_dfg,['in_port_dimension=[' num2str(get_scalar_port_dim(cell2mat(dimensions_inport(j,:)),1)) ']\n']); % write port dimension for tb generation
            fprintf(fid_dfg,['in_port_byte_size=[' num2str(get_port_byte_size(char(data_types_inport(j,:)))) ']\n']); % write port byte size for the tb generation
        end
        % add new inputs to the block
        add_block('built-in/Inport',[blk_properties.name '/In' int2str(j)]);
        [dim_ret,~] = get_port_dim(cell2mat(dimensions_inport(j,:)),1);
        tmp_dim = ['[' num2str(dim_ret) ']'];
        set_param([blk_properties.name '/In' int2str(j)], 'PortDimensions', tmp_dim);
        % correct the datatype if datatype is a fixed point variable
        if strfind(data_types_inport(j,:),'fix') >= 1
            data_types_inport(j,:) = correct_fixed_point_format(data_types_inport(j,:));
        end
        
        set_param([blk_properties.name '/In' int2str(j)], 'OutDataTypeStr', data_types_inport(j,:));
        if complex_ports_inport(j) == 1
            set_param([blk_properties.name '/In' int2str(j)], 'SignalType', 'complex');
        else
            set_param([blk_properties.name '/In' int2str(j)], 'SignalType', 'real');
        end
        % connect the new inputs
        add_line(blk_properties.name,['In' int2str(j) '/1'], [blk_properties.org_name '/' int2str(j)],'autorouting','on');
    end
end

a = RTW.ModelSpecificCPrototype;
% configure input arguments
for j=1:ports(1)
    % Vivado HLS sets scalar pointers always to outputs, therefore
    % we have to check if input is a single data value
    if(1 ~= get_scalar_port_dim(cell2mat(dimensions_inport(j,:)),1))
        addArgConf(a,['In' num2str(j)],'Pointer',['inputArg' num2str(j)], 'const *');
    else
        addArgConf(a,['In' num2str(j)],'Value',['inputArg' num2str(j)], 'const');
    end
end

% configure output arguments
for j=1:ports(2)
    addArgConf(a,['Out' num2str(j)],'Pointer',['outputArg' num2str(j)], 'none');
end
setFunctionName(a,[blk_properties.name '_hw'],'step');
setFunctionName(a,[blk_properties.name '_init'],'init')

attachToModel(a,blk_properties.name);
end
