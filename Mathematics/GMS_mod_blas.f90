

module mod_blas


 !===================================================================================85
 !---------------------------- DESCRIPTION ------------------------------------------85
 !
 !
 !
 !          Module  name:
 !                         'mod_blas
 !          
 !          Purpose:
  !                      This module contains an explicitly vectorized complex
  !                      blas implementation, which is based on packed AoS
  !                      complex data type (AVX512c8f64_t).
 !
 !          History:
 !                        Date: 29-11-2019
 !                        Time: 10:41 GMT+2
 !                        
 !          Version:
 !
 !                      Major: 1
 !                      Minor: 0
 !                      Micro: 0
 !
 !          Author:  
 !                      Bernard Gingold
 !                      As per original authors request -- the name of the
 !                      modified subroutine/function was changed to include the 'gms' prefix.
 !                 
 !          References:
 !         
 !                            Based on LAPACK package
 !                            Copyright (c) 1992-2013 The University of Tennessee and The University
 !                            of Tennessee Research Foundation.  All rights
 !                            reserved.
 !                            Copyright (c) 2000-2013 The University of California Berkeley. All
 !                            rights reserved.
 !                            Copyright (c) 2006-2013 The University of Colorado Denver.  All rights
 !                            reserved.
 !
 !                            $COPYRIGHT$
 !
 !                            Additional copyrights may follow
 !         
 !          E-mail:
 !                  
 !                      beniekg@gmail.com
 !==================================================================================85
    ! Tab:5 col - Type and etc.. definitions
    ! Tab:10,11 col - Type , function and subroutine code blocks.

    use module_kinds, only : int4,dp
    use mod_avx512c8f64
    implicit none

     !=====================================================59
     !  File and module information:
     !  version,creation and build date, author,description
     !=====================================================59

    ! Major version
    integer(kind=int4), parameter, public :: MOD_BLAS_MAJOR = 1
    ! MInor version
    integer(kind=int4), parameter, public :: MOD_BLAS_MINOR = 0
    ! Micro version
    integer(kind=int4), parameter, public :: MOD_BLAS_MICRO = 0
    ! Module full version
    integer(kind=int4), parameter, public :: MOD_BLAS_FULLVER = &
         1000*MOD_BLAS_MAJOR+100*MOD_BLAS_MINOR+10*MOD_BLAS_MICRO
    !Module creation date
    character(*),       parameter, public :: MOD_BLAS_CREATION_DATE = "29-11-2019 10:55 +00200 (FRI 29 NOV 2019 GMT+2)"
    ! Module build date
    character(*),       parameter, public :: MOD_BLAS_BUILD_DATE    = __DATE__ " " __TIME__
    ! Module author info
    character(*)        parameter, public :: MOD_BLAS_AUTHOR = "LAPACK original authors[all rights reserved] -- This version was  modified by Bernard Gingold, contact: beniekg@gmail.com"
    ! Module short description
    character(*)        parameter, public :: MOD_BLAS_SYNOPSIS = "Explicitly vectorized complex  blas implementation, which is based on packed AoS complex data type (AVX512c8f64_t) "
                                                                  
    ! public

  contains

!*  Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date November 2017
!*
!*> \ingroup complex16_blas_level1
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>     jack dongarra, 3/11/78.
!*>     modified 12/3/93, array(1) declarations changed to array(*)
!       Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features)
!*> \endverbatim
!*>

    subroutine gms_zaxpy(n,za,zx,incx,zy,incy)
      
      !DIR$ ATTRIBUTES CODE_ALIGNED : 32 :: gms_zaxpy
      !DIR$ ATTRIBUTES VECTOR :: gms_zaxpy
      use mod_vecconsts, only : v8_n0
      integer(kind=int4),                intent(in)    :: n
      type(AVX512c8f64_t),               intent(in)    :: za
      type(AVX512c8f64_t), dimension(*), intent(in)    :: zx
      !DIR$ ASSUME_ALIGNED zx:64
      integer(kind=int4),                intent(in)    :: incx
      type(AVX512c8f64_t), dimension(*), intent(inout) :: zy
      !DIR$ ASSUME_ALIGNED zy:64
      integer(kind=int4),                intent(in)    :: incy
      ! Locals
      integer(kind=int4), automatic :: i,ix,iy
      ! EXec code .....
      if(n<=0) return
      if(all(cabs_zmm8c8(za) == v8_n0.v)) return
      if(incx==1 .and. incy==1) then
         ! *        code for both increments equal to 1
         !DIR$ VECTOR ALIGNED
         !DIR$ VECTOR ALWAYS
         do i = 1,n
            zy(i) = zy(i)+za*zx(i)
         end do

         !*        code for unequal increments or equal increments
         !*          not equal to 1
      else
         ix=1
         iy=1
         if(incx<0) ix=(-n+1)*incx+1
         if(incy<0) iy=(-n+1)*incy+1
         !DIR$ VECTOR ALIGNED
         !DIR$ VECTOR ALWAYS
         do i = 1,n
            zy(iy) = zy(iy)+za*zx(ix)
            ix = ix+incx
            iy = iy+incy
         end do
      end if
    end subroutine gms_zaxpy

!*  Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date November 2017
!*
!*> \ingroup complex16_blas_level1
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>     jack dongarra, linpack, 4/11/78.
!*>     modified 12/3/93, array(1) declarations changed to array(*)
!       Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features)    
!*> \endverbatim
!*>

    subroutine gms_zcopy(n,zx,incx,zy,incy)
      !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zcopy
      !DIR$ ATTRIBUTES VECTOR :: gms_zcopy
      integer(kind=int4),                intent(in)  :: n
      type(AVX512c8f64_t), dimension(*), intent(in)  :: zx
      !DIR$ ASSUME_ALIGNED zx:64
      integer(kind=int4),                intent(in)  :: incx
      type(AVX512c8f64_t), dimension(*), intent(out) :: zy
      integer(kind=dint4),               intent(in)  :: incy
      ! LOcals
      integer(kind=int4), automatic :: i,ix,iy
      ! EXec code ...
      if(n<=0) return
      if(incx==1 .and. incy==1) then
         
         !  code for both increments equal to 1
         !DIR$ VECTOR ALIGNED
         !DIR$ VECTOR ALWAYS
         do i = 1,n
            zy(i) = zx(i)
         end do

         !  code for unequal increments or equal increments
         !*          not equal to 1
       else
         ix=1
         iy=1
         if(incx<0) ix=(-n+1)*incx+1
         if(incy<0) iy=(-n+1)*incy+1
         !DIR$ VECTOR ALIGNED
         !DIR$ VECTOR ALWAYS
         do i = 1,n
            zy(iy) = zx(ix)
            ix = ix+incx
            iy = iy+incy
         end do
      end if
    end subroutine gms_zcopy

!     Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date November 2017
!*
!1*> \ingroup complex16_blas_level1
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>     jack dongarra, 3/11/78.
!*>     modified 12/3/93, array(1) declarations changed to array(*)
!       Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features)     
!*> \endverbatim
    
    function gms_zdotc(n,zx,incx,zy,incy) result(dotc)
      !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zdotc
      !DIR$ ATTRIBUTES VECTOR :: gms_zdotc
      integer(kind=int4),                intent(in) :: n
      type(AVX512c8f64_t), dimension(*), intent(in) :: zx
      !DIR$ ASSUME_ALIGNED zx:64
      integer(kind=int4),                intent(in) :: incx
      type(AVX512c8f64_t), dimension(*), intent(in) :: zy
      !DIR$ ASSUME_ALIGNED zy:64
      integer(kind=int4),                intent(in) :: incy
      !DIR$ ATTRIBUTES ALIGN : 64 :: dotc
      type(AVX512c8f64_t) :: dotc
      !DIR$ ATTRIBUTES ALIGN : 64 :: ztemp
      type(AVX512c8f64_t), automatic :: ztemp
      integer(kind=int4), automatic :: i,ix,iy
      ! EXec code ....
      !
      if(n<=0) return
      ztemp = default_init()
      if(incx==1 .and. incy==1) then
         !   code for both increments equal to 1
         
         !DIR$ VECTOR ALIGNED
         !DIR$ VECTOR ALWAYS
         do i = 1,n
            ztemp = ztemp+conjugate(zx(i))*zy(i)
         end do
      else
         !   code for unequal increments or equal increments
         !*          not equal to 1
         ix=1
         iy=1
         if(incx<0) ix=(-n+1)*incx+1
         if(incy<0) iy=(-n+1)*incy+1
         !DIR$ VECTOR ALIGNED
         !DIR$ VECTOR ALWAYS
         do i = 1,n
            ztemp = ztemp+conjugate(zx(ix))*zy(iy)
            ix = ix+incx
            iy = iy+incy
         end do
         zdotc = default_init()
      end if  
      zdotc = ztemp
    end function gms_zdotc

