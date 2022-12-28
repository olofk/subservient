import os
import logging

import riscof.utils as utils
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()

class subservient(pluginTemplate):
    __model__ = "subservient"
    __version__ = "0.1.0"

    def __init__(self, *args, **kwargs):
        sclass = super().__init__(*args, **kwargs)
        config = kwargs.get('config')
        if config is None:
            print("Please enter input file paths in configuration.")
            raise SystemExit(1)
        self.dut_exe = os.path.join(config['PATH'] if 'PATH' in config else "","subservient")
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)
        self.pluginpath=os.path.abspath(config['pluginpath'])
        self.isa_spec = os.path.abspath(config['ispec'])
        self.platform_spec = os.path.abspath(config['pspec'])
        if 'target_run' in config and config['target_run']=='0':
            self.target_run = False
        else:
            self.target_run = True
        return sclass

    def initialise(self, suite, work_dir, archtest_env):
       self.work_dir = work_dir
       self.suite_dir = suite
       self.compile_cmd = 'riscv64-unknown-elf-gcc -march={0} \
         -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g\
         -T '+self.pluginpath+'/env/link.ld\
         -I '+self.pluginpath+'/env/\
         -I ' + archtest_env + ' {1} -o {2} {3}'
       self.objcopy_cmd = 'riscv64-unknown-elf-objcopy -O binary {0} {1}.bin'
       self.objdump_cmd = 'riscv64-unknown-elf-objdump -D {0} > {1}.disass'
       self.hexgen_cmd  = 'riscv64-unknown-elf-objcopy -O verilog {0}/{1}.elf {0}/{1}.hex'

       build_subservient = 'fusesoc run --target=fpga_tb \
         --build --build-root=subservient_test subservient'
       utils.shellCommand(build_subservient).run()
       self.sigdump_cmd = 'subservient_test/fpga_tb-verilator/Vsubservient_fpga\
          +timeout=100000000000\
          +signature={0}/DUT-subservient.signature\
          +firmware={0}/{1}.hex'

    def build(self, isa_yaml, platform_yaml):
      ispec = utils.load_yaml(isa_yaml)['hart0']
      self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')
      self.isa = 'rv' + self.xlen
      if "I" in ispec["ISA"]:
          self.isa += 'i'
      if "M" in ispec["ISA"]:
          self.isa += 'm'
      if "C" in ispec["ISA"]:
          self.isa += 'c'
      self.compile_cmd = self.compile_cmd+' -mabi='+('lp64 ' if 64 in ispec['supported_xlen'] else 'ilp32 ')

    def runTests(self, testList):
      for testname in testList:
          testentry = testList[testname]
          test = testentry['test_path']
          test_dir = testentry['work_dir']
          file_name = 'subservient-{0}'.format(test.rsplit('/',1)[1][:-2])

          elf = '{0}.elf'.format(file_name)
          compile_macros= ' -D' + " -D".join(testentry['macros'])
          marchstr = testentry['isa'].lower()

          compile_run = self.compile_cmd.format(marchstr, test, elf, compile_macros)
          utils.shellCommand(compile_run).run(cwd=test_dir)
          
          objcopy_run = self.objcopy_cmd.format(elf,file_name)
          utils.shellCommand(objcopy_run).run(cwd=test_dir)
          
          objdump_run = self.objdump_cmd.format(elf,file_name)
          utils.shellCommand(objdump_run).run(cwd=test_dir)

          hexgen_run = self.hexgen_cmd.format(test_dir,file_name)
          utils.shellCommand(hexgen_run).run()

          sigdump_run = self.sigdump_cmd.format(test_dir,file_name)
          utils.shellCommand(sigdump_run).run()
      if not self.target_run:
          raise SystemExit
