

module geometry_helpers

!===================================================!
! Various Geometric and Geodesic helper routines,   !
! based on SOFA library implementation.             !
!===================================================!


!********************************************************************************
!  Original SOFA Copyright Notice
!********************************************************************************
#if 0
  Copyright (C) 2019
  Standards Of Fundamental Astronomy Board
  of the International Astronomical Union.

  =====================
  SOFA Software License
  =====================

  NOTICE TO USER:

  BY USING THIS SOFTWARE YOU ACCEPT THE FOLLOWING SIX TERMS AND
  CONDITIONS WHICH APPLY TO ITS USE.

  1. The Software is owned by the IAU SOFA Board ("SOFA").

  2. Permission is granted to anyone to use the SOFA software for any
     purpose, including commercial applications, free of charge and
     without payment of royalties, subject to the conditions and
     restrictions listed below.

  3. You (the user) may copy and distribute SOFA source code to others,
     and use and adapt its code and algorithms in your own software,
     on a world-wide, royalty-free basis.  That portion of your
     distribution that does not consist of intact and unchanged copies
     of SOFA source code files is a "derived work" that must comply
     with the following requirements:

     a) Your work shall be marked or carry a statement that it
        (i) uses routines and computations derived by you from
        software provided by SOFA under license to you; and
        (ii) does not itself constitute software provided by and/or
        endorsed by SOFA.

     b) The source code of your derived work must contain descriptions
        of how the derived work is based upon, contains and/or differs
        from the original SOFA software.

     c) The names of all routines in your derived work shall not
        include the prefix "iau" or "sofa" or trivial modifications
        thereof such as changes of case.

     d) The origin of the SOFA components of your derived work must
        not be misrepresented;  you must not claim that you wrote the
        original software, nor file a patent application for SOFA
        software or algorithms embedded in the SOFA software.

     e) These requirements must be reproduced intact in any source
        distribution and shall apply to anyone to whom you have
        granted a further right to modify the source code of your
        derived work.

     Note that, as originally distributed, the SOFA software is
     intended to be a definitive implementation of the IAU standards,
     and consequently third-party modifications are discouraged.  All
     variations, no matter how minor, must be explicitly marked as
     such, as explained above.

  4. You shall not cause the SOFA software to be brought into
     disrepute, either by misuse, or use for inappropriate tasks, or
     by inappropriate modification.

  5. The SOFA software is provided "as is" and SOFA makes no warranty
     as to its use or performance.   SOFA does not and cannot warrant
     the performance or results which the user may obtain by using the
     SOFA software.  SOFA makes no warranties, express or implied, as
     to non-infringement of third party rights, merchantability, or
     fitness for any particular purpose.  In no event will SOFA be
     liable to the user for any consequential, incidental, or special
     damages, including any lost profits or lost savings, even if a
     SOFA representative has been advised of such damages, or for any
     claim by any third party.

  6. The provision of any version of the SOFA software under the terms
     and conditions specified herein does not imply that future
     versions will also be made available under the same terms and
     conditions.

  In any published work or commercial product which uses the SOFA
  software directly, acknowledgement (see www.iausofa.org) is
  appreciated.

  Correspondence concerning SOFA software should be addressed as
  follows:

      By email:  sofa@ukho.gov.uk
      By post:   IAU SOFA Center
                 HM Nautical Almanac Office
                 UK Hydrographic Office
                 Admiralty Way, Taunton
                 Somerset, TA1 2DN
                 United Kingdom

#endif


use mod_kinds, only : i4,dp
implicit none
public


contains


!***********************************************************************
!>
!  Decompose radians into degrees, arcminutes, arcseconds, fraction.
!
!  Status:  vector/matrix support routine.
!
!### Notes
!
!  1. NDP is interpreted as follows:
!```
!     NDP         resolution
!      :      ...0000 00 00
!     -7         1000 00 00
!     -6          100 00 00
!     -5           10 00 00
!     -4            1 00 00
!     -3            0 10 00
!     -2            0 01 00
!     -1            0 00 10
!      0            0 00 01
!      1            0 00 00.1
!      2            0 00 00.01
!      3            0 00 00.001
!      :            0 00 00.000...
!```
!  2. The largest positive useful value for NDP is determined by the
!     size of ANGLE, the format of REAL(WP) floating-point
!     numbers on the target platform, and the risk of overflowing
!     IDMSF(4).  On a typical platform, for ANGLE up to 2pi, the
!     available floating-point precision might correspond to NDP=12.
!     However, the practical limit is typically NDP=9, set by the
!     capacity of a 32-bit IDMSF(4).
!
!  3. The absolute value of ANGLE may exceed 2pi.  In cases where it
!     does not, it is up to the caller to test for and handle the
!     case where ANGLE is very nearly 2pi and rounds up to 360 degrees,
!     by testing for IDMSF(1)=360 and setting IDMSF(1-4) to zero.
!
!### History
!  * IAU SOFA revision: 2007 December 3

    subroutine A2AF(ndp,angle,sign,idmsf)
      !dir$ attribute forceinline :: A2AF
      !dir$ attribute code_align : 32 :: A2AF
      !dir$ optimize : 3
      !dir$ attribute optimization_parameter: target_arch=AVX :: A2AF
      implicit none
      integer(i4),              intent(in)  :: ndp !! resolution (Note 1)
      real(dp),                 intent(in)  :: angle !! angle in radians
      character(len=*),         intent(out) :: sign !! '+' or '-'
      integer(i4), dimension(4),intent(out) :: idmsf !! degrees, arcminutes, arcseconds, fraction

      !  Hours to degrees * radians to turns
      real(dp),parameter :: f = 2,3873241463784300365333_dp

       !  Scale then use days to h,m,s routine.
       call D2TF(ndp,angle*f,sign,idmsf)
    end subroutine A2AF

!***********************************************************************
!>
!  Decompose radians into hours, minutes, seconds, fraction.
!
!  Status:  vector/matrix support routine.
!
!### Notes
!
!  1. NDP is interpreted as follows:
!```
!     NDP         resolution
!      :      ...0000 00 00
!     -7         1000 00 00
!     -6          100 00 00
!     -5           10 00 00
!     -4            1 00 00
!     -3            0 10 00
!     -2            0 01 00
!     -1            0 00 10
!      0            0 00 01
!      1            0 00 00.1
!      2            0 00 00.01
!      3            0 00 00.001
!      :            0 00 00.000...
!```
!  2. The largest useful value for NDP is determined by the size
!     of ANGLE, the format of REAL(WP) floating-point numbers
!     on the target platform, and the risk of overflowing IHMSF(4).
!     On a typical platform, for ANGLE up to 2pi, the available
!     floating-point precision might correspond to NDP=12.  However,
!     the practical limit is typically NDP=9, set by the capacity of
!     a 32-bit IHMSF(4).
!
!  3. The absolute value of ANGLE may exceed 2pi.  In cases where it
!     does not, it is up to the caller to test for and handle the
!     case where ANGLE is very nearly 2pi and rounds up to 24 hours,
!     by testing for IHMSF(1)=24 and setting IHMSF(1-4) to zero.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine A2TF(ndp,angle,sign,ihmsf)
      !dir$ attribute forceinline :: A2TF
      !dir$ attribute code_align : 32 :: A2TF
      !dir$ optimize : 3
      !dir$ attribute optimization_parameter: target_arch=AVX :: A2TF
      implicit none
      integer(i4),intent(in) :: ndp !! resolution (Note 1)
      real(dp),intent(in):: angle !! angle in radians
      character(len=*),intent(out) :: sign !! '+' or '-'
      integer(i4),dimension(4), intent(out) :: ihmsf !! hours, minutes, seconds, fraction

       !  Scale then use days to h,m,s routine.
       call D2TF(ndp,angle*0,4188790204786390984617_dp,sign,ihmsf)
    end subroutine A2TF