!     Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date November 2017
!*
!1*> \ingroup complex16_blas_level1
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>     jack dongarra, 3/11/78.
!*>     modified 12/3/93, array(1) declarations changed to array(*)
!       Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features)     
!*> \endverbatim

    function gms_zdotu(n,zx,incx,zy,incy) result(zdotu)
      !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zdotu
      !DIR$ ATTRIBUTES VECTOR :: gms_zdotu
      integer(kind=int4),                intent(in) :: n
      type(AVX512c8f64_t), dimension(*), intent(in) :: zx
      !DIR$ ASSUME_ALIGNED zx:64
      integer(kind=int4),                intent(in) :: incx
      type(AVX512c8f64_t), dimension(*), intent(in) :: zy
      !DIR$ ASSUME_ALIGNED zy:64
      integer(kind=int4),                intent(in) :: incy
      ! LOcals
      !DIR$ ATTRIBUTES ALIGN : 64 :: zdotu
      type(AVX512c8f64_t) :: zdotu
      !DIR$ ATTRIBUTES ALIGN : 64 :: ztemp
      type(AVX512c8f64_t), automatic :: ztemp
      integer(kind=int4),  automatic :: i,ix,iy
      ! Exec code ....
      if(n<=0) return
      ztemp = default_init()
      if(incx==1 .and. incy==1) then

         !  code for both increments equal to 1
         !DIR$ VECTOR ALIGNED
         !DIR$ VECTOR ALWAYS
         do i = 1,n
            ztemp = ztemp+zx(i)*zy(i)
         end do

         !  code for unequal increments or equal increments
         !*          not equal to 1
      else
         ix=1
         iy=1
         if(incx<0) ix=(-n+1)*incx+1
         if(incy<0) iy=(-n+1)*incy+1
         !DIR$ VECTOR ALIGNED
         !DIR$ VECTOR ALWAYS
         do i = 1,n
            ztemp = ztemp+zx(ix)*zy(iy)
            ix = ix+incx
            iy = iy+incy
         end do
      end if
      zdotu = default_init()
      zdotu = ztemp
    end function gms_zdotu

!    *
!*  Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*  Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features)     
!*> \date December 2016

    subroutine gms_zdrot(n,cx,incx,cy,incy,c,s)
      !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zdrot
      !DIR$ ATTRIBUTES VECTOR :: gms_zdrot
      use mod_vectypes, only : ZMM8r8_t
      integer(kind=int4),                intent(in)    :: n
      type(AVX512c8f64_t), dimension(*), intent(inout) :: cx
      !DIR$ ASSUME_ALIGNED cx:64
      integer(kind=int4),                intent(in)    :: incx
      type(AVX512c8f64_t), dimension(*), intent(inout) :: cy
      !DIR$ ASSUME_ALIGNED cy:64
      integer(kind=int4),                intent(in)    :: incy
      type(ZMM8r8_t),                    intent(in)    :: c ! scalar extended to vector
      !DIR$ ASSUME_ALIGNED c:64
      type(ZMM8r8_t),                    intent(in)    :: s ! scalar extended to vector
      !DIR$ ASSUME_ALIGNED s:64
      !DIR$ ATTRIBUTES ALIGN : 64 :: ztemp
      type(AVX512c8f64_t), automatic :: ztemp
      integer(kind=int4),  automatic :: i,ix,iy
      ! EXec code ...
      if(n<=0) return
      ctemp = default_init()
      if(incx==1 .and. incy==1) then
         !  code for both increments equal to 1
         !DIR$ VECTOR ALIGNED
         !DIR$ VECTOR ALWAYS
         do i = 1,n
            ctemp = c*cx(i)+s*cy(i)
            cy(i) = c*cy(i)-s*cx(i)
            cx(i) = ctemp
         end do

         !  code for unequal increments or equal increments not equal
         !*          to 1
      else
         ix=1
         iy=1
         if(incx<0) ix=(-n+1)*incx+1
         if(incy<0) iy=(-n+1)*incy+1
         !DIR$ VECTOR ALIGNED
         !DIR$ VECTOR ALWAYS
         do i = 1,n
            ctemp  = c*cx(ix)+s*cy(iy)
            cy(iy) = c*cy(iy)-s*cx(ix)
            cx(ix) = ctemp
            ix = ix+incx
            iy = iy+incy
         end do
       end if
    end subroutine gms_zdrot

!     Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date November 2017
!1*
!*> \ingroup complex16_blas_level1
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>     jack dongarra, 3/11/78.
!*>     modified 3/93 to return if incx .le. 0.
!*>     modified 12/3/93, array(1) declarations changed to array(*)
!       Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features)       
!*> \endverbatim

    subroutine gms_zdscal(n,da,zx,incx)
       !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zdscal
       !DIR$ ATTRIBUTES VECTOR :: gms_zdscal
       integer(kind=int4),                intent(in)    :: n
       type(AVX512c8f64_t),               intent(in)    :: da
       type(AVX512c8f64_t), dimension(*), intent(inout) :: zx
       !DIR$ ASSUME_ALIGNED zx:64
       integer(kind=int4),                intent(in)    :: incx
       ! LOcals
       integer(kind=int4), automatic :: i,nincx
       ! Exec code ....
       if(n<=0 .or. incx<0) return
       if(incx==1) then
          !  code for increment equal to 1
          !DIR$ VECTOR ALIGNED
          !DIR$ VECTOR ALWAYS
          do i = 1,n
             zx(i) = da*zx(i)
          end do
       else
          !   *        code for increment not equal to 1
          nincx=n*incx
          !DIR$ VECTOR ALIGNED
          !DIR$ VECTOR ALWAYS
          do i = 1,nincx,incx
             zx(i) = da*zx(i)
          end do
       end if
    end subroutine gms_zdscal

