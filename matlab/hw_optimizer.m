% 
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
%  @brief   Here you can define your build model parameters, for HW IP-Block
%           generation. Changing this parameters has influence on code generation
%           synthesis.
%
%% 

function hw_optimizer(model_name)
   cs = getActiveConfigSet(model_name);    
   switchTarget(cs,'ert.tlc',[]);
   % Hardware Implementation
   set_param(cs,'ProdHWDeviceType', 'Custom Processor->Custom');   % Production device vendor and type
   set_param(cs,'ProdBitPerChar', 8);   % Bits per char in production hardware
   set_param(cs,'ProdBitPerShort', 16);   % Bits per short in production hardware
   set_param(cs,'ProdBitPerInt', 32);   % Bits per int in production hardware
   set_param(cs,'ProdBitPerLong', 64);   % Bits per long in production hardware  
   set_param(cs,'ProdBitPerLongLong', 64); % Bits per long long in production hardware
   set_param(cs,'ProdEndianess', 'LittleEndian'); %Describe the byte ordering for the hardware board
   set_param(cs,'ProdIntDivRoundTo', 'Zero'); %Describe hardware rounds of dividing two signed integers.
   set_param(cs,'ProdShiftRightIntArith', 'on'); %Describe sign bit in a right shift of a signed integer.
   set_param(cs,'ProdLongLongMode', 'on'); % Specify that your C compiler supports the C long long data type.
   set_param(cs,'ProdWordSize', 64); % Describe native word size for the hardware
   set_param(cs,'PortableWordSizes', 'off'); % Enable portable word sizes
   set_param(cs,'EnableSignedLeftShifts', 'on');   % Replace multiplications by powers of two with signed bitwise shifts
   set_param(cs,'EnableSignedRightShifts', 'on');   % Allow right shifts on signed integers
   set_param(cs,'EfficientFloat2IntCast', 'on');   % Remove code from floating-point to integer conversions that wraps out-of-range values
   set_param(cs,'NoFixptDivByZeroProtection', 'on'); %Specify whether to generate code that guards against division by zero 
   set_param(cs,'ProdEqTarget', 'on');   % Test hardware is the same as production hardware
   
   set_param(cs,'CodeReplacementLibrary', 'MoDesA replacement lib');% use MoDesA code replacement library
   set_param(cs,'MaxIdLength',200);
   set_param(cs,'Solver','FixedStepDiscrete');
   set_param(cs,'LaunchReport','off');
   set_param(cs,'ERTDataHdrFileTemplate','template.cgt');
   set_param(cs,'ERTDataSrcFileTemplate','template.cgt');
   set_param(cs,'ERTHdrFileBannerTemplate','template.cgt');
   set_param(cs,'ERTSrcFileBannerTemplate','template.cgt');
   set_param(cs,'ERTFilePackagingFormat','Compact');
   set_param(cs,'GenCodeOnly','on');
   set_param(cs,'MatFileLogging','off');
   set_param(cs,'SupportVariableSizeSignals','on'); % matlab and s-function blocks sometimes requires on
   set_param(cs,'TargetLang','C');
   set_param(cs,'SupportNonFinite','on'); % 'on' generates non-finite data (for example, NaN and Inf) and related operations
   set_param(cs,'SupportAbsoluteTime','off');
   set_param(cs,'SupportModelReferenceSimTargetCustomCode','off');
   set_param(cs,'SupportContinuousTime','off');
   set_param(cs,'DefaultUnderspecifiedDataType','single');
   set_param(cs,'DefaultParameterBehavior','Inlined'); % transform numeric block parameters into constant inlined values in the generated code.
   set_param(cs,'EnableMemcpy','on');
   set_param(cs,'MemcpyThreshold','2147483647'); % highest possible value avoids also memcpy for int values
   set_param(cs,'InitFltsAndDblsToZero','off');
   set_param(cs,'ZeroInternalMemoryAtStartup', 'on'); %initializes internal data to zero important to break algebraic loops
   set_param(cs,'ZeroExternalMemoryAtStartup', 'off'); %
   set_param(cs,'SuppressErrorStatus', 'on'); % omits the error status field from the generated real-time model data structure rtModel. This option reduces memory usage.
   set_param(cs,'GlobalDataDefinition','InSourceFile'); % specify where to place definitions of global variables.
   set_param(cs,'GlobalDataReference','InSourceFile'); % specify where extern, typedef, and #define statements are to be declared.
   set_param(cs,'MaxStackSize','inf'); %If you specify the maximum stack to be inf, then the generated code contains the least number of global variables.
   set_param(cs,'GlobalVariableUsage','Minimize global data access'); % Minimize use of global variables by using local variables to hold intermediate values.
   set_param(cs,'GlobalBufferReuse','off');
   set_param(cs,'OptimizeBlockIOStorage','on'); %'on' Simulink software reuses memory buffers allocated to store block input and output signals, reducing the memory requirements. 
   set_param(cs,'LocalBlockOutputs','on'); %Specify whether block signals are declared locally or globally
   set_param(cs,'BufferReuse','off'); %Specify whether Simulink® Coder™ software reuses signal memory.
   set_param(cs,'OptimizeDataStoreBuffers','off');
   set_param(cs,'ExpressionFolding','on'); % enables block computations into single expressions wherever possible.
   set_param(cs,'StrengthReduction','on'); % replace multiply operations in the array index with a temporary variable
   set_param(cs,'SimCompilerOptimization','off'); % sets the degree of optimization used by the compiler when generating code for acceleration.
   set_param(cs,'OptimizeBlockOrder','off'); % reorder block operations in the generated code for improved code execution 'speed'.
   set_param(cs,'RollThreshold', '10');   % loop unrolling threshold
   set_param(cs,'CompileTimeRecursionLimit', '100'); % prevent run-time recursion
   set_param(cs,'EnableRuntimeRecursion','off'); % Disables run-time recursion for code generation. If run-time recursion is disabled, and the MATLAB code requires run-time recursion, code generation fails.
   set_param(cs,'RTWCompilerOptimization', 'off'); % on (faster runs) and off (faster builds)
   save_system(model_name);
   rtwbuild(model_name);
  end
