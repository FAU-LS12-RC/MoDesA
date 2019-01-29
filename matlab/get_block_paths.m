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
%  @date    09 November 2017
%  @version 0.1
%  @brief   Function which returns the path of blocks on the first level, 
%           within the current model in the order they appear from left to right
%
%%

function srt_block_paths = get_block_paths(model)
    
  blocks = find_system(model,'SearchDepth',1,'Type','Block');
  pos = get_param(blocks,'Position');
  nLeftPos = cellfun(@(c)c(1),pos);
  [~,nOrderIdx] = sort(nLeftPos);
  % reorder the blocks based on new index
  srt_block_paths = blocks(nOrderIdx);
end