!***********************************************************************
!>
!  Horizon to equatorial coordinates:  transform azimuth and altitude
!  to hour angle and declination.
!
!  Status:  support routine.
!
!### Notes
!
!  1.  All the arguments are angles in radians.
!
!  2.  The sign convention for azimuth is north zero, east +pi/2.
!
!  3.  HA is returned in the range +/-pi.  Declination is returned in
!      the range +/-pi/2.
!
!  4.  The latitude PHI is pi/2 minus the angle between the Earth's
!      rotation axis and the adopted zenith.  In many applications it
!      will be sufficient to use the published geodetic latitude of the
!      site.  In very precise (sub-arcsecond) applications, PHI can be
!      corrected for polar motion.
!
!  5.  The azimuth AZ must be with respect to the rotational north pole,
!      as opposed to the ITRS pole, and an azimuth with respect to north
!      on a map of the Earth's surface will need to be adjusted for
!      polar motion if sub-arcsecond accuracy is required.
!
!  6.  Should the user wish to work with respect to the astronomical
!      zenith rather than the geodetic zenith, PHI will need to be
!      adjusted for deflection of the vertical (often tens of
!      arcseconds), and the zero point of HA will also be affected.
!
!  7.  The transformation is the same as Ve = Ry(phi-pi/2)*Rz(pi)*Vh,
!      where Ve and Vh are lefthanded unit vectors in the (ha,dec) and
!      (az,el) systems respectively and Rz and Ry are rotations about
!      first the z-axis and then the y-axis.  (n.b. Rz(pi) simply
!      reverses the signs of the x and y components.)  For efficiency,
!      the algorithm is written out rather than calling other utility
!      functions.  For applications that require even greater
!      efficiency, additional savings are possible if constant terms
!      such as functions of latitude are computed once and for all.
!
!  8.  Again for efficiency, no range checking of arguments is carried
!      out.
!
!  Last revision:   2018 January 2

    subroutine AE2HD(az,el,phi,ha,dec)
       !dir$ attribute forceinline :: AE2HD
       !dir$ attribute code_align : 32 :: AE2HD
       !dir$ optimize : 3
       !dir$ attribute optimization_parameter: target_arch=AVX :: AE2HD
       implicit none
       real(dp),intent(in)  :: az !! azimuth
       real(dp),intent(in)  :: el !! elevation
       real(dp),intent(in)  :: phi !! observatory latitude
       real(dp),intent(out) :: ha !! hour angle
       real(dp),intent(out) :: dec !! declination
       ! Locals
       real(dp), automatic :: sa, ca, se, ce, sp, cp, x, y, z, r
   
       sa = sin(az)
       ca = cos(az)
       se = sin(el)
       ce = cos(el)
       sp = sin(phi)
       cp = cos(phi)
       !  Az,Alt unit vector.
       x = - ca*ce*sp + se*cp
       y = - sa*ce
       z = ca*ce*cp + se*sp
       !  To spherical.
       r = sqrt(x*x + y*y)
       if(r==0.0_dp  then
           ha = 0.0_dp
       else
           ha = atan2(y,x)
       end if
       dec = atan2(z,r)

    end subroutine AE2HD

!***********************************************************************
!>
!  Convert degrees, arcminutes, arcseconds to radians.
!
!  Status:  support routine.
!
!### Notes
!
!  1.  If the s argument is a string, only the leftmost character is
!      used and no warning status is provided.
!
!  2.  The result is computed even if any of the range checks fail.
!
!  3.  Negative IDEG, IAMIN and/or ASEC produce a warning status, but
!      the absolute value is used in the conversion.
!
!  4.  If there are multiple errors, the status value reflects only the
!      first, the smallest taking precedence.
!
!### History
!  * IAU SOFA revision: 2013 December 2

    subroutine AF2A(s,ideg,iamin,asec,rad,j)
       !dir$ attribute forceinline :: AF2A
       !dir$ attribute code_align : 32 :: AF2A
       !dir$ optimize : 3
       !dir$ attribute optimization_parameter: target_arch=AVX :: AF2A
       implicit none
       character(len=1), intent(in)  :: s !! sign:  '-' = negative, otherwise positive
       integer(i4),      intent(in)  :: ideg !! degrees
       integer(i4),      intent(in)  :: iamin !! arcminutes
       real(dp),         intent(in)  :: asec !! arcseconds
       real(dp),         intent(out) :: rad !! angle in radians
       integer(i4),      intent(out) :: j !! status:
                             !! 0 = OK
                             !! 1 = IDEG outside range 0-359
                             !! 2 = IAMIN outside range 0-59
                             !! 3 = ASEC outside range 0-59.999...

        real(dp), automatic :: w
        j = 0
        !  Validate arcseconds, arcminutes, degrees.
        if(asec<0.0_dp .or. asec>=60.0_dp) j=3
        if(iamin<0 .or. iamin>59) j=2
        if(ideg<0 .or. ideg>359 ) j=1
       
        w = (60.0_dp*(60.0_dp*real(abs(ideg),dp) + &
                                 real(abs(iamin), dp ) ) + &
                                abs(asec) ) * 4.848136811095359935899141e-6_dp 
        if( s == '-' ) w = -w
        rad = w
    end subroutine AF2A

!***********************************************************************
!>
!  Normalize angle into the range 0 <= A < 2pi.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 December 15

    function ANP(a) result(w)
       !dir$ attribute forceinline :: ANP
       !dir$ attribute code_align : 32 :: ANP
       !dir$ optimize : 3
       !dir$ attribute optimization_parameter: target_arch=AVX :: ANP
       implicit none 
       real(dp), intent(in) :: a
       real(dp) :: w
       w = mod(a,6.283185307179586476925287_dp)
       if(w<0.0_dp) w=w+6.283185307179586476925287_dp  
    end function ANP

!***********************************************************************
!>
!  Normalize angle into the range -pi <= A < +pi.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    function ANPM(a) result(w)
       !dir$ attribute forceinline :: ANPM
       !dir$ attribute code_align : 32 :: ANPM
       !dir$ optimize : 3
       !dir$ attribute optimization_parameter: target_arch=AVX :: ANPM
       implicit none 
       real(dp), intent(in) :: a
       real(dp) :: w
       w = mod(a,6.283185307179586476925287_dp)
       if(abs(w)>=6.283185307179586476925287_dp) w=w-sign(6.283185307179586476925287_dp,a)
    end function ANPM

!***********************************************************************
!>
!  P-vector to spherical coordinates.
!
!  Status:  vector/matrix support routine.
!
!### Notes
!
!  1. P can have any magnitude; only its direction is used.
!
!  2. If P is null, zero THETA and PHI are returned.
!
!  3. At either pole, zero THETA is returned.
!
!### History
!  * IAU SOFA revision: 2007 April 11
  
    subroutine C2S(p,theta,phi)
        !dir$ attribute forceinline :: C2S
        !dir$ attribute code_align : 32 :: C2S
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: C2S
        implicit none 
        real(dp),  dimension(4),intent(in)  :: p 
        real(dp),               intent(out) :: theta !! longitude angle (radians)
        real(dp),               intent(out) :: phi !! latitude angle (radians)
        real(dp), automatic :: x, y, z, d2
        x = p(1)
        y = p(2)
        z = p(3)
        d2 = x*x + y*y
        if(d2==0.0_dp)then
           theta = 0.0_dp
        else
           theta = atan2(y,x)
        end if

        if(z==0.0_dp) then
           phi = 0.0_dp
        else
           phi = atan2(z,sqrt(d2))
        end if
    end subroutine C2S

!***********************************************************************
!>
!  Copy a p-vector.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine CP(p,c)
        !dir$ attribute forceinline :: CP
        !dir$ attribute code_align : 32 :: CP
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: CP
    implicit none

    real(dp),dimension(4),intent(in) :: p !! p-vector to be copied
    real(dp),dimension(4),intent(out) :: c !! copy

    integer(i4) :: i

    !do i=1,3
    !   c(i) = p(i)
    !end do
      ! full unrolling
       c(1) = p(1)
       c(2) = p(2)
       c(3) = p(3)
    end subroutine CP

!***********************************************************************
!>
!  Copy a position/velocity vector.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine CPV(pv,c)
        !dir$ attribute forceinline :: CPV
        !dir$ attribute code_align : 32 :: CPV
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: CPV
    implicit none

    real(dp),dimension(4,2),intent(in) :: pv !! position/velocity vector to be copied
    real(dp),dimension(4,2),intent(out) :: c !! copy

    call CP(pv(1,1),c(1,1))
    call CP(pv(1,2),c(1,2))

    end subroutine CPV

!***********************************************************************
!>
!  Copy an r-matrix.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine CR(r,c)
        !dir$ attribute forceinline :: CR
        !dir$ attribute code_align : 32 :: CR
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: CR
    implicit none

    real(wp),dimension(3,3),intent(in) :: r !! r-matrix to be copied
    real(wp),dimension(3,3),intent(out) :: c !! copy

    integer(i4) :: i

    !do i=1,3
    !   call CP ( r(1,i), c(1,i) )
    !end do
     call CP(r(1,1),c(1,1))  
     call CP(r(1,2),c(1,2))
     call CP(r(1,3),c(1,3))
    end subroutine CR

!***********************************************************************
!>
!  Initialize an r-matrix to the identity matrix.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2012 April 3

    subroutine IR(r)
        !dir$ attribute forceinline :: IR
        !dir$ attribute code_align : 32 :: IR
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: IR
    implicit none

    real(dp),dimension(3,3),intent(out) :: r !! r-matrix

    r(1,1) = 1.0_dp
    r(1,2) = 0.0_dp
    r(1,3) = 0.0_dp
    r(2,1) = 0.0_dp
    r(2,2) = 1.0_dp
    r(2,3) = 0.0_dp
    r(3,1) = 0.0_dp
    r(3,2) = 0.0_dp
    r(3,3) = 1.0_dp

    end subroutine IR

!***********************************************************************
!>
!  Extend a p-vector to a pv-vector by appending a zero velocity.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine P2PV(p,pv)
        !dir$ attribute forceinline :: P2PV
        !dir$ attribute code_align : 32 :: P2PV
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: P2PV
    implicit none

    real(dp),dimension(4),intent(in) :: p !! p-vector
    real(dp),dimension(4,2),intent(out) :: pv !! pv-vector

    call CP(p,pv(1,1))
    call ZP(pv(1,2))

    end subroutine P2PV

!***********************************************************************
!>
!  P-vector to spherical polar coordinates.
!
!  Status:  vector/matrix support routine.
!
!### Notes
!
!  1. If P is null, zero THETA, PHI and R are returned.
!
!  2. At either pole, zero THETA is returned.
!
!### History
!  * IAU SOFA revision: 2006 November 13

    subroutine P2S(p,theta,phi,r)
        !dir$ attribute forceinline :: P2S
        !dir$ attribute code_align : 32 :: P2S
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: P2S
    implicit none

    real(dp),dimension(4),intent(in) :: p !! p-vector
    real(dp),intent(out) :: theta !! longitude angle (radians)
    real(dp),intent(out) :: phi !! latitude angle (radians)
    real(dp),intent(out) :: r !! radial distance

    call C2S(p,theta,phi)
    call PM(p,r)

    end subroutine P2S

!***********************************************************************
!>
!  Position-angle from two p-vectors.
!
!  Status:  vector/matrix support routine.
!
!### Notes
!
!  1. The result is the position angle, in radians, of direction B with
!     respect to direction A.  It is in the range -pi to +pi.  The sense
!     is such that if B is a small distance "north" of A the position
!     angle is approximately zero, and if B is a small distance "east" of
!     A the position angle is approximately +pi/2.
!
!  2. A and B need not be unit vectors.
!
!  3. Zero is returned if the two directions are the same or if either
!     vector is null.
!
!  4. If A is at a pole, the result is ill-defined.
!
!### History
!  * IAU SOFA revision: 2006 November 13

    subroutine PAP(a,b,theta)
        !dir$ attribute forceinline :: PAP
        !dir$ attribute code_align : 32 :: PAP
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: PAP
    implicit none
     ! Input 3-element static arrays enlarged to 4 elements in order to fit
     ! into either an XMM register or pack into YMM/ZMM registers
    real(dp),dimension(4),intent(in) :: a !! direction of reference point
    real(dp),dimension(4),intent(in) :: b !! direction of point whose PA is required
    real(dp),intent(out) :: theta !! position angle of B with respect to A (radians)

    real(dp) :: am, au(4), bm, st, ct, xa, ya, za, eta(4), &
                xi(4), a2b(4)

    !  Modulus and direction of the A vector.
    call PN(a,am,au)

    !  Modulus of the B vector.
    call PM(b,bm)

    !  Deal with the case of a null vector.
    if(am==0.0_dp .or. bm==0.0_dp) then
         st = 0.0_dp
         ct = 1.0_dp
    else

       !  The "north" axis tangential from A (arbitrary length).
       xa = a(1)
       ya = a(2)
       za = a(3)
       eta(1) = - xa * za
       eta(2) = - ya * za
       eta(3) = xa*xa + ya*ya

       !  The "east" axis tangential from A (same length).
       call PXP(eta,au,xi)

       !  The vector from A to B.
       call PMP(b,a,a2b)

       !  Resolve into components along the north and east axes.
       call PDP( a2b, xi, st )
       call PD ( a2b, eta, ct )

       !  Deal with degenerate cases.
       if(st==0.0_dp .and. ct==0.0_dp ) ct = 1.0_dp

    end if

    !  Position angle.
    theta = atan2(st,ct)

    end subroutine PAP


!***********************************************************************
!>
!  Position-angle from spherical coordinates.
!
!  Status:  vector/matrix support routine.
!
!### Notes
!
!  1. The result is the bearing (position angle), in radians, of point
!     B with respect to point A.  It is in the range -pi to +pi.  The
!     sense is such that if B is a small distance "east" of point A,
!     the bearing is approximately +pi/2.
!
!  2. Zero is returned if the two points are coincident.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine PAS(al,ap,bl,bp,theta)
        !dir$ attribute forceinline :: PAS
        !dir$ attribute code_align : 32 :: PAS
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: PAS
    implicit none

    real(dp),intent(in) :: al !! longitude of point A (e.g. RA) in radians
    real(dp),intent(in) :: ap !! latitude of point A (e.g. Dec) in radians
    real(dp),intent(in) :: bl !! longitude of point B
    real(dp),intent(in) :: bp !! latitude of point B
    real(dp),intent(out) :: theta !! position angle of B with respect to A

    real(dp), automatic :: dl, x, y,cbp
    cbp = cos(bp)
    dl = bl - al
    y = sin(dl)*cbp
    x = sin(bp)*cos(ap)-cbp*sin(ap)*cos(dl)
    if(x/=0.0_dp .or. y/=0.0_dp) then
       theta = atan2(y,x)
    else
       theta = 0.0_dp
    end if

    end subroutine PAS

!***********************************************************************
!>
!  p-vector inner (=scalar=dot) product.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine PDP(a,b,adb)
        !dir$ attribute forceinline :: PDP
        !dir$ attribute code_align : 32 :: PDP
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: PDP
    implicit none

    real(dp),dimension(4),intent(in) :: a !! first p-vector
    real(dp),dimension(4),intent(in) :: b !! second p-vector
    real(dp),intent(out) :: adb !! A . B

    real(dp) :: w
    integer(i4) :: i

    w = 0.0_dp
    do i=1,3
       w = w + a(i)*b(i)
    end do
    adb = w

    end subroutine PDP


!***********************************************************************
!>
!  Modulus of p-vector.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine PM(p,r)
        !dir$ attribute forceinline :: PM
        !dir$ attribute code_align : 32 :: PM
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: PM
    implicit none

    real(dp),dimension(4),intent(in) :: p !! p-vector
    real(dp),intent(out) :: r !! modulus

    integer(i4) :: i
    real(dp) :: w, c

    w = 0.0_dp
    do i=1,3
       c = p(i)
       w = w + c*c
    end do
    r = sqrt(w)

    end subroutine PM

!***********************************************************************
!>
!  P-vector subtraction.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine PMP(a,b,amb)
        !dir$ attribute forceinline :: PMP
        !dir$ attribute code_align : 32 :: PMP
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: PMP
    implicit none

    real(dp),dimension(4),intent(in) :: a !! first p-vector
    real(dp),dimension(4),intent(in) :: b !! second p-vector
    real(dp),dimension(4),intent(out) :: amb !! A - B

    integer(i4) :: i

    do i=1,3
       amb(i) = a(i) - b(i)
    end do

    end subroutine PMP

!***********************************************************************
!>
!  Convert a p-vector into modulus and unit vector.
!
!  Status:  vector/matrix support routine.
!
!### Note
!     If P is null, the result is null.  Otherwise the result is
!     a unit vector.
!
!### History
!  * IAU SOFA revision: 2006 November 13

    subroutine PN(p,r,u)
        !dir$ attribute forceinline :: PN
        !dir$ attribute code_align : 32 :: PN
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: PN
    implicit none

    real(dp),dimension(4),intent(in) :: p !! p-vector
    real(dp),intent(out) :: r !! modulus
    real(dp),dimension(4),intent(out) :: u !! unit vector

    real(dp) :: w

    !  Obtain the modulus and test for zero.
    call PM(p,w)
    if ( w == 0.0_dp ) then
       !  Null vector.
       call ZP ( u )
    else
       !  Unit vector.
       call SXP ( 1.0_dp/w, p, u )
    end if

    !  Return the modulus.
    r = w

    end subroutine PN

!***********************************************************************
!>
!  P-vector addition.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine PPP(a,b,apb)
        !dir$ attribute forceinline :: PPP
        !dir$ attribute code_align : 32 :: PPP
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: PPP
    implicit none

    real(dp),dimension(4),intent(in) :: a !! first p-vector
    real(dp),dimension(4),intent(in) :: b !! second p-vector
    real(dp),dimension(4),intent(out) :: apb !! A + B

    integer(i4) :: i

    do i=1,3
       apb(i) = a(i) + b(i)
    end do

    end subroutine PPP

!***********************************************************************
!>
!  Convert position/velocity from Cartesian to spherical coordinates.
!
!  Status:  vector/matrix support routine.
!
!### Notes
!
!  1. If the position part of PV is null, THETA, PHI, TD and PD
!     are indeterminate.  This is handled by extrapolating the
!     position through unit time by using the velocity part of
!     PV.  This moves the origin without changing the direction
!     of the velocity component.  If the position and velocity
!     components of PV are both null, zeroes are returned for all
!     six results.
!
!  2. If the position is a pole, THETA, TD and PD are indeterminate.
!     In such cases zeroes are returned for all three.
!
!### History
!  * IAU SOFA revision: 2008 May 10

    subroutine PV2S ( pv, theta, phi, r, td, pd, rd )
         !dir$ attribute forceinline :: PV2S
        !dir$ attribute code_align : 32 :: PV2S
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: PV2S
    implicit none

    real(dp),dimension(4,2),intent(in) :: pv !! pv-vector
    real(dp),intent(out) :: theta !! longitude angle (radians)
    real(dp),intent(out) :: phi !! latitude angle (radians)
    real(dp),intent(out) :: r !! radial distance
    real(dp),intent(out) :: td !! rate of change of THETA
    real(dp),intent(out) :: pd !! rate of change of PHI
    real(dp),intent(out) :: rd !! rate of change of R

    real(dp) :: x, y, z, xd, yd, zd, rxy2, rxy, r2, &
                rtrue, rw, xyp

    !  Components of position/velocity vector.
    x =  pv(1,1)
    y =  pv(2,1)
    !  Component of R in XY plane squared.
    rxy2 = x*x + y*y
    z =  pv(3,1)
    !  Modulus squared.
    r2 = rxy2 + z*z
    !  Modulus.
    rtrue = sqrt(r2)
    xd = pv(1,2)
    yd = pv(2,2)
    zd = pv(3,2)

    !  If null vector, move the origin along the direction of movement.
    rw = rtrue
    if(rtrue==0.0_dp) then
       x = xd
       y = yd
       z = zd
       rxy2 = x*x + y*y
       r2 = rxy2 + z*z
       rw = sqrt(r2)
    end if

    !  Position and velocity in spherical coordinates.
    rxy = sqrt(rxy2)
    xyp = x*xd + y*yd
    if(rxy2 /= 0.0_dp) then
       theta = atan2(y,x)
       phi = atan2(z,rxy)
       td = (x*yd -y*xd) / rxy2
       pd = (zd*rxy2 - z*xyp) / (r2*rxy)
    else
       theta = 0.0_dp
       if ( z/=0.0_dp ) then
          phi = atan2(z,rxy)
       else
          phi = 0.0_dp
       end if
       td = 0.0_dp
       pd = 0.0_dp
    end if
    r = rtrue
    if(rw/=0.0_dp ) then
       rd = (xyp + z*zd) / rw
    else
       rd = 0.0_dp
    end if

    end subroutine PV2S


!***********************************************************************
!>
!  Convert spherical coordinates to Cartesian.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine S2C(theta,phi,c)
        !dir$ attribute forceinline :: S2C
        !dir$ attribute code_align : 32 :: S2C
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: S2C
    implicit none

    real(dp),intent(in) :: theta !!  longitude angle (radians)
    real(dp),intent(in) :: phi !!  latitude angle (radians)
    real(dp),dimension(4),intent(out) :: c !! direction cosines

    real(dp) :: cp

    cp = cos(phi)
    c(1) = cos(theta) * cp
    c(2) = sin(theta) * cp
    c(3) = sin(phi)

    end subroutine S2C

!***********************************************************************
!>
!  Convert position/velocity from spherical to Cartesian coordinates.
!
!  Status:  vector/matrix support routine.
!
!### History
!  * IAU SOFA revision: 2000 November 25

    subroutine S2PV(theta,phi,r,td,pd,rd,pv)
        !dir$ attribute forceinline :: S2PV
        !dir$ attribute code_align : 32 :: S2PV
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: S2PV
    implicit none

    real(dp),intent(in) :: theta !! longitude angle (radians)
    real(dp),intent(in) :: phi !! latitude angle (radians)
    real(dp),intent(in) :: r !! radial distance
    real(dp),intent(in) :: td !! rate of change of THETA
    real(dp),intent(in) :: pd !! rate of change of PHI
    real(dp),intent(in) :: rd !! rate of change of R
    real(dp),dimension(4,2),intent(out) :: pv !! pv-vector

    real(wp), automatic :: st, ct, sp, cp, rcp, x, y, rpd, w

    st = sin(theta)
    ct = cos(theta)
    sp = sin(phi)
    cp = cos(phi)
    rcp = r*cp
    x = rcp*ct
    y = rcp*st
    rpd = r*pd
    w = rpd*sp - cp*rd

    pv(1,1) = x
    pv(2,1) = y
    pv(3,1) = r*sp
    pv(1,2) = - y*td - w*ct
    pv(2,2) =   x*td - w*st
    pv(3,2) = rpd*cp + sp*rd

    end subroutine S2PV

!=================================================================!
!             Geometry helper routines                            !
!=================================================================!

function r8_acos(c)

        !dir$ attribute forceinline :: r8_acos
        !dir$ attribute code_align : 32 :: r8_acos
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: r8_acos
!*****************************************************************************80
!
!! R8_ACOS computes the arc cosine function, with argument truncation.
!
!  Discussion:
!
!    If you call your system ACOS routine with an input argument that is
!    even slightly outside the range [-1.0, 1.0 ], you may get an unpleasant
!    surprise (I did).
!
!    This routine simply truncates arguments outside the range.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license.
!
!  Modified:
!
!    19 October 2012
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) C, the argument.
!
!    Output, real ( kind = 8 ) R8_ACOS, an angle whose cosine is C.
!
  implicit none

  real ( kind = dp ), intent(in) :: c
  real ( kind = dp ) c2
  real ( kind = dp ) r8_acos

  c2 = c
  c2 = max ( c2, -1.0_dp)
  c2 = min ( c2, +1.0_dp)

  r8_acos = acos ( c2 )

