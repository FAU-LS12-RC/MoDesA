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
%  @brief   This functions isolates a Simulink Block from a Model, all
%           parameters are copied from the original model to the temporal model
%
%
%%

function bl = analyse_block_from_model( model, block, Params , Values)
bl                                              = block;
newline                                         = sprintf('\n');
% we do not generate code for the next elements: Rate Transition, EnablePort
% TriggerPortm, and subgraph
% and if the block has the hls_cogen string in the TAG string
tag = get_param(bl.blk_hierarchy,'Tag');
% if hw_ip or hw_chip block
if contains(tag,'hw')
    fid_dfg                                          = fopen('dfg_hw.txt','a');
    try
        % First, to obtain the name of the Simulink block
        name = get_param(bl.blk_hierarchy,'Name');
        % set model name based on block name and id
        model_name                      = [bl.blk_name '_' num2str(bl.id)];
        model_name = strrep(model_name, '__', '_' );                % change __ to _ for right name handling in vivado
        bl.header_file                   = ['ert_' model_name '.h']; % define name for header and 
        bl.source_file                   = ['ert_' model_name];
        % load the Simulink model
        load_system(new_system(model_name));
        % copy the block from the original model to the temporal model
        tmp_block                       = [model_name '/' name];
        add_block(bl.blk_hierarchy,tmp_block);
        % Extract the parameters and copy them from the original model
        % to the tmp model
        ParameterNames                  = get_param(bl.blk_hierarchy,'ObjectParameters');
        ParameterNames                  = fieldnames(ParameterNames);
        % obtain the number of parameters
        n_params = length(ParameterNames);
        
        for j=1:n_params
            cmd = ['param = get_param(''' strrep(bl.blk_hierarchy,newline,' ') ''','''  ParameterNames{j} ''');'];
            eval(cmd);
            try
                cmd = ['set_param(''' model_name '/' name ''',''' ParameterNames{j} ''', param);'];
                eval(cmd);
            catch
                %disp(['This is an only-read parameter: ' ParameterNames{j}]);
            end
        end
        
        % here we add the parameters of the masked subsystem
        hws                             = get_param(model_name, 'modelworkspace');
        c                               = strsplit(Params, '|');
        d                               = strsplit(Values, '|');
        for j=2:length(c)
            [num, status]               = str2num(d{j});
            if status == 0
                for h=j-1:2
                    if strcmp(d{j},c{h})
                        hws.assignin(c{j}, d{h});
                    end
                end
            else
                hws.assignin(c{j}, num);
            end
        end
        
        % here we pack all required block informations into a new struct
        blk_properties = struct('name',model_name,'org_name',name,'file_dir',bl.file_dir,'tag',tag,'hierarchy',bl.blk_hierarchy);
        
        % here we generate the Data-Flow Graph (DFG) based on the hw blocks
        [fid_dfg,dimensions_inport,data_types_inport,dimensions_outport,data_types_outport] = generate_dfg_hw(model, blk_properties, fid_dfg);
        % here we use the matlab target language compiler to influence code
        % generation specific for hw ip_blocks and hw_chips
        if strcmp(tag,'hw_ip') % if the block should be realized as hw_ip
            hw_optimizer(model_name);
        elseif strcmp(tag,'hw_chip') %or hw_chip block
            sw_config(model_name);
        end
        
        close_system(model_name,1);
        folder_sf = get_last_created_dir();
    catch ME
        if (strcmp(ME.identifier,'MATLAB:concatenate:dimensionMismatch'))
            msg                         = ['Dimension mismatch occurred: First argument has ', ...
                num2str(size(A,2)),' columns while second has ', ...
                num2str(size(B,2)),' columns.'];
            causeException              = MException('MATLAB:myCode:dimensions',msg);
            ME                          = addCause(ME,causeException);
        end
        rethrow(ME)
    end
    
    delete([folder_sf '/ert_main.c']);
    delete([folder_sf '/rtwtypes.h']);
    
    movefile([folder_sf '/*.h'], bl.file_dir);
    movefile([folder_sf '/*.c'], bl.file_dir);
    % remove the temporal folder with all it's files
    rmdir([model_name '_ert_rtw'],'s');
    
    % Here we do the target specific code manipulation
    if strcmp(tag,'hw_ip') % if the block should be realized as hw_ip
        hw_ip_file_manipulation(blk_properties); % this one is for VivadoHLS IPB
        % delete the old .c .h files
        delete([bl.file_dir '/' model_name '.c']);
        delete([bl.file_dir '/' model_name '.h']);
    elseif strcmp(tag,'hw_chip') %or hw_chip block
        hw_chip_file_manipulation(blk_properties,dimensions_inport,data_types_inport,dimensions_outport,data_types_outport); % this one for the Chips Soft-Cores
        % delete the old .c .h files
        delete([bl.file_dir '/' model_name '.c']);
        delete([bl.file_dir '/' model_name '.h']);
        if(exist(bl.file_dir,'dir'))
            movefile(bl.file_dir, [model '_chip/' lower(name)]);
        end
    else
        error('Sorry !!! \nYou specified the wrong Tag for the block %s.',name);
    end
    
    % delete used model
    delete([model_name '.slx']);
    % close file descriptor
    fclose(fid_dfg);
end
end

