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
%  @brief   Function that verifies the name of variables, forms a complete 
%           list of c++ keywords
%
%
%% 

function [ right_name] = check_reserved_word(name)
    % list of keywords
    keywords =  { 'alignas';'alignof';'and';'and_eq';'asm';'auto';'bitand';'bitor';'bool';'break';'case';'catch';'char';'char16_t';'char32_t';'class';'compl';'const';'constexpr';'const_cast';'continue';'decltype';
            'default';'delete';'do';'double';'dynamic_cast';'else';'enum';'explicit';'export';'extern';'false';'float';'for';'friend';'goto';'if';'inline';'int';'long';'mutable';'namespace';'new';'noexcept';'not';
            'not_eq';'nullptr';'operator';'or';'or_eq';'private';'protected';'public';'register';'reinterpret_cast';'return';'short';'signed';'sizeof';'static';'static_assert';'static_cast';'struct';'switch';'template';
            'this';'thread_local';'throw';'true';'try';'typedef';'typeid';'typename';'union';'unsigned';'using';'virtual';'void';'volatile';'wchar_t';'while';'xor';'xor_eq' }; 

    str = find(strcmp(keywords,name));
    if(length(str)>0)
        right_name = ['_' name];
    else
        right_name = name;
    end
end