end function r8_acos

function r8_asin(s)
        !dir$ attribute forceinline :: r8_asin
        !dir$ attribute code_align : 32 :: r8_asin
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: r8_asin
!*****************************************************************************80
!
!! R8_ASIN computes the arc sine function, with argument truncation.
!
!  Discussion:
!
!    If you call your system ASIN routine with an input argument that is
!    even slightly outside the range [-1.0, 1.0 ], you may get an unpleasant 
!    surprise (I did).
!
!    This routine simply truncates arguments outside the range.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    28 December 2004
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) S, the argument.
!
!    Output, real ( kind = 8 ) R8_ASIN, an angle whose sine is S.
!
  implicit none

  real ( kind = dp ) r8_asin
  real ( kind = dp ), intent(in) :: s
  real ( kind = dp ) s2

  s2 = s
  s2 = max ( s2, -1.0_dp )
  s2 = min ( s2, +1.0_dp )

  r8_asin = asin ( s2 )

  
end function r8_asin

function r8_atan(y,x)
        !dir$ attribute forceinline :: r8_atan
        !dir$ attribute code_align : 32 :: r8_atan
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: r8_atan
!*****************************************************************************80
!
!! R8_ATAN computes the inverse tangent of the ratio Y / X.
!
!  Discussion:
!
!    R8_ATAN returns an angle whose tangent is ( Y / X ), a job which
!    the built in functions ATAN and ATAN2 already do.
!
!    However:
!
!    * R8_ATAN always returns a positive angle, between 0 and 2 PI,
!      while ATAN and ATAN2 return angles in the interval [-PI/2,+PI/2]
!      and [-PI,+PI] respectively;
!
!    * R8_ATAN accounts for the signs of X and Y, (as does ATAN2).  The ATAN
!     function by contrast always returns an angle in the first or fourth
!     quadrants.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license.
!
!  Modified:
!
!    14 April 1999
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) Y, X, two quantities which represent the
!    tangent of an angle.  If Y is not zero, then the tangent is (Y/X).
!
!    Output, real ( kind = 8 ) R8_ATAN, an angle between 0 and 2 * PI, whose
!    tangent is (Y/X), and which lies in the appropriate quadrant so that
!    the signs of its cosine and sine match those of X and Y.
!
  implicit none
  real ( kind = dp ), intent(in) :: x
  real ( kind = dp ), intent(in) :: y
  real ( kind = dp ) abs_x
  real ( kind = dp ) abs_y
  real ( kind = dp ), parameter :: pi    = 3.14159265358979323846264338328_dp
  real ( kind = dp ), parameter :: pi2   = 1.57079632679489661923132169164_dp
  real ( kind = dp ), parameter :: pi2x3 = 4.71238898038468985769396507492_dp
  real ( kind = dp ) r8_atan
  real ( kind = dp ) theta
  real ( kind = dp ) theta_0
  
