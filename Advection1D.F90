program advection

!Simple program to demonstrate the use of a custom interface to 
!Tapenade checkpointing of the adjoint. Could be useful in iterative 
!models, such as when using the adjoint for 4DVar data assimilation.
!Essentially the forward calls can be eliminated after a 3 iterations
!by saving the checkpoints to static arrays rather than the processor
!stack. Though this uses more memory than recompuation it can be 
!significantly cheaper. Further the software can check that the 
!checkpoint was indeed necessary.

!Uses of nlm/tlm/adm
use advection_mod, only: advect_1d, gridind_type
use advection_tlm_mod, only: advect_1d_tlm
use advection_adm_mod, only: advect_1d_fwd, advect_1d_bwd

!Use for custom checkpointing at the top level
use tapenade_iter, only: cp_iter_controls, initialize_cp_iter, finalize_cp_iter
!Use for custom checkpointing at the module level
use tapenade_iter, only: cp_iter, cp_mod_ini, cp_mod_mid, cp_mod_end

implicit none

!Model parameters
integer, parameter :: ni = 2                     !Number of iterations
integer, parameter :: nx = 640                   !Number of grid points
real(8), parameter :: dx = 1.0/nx                !Grid spacing
real(8), parameter :: c = 0.1                    !Courant number
real(8), parameter :: dt = C*dx                  !Time step
integer, parameter :: nt = ceiling((1.0/(dt)))   !Number of time steps
real(8), parameter :: pi = 3.1415926535897932384 !pi
integer, parameter :: initcase = 1               !Reference state: 1 = sine wave, 2 = step
integer, parameter :: initcasep = 1              !Perturbation: 1 = sine wave, 2 = step

!Model variables
real(8), dimension(nx) :: x0, x0p
real(8), dimension(nx) :: x, y, xp, yp, ynl1, ynl2
real(8) :: U, UP, U0, UP0

!Model grid
type(gridind_type) :: grid

!Locals
real(8) :: dot(2) = 0.0
integer :: n, j

!Custom checkpointing
logical :: do_custom_cp
integer :: cp_adv_ind
real(8) :: start(3), finish(3)


!Set up the grid
!---------------
allocate(grid%x(nx))
allocate(grid%fx(nx))
allocate(grid%f1x(nx))
allocate(grid%g1x(nx))

do j = 1,nx
   grid%x(j) = j*dx
   grid%fx(j) = j
enddo
grid%f1x=mod(grid%fx,nx)+1
grid%g1x=mod(grid%fx-1,nx)
grid%g1x(1)=nx


!Initial reference state field
!-----------------------------
if (initcase == 1) then
  !Sin wave
  x0 = 0.5*(1.0+sin(2.0*pi*grid%x))
elseif (initcase == 2) then
  !Step function
  x0 = 0.0
  do j = 1,nx
    if (grid%x(j) .gt. 0.25 .and. grid%x(j) .lt. 0.75) then
      x0(j)=1.0
    endif
  enddo
endif


!Initial perturbation state
!--------------------------
if (initcasep == 1) then
  !Sin wave
  x0p = 1.0e-5 * 0.5*(1.0+sin(2.0*pi*grid%x))
elseif (initcasep == 2) then
  !Step function
  x0p = 0.0
  do j = 1,nx
    if (grid%x(j) .gt. 0.25 .and. grid%x(j) .lt. 0.75) then
      x0p(j)=1.0e-5
    endif
  enddo
endif


!Winds
!-----
U0 = 1.0
Up0 = 1.0e-5

!Setup the custom checkpointing (top level, i.e. if we had more than just advection)
!-----------------------------------------------------------------------------------
do_custom_cp = .true.

cp_iter_controls%cp_i = 0
if (do_custom_cp) cp_iter_controls%cp_i = 1      !Default to 0 to just do what Tapenade would do to checkpoint
cp_iter_controls%cp_nt = 1     !Total timesteps when optionally tracking the time steps
cp_iter_controls%cp_t = 1      !Current time step when optionally track the time steps
cp_iter_controls%cp_gb = -0.1  !If poisitive provides max gb per processor to prevent crash
cp_iter_controls%cp_nm = 1     !Number of modules using the custom checkpointin just advction here


!If iterative then allocate variable that will hold controls
call initialize_cp_iter

