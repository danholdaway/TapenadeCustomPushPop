module advection_mod

implicit none

private
public advect_1d, gridind_type

type gridind_type
 real(8), allocatable :: x(:)
 integer, allocatable :: fx(:)
 integer, allocatable :: f1x(:)
 integer, allocatable :: g1x(:)
end type gridind_type

contains

 subroutine advect_1d(nx,nt,x,y,C,dt,dx,U,grid)
 
  implicit none
 
  integer, intent(in) :: nx, nt
  real(8), intent(in) :: C, dt, dx, U
  real(8), intent(inout) :: x(nx)
  real(8), intent(out) :: y(nx)
  type(gridind_type), intent(in) :: grid
 
  integer :: t, j
  real(8) :: xold(nx), xhalf(nx)
 
  xold = x
  x = 0.0

  !Advect once around the domain (if u = 1)
  do t = 1,nt

    do j = 1,nx
      xhalf(grid%fx(j))=0.5*(xold(grid%fx(j))+xold(grid%g1x(j))) - 0.5*C*(xold(grid%fx(j))-xold(grid%g1x(j)))
    enddo

    do j = 1,nx
      xold(grid%fx(j)) = xold(grid%fx(j)) - (U*dt/dx)*(xhalf(grid%f1x(j))-xhalf(grid%fx(j)))
    enddo 

  enddo
 
  y = xold

 end subroutine advect_1d

end module advection_mod
