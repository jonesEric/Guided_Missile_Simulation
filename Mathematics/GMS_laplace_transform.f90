

module laplace_transform




 !===================================================================================85
 !---------------------------- DESCRIPTION ------------------------------------------85
 !
 !
 !
 !          Module  name:
 !                         'laplace_transform'
 !          
 !          Purpose:
 !                      This module contains an implementation of the Laplace
 !                      Transform with the help of Quadpack QAGE integrators.
 !          History:
 !                        Date: 16-07-2022
 !                        Time: 12:55 GMT+2
 !                        
 !          Version:
 !
 !                      Major: 1
 !                      Minor: 0
 !                      Micro: 0
 !
 !          Author:  
 !                      Bernard Gingold
 !          
 !                 
 !          References:
 !         
 !                          Own implementation (ported from similar C++ version)
 !         
 !          E-mail:
 !                  
 !                      beniekg@gmail.com
 !==================================================================================85
    ! Tab:5 col - Type and etc.. definitions
    ! Tab:10,11 col - Type , function and subroutine code blocks.

    use mod_kinds, only : i4, dp
    implicit none
    public

    !=====================================================59
     !  File and module information:
     !  version,creation and build date, author,description
     !=====================================================59

     ! Major version
     integer(kind=i4),   parameter :: LAPLACE_TRANSFORM_MAJOR = 1
     ! Minor version
     integer(kind=i4),   parameter :: LAPLACE_TRANSFORM_MINOR = 0
     ! Micro version
     integer(kind=i4),   parameter :: LAPLACE_TRANSFORM_MICRO = 0
     ! Full version
     integer(kind=i4),   parameter :: LAPLACE_TRANSFORM_FULLVER =   &
            1000*LAPLACE_TRANSFORM_MAJOR+100*LAPLACE_TRANSFORM_MINOR+10*LAPLACE_TRANSFORM_MICRO
     ! Module creation date
     character(*),        parameter :: LAPLACE_TRANSFORM_DATE        = "16-07-2022 13:04 +00200 (SAT 16 JUL 2022 GMT+2)"
     ! Module build date
     character(*),        parameter :: LAPLACE_TRANSFORM_BUILD_DATE  = __DATE__ " " __TIME__
     ! Module author info
     character(*),        parameter :: LAPLACE_TRANSFORM_AUTHOR      = "Programmer: Bernard Gingold, contact: beniekg@gmail.com"
     ! Short description
     character(*),        parameter :: LAPLACE_TRANSFORM_SYNOPSIS    = "Laplace-Transform computed by QUADPACK QAGE integrators."

     type, public :: l_qage_params
           ! QAGE return info
        real(kind=dp),    dimension(:), allocatable :: re_abserr
        real(kind=dp),    dimension(:), allocatable :: im_abserr
        integer(kind=i4), dimension(:), allocatable :: re_neval
        integer(kind=i4), dimension(:), allocatable :: im_neval
        integer(kind=i4), dimension(:), allocatable :: re_ier
        integer(kind=i4), dimension(:), allocatable :: im_ier
        integer(kind=i4), dimension(:), allocatable :: re_last
        integer(kind=i4), dimension(:), allocatable :: im_last
        !dir$ attributes align : 64 :: re_abserr
        !dir$ attributes align : 64 :: im_abserr
        !dir$ attributes align : 64 :: re_neval
        !dir$ attributes align : 64 :: im_neval
        !dir$ attributes align : 64 :: re_ier
        !dir$ attributes align : 64 :: im_ier
        !dir$ attributes align : 64 :: re_last
        !dir$ attributes align : 64 :: im_last
        integer(kind=i4) :: npts ! Number of transform points.
        logical(kind=i4) :: isalloc
     end type l_qage_params


     abstract interface

        real(kind=dp) function re_func(t,user_data)
             import :: dp
             implicit none
             real(kind=dp),   intent(in) :: t
             class(*),        intent(in) :: user_data
        end function re_func

        real(kind=dp) function im_func(t,user_data)
             import :: dp
             implicit none
             real(kind=dp),   intent(in) :: t
             class(*),        intent(in) :: user_data
        end function im_func
        
       
     end interface


     contains

     
     subroutine init_l_qage_params(params,npts)
         !dir$ optimize:3
         !dir$ attributes code_align : 32 :: init_l_qage_params
         type(l_qage_params),   intent(in) :: params
         integer(kind=i4),      intent(in) :: npts
         ! Exec code
         if(params.isalloc .or. &
              npts <= 2)   return
         allocate(params.re_abserr(npts))
         allocate(params.im_abserr(npts))
         allocate(params.re_neval(npts))
         allocate(params.im_neval(npts))
         allocate(params.re_ier(npts))
         allocate(params.im_ier(npts))
         allocate(params.re_last(npts))
         allocate(params.im_last(npts))
         params.isalloc = .true.
     end subroutine init_l_qage_params

     subroutine free_l_qage_params(params)
         !dir$ optimize:3
         !dir$ attributes code_align : 32 :: free_l_qage_params
         type(m_qage_params),   intent(in) :: params
         ! Exec code
         if(.not.params.isalloc) return
         deallocate(params.re_abserr)
         deallocate(params.im_abserr)
         deallocate(params.re_neval)
         deallocate(params.im_neval)
         deallocate(params.re_ier)
         deallocate(params.im_ier)
         deallocate(params.re_last)
         deallocate(params.im_last)
     end subroutine free_l_qage_params