!    *> \date December 2016
!*
!*> \ingroup complex16_blas_level2
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>  Level 2 Blas routine.
!*>  The vector and matrix arguments are not referenced when N = 0, or M = 0
!*>
!*>  -- Written on 22-October-1986.
!*>     Jack Dongarra, Argonne National Lab.
!*>     Jeremy Du Croz, Nag Central Office.
!*>     Sven Hammarling, Nag Central Office.
!*>     Richard Hanson, Sandia National Labs.
!  Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features) 
!*> \endverbatim

    subroutine gms_zgbmv(trans,m,n,kl,ku,alpha,a,lda,x,incx,beta,y,incy)
        !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zgbmv
        !
        character(len=5),                      intent(in) :: trans
        integer(kind=int4),                    intent(in) :: m
        integer(kind=int4),                    intent(in) :: n
        integer(kind=int4),                    intent(in) :: kl
        integer(kind=int4),                    intent(in) :: ku
        type(AVX512c8f64_t),                   intent(in) :: alpha
        type(AVX512c8f64_t), dimension(lda,*), intent(in) :: a
        !DIR$ ASSUME_ALIGNED a:64
        integer(kind=int4),                    intent(in) :: lda
        type(AVX512c8f64_t), dimension(*),     intent(in) :: x
        !DIR$ ASSUME_ALIGNED x:64
        integer(kind=int4),                    intent(in) :: incx
        type(AVX512c8f64_t),                   intent(in) :: beta
        type(AVX512c8f64_t), dimension(*),     intent(inout) :: y
        integer(kind=int4),                    intent(in) :: incy
        ! LOcals
        !DIR$ ATTRIBUTES ALIGN : 64 :: temp
        type(AVX512c8f64_t), automatic :: temp
        !
        integer(kind=dp),    automatic :: i,info,ix,iy,j,jk,k,kup1,kx,ky,lenx,leny
        logical(kind=int4),  automatic :: noconj
        logical(kind=int1),  automatic :: beq0,aeq0,bneq0,aneq0,beq1,aeq1
        !DIR$ ATTRIBUTES ALIGN : 64 :: ONE
        type(AVX512c8f64_t), parameter :: ONE  = AVX512c8f64_t([1.0_dp,1.0_dp,1.0_dp,1.0_dp, &
                                                                1.0_dp,1.0_dp,1.0_dp,1.0_dp],&
                                                                [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp])
        !DIR$ ATTRIBUTES ALIGN : 64 :: ZERO
        type(AVX512c8f64_t), parameter :: ZERO = AVX512c8f64_t([0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp],&
                                                               [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp])
            
             
        ! EXec code ....
        info = 0
        if(.not.lsame(trans,'N') .and. .not.lsame(trans,'T') .and. &
           .not.lsame(trans,'C')) then
           info = 1
        else if(m<0) then
           info = 2
        else if(n<0) then
           info = 3
        else if(kl<0) then
           info = 4
        else if(ku<0) then
           info = 5
        else if(lda<(kl+ku+1)) then
           info = 8
        else if(incx==0) then
           info = 10
        else if(incy==0) then
           info = 13
        end if
        if(info/=0) then
           call xerbla('GMS_ZGBMV',info)
           return
        end if
        !  Quick return if possible.
        aeqz=all(alpha==ZERO)
        beq1=all(beta==ONE)
        if((m==0) .or. (n==0) .or. &
             ((aeqz) .and. (beq1))) return
        noconj = lsame(trans,'T')
        !  Set  LENX  and  LENY, the lengths of the vectors x and y, and set
        !*     up the start points in  X  and  Y.
        if(lsame(trans,'N')) then
           lenx = n
           leny = m
        else
           lenx = m
           leny = n
        end if
        if(incx>0) then
           kx = 1
        else
           kx = 1-(lenx-1)*incx
        end if
        if(incy>0) then
           ky = 1
        else
           ky = 1-(leny-1)*incy
        end if
        ! *     Start the operations. In this version the elements of A are
        ! *     accessed sequentially with one pass through the band part of A.
        ! *
        ! *     First form  y := beta*y.
        VCZERO = default_init()
        bneq1=all(beta/=ONE)
        beq0=all(beta==ZERO)
        if(bneq1) then
           if(incy==1) then
              if(beq0) then
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=1,leny
                    y(i) = ZERO
                 end do
              else
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=1,leny
                    y(i) = beta*y(i)
                 end do
              end if
           else
              iy=ky
              if(beq0) then
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=1,leny
                    y(iy) = ZERO
                    iy = iy+incy
                 end do
              else
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=1,leny
                    y(iy) = beta*y(iy)
                    iy = iy+incy
                 end do
              end if
           end if
        end if
        if(aeq0) return
        kup1 = ku+1
        if(lsame(trans,'N')) then
           !   Form  y := alpha*A*x + y.
           jx=kx
           if(incy==1) then
              do j=1,n
                 temp=alpha*x(jx)
                 k=kup1-j
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=max(1,j-ku),min(m,j+kl)
                    y(i) = y(i)+temp*a(k+1,j)
                 end do
                 jx = jx+incx
              end do
           else
              do j=1,n
                 temp=alpha*x(jx)
                 iy=ky
                 k=kup1-j
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=max(1,j-ku),min(m,j+kl)
                    y(iy) = y(iy)+temp*a(k+1,j)
                    iy=iy+incy
                 end do
                 jx=jx+incx
                 if(j>ku) ky=ky+incy
              end do
           end if
        else
           !  Form  y := alpha*A**T*x + y  or  y := alpha*A**H*x + y.
           jy=ky
           if(incx==1) then
              do j=1,n
                 temp=ZERO
                 k=kup1-j
                 if(noconj) then
                    !DIR$ VECTOR ALIGNED
                    !DIR$ SIMD REDUCTION(+:TEMP)
                    do i=max(1,j-ku),min(m,j+kl)
                       temp = temp+a(k+i,j)*x(i)
                    end do
                 else
                    !DIR$ VECTOR ALIGNED
                    !DIR$ SIMD REDUCTION(+:TEMP)
                    do i=,max(1,j-ku),min(m,j+kl)
                       temp = temp+conjugate(a(k+i,j))*x(i)
                    end do
                 end if
                 y(jy) = y(jy)+alpha*temp
                 jy=jy+incy
              end do
           else
              do j=1,n
                 temp=ZERO
                 ix=kx
                 k=kup1-j
                 if(noconj) then
                    !DIR$ VECTOR ALIGNED
                    !DIR$ SIMD REDUCTION(+:TEMP)
                    do i=max(1,j-ku),min(m,j+kl)
                       temp = temp+a(k+i,j)*x(ix)
                       ix = ix+incx
                    end do
                 else
                    !DIR$ VECTOR ALIGNED
                    !DIR$ SIMD REDUCTION(+:TEMP)
                    do i=max(1,j-ku),min(m,j+kl)
                       temp = temp+conjugate(a(k+i,j)*x(ix)
                       ix = ix+incx
                    end do
                 end if
                 y(jy) = y(jy)+alpha*temp
                 jy = jy+incy
                 if(j>ku) kx = kx+incx
              end do
           end if
        end if
        
    end subroutine gms_zgbmv

!    *  Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date December 2016
!*
!*> \ingroup complex16_blas_level3
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>  Level 3 Blas routine.
!*>
!1*>  -- Written on 8-February-1989.
!*>     Jack Dongarra, Argonne National Laboratory.
!*>     Iain Duff, AERE Harwell.
!*>     Jeremy Du Croz, Numerical Algorithms Group Ltd.
    !*>     Sven Hammarling, Numerical Algorithms Group Ltd.
!     Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features) 
!1*> \endverbatim
    !*>

    subroutine gms_zgemm(transa,transb,m,n,k,alpha,a,lda,b,ldb,beta,c,ldc)
       !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zgemm
       character(len=6),                      intent(in)    :: transa
       character(len=6),                      intent(in)    :: transb
       integer(kind=int4),                    intent(in)    :: m
       integer(kind=int4),                    intent(in)    :: n
       integer(kind=int4),                    intent(in)    :: k
       type(AVX512c8f64_t),                   intent(in)    :: alpha
       type(AVX512c8f64_t), dimension(lda,*), intent(in)    :: a
       !DIR$ ASSUME_ALIGNED a:64
       integer(kind=int4),                    intent(in)    :: lda
       type(AVX512c8f64_t), dimension(ldb,*), intent(in)    :: b
       !DIR$ ASSUME_ALIGNED b:64
       integer(kind=int4),                    intent(in)    :: ldb
       type(AVX512c8f64_t),                   intent(in)    :: beta
       type(AVX512c8f64_t), dimension(ldc,*), intent(inout) :: c
       !DIR$ ASSUME_ALIGNED c:64
       integer(kind=int4),                    intent(in)    :: ldc
       ! Locals
       !DIR$ ATTRIBUTES ALIGN : 64 :: temp
       type(AVX512c8f64_t), automatic :: temp
       integer(kind=int4),  automatic :: i,info,j,l,ncola,nrowa,nrowb
       logical(kind=int4),  automatic :: conja,conjb,nota,notb
       logical(kind=int1),  automatic :: aeq0,beq0,beq1,bneq1
       !DIR$ ATTRIBUTES ALIGN : 64 :: ONE
       type(AVX512c8f64_t), parameter :: ONE  = AVX512c8f64_t([1.0_dp,1.0_dp,1.0_dp,1.0_dp, &
                                                                1.0_dp,1.0_dp,1.0_dp,1.0_dp],&
                                                                [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp])
       !DIR$ ATTRIBUTES ALIGN : 64 :: ZERO
       type(AVX512c8f64_t), parameter :: ZERO = AVX512c8f64_t([0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp],&
                                                               [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp])
       ! EXec code ....