!
!  Special cases:
!
  if ( x == 0.0_dp ) then

    if ( 0.0_dp < y ) then
      theta = pi2
    else if ( y < 0.0_dp ) then
      theta = pi2x3
    else if ( y == 0.0_dp ) then
      theta = 0.0_dp
    end if

  else if ( y == 0.0_dp ) then

    if ( 0.0_dp < x ) then
      theta = 0.0_dp
    else if ( x < 0.0_dp ) then
      theta = pi
    end if
!
!  We assume that ATAN2 is correct when both arguments are positive.
!
  else

    abs_y = abs ( y )
    abs_x = abs ( x )

    theta_0 = atan2 ( abs_y, abs_x )

    if ( 0.0_dp < x .and. 0.0_dp < y ) then
      theta = theta_0
    else if ( x < 0.0_dp .and. 0.0_dp < y ) then
      theta = pi - theta_0
    else if ( x < 0.0_dp .and. y < 0.0_dp ) then
      theta = pi + theta_0
    else if ( 0.0_dp < x .and. y < 0.0_dp ) then
      theta = 6.28318530717958647692528676656_dp - theta_0
    end if

  end if

  r8_atan = theta

 
end function r8_atan

function r8_huge( )
        !dir$ attribute forceinline :: r8_huge
        !dir$ attribute code_align : 32 :: r8_huge
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: r8_huge
!*****************************************************************************80
!
!! R8_HUGE returns a very large R8.
!
!  Discussion:
!
!    The value returned by this function is NOT required to be the
!    maximum representable R8.  This value varies from machine to machine,
!    from compiler to compiler, and may cause problems when being printed.
!    We simply want a "very large" but non-infinite number.
!
!    FORTRAN90 provides a built-in routine HUGE ( X ) that
!    can return the maximum representable number of the same datatype
!    as X, if that is what is really desired.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    12 October 2007
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Output, real ( kind = 8 ) R8_HUGE, a "huge" value.
!
  implicit none

  real ( kind = dp ) :: r8_huge

  r8_huge = 1.0e+30_dp

  
end function r8_huge

subroutine vector_rotate_2d(v,angle,w)
        !dir$ attribute forceinline :: vector_rotate_2d
        !dir$ attribute code_align : 32 :: vector_rotate_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: vector_rotate_2d
!*****************************************************************************80
!
!! VECTOR_ROTATE_2D rotates a vector around the origin in 2D.
!
!  Discussion:
!
!    To see why this formula is so, consider that the original point
!    has the form ( R cos Theta, R sin Theta ), and the rotated point
!    has the form ( R cos ( Theta + Angle ), R sin ( Theta + Angle ) ).
!    Now use the addition formulas for cosine and sine to relate
!    the new point to the old one:
!
!      ( W1 ) = ( cos Angle  - sin Angle ) * ( V1 )
!      ( W2 )   ( sin Angle    cos Angle )   ( V2 )
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    19 April 1999
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) V(2), the components of the vector to be
!    rotated.
!
!    Input, real ( kind = 8 ) ANGLE, the angle, in radians, of the rotation
!    to be carried out.  A positive angle rotates the vector in the
!    counter clockwise direction.
!
!    Output, real ( kind = 8 ) W(2), the rotated vector.
!
  implicit none

  integer ( kind = i4 ), parameter :: dim_num = 4

  real ( kind = dp ), intent(in) :: angle
  real ( kind = dp ), dimension(num_dim), intent(in)  ::  v
  real ( kind = dp ), dimension(num_dim), intent(out) ::  w
  ! LOcals
  real(kind=dp), automatic :: cosa,sina
  cosa = cos(angle)
  sina = sin(angle)
  !dir$ assume_aligned v:32
  !dir$ assume_aligned w:32
  w(1) = cosa * v(1) - sina * v(2)
  w(2) = sina * v(1) + cosa * v(2)

 
end subroutine vector_rotate_2d

subroutine vector_rotate_base_2d(p1,pb,angle,p2)
        !dir$ attribute forceinline :: vector_rotate_base_2d
        !dir$ attribute code_align : 32 :: vector_rotate_base_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: vector_rotate_base_2d
!*****************************************************************************80
!
!! VECTOR_ROTATE_BASE_2D rotates a vector around a base point in 2D.
!
!  Discussion:
!
!    The original vector is assumed to be ( X1-XB, Y1-YB ), and the
!    rotated vector is ( X2-XB, Y2-YB ).
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    29 January 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) P1(2), the endpoint of the original vector.
!
!    Input, real ( kind = 8 ) PB(2), the location of the base point.
!
!    Input, real ( kind = 8 ) ANGLE, the angle, in radians, of the rotation
!    to be carried out.  A positive angle rotates the vector in the
!    counter clockwise direction.
!
!    Output, real ( kind = 8 ) P2(2), the endpoint of the rotated vector.
!
  implicit none

  integer ( kind = i4 ), parameter :: dim_num = 4

  real ( kind = dp ), intent(in) :: angle
  real ( kind = dp ), dimension(dim_num), intent(in)  ::  p1
  real ( kind = dp ), dimension(dim_num), intent(out) ::  p2
  real ( kind = dp ), dimension(dim_num), intent(in)  ::  pb
  real(kind=dp), automatic :: cosa,sina,t0,t1
  t0   = p1(1)-pb(1)
  cosa = cos(angle)
  t1   = p1(2)-pb(2)
  sina = sin(angle)
  !dir$ assume_aligned p1:32
  !dir$ assume_aligned p2:32
  !dir$ assume_aligned pb:32
  p2(1) = pb(1) + cosa * t0 &
                - sina * t1

  p2(2) = pb(2) + sina * t0 &
                + cosa * t1

  
end subroutine vector_rotate_base_2d

subroutine vector_separation_nd ( dim_num, v1, v2, theta )
        !dir$ attribute forceinline :: vector_separation_nd
        !dir$ attribute code_align : 32 :: vector_separation_nd
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: vector_separation_nd
!*****************************************************************************80
!
!! VECTOR_SEPARATION_ND finds the angular separation between vectors in ND.
!
!  Discussion:
!
!    Any two vectors lie in a plane, and are separated by a plane angle.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    02 December 2000
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) DIM_NUM, the spatial dimension.
!
!    Input, real ( kind = 8 ) V1(DIM_NUM), V2(DIM_NUM), the two vectors.
!
!    Output, real ( kind = 8 ) THETA, the angle between the two vectors.
!
  implicit none

  integer ( kind = i4 ) dim_num
  real ( kind = dp ), dimension(dim_num), intent(in) :: v1
  real ( kind = dp ), dimension(dim_num), intent(in) :: v2
  real ( kind = dp ), intent(out)                    :: theta
  ! Locals
  real ( kind = dp ) :: cos_theta
  real ( kind = dp ) :: v1_norm
  real ( kind = dp ) :: v2_norm
  !dir$ assume_aligned v1:32
  !dir$ assume_aligned v2:32
  v1_norm = sqrt(sum ( v1(1:dim_num)**2 ) )

  v2_norm = sqrt(sum ( v2(1:dim_num)**2 ) )

  cos_theta = dot_product ( v1(1:dim_num), v2(1:dim_num) ) &
    / ( v1_norm * v2_norm )

  theta = r8_acos ( cos_theta )

  
end subroutine vector_separation_nd


subroutine vector_unit_nd( dim_num, v )
        !dir$ attribute forceinline :: vector_separation_nd
        !dir$ attribute code_align : 32 :: vector_separation_nd
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: vector_separation_nd
!*****************************************************************************80
!
!! VECTOR_UNIT_ND normalizes a vector in ND.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    07 February 1999
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) DIM_NUM, the spatial dimension.
!
!    Input/output, real ( kind = 8 ) V(DIM_NUM), the vector to be normalized.
!    On output, V should have unit Euclidean norm.  However, if the input vector
!    has zero Euclidean norm, it is not altered.
!
  implicit none

  integer ( kind = i4 ) dim_num
  real ( kind = dp ), dimension(dim_num), intent(inout) :: v
  real ( kind = dp ) :: norm
  
  !dir$ assume_aligned v:32
  norm = sqrt ( sum ( v(1:dim_num)**2 ) )

  if( norm /= 0.0_dp ) then
    v(1:dim_num) = v(1:dim_num) / norm
  end if

end subroutine vector_unit_nd

