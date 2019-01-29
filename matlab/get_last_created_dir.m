%%
% -------------------------------------------------------------------------  
%    Copyright (c) 2017 Hardware-Software-Co-Design, Friedrich-
%    Alexander-Universitaet Erlangen-Nuernberg (FAU), Germany.
%    All rights reserved.
% 
%    Licensed under the Apache License, Version 2.0 (the "License");
%    you may not use this file except in compliance with the License.
%    You may obtain a copy of the License at
% 
%        http://www.apache.org/licenses/LICENSE-2.0
% 
%    Unless required by applicable law or agreed to in writing, software
%    distributed under the License is distributed on an "AS IS" BASIS,
%    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%    See the License for the specific language governing permissions and
%    limitations under the License.
%  -------------------------------------------------------------------------  
% 
%  @author  Martin Letras, Streit Franz-Josef
%  @mail    franz-josef.streit@fau.de                                                   
%  @date    09 November 2017
%  @version 0.1
%  @brief   If you are using MATLAB 2017 use this function because the 
%           structure obtained by dir is formed by the next fields:
%           name, folder, date, bytes, isdir, date_num
%
%%

function [folder] = get_last_created_dir()
    d=dir(pwd);
    folders = struct('name',{},'folder',{},'date',{},'bytes',{},'isdir',{},'datenum',{});
    for i=1:length(d)
        if d(i).isdir == 1 && ~strcmp(d(i).name,'.') && ~strcmp(d(i).name,'..')
            folders(end+1) = d(i);
        end
    end
    dates = [folders.datenum];
    [~,newestIndex]  = max(dates);
    folder = folders(newestIndex).name;
end
