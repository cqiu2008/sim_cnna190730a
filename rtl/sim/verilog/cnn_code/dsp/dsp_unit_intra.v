//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : dsp_unit_intra.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_main_process.v
//        |--U02_axim_wddr
// cnna --|--U03_axis_reg
//        |--U04_
//--------------------------------------------------------------------------------------------------
//Relaese History :
//--------------------------------------------------------------------------------------------------
//Version         Date           Author        Description
// 1.1           july-30-2019                    
//--------------------------------------------------------------------------------------------------
//Main Function:
//a)Get the data from ddr chip using axi master bus
//b)Write it to the ibuf ram
//--------------------------------------------------------------------------------------------------
//REUSE ISSUES: none
//Reset Strategy: synchronization 
//Clock Strategy: one common clock 
//Critical Timing: none 
//Asynchronous Interface: none 
//END_HEADER----------------------------------------------------------------------------------------
module dsp_unit_intra #(
parameter 
    C_IN0                    = 30        ,
    C_IN1                    = 18        ,
    C_IN2                    = 48        ,
    C_OUT                    = 48        
)(
input                               I_clk               ,
input       [             C_IN0-1:0]I_weight            ,//
input       [             C_IN1-1:0]I_pixel             ,//
input       [             C_IN2-1:0]I_product_cas       ,//
output      [             C_OUT-1:0]O_product_cas       ,//
output      [             C_OUT-1:0]O_product            //
);

parameter C_MULTIPLIERA            = 30        ;
parameter C_MULTIPLIERB            = 18        ;
parameter C_PRODUCTC               = 48        ;

wire   [     C_MULTIPLIERA-1:0]S_weight            ;//
wire   [     C_MULTIPLIERB-1:0]S_pixel             ;//
wire   [        C_PRODUCTC-1:0]S_product           ;//
wire   [        C_PRODUCTC-1:0]S_product_casi      ;//
wire   [        C_PRODUCTC-1:0]S_product_caso      ;//

////////////////////////////////////////////////////////////////////////////////////////////////////
// align 
////////////////////////////////////////////////////////////////////////////////////////////////////
//input
align #(
    .C_IN_WIDTH     (C_IN0          ), 
    .C_OUT_WIDTH    (C_MULTIPLIERA  ))
u_weight(
    .I_din          (I_weight       ),
    .O_dout         (S_weight       ) 
);

align #(
    .C_IN_WIDTH     (C_IN1          ), 
    .C_OUT_WIDTH    (C_MULTIPLIERB  ))
u_pixel(
    .I_din          (I_pixel        ),
    .O_dout         (S_pixel        ) 
);

align #(
    .C_IN_WIDTH     (C_IN2          ), 
    .C_OUT_WIDTH    (C_PRODUCTC     ))
u_product_casi(
    .I_din          (I_product_cas  ),
    .O_dout         (S_product_casi  ) 
);

//output 
align #(
    .C_IN_WIDTH     (C_PRODUCTC     ), 
    .C_OUT_WIDTH    (C_OUT          ))
u_product(
    .I_din          (S_product      ),
    .O_dout         (O_product      ) 
);

align #(
    .C_IN_WIDTH     (C_PRODUCTC     ), 
    .C_OUT_WIDTH    (C_OUT          ))
u_product_caso(
    .I_din          (S_product_caso ),
    .O_dout         (O_product_cas  ) 
);
////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//                                                                                                
//                                                                                                
////////////////////////////////////////////////////////////////////////////////////////////////////