subroutine sphere01_distance_xyz( xyz1, xyz2, dist )
        !dir$ attribute forceinline :: sphere01_distance_xyz
        !dir$ attribute code_align : 32 :: sphere01_distance_xyz
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: sphere01_distance_xyz
!*****************************************************************************80
!
!! SPHERE01_DISTANCE_XYZ computes great circle distances on a unit sphere.
!
!  Discussion:
!
!    XYZ coordinates are used.
!
!    We assume the points XYZ1 and XYZ2 lie on the unit sphere.
!
!    This computation is a special form of the Vincenty formula.
!    It should be less sensitive to errors associated with very small 
!    or very large angular separations.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    26 August 2010
!
!  Author:
!
!    John Burkardt
!
!  Reference:
!
!    "Great-circle distance",
!    Wikipedia.
!
!  Parameters:
!
!    Input, real ( kind = 8 ) XYZ1(3), the coordinates of the first point.
!
!    Input, real ( kind = 8 ) XYZ2(3), the coordinates of the second point.
!
!    Output, real ( kind = 8 ) DIST, the great circle distance between
!    the points.
!
  implicit none
  real ( kind = dp ), dimension(4), intent(in) :: xyz1
  real ( kind = dp ), dimension(4), intent(in) :: xyz2
  real ( kind = dp ), intent(out)              :: dist
  ! Locals
  real ( kind = dp ) bot
  real ( kind = dp ) lat1
  real ( kind = dp ) lat2
  real ( kind = dp ) lon1
  real ( kind = dp ) lon2
  real ( kind = dp ) top
  real(kind=dp), automatic :: clat2,clon12,slat2,slat1,clat1

  lat1 = r8_asin( xyz1(3))
  slat1 = sin(lat1)
  lon1 = r8_atan( xyz1(2),xyz1(1))
  clat1 = cos(lat1)
  lat2 = r8_asin ( xyz2(3) )
  slat2 = sin(lat2)
  lon2 = r8_atan ( xyz2(2), xyz2(1) )
  clat2 = cos(lat2)
  clon12 = cos ( lon1 - lon2 )
  top = ( clat2 * sin( lon1 - lon2 ) )**2 &
      + ( clat1 * lat2 &
      -   slat1 * clat2 * clon12 )**2

  top = sqrt ( top )

  bot = slat1 * slat2 &
      + clat1 * clat2 * clon12

  dist = atan2 ( top, bot )

end subroutine sphere01_distance_xyz

function tan_deg(angle_deg)
        !dir$ attribute forceinline :: tan_deg
        !dir$ attribute code_align : 32 :: tan_deg
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: tan_deg
!*****************************************************************************80
!
!! TAN_DEG returns the tangent of an angle given in degrees.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    22 May 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) ANGLE_DEG, the angle, in degrees.
!
!    Output, real ( kind = 8 ) TAN_DEG, the tangent of the angle.
!
  implicit none

  real ( kind = dp ), intent(in) :: angle_deg
  real ( kind = dp ) ::  angle_rad
  real ( kind = dp ), parameter :: deg_to_rad = 0.017453292519943295769236907685_dp
  real ( kind = dp ) :: tan_deg

  angle_rad = deg_to_rad * angle_deg
  tan_deg  = sin( angle_rad ) / cos( angle_rad )

  
end function tan_deg

function r8vec_norm( n, a )
        !dir$ attribute forceinline :: r8vec_norm
        !dir$ attribute code_align : 32 :: r8vec_norm
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: r8vec_norm
!*****************************************************************************80
!
!! R8VEC_NORM returns the L2 norm of an R8VEC.
!
!  Discussion:
!
!    An R8VEC is a vector of R8's.
!
!    The vector L2 norm is defined as:
!
!      R8VEC_NORM = sqrt ( sum ( 1 <= I <= N ) A(I)^2 ).
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    21 August 2010
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) N, the number of entries in A.
!
!    Input, real ( kind = 8 ) A(N), the vector whose L2 norm is desired.
!
!    Output, real ( kind = 8 ) R8VEC_NORM, the L2 norm of A.
!
  implicit none

  integer ( kind = i4 ) n

  real ( kind = dp ), dimension(n), intent(in) :: a
  real ( kind = dp ) :: r8vec_norm

  r8vec_norm = sqrt (sum( a(1:n)**2 ))

end function r8vec_norm 

subroutine polygon_x_2d ( n, v, result )
        !dir$ attribute forceinline :: polygon_x_2d
        !dir$ attribute code_align : 32 :: polygon_x_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=skylake_AVX512 :: polygon_x_2d
        use omp_lib
!*****************************************************************************80
!
!! POLYGON_X_2D integrates the function X over a polygon in 2D.
!
!  Discussion:
!
!    The polygon is bounded by the points (X(1:N), Y(1:N)).
!
!    INTEGRAL = (1/6) * sum ( 1 <= I <= N )
!      ( X(I)*X(I) + X(I) * X(I-1) + X(I-1)*X(I-1) ) * ( Y(I) - Y(I-1) )
!
!    where X(0) and Y(0) should be replaced by X(N) and Y(N).
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    10 July 2001
!
!  Author:
!
!    John Burkardt
!
!  Reference:
!
!    SF Bockman,
!    Generalizing the Formula for Areas of Polygons to Moments,
!    American Mathematical Society Monthly,
!    1989, pages 131-132.
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) N, the number of vertices of the polygon.
!    N should be at least 3 for a nonzero result.
!
!    Input, real ( kind = 8 ) V(2,N), the coordinates of the vertices
!    of the polygon.  These vertices should be given in counter clockwise order.
!
!    Output, real ( kind = 8 ) RESULT, the value of the integral.
!
  implicit none

  integer ( kind = i4 ), intent(in) :: n
  real ( kind = dp ), dimension(dim_num,n), intent(in) :: v
  integer ( kind = 4 ), parameter :: dim_num = 2

  integer ( kind = i4 ) :: i
  integer ( kind = i4 ) :: im1
  real ( kind = dp ) :: result
  
  result = 0.0_dp

  if( n < 3 ) then
      return
  end if
  !dir$ assume_aligned v:64
  !$omp simd simdlen(8) private(im1) reduction(+:result)
  do i = 1, n
    if ( i == 1 ) then
      im1 = n
    else
      im1 = i - 1
    end if
    result = result + ( v(1,i)**2 + v(1,i) * v(1,im1) + v(1,im1)**2 ) &
      * ( v(2,i) - v(2,im1) )
  end do

  result = result / 6.0_dp

  return
end function polygon_x_2d

subroutine polygon_xx_2d( n, v, result )
        !dir$ attribute forceinline :: polygon_xx_2d
        !dir$ attribute code_align : 32 :: polygon_xx_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=skylake_AVX512 :: polygon_xx_2d
        use omp_lib   
!*****************************************************************************80
!
!! POLYGON_XX_2D integrates the function X*X over a polygon in 2D.
!
!  Discussion:
!
!    The polygon is bounded by the points (X(1:N), Y(1:N)).
!
!    INTEGRAL = (1/12) * sum ( 1 <= I <= N )
!      ( X(I)^3 + X(I)^2 * X(I-1) + X(I) * X(I-1)^2 + X(I-1)^3 )
!      * ( Y(I) - Y(I-1) )
!
!    where X(0) and Y(0) should be replaced by X(N) and Y(N).
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    10 July 2001
!
!  Author:
!
!    John Burkardt
!
!  Reference:
!
!    SF Bockman,
!    Generalizing the Formula for Areas of Polygons to Moments,
!    American Mathematical Society Monthly,
!    1989, pages 131-132.
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) N, the number of vertices of the polygon.
!    N should be at least 3 for a nonzero result.
!
!    Input, real ( kind = 8 ) V(2,N), the coordinates of the vertices
!    of the polygon.  These vertices should be given in
!    counter clockwise order.
!
!    Output, real ( kind = 8 ) RESULT, the value of the integral.
!
  implicit none

  integer( kind = i4 ),                    intent(in) :: n
  real ( kind = dp ), dimension(dim_num,n), intent(in) :: v
  integer ( kind = i4 ), parameter :: dim_num = 2

  integer ( kind = i4 ) :: i
  integer ( kind = i4 ) :: im1
  real ( kind = dp ) :: result
  

  result = 0.0_dp

  if( n < 3 ) then
      return
  end if
  !dir$ assume_aligned v:64
  !$omp simd simdlen(8) private(im1) reduction(+:result)
  do i = 1, n
    if ( i == 1 ) then
      im1 = n
    else
      im1 = i - 1
    end if
    result = result + ( v(1,i)**3 + v(1,i)**2 * v(1,im1) &
      + v(1,i) * v(1,im1)**2 + v(1,im1)**3 ) * ( v(2,i) - v(2,im1) )
  end do
  result = result / 12.0_dp

end function polygon_xx_2d

subroutine polygon_xy_2d(n,v,result)
        !dir$ attribute forceinline :: polygon_xy_2d
        !dir$ attribute code_align : 32 :: polygon_xy_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=skylake_AVX512 :: polygon_xy_2d
        use omp_lib   
!*****************************************************************************80
!
!! POLYGON_XY_2D integrates the function X*Y over a polygon in 2D.
!
!  Discussion:
!
!    The polygon is bounded by the points (X(1:N), Y(1:N)).
!
!    INTEGRAL = (1/24) * sum ( 1 <= I <= N )
!      ( Y(I)   * ( 3 * X(I)^2 + 2 * X(I) * X(I-1) +     X(I-1)^2 )
!      + Y(I-1) * (     X(I)^2 + 2 * X(I) * X(I-1) + 3 * X(I-1)^2 ) )
!      * ( Y(I) - Y(I-1) )
!
!    where X(0) and Y(0) should be replaced by X(N) and Y(N).
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    10 July 2001
!
!  Author:
!
!    John Burkardt
!
!  Reference:
!
!    SF Bockman,
!    Generalizing the Formula for Areas of Polygons to Moments,
!    American Mathematical Society Monthly,
!    1989, pages 131-132.
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) N, the number of vertices of the polygon.
!    N should be at least 3 for a nonzero result.
!
!    Input, real ( kind = 8 ) V(2,N), the coordinates of the vertices
!    of the polygon.  These vertices should be given in
!    counter clockwise order.
!
!    Output, real ( kind = 8 ) RESULT, the value of the integral.
!
  implicit none

  integer ( kind = i4 ),                    intent(in) :: n
  real ( kind = dp ), dimension(dim_num,n), intent(in) :: v
  integer ( kind = i4 ), parameter :: dim_num = 2

  integer ( kind = i4 ) :: i
  integer ( kind = i4 ) :: im1
  real ( kind = dp ) :: result
  

  result = 0.0_dp

  if( n < 3 ) then
        return
  end if
  !dir$ assume_aligned v:64
  !$omp simd simdlen(8) private(im1) reduction(+:result)
  do i = 1, n
    if ( i == 1 ) then
      im1 = n
    else
      im1 = i - 1
    end if
    result = result + ( &
      v(2,i) * ( 3.0_dp * v(1,i)**2 + 2.0_dp * v(1,i) * v(1,im1) &
      + v(1,im1)**2 ) + v(2,im1) * ( v(1,i)**2 + 2.0_dp * v(1,i) * v(1,im1) &
      + 3.0_dp * v(1,im1)**2 ) ) * ( v(2,i) - v(2,im1) )
  end do

  result = result / 24.0_dp

end function polygon_xy_2d

subroutine polygon_y_2d ( n, v, result )
        !dir$ attribute forceinline :: polygon_y_2d
        !dir$ attribute code_align : 32 :: polygon_y_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=skylake_AVX512 :: polygon_y_2d
        use omp_lib  
