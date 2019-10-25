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
*  @brief baremetal software driver for the write adapter ipb 
*                                                                                
*                                                                                
**/

/***************************** Include Files *******************************/
#include "write_adapter.h"
/************************** Function Definitions ***************************/

write_adapter * init_write_adapter(u32 address) {
  write_adapter *control = (write_adapter*) address;
  return control;
}

u32 pop_data(write_adapter *control, XAxiDma * InstancePtr, void* data, pop_size size) {

  if (reg_en_write_adapt == control->use_reg) {
    u32 lsb_word;
    s64 msb_word;
    switch (size) {
      case pop_32_bit:
        *(s32 *) data = control->lsb_pop;
        break;
      case pop_64_bit:
        lsb_word = control->lsb_pop;
        msb_word = control->msb_pop;
        *(s64 *) data = (msb_word<<32 | lsb_word);
        break;
      default:
        *(s32 *) data = control->lsb_pop;
        break;
    }
  } else {
    u32 Status;
    Status = XAxiDma_SimpleTransfer(InstancePtr, (UINTPTR) data, control->pkg_lng,
        XAXIDMA_DEVICE_TO_DMA);
    if (Status != XST_SUCCESS) {
      return XST_FAILURE;
    }
    // Wait for read done
    while ((XAxiDma_Busy(InstancePtr, XAXIDMA_DEVICE_TO_DMA))) {
      /* Wait */
    }
  // Invalidate Cache to read the new data 
  Xil_DCacheInvalidateRange((UINTPTR) data, control->pkg_lng);
  }
  
  return XST_SUCCESS;
}

u32 set_reg_write_adapt(write_adapter *control, XAxiDma * InstancePtr,
    u32 dma_id, reg_ctrl_write_adapt reg) {
  switch (reg) {
    case reg_en_write_adapt:
      control->use_reg = reg;
      break;
    case reg_nen_write_adapt:
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

reg_ctrl_write_adapt get_reg_write_adapt(write_adapter *control) {
  return control->use_reg;
}

void set_pkg_lng(write_adapter *control, u32 lng) {
  control->pkg_lng = lng;
}

u32 get_pkg_lng(write_adapter *control) {
  return control->pkg_lng;
}


