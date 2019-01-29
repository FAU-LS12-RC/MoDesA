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
%  @date    19 November 2017
%  @version 0.1
%  @brief   Deletes unconnected lines from a Simulink model.
%           This function deletes all lines which has either no 
%           source or no destination in a model. That is, lines that are not 
%           fully connected to two blocks are removed (red-dotted in the GUI).
%
%%

function delete_unconnected_lines(model)
% get handles to all lines in system
lines = find_system(model, ...
    'LookUnderMasks', 'all', ...
    'FindAll', 'on', ...
    'Type', 'line' ) ;

% for each line, call delete_recursive if handle still exist
for i=1:length(lines)
    if ishandle(lines(i))
        delete_recursive(lines(i))
    end
end
end