#if 0

     Taken from C++ version.
     
 /*
                The integrands [real and imaginary] parts shall be implemented the following way
                void * user_data points to "s-1" complex power
                double re_func(double t, void * user_data) {
                   complex<double> s = *((complex<double>*)user_data); // s-complex power
                   const double x; // = .... Result of integrand evaluation of argument 't', e.g 't=x^2'
                   double re = s.real();
                   double im = s.imag();
                   double ere = std::exp(-re*t);
                   double cim = ere*std::cos(im*t);
                   return (cim*x);
                }
                 double im_func(double t, void * user_data) {
                   complex<double> s = *((complex<double>*)user_data); // s-complex power
                   const double x; // = .... Result of integrand evaluation of argument 't', e.g 't=x^2'
                   double re = s.real();
                   double im = s.imag();
                   double ere = std::exp(-re*t);
                   double sim = -ere*std::sin(im*t);
                   return (sim*x);
                }
            */



#endif


       subroutine laplacet_dqagi_omp(re_f,im_f,bound,inf,epsabs,  &
                                     epsrel,params,lenw,limit,    &
                                     work,iwork,input,output)
              !dir$ optimize:3
              !dir$ attributes code_align : 32 :: laplace_dqagi_omp
              use quadpack, only : dqagi
              use omp_lib
              implicit none
              procedure(re_func)                                :: re_f
              procedure(im_func)                                :: im_f
              real(kind=dp),                      intent(in)    :: bound
              integer(kind=i4),                   intent(in)    :: inf
              real(kind=dp),                      intent(in)    :: epsabs
              real(kind=dp),                      intent(in)    :: epsrel
              type(l_qage_params),                intent(inout) :: params
              integer(kind=i4),                   intent(in)    :: lenw
              integer(kind=i4),                   intent(in)    :: limit
              real(kind=dp),    dimension(lenw),  intent(inout) :: work
              integer(kind=i4), dimension(limit), intent(inout) :: iwork
              class(*),         dimension(:),     intent(in)    :: input
              complex(kind=dp), dimension(:),     intent(out)   :: output
              ! Locals
              complex(kind=dp), parameter :: I = cmplx(0.0_dp,1.0_dp)
              real(kind=dp),    automatic :: re
              real(kind=dp),    automatic :: im
              integer(kind=i4), automatic :: i
              ! Exec code ....
              re = 0.0_dp
              im = 0.0_dp
              select type (input)
                  type is (real(kind=dp))