!Setup the custom checkpointing (module level, i.e. for advection)
!-----------------------------------------------------------------
if (do_custom_cp) then
  cp_adv_ind = 1 !use an integer to identify this subroutine/module calling the checkpointing
                 !This allows multiple subroutines to create their own static arrays for 
                 !storing checkpoints

  cp_iter(cp_adv_ind)%my_name(1:3) = 'adv'         !Give myself a name
  cp_iter(cp_adv_ind)%cp_test = .false.            !Run in test mode?
  cp_iter(cp_adv_ind)%cp_rep = .false.              !Write reports on memory use etc?
  cp_iter(cp_adv_ind)%check_st_control = .false.   !Check whether checkpoints are necessary?
  cp_iter(cp_adv_ind)%check_st_integer = .false.   !Check whether checkpoints are necessary?
  cp_iter(cp_adv_ind)%check_st_real_r4 = .false.   !Check whether checkpoints are necessary?
  cp_iter(cp_adv_ind)%check_st_real_r8 = .false.   !Check whether checkpoints are necessary?
endif

!call writetotxt(x0,nx,"intitial.txt")

!Iterate
!-------
do n = 1,4

   start = 0.0
   finish = 0.0

   !Current iteration
   if (do_custom_cp) cp_iter_controls%cp_i = n

   print*, 'Iteration number: ', n
   print*, '   Iteration number for custom checkpointing: ', cp_iter_controls%cp_i

   !Call the nonlinear scheme to advect, once around the domain if u = 1, up = 0
   x = x0 
   U = U0
   call advect_1d(nx,nt,x,ynl1,C,dt,dx,U,grid)

   !Call again so the tangent linear test can be computed
   x = x0 + x0p
   U = U0 + Up0
   call advect_1d(nx,nt,x,ynl2,C,dt,dx,U,grid)

   !Call the tangent linear model
   x = x0
   U = U0
   xp = x0p
   Up = Up0
   call cpu_time(start(1))
   call advect_1d_tlm(nx,nt,x,xp,y,yp,C,dt,dx,U,Up,grid)
   call cpu_time(finish(1))

   print*, '   Tangent linear test [y(x+dx)-y(x)]/Mdx: ', maxval((ynl2 - ynl1)/yp)

   !Compute first part of the adjoint test
   do j = 1,nx
      dot(1) = dot(1) + yp(j) * yp(j)
   enddo

   !Initilize the this iterative step
   if (do_custom_cp) call cp_mod_ini(cp_adv_ind)

   !Call the forward sweep for the adjoint
   x = x0
   U = U0
   if (n<=3 .or. .not.do_custom_cp) then
      call cpu_time(start(2))
      !Only need to call the forward scheme if in first few iterations
      call advect_1d_fwd(nx,nt,x,y,C,dt,dx,U,grid)
      call cpu_time(finish(2))
   endif

   !Checkpoint mid point, reset counters etc
   if (do_custom_cp) call cp_mod_mid

   !WARNING: possible the backward sweep expects some reference state variables at the end time
   !so may need to checkpoint them inside the forward sweep if statement.

   !Call the backward sweep for the adjoint
   call cpu_time(start(3))
   Up = 0.0
   call advect_1d_bwd(nx,nt,x,xp,y,yp,C,dt,dx,U,Up,grid)
   call cpu_time(finish(3))

   !Compute second part of the adjoint test
   do j = 1,nx
      dot(2) = dot(2) + xp(j) * x0p(j)
   enddo
   dot(2) = dot(2) + Up * Up0

   !Print adjoint dor product test results
   print*, '   Adjoint test: ', (dot(2)-dot(1))/dot(2)

   print*, '    TIMING: '
   print '("     TLM = ",f6.3," seconds")',finish(1)-start(1)
   print '("     FWD = ",f6.3," seconds")',finish(2)-start(2)
   print '("     BWD = ",f6.3," seconds")',finish(3)-start(3)

   print*, ' '

enddo

deallocate(grid%x)
deallocate(grid%fx)
deallocate(grid%f1x)
deallocate(grid%g1x)

!Module level finalize
if (do_custom_cp .and. .not.cp_iter(cp_adv_ind)%cp_test) call cp_mod_end

!Global finialize
if (do_custom_cp) call finalize_cp_iter

contains

!A sub for writing output to be read by e.g. python routine
subroutine writetotxt(x,nx,filename)

 integer, intent(in) :: nx
 real(8), intent(in) :: x(nx)
 character(len=*), intent(in) :: filename

 integer :: n

 open (unit=223, file=trim(filename), status='unknown')
 do n = 1,nx
   write(223,*) x(n)
 enddo
 close(223)

endsubroutine writetotxt

end program advection
