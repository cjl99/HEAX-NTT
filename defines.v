`timescale 1 ns / 1 ps

// ------------------------------------------------
// User parameters
// -- K: DATA_SIZE_ARB
// -- n: RING_SIZE
// -- PE: (processing element) = the number of NTT core

`define CIPHER_SIZE   27
`define RING_SIZE     1024
`define NTT_CORE      8
`define CIPHER_MORE   32 // for debug

`define LOG_RING_SIZE   ($clog2(`RING_SIZE))
`define LOG_NTT_CORE   ($clog2(`NTT_CORE))

`define DOUBLE_NTT_CORE (`NTT_CORE << 1)
`define DOUBLE_RING_SIZE (`RING_SIZE << 1) 
`define TWI_DRAM_DEPTH ((`LOG_RING_SIZE)-(`LOG_NTT_CORE))
`define CIPHER_DRAM_DEPTH ((`LOG_RING_SIZE)-(`LOG_NTT_CORE)-1)

`define MASK (1<<(`CIPHER_SIZE + 2) - 1)

//--------------------------------------------------------------------------------

// ------------------------------------------------