!$omp parallel do schedule(runtime) default(none) if(params.npts >= 8) &
!$omp private(i,iwork,work,re,im)                               &
!$omp shared(npts,re_f,bound,inf,epsabs,epsrel,re_abserr)  &
!$omp shared(re_neval,re_ier,limit,lenw,re_last,input,output)                     
                     do i=1, params.npts
                        call dqagi(re_f,bound,inf,epsabs,epsrel,re,         &
                                   params.re_abserr(i),params.re_neval(i),  &
                                   params.re_ier(i),limit,lenw,             &
                                   params.re_last(i),iwork,work,input(i))
                        call dqagi(im_f,bound,inf,epsabs,epsrel,im,         &
                                   params.im_abserr(i),params.im_neval(i),  &
                                   params.im_ier(i),limit,lenw,             &
                                   params.im_last(i),iwork,work,input(i))
                        output(i) = re+I*im
                     end do
!$omp end parallel do
                  type is (complex(kind=dp))
!$omp parallel do schedule(runtime) default(none) if(params.npts >= 8) &
!$omp private(i,iwork,work,re,im)                               &
!$omp shared(npts,im_f,bound,inf,epsabs,epsrel,im_abserr)       &
!$omp shared(im_neval,im_ier,limit,lenw,im_last,input,output)   &
!$omp shared(re_abserr,re_neval,re_ier,re_last)
                     do i=1, params.npts
                        call dqagi(re_f,bound,inf,epsabs,epsrel,re,         &
                                   params.re_abserr(i),params.re_neval(i),  &
                                   params.re_ier(i),limit,lenw,             &
                                   params.re_last(i),iwork,work,input(i))
                        call dqagi(im_f,bound,inf,epsabs,epsrel,im,         &
                                   params.im_abserr(i),params.im_neval(i),  &
                                   params.im_ier(i),limit,lenw,             &
                                   params.im_last(i),iwork,work,input(i))
                        output(i) = re+I*im
                     end do
!$omp end parallel do
                  class default
                     stop "Invalid type in: laplacet_dqagi_omp"
                  end select
          end subroutine laplacet_dqagi_omp


          subroutine laplacet_dqage_omp(re_f,im_f,a,b,epsabs,epsrel,key, &
                                        limit,params,alist,blist,rlist,  &
                                        elist,iord,input,output)
                   !dir$ optimize:3
                   !dir$ attributes code_align : 32 :: laplacet_dqage_omp
                   use omp_lib
                   use quadpack, only : dqage
                   implicit none
                   procedure(re_func)                                 :: re_f
                   procedure(im_func)                                 :: im_f
                   real(kind=dp),                      intent(in)     :: a
                   real(kind=dp),                      intent(in)     :: b
                   real(kind=dp),                      intent(in)     :: epsabs
                   real(kind=dp),                      intent(in)     :: epsrel
                   integer(kind=i4),                   intent(in)     :: key
                   integer(kind=i4),                   intent(in)     :: limit
                   type(l_qage_params),                intent(inout)  :: params
                   real(kind=dp),    dimension(limit), intent(out)    :: alist
                   real(kind=dp),    dimension(limit), intent(out)    :: blist
                   real(kind=dp),    dimension(limit), intent(out)    :: elist
                   real(kind=dp),    dimension(limit), intent(out)    :: rlist
                   integer(kind=i4), dimension(limit), intent(out)    :: iord
                   class(*),         dimension(:),     intent(in)     :: input
                   complex(kind=dp), dimension(:),     intent(out)    :: output
                   ! Locals
                   complex(kind=dp), parameter :: I = cmplx(0.0_dp,1.0_dp)
                   real(kind=dp),    automatic :: re
                   real(kind=dp),    automatic :: im
                   integer(kind=i4), automatic :: i
                   ! Exec code ....
                   re = 0.0_dp
                   im = 0.0_dp
                   select type (input)
                       type is(real(kind=dp))
