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
%  @date    09 December 2018
%  @version 0.1
%  @brief   This function specifies that the library appears
%            in the Library Browser and is cached in the browser repository
%
%%

function blkStruct = slblocks

  % 'MoDesA_lib' is the name of the library
  Browser.Library   = 'MoDesA_lib';
  Browser.Name      = 'Custom Lib for MoDesA code generator';
  blkStruct.Browser = Browser;
end
