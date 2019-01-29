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
%  @date    09 January 2019
%  @version 0.1
%  @brief   This functions generates the application graph from the model which 
%           can be read by OpenDSE
%
%%

function fid_dfg = generate_application_graph(model, fid_dfg)

% obtain the paths of all blocks in the model
paths = get_block_paths(model);

% it is necessary to compile the block to get more information about the
cmd = [model '([],[],[],''compile'')'];
eval(cmd);

for i = 1: length(paths)
    
    blk_name     = get_param(paths{i},'Name'); % get current blk name
    blk_id       = sscanf(Simulink.ID.getSID(paths{i}), [model ':%d']);  % get current blk id
    port_handles = get_param(paths{i},'PortHandles'); % get port handle of blk
    
    outport_line = get_param(port_handles.Outport,'Line'); % get output connections
    % extract dimensions, data_types complex information of the port
    dimensions_outport = get_param(port_handles.Outport, 'CompiledPortDimensions');
    data_types_outport = get_param(port_handles.Outport, 'CompiledPortDataType');
    % complex_ports_outport = get_param(port_handles.Outport, 'CompiledPortComplexSignal');
    
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
            name_dst_blk = get_param(dstport_properties.Parent,'Name');
            dst_blk_id   = sscanf(Simulink.ID.getSID([model '/' name_dst_blk]), [model ':%d']);  % get dst blk id
            fprintf(fid_dfg,['%s_%d/outputArg' num2str(j) '->%s_%d/inputArg' num2str(dstport_properties.PortNumber) '\n'],lower(blk_name),blk_id,lower(name_dst_blk),dst_blk_id);
            fprintf(fid_dfg,['out_port_dimension=[' num2str(get_scalar_port_dim(cell2mat(dimensions_outport(j,:)),1)) ']\n']); % write port dimensions for the tb generation
            fprintf(fid_dfg,['out_port_byte_size=[' num2str(get_port_byte_size(char(data_types_outport(j,:)))) ']\n']); % write port byte size for the tb generation
        end
    end
end
cmd = [model '([],[],[],''term'')']; % terminate compilation
eval(cmd);
end