!$omp parallel do default(none) schedule(runtime) if(params.npts>=8)    &
!$omp private(i,re,im,alist,blist,rlist,elist,iord)                     &
!$omp shared(npts,re_f,im_f,a,b,epsabs,epsrel,key,limit)                &
!$omp shared(re_abserr,re_neval,re_ier,re_last,input,output)            &
!$omp shared(im_abserr,im_neval,im_ier,im_last)                          
                            do i=1, params.npts
                                call dqage(re_f,a,b,epsabs,epsrel,key,limit,           &
                                           re,params.re_abserr(i),params.re_neval(i),  &
                                           params.re_ier(i),alist,blist,rlist,elist,   &
                                           iord,re_last(i),input(i))
                                call dqage(im_f,a,b,epsabs,epsrel,key,limit,           &
                                           im,params.im_abserr(i),params.im_neval(i),  &
                                           params.im_ier(i),alist,blist,rlist,elist,   &
                                           iord,im_last(i),input(i))
                                output(i) = re+I*im
                             end do
!$omp end parallel do
                        type is(complex(kind=dp))
!$omp parallel do default(none) schedule(runtime) if(params.npts>=8)    &
!$omp private(i,im,im,alist,blist,rlist,elist,iord)                     &
!$omp shared(npts,im_f,re_f,a,b,epsabs,epsrel,key,limit)                &
!$omp shared(im_abserr,im_neval,im_ier,im_last,input,output)            &
!$omp shared(re_abserr,re_neval,re_ier,re_last)        
                             do i=1, params.npts
                                call dqage(re_f,a,b,epsabs,epsrel,key,limit,           &
                                           re,params.re_abserr(i),params.re_neval(i),  &
                                           params.re_ier(i),alist,blist,rlist,elist,   &
                                           iord,re_last(i),input(i))
                                call dqage(im_f,a,b,epsabs,epsrel,key,limit,           &
                                           im,params.im_abserr(i),params.im_neval(i),  &
                                           params.im_ier(i),alist,blist,rlist,elist,   &
                                           iord,im_last(i),input(i))
                                output(i) = re+I*im
                             end do
!$omp end parallel do
                   class default
                     stop "Invalid type in: laplacet_dqage_omp"
                  end select
                        
          end subroutine laplacet_dqage_omp
          

          
          subroutine laplacet_dqagp_omp(re_f,im_f,a,b,npts2,points,epsabs,epsrel, &
                                        params,leniw,lenw,iwork,work,input,output)
                                      
                   !dir$ optimize:3
                   !dir$ attributes code_align : 32 :: laplacet_dqagp_omp
                   use omp_lib
                   use quadpack, only : dqagp
                   implicit none
                   procedure(re_func)                                 :: re_f
                   procedure(im_func)                                 :: im_f
                   real(kind=dp),                      intent(in)     :: a
                   real(kind=dp),                      intent(in)     :: b
                   integer(kind=i4),                   intent(in)     :: npts2
                   real(kind=dp),   dimension(npts2),  intent(in)     :: points
                   real(kind=dp),                      intent(in)     :: epsabs
                   real(kind=dp),                      intent(in)     :: epsrel
                   type(l_qage_params),                intent(inout)  :: params
                   integer(kind=i4),                   intent(in)     :: leniw
                   integer(kind=i4),                   intent(in)     :: lenw
                   integer(kind=i4), dimension(leniw), intent(inout)  :: iwork
                   real(kind=dp),    dimension(lenw),  intent(inout)  :: work
                   class(*),         dimension(:),     intent(in)     :: input
                   complex(kind=dp), dimension(:),     intent(out)    :: output
                   ! Locals
                   complex(kind=dp), parameter :: I = cmplx(0.0_dp,1.0_dp)
                   real(kind=dp),    automatic :: re
                   real(kind=dp),    automatic :: im
                   integer(kind=i4), automatic :: i
                   ! Exec code ....
                   re = 0.0_dp
                   im = 0.0_dp
                   select type (input)
                       type is(real(kind=dp))
