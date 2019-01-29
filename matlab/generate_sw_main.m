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
%  @author  Streit Franz-Josef, Martin Letras 
%  @mail    franz-josef.streit@fau.de                                                   
%  @date    04 May 2018
%  @version 0.1
%  @brief   This function performs the automatic code generation for the
%           main function that controls the SW/HW, HW/SW modules execution
%
%%

function [status] = generate_sw_main(mdl,src_edges,snk_edges,hwsw_edges,swhw_edges,islands_in_model)

% we need to know how many of these combinations of boundaries we have
%       -> These are the different types of boundaries
%       - Boundary HW/SW
%       - Boundary SW/HW

counter_src = length(src_edges); % get number of src boundaries
counter_snk = length(snk_edges); % get number of snk boundaries
counter_hwsw = length(hwsw_edges); % get number of hw->sw boundaries
counter_swhw = length(swhw_edges); % get number of sw->hw boundaries

% get name of SW model
src_folder = [mdl '_sw'];
% generate model main file with drivers for HW/SW and SW/HW communication
fileID = fopen([src_folder '/main.cc'],'w');
% writes the headers of the sw islands
load_headers(fileID,counter_hwsw,counter_swhw,islands_in_model);

% writes the addresses for DMA operations
if ((counter_hwsw > 1) || (counter_swhw >1))
    load_address(fileID);
end

