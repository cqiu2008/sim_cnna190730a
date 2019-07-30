/*  global parameter  */
`define CH_IN                16
`define CH_OUT               32
`define PIX                  8
`define AXIWIDTH             128
`define LITEWIDTH            32
`define DWIDTH               8
`define ADD_WIDTH            19
`define COWIDTH              10
`define KWIDTH               4
`define LAYERWIDTH           8
`define DEPTHWIDTH           9

/*  for layer 0  */
`define LAYER_CH_IN          3
`define LAYER_CH_OUT         64
`define LAYER_BIAS           64
`define LAYER_KX             3
`define LAYER_KY             3
`define LAYER_WLOAD_LOOPS    576 //384=[(16*64*9)/16]*(2/3),because in layer0 case,only k3-k8 weights need,for other cases, there should be [(16*64*9)/16]=576
`define LAYER_OWIDTH         224