!$omp parallel do default(none) schedule(runtime) if(params.npts>=8)    &
!$omp private(i,re,im,iwork,work)                                       &
!$omp shared(npts2,npts,im_f,re_f,a,b,epsabs,epsrel,lenw,leniw,points)       &
!$omp shared(re_abserr,re_neval,re_ier,re_last,input,output)            &
!$omp shared(im_abserr,im_neval,im_ier,im_last)                          
                            do i=1, params.npts
                                call dqagp(re_f,a,b,npts2,points,epsabs,epsrel,        &
                                           re,params.re_abserr(i),params.re_neval(i),  &
                                           params.re_ier(i),leniw,lenw,re_last(i),iwork   &
                                           work,input(i))
                                call dqagp(im_f,a,b,npts2,points,epsabs,epsrel,        &
                                           im,params.im_abserr(i),params.im_neval(i),  &
                                           params.im_ier(i),leniw,lenw,re_last(i),     &
                                           iwork,work,input(i))
                                output(i) = re+I*im
                             end do
!$omp end parallel do
                        type is(complex(kind=dp))
!$omp parallel do default(none) schedule(runtime) if(params.npts>=8)    &
!$omp private(i,im,im,alist,blist,rlist,elist,iord)                     &
!$omp shared(npts,im_f,a,b,epsabs,epsrel,key,limit)                     &
!$omp shared(im_abserr,im_neval,im_ier,im_last,input,output)
!$omp shared(re_abserr,re_neval,re_ier,re_last)                           
                             do i=1, params.npts
                                call dqage(re_f,a,b,epsabs,epsrel,key,limit,           &
                                           re,params.re_abserr(i),params.re_neval(i),  &
                                           params.re_ier(i),alist,blist,rlist,elist,   &
                                           iord,re_last(i),input(i))
                                call dqage(im_f,a,b,epsabs,epsrel,key,limit,           &
                                           im,params.im_abserr(i),params.im_neval(i),  &
                                           params.im_ier(i),alist,blist,rlist,elist,   &
                                           iord,im_last(i),input(i))
                                output(i) = re+I*im
                             end do