fprintf(fileID,'\n');
% print defines for frame size of DMA write
for j=1:counter_swhw
    string_print = ['#define MAX_WRITE_' strrep(upper(swhw_edges{j}.blk_name),'/','_') '_' num2str(swhw_edges{j}.id) '_LEN'];
    fprintf(fileID,'%s\t %d // output size of sw boundary\n',string_print,get_scalar_port_dim(cell2mat(swhw_edges{j}.dimension),1));
    fprintf(fileID,'#define TX_BUFFER_BASE_%s_%s (MEM_BASE_ADDR + 0x00%d00000) // memory address for transmit buffer\n',strrep(upper(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id),j);
    fprintf(fileID,'#define DMA_%s_%s XPAR_READ_ADAPT_ID_%d_AXI_DMA_%d_DEVICE_ID\n\n',strrep(upper(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id),j,j);
end

% print defines for frame size of DMA read
for j=1:counter_hwsw
    string_print = ['#define MAX_READ_' strrep(upper(hwsw_edges{j}.blk_name),'/','_') '_' num2str(hwsw_edges{j}.id) '_LEN'];
    fprintf(fileID,'%s\t %d// output size of hw boundary\n',string_print,get_scalar_port_dim(cell2mat(hwsw_edges{j}.dimension),1));
    fprintf(fileID,'#define RX_BUFFER_BASE_%s_%s (MEM_BASE_ADDR + 0x00%d00000) // memory address for receive buffer\n',strrep(upper(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id),(j+4));
    fprintf(fileID,'#define DMA_%s_%s XPAR_WRITE_ADAPT_ID_%d_AXI_DMA_%d_DEVICE_ID\n\n',strrep(upper(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id),j,j);
end

print_function_prototypes(fileID);
print_variable_definitions(fileID,counter_hwsw,counter_swhw,hwsw_edges,swhw_edges);
print_main_function(fileID,counter_src,counter_snk,src_edges,snk_edges,counter_hwsw,counter_swhw,hwsw_edges,swhw_edges,islands_in_model,mdl)
fclose(fileID);

status = true;
end

function load_headers(fileID,counter_hwsw,counter_swhw,islands_in_model)
fprintf(fileID,'\n/**************************** MoDesA generated main file *******************************/\n\n');
fprintf(fileID,'#include <stdio.h>\n');
fprintf(fileID,'#include <unistd.h> // for usleep if necessary\n\n');
fprintf(fileID,'#include "xil_printf.h"\n');
fprintf(fileID,'#include "xparameters.h"\n');
fprintf(fileID,'#include "xdebug.h"\n');
fprintf(fileID,'#include "xtime_l.h" // for timing measurements with XTime if necessary\n');
if ((counter_hwsw > 1) || (counter_swhw >1))
    fprintf(fileID,'#include "xaxidma.h"\n\n');
end

if counter_swhw > 0
    fprintf(fileID,'#include "read_adapter.h"  // SW->HW driver\n');
end
if counter_hwsw > 0
    fprintf(fileID,'#include "write_adapter.h" // HW->SW driver\n');
end

for j=1:length(islands_in_model)
    fprintf(fileID,'#include <%s.hpp> // name of generated SW island\n',islands_in_model(j).name_island);
end

end

function load_address(fileID)
fprintf(fileID,'\n');
fprintf(fileID,'#ifdef XPAR_AXI_7SDDR_0_S_AXI_BASEADDR\n');
fprintf(fileID,'#define DDR_BASE_ADDR		XPAR_AXI_7SDDR_0_S_AXI_BASEADDR\n');
fprintf(fileID,'#elif XPAR_MIG7SERIES_0_BASEADDR\n');
fprintf(fileID,'#define DDR_BASE_ADDR		XPAR_MIG7SERIES_0_BASEADDR\n');
fprintf(fileID,'#elif XPAR_MIG_0_BASEADDR\n');
fprintf(fileID,'#define DDR_BASE_ADDR		XPAR_MIG_0_BASEADDR\n');
fprintf(fileID,'#elif XPAR_PSU_DDR_0_S_AXI_BASEADDR\n');
fprintf(fileID,'#define DDR_BASE_ADDR		XPAR_PSU_DDR_0_S_AXI_BASEADDR\n');
fprintf(fileID,'#endif\n');
fprintf(fileID,'\n');
fprintf(fileID,'#ifndef DDR_BASE_ADDR\n');
fprintf(fileID,'#warning CHECK FOR THE VALID DDR ADDRESS IN XPARAMETERS.H, DEFAULT SET TO 0x00100000\n');
fprintf(fileID,'#define MEM_BASE_ADDR		0x00100000\n');
fprintf(fileID,'#else\n');
fprintf(fileID,'#define MEM_BASE_ADDR		(DDR_BASE_ADDR + 0x1000000)\n');
fprintf(fileID,'#endif\n\n');
end

function print_function_prototypes(fileID)
fprintf(fileID,'\n/**************************** Type Definitions *******************************/\n\n');
fprintf(fileID,'/***************** Macros (Inline Functions) Definitions *********************/\n\n');
fprintf(fileID,'/************************** Function Prototypes ******************************/\n\n');
fprintf(fileID,'#if (!defined(DEBUG))\n');
fprintf(fileID,'extern void xil_printf(const char *format, ...);\n');
fprintf(fileID,'#endif\n\n');
end


function print_variable_definitions(fileID,counter_hwsw,counter_swhw,hwsw_edges,swhw_edges)
fprintf(fileID,'/************************** Variable Definitions *****************************\n');
fprintf(fileID,'*\n');
fprintf(fileID,'* Device instance definitions\n');
fprintf(fileID,'*\n');
fprintf(fileID,'*****************************************************************************/\n\n');

for j=1:counter_hwsw
    fprintf(fileID,'write_adapter *my_write_%s_%s_adapter;\n',strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id));
    fprintf(fileID,'XAxiDma AxiDma_%s_%s;\n\n',strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id));
end

for j=1:counter_swhw
    fprintf(fileID,'read_adapter *my_read_%s_%s_adapter;\n',strrep(lower(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id));
    fprintf(fileID,'XAxiDma AxiDma_%s_%s;\n\n',strrep(lower(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id));
end

% Then we print out the comments
fprintf(fileID,'/*****************************************************************************\n');
fprintf(fileID,'*\n');
fprintf(fileID,'* The entry point of the driver management. The driver writes and reads data to/from HW,\n');
fprintf(fileID,'* and reports the execution status.\n');
fprintf(fileID,'*\n');
fprintf(fileID,'* @param	None.\n');
fprintf(fileID,'*\n');
fprintf(fileID,'* @param	None.\n');
fprintf(fileID,'* * @return\n');
fprintf(fileID,'*		- XST_SUCCESS if execution finishes successfully\n');
fprintf(fileID,'*		- XST_FAILURE if execution fails.\n');
fprintf(fileID,'*\n');
fprintf(fileID,'* @note		None.\n');
fprintf(fileID,'*\n');
fprintf(fileID,'*****************************************************************************/\n\n');

end

function print_main_function(fileID,counter_src,counter_snk,src_edges,snk_edges,counter_hwsw,counter_swhw,hwsw_edges,swhw_edges,islands_in_model,mdl)

fprintf(fileID,'int main() {\n\n');
fprintf(fileID,'\tint Status;\n\n');

for j=1:counter_src
    % replace the internal used floating-point types with the coder generated types
    src_edges{j}.data_type = strrep(src_edges{j}.data_type,'double','real64');
    src_edges{j}.data_type = strrep(src_edges{j}.data_type,'single','real32');
    fprintf(fileID,'\t%s_T input_%s_%s[%d];\n',src_edges{j}.data_type,strrep(lower(src_edges{j}.blk_name),'/','_'),num2str(src_edges{j}.id),get_scalar_port_dim(cell2mat(src_edges{j}.dimension),1));
end

for j=1:counter_snk
    % replace the internal used floating-point types with the coder generated types
    snk_edges{j}.data_type = strrep(snk_edges{j}.data_type,'double','real64');
    snk_edges{j}.data_type = strrep(snk_edges{j}.data_type,'single','real32');
    fprintf(fileID,'\t%s_T output_%s_%s[%d];\n',snk_edges{j}.data_type,strrep(lower(snk_edges{j}.blk_name),'/','_'),num2str(snk_edges{j}.id),get_scalar_port_dim(cell2mat(snk_edges{j}.dimension),1));
end

for j=1:counter_hwsw
    % replace the internal used floating-point types with the coder generated types
    hwsw_edges{j}.data_type = strrep(hwsw_edges{j}.data_type,'double','real64');
    hwsw_edges{j}.data_type = strrep(hwsw_edges{j}.data_type,'single','real32');
    fprintf(fileID,'\t%s_T *RxBuffer_%s_%s_Ptr;\n',hwsw_edges{j}.data_type,strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id));
    fprintf(fileID,'\tRxBuffer_%s_%s_Ptr = (%s_T *) RX_BUFFER_BASE_%s_%s;\n',strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id),hwsw_edges{j}.data_type,strrep(upper(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id));
end

for j=1:counter_swhw
    % replace the internal used floating-point types with the coder generated types
    swhw_edges{j}.data_type = strrep(swhw_edges{j}.data_type,'double','real64');
    swhw_edges{j}.data_type = strrep(swhw_edges{j}.data_type,'single','real32');
    fprintf(fileID,'\t%s_T *TxBuffer_%s_%s_Ptr;\n',swhw_edges{j}.data_type,strrep(lower(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id));
    fprintf(fileID,'\tTxBuffer_%s_%s_Ptr = (%s_T *) TX_BUFFER_BASE_%s_%s;\n',strrep(lower(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id),swhw_edges{j}.data_type,strrep(upper(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id));
end

fprintf(fileID,'\n');
fprintf(fileID,'\txil_printf("\\r\\n--- Program starts --- \\r\\n");\n');
fprintf(fileID,'\n');

for j=1:counter_swhw
    fprintf(fileID,'\treg_ctrl_read_adapt %s_%s_reg_ctrl = reg_nen_read_adapt; //default setting for read adapter\n',strrep(lower(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id));
    fprintf(fileID,'\tmy_read_%s_%s_adapter = init_read_adapter(XPAR_READ_ADAPT_ID_%d_READ_ADAPTER_%d_S00_AXI_BASEADDR);\n\n',strrep(lower(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id),j,j);
end

for j=1:counter_hwsw
    fprintf(fileID,'\treg_ctrl_write_adapt %s_%s_reg_ctrl = reg_nen_write_adapt; //default setting for write adapter\n',strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id));
    fprintf(fileID,'\tmy_write_%s_%s_adapter = init_write_adapter(XPAR_WRITE_ADAPT_ID_%d_WRITE_ADAPTER_%d_S00_AXI_BASEADDR);\n\n',strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id),j,j);
end

for j=1:counter_hwsw
    fprintf(fileID,'\tStatus = set_reg_write_adapt(my_write_%s_%s_adapter, &AxiDma_%s_%s, DMA_%s_%s, %s_%s_reg_ctrl);\n',strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id), strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id), strrep(upper(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id), strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id));
    fprintf(fileID,'\tif (Status != XST_SUCCESS) {\n');
    fprintf(fileID,'\t\txil_printf("Setup write adapter: Failed\\r\\n");\n');
    fprintf(fileID,'\t\treturn XST_FAILURE;\n');
    fprintf(fileID,'\t}\n');
    fprintf(fileID,'\tset_pkg_lng(my_write_%s_%s_adapter, MAX_READ_%s_%s_LEN);\n',strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id), strrep(upper(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id));
end

for j=1:counter_swhw
    fprintf(fileID,'\tStatus = set_reg_read_adapt(my_read_%s_%s_adapter, &AxiDma_%s_%s, DMA_%s_%s, %s_%s_reg_ctrl);\n',strrep(lower(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id), strrep(lower(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id), strrep(upper(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id), strrep(lower(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id));
    fprintf(fileID,'\tif (Status != XST_SUCCESS) {\n');
    fprintf(fileID,'\t\txil_printf("Setup read adapter: Failed\\r\\n");\n');
    fprintf(fileID,'\t\treturn XST_FAILURE;\n');
    fprintf(fileID,'\t}\n');
end


fprintf(fileID,'\n');

for j=1:counter_swhw
    fprintf(fileID,'\n\t/* Disable interrupts, on AxiDma_%s_%s, we use polling mode */\n',strrep(lower(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id));
    fprintf(fileID,'\tXAxiDma_IntrDisable(&AxiDma_%s_%s, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);\n',strrep(lower(swhw_edges{j}.blk_name),'/','_'),num2str(swhw_edges{j}.id));
end

for j=1:counter_hwsw
    fprintf(fileID,'\n\t/* Disable interrupts, on AxiDma_%s_%s, we use polling mode */\n',strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id));
    fprintf(fileID,'\tXAxiDma_IntrDisable(&AxiDma_%s_%s, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);\n',strrep(lower(hwsw_edges{j}.blk_name),'/','_'),num2str(hwsw_edges{j}.id));
end

fprintf(fileID,'\n');
fprintf(fileID,'\n');

% here we write the communication between the islands
print_CLUSTER_INFO(fileID,counter_src,counter_snk,src_edges,snk_edges,islands_in_model,counter_swhw,counter_hwsw,hwsw_edges,swhw_edges,mdl);

fprintf(fileID,'\n');
fprintf(fileID,'\txil_printf("--- Exiting main() --- \\r\\n");\n');
fprintf(fileID,'\treturn XST_SUCCESS;\n');
fprintf(fileID,'\n');
fprintf(fileID,'}');

end

function print_CLUSTER_INFO(fileID,counter_src,counter_snk,src_edges,snk_edges,islands_in_model,counter_swhw,counter_hwsw,hwsw_edges,swhw_edges,mdl)

counter_island = length(islands_in_model);

% print the islands init function recursively
for j=1:counter_island
    fprintf(fileID,'\t/* %s island initialization */\n',islands_in_model(j).name_island);
    fprintf(fileID,'\t%s_init();\n\n',islands_in_model(j).name_island);
end

% print the islands step function recursively
for i=1:counter_island
    
    % get the islands function arguments
    [srcsw_inputs,hwsw_inputs,swhw_outputs,swsnk_outputs] = get_island_arguments(mdl,islands_in_model(i),counter_src,counter_hwsw,counter_swhw,counter_snk,src_edges,hwsw_edges,swhw_edges,snk_edges);
    
    % get number of blocks in island
    counter_blocks_in_island = length(islands_in_model(i).blocks);
    
    % print here step function if we have at least one input on the edge but no
    % outputs
    if (~isempty(srcsw_inputs) || ~isempty(swhw_outputs)) && (isempty(hwsw_inputs) && isempty(swsnk_outputs))
        if~isempty(swhw_outputs)
            swhw_outputs = swhw_outputs(1:end-1); %delete last comma from string
        else
            srcsw_inputs = srcsw_inputs(1:end-1); %delete last comma from string
        end
        
        fprintf(fileID,'\t/* %s island execution */\n',islands_in_model(i).name_island);
        fprintf(fileID,'\t%s_step(%s);\n\n',islands_in_model(i).name_island,[srcsw_inputs swhw_outputs]);
    end
    
    for j=1:counter_blocks_in_island
        % print adatper for hwsw edge
        for k=1:counter_hwsw
            if strcmp(islands_in_model(i).blocks{j},[mdl '_sw/' hwsw_edges{k}.blk_name])
                fprintf(fileID,'\tif (%s_%s_reg_ctrl == reg_en_write_adapt) {\n',strrep(lower(hwsw_edges{k}.blk_name),'/','_'),num2str(hwsw_edges{k}.id));
                fprintf(fileID,'\t\tStatus = pop_data(my_write_%s_%s_adapter, &AxiDma_%s_%s, RxBuffer_%s_%s_Ptr, pop_32_bit);\n', ...
                    strrep(lower(hwsw_edges{k}.blk_name),'/','_'),num2str(hwsw_edges{k}.id), strrep(lower(hwsw_edges{k}.blk_name),'/','_'),num2str(hwsw_edges{k}.id), strrep(lower(hwsw_edges{k}.blk_name),'/','_'),num2str(hwsw_edges{k}.id));
                fprintf(fileID,'\t\tif (Status != XST_SUCCESS) {\n');
                fprintf(fileID,'\t\t\txil_printf("Setup read from HW: Failed\\r\\n");\n');
                fprintf(fileID,'\t\t\treturn XST_FAILURE;\n');
                fprintf(fileID,'\t\t}\n');
                fprintf(fileID,'\t} else {\n');
                fprintf(fileID,'\t\tStatus = pop_data(my_write_%s_%s_adapter, &AxiDma_%s_%s, RxBuffer_%s_%s_Ptr, pop_32_bit);\n', ...
                    strrep(lower(hwsw_edges{k}.blk_name),'/','_'),num2str(hwsw_edges{k}.id), strrep(lower(hwsw_edges{k}.blk_name),'/','_'),num2str(hwsw_edges{k}.id), strrep(lower(hwsw_edges{k}.blk_name),'/','_'),num2str(hwsw_edges{k}.id));
                fprintf(fileID,'\t\tif (Status != XST_SUCCESS) {\n');
                fprintf(fileID,'\t\t\txil_printf("Setup read from HW: Failed\\r\\n");\n');
                fprintf(fileID,'\t\t\treturn XST_FAILURE;\n');
                fprintf(fileID,'\t\t}\n');
                fprintf(fileID,'\t}\n\n');
            end
        end
    end
    
    % print here step function if we have an island with a hwsw_edge and swhw_edge
    if isempty(srcsw_inputs) && (~isempty(swhw_outputs) && ~isempty(hwsw_inputs)) && isempty(swsnk_outputs)
        swhw_outputs = swhw_outputs(1:end-1); %delete last comma from string
        
        fprintf(fileID,'\t/* %s island execution */\n',islands_in_model(i).name_island);
        fprintf(fileID,'\t%s_step(%s);\n\n',islands_in_model(i).name_island,[hwsw_inputs swhw_outputs]);
    end
    
    for j=1:counter_blocks_in_island
        % print adatper for swhw edge
        for k=1:counter_swhw
            if strcmp(islands_in_model(i).blocks{j},[mdl '_sw/'  swhw_edges{k}.blk_name])
                fprintf(fileID,'\tif (%s_%s_reg_ctrl == reg_en_read_adapt) {\n',strrep(lower(swhw_edges{k}.blk_name),'/','_'),num2str(swhw_edges{k}.id));
                fprintf(fileID,'\t\tStatus = push_data(my_read_%s_%s_adapter, &AxiDma_%s_%s, TxBuffer_%s_%s_Ptr, 1, push_32_bit);\n', ...
                    strrep(lower(swhw_edges{k}.blk_name),'/','_'),num2str(swhw_edges{k}.id), strrep(lower(swhw_edges{k}.blk_name),'/','_'),num2str(swhw_edges{k}.id), strrep(lower(swhw_edges{k}.blk_name),'/','_'),num2str(swhw_edges{k}.id));
                fprintf(fileID,'\t\tif (Status != XST_SUCCESS) {\n');
                fprintf(fileID,'\t\t\txil_printf("Setup write to HW: Failed\\r\\n");\n');
                fprintf(fileID,'\t\t\treturn XST_FAILURE;\n');
                fprintf(fileID,'\t\t}\n');
                fprintf(fileID,'\t} else {\n');
                fprintf(fileID,'\t\tStatus = push_data(my_read_%s_%s_adapter, &AxiDma_%s_%s, TxBuffer_%s_%s_Ptr, MAX_WRITE_%s_%s_LEN, push_32_bit);\n', ...
                    strrep(lower(swhw_edges{k}.blk_name),'/','_'),num2str(swhw_edges{k}.id), strrep(lower(swhw_edges{k}.blk_name),'/','_'),num2str(swhw_edges{k}.id), strrep(lower(swhw_edges{k}.blk_name),'/','_'),num2str(swhw_edges{k}.id), strrep(upper(swhw_edges{k}.blk_name),'/','_'),num2str(swhw_edges{k}.id));
                fprintf(fileID,'\t\tif (Status != XST_SUCCESS) {\n');
                fprintf(fileID,'\t\t\txil_printf("Setup write to HW: Failed\\r\\n");\n');
                fprintf(fileID,'\t\t\treturn XST_FAILURE;\n');
                fprintf(fileID,'\t\t}\n');
                fprintf(fileID,'\t}\n\n');
            end
        end
    end
    
    % print here step function if we at least one output on the edge
    if (~isempty(swsnk_outputs) || ~isempty(hwsw_inputs)) && isempty(swhw_outputs)
        if ~isempty(swsnk_outputs)
            swsnk_outputs = swsnk_outputs(1:end-1); %delete last comma from string
        elseif ~isempty(swhw_outputs)
            swhw_outputs = swhw_outputs(1:end-1); %delete last comma from string
        elseif ~isempty(hwsw_inputs)
            hwsw_inputs = hwsw_inputs(1:end-1); %delete last comma from string
        else
            srcsw_inputs = srcsw_inputs(1:end-1); %delete last comma from string
        end
        
        fprintf(fileID,'\t/* %s island execution */\n',islands_in_model(i).name_island);
        fprintf(fileID,'\t%s_step(%s);\n\n',islands_in_model(i).name_island,[srcsw_inputs hwsw_inputs swhw_outputs swsnk_outputs]);
    end
end

% print the islands terminate function recursively
for j=1:counter_island
    fprintf(fileID,'\n\t/* %s island termination */\n',islands_in_model(j).name_island);
    fprintf(fileID,'\t%s_terminate();\n\n',islands_in_model(j).name_island);
end
end

% extract islands function arguments
function [srcsw_inputs,hwsw_inputs,swhw_outputs,swsnk_outputs] = get_island_arguments(mdl,island,counter_src,counter_hwsw,counter_swhw,counter_snk,src_edges,hwsw_edges,swhw_edges,snk_edges)

srcsw_inputs = ''; % in this variable we store all inport arguments
hwsw_inputs = ''; % in this variable we store all inport arguments
swhw_outputs = ''; % in this variable we store all outport arguments
swsnk_outputs = ''; % in this variable we store all outport arguments

counter_blocks_in_island = length(island.blocks);

for j=1:counter_blocks_in_island
    for k=1:counter_src
        if strcmp(island.blocks{j},[mdl '_sw/' src_edges{k}.blk_name])
            srcsw_inputs = [srcsw_inputs 'input_' strrep(lower(src_edges{k}.blk_name),'/','_') '_' num2str(src_edges{k}.id) ','];
        end
    end
    
    for k=1:counter_hwsw
        if strcmp(island.blocks{j},[mdl '_sw/' hwsw_edges{k}.blk_name])
            hwsw_inputs = [hwsw_inputs 'RxBuffer_' strrep(lower(hwsw_edges{k}.blk_name),'/','_') '_' num2str(hwsw_edges{k}.id) '_Ptr,'];
        end
    end
    
    for k=1:counter_swhw
        if strcmp(island.blocks{j},[mdl '_sw/'  swhw_edges{k}.blk_name])
            swhw_outputs = [swhw_outputs 'TxBuffer_' strrep(lower(swhw_edges{k}.blk_name),'/','_') '_' num2str(swhw_edges{k}.id) '_Ptr,'];
        end
    end
    
    for k=1:counter_snk
        if strcmp(island.blocks{j},[mdl '_sw/' snk_edges{k}.blk_name])
            swsnk_outputs = [swsnk_outputs 'output_' strrep(lower(snk_edges{k}.blk_name),'/','_') '_' num2str(snk_edges{k}.id) ','];
        end
    end
end
end
