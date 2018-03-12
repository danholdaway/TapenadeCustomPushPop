#!/bin/csh -f

source /usr/share/modules/init/csh

if ($1 == "") then
  echo "Specifify either int or gcc as compiler"
  exit()
else
  echo "Building with $1 compiler"
endif

module purge

if ($1 == "int") then

  module load comp/intel-18.0.1.163
  set comp = "ifort"
  set ccomp = "icc"
  set opts = "-O3 -r8 -traceback"

else if ($1 == "gcc") then

  module load other/comp/gcc-7.2
  set comp = "gfortran"
  set ccomp = "gcc"
  set opts = "-O3 -fdefault-real-8 -fno-backtrace"

endif

set subs = "tapenade_iter.F90 advection.F90 advection_tlm.F90 advection_adm.F90"
set exec = "-o adv_1d.x"
set prog = "Advection1D.F90"

rm -f *.mod adv_1d.x

cd Tapenade
$ccomp -c adStack.c
$comp -c adBuffer.f
cd ../

$comp Tapenade/adStack.o Tapenade/adBuffer.o $opts $subs $exec $prog
