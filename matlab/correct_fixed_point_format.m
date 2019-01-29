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
%  @brief   Function that corrects the data format of FIXED POINT ports
%  @param   input = the fixed point format string in the form of e.g., ufix16_En8
%  @param   output is the corrected string in the format fixdt(0,16,8)
%
%  example: correct_fixed_point_format('ufix16_En8')
%
%
%%
 
function [output] = correct_fixed_point_format(input)
    is_signed = 0;
    n_bits = 0;
    n_frac = 0;
    
    if length(strfind(input,'sfix')) == 1
        is_signed = 1;
    end
    
    C = strsplit(input,'_');
    p_ent = lower(C{1});
    
    if length(C)>1
        p_frac = strrep(lower(C{2}),'en','');
        p_frac = strrep(p_frac,'e','');
        p_frac = strrep(p_frac,'E','');
        n_frac = num2str(p_frac);
    end
    
    if is_signed == 1
        newStr = strrep(p_ent,'sfix','');
    else
        newStr = strrep(p_ent,'ufix','');
    end
    
    n_bits = num2str(newStr);
    
    if length(C)>1
        output = ['fixdt(' num2str(is_signed) ',' num2str(n_bits) ',' num2str(n_frac) ')'];
    else
        output = ['fixdt(' num2str(is_signed) ',' num2str(n_bits) ', 0)'];
    end
    
end