!*****************************************************************************80
!
!! POLYGON_Y_2D integrates the function Y over a polygon in 2D.
!
!  Discussion:
!
!    The polygon is bounded by the points (X(1:N), Y(1:N)).
!
!    INTEGRAL = (1/6) * sum ( 1 <= I <= N )
!      - ( Y(I)^2 + Y(I) * Y(I-1) + Y(I-1)^2 ) * ( X(I) - X(I-1) )
!
!    where X(0) and Y(0) should be replaced by X(N) and Y(N).
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    10 July 2001
!
!  Author:
!
!    John Burkardt
!
!  Reference:
!
!    SF Bockman,
!    Generalizing the Formula for Areas of Polygons to Moments,
!    American Mathematical Society Monthly,
!    1989, pages 131-132.
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) N, the number of vertices of the polygon.
!    N should be at least 3 for a nonzero result.
!
!    Input, real ( kind = 8 ) V(2,N), the coordinates of the vertices
!    of the polygon.  These vertices should be given in
!    counter clockwise order.
!
!    Output, real ( kind = 8 ) RESULT, the value of the integral.
!
  implicit none
  real ( kind = dp ) result
  real ( kind = dp ), dimension(dim_num), intent(in) ::  v
  integer ( kind = i4 ) n
  integer ( kind = i4 ), parameter :: dim_num = 2

  integer ( kind = i4 ) i
  integer ( kind = i4 ) im1
  

  result = 0.0_dp

  if ( n < 3 ) then
       return
  end if
  !dir$ assume_aligned v:64
  !$omp simd simdlen(8) reduction(-:result)
  do i = 1, n

    if ( i == 1 ) then
      im1 = n
    else
      im1 = i - 1
    end if

    result = result - ( v(2,i)**2 + v(2,i) * v(2,im1) + v(2,im1)**2 ) &
      * ( v(1,i) - v(1,im1) )

  end do

  result = result / 6.0_dp

 
end subroutine

subroutine polygon_yy_2d ( n, v, result )
        !dir$ attribute forceinline :: polygon_yy_2d
        !dir$ attribute code_align : 32 :: polygon_yy_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=skylake_AVX512 :: polygon_yy_2d
        use omp_lib  
!*****************************************************************************80
!
!! POLYGON_YY_2D integrates the function Y*Y over a polygon in 2D.
!
!  Discussion:
!
!    The polygon is bounded by the points (X(1:N), Y(1:N)).
!
!    INTEGRAL = (1/12) * sum ( 1 <= I <= N )
!      - ( Y(I)^3 + Y(I)^2 * Y(I-1) + Y(I) * Y(I-1)^2 + Y(I-1)^3 )
!      * ( X(I) - X(I-1) )
!
!    where X(0) and Y(0) should be replaced by X(N) and Y(N).
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    10 July 2001
!
!  Author:
!
!    John Burkardt
!
!  Reference:
!
!    SF Bockman,
!    Generalizing the Formula for Areas of Polygons to Moments,
!    American Mathematical Society Monthly,
!    1989, pages 131-132.
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) N, the number of vertices of the polygon.
!    N should be at least 3 for a nonzero result.
!
!    Input, real ( kind = 8 ) V(2,N), the coordinates of the vertices
!    of the polygon.  These vertices should be given in
!    counter clockwise order.
!
!    Output, real ( kind = 8 ) RESULT, the value of the integral.
!
  implicit none
  real ( kind = dp ) result
  real ( kind = dp ), dimension(dim_num,n), intent(in) ::  v 
  integer ( kind = i4 ) n
  integer ( kind = i4 ), parameter :: dim_num = 2

  integer ( kind = i4 ) i
  integer ( kind = i4 ) im1
  

  result = 0.0_dp

  if ( n < 3 ) then
       return
  end if
  !dir$ assume_aligned v:64
  !$omp simd simdlen(8) reduction(+:result)
  do i = 1, n

    if ( i == 1 ) then
      im1 = n
    else
      im1 = i - 1
    end if

    result = result - ( v(2,i)**3 + v(2,i)**2 * v(2,im1) &
      + v(2,i) * v(2,im1)**2 + v(2,im1)**3 ) * ( v(1,i) - v(1,im1) )

  end do

  result = result / 12.0_dp

end subroutine


subroutine angle_box_2d( dist, p1, p2, p3, p4, p5 )
        !dir$ attribute code_align : 32 :: angle_box_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: angle_box_2d
!*****************************************************************************80
!
!! ANGLE_BOX_2D "boxes" an angle defined by three points in 2D.
!
!  Discussion:
!
!    The routine is given points P1, P2 and P3, determining the two lines:
!      P1 to P2
!    and
!      P2 to P3
!    and a nonnegative distance
!      DIST.
!
!    The routine returns a pair of "corner" points
!      P4 and P5
!    both of which are a distance DIST from both lines, and in fact,
!    both of which are a distance DIST from P2.
!
!                         /  P3
!                        /   /   /
!     - - - - - - - - -P4 - / -P6 - - -
!                      /   /   /
!    P1---------------/--P2-----------------
!                    /   /   /
!     - - - - - - -P7 - / -P5 - - - - -
!                  /   /   /
!
!    In the illustration, P1, P2 and P3 are the points defining the lines.
!
!    P4 and P5 represent the desired "corner points", which
!    are on the positive or negative sides of both lines.
!
!    P6 and P7 represent the undesired points, which
!    are on the positive side of one line and the negative of the other.
!
!    Special cases:
!
!    if P1 = P2, this is the same as extending the line from
!    P3 through P2 without a bend.
!
!    if P3 = P2, this is the same as extending the line from
!    P1 through P2 without a bend.
!
!    if P1 = P2 = P3 this is an error.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    05 March 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) DIST, the nonnegative distance from P1
!    to the computed points P4 and P5.
!
!    Input, real ( kind = 8 ) P1(2), P2(2), P3(2).
!    P1 and P2 are distinct points that define a line.
!    P2 and P3 are distinct points that define a line.
!
!    Output, real ( kind = 8 ) P4(2), P5(2), points which lie DIST units from
!    the line between P1 and P2, and from the line between P2 and P3.
!
  implicit none

  integer ( kind = i4 ), parameter :: dim_num = 2

  real ( kind = dp ),                     intent(in)  ::  dist
  real ( kind = dp ), dimension(dim_num), intent(in)  ::  p1
  real ( kind = dp ), dimension(dim_num), intent(in)  ::  p2
  real ( kind = dp ), dimension(dim_num), intent(in)  ::  p3
  real ( kind = dp ), dimension(dim_num), intent(out) ::  p4
  real ( kind = dp ), dimension(dim_num), intent(out) ::  p5
  real ( kind = dp ) :: stheta
  real ( kind = dp ) :: temp1
  real ( kind = dp ) :: temp2
  real ( kind = dp ), dimension(dim_num) :: u
  real ( kind = dp ), dimension(dim_num) :: u1
  real ( kind = dp ), dimension(dim_num) :: u2
!
!  If DIST = 0, assume the user knows best.
!
  if ( dist == 0.0_dp ) then
    p4(1:dim_num) = p2(1:dim_num)
    p5(1:dim_num) = p2(1:dim_num)
    return
  end if
!
!  Fail if all three points are equal.
!
  if ( all ( p1(1:dim_num) == p2(1:dim_num) ) .and. &
       all ( p2(1:dim_num) == p3(1:dim_num) ) ) then
            return
  end if
!
!  If P1 = P2, extend the line through the doubled point.
!
  if ( all ( p1(1:dim_num) == p2(1:dim_num) ) ) then
    u2(1) = p3(2) - p2(2)
    u2(2) = p2(1) - p3(1)
    temp1 = sqrt ( sum ( u2(1:dim_num)**2 ) )
    u2(1:dim_num) = u2(1:dim_num) / temp1
    p4(1:dim_num) = p2(1:dim_num) + dist * u2(1:dim_num)
    p5(1:dim_num) = p2(1:dim_num) - dist * u2(1:dim_num)
    return
  end if
!
!  If P2 = P3, extend the line through the doubled point.
!
  if ( all ( p2(1:dim_num) == p3(1:dim_num) ) ) then
    u1(1) = p1(2) - p2(2)
    u1(2) = p2(1) - p1(1)
    temp1 = sqrt ( sum ( u1(1:dim_num)**2 ) )
    u1(1:dim_num) = u1(1:dim_num) / temp1
    p4(1:dim_num) = p2(1:dim_num) + dist * u1(1:dim_num)
    p5(1:dim_num) = p2(1:dim_num) - dist * u1(1:dim_num)
    return
  end if
!
!  Compute the unit normal vectors to each line.
!  We choose the sign so that the unit normal to line 1 has
!  a positive dot product with line 2.
!
  u1(1) = p1(2) - p2(2)
  u1(2) = p2(1) - p1(1)
  temp1 = sqrt ( sum ( u1(1:dim_num)**2 ) )
  u1(1:dim_num) = u1(1:dim_num) / temp1

  temp1 = dot_product ( u1(1:dim_num), p3(1:dim_num) - p2(1:dim_num) )

  if ( temp1 < 0.0_dp ) then
    u1(1:dim_num) = -u1(1:dim_num)
  end if

  u2(1) = p3(2) - p2(2)
  u2(2) = p2(1) - p3(1)
  temp1 = sqrt ( sum ( u2(1:dim_num)**2 ) )
  u2(1:dim_num) = u2(1:dim_num) / temp1

  temp1 = dot_product ( u2(1:dim_num), p1(1:dim_num) - p2(1:dim_num) )
  if ( temp1 < 0.0_dp ) then
    u2(1:dim_num) = -u2(1:dim_num)
  end if
!
!  Try to catch the case where we can't determine the
!  sign of U1, because both U1 and -U1 are perpendicular
!  to (P3-P2)...and similarly for U2 and (P1-P2).
!
  temp1 = dot_product ( u1(1:dim_num), p3(1:dim_num) - p2(1:dim_num) )
  temp2 = dot_product ( u2(1:dim_num), p1(1:dim_num) - p2(1:dim_num) )

  if ( temp1 == 0.0_dp .or. temp2 == 0.0_dp ) then

    if ( dot_product ( u1(1:dim_num), u2(1:dim_num) ) < 0.0_dp ) then
      u1(1:dim_num) = -u1(1:dim_num)
    end if

  end if
!
!  Try to catch a line turning back on itself, evidenced by
!    Cos(theta) = (P3-P2) dot (P2-P1) / ( norm(P3-P2) * norm(P2-P1) )
!  being -1, or very close to -1.
!
  temp1 = dot_product ( p3(1:dim_num) - p2(1:dim_num), &
                       p2(1:dim_num) - p1(1:dim_num) ) 

  temp1 = temp1 / &
        ( sqrt ( sum ( ( p3(1:dim_num) - p2(1:dim_num) )**2 ) ) &
        * sqrt ( sum ( ( p2(1:dim_num) - p1(1:dim_num) )**2 ) ) )

  if ( temp1 < -0.99_dp ) then
    temp1 = sqrt ( sum ( ( p2(1:dim_num) - p1(1:dim_num) )**2 ) )
    p4(1:dim_num) = p2(1:dim_num) + dist * ( p2(1:dim_num) - p1(1:dim_num) ) &
      / temp1 + dist * u1(1:dim_num)
    p5(1:dim_num) = p2(1:dim_num) + dist * ( p2(1:dim_num) - p1(1:dim_num) ) &
      / temp1 - dist * u1(1:dim_num)
    return
  end if