!      Set  NOTA  and  NOTB  as  true if  A  and  B  respectively are not
!*     conjugated or transposed, set  CONJA and CONJB  as true if  A  and
!*     B  respectively are to be  transposed but  not conjugated  and set
!*     NROWA, NCOLA and  NROWB  as the number of rows and  columns  of  A
!1*    and the number of rows of  B  respectively.
        nota  = lsame(transa,'N')
        notb  = lsame(transb,'N')
        conja = lsame(transa,'C')
        conjb = lsame(transb,'C')
        if(nota) then
          nrowa = m
          ncola = k
        else
          nrowa = k
          ncola = m
        end if
        if(notb) then
          nrowb = k
        else
          nrowb = n
        end if
        !    Test the input parameters.
        info = 0
        if((.not.nota) .and. (.not.conja) .and. &
           (.not.lsame(transa,'T'))) then
           info = 1
        else if((.not.notb) .and. (.not.conjb) .and. &
           (.not.lsame(transb,'T'))) then
           info = 2
        else if(m<0) then
           info = 3
        else if(n<0) then
           info = 4
        else if(k<0) then
           info = 5
        else if(lda < max(1,nrowa)) then
           info = 8
        else if(ldb < max(1,nrowb)) then
           info = 10
        else if(ldc < max(1,m)) then
           info = 13
        end if
        if(info/=0) then
           call xerbla('GMS_ZGEMM',info)
        end if
        aeq0 = all(alpha==ZERO)
        beq1 = all(beta==ONE)
        ! Early exit
        if((m==0) .or. (n==0) .or. &
             (((aeq0) .or. (k==0)) .and. (beq1))) return
        !   And when  alpha.eq.zero.
        beq0 = all(beta==ZERO)
        if(aeq0) then
           if(beq0) then
              do j=1,n
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=1,m
                    c(i,j) = ZERO
                 end do
              end do
           else
              do j=1,n
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=1,m
                    c(i,j) = beta*c(i,j)
                 end do
              end do
           end if
           return
        end if
        !  Start the operations.
        bneq1 = all(beta/=ONE)
        if(notb) then
           if(nota) then
              !  Form  C := alpha*A*B + beta*C.
              do j=1,n
                 if(beq0) then
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,m
                       c(i,j) = ZERO
                    end do
                 else if(bneq0) then
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,m
                       c(i,j) = beta*c(i,j)
                    end do
                 end if
                 do l=1,k
                    temp = alpha*b(l,j)
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,m
                       c(i,j) = c(i,j)+temp*a(i,l)
                    end do
                 end do
              end do
           else if(conja) then
              !   Form  C := alpha*A**H*B + beta*C.
              do j=1,n
                 do i=1,m
                    temp = ZERO
                    !DIR$ VECTOR ALIGNED
                    !DIR$ SIMD REDUCTION (+:TEMP)
                    do l=1,k
                       temp = temp+conjugate(a(l,i))*b(l,j)
                    end do
                    if(beq0) then
                       c(i,j) = alpha*temp
                    else
                       c(i,j) = alpha*temp+beta*c(i,j)
                    end if
                 end do
              end do
           else
              !  Form  C := alpha*A**T*B + beta*C
              do j=1,n
                 do i=1,m
                    temp = ZERO
                    !DIR$ VECTOR ALIGNED
                    !DIR$ SIMD REDUCTION (+:TEMP)
                    do l=1,k
                       temp = temp+a(l,i)*b(l,j)
                    end do
                    if(beq0) then
                       c(i,j) = alpha*temp
                    else
                       c(i,j) = alpha*temp+beta*c(i,j)
                    end if
                 end do
              end do
           end if
        else if(nota) then
               if(conjb) then
                 !  Form  C := alpha*A*B**H + beta*C.
                  do j=1,n
                     if(beq0) then
                        !DIR$ VECTOR ALIGNED
                        !DIR$ VECTOR ALWAYS
                        do i=1,m
                           c(i,j) = ZERO
                        end do
                     else if(bneq1) then
                        !DIR$ VECTOR ALIGNED
                        !DIR$ VECTOR ALWAYS
                        do i=1,m
                           c(i,j) = beta*c(i,j)
                        end do
                     end if
                     do l=1,k
                        temp = alpha*conjugate(b(j,l))
                        !DIR$ VECTOR ALIGNED
                        !DIR$ VECTOR ALWAYS
                        do i=1,m
                           c(i,j) = c(i,j)+temp*a(i,l)
                        end do
                     end do
                  end do
               else
                  !  Form  C := alpha*A*B**T + beta*C
                  do j=1,n
                     if(beq0) then
                        !DIR$ VECTOR ALIGNED
                        !DIR$ VECTOR ALWAYS
                        do i=1,m
                           c(i,j) = ZERO
                        end do
                     else if(bneq1) then
                        do i=1,m
                           c(i,j) = beta*c(i,j)
                        end do
                     end if
                     do l=1,k
                        temp = alpha*b(j,l)
                        !DIR$ VECTOR ALIGNED
                        !DIR$ VECTOR ALWAYS
                        do i=1,m
                           c(i,j) = c(i,j)+temp*a(i,l)
                        end do
                     end do
                  end do
               end if
            else if(conja) then
                  if(conjb) then
                     !   Form  C := alpha*A**H*B**H + beta*C.
                     do j=1,n
                        do i=1,m
                           temp = ZERO
                           !DIR$ VECTOR ALIGNED
                           !DIR$ SIMD REDUCTION(+:TEMP)
                           do l=1,k
                              temp = temp+conjugate(a(l,i))*conjugate(b(j,l))
                           end do
                           if(beq0) then
                              c(i,j) = alpha*temp
                           else
                              c(i,j) = alpha*temp+beta*c(i,j)
                           end if
                        end do
                     end do
                  else
                     !   Form  C := alpha*A**H*B**T + beta*C
                     do j=1,n
                        do i=1,m
                           temp = ZERO
                           !DIR$ VECTOR ALIGNED
                           !DIR$ SIMD REDUCTION(+:TEMP)
                           do l=1,k
                              temp = temp+conjugate(a(l,i))*b(j,l)
                           end do
                           if(beq0) then
                              c(i,j) = alpha*temp
                           else
                              c(i,j) = alpha*temp+beta*c(i,j)
                           end if
                        end do
                     end do
                  end if
               else
                  if(conjb) then
                     !  Form  C := alpha*A**T*B**H + beta*C
                     do j=1,n
                        do i=1,m
                           temp = ZERO
                           !DIR$ VECTOR ALIGNED
                           !DIR$ SIMD REDUCTION(+:TEMP)
                           do l=1,k
                              temp = temp+a(l,i)*conjugate(b(j,l))
                           end do
                           if(beq0) then
                              c(i,j) = alpha*temp
                           else
                              c(i,j) = alpha*temp+beta*c(i,j)
                           end if
                        end do
                     end do
                  else
                     !  Form  C := alpha*A**T*B**T + beta*C
                     do j=1,n
                        do i=1,m
                           temp = ZERO
                           !DIR$ VECTOR ALIGNED
                           !DIR$ SIMD REDUCTION(+:TEMP)
                           do l=1,k
                              temp = temp+a(l,i)*b(j,l)
                           end do
                           if(beq0) then
                              c(i,j) = alpha*temp
                           else
                              c(i,j) = alpha*temp+beta*c(i,j)
                           end if
                        end do
                     end do
                  end if
               end if
               ! End of GMS_ZGEMM
      end subroutine gms_zgemm

!       Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date December 2016
!*
!*> \ingroup complex16_blas_level2
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>  Level 2 Blas routine.
!*>  The vector and matrix arguments are not referenced when N = 0, or M = 0
!*>
!*>  -- Written on 22-October-1986.
!*>     Jack Dongarra, Argonne National Lab.
!*>     Jeremy Du Croz, Nag Central Office.
!*>     Sven Hammarling, Nag Central Office.
      !*>     Richard Hanson, Sandia National Labs.
      !  Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features) 
      !*> \endverbatim

      subroutine gms_zgemv(trans,m,n,alpha,a,lda,x,incx,beta,y,incy)
          !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zgmev
          character(len=1),                      intent(in) :: trans
          integer(kind=int4),                    intent(in) :: m
          integer(kind=int4),                    intent(in) :: n
          type(AVX512c8f64_t),                   intent(in) :: alpha
          type(AVX512c8f64_t), dimension(lda,*), intent(in) :: a
          !DIR$ ASSUME_ALIGNED a:64
          integer(kind=int4),                    intent(in) :: lda
          type(AVX512c8f64_t), dimension(*),     intent(in) :: x
          !DIR$ ASSUME_ALIGNED x:64
          integer(kind=int4),                    intent(in)    :: incx
          type(AVX512c8f64_t),                   intent(in)    :: beta
          type(AVX512c8f64_t), dimension(*),     intent(inout) :: y
          !DIR$ ASSUME_ALIGNED y:64
          integer(kind=int4),                    intent(in)    :: incy
          ! LOcals
          !DIR$ ATTRIBUTES ALIGN : 64 :: temp
          type(AVX512c8f64_t), automatic :: temp
          integer(kind=int4),  automatic :: i,info,ix,iy,j,jx.jy,kx,ky,lenx,leny
          logical(kind=int4),  automatic :: noconj
          logical(kind=int1),  automatic :: aeq0,beq1,bneq1,beq0
          !DIR$ ATTRIBUTES ALIGN : 64 :: ONE
          type(AVX512c8f64_t), parameter :: ONE  = AVX512c8f64_t([1.0_dp,1.0_dp,1.0_dp,1.0_dp, &
                                                                1.0_dp,1.0_dp,1.0_dp,1.0_dp],&
                                                                [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp])
          !DIR$ ATTRIBUTES ALIGN : 64 :: ZERO
          type(AVX512c8f64_t), parameter :: ZERO = AVX512c8f64_t([0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp],&
                                                               [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                               0.0_dp,0.0_dp,0.0_dp,0.0_dp])
          ! EXec code .....
          info = 0
          if(.not.lsame(trans,'N') .and. .not.lsame(trans,'T') .and. &
             .not.lsame(trans,'C')) then
             info = 1
          else if(m<0) then
             info = 2
          else if(n<0) then
             info = 3
          else if(lda < max(1,m)) then
             info = 6
          else if(incx==0) then
             info = 8
          else if(incy==0) then
             info = 11
          end if
          if(info/=0) then
             call xerbla('GMS_ZGEMV',info)
             return
          end if
          aeq0  = .false.
          beq1  = .false.
          bneq1 = .false.
          beq0  = .false.
          ! Quick return if possible.
          aeq0 = all(alpha==ZERO)
          beq1 = all(beta==ONE)
          if((m==0)  .or. (n==0) .or. &
               ((aeq0) .and. (beq1))) return
          noconj = lsame(trans,'T')
          !  Set  LENX  and  LENY, the lengths of the vectors x and y, and set
          !  *     up the start points in  X  and  Y.
          if (lsame(trans,'N')) then
             lenx = n
             leny = m
          else
             lenx = m
             leny = n
          end if
          if (incx>0) then
             kx = 1
          else
             kx = 1-(lenx-1)*incx
          end if
          if (incx>0) then
             ky = 1
          else
             ky = 1-(leny-1)*incy
          end if
          ! *     Start the operations. In this version the elements of A are
          ! *     accessed sequentially with one pass through A.
          ! *
          ! *     First form  y := beta*y.
          bneq1 = all(beta/=ONE)
          beq0  = all(beta==ZERO)
          if(bneq1) then
             if(incy==1) then
                 if(beq0)  then
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,leny
                       y(i) = ZERO
                    end do
                 else
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,leny
                       y(i) = beta*leny(i)
                    end do
                 end if
              else
                 iy = ky
                 if(beq0) then
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,leny
                       y(iy) = ZERO
                       iy = iy+incy
                    end do
                 else
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,leny
                       y(iy) = beta*y(iy)
                       iy = iy+incy
                    end do
                 end if
              end if
           end if
           if(aeq0) return
           if(lsame(trans,'N')) then
              ! Form  y := alpha*A*x + y.
              jx = kx
              if(incy==1) then
                 do j=1,n
                    temp = alpha*x(jx)
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,m
                       y(i) = y(i)+temp*a(i,j)
                    end do
                    jx = jx+incx
                 end do
              else
                 do j=1,n
                    temp = alpha*x(jx)
                    iy = ky
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,m
                       y(iy) = y(iy)+temp*a(i,j)
                       iy = iy+incy
                    end do
                    jx = jx+incx
                 end do
              end if
           else
              !  Form  y := alpha*A**T*x + y  or  y := alpha*A**H*x + y.
              jy = ky
              if(incx==1) then
                 do j=1,n
                    temp = zero
                    if(noconj) then
                       !DIR$ VECTOR ALIGNED
                       !DIR$ SIMD REDUCTION(+:temp)
                       do i=1,m
                          temp = temp+a(i,j)*x(i)
                       end do
                    else
                       !DIR$ VECTOR ALIGNED
                       !DIR$ SIMD REDUCTION(+:temp)
                       do i=1,m
                          temp = temp+conjugate(a(i,j))*x(i)
                       end do
                    end if
                    y(jy) = y(jy)+alpha*temp
                    jy = jy+incy
                 end do
              else
                 do j=1,n
                    temp = zero
                    ix = ky
                    if (noconj) then
                       !DIR$ VECTOR ALIGNED
                       !DIR$ SIMD REDUCTION(+:temp)
                       do i=1,m
                          temp = temp+a(i,j)*x(ix)
                          ix = ix+incx
                       end do
                    else
                       !DIR$ VECTOR ALIGNED
                       !DIR$ SIMD REDUCTION(+:temp)
                       do i=1,m
                          temp = temp+conjugate(a(i,j))*x(ix)
                          ix = ix+incx
                       end do
                    end if
                       y(jy) = y(jy)+alpha*temp
                       jy = jy+incy
                  end do
               end if
            end if
            ! End of ZGEMV
     end subroutine gms_zgemv

