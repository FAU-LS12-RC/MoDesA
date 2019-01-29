##
# -------------------------------------------------------------------------  
#   Copyright (c) 2017 Hardware-Software-Co-Design, Friedrich-
#   Alexander-Universitaet Erlangen-Nuernberg (FAU), Germany.
#   All rights reserved.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
# -------------------------------------------------------------------------  
# 
#  @author  Patrick Plagwitz
#  @mail    franz-josef.streit@fau.de                                                   
#  @date    17 August 2018
#  @version 0.1
#  @brief   Chips softcore processor 
#
##

from chipsc.compiler import compile_chip
from chipsc.net.compiler import Net
from chipsc.compileoptions import CompileOptions, Toolchain, OptLevel, \
    compilation_id, generic_chip_id
from chipsc.project import Project
import argparse
import os
import sys

def parse_args():
  parser = argparse.ArgumentParser(prog="chipsc")
  parser.add_argument("source", help="source file or project directory")
  parser.add_argument("-o", help="output directory", metavar="output-dir")
  parser.add_argument("--make-subdir", help="make a subdirectory with name "
    "generated from compilation options within the output argument",
    action="store_true")

  parser.add_argument("-O", help="optimization level", metavar="opt-level",
      choices=["s", "0", "1", "2", "3"], default="0")
  parser.add_argument("--toolchain", help="python or llvm",
      choices=["python", "llvm"], default="llvm")
  parser.add_argument("--stack-size", help="stack size in bytes", type=int)
  parser.add_argument("--copts", help="Compiler options, separated by comma, "
    "e.g., --copts=-DA=1,-DB=2 passes -DA=1 and -DB=2 to the compiler.")

  parser.add_argument("--make-project", action="store_true",
      help="generate vivado project")
  parser.add_argument("--impl",
      metavar="results-dir",
      help="implement design and store reports in argument")
  parser.add_argument("--ip", metavar="ip-repo",
      help="generate ip block into specified repo directory")

  parser.add_argument("--make-net",
      help="Generate a net of processors. The source must be a config file.",
      action="store_true")
  ret = parser.parse_args()

  source_is_project = os.path.isdir(ret.source)

  if ret.o is not None and source_is_project:
    sys.stderr.write("warning: -o ignored\n")
  if ret.o is None and not source_is_project:
    sys.stderr.write("error: missing option -o\n")
    parser.print_help(sys.stderr)
    sys.exit(2)

  if ret.copts:
    ret.copts = ret.copts.split(",")
  return ret

def make_net_project(args):
  options = args.copts or []
  net = Net(args.source, options)
  chip_id = generic_chip_id(net.name, options)
  out_dir = args.o
  if args.make_subdir:
    out_dir = os.path.join(out_dir, chip_id)
  os.mkdir(out_dir)
  src_dir = os.path.join(out_dir, "src")
  os.mkdir(src_dir)
  inputs, outputs = net.compile(src_dir)
  return Project.create(out_dir, inputs, outputs, net.name, chip_id)

def main():
  args = parse_args()

  toolchain = dict(llvm=Toolchain.Llvm, python=Toolchain.Python)[args.toolchain]
  compile_options = CompileOptions(toolchain, OptLevel(args.O),
      stack_size=args.stack_size)
  if args.copts:
    compile_options = compile_options.with_misc_opts(*args.copts)

  if args.make_net:
    project = make_net_project(args)
  elif not os.path.isdir(args.source):
    project_dir = args.o
    if args.make_subdir:
      project_dir = os.path.join(project_dir,
          compilation_id(args.source, compile_options))
    project = Project.compile(project_dir, compile_options, args.source)
  else:
    project = Project.open(args.source)

  if args.make_project:
    project.generate_vivado_project()
  if args.ip is not None:
    project.generate_ip_block(args.ip)
  if args.impl is not None:
    project.run_implementation(args.impl)

  return 0

if __name__ == "__main__":
  sys.exit(main())