!
!  Compute the "average" unit normal vector.
!
!  The average of the unit normals could be zero, but only when
!  the second line has the same direction and opposite sense
!  of the first, and we've already checked for that case.
!
!  Well, check again!  This problem "bit" me in the case where
!  P1 = P2, which I now treat specially just to guarantee I
!  avoid this problem!
!
  if ( dot_product ( u1(1:dim_num), u2(1:dim_num) ) < 0.0_dp ) then
    u2(1:dim_num) = -u2(1:dim_num)
  end if

  u(1:dim_num) = 0.5_dp * ( u1(1:dim_num) + u2(1:dim_num) )
  temp1 = sqrt ( sum ( u(1:dim_num)**2 ) )
  u(1:dim_num) = u(1:dim_num) / temp1
!
!  You must go DIST/STHETA units along this unit normal to
!  result in a distance DIST from line1 (and line2).
!
  stheta = dot_product ( u(1:dim_num), u1(1:dim_num) )

  p4(1:dim_num) = p2(1:dim_num) + dist * u(1:dim_num) / stheta
  p5(1:dim_num) = p2(1:dim_num) - dist * u(1:dim_num) / stheta

  
end  subroutine

subroutine angle_contains_point_2d ( p1, p2, p3, p, inside )
        !dir$ attribute forceinline :: angle_contains_point_2d
        !dir$ attribute code_align : 32 :: angle_contains_point_2d
        !dir$ optimize : 3
       
!*****************************************************************************80
!
!! ANGLE_CONTAINS_POINT_2D determines if an angle contains a point, in 2D.
!
!  Discussion:
!
!    The angle is defined by the sequence of points P1, P2 and P3.
!
!    The point is "contained" by the angle if the ray P - P2
!    is between (in a counter clockwise sense) the rays P1 - P2
!    and P3 - P2.
!
!        P1
!        /
!       /   P
!      /  .  
!     / .
!    P2--------->P3
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    15 January 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) P1(2), P2(2), P3(2), the coordinates of
!    three points that define the angle.  The order of these points matters!
!
!    Input, real ( kind = 8 ) P(2), the point to be checked.
!
!    Output, logical INSIDE, is TRUE if the point is inside the angle.
!
  implicit none

 
  logical inside
  real ( kind = dp ) p(2)
  real ( kind = dp ) p1(2)
  real ( kind = dp ) p2(2)
  real ( kind = dp ) p3(2)

  if ( angle_rad_2d ( p1, p2, p ) <= angle_rad_2d ( p1, p2, p3 ) ) then
    inside = .true.
  else
    inside = .false.
  end if

 
end subroutine

function angle_deg_2d ( p1, p2, p3 )
        !dir$ attribute forceinline :: angle_deg_2d
        !dir$ attribute code_align : 32 :: angle_deg_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: angle_deg_2d
!*****************************************************************************80
!
!! ANGLE_DEG_2D returns the angle swept out between two rays in 2D.
!
!  Discussion:
!
!    Except for the zero angle case, it should be true that
!
!      ANGLE_DEG_2D ( P1, P2, P3 ) + ANGLE_DEG_2D ( P3, P2, P1 ) = 360.0
!
!        P1
!        /
!       /    
!      /     
!     /  
!    P2--------->P3
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    14 January 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) P1(2), P2(2), P3(2), define the rays
!    P1 - P2 and P3 - P2 which define the angle.
!
!    Output, real ( kind = 8 ) ANGLE_DEG_2D, the angle swept out by the 
!    rays, measured in degrees.  0 <= ANGLE_DEG_2D < 360.  If either ray 
!    has zero length, then ANGLE_DEG_2D is set to 0.
!
  implicit none

  integer ( kind = i4 ), parameter :: dim_num = 2

  
  real(kind=dp), parameter :: pitwo = 6.283185307179586476925286766559_dp
  real ( kind = dp ) p(dim_num)
  real ( kind = dp ) p1(dim_num)
  real ( kind = dp ) p2(dim_num)
  real ( kind = dp ) p3(dim_num)

  p(1) = ( p3(1) - p2(1) ) * ( p1(1) - p2(1) ) &
       + ( p3(2) - p2(2) ) * ( p1(2) - p2(2) )

  p(2) = ( p3(1) - p2(1) ) * ( p1(2) - p2(2) ) &
       - ( p3(2) - p2(2) ) * ( p1(1) - p2(1) )

  if ( p(1) == 0.0_dp .and. p(2) == 0.0_dp ) then
    angle_deg_2d = 0.0_dp
    return
  end if

  angle_rad_2d = atan2 ( p(2), p(1) )

  if ( angle_rad_2d < 0.0_dp ) then
    angle_rad_2d = angle_rad_2d + pitwo
  end if

  angle_deg_2d = radians_to_degrees ( angle_rad_2d )

end function

subroutine angle_half_2d ( p1, p2, p3, p4 )
        !dir$ attribute forceinline :: angle_half_2d
        !dir$ attribute code_align : 32 :: angle_half_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: angle_half_2d
!*****************************************************************************80
!
!! ANGLE_HALF_2D finds half an angle in 2D.
!
!  Discussion:
!
!    The original angle is defined by the sequence of points P1, P2 and P3.
!
!    The point P4 is calculated so that:
!
!      (P1,P2,P4) = (P1,P2,P3) / 2
!
!        P1
!        /
!       /   P4
!      /  .  
!     / .
!    P2--------->P3
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    01 March 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) P1(2), P2(2), P3(2), points defining the angle. 
!
!    Input, real ( kind = 8 ) P4(2), a point defining the half angle.
!    The vector P4 - P2 will have unit norm.
!
  implicit none

  integer ( kind = i4 ), parameter :: dim_num = 2

  real ( kind = dp ) p1(dim_num)
  real ( kind = dp ) p2(dim_num)
  real ( kind = dp ) p3(dim_num)
  real ( kind = dp ) p4(dim_num)
  real(kind=dp), automatic :: t1,t2,t3
  t1 = p1(1:2)
  t2 = p2(1:2)
  t3 = p3(1:2)
  
  p4(1:2) = 0.5_dp * ( &
      ( t1 - t2 ) / sqrt ( sum ( ( t1 - t2 )**2 ) ) &
    + ( t3 - t2 ) / sqrt ( sum ( ( t3 - t2 )**2 ) ) )

   p4(1:2) = t1 + p4(1:2) / sqrt ( sum ( p4(1:2)**2 ) )

  
end function

function angle_rad_2d ( p1, p2, p3 )
        !dir$ attribute forceinline :: angle_rad_2d
        !dir$ attribute code_align : 32 :: angle_rad_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: angle_rad_2d
!*****************************************************************************80
!
!! ANGLE_RAD_2D returns the angle in radians swept out between two rays in 2D.
!
!  Discussion:
!
!    Except for the zero angle case, it should be true that
!
!      ANGLE_RAD_2D ( P1, P2, P3 ) + ANGLE_RAD_2D ( P3, P2, P1 ) = 2 * PI
!
!        P1
!        /
!       /    
!      /     
!     /  
!    P2--------->P3
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    15 January 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) P1(2), P2(2), P3(2), define the rays
!    P1 - P2 and P3 - P2 which define the angle.
!
!    Output, real ( kind = 8 ) ANGLE_RAD_2D, the angle swept out by the rays,
!    in radians.  0 <= ANGLE_RAD_2D < 2 * PI.  If either ray has zero
!    length, then ANGLE_RAD_2D is set to 0.
!
  implicit none

  integer ( kind = i4 ), parameter :: dim_num = 2

  
  real ( kind = dp ), parameter :: twopi = 6.283185307179586476925286766559_dp
  real ( kind = dp ) p(dim_num)
  real ( kind = dp ) p1(dim_num)
  real ( kind = dp ) p2(dim_num)
  real ( kind = dp ) p3(dim_num)
  real(kind=dp), automatic :: d0,d1,d2,d3
  d0 = p3(1)-p2(1)
  d1 = p1(1)-p2(1)
  d2 = p3(2)-p2(2)
  d3 = p1(2)-p2(2)
  p(1) = d0 * d1 + d2 * d3
  p(2) = d0 * d3 - d2 * d1
       
  if ( all ( p(1:dim_num) == 0.0_dp)  ) then
    angle_rad_2d = 0.0_dp
    return
  end if

  angle_rad_2d = atan2 ( p(2), p(1) )

  if ( angle_rad_2d < 0.0_dp ) then
    angle_rad_2d = angle_rad_2d + twopi
  end if

end function

function angle_rad_3d ( p1, p2, p3 )
        !dir$ attribute forceinline :: angle_rad_3d
        !dir$ attribute code_align : 32 :: angle_rad_3d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: angle_rad_3d
!*****************************************************************************80
!
!! ANGLE_RAD_3D returns the angle in radians between two rays in 3D.
!
!  Discussion:
!
!    The routine always computes the SMALLER of the two angles between
!    two rays.  Thus, if the rays make an (exterior) angle of
!    1.5 pi radians, the (interior) angle of 0.5 pi radians will be reported.
!
!    X dot Y = Norm(X) * Norm(Y) * Cos ( Angle(X,Y) )
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    21 January 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) P1(3), P2(3), P3(3), points defining an angle.
!    The rays are P1 - P2 and P3 - P2.
!
!    Output, real ( kind = 8 ) ANGLE_RAD_3D, the angle between the two rays,
!    in radians.  This value will always be between 0 and PI.  If either ray has
!    zero length, then the angle is returned as zero.
!
  implicit none

  integer ( kind = i4 ), parameter :: dim_num = 4

  real ( kind = dp ) angle_rad_3d
  real ( kind = dp ) dot
  real ( kind = dp ) p1(dim_num)
  real ( kind = dp ) p2(dim_num)
  real ( kind = dp ) p3(dim_num)
  real ( kind = dp ) v1norm
  real ( kind = dp ) v2norm

  v1norm = sqrt ( sum ( ( p1(1:dim_num) - p2(1:dim_num) )**2 ) )

  if ( v1norm == 0.0_dp ) then
    angle_rad_3d = 0.0_dp
    return
  end if

  v2norm = sqrt ( sum ( ( p3(1:dim_num) - p2(1:dim_num) )**2 ) )

  if ( v2norm == 0.0_dp ) then
    angle_rad_3d = 0.0_dp
    return
  end if

  dot = sum ( ( p1(1:dim_num) - p2(1:dim_num) ) &
            * ( p3(1:dim_num) - p2(1:dim_num) ) )

  angle_rad_3d = r8_acos ( dot / ( v1norm * v2norm ) )

 
end function

