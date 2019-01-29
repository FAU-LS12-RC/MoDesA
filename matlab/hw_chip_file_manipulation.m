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
%  @brief   This functions rewrites the generated c files into a Chips
%           soft processor specific form with adapters for the input and
%           output ports.
%
%
%%

function hw_chip_file_manipulation(blk_properties,dimensions_inport,data_types_inport,dimensions_outport,data_types_outport)

ports = get_param(blk_properties.hierarchy,'Ports');

% variable declaration
init = '';
init_cnt = 0;
glob_vars = '';
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
    
    % save definition of global vars and remove them
    if contains(tline, "extern")
        if (~contains(tline, ");")) && (~contains(tline, "(")) && (~contains(tline, "const"))
            tline = strtrim(tline);
            glob_vars = erase([tline '\n' glob_vars],"extern ");
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


% make changes in source file: move init-function and global variables and delete terminate function
while ~feof(fid_c_file)
    tline = fgetl(fid_c_file);
    tline = strrep( tline, '%', '%%' ); % change % to %% for right interpretation in fprintf
    if contains(tline,[blk_properties.name '.h'])
        tline = strrep(tline,'.h','_hw.hpp');
    end
    
    if contains(glob_vars, strtrim(tline))
        continue;
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
        fprintf(fid_cpp_file,['\n' glob_vars '\n']);
        fprintf(fid_cpp_file,'static bool init=true;\n');
        
        fprintf(fid_cpp_file,'if(init){\n');
        fprintf(fid_cpp_file, init);
        fprintf(fid_cpp_file,'  init=false;\n');
        fprintf(fid_cpp_file,'}\n');
        ban = 0;
    end
end

cnt_arguments = ''; % in this variable we store all in- and outport arguments

for j=1:ports(1)
    fprintf(fid_cpp_file,['int inputArg' num2str(j) ' input("inputArg' num2str(j) '");\n']);
end

for j=1:ports(2)
    fprintf(fid_cpp_file,['int outputArg' num2str(j) ' output("outputArg' num2str(j) '");\n']);
end

fprintf(fid_cpp_file,'void main() {\n\n');

for j=1:ports(1)
    input_type = char(data_types_inport(j,:));
    switch input_type
        case 'double'
            chips_type = 'double';
        case 'single'
            chips_type = 'float';
        otherwise
            chips_type = [input_type '_T'];
    end
    fprintf(fid_cpp_file,['\t%s input_' num2str(j) '[%d];\n'],chips_type,get_scalar_port_dim(cell2mat(dimensions_inport(j,:)),1));
    cnt_arguments = [cnt_arguments 'input_' num2str(j) ', '];
end

for j=1:ports(2)
    output_type = char(data_types_outport(j,:));
    switch output_type
        case 'double'
            chips_type = 'double';
        case 'single'
            chips_type = 'float';
        otherwise
            chips_type = [output_type '_T'];
    end
    fprintf(fid_cpp_file,['\t%s output_' num2str(j) '[%d];\n'],chips_type,get_scalar_port_dim(cell2mat(dimensions_outport(j,:)),1));
    cnt_arguments = [cnt_arguments 'output_' num2str(j) ', '];
end

fprintf(fid_cpp_file,['\n\twhile(1) {\n']);

for j=1:ports(1)
    input_type = char(data_types_inport(j,:));
    switch input_type
        case 'int64'
            chips_gettype = 'fget_long';
        case 'uint64'
            chips_gettype = 'fget_long';
        case 'double'
            chips_gettype = 'fget_double';
        case 'single'
            chips_gettype = 'fget_float';
        otherwise
            chips_gettype = 'fgetc';
    end
    fprintf(fid_cpp_file,'\t\tfor(int i = 0; i < %d; ++i) {\n',get_scalar_port_dim(cell2mat(dimensions_inport(j,:)),1));
    fprintf(fid_cpp_file,['\t\t\tinput_' num2str(j) '[i] =' chips_gettype '(inputArg' num2str(j) ');\n']);
    fprintf(fid_cpp_file,'\t\t}\n');
end

cnt_arguments = cnt_arguments(1:end-2); %delete last comma from string
fprintf(fid_cpp_file,['\n\t\t' blk_properties.name '_hw( ' cnt_arguments ' );\n\n']);

for j=1:ports(2)
    output_type = char(data_types_outport(j,:));
    switch output_type
        case 'int64'
            chips_puttype = 'fput_long';
        case 'uint64'
            chips_puttype = 'fput_long';
        case 'double'
            chips_puttype = 'fput_double';
        case 'single'
            chips_puttype = 'fput_float';
        otherwise
            chips_puttype = 'fputc';
    end
    fprintf(fid_cpp_file,'\t\tfor(int i = 0; i < %d; ++i) {\n',get_scalar_port_dim(cell2mat(dimensions_outport(j,:)),1));
    fprintf(fid_cpp_file,['\t\t\t' chips_puttype '(output_' num2str(j) '[i], outputArg' num2str(j) ');\n']);
    fprintf(fid_cpp_file,'\t\t}\n');
end
fprintf(fid_cpp_file,'\t}\n');
fprintf(fid_cpp_file,'}\n');

disp('created source file');
% close all file descriptors
fclose(fid_hpp_file);
fclose(fid_h_file);
fclose(fid_cpp_file);
fclose(fid_c_file);
end