!      Authors:
!1*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date December 2016
!*
!*> \ingroup complex16_blas_level2
!*
!*> \par Further Details:
!1*  =====================
!*>
!*> \verbatim
!*>
!*>  Level 2 Blas routine.
!*>
!*>  -- Written on 22-October-1986.
!1*>     Jack Dongarra, Argonne National Lab.
!1*>     Jeremy Du Croz, Nag Central Office.
!*>     Sven Hammarling, Nag Central Office.
     !*>     Richard Hanson, Sandia National Labs.
     !   Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features) 
!*> \endverbatim
     !*>

     subroutine gms_zgerc(m,n,alpha,x,incx,y,incy,a,lda)
        !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zgerc
        integer(kind=int4),                    intent(in)    :: m
        integer(kind=int4),                    intent(in)    :: n
        type(AVX512c8f64_t),                   intent(in)    :: alpha
        type(AVX512c8f64_t), dimension(*),     intent(in)    :: x
        !DIR$ ASSUME_ALIGNED x:64
        integer(kind=int4),                    intent(in)    :: incx
        type(AVX512c8f64_t), dimension(*),     intent(in)    :: y
        !DIR$ ASUME_ALIGNED y:64
        integer(kind=int4),                    intent(in)    :: incy
        type(AVX512c8f64_t), dimension(lda,*), intent(inout) :: a
        !DIR$ ASSUME_ALIGNED a:64
        integer(kind=int4),                    intent(in)    :: lda
        ! Locals
        !DIR$ ATTRIBUTES ALIGN : 64 :: temp
        type(AVX512c8f64_t), automatic :: temp
        integer(kind=int4),  automatic :: i,info,ix,j,jy,kx
        logical(kind=int1),  automatic :: aeq0
        !DIR$ ATTRIBUTES ALIGN : 64 :: ZERO
        type(AVX512c8f64_t), parameter :: ZERO = AVX512c8f64_t([0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp],&
                                                               [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                               0.0_dp,0.0_dp,0.0_dp,0.0_dp])
        ! EXec code .....
        info = 0
        if(m<0) then
           info = 1
        else if(n<0) then
           info = 2
        else if(incx==0) then
           info = 5
        else if(incy==0) then
           info = 7
        else if(lds < max(1,m)) then
           info = 9
        end if
        if(info/=0) then
           call xerbla('ZGERC',info)
           return
        end if
        !  Quick return if possible.
        aeq0 = .false.
        aeq0 = all(alpha==ZERO)
        if((m==0) .or. (n==0) .or. (aeq0)) return
        ! Start the operations. In this version the elements of A are
        ! *     accessed sequentially with one pass through A.
        if(incy>0) then
           jy = 1
        else
           jy = 1-(n-1)*incy
        end if
        if(incx==1) then
           do j=1,n
              if(all(y(jy)/=ZERO)) then
                 temp = alpha*conjugate(y(jy))
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=1,m
                    a(i,j) = a(i,j)+x(i)*temp
                 end do
              end if
              jy = jy+incy
           end do
        else
           if(incx>0) then
              kx = 1
           else
              kx = 1-(m-1)*incx
           end if
           do j=1,n
              if(all(y(jy)/=ZERO)) then
                 temp = alpha*conjugate(y(jy))
                 ix = kx
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=1,m
                    a(i,j) = a(i,j)+x(ix)*temp
                    ix = ix+incx
                 end do
              end if
              jy = jy+incy
           end do
        end if
        ! End of zgerc
     end subroutine gms_zgerc

