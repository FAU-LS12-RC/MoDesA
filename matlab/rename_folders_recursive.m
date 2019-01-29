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
%  @brief   Function that performs the renaming of the folders
%
%
%%

function rename_folders_recursive(folder_base)
    folders = dir(folder_base);
    
    
    for i=1:length(folders)
        if  (~strcmp(folders(i).name,'.') && ~strcmp(folders(i).name,'..')) && folders(i).isdir == 1
             cpp_file = getcpp_name([folders(i).folder '/' folders(i).name]);
             if ~isempty(cpp_file)
                 % find the /
                 movefile([folders(i).folder '/' folders(i).name],[folders(i).folder '/' cpp_file]);
             end
        end
    end
end


function cpp_file = getcpp_name(folder_base)
   folders = dir(folder_base);
   cpp_file = ''; 
   for i=1:length(folders)
        if  contains(folders(i).name,'.cpp')
             cpp_file = strrep(folders(i).name,'.cpp','');
             break;
        end
    end
end

