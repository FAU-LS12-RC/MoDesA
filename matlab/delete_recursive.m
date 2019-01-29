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
%  @brief   This function deletes lines if:
%           1) they do not have any source-block
%           2) they do not have any line-children AND no destination-block
%           then we go recursively through all eventual line-children
%
%%

function delete_recursive(line)

if get(line,'SrcPortHandle') < 0
    delete_line( line ) ;
    return
end
LineChildren = get(line,'LineChildren');
if isempty(LineChildren)
    if get(line, 'DstPortHandle') < 0
        delete_line(line) ;
    end
else
    for i=1:length(LineChildren)
        delete_recursive(LineChildren(i))
    end
end
end