!      Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date December 2016
!1*
!*> \ingroup complex16_blas_level2
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>  Level 2 Blas routine.
!*>
!*>  -- Written on 22-October-1986.
!*>     Jack Dongarra, Argonne National Lab.
!*>     Jeremy Du Croz, Nag Central Office.
!*>     Sven Hammarling, Nag Central Office.
     !*>     Richard Hanson, Sandia National Labs.
     !   Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features) 
     !*> \endverbatim

     subroutine gms_zgeru(m,n,alpha,x,incx,y,incy,a,lda)
        !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zgeru
        integer(kind=int4),                    intent(in)    :: m
        integer(kind=int4),                    intent(in)    :: n
        type(AVX512c8f64_t),                   intent(in)    :: alpha
        type(AVX512c8f64_t), dimension(*),     intent(in)    :: x
        !DIR$ ASSUME_ALIGNED x:64
        integer(kind=int4),                    intent(in)    :: incx
        type(AVX512c8f64_t), dimension(*),     intent(in)    :: y
        !DIR$ ASSUME_ALIGNED y:64
        integer(kind=int4),                    intent(in)    :: incy
        type(AVX512c8f64_t), dimension(lda,*), intent(inout) :: a
        integer(kind=int4),                    intent(in)    :: lda
        ! Locals
        !DIR$ ATTRIBUTES ALIGN : 64 :: temp
        type(AVX512c8f64_t), automatic :: temp
        integer(kind=int4),  automatic :: i,info,ix,j,jy,kx
        logical(kind=int1),  automatic :: aeq0
        !DIR$ ATTRIBUTES ALIGN : 64 :: ZERO
        type(AVX512c8f64_t), parameter :: ZERO = AVX512c8f64_t([0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp],&
                                                               [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                               0.0_dp,0.0_dp,0.0_dp,0.0_dp])
        !  Test the input parameters.
        info = 0
        aeq0 = .false.
        if(m<0) then
           info = 1
        else if(n<0) then
           info = 2
        else if(incx==0) then
           info = 5
        else if(incy==0) then
           info = 7
        else if(lda < max(1,m)) then
           info = 9
        end if
        if(info/=0) then
           call xerbla('GMS_ZGERU',info)
           return
        end if
        !  Quick return if possible.
        aeq0 = all(alpha==ZERO)
        if((m==0) .or. (n==0) .or. (aeq0)) return
        !   Start the operations. In this version the elements of A are
        ! *     accessed sequentially with one pass through A.
        if(incy>0) then
           jy = 1
        else
           jy = 1-(n-1)*incy
        end if
        if(incx==1) then
           do j=1,n
              if(all(y(jy)/=ZERO)) then
                 temp = alpha*y(jy)
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=1,m
                    a(i,j) = a(i,j)+x(i)*temp
                 end do
              end if
              jy = jy+incy
           end do
        else
           if(incx>0) then
              kx=1
           else
              kx = 1-(m-1)*incx
           end if
           do j=1,n
              if(all(y(jy)/=ZERO)) then
                 temp = alpha*y(jy)
                 ix = kx
                 !DIR$ VECTOR ALIGNED
                 !DIR$ VECTOR ALWAYS
                 do i=1,m
                    a(i,j) = a(i,j)+x(ix)*temp
                    ix = ix+incx
                 end do
              end if
              jy = jy+incy
           end do
        end if
        ! End of ZGERU
     end subroutine gms_zgeru

     subroutine gms_zhbmv(uplo,n,k,alpha,a,lda,x,incx,beta,y,incy)
        !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zhbmv
        character(len=1),                      intent(in)    :: uplo
        integer(kind=int4),                    intent(in)    :: n
        integer(kind=int4),                    intent(in)    :: k
        type(AVX512c8f64_t),                   intent(in)    :: alpha
        type(AVX512c8f64_t), dimension(lda,*), intent(in)    :: a
        !DIR$ ASSUME_ALIGNED a:64
        integer(kind=int4),                    intent(in)    :: lda
        type(AVX512c8f64_t), dimension(*),     intent(in)    :: x
        !DIR$ ASSUME_ALIGNED x:64
        integer(kind=int4),                    intent(in)    :: incx
        type(AVX512c8f64_t),                   intent(in)    :: beta
        type(AVX512c8f64_t), dimension(*),     intent(inout) :: y
        !DIR$ ASSUME_ALIGNED y:64
        integer(kind=int4),                    intent(in)    :: incy
        ! Locals
        !DIR$ ATTRIBUTES ALIGN : 64 :: temp1
        type(AVX512c8f64_t), automatic :: temp1
        !DIR$ ATTRIBUTES ALIGN : 64 :: temp2
        type(AVX512c8f64_t), automatic :: temp2
        integer(kind=int4),  automatic :: i,info,ix,iy,j,jx,jy,kplus1,kx,ky,l
        logical(kind=int1),  automatic :: aeq0,beq1,beq0,bneq1
        !DIR$ ATTRIBUTES ALIGN : 64 :: ONE
        type(AVX512c8f64_t), parameter :: ONE  = AVX512c8f64_t([1.0_dp,1.0_dp,1.0_dp,1.0_dp, &
                                                                1.0_dp,1.0_dp,1.0_dp,1.0_dp],&
                                                                [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp])
        !DIR$ ATTRIBUTES ALIGN : 64 :: ZERO
        type(AVX512c8f64_t), parameter :: ZERO = AVX512c8f64_t([0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp],&
                                                               [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                               0.0_dp,0.0_dp,0.0_dp,0.0_dp])
        ! EXec code ....
        ! Test the input parameters.
        
        info = 1
        if(.not.lsame(uplo,'U') .and. .not.lsame(uplo,'L')) then
           info = 1
        else if(n<0) then
           info = 2
        else if(k<0) then
           info = 3
        else if(lda<(k+1)) then
           info = 6
        else if(incx==0) then
           info = 8
        else if(incy==0) then
           info = 11
        end if
        if(info/=0) then
           call xerbla('GMS_ZHBMV',info)
           return
        end if
        ! Quick return if possible
        aeq0 = .false.
        beq1 = .false.
        aeq0 = all(alpha==ZERO)
        beq1 = all(beta==ONE)
        if((n==0) .or. ((aeq0) .and. (beq1))) return
        !  Set up the start points in  X  and  Y.
        if(incx>0) then
           kx = 1
        else
           kx = 1-(n-1)*incx
        end if
        if(incy>0) then
           ky = 1
        else
           ky = 1-(n-1)*incx
        end if
!      Start the operations. In this version the elements of the array A
!*     are accessed sequentially with one pass through A.
!*
        !1*     First form  y := beta*y.
        bneq1 = .false.
        beq0  = .false.
        bneq1 = all(beta/=ONE)
        beq0  = all(beta==ZERO)
        if(bneq1) then
           if(incy==1) then
                if(beq0) then
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=1,n
                      y(i) = ZERO
                   end do
                else
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=1,m
                      y(i) = beta*y(i)
                   end do
                end if
             else
                iy = ky
                if(beq0) then
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=1,n
                      y(iy) = ZERO
                      iy = iy+incy
                   end do
                else
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=1,n
                      y(iy) = beta*y(iy)
                      iy = iy+incy
                   end do
                end if
             end if
          end if
          if(aeq0) return
          if(lsame(uplo,'U')) then
             !  Form  y  when upper triangle of A is stored.
             kplus1 = k+1
             if((incx==1) .and. (incy==1)) then
                do j=1,n
                   temp1 = alpha*x(j)
                   temp2 = ZERO
                   l = kplus1-j
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do u=max(1,j-k),j-1
                      y(i) = y(i)+temp1*a(l+i,j)
                      temp2 = temp2+conjugate(a(l+i,j))*x(i)
                   end do
                   y(j) = y(j)+temp1*a(kplus1,j).re+alpha*temp2
                end do
             else
                jx = kx
                jy = ky
                do j=1,n
                   temp1 = alpha*x(jx)
                   temp2 = ZERO
                   ix = kx
                   iy = ky
                   l = kplus1-j
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=max(1,j-k),j-1
                      y(iy) = y(iy)+temp1*a(l+i,j)
                      temp2 = temp2+conjugate(a(l+i,j))*x(ix)
                      ix = ix+incx
                      iy = iy+incy
                   end if
                   y(jy) = y(jy)+temp1*a(kplus1,j).re+alpha*temp2
                   jx = jx+incx
                   jy = jy+incy
                   if(j>k) then
                      kx = kx+incx
                      ky = ky+incy
                   end if
                end do
             end if
          else
             !  Form  y  when lower triangle of A is stored.
             if((incx==1) .and. (incy==1)) then
                do j=1,n
                   temp1 = alpha*x(j)
                   temp2 = ZERO
                   y(j) = y(j)+temp1*a(1,j).re
                   l = 1-j
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=j+1,min(n,j+k)
                      y(i) = y(i)+temp1*a(l+i,j)
                      temp2 = temp2+conjugate(a(l+i,j))*x(i)
                   end do
                   y(j) = y(j)+alpha*temp2
                end do
             else
                jx = kx
                jy = ky
                do j=1,n
                   temp1 = alpha*x(jx)
                   temp2 = ZERO
                   y(jy) = y(jy)+temp1*a(1,j).re
                   l = 1-j
                   ix = jx
                   iy = jy
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=j+1,min(n,j+k)
                      ix = ix+incx
                      iy = iy+incy
                      y(iy) = y(iy) + temp1*a(l+i,j)
                      temp2 = temp2+conjugate(a(l+i,j))*x(ix)
                   end do
                   y(jy) = y(jy)+alpha*temp2
                   jx = jx+incx
                   jy = jy+incy
                end do
             end if
          end if
          ! End of zhbmv
      end subroutine gms_zhbmv

!        Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date December 2016
!*
!*> \ingroup complex16_blas_level3
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>  Level 3 Blas routine.
!*>
!*>  -- Written on 8-February-1989.
!*>     Jack Dongarra, Argonne National Laboratory.
!*>     Iain Duff, AERE Harwell.
!*>     Jeremy Du Croz, Numerical Algorithms Group Ltd.
      !*>     Sven Hammarling, Numerical Algorithms Group Ltd.
      !Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features) 