function angle_rad_nd ( dim_num, v1, v2 )
        !dir$ attribute forceinline :: angle_rad_nd
        !dir$ attribute code_align : 32 :: angle_rad_nd
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: angle_rad_nd
!*****************************************************************************80
!
!! ANGLE_RAD_ND returns the angle in radians between two rays in ND.
!
!  Discussion:
!
!    This routine always computes the SMALLER of the two angles between
!    two rays.  Thus, if the rays make an (exterior) angle of 1.5 PI,
!    then the (interior) angle of 0.5 PI is reported.
!
!    X dot Y = Norm(X) * Norm(Y) * Cos( Angle(X,Y) )
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    19 April 1999
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) DIM_NUM, the spatial dimension.
!
!    Input, real ( kind = 8 ) V1(DIM_NUM), V2(DIM_NUM), the two rays.
!
!    Output, real ( kind = 8 ) ANGLE_RAD_ND, the angle between the rays,
!    in radians.  This value will always be between 0 and PI.
!
  implicit none

  integer ( kind = i4 ) dim_num

 
  real ( kind = dp ) dot
  real ( kind = dp ) v1(dim_num)
  real ( kind = dp ) v1norm
  real ( kind = dp ) v2(dim_num)
  real ( kind = dp ) v2norm

  dot = dot_product ( v1(1:dim_num), v2(1:dim_num) )

  v1norm = sqrt ( sum ( v1(1:dim_num)**2 ) )

  if ( v1norm == 0.0_dp ) then
    angle_rad_nd = 0.0_dp
    return
  end if

  v2norm = sqrt ( sum ( v2(1:dim_num)**2 ) )

  if ( v2norm == 0.0_dp ) then
    angle_rad_nd = 0.0_dp
    return
  end if

  angle_rad_nd = r8_acos ( dot / ( v1norm * v2norm ) )

 
end function

subroutine annulus_area_2d ( r1, r2, area )
        !dir$ attribute forceinline :: annulus_area_2d
        !dir$ attribute code_align : 32 :: annulus_area_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: annulus_area_2d
!*****************************************************************************80
!
!! ANNULUS_AREA_2D computes the area of a circular annulus in 2D.
!
!  Discussion:
!
!    A circular annulus with center (XC,YC), inner radius R1 and
!    outer radius R2, is the set of points (X,Y) so that
!
!      R1^2 <= (X-XC)^2 + (Y-YC)^2 <= R2^2
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    02 August 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) R1, R2, the inner and outer radii.
!
!    Output, real ( kind = 8 ) AREA, the area.
!
  implicit none

  real ( kind = dp ) area
  real ( kind = dp ), parameter :: pi = 3.14159265358979323846264338328_dp
  real ( kind = dp ) r1
  real ( kind = dp ) r2

  area = pi * ( r2 + r1 ) * ( r2 - r1 )

 
end function


subroutine annulus_sector_area_2d ( r1, r2, theta1, theta2, area )
        !dir$ attribute forceinline :: annulus_sector_area_2d
        !dir$ attribute code_align : 32 :: annulus_sector_area_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: annulus_sector_area_2d
!*****************************************************************************80
!
!! ANNULUS_SECTOR_AREA_2D computes the area of an annular sector in 2D.
!
!  Discussion:
!
!    An annular sector with center PC, inner radius R1 and
!    outer radius R2, and angles THETA1, THETA2, is the set of points 
!    P so that
!
!      R1^2 <= (P(1)-PC(1))^2 + (P(2)-PC(2))^2 <= R2^2
!
!    and
!
!      THETA1 <= THETA ( P - PC ) <= THETA2
!
!  Modified:
!
!    02 August 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) R1, R2, the inner and outer radii.
!
!    Input, real ( kind = 8 ) THETA1, THETA2, the angles.
!
!    Output, real ( kind = 8 ) AREA, the area.
!
  implicit none

  real ( kind = dp ) area
  real ( kind = dp ) r1
  real ( kind = dp ) r2
  real ( kind = dp ) theta1
  real ( kind = dp ) theta2

  area = 0.5_dp * ( theta2 - theta1 ) * ( r2 + r1 ) * ( r2 - r1 )

 
end subroutine


subroutine annulus_sector_centroid_2d ( pc, r1, r2, theta1, theta2, centroid )
        !dir$ attribute forceinline :: annulus_sector_centroid_2d
        !dir$ attribute code_align : 32 :: annulus_sector_centroid_2d
        !dir$ optimize : 3
        !dir$ attribute optimization_parameter: target_arch=AVX :: annulus_sector_centroid_2d
!*****************************************************************************80
!
!! ANNULUS_SECTOR_CENTROID_2D computes the centroid of an annular sector in 2D.
!
!  Discussion:
!
!    An annular sector with center PC, inner radius R1 and
!    outer radius R2, and angles THETA1, THETA2, is the set of points 
!    P so that
!
!      R1^2 <= (P(1)-PC(1))^2 + (P(2)-PC(2))^2 <= R2^2
!
!    and
!
!      THETA1 <= THETA ( P - PC ) <= THETA2
!
!    Thanks to Ed Segall for pointing out a mistake in the computation
!    of the angle THETA associated with the centroid.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    02 December 2005
!
!  Author:
!
!    John Burkardt
!
!  Reference:
!
!    John Harris, Horst Stocker,
!    Handbook of Mathematics and Computational Science,
!    Springer, 1998, QA40.S76
!
!  Parameters:
!
!    Input, real ( kind = 8 ) PC(2), the center.
!
!    Input, real ( kind = 8 ) R1, R2, the inner and outer radii.
!
!    Input, real ( kind = 8 ) THETA1, THETA2, the angles.
!
!    Output, real ( kind = 8 ) CENTROID(2), the centroid.
!
  implicit none

  real ( kind = dp ) centroid(2)
  real ( kind = dp ) pc(2)
  real ( kind = dp ) r
  real ( kind = dp ) r1
  real ( kind = dp ) r2
  real ( kind = dp ) theta
  real ( kind = dp ) theta1
  real ( kind = dp ) theta2
  real(kind=dp) :: c0
  theta = theta2 - theta1
  c0 = theta1+theta*0.5_dp
  r = 4.0_dp * sin ( theta*0.5_dp ) / ( 3.0_dp * theta ) &
    * ( r1 * r1 + r1 * r2 + r2 * r2 ) / ( r1 + r2 )

  centroid(1) = pc(1) + r * cos ( c0 )
  centroid(2) = pc(2) + r * sin ( c0 )

 
end subroutine

function box_01_contains_point_2d ( p )
        !dir$ attribute forceinline :: box_01_contains_point_2d
        !dir$ attribute code_align : 32 :: box_01_contains_point_2d
        !dir$ optimize : 3
!*****************************************************************************80
!
!! BOX_01_CONTAINS_POINT_2D determines if a point is inside the unit box in 2D.
!
!  Discussion:
!
!    A unit box is assumed to be a rectangle with sides aligned on coordinate
!    axes.  It can be described as the set of points P satisfying:
!
!      0.0 <= P(1:DIM_NUM) <= 1.0
!
!      0.0 <= P(1:2) <= 1.0 
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    10 May 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) P(2), the point to be checked.
!
!    Output, logical BOX_01_CONTAINS_POINT_2D, is TRUE if the point is 
!    inside the box.
!
  implicit none

  logical box_01_contains_point_2d
  real ( kind = dp ) p(2)

  box_01_contains_point_2d = &
    all ( 0.0_dp <= p(1:2) ) .and. all ( p(1:2) <= 1.0_dp )

 
end function

function box_01_contains_point_nd ( dim_num, p )
        !dir$ attribute forceinline :: box_01_contains_point_nd
        !dir$ attribute code_align : 32 :: box_01_contains_point_nd
        !dir$ optimize : 3
!*****************************************************************************80
!
!! BOX_01_CONTAINS_POINT_ND determines if a point is inside the unit box in ND.
!
!  Discussion:
!
!    A unit box is assumed to be a rectangle with sides aligned on coordinate
!    axes.  It can be described as the set of points P satisfying:
!
!      0.0 <= P(1:DIM_NUM) <= 1.0
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    16 June 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) DIM_NUM, the spatial dimension.
!
!    Input, real ( kind = 8 ) P(DIM_NUM), the point to be checked.
!
!    Output, logical BOX_01_CONTAINS_POINT_ND, is TRUE if the point is 
!    inside the box.
!
  implicit none

  integer ( kind = i4 ) dim_num

  logical box_01_contains_point_nd
  real ( kind = dp ) p(dim_num)

  box_01_contains_point_nd = &
    all ( 0.0_dp <= p(1:dim_num) ) .and. all ( p(1:dim_num) <= 1.0_dp )

 
end function

function box_contains_point_2d ( p1, p2, p )
        !dir$ attribute forceinline :: box_contains_point_2d
        !dir$ attribute code_align : 32 :: box_contains_point_2d
        !dir$ optimize : 3
!*****************************************************************************80
!
!! BOX_CONTAINS_POINT_2D determines if a point is inside a box in 2D.
!
!  Discussion:
!
!    A box in 2D is a rectangle with sides aligned on coordinate
!    axes.  It can be described by its low and high corners, P1 and P2
!    as the set of points P satisfying:
!
!      P1(1:2) <= P(1:2) <= P2(1:2).
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    16 June 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, real ( kind = 8 ) P1(2), P2(2), the low and high 
!    corners of the box.
!
!    Input, real ( kind = 8 ) P(2), the point to be checked.
!
!    Output, logical BOX_CONTAINS_POINT_2D, is TRUE if the point 
!    is inside the box.
!
  implicit none

  logical box_contains_point_2d
  real ( kind = dp ) p(2)
  real ( kind = dp ) p1(2)
  real ( kind = dp ) p2(2)

  if ( p(1)  < p1(1) .or. &
       p2(1) < p(1)  .or. &
       p(2)  < p1(2) .or. &
       p2(2) < p(2) ) then
    box_contains_point_2d = .false.
  else
    box_contains_point_2d = .true.
  end if

 
end function 

function box_contains_point_nd ( dim_num, p1, p2, p )
        !dir$ attribute forceinline :: box_contains_point_nd
        !dir$ attribute code_align : 32 :: box_contains_point_nd
        !dir$ optimize : 3
!*****************************************************************************80
!
!! BOX_CONTAINS_POINT_ND determines if a point is inside a box in ND.
!
!  Discussion:
!
!    A box is a rectangle with sides aligned on coordinate
!    axes.  It can be described by its low and high corners, P1 and P2
!    as the set of points P satisfying:
!
!      P1(1:DIM_NUM) <= P(1:DIM_NUM) <= P2(1:DIM_NUM).
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    28 February 2005
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) DIM_NUM, the spatial dimension.
!
!    Input, real ( kind = 8 ) P1(DIM_NUM), P2(DIM_NUM), the low and high 
!    corners of the box.
!
!    Input, real ( kind = 8 ) P(DIM_NUM), the point to be checked.
!
!    Output, logical BOX_CONTAINS_POINT_ND, is TRUE if the point 
!    is inside the box.
!
  implicit none

  integer ( kind = i4 ) dim_num

  logical box_contains_point_nd
  integer ( kind = i4 ) i
  real ( kind = dp) p(dim_num)
  real ( kind = dp ) p1(dim_num)
  real ( kind = dp ) p2(dim_num)

  box_contains_point_nd = .false.

  do i = 1, dim_num
    if ( p(i) < p1(i) .or. p2(i) < p(i) ) then
      return
    end if
  end do

  box_contains_point_nd = .true.

 
end function

end module geometry_helpers
