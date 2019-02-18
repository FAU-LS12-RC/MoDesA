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
%  @date    20 August 2018
%  @version 0.1
%  @brief   This functions rewrites the generated c files into a VivadoHLS 
%           specific form with pragmas for the input and output ports,
%           pipelining and dataflow parallelism. Therefore we remove all 
%           global variable definitions from the header
%
%
%%

function hw_ip_file_manipulation(blk_properties)

ports = get_param(blk_properties.hierarchy,'Ports');

% variable declaration
    init = '';
    init_cnt = 0;
    glob_vars = {};
    ban = 0;
    is_init = 0;
    is_terminate = 0;
    terminate_cnt = 0;
    is_for = 0;
    for_cnt = 0;
    while_cnt = 0;
    
    fid_h_file = fopen([blk_properties.file_dir '/' blk_properties.name '.h'],'r');
    fid_hpp_file = fopen([blk_properties.file_dir '/' blk_properties.name '_hw.hpp'],'w');
    fid_c_file = fopen([blk_properties.file_dir '/' blk_properties.name '.c'],'r');
    fid_cpp_file = fopen([blk_properties.file_dir '/' blk_properties.name '_hw.cpp'],'w');
    
    % here we reformat the header file
    while ~feof(fid_h_file)
        tline = fgetl(fid_h_file);
        tline = strrep( tline, '%', '%%' ); % change % to %% for right interpretation in fprintf
        % save definition of global vars and remove them
        if contains(tline, "extern")
            if (~contains(tline, ");")) && (~contains(tline, "(")) && (~contains(tline, "const"))
                tline = strtrim(tline);
                tmp = extractBefore(tline,";"); %extract global variables
                glob_vars{end+1} = erase([tmp ';\n'],"extern "); % and remove the extern keyword
                continue;
            end
        end
        
        % remove comments
        if (contains(tline, "Block signals") || contains(tline, "Block states")) && startsWith(strtrim(tline), "/*")
            continue;
        end
        if (contains(tline, "/* Model entry point functions */"))
            continue;
        end
        if (contains(tline,['void ' blk_properties.name '_init']) || contains(tline,['void ' blk_properties.name '_terminate'])) && startsWith(strtrim(tline), "extern")
            continue;
        end
        fprintf(fid_hpp_file,[tline '\n']);
    end
    
    disp('created header file');

    % here we extract the global variable declarations and init function
    % from the c file
    while ~feof(fid_c_file)
        tline = fgetl(fid_c_file);

        % save init function in variable
        if contains(tline,['void ' blk_properties.name '_init'])
            is_init = 1;
            if contains(tline, '{')
                init_cnt = init_cnt + 1;
                init = [init tline '{\n'];
            end
            continue;
        end
        if is_init && contains(tline, '{')
            init_cnt = init_cnt + 1;
        end
        if is_init && contains(tline, '}')
            init_cnt = init_cnt - 1;
            if(init_cnt == 0)
                is_init = 0;
                init = [init tline '\n'];
            end
        end
        if is_init
            init = [init tline '\n'];
        end
    end
    fclose(fid_c_file);
    fid_c_file = fopen([blk_properties.file_dir '/' blk_properties.name '.c'],'r');
    
    % make changes in source file: move init-function and global variables, add pragmas delete terminate function
    while ~feof(fid_c_file)
        tline = fgetl(fid_c_file);
        tline = strrep( tline, '%', '%%' ); % change % to %% for right interpretation in fprintf
        if contains(tline,[blk_properties.name '.h'])
            tline = strrep(tline,'.h','_hw.hpp');
        end
        
        % here we ignore all global variables within the c file to allow
        % the DATAFLOW pragma
        if (any(contains(glob_vars, eraseBetween(strtrim(tline),";","*/",'Boundaries','inclusive'))))
           if  (strtrim(tline) ~= "")
                continue;
           end
        end
        % check if we are in terminate function
        if contains(tline,['void ' blk_properties.name '_terminate'])
            is_terminate = 1;
            if contains(tline, '{')
                terminate_cnt = terminate_cnt +1;
            end
            continue;
        end
        if contains(tline, '{') && is_terminate
            terminate_cnt = terminate_cnt +1;
        end
        
        % check if we are in init function
        if contains(tline,['void ' blk_properties.name '_init'])
            is_init = 1;
            if contains(tline, '{')
                init_cnt = init_cnt + 1;
            end
            continue;
        end
        if is_init && contains(tline, '{')
            init_cnt = init_cnt + 1;
        end
        
        
        if ~is_init && ~is_terminate
            % add pipeline pragmas in innermost for loops,
            % ignore init funcion
            if contains(tline, 'for (')
                for_cnt = 0;
                is_for = 1;
                while_cnt = 0;
            end
            if contains(tline, 'while')
                while_cnt = 1;
            end
            % !!!! bracket and for has to be in the same line !!!!
            if contains(tline, '{') && ~contains(tline, 'for')
                for_cnt = for_cnt + 1;
            end
            if contains(tline, '}') && (for_cnt == 0) && is_for && ~while_cnt
                fprintf(fid_cpp_file,'#pragma HLS pipeline\n');
                is_for = 0;
            end
            if contains(tline, '}') && (for_cnt >= 1)
                for_cnt = for_cnt -1;
            end
            %print line in cpp file
            fprintf(fid_cpp_file,[tline '\n']);
        end
        
        % check if we are still in terminate function
        if contains(tline, '}') && is_terminate
            terminate_cnt = terminate_cnt -1;
            if terminate_cnt == 0
                is_terminate = 0;
            end
        end
        % check if we are still in init function
        if is_init && contains(tline, '}')
            init_cnt = init_cnt - 1;
            if(init_cnt == 0)
                is_init = 0;
            end
        end
        
        if contains(tline,['void ' blk_properties.name '_hw'])
            ban = 1;
        end
        
        if contains(tline,'{') && ban == 1
            % add HLS pragmas, here we specify the interfaces of the
            % vivado hls top function, adapt this according to your interface requirements
            % print here all global variables to support dataflow pragma
            fprintf(fid_cpp_file,['\n' cell2mat(glob_vars) '\n']);
            fprintf(fid_cpp_file,'static bool init=false;\n\n');
            fprintf(fid_cpp_file,'#pragma HLS reset variable=init\n');
            fprintf(fid_cpp_file,'#pragma HLS inline region recursive\n');
            fprintf(fid_cpp_file,'#pragma HLS DATAFLOW\n');
            fprintf(fid_cpp_file,'#pragma HLS INTERFACE ap_ctrl_none port=return\n'); 
            
            for j=1:ports(1)
                fprintf(fid_cpp_file,['#pragma HLS INTERFACE axis port=inputArg' num2str(j) '\n']);
            end
            for j=1:ports(2)
                fprintf(fid_cpp_file,['#pragma HLS INTERFACE axis port=outputArg' num2str(j) '\n\n']);
            end
            
            fprintf(fid_cpp_file,'if(!init){\n');
            fprintf(fid_cpp_file, init);
            fprintf(fid_cpp_file,'  init=true;\n');
            fprintf(fid_cpp_file,'}\n');
            ban = 0;
        end
    end
    
    disp('created source file');
        % close all file descriptors
    fclose(fid_hpp_file);
    fclose(fid_h_file);
    fclose(fid_cpp_file);
    fclose(fid_c_file);
end