!$omp end parallel do
                   class default
                     stop "Invalid type in: laplacet_dqagp_omp"
                  end select
                        
          end subroutine laplacet_dqagp_omp

                
            !==================================!
            !     Single-threaded versions     !
            !==================================!

          subroutine laplacet_dqagi(re_f,im_f,bound,inf,epsabs,  &
                                    epsrel,params,lenw,limit,    &
                                    work,iwork,input,output)
              !dir$ optimize:3
              !dir$ attributes code_align : 32 :: laplace_dqagi
              use quadpack, only : dqagi
              use omp_lib
              implicit none
              procedure(re_func)                                :: re_f
              procedure(im_func)                                :: im_f
              real(kind=dp),                      intent(in)    :: bound
              integer(kind=i4),                   intent(in)    :: inf
              real(kind=dp),                      intent(in)    :: epsabs
              real(kind=dp),                      intent(in)    :: epsrel
              type(l_qage_params),                intent(inout) :: params
              integer(kind=i4),                   intent(in)    :: lenw
              integer(kind=i4),                   intent(in)    :: limit
              real(kind=dp),    dimension(lenw),  intent(inout) :: work
              integer(kind=i4), dimension(limit), intent(inout) :: iwork
              class(*),         dimension(:),     intent(in)    :: input
              complex(kind=dp), dimension(:),     intent(out)   :: output
              ! Locals
              complex(kind=dp), parameter :: I = cmplx(0.0_dp,1.0_dp)
              real(kind=dp),    automatic :: re
              real(kind=dp),    automatic :: im
              integer(kind=i4), automatic :: i
              ! Exec code ....
              re = 0.0_dp
              im = 0.0_dp
              select type (input)
                  type is (real(kind=dp))
                    
                     do i=1, params.npts
                        call dqagi(re_f,bound,inf,epsabs,epsrel,re,         &
                                   params.re_abserr(i),params.re_neval(i),  &
                                   params.re_ier(i),limit,lenw,             &
                                   params.re_last(i),iwork,work,input(i))
                        call dqagi(im_f,bound,inf,epsabs,epsrel,im,         &
                                   params.im_abserr(i),params.im_neval(i),  &
                                   params.im_ier(i),limit,lenw,             &
                                   params.im_last(i),iwork,work,input(i))
                        output(i) = re+I*im
                     end do

                  type is (complex(kind=dp))

                     do i=1, params.npts
                        call dqagi(re_f,bound,inf,epsabs,epsrel,re,         &
                                   params.re_abserr(i),params.re_neval(i),  &
                                   params.re_ier(i),limit,lenw,             &
                                   params.re_last(i),iwork,work,input(i))
                        call dqagi(im_f,bound,inf,epsabs,epsrel,im,         &
                                   params.im_abserr(i),params.im_neval(i),  &
                                   params.im_ier(i),limit,lenw,             &
                                   params.im_last(i),iwork,work,input(i))
                        output(i) = re+I*im
                     end do

                  class default
                     stop "Invalid type in: laplacet_dqagi"
                  end select
          end subroutine laplacet_dqagi


          subroutine laplacet_dqage(re_f,im_f,a,b,epsabs,epsrel,key, &
                                        limit,params,alist,blist,rlist,  &
                                        elist,iord,input,output)
                   !dir$ optimize:3
                   !dir$ attributes code_align : 32 :: laplacet_dqage
                   use omp_lib
                   use quadpack, only : dqage
                   implicit none
                   procedure(re_func)                                 :: re_f
                   procedure(im_func)                                 :: im_f
                   real(kind=dp),                      intent(in)     :: a
                   real(kind=dp),                      intent(in)     :: b
                   real(kind=dp),                      intent(in)     :: epsabs
                   real(kind=dp),                      intent(in)     :: epsrel
                   integer(kind=i4),                   intent(in)     :: key
                   integer(kind=i4),                   intent(in)     :: limit
                   type(l_qage_params),                intent(inout)  :: params
                   real(kind=dp),    dimension(limit), intent(out)    :: alist
                   real(kind=dp),    dimension(limit), intent(out)    :: blist
                   real(kind=dp),    dimension(limit), intent(out)    :: elist
                   real(kind=dp),    dimension(limit), intent(out)    :: rlist
                   integer(kind=i4), dimension(limit), intent(out)    :: iord
                   class(*),         dimension(:),     intent(in)     :: input
                   complex(kind=dp), dimension(:),     intent(out)    :: output
                   ! Locals
                   complex(kind=dp), parameter :: I = cmplx(0.0_dp,1.0_dp)
                   real(kind=dp),    automatic :: re
                   real(kind=dp),    automatic :: im
                   integer(kind=i4), automatic :: i
                   ! Exec code ....
                   re = 0.0_dp
                   im = 0.0_dp
                   select type (input)
                       type is(real(kind=dp))
                        
                            do i=1, params.npts
                                call dqage(re_f,a,b,epsabs,epsrel,key,limit,           &
                                           re,params.re_abserr(i),params.re_neval(i),  &
                                           params.re_ier(i),alist,blist,rlist,elist,   &
                                           iord,re_last(i),input(i))
                                call dqage(im_f,a,b,epsabs,epsrel,key,limit,           &
                                           im,params.im_abserr(i),params.im_neval(i),  &
                                           params.im_ier(i),alist,blist,rlist,elist,   &
                                           iord,im_last(i),input(i))
                                output(i) = re+I*im
                             end do

                        type is(complex(kind=dp))
       
                             do i=1, params.npts
                                call dqage(re_f,a,b,epsabs,epsrel,key,limit,           &
                                           re,params.re_abserr(i),params.re_neval(i),  &
                                           params.re_ier(i),alist,blist,rlist,elist,   &
                                           iord,re_last(i),input(i))
                                call dqage(im_f,a,b,epsabs,epsrel,key,limit,           &
                                           im,params.im_abserr(i),params.im_neval(i),  &
                                           params.im_ier(i),alist,blist,rlist,elist,   &
                                           iord,im_last(i),input(i))
                                output(i) = re+I*im
                             end do

                   class default
                     stop "Invalid type in: laplacet_dqage"
                  end select
                        
          end subroutine laplacet_dqage
          

          
          subroutine laplacet_dqagp(re_f,im_f,a,b,npts2,points,epsabs,epsrel, &
                                    params,leniw,lenw,iwork,work,input,output)
                                      
                   !dir$ optimize:3
                   !dir$ attributes code_align : 32 :: laplacet_dqagp
                   use omp_lib
                   use quadpack, only : dqagp
                   implicit none
                   procedure(re_func)                                 :: re_f
                   procedure(im_func)                                 :: im_f
                   real(kind=dp),                      intent(in)     :: a
                   real(kind=dp),                      intent(in)     :: b
                   integer(kind=i4),                   intent(in)     :: npts2
                   real(kind=dp),   dimension(npts2),  intent(in)     :: points
                   real(kind=dp),                      intent(in)     :: epsabs
                   real(kind=dp),                      intent(in)     :: epsrel
                   type(l_qage_params),                intent(inout)  :: params
                   integer(kind=i4),                   intent(in)     :: leniw
                   integer(kind=i4),                   intent(in)     :: lenw
                   integer(kind=i4), dimension(leniw), intent(inout)  :: iwork
                   real(kind=dp),    dimension(lenw),  intent(inout)  :: work
                   class(*),         dimension(:),     intent(in)     :: input
                   complex(kind=dp), dimension(:),     intent(out)    :: output
                   ! Locals
                   complex(kind=dp), parameter :: I = cmplx(0.0_dp,1.0_dp)
                   real(kind=dp),    automatic :: re
                   real(kind=dp),    automatic :: im
                   integer(kind=i4), automatic :: i
                   ! Exec code ....
                   re = 0.0_dp
                   im = 0.0_dp
                   select type (input)
                       type is(real(kind=dp))
                         
                            do i=1, params.npts
                                call dqagp(re_f,a,b,npts2,points,epsabs,epsrel,        &
                                           re,params.re_abserr(i),params.re_neval(i),  &
                                           params.re_ier(i),leniw,lenw,re_last(i),iwork   &
                                           work,input(i))
                                call dqagp(im_f,a,b,npts2,points,epsabs,epsrel,        &
                                           im,params.im_abserr(i),params.im_neval(i),  &
                                           params.im_ier(i),leniw,lenw,re_last(i),     &
                                           iwork,work,input(i))
                                output(i) = re+I*im
                             end do

                        type is(complex(kind=dp))
                          
                             do i=1, params.npts
                                call dqage(re_f,a,b,epsabs,epsrel,key,limit,           &
                                           re,params.re_abserr(i),params.re_neval(i),  &
                                           params.re_ier(i),alist,blist,rlist,elist,   &
                                           iord,re_last(i),input(i))
                                call dqage(im_f,a,b,epsabs,epsrel,key,limit,           &
                                           im,params.im_abserr(i),params.im_neval(i),  &
                                           params.im_ier(i),alist,blist,rlist,elist,   &
                                           iord,im_last(i),input(i))
                                output(i) = re+I*im
                             end do

                   class default
                     stop "Invalid type in: laplacet_dqagp"
                  end select
                        
            end subroutine laplacet_dqagp


end module laplace_transform
