from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import argparse
import os
import math

def check_power_of_2(value):
    value = int(value)
    if value <= 0:
        raise argparse.ArgumentTypeError("{} must be positive".format(value))
    frac, whole = math.modf(math.log(value) / math.log(2))
    if frac != 0:
        raise argparse.ArgumentTypeError("{} is not a power of 2".format(value))
    return value

def check_positive(value):
    if value <= 0:
        raise argparse.ArgumentTypeError("{} must be positive".format(value))
    return value

parser = argparse.ArgumentParser(description='Generate an SRAM macro')
parser.add_argument('depth', type=check_power_of_2, help='Number of words')
parser.add_argument('width', type=int, help='Word size in bits')
parser.add_argument('ports', type=int, help='Number of ports', choices=[1, 2])

sram_1_rw_template = """`default_nettype none

module {name} (
  input wire [{addr_bits}-1:0] A,
  input wire CE,
  input wire WEB,
  input wire OEB,
  input wire CSB,
  input wire [{data_bits}-1:0] I,
  output reg [{data_bits}-1:0] O
);
  wire RE = ~CSB && WEB;
  wire WE = ~CSB && ~WEB;

  reg [{depth}-1:0][{data_bits}-1:0] mem;
  reg [{data_bits}-1:0] data_out;
  always_ff @(posedge CE) begin
    if (RE) data_out <= mem[A];
    if (WE) mem[A] <= I;
  end

  assign O = !OEB ? data_out : {data_bits}'bz;
endmodule
"""

sram_2_rw_template = """`default_nettype none

module {name} (
  input  wire [{addr_bits}-1:0] A1,
  input  wire [{addr_bits}-1:0] A2,
  input  wire CE1,
  input  wire CE2,
  input  wire WEB1,
  input  wire WEB2,
  input  wire OEB1,
  input  wire OEB2,
  input  wire CSB1,
  input  wire CSB2,
  input  wire [{data_bits}-1:0] I1,
  input  wire [{data_bits}-1:0] I2,
  output reg  [{data_bits}-1:0] O1,
  output reg  [{data_bits}-1:0] O2
);
  wire RE1 = ~CSB1 &&  WEB1;
  wire WE1 = ~CSB1 && ~WEB1;
  wire RE2 = ~CSB2 &&  WEB2;
  wire WE2 = ~CSB2 && ~WEB2;

  reg [{depth}-1:0][{data_bits}-1:0] mem;
  reg [{data_bits}-1:0] data_out1;
  reg [{data_bits}-1:0] data_out2;
  always_ff @(posedge CE) begin
    if (RE1) data_out1 <= mem[A1];
    if (RE2) data_out2 <= mem[A2];
    if (WE1) mem[A1] <= I1;
    if (WE2) mem[A2] <= I2;
  end

  assign O1 = !OEB1 ? data_out1 : {data_bits}'bz;
  assign O2 = !OEB2 ? data_out2 : {data_bits}'bz;
endmodule
"""

def generate_sram(depth, width, ports):
    name = 'SRAM{p}RW{n}x{w}'.format(p=ports, n=depth, w=width)
    addr_bits = int(math.ceil(math.log(depth) / math.log(2)))
    with open(name + ".sv", 'w') as f:
        if ports == 1:
            f.write(sram_1_rw_template.format(
                name=name, depth=depth, addr_bits=addr_bits, data_bits=width))
        else:
            f.write(sram_2_rw_template.format(
                name=name, depth=depth, addr_bits=addr_bits, data_bits=width))

if __name__ == "__main__":
    args = parser.parse_args()
    generate_sram(depth=args.depth, width=args.width, ports=args.ports)
