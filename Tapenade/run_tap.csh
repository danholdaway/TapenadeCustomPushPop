#!/bin/csh -f

reset

setenv TAPENADE_HOME /home/drholdaw/Programs/tapenade3.13

#Tapenade options
set opts = "-tgtvarname _tl -tgtfuncname _tlm -adjvarname _ad -adjfuncname _adm"

rm -rf tlm/
mkdir tlm/

$TAPENADE_HOME/bin/tapenade ${opts} -d -O tlm/ -head "advection_mod.advect_1d (y)/(x U)" advection.F90

cd tlm/
mv advection_mod_diff.f90 advection_tlm.F90
cd ../

rm -rf adm/
mkdir adm/

$TAPENADE_HOME/bin/tapenade ${opts} -b -O adm/ -head "advection_mod.advect_1d (x y U)/(x y U)" advection.F90 -nocheckpoint "advection_mod.advect_1d"

cd adm/
mv advection_mod_diff.f90 advection_adm.F90
cd ../
