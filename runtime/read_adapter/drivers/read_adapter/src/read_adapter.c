/*
* --------------------------------------------------------------------------     
* Copyright (c) 2017 Hardware-Software-Co-Design, Friedrich-                     
* Alexander-Universitaet Erlangen-Nuernberg (FAU), Germany.                      
* All rights reserved.                                                           
*                                                                                
*                                                                                
* This code and any associated documentation is provided "as is"                 
*                                                                                
* IN NO EVENT SHALL HARDWARE-SOFTWARE-CO-DESIGN, FRIEDRICH-ALEXANDER-            
* UNIVERSITAET ERLANGEN-NUERNBERG (FAU) BE LIABLE TO ANY PARTY FOR DIRECT,       
* INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT            
* OF THE USE OF THIS CODE AND ITS DOCUMENTATION, EVEN IF HARDWARE-               
* SOFTWARE-CO-DESIGN, FRIEDRICH-ALEXANDER-UNIVERSITAET ERLANGEN-NUERNBERG        
* (FAU) HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. THE                  
* AFOREMENTIONED EXCLUSIONS OF LIABILITY DO NOT APPLY IN CASE OF INTENT          
* BY HARDWARE-SOFTWARE-CO-DESIGN, FRIEDRICH-ALEXANDER-UNIVERSITAET               
* ERLANGEN-NUERNBERG (FAU).                                                      
*                                                                                
* HARDWARE-SOFTWARE-CO-DESIGN, FRIEDRICH-ALEXANDER-UNIVERSITAET ERLANGEN-        
* NUERNBERG (FAU), SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT         
* NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          
* FOR A PARTICULAR PURPOSE.                                                      
*                                                                                
* THE CODE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND HARDWARE-              
* SOFTWARE-CO-DESIGN, FRIEDRICH-ALEXANDER-UNIVERSITAET ERLANGEN-                 
* NUERNBERG (FAU) HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,             
* UPDATES, ENHANCEMENTS, OR MODIFICATIONS.                                       
* -------------------------------------------------------------------------      
*                                                                                
*  @author Streit Franz-Josef                                                    
*  @date   05 Mai 2018                                                      
*  @version 0.1                                                                  
*  @brief baremetal software driver for the read adapter ipb 
*                                                                                
*                                                                                
**/


/***************************** Include Files *******************************/
#include "read_adapter.h"
/************************** Function Definitions ***************************/

read_adapter * init_read_adapter(u32 address) {
  read_adapter *control = (read_adapter*) address;
  return control;
}

u32 push_data(read_adapter *control, XAxiDma * InstancePtr, void *data,
    u32 pkt_length, push_size size) {

  if (reg_en_read_adapt == control->use_reg) {
    switch (size) {
      case push_32_bit:
        control->lsb_push = *(s32 *) data;
        break;
      case push_64_bit:
        control->lsb_push = (*(s64 *) data & 0xFFFFFFFF);
        control->msb_push = (((*(s64 *) data) >> 32) & 0xFFFFFFFF);
        break;
      default:
        control->lsb_push = *(s32 *) data;
        break;
    }
  } else {
    u32 Status;
    /* Flush the SrcBuffer before the DMA transfer */
    Xil_DCacheFlushRange((UINTPTR) data, pkt_length);
    Status = XAxiDma_SimpleTransfer(InstancePtr, (UINTPTR) data, pkt_length,
        XAXIDMA_DMA_TO_DEVICE);

    if (Status != XST_SUCCESS) {
      return XST_FAILURE;
    }
    // Wait for write done
    while ((XAxiDma_Busy(InstancePtr, XAXIDMA_DMA_TO_DEVICE))) {
      /* Wait */
    }
  }
  return XST_SUCCESS;
}

u32 set_reg_read_adapt(read_adapter *control, XAxiDma * InstancePtr, u32 dma_id,
    reg_ctrl_read_adapt reg) {

  switch (reg) {
    case reg_en_read_adapt:
      control->use_reg = reg;
      break;
    case reg_nen_read_adapt:
      control->use_reg = reg;
      u32 Status;
      XAxiDma_Config *CfgPtr;
      CfgPtr = NULL;
      CfgPtr = XAxiDma_LookupConfig(dma_id);
      if (!CfgPtr) {
        xil_printf("No config found for %d\r\n", dma_id);
        return XST_FAILURE;
      }
      Status = XAxiDma_CfgInitialize(InstancePtr, CfgPtr);
      if (Status != XST_SUCCESS) {
        xil_printf("Initialization failed %d\r\n", Status);
        return XST_FAILURE;
      }
      break;
    default:
      control->use_reg = reg;
      break;

  }
  return XST_SUCCESS;
}

reg_ctrl_read_adapt get_reg_read_adapt(read_adapter *control) {
  return control->use_reg;
}


