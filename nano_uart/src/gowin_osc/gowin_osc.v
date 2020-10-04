//Copyright (C)2014-2019 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.2.01Beta
//Part Number: GW1N-LV1QN48C6/I5
//Created Time: Sun Aug 23 21:49:09 2020

module Gowin_OSC (oscout);

output oscout;

OSCH osc_inst (
    .OSCOUT(oscout)
);

defparam osc_inst.FREQ_DIV = 2;

endmodule //Gowin_OSC
