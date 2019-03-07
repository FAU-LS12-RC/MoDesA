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
%  @brief   This functions returns the byte size of a given matlab data type
%           See: https://www.mathworks.com/help/matlab/numeric-types.html
%
%%

function [bytes] = get_port_byte_size(data_type)
    %Remove leading and trailing whitespace from string
    data_type = strtrim(data_type);
    switch data_type
        case 'double'
            bytes = 8;
        case 'int64'
            bytes = 8;
        case 'uint64'
            bytes = 8;
        case 'single'
            bytes = 4;
        case 'int32'
            bytes = 4;
        case 'uint32'
            bytes = 4;
        case 'int16'
            bytes = 2;
        case 'uint16'
            bytes = 2;
        otherwise
            bytes = 1;
    end
end