!*> \endverbatim
!*>
     !*  =====================================================================

      subroutine gms_zhemm(side,uplo,m,n,alpha,a,lda,b,ldb,beta,c,ldc)
          !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zhemm
          character(len=1),                      intent(in)    :: side
          character(len=1),                      intent(in)    :: uplo
          integer(kind=int4),                    intent(in)    :: m
          integer(kind=int4),                    intent(in)    :: n
          type(AVX512c8f64_t),                   intent(in)    :: alpha
          type(AVX512c8f64_t), dimension(lda,*), intent(in)    :: a
          !DIR$ ASSUME_ALIGNED a:64
          integer(kind=int4),                    intent(in)    :: lda
          type(AVX512c8f64_t), dimension(ldb,*), intent(in)    :: b
          !DIR$ ASSUME_ALIGNED b:64
          integer(kind=int4),                    intent(in)    :: ldb
          type(AVX512c8f64_t),                   intent(in)    :: beta
          type(AVX512c8f64_t), dimension(ldc,*), intent(inout) :: c
          !DIR$ ASSUME_ALIGNED c:64
          integer(kind=int4),                    intent(in)    :: ldc
          ! LOcals
          !DIR$ ATTRIBUTES ALIGN : 64 :: temp1,temp2
          type(AVX512c8f64_t), automatic :: temp1,temp2
          integer(kind=int4),  automatic :: i,info,j,k,nrowa
          logical(kind=int4),  automatic :: upper
          logical(kind=int1),  automatic :: aeq0,beq1,beq0
          !DIR$ ATTRIBUTES ALIGN : 64 :: ONE
          type(AVX512c8f64_t), parameter :: ONE  = AVX512c8f64_t([1.0_dp,1.0_dp,1.0_dp,1.0_dp, &
                                                                1.0_dp,1.0_dp,1.0_dp,1.0_dp],&
                                                                [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp])
          !DIR$ ATTRIBUTES ALIGN : 64 :: ZERO
          type(AVX512c8f64_t), parameter :: ZERO = AVX512c8f64_t([0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp],&
                                                               [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                               0.0_dp,0.0_dp,0.0_dp,0.0_dp])
          ! EXec code ....
          !  Set NROWA as the number of rows of A.
          if(lsame(side,'L')) then
             nrowa = m
          else
             nrowa = n
          end if
          upper = lsame(uplo,'U')
          !  Test the input parameters.
          aeq0 = .false.
          beq1 = .false.
          beq0 = .false.
          info = 0
          if((.not.lsame(side,'L')) .and. (.not.lsame(side,'R'))) then
             info = 1
          else if((.not.upper) .and. (not.lsame(uplo,'L'))) then
             info = 2
          else if(m<0) then
             info = 3
          else if(n<0) then
             info = 4
          else if(lda < max(1,nrowa)) then
             info = 7
          else if(ldb < max(1,m)) then
             info = 9
          else if(ldc < max(1,m)) then
             info = 13
          end if
          if(info/=0) then
             call xerbla('GMS_ZHEMM',info)
             return
          end if
          !  Quick return if possible.
          aeq0 = all(alpha==ZERO)
          beq1 = all(beta==ONE)
          if((m==0) .or. (n==0) .or. &
               ((aeq0) .and. (beq1))) return
          !  And when  alpha.eq.zero.
          beq0 = all(beta==ZERO)
          if(aeq0) then
             if(beq0) then
                do j=1,n
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=1,m
                      c(i,j) = ZERO
                   end do
                end do
             else
                do j=1,n
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=1,m
                      c(i,j) = beta*c(i,j)
                   end do
                end do
             end if
             return
          end if
          !  Start the operations.
          if(lsame(side,'L')) then
             !  Form  C := alpha*A*B + beta*C.
             if(upper) then
                do j=1,n
                   do i=1,m
                      temp1 = alpha*b(i,j)
                      temp2 = ZERO
                      !DIR$ VECTOR ALIGNED
                      !DIR$ SIMD REDUCTION(+:temp2)
                      do k=1,i-1
                         c(k,j) = c(k,j)+temp1*a(k,i)
                         temp2 = temp2+b(k,j)*conjugate(a(k,i))
                      end do
                      if(beq0) then
                         c(i,j) = temp1*a(i,i).re+alpha*temp2
                      else
                         c(i,j) = beta*c(i,j)+temp1*a(i,i).re+ &
                              alpha*temp2
                      end if
                   end do
                end do
             else
                do j=1,n
                   do i=m,1,-1
                      temp1 = alpha*b(i,j)
                      temp2 = ZERO
                      !DIR$ VECTOR ALIGNED
                      !DIR$ SIMD REDUCTION(+:temp2)
                      do k=i+1,m
                         c(k,j) = c(k,j)+temp1*a(k,i)
                         temp2 = temp2+b(k,j)*conjugate(a(k,i))
                      end do
                      if(beq0) then
                         c(i,j) = temp1*a(i,i).re+alpha*temp2
                      else
                         c(i,j) = beta*c(i,j)+temp1*a(i,i).re + &
                              alpha*temp2
                      end if
                   end do
                end do
             end if
          else
             !   Form  C := alpha*B*A + beta*C.
             do j=1,n
                temp1 = alpha*a(j,j).re
                if(beq0) then
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=1,m
                      c(i,j) = temp*b(i,j)
                   end do
                else
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=1,m
                      c(i,j) = beta*c(i,j)+temp1*b(i,j)
                   end do
                end if
                do k=1,j-1
                   if(upper) then
                      temp1 = alpha*a(k,j)
                   else
                      temp1 = alpha*conjugate(a(j,k))
                   end if
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=1,m
                      c(i,j) = c(i,j)+temp1*b(i,k)
                   end do
                end do
                do k=j+1,n
                   if(upper) then
                      temp1 = alpha*conjugate(a(j,k))
                   else
                      temp1 = alpha*a(k,j)
                   end if
                   !DIR$ VECTOR ALIGNED
                   !DIR$ VECTOR ALWAYS
                   do i=1,m
                      c(i,j) = c(i,j)+temp1*b(i,k)
                   end do
                end do
             end do
          end if
          !End of ZHEMM
     end subroutine gms_zhemm

!      Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date December 2016
!*
!*> \ingroup complex16_blas_level2
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>  Level 2 Blas routine.
!*>  The vector and matrix arguments are not referenced when N = 0, or M = 0
!*>
!*>  -- Written on 22-October-1986.
!*>     Jack Dongarra, Argonne National Lab.
!*>     Jeremy Du Croz, Nag Central Office.
!*>     Sven Hammarling, Nag Central Office.
     !*>     Richard Hanson, Sandia National Labs.
     !!Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features) 
!*> \endverbatim
     !*>

     subroutine gms_zhemv(uplo,n,alpha,a,lda,x,incx,beta,y,incy)
         !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zhemv
        character(len=1),                       intent(in)    :: uplo
        integer(kind=int4),                     intent(in)    :: n
        type(AVX512c8f64_t),                    intent(in)    :: alpha
        type(AVX512c8f64_t), dimension(lda,*),  intent(in)    :: a
        !DIR$ ASSUME_ALIGNED a:64
        integer(kind=int4),                     intent(in)    :: lda
        type(AVX512c8f64_t), dimension(*),      intent(in)    :: x
        !DIR$ ASSUME_ALIGNED x:64
        integer(kind=int4),                     intent(in)    :: incx
        type(AVX512c8f64_t),                    intent(in)    :: beta
        type(AVX512c8f64_t), dimension(*),      intent(inout) :: y
        integer(kind=int4),                     intent(in)    :: incy
        ! Locals
        !DIR$ ATTRIBUTES ALIGN : 64 :: temp1
        type(AVX512c8f64_t), automatic :: temp1
        !DIR$ ATTRIBUTES ALIGN : 64 :: temp2
        type(AVX512c8f64_t), automatic :: temp2
        integer(kind=int4),  automatic :: i,info,ix,iy,j,jx,jy,kx,ky
        logical(kind=int1),  automatic :: aeq0,beq1,bneq1
        !DIR$ ATTRIBUTES ALIGN : 64 :: ONE
        type(AVX512c8f64_t), parameter :: ONE  = AVX512c8f64_t([1.0_dp,1.0_dp,1.0_dp,1.0_dp, &
                                                                1.0_dp,1.0_dp,1.0_dp,1.0_dp],&
                                                                [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp])
        !DIR$ ATTRIBUTES ALIGN : 64 :: ZERO
        type(AVX512c8f64_t), parameter :: ZERO = AVX512c8f64_t([0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp],&
                                                               [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                               0.0_dp,0.0_dp,0.0_dp,0.0_dp])
        !  Test the input parameters.
        info  = 0
        aeq0  = .false.
        beq1  = .false.
        bneq1 = .false.
        if(.not.lsame(uplo,'U') .and. .not.lsame(uplo,'L')) then
           info = 1
        else if(n<0) then
           info = 2
        else if(lda < max(n,n)) then
           info = 5
        else if(incx==0) then
           info = 7
        else if(incy==0) then
           info = 10
        end if
        if(info/=0) then
           call xerbla('GMS_ZHEMV',info)
           return
        end if
        aeq0 = all(alpha==ZERO)
        beq1 = all(beta==ONE)
        !   Quick return if possible.
        if((n==0) .or. ((aeq0) .and. (beq1))) return
        !   Set up the start points in  X  and  Y.
        if(incx>0) then
           kx = 1
        else
           kx = 1-(n-1)*incx
        end if
        if(incy>0) then
           ky = 1
        else
           ky = 1-(n-1)*incy
        end if
        !  Start the operations. In this version the elements of A are
        !*     accessed sequentially with one pass through the triangular part
        !*     of A.
        !*
        bneq1 = all(beta/=ONE)
        !*     First form  y := beta*y.
        if(bneq1) then
           if(incy==1) then
                 if(beq0) then
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,n
                       y(i) = ZERO
                    end do
                 else
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,n
                       y(i) = beta*y(i)
                    end do
                 end if
              else
                 iy = ky
                 if(beq0) then
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,n
                       y(iy) = ZERO
                       iy = iy+incy
                    end do
                 else
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,n
                       y(iy) = beta*y(iy)
                       iy = iy+incy
                    end do
                 end if
              end if
           end if
           if(aeq0) return
           if(lsame(uplo,'U')) then
              !Form  y  when A is stored in upper triangle.
              if((incx==1) .and. (incy==1)) then
                 do j=1,n
                    temp1 = alpha*x(j)
                    temp2 = ZERO
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    !DIR$ SIMD REDUCTION(+:temp2)
                    do i=1,j-1
                       y(i) = y(i)+temp1*a(i,j)
                       temp2 = temp2+conjugate(a(i,j))*x(i)
                    end do
                    y(j) = y(j)+temp1*a(j,j).re+alpha*temp2
                 end do
              else
                 jx = kx
                 jy = ky
                 do j=1,n
                    temp1 = alpha*x(jx)
                    temp2 = ZERO
                    ix = kx
                    iy = ky
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    !DIR$ SIMD REDUCTION(+:temp2)
                    do i=1,j-1
                       y(iy) = y(iy)+temp1*a(i,j)
                       temp2 = temp2+conjugate(a(i,j))*x(ix)
                       ix = ix+incx
                       iy = iy+incy
                    end do
                    y(jy) = y(jy)+temp1*a(j,j).re+alpha*temp2
                    jx = jx+incx
                    jy = jy+incy
                 end do
              end if
           else
              !  Form  y  when A is stored in lower triangle.
              if((incx==1) .and. (incy==1)) then
                 do j=1,n
                    temp1 = alpha*x(j)
                    temp2 = ZERO
                    y(j) = y(j)+temp1*a(j,j).re
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    !DIR$ SIMD REDUCTION(+:temp2)
                    do i=j+1,n
                       y(i) = y(i)+temp1*a(i,j)
                       temp2 = temp2+conjugate(a(i,j))*x(i)
                    end do
                    y(j) = y(j)+alpha*temp2
                 end do
              else
                 jx = kx
                 jy = ky
                 do j=1,n
                    temp1 = alpha*x(jx)
                    temp2 = ZERO
                    y(jy) = y(jy)+temp1*a(j,j).re
                    ix = jx
                    iy = jy
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    !DIR$ SIMD REDUCTION(+:temp2)
                    do i=j+1,n
                       ix = ix+incx
                       iy = iy+incy
                       y(iy) = y(iy)+temp1*a(i,j)
                       temp2 = temp2+conjugate(a(i,j))*x(ix)
                    end do
                    y(jy) = y(jy)+alpha*temp2
                    jx = jx+incx
                    jy = jy+incy
                 end do
              end if
           end if
           !End of ZHEMV
     end subroutine gms_zhemv

