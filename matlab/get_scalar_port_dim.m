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
%  @author Streit Franz-Josef
%  @mail    franz-josef.streit@fau.de                                                   
%  @date   23 August 2018
%  @version 0.1
%  @brief returns the scalar dimension of a port at a specific port number
%
%%

function dim = get_scalar_port_dim(dimensions, port_nr)

dim = 1;
for i=1:port_nr
        if i>1
            port_dim=dimensions(end_port+1);
            start_port = end_port+2;
            end_port =start_port+port_dim-1;
        else 
            port_dim=dimensions(1);
            start_port = 2;
            end_port =port_dim+1;
        end
        % debug code
        %display(port_dim);
        %display(start_port);
        %display(end_port)
end


for k=start_port:end_port
    dim = dim * dimensions(k);
end
end

