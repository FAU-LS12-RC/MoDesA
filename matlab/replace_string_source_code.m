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
%  @brief   This function is an alternative to the sed function from Linux
%
%
%%

function replace_string_source_code(folder,old_string,new_string)
    files = dir(folder);
    
    source_files = struct(files);
    for i=1:length(files)
        if files(i).isdir == 0 && ( contains(files(i).name,'.cpp') || contains(files(i).name,'.hpp') ...
                || contains(files(i).name,'.c') || contains(files(i).name,'.h'))
            source_files(i) = files(i);
            
                copyfile([files(i).folder '/' files(i).name],[files(i).folder '/' 'temp_file']);
                delete([files(i).folder '/' files(i).name]);
                
                old_file                        = fopen([files(i).folder '/' 'temp_file']);
                new_file                        = fopen([files(i).folder '/' files(i).name],'w');
                
                while ~feof(old_file)
                    tline = fgets(old_file);
                    tline = strrep( tline, '%', '%%' ); % change % to %% for right interpretation in fprintf
                    if contains(tline,old_string)
                        tline = strrep(tline,old_string,new_string);
                    end
                    fprintf(new_file,tline);
                end
                fclose(old_file);
                fclose(new_file);
                delete([files(i).folder '/' 'temp_file']);
        end
    end
end
