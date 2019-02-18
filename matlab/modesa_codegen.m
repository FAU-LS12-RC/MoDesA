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
%  @author  Streit Franz-Josef, Martin Letras
%  @mail    franz-josef.streit@fau.de                                                   
%  @date    09 November 2017
%  @version 0.1
%  @brief   main function that performs the execution of the code generation
%  @param   mdl_name = name of the model
%  @param   mdl_path = path to the model
%  @param   profiling = generates an application graph and sw profiles the model
%
% example: modesa_codegen('test_model', 'path_to_test_model')
% Remember: Block in HW      --> Tag 'hw_ip'
%           Block on HW Chip --> Tag 'hw_chip'
%           Block in SW      --> Tag 'sw'
%           Debug SRC Block  --> Tag 'no tagging !!!'
%           Debug SNK Block  --> Tag 'no tagging !!!'
%%

function [obj] = modesa_codegen( mdl_name , mdl_path , profiling)
% Turn off WARNING 'Escaped character '\ ' is not valid.
% See 'doc sprintf' for supported special characters.'
warning('off', 'MATLAB:printf:BadEscapeSequenceInFormat');

% here we clean up at the beginning if legacy code exists
% if an old model with this name is loaded close it
if bdIsLoaded(mdl_name)
    close_system(mdl_name,0);
end
% with this command we register the MoDesA code replacement library
sl_refresh_customizations
 
% add path for MoDesA_lib.slx to matlab search path 
addpath('lib','-end');

% if an old folder with this name exists remove it
if exist(mdl_name,'dir') == 7
    rmdir(mdl_name,'s');
end
% if an old model with this name exists remove it
if exist([mdl_name '.slx'],'file') == 2
    delete('dfg_hw.txt');
end

% model has to be in the models folder, out of this we create a
% temporal copy of the model in the archive_test folder
file_name = [];
try
    copyfile(['./../models/' mdl_path '/' mdl_name '.slx'],['./' mdl_name '.slx']);
    file_name = ['./' mdl_name '.slx'];
catch
    disp('There is no model with slx extension');
end
load_system(mdl_name);

% generate image from Model
systemHandle = get_param(mdl_name, 'Handle');
saveas(systemHandle,'model.jpg','jpg');

% generate HW Stimuli files if write_stimuli block is inserted
try
    writeStim_blks = find_system(mdl_name, 'MaskType','writeStimuli');
    for k = 1: size(writeStim_blks)
        if k == 1
            set_param(mdl_name, 'StopTime', 'Inf');
            mkdir('stimuli');
            sim(mdl_name);
            % close library
            close_system('MoDesA_lib');
        end
        ports = get_param(writeStim_blks{k},'PortHandles');
        srcSignal = get_param(ports.Inport,'Line');
        delete_line(srcSignal);
        delete_block(get_param(writeStim_blks{k},'Handle'));
    end
catch
    disp('No write_stimuli block in model');
end

% generate sw profiling of application not yet fully implemented
try
    if strcmp(profiling,'on')
        disp('Start SW profiling');
        fid_dfg = fopen('app_graph.txt','a');
        fid_dfg = generate_application_graph(mdl_name, fid_dfg);
        fclose(fid_dfg);
    elseif strcmp(profiling,'off')
        disp('No SW profiling required');
    else
        warning('%s is wrong parameter to setup profiling, use ether ''on'' or ''off''',profiling);
    end
catch
    save_system;
    close_system;
end

close_system(mdl_name,1);

obj = model(mdl_name);
obj = extract_hierarchy(obj);
obj = extract_connections_model(obj,'on');
generates_folders_model(obj);

try
    [obj,src_edges,snk_edges,hwsw_edges,swhw_edges,islands_in_model] = generate_code(mdl_name,obj);
catch e
    save_system;
    close_system;
    folders = dir();
    for j=1:length(folders)
        if folders(j).isdir && (~strcmp(folders(j).name,'.') && ~strcmp(folders(j).name,'..') && ~strcmp(folders(j).name,'lib'))
            rmdir(folders(j).name, 's');
        end
    end
    delete('*.slx*');
    %if exist('rtwmakecfg','file') == 2
    %    delete('rtwmakecfg.m');
    %end
    delete *.mex* *.ppm *.c *.mat *.tlc *.jpg;
    if exist('dfg_hw.txt','file') == 2
        delete('dfg_hw.txt');
    end
    if exist('app_graph.txt','file') == 2
        delete('app_graph.txt');
    end
    error('code generation failed with message %s ... delete all generated files and folders\n',e.message);
end

% generated hw files post processing
if(exist([pwd '/' mdl_name],'dir'))
    % if folder contains just . and .. we know it is empty
    if(length(dir([pwd '/' mdl_name]))~=2)
        remove_rtwtypes_from_model(obj,'on');
        rename_folders_recursive(obj.file_dir);
        movefile([pwd '/' mdl_name], [ pwd '/' mdl_name '_hw']);
        % copy the dataflow information into the hw folder
        if(exist([pwd '/dfg_hw.txt'],'file'))
            copyfile([pwd '/dfg_hw.txt'], [pwd '/' mdl_name '_hw/']);
        end
    else
        rmdir([pwd '/' mdl_name],'s');
    end
end

% generated chip files post processing
if(exist([ pwd '/' mdl_name '_chip'],'dir'))
    path = [obj.file_dir '_chip'];
    for i=1:obj.n_blocks
        obj.blocks{i}.file_dir = [path '/' obj.blocks{i}.blk_name];
        remove_rtwtypes(obj.blocks{i},path,'on');
    end
    rename_folders_recursive(path);
    % copy the dataflow information into the chip folder
    if(exist([ pwd '/dfg_hw.txt'],'file'))
        copyfile([ pwd '/dfg_hw.txt'], [ pwd '/' mdl_name '_chip/']);
    end
end

% 2 — name is a file with extension
if exist('dfg_hw.txt','file') == 2
    delete('dfg_hw.txt');
end

delete(file_name);

% if we found at least one sw island we generate the main function for the PSoC PS system
if ~isempty(islands_in_model)
    try
        generate_sw_main(mdl_name,src_edges,snk_edges,hwsw_edges,swhw_edges,islands_in_model);
    catch e
        save_system;
        close_system;
        folders = dir();
        for j=1:length(folders)
            if folders(j).isdir && (~strcmp(folders(j).name,'.') && ~strcmp(folders(j).name,'..') && ~strcmp(folders(j).name,'lib'))
                rmdir(folders(j).name,'s');
            end
        end
        
        delete *.slx* *.mex* *.ppm *.c *.mat *.tlc *.jpg;
        if exist('dfg_hw.txt','file') == 2
            delete('dfg_hw.txt');
        end
        if exist('app_graph.txt','file') == 2
            delete('app_graph.txt');
        end
        error('write main failed with message %s ... delete all generated files and folders\n',e.message);
    end
end

% remove meta simulation folder
% 7 — name is a folder
if exist('slprj','dir') == 7
    rmdir('slprj','s');
end

fprintf('\nMoDesA: "code generation completed successfully."\n');
bdclose(obj.mdl_name_trimmed); %close current system without saving

% here we clean up
clear all; %clear all persistent variables
delete *.slx* *.mex* *.ppm *.c *.mat *.tlc;
end