!      Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date December 2016
!*
!*> \ingroup complex16_blas_level2
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!*>
!*>  Level 2 Blas routine.
!*>
!1*>  -- Written on 22-October-1986.
!*>     Jack Dongarra, Argonne National Lab.
!*>     Jeremy Du Croz, Nag Central Office.
!*>     Sven Hammarling, Nag Central Office.
     !*>     Richard Hanson, Sandia National Labs.
     ! !!Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features) 
!*> \endverbatim
!*>
     subroutine gms_zher(uplo,n,alpha,x,incx,a,lda)
        !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zher
        character(len=1),                      intent(in)    :: uplo
        integer(kind=int4),                    intent(in)    :: n
        type(ZMM8r4_t),                        intent(in)    :: alpha
        type(AVX512c8f64_t), dimension(*),     intent(in)    :: x
        !DIR$ ASSUME_ALIGNED x:64
        integer(kind=int4),                    intent(in)    :: incx
        type(AVX512c8f64_t), dimension(lda,*), intent(inout) :: a
        !DIR$ ASSUME_ALIGNED a:64
        integer(kind=int4),                    intent(in)    :: lda
        ! Locals
        !DIR$ ATTRIBUTES ALIGN : 64 :: temp
        type(AVX512c8f64_t), automatic :: temp
        integer(kind=int4),  automatic :: i,info,ix,j,jx,kx
        logical(kind=int1),  automatic :: aeq0
        !
        !DIR$ ATTRIBUTES ALIGN : 64 :: ZERO
        type(AVX512c8f64_t), parameter :: ZERO = AVX512c8f64_t([0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                                0.0_dp,0.0_dp,0.0_dp,0.0_dp],&
                                                               [0.0_dp,0.0_dp,0.0_dp,0.0_dp, &
                                                               0.0_dp,0.0_dp,0.0_dp,0.0_dp])
        aeq0 = .false.
        info = 0
        if(.not.lsame(uplo,'U') .and. .not.lsame(uplo,'L')) then
           info = 1
        else if(n<0) then
           info = 2
        else if(incx==0) then
           info = 5
        else if(lda < max(1,n)) then
           info = 7
        end if
        if(info/=0) then
           call xerbla('GMS_ZHER',info)
           return
        end if
        !  Quick return if possible.
        aeq0 = all(alpha==ZERO.re)
        if((n==0) .or. (aeq0)) return
        !  Set the start point in X if the increment is not unity.
        if(incx<=0) then
           kx = 1-(n-1)*incx
        else
           kx = 1
        end if
        !   Start the operations. In this version the elements of A are
        !*     accessed sequentially with one pass through the triangular part
        !*     of A.
        if(lsame(uplo,'U')) then
           !   Form  A  when A is stored in upper triangle.
           if(incx==1) then
              do j=1,n
                 if(all(x(j)/=ZERO)) then
                    temp = alpha*conjugate(x(j))
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,j-1
                       a(i,j) = a(i,j)+x(i)*temp
                    end do
                    a(j,j) = a(j,j).re+x(j).re*temp.re
                 else
                    a(j,j) = a(j,j).re
                 end if
              end do
           else
              jx = kx
              do j=1,n
                 if(all(x(jx)/=ZERO)) then
                    temp = alpha*conjugate(x(jx))
                    ix = kx
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,j-1
                       a(i,j) = a(i,j)+x(ix)*temp
                       ix = ix+incx
                    end do
                    a(j,j) = a(j,j).re+x(j).re*temp.re
                 else
                    a(j,j) = a(j,j).re
                 end if
              end do
           else
              jx = kx
              do j=1,n
                 if(all(x(jx)/=ZERO)) then
                    temp = alpha*conjugate(x(jx))
                    ix = kx
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=1,j-1
                       a(i,j) = a(i,j)+x(ix)*temp
                       ix = ix+incx
                    end do
                    a(j,j) = a(j,j).re+x(jx).re*temp.re
                 else
                    a(j,j) = a(j,j).re
                 end if
                 jx = jx+incx
              end do
           end if
        else
           !  Form  A  when A is stored in lower triangle.
           if(incx==1) then
              do j=1,n
                 if(all(x(j)/=ZERO)) then
                    temp = alpha*conjugate(x(j))
                    a(j,j) = a(j,j).re+temp.re*x(j).re
                    !DIR$ VECTOR ALIGNED
                    !DIR$ VECTOR ALWAYS
                    do i=j+1,n
                       a(i,j) = a(i,j)+x(i)*temp
                    end do
                 else
                    a(j,j) = a(j,j).re
                 end if
              end do
           else
              jx = kx
              do j=1,n
                 if(all(x(jx)/=ZERO)) then
                    temp = alpha*conjugate(x(jx))
                    a(j,j) = a(j,j).re+temp.re*x(jx).re
                    ix = jx
                    do i=j+1,n
                       ix = ix+incx
                       a(i,j) = a(i,j)+x(ix)*temp
                    end do
                 else
                    a(j,j) = a(j,j).re
                 end if
                 jx = jx+incx
              end do
           end if
        end if
        ! End of ZHER
    end subroutine gms_zher

!    Authors:
!*  ========
!*
!*> \author Univ. of Tennessee
!*> \author Univ. of California Berkeley
!1*> \author Univ. of Colorado Denver
!*> \author NAG Ltd.
!*
!*> \date November 2017
!*
!*> \ingroup complex16_blas_level1
!*
!*> \par Further Details:
!*  =====================
!*>
!*> \verbatim
!1*>
!*>     jack dongarra, 3/11/78.
!*>     modified 3/93 to return if incx .le. 0.
    !*>     modified 12/3/93, array(1) declarations changed to array(*)
    !  !!Modified by Bernard Gingold on 29-11-2019 (removing build-in complex*16 data type,using modern Fortran features) 
    !*> \endverbatim

     subroutine gms_zscal(n,za,zx,incx)
       !DIR$ ATTRIBUTES CODE_ALIGN : 32 :: gms_zscal
       !DIR$ ATTIRBUTES VECTOR  :: gms_zscal
       integer(kind=int4),                     intent(in)    :: n
       type(AVX512c8f64_t),                    intent(in)    :: za
       type(AVX512c8f64_t), dimension(*),      intent(inout) :: zx
       !DIR$ ASSUME_ALIGNED zx:64
       integer(kind=int4),                     intent(in)    :: incx
       ! Locals
       integer(kind=int4), automatic :: i,nincx
       ! Exec code ....
       if(n<=0 .or. incx<0) return
       if(incx==1) then
          !   code for increment equal to 1
          !DIR$ VECTOR ALIGNED
          !DIR$ VECTOR ALWAYS
          do i=1,n
             zx(i) = za*zx(i)
          end do
       else
          !  code for increment not equal to 1
          nincx = n*incx
          !DIR$ VECTOR ALIGNED
          !DIR$ VECTOR ALWAYS
          do i=1,nincx,incx
             zx(i) = za*zx(i)
          end do
       end if 
     end subroutine gms_zscal
    
end module mod_blas
