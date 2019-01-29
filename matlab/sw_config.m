%%
% --------------------------------------------------------------------------  
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
%  @brief here you can define your SW codegeneration parameters
%
%% 

function sw_config(model_name)
    cs = getActiveConfigSet(model_name);    
    switchTarget(cs,'ert.tlc',[]);
    % Hardware Implementation
    set_param(cs,'ProdHWDeviceType', 'ARM Compatible->ARM 9');   % Production device vendor and type 
    set_param(cs,'MaxIdLength',200);
    set_param(cs,'Solver','FixedStepDiscrete');
    set_param(cs,'ERTFilePackagingFormat','Compact');
    set_param(cs,'LaunchReport','off');
    set_param(cs,'ERTDataHdrFileTemplate','template.cgt');
    set_param(cs,'ERTDataSrcFileTemplate','template.cgt');
    set_param(cs,'ERTHdrFileBannerTemplate','template.cgt');
    set_param(cs,'ERTSrcFileBannerTemplate','template.cgt');
    set_param(cs,'ERTFilePackagingFormat','Compact');
    set_param(cs,'GenCodeOnly','on');
    set_param(cs,'MatFileLogging','off');
    set_param(cs,'SupportVariableSizeSignals','on'); % some matlab and s-function blocks require on
    set_param(cs,'TargetLang','C');
    set_param(cs,'SupportNonFinite','on');
    set_param(cs,'SupportAbsoluteTime','off');
    set_param(cs,'SupportModelReferenceSimTargetCustomCode','off');
    set_param(cs,'SupportContinuousTime','off');
    set_param(cs,'DefaultUnderspecifiedDataType','single'); % a lot of matlab functions require double if you not specify it explicitly code generation failes when this parameter is set to *single'
    set_param(cs,'EnableMemcpy','on');
    set_param(cs,'MATLABDynamicMemAlloc','on'); % Dynamic memory allocation in MATLAB Function blocks
    set_param(cs,'SuppressErrorStatus', 'on'); %Omits the error status field from the generated real-time model data structure rtModel. This option reduces memory usage.
    set_param(cs,'SaveFormat', 'Structure'); %Format used to save data to the MATLAB workspace
    save_system(model_name);
    rtwbuild(model_name);
end