DSP48E2 #(
   // Feature Control Attributes: Data Path Selection
   .AMULTSEL("A"),                    // Selects A input to multiplier (A, AD)
   .A_INPUT("DIRECT"),                // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
   .BMULTSEL("B"),                    // Selects B input to multiplier (AD, B)
   .B_INPUT("DIRECT"),                // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
   .PREADDINSEL("A"),                 // Selects input to pre-adder (A, B)
   .RND(48'h000000000000),            // Rounding Constant
   .USE_MULT("MULTIPLY"),             // Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
   .USE_SIMD("ONE48"),                // SIMD selection (FOUR12, ONE48, TWO24)
   .USE_WIDEXOR("FALSE"),             // Use the Wide XOR function (FALSE, TRUE)
   .XORSIMD("XOR24_48_96"),           // Mode of operation for the Wide XOR (XOR12, XOR24_48_96)
   // Pattern Detector Attributes: Pattern Detection Configuration
   .AUTORESET_PATDET("NO_RESET"),     // NO_RESET, RESET_MATCH, RESET_NOT_MATCH
   .AUTORESET_PRIORITY("RESET"),      // Priority of AUTORESET vs. CEP (CEP, RESET).
   .MASK(48'h3fffffffffff),           // 48-bit mask value for pattern detect (1=ignore)
   .PATTERN(48'h000000000000),        // 48-bit pattern match for pattern detect
   .SEL_MASK("MASK"),                 // C, MASK, ROUNDING_MODE1, ROUNDING_MODE2
   .SEL_PATTERN("PATTERN"),           // Select pattern value (C, PATTERN)
   .USE_PATTERN_DETECT("NO_PATDET"),  // Enable pattern detect (NO_PATDET, PATDET)
   // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
   .IS_ALUMODE_INVERTED(4'b0000),     // Optional inversion for ALUMODE
   .IS_CARRYIN_INVERTED(1'b0),        // Optional inversion for CARRYIN
   .IS_CLK_INVERTED(1'b0),            // Optional inversion for CLK
   .IS_INMODE_INVERTED(5'b00000),     // Optional inversion for INMODE
   .IS_OPMODE_INVERTED(9'b000000000), // Optional inversion for OPMODE
   .IS_RSTALLCARRYIN_INVERTED(1'b0),  // Optional inversion for RSTALLCARRYIN
   .IS_RSTALUMODE_INVERTED(1'b0),     // Optional inversion for RSTALUMODE
   .IS_RSTA_INVERTED(1'b0),           // Optional inversion for RSTA
   .IS_RSTB_INVERTED(1'b0),           // Optional inversion for RSTB
   .IS_RSTCTRL_INVERTED(1'b0),        // Optional inversion for RSTCTRL
   .IS_RSTC_INVERTED(1'b0),           // Optional inversion for RSTC
   .IS_RSTD_INVERTED(1'b0),           // Optional inversion for RSTD
   .IS_RSTINMODE_INVERTED(1'b0),      // Optional inversion for RSTINMODE
   .IS_RSTM_INVERTED(1'b0),           // Optional inversion for RSTM
   .IS_RSTP_INVERTED(1'b0),           // Optional inversion for RSTP
   // Register Control Attributes: Pipeline Register Configuration
   .ACASCREG(1),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
   .ADREG(1),                         // Pipeline stages for pre-adder (0-1)
   .ALUMODEREG(1),                    // Pipeline stages for ALUMODE (0-1)
   .AREG(2),                          // Pipeline stages for A (0-2)
   .BCASCREG(1),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
   .BREG(1),                          // Pipeline stages for B (0-2)
   .CARRYINREG(1),                    // Pipeline stages for CARRYIN (0-1)
   .CARRYINSELREG(1),                 // Pipeline stages for CARRYINSEL (0-1)
   .CREG(1),                          // Pipeline stages for C (0-1)
   .DREG(1),                          // Pipeline stages for D (0-1)
   .INMODEREG(1),                     // Pipeline stages for INMODE (0-1)
   .MREG(1),                          // Multiplier pipeline stages (0-1)
   .OPMODEREG(1),                     // Pipeline stages for OPMODE (0-1)
   .PREG(1)                           // Number of pipeline stages for P (0-1)
)
u_dsp48e2(
   // Cascade outputs: Cascade Ports
   .ACOUT(),                          // 30-bit output: A port cascade
   .BCOUT(),                          // 18-bit output: B cascade
   .CARRYCASCOUT(),                   // 1-bit output: Cascade carry
   .MULTSIGNOUT(),                    // 1-bit output: Multiplier sign cascade
   .PCOUT(S_product_caso),             // 48-bit output: Cascade output
   // Control outputs: Control Inputs/Status Bits
   .OVERFLOW(),                       // 1-bit output: Overflow in add/acc
   .PATTERNBDETECT(),                 // 1-bit output: Pattern bar detect
   .PATTERNDETECT(),                  // 1-bit output: Pattern detect
   .UNDERFLOW(),                      // 1-bit output: Underflow in add/acc
   // Data outputs: Data Ports
   .CARRYOUT(),                       // 4-bit output: Carry
   .P(S_product),                     // 48-bit output: Primary data
   .XOROUT(),                         // 8-bit output: XOR data
   // Cascade inputs: Cascade Ports
   .ACIN(30'd0),                      // 30-bit input: A cascade data
   .BCIN(18'd0),                      // 18-bit input: B cascade
   .CARRYCASCIN(1'b0),                // 1-bit input: Cascade carry
   .MULTSIGNIN(1'b0),                 // 1-bit input: Multiplier sign cascade
   .PCIN(S_product_casi),              // 48-bit input: P cascade
   // Control inputs: Control Inputs/Status Bits
   .ALUMODE(4'd0),                    // 4-bit input: ALU control
   .CARRYINSEL(3'd0),                 // 3-bit input: Carry select
   .CLK(I_clk),                       // 1-bit input: Clock
   .INMODE(5'b10001),                 // 5-bit input: INMODE control
   //INMODE{ [4]=1'b1[3]=x,[2]=x, [1]=1'b0,[0]=1'b1,}
   .OPMODE(9'b00_001_0101),           // 9-bit input: Operation mode
   //OPMODE{[8,7]=2'b0,[6,4]=3'b001,[3,2,1,0]=4'b0101}
   // Data inputs: Data Ports
   .A(S_weight),                      // 30-bit input: A data
   .B(S_pixel),                       // 18-bit input: B data
   .C(48'd0),                         // 48-bit input: C data
   .CARRYIN(1'b0),                    // 1-bit input: Carry-in
   .D(27'd0),                         // 27-bit input: D data
   // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
   .CEA1(1'b1),                       // 1-bit input: Clock enable for 1st stage AREG
   .CEA2(1'b0),                       // 1-bit input: Clock enable for 2nd stage AREG
   .CEAD(1'b1),                       // 1-bit input: Clock enable for ADREG
   .CEALUMODE(1'b0),                  // 1-bit input: Clock enable for ALUMODE
   .CEB1(1'b1),                       // 1-bit input: Clock enable for 1st stage BREG
   .CEB2(1'b0),                       // 1-bit input: Clock enable for 2nd stage BREG
   .CEC(1'b0),                        // 1-bit input: Clock enable for CREG
   .CECARRYIN(1'b0),                  // 1-bit input: Clock enable for CARRYINREG
   .CECTRL(1'b1),                     // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
   .CED(1'b1),                        // 1-bit input: Clock enable for DREG
   .CEINMODE(1'b1),                   // 1-bit input: Clock enable for INMODEREG
   .CEM(1'b1),                        // 1-bit input: Clock enable for MREG
   .CEP(1'b1),                        // 1-bit input: Clock enable for PREG
   .RSTA(1'b0),                       // 1-bit input: Reset for AREG
   .RSTALLCARRYIN(1'b0),              // 1-bit input: Reset for CARRYINREG
   .RSTALUMODE(1'b0),                 // 1-bit input: Reset for ALUMODEREG
   .RSTB(1'b0),                       // 1-bit input: Reset for BREG
   .RSTC(1'b0),                       // 1-bit input: Reset for CREG
   .RSTCTRL(1'b0),                    // 1-bit input: Reset for OPMODEREG and CARRYINSELREG
   .RSTD(1'b0),                       // 1-bit input: Reset for DREG and ADREG
   .RSTINMODE(1'b0),                  // 1-bit input: Reset for INMODEREG
   .RSTM(1'b0),                       // 1-bit input: Reset for MREG
   .RSTP(1'b0)                        // 1-bit input: Reset for PREG
);

// End of DSP48E2_inst instantiation

endmodule

