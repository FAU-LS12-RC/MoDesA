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
%  @brief   class which handels edges between different domains
%
%%

classdef domain_channel
    
    properties
        model_name
        blk_name
        port_nr
        id
        dimension
        data_type
        complex
        var_size
    end

    methods
        function obj = domain_channel(model_name,blk_name,port_nr,id,dimension,data_type,complex,var_size)
            obj.model_name         = model_name;
            obj.blk_name           = blk_name;
            obj.port_nr            = port_nr;
            obj.id                 = id;
            obj.dimension          = dimension;
            obj.data_type          = data_type;
            obj.complex            = complex;
            obj.var_size           = var_size;
        end
    end
end
