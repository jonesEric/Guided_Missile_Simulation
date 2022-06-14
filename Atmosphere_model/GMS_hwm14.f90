!!!
!!!  Horizontal Wind Model 14
!!!
!!!  AUTHORS
!!!    Douglas Drob  (0 to ~450+ km, quite-time)
!!!    John Emmert   (disturbance winds, DWM Emmert et al., (2008))
!!!    Geospace Science and Technology Branch
!!!    Space Science Division
!!!    Naval Research Laboratory
!!!    4555 Overlook Ave.
!!!    Washington, DC 20375
!!!
!!!  Point of Contact
!!!   douglas.drob@nrl.navy.mil
!!!
!!!   DATE
!!!    July 8, 2014
!!!
!!!
!!!
!!!============================================================================
!!! Input arguments:
!!!        iyd - year and day as yyddd
!!!        sec - ut(sec)
!!!        alt - altitude(km)
!!!        glat - geodetic latitude(deg)
!!!        glon - geodetic longitude(deg)
!!!        stl - not used
!!!        f107a - not used
!!!        f107 - not used
!!!        ap - two element array with
!!!             ap(1) = not used
!!!             ap(2) = current 3hr ap index
!!!
!!! Output argument:
!!!        w(1) = meridional wind (m/sec + northward)
!!!        w(2) = zonal wind (m/sec + eastward)
!!!
!!!============================================================================


module hwm

    integer(4)           :: nmaxhwm = 0        ! maximum degree hwmqt
    integer(4)           :: omaxhwm = 0        ! maximum order hwmqt
    integer(4)           :: nmaxdwm = 0        ! maximum degree hwmqt
    integer(4)           :: mmaxdwm = 0        ! maximum order hwmqt
    integer(4)           :: nmaxqdc = 0        ! maximum degree of coordinate coversion
    integer(4)           :: mmaxqdc = 0        ! maximum order of coordinate coversion
    integer(4)           :: nmaxgeo = 0        ! maximum of nmaxhwm, nmaxqd
    integer(4)           :: mmaxgeo = 0        ! maximum of omaxhwm, nmaxqd
   
    real(8),allocatable  :: gpbar(:,:),gvbar(:,:),gwbar(:,:) ! alfs for geo coordinates
    real(8),allocatable  :: spbar(:,:),svbar(:,:),swbar(:,:) ! alfs MLT calculation
    !dir$ attributes align : 64 :: gpbar
    !dir$ attributes align : 64 :: gvbar
    !dir$ attributes align : 64 :: gwbar
    !dir$ attributes align : 64 :: spbar
    !dir$ attributes align : 64 :: svbar
    !dir$ attributes align : 64 :: swbar

    real(8)              :: glatalf = -1.d32

    character(240)       :: pathdefault = ''

    logical              :: hwminit = .true.

end module hwm

subroutine hwm14(iyd,sec,alt,glat,glon,stl,f107a,f107,ap,path,w,rc)
      !dir$ attributes code_align : 32 :: hwm14
      !dir$ optimize : 3
    use hwm
    use ipe_error_module
    implicit none
    integer(4),     intent(in)  :: iyd
    real(4),        intent(in)  :: sec,alt,glat,glon,stl,f107a,f107
    real(4),        intent(in)  :: ap(2)
    real(4),        intent(out) :: w(2)
    real(4)                     :: dw(2)
    character(250), intent(in)  :: path
    integer,        intent(out) :: rc

    integer :: localrc

    rc = IPE_SUCCESS

    pathdefault = path
    if (hwminit) then
      call inithwm(localrc)
      if (ipe_error_check(localrc,msg="hwm14: call to inithwm failed",rc=rc)) return
    end if

    call hwmqt(iyd,sec,alt,glat,glon,stl,f107a,f107,ap,w,localrc)
    if (ipe_error_check(localrc,msg="hwm14: call to hwmqt failed",rc=rc)) return

    if (ap(2) .ge. 0.0) then
        call dwm07(iyd,sec,alt,glat,glon,ap,dw,localrc)
        if (ipe_error_check(localrc,msg="hwm14: call to dwm07 failed",rc=rc)) return
        w = w + dw
    endif

    return

end subroutine hwm14

! #############################################################################
! Portable utility to compute vector spherical harmonical harmonic basis functions
! ##############################################################################

module alf

    implicit none

    integer(4)              :: nmax0,mmax0

    ! static normalizational coeffiecents

    real(8), allocatable    :: anm(:,:),bnm(:,:),dnm(:,:)
    real(8), allocatable    :: cm(:),en(:)
    real(8), allocatable    :: marr(:),narr(:)
    !dir$ attributes align : 64 :: anm
    !dir$ attributes align : 64 :: bnm
    !dir$ attributes align : 64 :: dnm
    !dir$ attributes align : 64 :: cm
    !dir$ attributes align : 64 :: en
    !dir$ attributes align : 64 :: marr
    !dir$ attributes align : 64 :: narr

contains

    ! -------------------------------------------------------------
    ! routine to compute vector spherical harmonic basis functions
    ! -------------------------------------------------------------

    subroutine alfbasis(nmax,mmax,theta,P,V,W)
         !dir$ attributes forceinline :: alfbasis
         !dir$ attributes code_align : 32 :: alfbasis
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: alfbasis
        implicit none

        integer(4), intent(in)  :: nmax, mmax
        real(8), intent(in)     :: theta
        real(8), intent(out)    :: P(0:nmax,0:mmax)
        real(8), intent(out)    :: V(0:nmax,0:mmax)
        real(8), intent(out)    :: W(0:nmax,0:mmax)

        integer(8)              :: n, m
        real(8)                 :: x, y
        real(8), parameter      :: p00 = 0.70710678118654746d0

        P(0,0) = p00
        x = dcos(theta)
        y = dsin(theta)
        !dir$ assume_aligned P:64
        !dir$ assume_aligned V:64
        !dir$ assume_aligned W:64
        do m = 1, mmax
            W(m,m) = cm(m) * P(m-1,m-1)
            P(m,m) = y * en(m) * W(m,m)
            do n = m+1, nmax
                W(n,m) = anm(n,m) * x * W(n-1,m) - bnm(n,m) * W(n-2,m)
                P(n,m) = y * en(n) * W(n,m)
                V(n,m) = narr(n) * x * W(n,m) - dnm(n,m) * W(n-1,m)
                W(n-2,m) = marr(m) * W(n-2,m)
            enddo
            W(nmax-1,m) = marr(m) * W(nmax-1,m)
            W(nmax,m) = marr(m) * W(nmax,m)
            V(m,m) = x * W(m,m)
        enddo
        P(1,0) = anm(1,0) * x * P(0,0)
        V(1,0) = -P(1,1)
        do n = 2, nmax
            P(n,0) = anm(n,0) * x * P(n-1,0) - bnm(n,0) * P(n-2,0)
            V(n,0) = -P(n,1)
        enddo

        return

    end subroutine alfbasis

    ! -----------------------------------------------------
    ! routine to compute static normalization coeffiecents
    ! -----------------------------------------------------

    subroutine initalf(nmaxin,mmaxin)
         !dir$ attributes forceinline :: initalf
         !dir$ attributes code_align : 32 :: initalf
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: initalf
        use omp_lib
        implicit none

        integer(4), intent(in) :: nmaxin, mmaxin
        integer(8)             :: n, m   ! 64 bits to avoid overflow for (m,n) > 60

        nmax0 = nmaxin
        mmax0 = mmaxin

        if (allocated(anm)) deallocate(anm, bnm, cm, dnm, en, marr, narr)
        allocate( anm(0:nmax0, 0:mmax0) )
        allocate( bnm(0:nmax0, 0:mmax0) )
        allocate( cm(0:mmax0) )
        allocate( dnm(0:nmax0, 0:mmax0) )
        allocate( en(0:nmax0) )
        allocate( marr(0:mmax0) )
        allocate( narr(0:nmax0) )
        !dir$ assume_aligned narr:64
        !dir$ assume_aligned en:64
        !dir$ assume_aligned anm:64
        !dir$ assume_aligned bnm:64
        !dir$ ivdep
        !$omp simd simdlen(8) linear(n:1)
        do n = 1, nmax0
            narr(n) = dble(n)
            en(n)    = dsqrt(dble(n*(n+1)))
            anm(n,0) = dsqrt( dble((2*n-1)*(2*n+1)) ) / narr(n)
            bnm(n,0) = dsqrt( dble((2*n+1)*(n-1)*(n-1)) / dble(2*n-3) ) / narr(n)
        end do
        do m = 1, mmax0
            marr(m) = dble(m)
            cm(m)    = dsqrt(dble(2*m+1)/dble(2*m*m*(m+1)))
            !dir$ assume_aligned anm:64
            !dir$ assume_aligned bnm:64
            !dir$ assume_aligned dnm:64
            !dir$ ivdep
            !$omp simd simdlen(8) linear(n:1)
            do n = m+1, nmax0
                anm(n,m) = dsqrt( dble((2*n-1)*(2*n+1)*(n-1)) / dble((n-m)*(n+m)*(n+1)) )
                bnm(n,m) = dsqrt( dble((2*n+1)*(n+m-1)*(n-m-1)*(n-2)*(n-1)) &
                    / dble((n-m)*(n+m)*(2*n-3)*n*(n+1)) )
                dnm(n,m) = dsqrt( dble((n-m)*(n+m)*(2*n+1)*(n-1)) / dble((2*n-1)*(n+1)) )
            end do
        enddo

        return

    end subroutine initalf

end module alf

!###############################################################################
! Model Modules
!###############################################################################

module qwm

    implicit none

    integer(4)                 :: nbf              ! Count of basis terms per model level
    integer(4)                 :: maxn             ! latitude
    integer(4)                 :: maxs,maxm,maxl   ! seasonal,stationary,migrating
    integer(4)                 :: maxo

    integer(4)                 :: p                ! B-splines order, p=4 cubic, p=3 quadratic
    integer(4)                 :: nlev             ! e.g. Number of B-spline nodes
    integer(4)                 :: nnode            ! nlev + p

    real(8)                    :: alttns           ! Transition 1
    real(8)                    :: altsym           ! Transition 2
    real(8)                    :: altiso           ! Constant Limit
    real(8)                    :: e1(0:4)
    real(8)                    :: e2(0:4)
    real(8),parameter          :: H = 60.0d0

    integer(4),allocatable     :: nb(:)            ! total number of basis functions @ level
    integer(4),allocatable     :: order(:,:)       ! spectral content @ level
    real(8),allocatable        :: vnode(:)         ! Vertical Altitude Nodes
    real(8),allocatable        :: mparm(:,:)       ! Model Parameters
    real(8),allocatable        :: tparm(:,:)       ! Model Parameters
    !dir$ attributes align : 64 :: nb
    !dir$ attributes align : 64 :: order
    !dir$ attributes align : 64 :: vnode
    !dir$ attributes align : 64 :: mparm
    !dir$ attributes align : 64 :: tparm
    real(8)                    :: previous(1:5) = -1.0d32
    integer(4)                 :: priornb = 0

    real(8),allocatable        :: fs(:,:),fm(:,:),fl(:,:)
    real(8),allocatable        :: bz(:),bm(:)
    !dir$ attributes align : 64 :: fs
    !dir$ attributes align : 64 :: fm
    !dir$ attributes align : 64 :: fl
    !dir$ attributes align : 64 :: bz
    !dir$ attributes align : 64 :: bm
    real(8),allocatable        :: zwght(:)
    !dir$ attributes align : 64 :: zwght
    integer(4)                 :: lev

    integer(4)                 :: cseason = 0
    integer(4)                 :: cwave = 0
    integer(4)                 :: ctide = 0

    logical                    :: content(5) = .true.          ! Season/Waves/Tides
    logical                    :: component(0:1) = .true.      ! Compute zonal/meridional

    character(250)             :: qwmdefault = 'hwm123114.bin'
    logical                    :: qwminit = .true.

    real(8)                    :: wavefactor(4) = 1.0
    real(8)                    :: tidefactor(4) = 1.0

end module qwm

module dwm

    implicit none

    integer(4)                 :: nterm             ! Number of terms in the model
    integer(4)                 :: nmax,mmax         ! Max latitudinal degree
    integer(4)                 :: nvshterm          ! # of VSH basis functions

    integer(4),allocatable     :: termarr(:,:)      ! 3 x nterm index of coupled terms
    real(4),allocatable        :: coeff(:)          ! Model coefficients
    real(4),allocatable        :: vshterms(:,:)     ! VSH basis values
    real(4),allocatable        :: termval(:,:)      ! Term values to which coefficients are applied
    real(8),allocatable        :: dpbar(:,:)        ! Associated lengendre fns
    real(8),allocatable        :: dvbar(:,:)
    real(8),allocatable        :: dwbar(:,:)
    real(8),allocatable        :: mltterms(:,:)     ! MLT Fourier terms
    !dir$ attributes align : 64 :: termarr
    !dir$ attributes align : 64 :: coeff
    !dir$ attributes align : 64 :: vshterms
    !dir$ attributes align : 64 :: termval
    !dir$ attributes align : 64 :: dpbar
    !dir$ attributes align : 64 :: dvbar
    !dir$ attributes align : 64 :: dwbar
    !dir$ attributes align : 64 :: mltterms
    real(4)                    :: twidth            ! Transition width of high-lat mask

    real(8), parameter         :: pi=3.1415926535897932
    real(8), parameter         :: dtor=pi/180.d0

    logical                    :: dwminit = .true.
    character(250)             :: dwmdefault = 'dwm07b104i.dat'

end module dwm

subroutine inithwm(rc)
         !dir$ attributes code_align : 32 :: inithwm
         !dir$ optimize : 3
    use hwm
    use qwm
    use dwm
    use alf,only:initalf
    use ipe_error_module

    implicit none

    integer, intent(out) :: rc

    integer    :: lrc, stat
    integer(4) :: nmax0, mmax0

    rc = IPE_SUCCESS

    qwmdefault = trim(pathdefault)//trim(qwmdefault)
    dwmdefault = trim(pathdefault)//trim(dwmdefault)
    call initqwm(qwmdefault,lrc)
    if (ipe_error_check(lrc,msg="inithwm: call to initqwm failed",rc=rc)) return

    call initdwm(nmaxdwm, mmaxdwm, lrc)
    if (ipe_error_check(lrc,msg="inithwm: call to initdwm failed",rc=rc)) return

    nmaxgeo = max(nmaxhwm, nmaxqdc)
    mmaxgeo = max(omaxhwm, mmaxqdc)

    nmax0 = max(nmaxgeo, nmaxdwm)
    mmax0 = max(mmaxgeo, mmaxdwm)

    call initalf(nmax0,mmax0)

    ! shared for QWM and DWM, no need to compute twice

    if (allocated(gpbar)) then
      deallocate(gpbar,gvbar,gwbar,stat=stat)
      if (ipe_dealloc_check(stat, &
        msg="inithwm: failed to deallocate gpbar,gvbar,gwbar", rc=rc)) return
    endif
    allocate(gpbar(0:nmaxgeo,0:mmaxgeo), &
             gvbar(0:nmaxgeo,0:mmaxgeo), &
             gwbar(0:nmaxgeo,0:mmaxgeo), stat=stat)
    if (ipe_alloc_check(stat, &
      msg="inithwm: failed to allocate gpbar,gvbar,gwbar", rc=rc)) return

    gpbar = 0
    gvbar = 0
    gwbar = 0

    if (allocated(spbar)) then
      deallocate(spbar,svbar,swbar,stat=stat)
      if (ipe_dealloc_check(stat, &
        msg="inithwm: failed to deallocate spbar,svbar,swbar", rc=rc)) return
    endif
    allocate(spbar(0:nmaxgeo,0:mmaxgeo), &
             svbar(0:nmaxgeo,0:mmaxgeo), &
             swbar(0:nmaxgeo,0:mmaxgeo), stat=stat)
    if (ipe_alloc_check(stat, &
      msg="inithwm: failed to allocate spbar,svbar,swbar", rc=rc)) return

    spbar = 0
    svbar = 0
    swbar = 0

    hwminit = .false.

    return

end subroutine inithwm

! ##############################################################################
!                               The quiet time model functions
! ##############################################################################

!============================================================================
! A routine to load the quiet time HWM coeffiecents into memory
!============================================================================

subroutine initqwm(filename,rc)
         !dir$ attributes code_align : 32 :: initqwm
         !dir$ optimize : 3
    use qwm
    use hwm,only:omaxhwm,nmaxhwm
    use ipe_error_module

    implicit none

    character(128), intent(in)    :: filename
    integer,        intent(out)   :: rc
    integer(4)                    :: i,j
    integer(4)                    :: ncomp

    integer :: ios, lrc, stat

    rc = IPE_SUCCESS

    if (allocated(vnode)) then
        deallocate(order,nb,vnode,mparm,tparm,&
                   fs,fm,fl,zwght,bz,bm,stat=stat)
        if (ipe_dealloc_check(stat, msg="initqwm: unable to deallocate memory", rc=rc)) return
    endif

    call findandopen(filename,23,lrc)
    if (ipe_error_check(lrc,msg="initqwm: call to findandopen failed",&
      rc=rc)) return

    read(23,iostat=ios) nbf,maxs,maxm,maxl,maxn,ncomp
    if (ipe_iostatus_check(ios,msg="initqwm: error reading nbf,maxs,maxm,maxl,maxn,ncomp",&
      rc=rc)) return
    read(23,iostat=ios) nlev,p
    if (ipe_iostatus_check(ios,msg="initqwm: error reading nlev, p", &
      rc=rc)) return
    nnode = nlev + p
    allocate(nb(0:nnode),order(ncomp,0:nnode),vnode(0:nnode),stat=stat)
    if (ipe_alloc_check(stat,msg="initqwm: failed to allocate nb, order, vnode", rc=rc)) return
    read(23,iostat=ios) vnode
    if (ipe_iostatus_check(ios,msg="initqwm: error reading vnode",rc=rc)) return
    vnode(3) = 0.0
    allocate(mparm(nbf,0:nlev),stat=stat)
    if (ipe_alloc_check(stat,msg="initqwm: failed to allocate mparm", rc=rc)) return
    mparm = 0.0d0
    do i = 0,nlev-p+1-2
        read(23,iostat=ios) order(1:ncomp,i)
        if (ipe_iostatus_check(ios,msg="initqwm: error reading order array",rc=rc)) return
        read(23,iostat=ios) nb(i)
        if (ipe_iostatus_check(ios,msg="initqwm: error reading nb array",rc=rc)) return
        read(23,iostat=ios) mparm(1:nbf,i)
        if (ipe_iostatus_check(ios,msg="initqwm: error reading mparm array",rc=rc)) return
    enddo
    read(23,iostat=ios) e1,e2
    if (ipe_iostatus_check(ios,msg="initqwm: error reading e1,e2",rc=rc)) return
    close(23,iostat=ios)
    if (ipe_iostatus_check(ios,msg="initqwm: error closing file "//filename,rc=rc)) return

    ! Calculate the parity relationship permutations

    allocate(tparm(nbf,0:nlev),stat=stat)
    if (ipe_alloc_check(stat,msg="initqwm: unable to allocate tparm", rc=rc)) return
    do i = 0,nlev-p+1-2
        call parity(order(:,i),nb(i),mparm(:,i),tparm(:,i))
    enddo

    ! Set transition levels

    alttns = vnode(nlev-2)
    altsym = vnode(nlev-1)
    altiso = vnode(nlev)

    ! Allocate the global store of quasi-static parameters

    maxo = max(maxs,maxm,maxl)
    omaxhwm = maxo
    nmaxhwm = maxn

    allocate(fs(0:maxs,2),fm(0:maxm,2),fl(0:maxl,2),&
             bz(nbf),bm(nbf), &
             zwght(0:p), stat=stat)
    if (ipe_alloc_check(stat,&
      msg="initqwm: unable to allocate fs, fm, fl, bz, bm, zwght", rc=rc)) return

    bz = 0.0d0
    bm = 0.0d0

    ! change the initalization flag and reset some other things

    previous(1:5) = -1.0d32
    qwminit = .false.
    qwmdefault = filename

    return

contains

    subroutine parity(order,nb,mparm,tparm)
         !dir$ attributes forceinline :: parity
         !dir$ attributes code_align : 32 :: parity
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: parity
        use omp_lib
        implicit none

        integer(4),intent(in)     :: order(8)
        integer(4),intent(in)     :: nb
        real(8),intent(inout)     :: mparm(nb)
        real(8),intent(out)       :: tparm(nb)

        integer(4)                :: c,m,n,s,l

        integer(4)                :: amaxs,amaxn
        integer(4)                :: pmaxm,pmaxs,pmaxn
        integer(4)                :: tmaxl,tmaxs,tmaxn

        amaxs = order(1)
        amaxn = order(2)
        pmaxm = order(3)
        pmaxs = order(4)
        pmaxn = order(5)
        tmaxl = order(6)
        tmaxs = order(7)
        tmaxn = order(8)

        c = 1
        !dir$ assume_aligned tparm:64
        !dir$ assume_aligned mparm:64
        !dir$ ivdep
        !dir$ code_align(32)
        !$omp simd simdlen(8) linear(n:1)
        do n = 1,amaxn
            tparm(c) = 0.0
            tparm(c+1) = -mparm(c+1)
            mparm(c+1) = 0.0
            c = c + 2
        enddo
         !dir$ code_align(32) 
        do s = 1,amaxs
              !dir$ assume_aligned tparm:64
              !dir$ assume_aligned mparm:64
              !dir$ code_align(32)
              !dir$ ivdep
              !$omp simd simdlen(8) linear(n:1)
            do n = 1,amaxn
                tparm(c) = 0.0
                tparm(c+1) = 0.0
                tparm(c+2) = -mparm(c+2)
                tparm(c+3) = -mparm(c+3)
                mparm(c+2) = 0.0
                mparm(c+3) = 0.0
                c = c + 4
            enddo
        enddo
         !dir$ code_align(32)
        do m = 1,pmaxm
              !dir$ assume_aligned tparm:64
              !dir$ assume_aligned mparm:64
              !dir$ ivdep
              !dir$ code_align(32)
              !$omp simd simdlen(8) linear(n:1)
            do n = m,pmaxn
                tparm(c) = mparm(c+2)
                tparm(c+1) = mparm(c+3)
                tparm(c+2) = -mparm(c)
                tparm(c+3) = -mparm(c+1)
                c = c + 4
            enddo
              !dir$ code_align(32)
            do s = 1,pmaxs
                 !dir$ assume_aligned tparm:64
                 !dir$ assume_aligned mparm:64
                 !dir$ code_align(32)
                 !dir$ ivdep
                 !$omp simd simdlen(8) linear(n:1)
                do n = m,pmaxn
                    tparm(c) = mparm(c+2)
                    tparm(c+1) = mparm(c+3)
                    tparm(c+2) = -mparm(c)
                    tparm(c+3) = -mparm(c+1)
                    tparm(c+4) = mparm(c+6)
                    tparm(c+5) = mparm(c+7)
                    tparm(c+6) = -mparm(c+4)
                    tparm(c+7) = -mparm(c+5)
                    c = c + 8
                enddo
            enddo

        enddo
         !dir$ code_align(32)
        do l = 1,tmaxl
                 !dir$ assume_aligned tparm:64
                 !dir$ assume_aligned mparm:64
                 !dir$ code_align(32)
                 !dir$ ivdep
                 !$omp simd simdlen(8) linear(n:1)
            do n = l,tmaxn
                tparm(c) = mparm(c+2)
                tparm(c+1) = mparm(c+3)
                tparm(c+2) = -mparm(c)
                tparm(c+3) = -mparm(c+1)
                c = c + 4
             enddo
            !dir$ code_align(32)
             do s = 1,tmaxs
                 !dir$ assume_aligned tparm:64
                 !dir$ assume_aligned mparm:64
                 !dir$ code_align(32)
                 !dir$ ivdep
                 !$omp simd simdlen(8) linear(n:1)
                do n = l,tmaxn
                    tparm(c) = mparm(c+2)
                    tparm(c+1) = mparm(c+3)
                    tparm(c+2) = -mparm(c)
                    tparm(c+3) = -mparm(c+1)
                    tparm(c+4) = mparm(c+6)
                    tparm(c+5) = mparm(c+7)
                    tparm(c+6) = -mparm(c+4)
                    tparm(c+7) = -mparm(c+5)
                    c = c + 8
                enddo
            enddo
        enddo

        return

    end subroutine parity

end subroutine initqwm

! ------------------------------------------------------------
! The quiet time only HWM function call
! ------------------------------------------------------------

subroutine hwmqt(IYD,SEC,ALT,GLAT,GLON,STL,F107A,F107,AP,W,rc)
         !dir$ attributes code_align : 32 :: hwmqt
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: hwmqt
    use hwm
    use qwm
    use alf,only:alfbasis
    use ipe_error_module

    implicit none

    integer, intent(in)  :: IYD
    real(4), intent(in)  :: SEC,ALT,GLAT,GLON,STL,F107A,F107
    real(4), intent(in)  :: AP(2)
    real(4), intent(out) :: W(2)
    integer, intent(out) :: rc

    ! Local variables

    real(8)                 :: input(5)
    real(8)                 :: u,v

    real(8)                 :: cs,ss,cm,sm,cl,sl
    real(8)                 :: cmcs,smcs,cmss,smss
    real(8)                 :: clcs,slcs,clss,slss
    real(8)                 :: AA,BB,CC,DD
    real(8)                 :: vb,wb
    real(8)                 :: theta,sc

    integer                 :: lrc
    integer(4)              :: b,c,d,m,n,s,l

    integer(4)              :: amaxs,amaxn
    integer(4)              :: pmaxm,pmaxs,pmaxn
    integer(4)              :: tmaxl,tmaxs,tmaxn

    logical                 :: refresh(5)

    real(8),parameter       :: twoPi = 2.0d0*3.1415926535897932384626433832795d0
    real(8),parameter       :: deg2rad = twoPi/360.0d0

    rc = IPE_SUCCESS

    ! ====================================================================
    ! Update VSH model terms based on any change in the input parameters
    ! ====================================================================

    if (qwminit) then
      call initqwm(qwmdefault,lrc)
      if (ipe_error_check(lrc,msg="hwmqt: call to initqwm failed",rc=rc)) return
    endif

    input(1) = dble(mod(IYD,1000))
    input(2) = dble(sec)
    input(3) = dble(glon)
    input(4) = dble(glat)
    input(5) = dble(alt)

    refresh(1:5) = .false.

    ! Seasonal variations
    if (input(1) .ne. previous(1)) then
        AA = input(1)*twoPi/365.25d0
        do s = 0,MAXS
            BB = dble(s)*AA
            fs(s,1) = dcos(BB)
            fs(s,2) = dsin(BB)
        enddo
        refresh(1:5) = .true.
        previous(1) = input(1)
    endif

    ! Hourly time changes, tidal variations

    if (input(2) .ne. previous(2) .or. input(3) .ne. previous(3)) then
        AA = mod(input(2)/3600.d0 + input(3)/15.d0 + 48.d0,24.d0)
        BB = AA*twoPi/24.d0
        do l = 0,MAXL
            CC = dble(l)*BB
            fl(l,1) = dcos(CC)
            fl(l,2) = dsin(CC)
        enddo
        refresh(3) = .true.   ! tides
        previous(2) = input(2)
    endif

    ! Longitudinal variations, stationary planetary waves

    if (input(3) .ne. previous(3)) then
        AA = input(3)*deg2rad
        do m = 0,MAXM
            BB = dble(m)*AA
            fm(m,1) = dcos(BB)
            fm(m,2) = dsin(BB)
        enddo
        refresh(2) = .true.   ! stationary planetary waves
        previous(3) = input(3)
    endif

    ! Latitude

    theta = (90.0d0 - input(4))*deg2rad
    if (input(4) .ne. glatalf) then
        AA = (90.0d0 - input(4))*deg2rad        ! theta = colatitude in radians
        call alfbasis(maxn,maxm,AA,gpbar,gvbar,gwbar)
        refresh(1:4) = .true.
        glatalf = input(4)
        previous(4) = input(4)
    endif

    ! Altitude

    if (input(5) .ne. previous(5)) then
        call vertwght(input(5),zwght,lev)
        previous(5) = input(5)
    endif

    ! ====================================================================
    ! Calculate the VSH functions
    ! ====================================================================

    u = 0.0d0
    v = 0.0d0

    do b = 0,p

        if (zwght(b) .eq. 0.d0) cycle

        d = b + lev

        if (priornb .ne. nb(d)) refresh(1:5) = .true. ! recalculate basis functions
        priornb = nb(d)

        if (.not. any(refresh)) then
            c = nb(d)
            if (component(0)) u = u + zwght(b)*dot_product(bz(1:c),mparm(1:c,d))
            if (component(1)) v = v + zwght(b)*dot_product(bz(1:c),tparm(1:c,d))
            cycle
        endif

        amaxs = order(1,d)
        amaxn = order(2,d)
        pmaxm = order(3,d)
        pmaxs = order(4,d)
        pmaxn = order(5,d)
        tmaxl = order(6,d)
        tmaxs = order(7,d)
        tmaxn = order(8,d)

        c = 1

        ! ------------- Seasonal - Zonal average (m = 0) ----------------

        if (refresh(1) .and. content(1)) then
           !dir$ assume_aligned bz:64
           !dir$ ivdep
           !dir$ code_align(32)
           !$omp simd simdlen(8) linear(n:1)
            do n = 1,amaxn               ! s = 0
                bz(c) = -dsin(n*theta)   !
                bz(c+1) = dsin(n*theta)
                c = c + 2
            enddo
            do s = 1,amaxs                   ! Seasonal variations
                cs = fs(s,1)
                ss = fs(s,2)
                 !dir$ assume_aligned bz:64
                 !dir$ ivdep
                 !dir$ code_align(32)
                 !$omp simd simdlen(8) linear(n:1) private(sc)
                do n = 1,amaxn
                    sc = dsin(n*theta)
                    bz(c) = -sc*cs   ! Cr     A
                    bz(c+1) = sc*ss  ! Ci     B
                    bz(c+2) = sc*cs
                    bz(c+3) = -sc*ss
                    c = c + 4
                enddo
            enddo
            cseason = c
        else
            c = cseason
        endif

        ! ---------------- Stationary planetary waves --------------------

        if (refresh(2) .and. content(2)) then
           !dir$ code_align(32)
           !dir$ ivdep
           !dir$ assume_aligned fm:64,wavefactor:64
            do m = 1,pmaxm
                cm = fm(m,1)*wavefactor(m)
                sm = fm(m,2)*wavefactor(m)
                !dir$ code_align(32)
                !dir$ ivdep
                !dir$ assume_aligned gvbar:64
                !dir$ assume_aligned gwbar:64
                !dir$ assume_aligned bz:64
                !$omp simd simdlen(8) linear(n:1) private(vb,wb)
                do n = m,pmaxn           ! s = 0
                    vb = gvbar(n,m)
                    wb = gwbar(n,m)
                    bz(c) =   -vb*cm    ! Cr * (cm) * -vb   A
                    bz(c+1) =  vb*sm    ! Ci * (sm) *  vb   B
                    bz(c+2) = -wb*sm	! Br * (sm) * -wb   C
                    bz(c+3) = -wb*cm	! Bi * (cm) * -wb   D
                    c = c + 4
                enddo
                  !dir$ code_align(32)
                  !dir$ ivdep
                  !dir$ assume_aligned fs:64
                do s = 1,pmaxs
                    cs = fs(s,1)
                    ss = fs(s,2)
                     !dir$ code_align(32)
                     !dir$ ivdep
                     !dir$ assume_aligned gvbar:64
                     !dir$ assume_aligned gwbar:64
                     !dir$ assume_aligned bz:64
                     !$omp simd simdlen(8) linear(n:1) private(vb,wb)
                    do n = m,pmaxn
                        vb = gvbar(n,m)
                        wb = gwbar(n,m)
                        bz(c) =   -vb*cm*cs	! Crc * (cmcs) * -vb   A
                        bz(c+1) =  vb*sm*cs ! Cic * (smcs) *  vb   B
                        bz(c+2) = -wb*sm*cs	! Brc * (smcs) * -wb   C
                        bz(c+3) = -wb*cm*cs	! Bic * (cmcs) * -wb   D
                        bz(c+4) = -vb*cm*ss	! Crs * (cmss) * -vb   E
                        bz(c+5) =  vb*sm*ss ! Cis * (smss) *  vb   F
                        bz(c+6) = -wb*sm*ss	! Brs * (smss) * -wb   G
                        bz(c+7) = -wb*cm*ss	! Bis * (cmss) * -wb   H
                        c = c + 8
                    enddo
                enddo
                cwave = c
            enddo
        else
            c = cwave
        endif

        ! ---------------- Migrating Solar Tides ---------------------

        if (refresh(3) .and. content(3)) then
           !dir$ assume_aligned fl:64,tidefactor:64
           !dir$ ivdep
           !dir$ code_align(32)
            do l = 1,tmaxl
                cl = fl(l,1)*tidefactor(l)
                sl = fl(l,2)*tidefactor(l)
                     !dir$ code_align(32)
                     !dir$ ivdep
                     !dir$ assume_aligned gvbar:64
                     !dir$ assume_aligned gwbar:64
                     !dir$ assume_aligned bz:64
                     !$omp simd simdlen(8) linear(n:1) private(vb,wb)
                do n = l,tmaxn           ! s = 0
                    vb = gvbar(n,l)
                    wb = gwbar(n,l)
                    bz(c) =   -vb*cl    ! Cr * (cl) * -vb
                    bz(c+1) =  vb*sl    ! Ci * (sl) *  vb
                    bz(c+2) = -wb*sl	! Br * (sl) * -wb
                    bz(c+3) = -wb*cl	! Bi * (cl) * -wb
                    c = c + 4
                enddo
                   !dir$ assume_aligned fs:64
                   !dir$ ivdep
                   !dir$ code_align(32)
                do s = 1,tmaxs
                    cs = fs(s,1)
                    ss = fs(s,2)
                     !dir$ code_align(32)
                     !dir$ ivdep
                     !dir$ assume_aligned gvbar:64
                     !dir$ assume_aligned gwbar:64
                     !dir$ assume_aligned bz:64
                     !$omp simd simdlen(8) linear(n:1) private(vb,wb)
                    do n = l,tmaxn
                        vb = gvbar(n,l)
                        wb = gwbar(n,l)
                        bz(c) =   -vb*cl*cs	! Crc * (clcs) * -vb
                        bz(c+1) =  vb*sl*cs ! Cic * (slcs) *  vb
                        bz(c+2) = -wb*sl*cs	! Brc * (slcs) * -wb
                        bz(c+3) = -wb*cl*cs	! Bic * (clcs) * -wb
                        bz(c+4) = -vb*cl*ss	! Crs * (clss) * -vb
                        bz(c+5) =  vb*sl*ss ! Cis * (slss) *  vb
                        bz(c+6) = -wb*sl*ss	! Brs * (slss) * -wb
                        bz(c+7) = -wb*cl*ss	! Bis * (clss) * -wb
                        c = c + 8
                    enddo
                enddo
                ctide = c
            enddo
        else
            c = ctide
        endif

        ! ---------------- Non-Migrating Solar Tides ------------------

        ! TBD

        c = c - 1

        ! ====================================================================
        ! Calculate the wind components
        ! ====================================================================

        if (component(0)) u = u + zwght(b)*dot_product(bz(1:c),mparm(1:c,d))
        if (component(1)) v = v + zwght(b)*dot_product(bz(1:c),tparm(1:c,d))

    enddo

    w(1) = sngl(v)
    w(2) = sngl(u)

    return

end subroutine hwmqt


subroutine vertwght(alt,wght,iz)
         !dir$ attributes code_align : 32 :: vertwght
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: vertwght
    use qwm
    implicit none

    real(8),intent(in)      :: alt
    real(8),intent(out)     :: wght(4)
    integer(4),intent(out)  :: iz

    real(8)             :: we(0:4)

    iz = findspan(nnode-p-1_4,p,alt,vnode) - p

    iz = min(iz,26)

    wght(1) = bspline(p,nnode,vnode,iz,alt)
    wght(2) = bspline(p,nnode,vnode,iz+1_4,alt)
    if (iz .le. 25) then
        wght(3) = bspline(p,nnode,vnode,iz+2_4,alt)
        wght(4) = bspline(p,nnode,vnode,iz+3_4,alt)
        return
    endif
    if (alt .gt. alttns) then
        we(0) = 0.0d0
        we(1) = 0.0d0
        we(2) = 0.0d0
        we(3) = exp(-(alt - alttns)/H)
        we(4) = 1.0d0
    else
        we(0) = bspline(p,nnode,vnode,iz+2_4,alt)
        we(1) = bspline(p,nnode,vnode,iz+3_4,alt)
        we(2) = bspline(p,nnode,vnode,iz+4_4,alt)
        we(3) = 0.0d0
        we(4) = 0.0d0
    endif
    wght(3) = dot_product(we,e1)
    wght(4) = dot_product(we,e2)

    return

contains

  function bspline(p,m,V,i,u)
         !dir$ attributes forceinline :: bspline
         !dir$ attributes code_align : 32 :: bspline
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: bspline
        implicit none

        real(8)     :: bspline
        integer(4)  :: p,m
        real(8)     :: V(0:m)
        integer(4)  :: i
        real(8)     :: u

        real(8)     :: N(0:p+1)
        real(8)     :: Vleft,Vright
        real(8)     :: saved,temp
        integer(4)  :: j,k

        if ((i .eq. 0) .and. (u .eq. V(0))) then
            bspline = 1.d0
            return
        endif

        if ((i .eq. (m-p-1)) .and. (u .eq. V(m))) then
            bspline = 1.d0
            return
        endif

        if (u .lt. V(i) .or. u .ge. V(i+p+1)) then
            bspline = 0.d0
            return
        endif

        N = 0.0d0
        do j = 0,p
            if (u .ge. V(i+j) .and. u .lt. V(i+j+1)) then
                N(j) = 1.0d0
            else
                N(j) = 0.0d0
            endif
        enddo
        !dir$ code_align(32)
        do k = 1,p
            if (N(0) .eq. 0.d0) then
                saved = 0.d0
            else
                saved = ((u - V(i))*N(0))/(V(i+k) - V(i))
            endif
            !dir$ assume_aligned V:64,N:64
            !dir$ code_align(32)
            do j = 0,p-k
                Vleft = V(i+j+1)
                Vright = V(i+j+k+1)
                if (N(j+1) .eq. 0.d0) then
                    N(j) = saved
                    saved = 0.d0
                else
                    temp = N(j+1)/(Vright - Vleft)
                    N(j) = saved + (Vright - u)*temp
                    saved = (u - Vleft)*temp
                endif
            enddo
        enddo

        bspline = N(0)

        return

    end function bspline

    ! =====================================================
    ! Function to locate the knot span
    ! =====================================================

    integer(4) function findspan(n,p,u,V)
         !dir$ attributes forceinline :: findspan
         !dir$ attributes code_align : 32 :: findspan
         !dir$ optimize : 3
        implicit none

        integer(4),intent(in)   :: n,p
        real(8),intent(in)      :: u
        real(8),intent(in)      :: V(0:n+1)
        integer(4)              :: low,mid,high

        if (u .ge. V(n+1)) then
            findspan = n
            return
        endif

        low = p
        high = n+1
        mid = (low + high)/2

        do while (u .lt. V(mid) .or. u .ge. V(mid + 1))
            if (u .lt. V(mid)) then
                high = mid
            else
                low = mid
            endif
            mid = (low + high)/2
        end do

        findspan = mid
        return

    end function findspan

end subroutine vertwght

! #################################################################################
!                         Disturbance Wind Model Functions
! #################################################################################

subroutine initdwm(nmaxout,mmaxout,rc)
    
         !dir$ attributes code_align : 32 :: initdwm
         !dir$ optimize : 3
    use hwm
    use dwm
    use ipe_error_module

    implicit none

    integer(4), intent(out) :: nmaxout, mmaxout
    integer,    intent(out) :: rc

    integer :: ios, lrc, stat

    rc = IPE_SUCCESS

    call findandopen(dwmdefault,23,lrc)
    if (ipe_error_check(lrc,msg="initdwm: call to findandopen failed", &
      rc=rc)) return
    if (allocated(termarr)) then
      deallocate(termarr,coeff,stat=stat)
      if (ipe_dealloc_check(stat,&
        msg="initdwm: unable to deallocate termarr,coeff", rc=rc)) return
    endif
    read(23,iostat=ios) nterm, mmax, nmax
    if (ipe_iostatus_check(ios,msg="initdwm: error reading nterm, mmax, nmax",&
      rc=rc)) return

    allocate(termarr(0:2, 0:nterm-1),stat=stat)
    if (ipe_alloc_check(stat,&
        msg="initdwm: unable to allocate termarr", rc=rc)) return
    read(23,iostat=ios) termarr
    if (ipe_iostatus_check(ios,msg="initdwm: error reading termarr",&
      rc=rc)) return
    allocate(coeff(0:nterm-1),stat=stat)
    if (ipe_alloc_check(stat,&
        msg="initdwm: unable to allocate coeff", rc=rc)) return
    read(23,iostat=ios) coeff
    if (ipe_iostatus_check(ios,msg="initdwm: error reading coeff",&
      rc=rc)) return
    read(23,iostat=ios) twidth
    if (ipe_iostatus_check(ios,msg="initdwm: error reading twidth",&
      rc=rc)) return
    close(23,iostat=ios)
    if (ipe_iostatus_check(ios,msg="initdwm: error closing file "//dwmdefault,&
      rc=rc)) return

    if (allocated(termval)) then
      deallocate(termval,dpbar,dvbar,dwbar,mltterms,vshterms,stat=stat)
      if (ipe_dealloc_check(stat,&
        msg="initdwm: unable to deallocate termval,dpbar,dvbar,dwbar,mltterms,vshterms", rc=rc)) return
    endif
    nvshterm = ( ((nmax+1)*(nmax+2) - (nmax-mmax)*(nmax-mmax+1))/2 - 1 ) * 4 - 2*nmax
    allocate(termval(0:1, 0:nterm-1), &
             dpbar(0:nmax,0:mmax),dvbar(0:nmax,0:mmax),dwbar(0:nmax,0:mmax), &
             mltterms(0:mmax,0:1), &
             vshterms(0:1, 0:nvshterm-1), stat=stat)
    if (ipe_dealloc_check(stat,&
      msg="initdwm: unable to allocate termval,dpbar,dvbar,dwbar,mltterms,vshterms", rc=rc)) return
    dpbar = 0
    dvbar = 0
    dwbar = 0

    nmaxout = nmax
    mmaxout = mmax

    dwminit = .false.

    return

end subroutine initdwm

subroutine dwm07(IYD,SEC,ALT,GLAT,GLON,AP,DW,rc)
    
         !dir$ attributes code_align : 32 :: dwm07
         !dir$ optimize : 3
    use hwm
    use dwm
    use ipe_error_module

    implicit none

    INTEGER, intent(in)  :: IYD
    REAL(4), intent(in)  :: SEC,ALT,GLAT,GLON
    REAL(4), intent(in)  :: AP(2)
    REAL(4), intent(out) :: DW(2)
    INTEGER, intent(out) :: rc

    real(4), save           :: day, ut, mlat, mlon, mlt, kp
    real(4)                 :: mmpwind, mzpwind
    real(4), save           :: f1e, f1n, f2e, f2n
    real(4), save           :: glatlast=1.0e16, glonlast=1.0e16
    real(4), save           :: daylast=1.0e16, utlast=1.0e16, aplast=1.0e16
    real(4), parameter      :: talt=125.0 !, twidth=5.0

    real(4), external       :: ap2kp, mltcalc

    integer                 :: lrc

    rc = IPE_SUCCESS

    !CONVERT AP TO KP
    if (ap(2) .ne. aplast) then
      kp = ap2kp(ap(2))
    endif

    !CONVERT GEO LAT/LON TO QD LAT/LON
    if ((glat .ne. glatlast) .or. (glon .ne. glonlast)) then
      call gd2qd(glat,glon,mlat,mlon,f1e,f1n,f2e,f2n,lrc)
      if (ipe_error_check(lrc,msg="dwm07: call to gd2qd failed",rc=rc)) return
    endif

    !COMPUTE QD MAGNETIC LOCAL TIME (LOW-PRECISION)
    day = real(mod(iyd,1000))
    ut = sec / 3600.0
    if ((day .ne. daylast) .or. (ut .ne. utlast) .or. &
        (glat .ne. glatlast) .or. (glon .ne. glonlast)) then
      mlt = mltcalc(mlat,mlon,day,ut)
    endif

    !RETRIEVE DWM WINDS
    call dwm07b(mlt, mlat, kp, mmpwind, mzpwind, lrc)
    if (ipe_error_check(lrc, msg="dwm07: call to dwm07b failed", rc=rc)) return

    !CONVERT TO GEOGRAPHIC COORDINATES
    dw(1) = f2n*mmpwind + f1n*mzpwind
    dw(2) = f2e*mmpwind + f1e*mzpwind

    !APPLY HEIGHT PROFILE
    dw = dw / (1 + exp(-(alt - talt)/twidth))

    glatlast = glat
    glonlast = glon
    daylast = day
    utlast = ut
    aplast = ap(2)

    return

end subroutine dwm07

subroutine dwm07b(mlt, mlat, kp, mmpwind, mzpwind, rc)
         !dir$ attributes code_align : 32 :: dmw07b
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: dwm07b
    use omp_lib
    use hwm
    use dwm
    use alf,only:alfbasis
    use ipe_error_module

    implicit none

    real(4), intent(in)  :: mlt       !Magnetic local time (hours)
    real(4), intent(in)  :: mlat      !Magnetic latitude (degrees)
    real(4), intent(in)  :: kp        !3-hour Kp

    real(4), intent(out) :: mmpwind   !Mer. disturbance wind (+north, QD coordinates)
    real(4), intent(out) :: mzpwind   !Zon. disturbance wind (+east, QD coordinates)

    integer, intent(out) :: rc

    ! Local variables
    integer                   :: lrc
    integer(4)                :: iterm, ivshterm, n, m
    real(4)                   :: termvaltemp(0:1)
    real(4),save              :: kpterms(0:2)
    real(4)                   :: latwgtterm
    real(4),save              :: mltlast=1.e16, mlatlast=1.e16, kplast=1.e16
    real(8)                   :: theta, phi, mphi

    real(4),external          :: latwgt2

    rc = IPE_SUCCESS

    !LOAD MODEL PARAMETERS IF NECESSARY
    if (dwminit) then
        call initdwm(nmaxdwm, mmaxdwm, lrc)
        if (ipe_error_check(lrc,msg="dwm07b: call to initdwm failed",rc=rc)) return
    endif

    !COMPUTE LATITUDE PART OF VSH TERMS
    if (mlat .ne. mlatlast) then
        theta = (90.d0 - dble(mlat))*dtor
        call alfbasis(nmax,mmax,theta,dpbar,dvbar,dwbar)
    endif

    !COMPUTE MLT PART OF VSH TERMS
    if (mlt .ne. mltlast) then
       phi = dble(mlt)*dtor*15.d0
       !dir$ code_align(32)
       !dir$ ivdep
       !dir$ assume_aligned mltterms:64
       !$omp simd simdlen(8) linear(m:1) private(mphi)
        do m = 0, mmax
            mphi = dble(m)*phi
            mltterms(m,0) = dcos(mphi)
            mltterms(m,1) = dsin(mphi)
        enddo
    endif

    !COMPUTE VSH TERMS
    if ((mlat .ne. mlatlast) .or. (mlt .ne. mltlast)) then
       ivshterm = 0
       !dir$ code_align(32)
       !dir$ assume_aligned vshterms:64
       !dir$ assume_aligned dvbar:64
       !dir$ assume_aligned dwbar:64
       !dir$ assume_aligned mltterms:64
        do n = 1, nmax
            vshterms(0,ivshterm)   = -sngl(dvbar(n,0)*mltterms(0,0))
            vshterms(0,ivshterm+1) =  sngl(dwbar(n,0)*mltterms(0,0))
            vshterms(1,ivshterm)   = -vshterms(0,ivshterm+1)
            vshterms(1,ivshterm+1) =  vshterms(0,ivshterm)
            ivshterm = ivshterm + 2
            do m = 1, mmax
                if (m .gt. n) cycle
                vshterms(0,ivshterm)   = -sngl(dvbar(n,m)*mltterms(m,0))
                vshterms(0,ivshterm+1) =  sngl(dvbar(n,m)*mltterms(m,1))
                vshterms(0,ivshterm+2) =  sngl(dwbar(n,m)*mltterms(m,1))
                vshterms(0,ivshterm+3) =  sngl(dwbar(n,m)*mltterms(m,0))
                vshterms(1,ivshterm)   = -vshterms(0,ivshterm+2)
                vshterms(1,ivshterm+1) = -vshterms(0,ivshterm+3)
                vshterms(1,ivshterm+2) =  vshterms(0,ivshterm)
                vshterms(1,ivshterm+3) =  vshterms(0,ivshterm+1)
                ivshterm = ivshterm + 4
            enddo
        enddo
    endif

    !COMPUTE KP TERMS
    if (kp .ne. kplast) then
        call kpspl3(kp, kpterms)
    endif

    !COMPUTE LATITUDINAL WEIGHTING TERM
    latwgtterm = latwgt2(mlat, mlt, kp, twidth)

    !GENERATE COUPLED TERMS
    !dir$ code_align(32)
    !dir$ assume_aligned termarr:64,kpterms:64
    do iterm = 0, nterm-1
        termvaltemp = (/1.0, 1.0/)
        if (termarr(0,iterm) .ne. 999) termvaltemp = termvaltemp * vshterms(0:1,termarr(0,iterm))
        if (termarr(1,iterm) .ne. 999) termvaltemp = termvaltemp * kpterms(termarr(1,iterm))
        if (termarr(2,iterm) .ne. 999) termvaltemp = termvaltemp * latwgtterm
        termval(0:1,iterm) = termvaltemp(0:1)
    enddo

    !APPLY COEFFICIENTS
    mmpwind = dot_product(coeff, termval(0,0:nterm-1))
    mzpwind = dot_product(coeff, termval(1,0:nterm-1))

    mlatlast = mlat
    mltlast = mlt
    kplast = kp

    return

end subroutine dwm07b

!===============================================================================
!                           Convert Ap to Kp
!===============================================================================

function ap2kp(ap0)
         !dir$ attributes forceinline :: ap2kp
         !dir$ attributes code_align : 32 :: ap2kp
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: ap2kp
  real(4), parameter :: apgrid(0:27) = (/0.,2.,3.,4.,5.,6.,7.,9.,12.,15.,18., &
                                         22.,27.,32.,39.,48.,56.,67.,80.,94., &
                                       111.,132.,154.,179.,207.,236.,300.,400./)
  real(4), parameter :: kpgrid(0:27) = (/0.,1.,2.,3.,4.,5.,6.,7.,8.,9.,10.,11., &
                                         12.,13.,14.,15.,16.,17.,18.,19.,20.,21., &
                                         22.,23.,24.,25.,26.,27./) / 3.0
  real(4)            :: ap0, ap, ap2kp
  integer(4)         :: i


  ap = ap0
  if (ap .lt. 0) ap = 0
  if (ap .gt. 400) ap = 400

  i = 1
  do while (ap .gt. apgrid(i))
    i = i + 1
  end do
  if (ap .eq. apgrid(i)) then
    ap2kp = kpgrid(i)
  else
    ap2kp = kpgrid(i-1) + (ap - apgrid(i-1)) / (3.0 * (apgrid(i) - apgrid(i-1)))
  end if

  return

end function ap2kp

! ########################################################################
!     Geographic <=> Geomagnetic Coordinate Transformations
!
!  Converts geodetic coordinates to Quasi-Dipole coordinates (Richmond, J. Geomag.
!  Geoelec., 1995, p. 191), using a spherical harmonic representation.
!
! ########################################################################

module gd2qdc

    use ipe_error_module

    implicit none

    integer(4)               :: nterm, nmax, mmax  !Spherical harmonic expansion parameters

    real(8), allocatable     :: coeff(:,:)         !Coefficients for spherical harmonic expansion
    real(8), allocatable     :: xcoeff(:)          !Coefficients for x coordinate
    real(8), allocatable     :: ycoeff(:)          !Coefficients for y coordinate
    real(8), allocatable     :: zcoeff(:)          !Coefficients for z coordinate
    real(8), allocatable     :: sh(:)              !Array to hold spherical harmonic fuctions
    real(8), allocatable     :: shgradtheta(:)     !Array to hold spherical harmonic gradients
    real(8), allocatable     :: shgradphi(:)       !Array to hold spherical harmonic gradients
    real(8), allocatable     :: normadj(:)         !Adjustment to VSH normalization factor
    !dir$ attributes align : 64 :: coeff
    !dir$ attributes align : 64 :: xcoeff
    !dir$ attributes align : 64 :: ycoeff
    !dir$ attributes align : 64 :: zcoeff
    !dir$ attributes align : 64 :: sh
    !dir$ attributes align : 64 :: shgradtheta
    !dir$ attributes align : 64 :: shgradphi
    !dir$ attributes align : 64 :: normadj
    real(4)                  :: epoch, alt
    !$omp threadprivate(epoch,alt)
    real(8), parameter       :: pi = 3.1415926535897932d0
    real(8), parameter       :: dtor = pi/180.0d0
    real(8), parameter       :: sineps = 0.39781868d0

    logical                  :: gd2qdinit = .true.
    !$omp threadprivate(gd2qdinit)
contains

    subroutine initgd2qd(rc)
         !dir$ attributes code_align : 32 :: initgd2qd
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: initgd2qd
        
        use hwm
        implicit none

        integer, intent(out) :: rc

        character(250) :: datafile
        integer(4)     :: iterm, n
        integer(4)     :: j
        integer        :: ios, lrc, stat

        rc = IPE_SUCCESS

        datafile = trim(pathdefault)//'gd2qd.dat'

        call findandopen(datafile,23,lrc)
        if (ipe_error_check(lrc,msg="initgd2qd: call to findandopen failed", &
          rc=rc)) return
        read(23,iostat=ios) nmax, mmax, nterm, epoch, alt
        if (ipe_iostatus_check(ios, &
          msg="initgd2qd: error reading nmax, mmax, nterm, epoch, alt",rc=rc)) return
        if (allocated(coeff)) then
            deallocate(coeff,xcoeff,ycoeff,zcoeff,sh,shgradtheta,shgradphi,normadj,stat=stat)
            if (ipe_dealloc_check(stat,msg="initgd2qd: failed to deallocate memory",rc=rc)) return
        endif
        allocate( coeff(0:nterm-1, 0:2), stat=stat )
        if (ipe_dealloc_check(stat,msg="initgd2qd: failed to allocate coeff",rc=rc)) return
        read(23,iostat=ios) coeff
        if (ipe_iostatus_check(ios, msg="initgd2qd: error reading coeff", rc=rc)) return
        close(23,iostat=ios)
        if (ipe_iostatus_check(ios, msg="initgd2qd: error closing file "//datafile, rc=rc)) return

        allocate( xcoeff(0:nterm-1), stat=stat )
        if (ipe_dealloc_check(stat,msg="initgd2qd: failed to allocate xcoeff",rc=rc)) return
        allocate( ycoeff(0:nterm-1), stat=stat )
        if (ipe_dealloc_check(stat,msg="initgd2qd: failed to allocate ycoeff",rc=rc)) return
        allocate( zcoeff(0:nterm-1), stat=stat )
        if (ipe_dealloc_check(stat,msg="initgd2qd: failed to allocate zcoeff",rc=rc)) return
        allocate( sh(0:nterm-1), stat=stat )
        if (ipe_dealloc_check(stat,msg="initgd2qd: failed to allocate sh",rc=rc)) return
        allocate( shgradtheta(0:nterm-1), stat=stat )
        if (ipe_dealloc_check(stat,msg="initgd2qd: failed to allocate shgradtheta",rc=rc)) return
        allocate( shgradphi(0:nterm-1), stat=stat )
        if (ipe_dealloc_check(stat,msg="initgd2qd: failed to allocate shgradphi",rc=rc)) return
        allocate( normadj(0:nmax), stat=stat )
        if (ipe_dealloc_check(stat,msg="initgd2qd: failed to allocate normadj",rc=rc)) return
       
        do iterm = 0, nterm-1
            xcoeff(iterm) = coeff(iterm,0)
            ycoeff(iterm) = coeff(iterm,1)
            zcoeff(iterm) = coeff(iterm,2)
        enddo

        do n = 0, nmax
            normadj(n) = dsqrt(dble(n*(n+1)))
        end do

        nmaxqdc = nmax
        mmaxqdc = mmax

        gd2qdinit = .false.

        return

    end subroutine initgd2qd

end module gd2qdc

subroutine gd2qd(glatin,glon,qlat,qlon,f1e,f1n,f2e,f2n,rc)
         !dir$ attributes code_align : 32 :: gd2qd
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: gd2qd
    use omp_lib
    use hwm
    use gd2qdc
    use alf
    use ipe_error_module

    implicit none

    real(4), intent(in)  :: glatin, glon
    real(4), intent(out) :: qlat, qlon
    real(4), intent(out) :: f1e, f1n, f2e, f2n
    integer, intent(out) :: rc

    integer                  :: lrc
    integer(4)               :: n, m, i
    real(8)                  :: glat, theta, phi
    real(8)                  :: mphi, cosmphi, sinmphi
    real(8)                  :: x, y, z
    real(8)                  :: cosqlat, cosqlon, sinqlon
    real(8)                  :: xgradtheta, ygradtheta, zgradtheta
    real(8)                  :: xgradphi, ygradphi, zgradphi
    real(8)                  :: qlonrad

    rc = IPE_SUCCESS

    if (gd2qdinit) then
      call initgd2qd(lrc)
      if (ipe_error_check(lrc,msg="gd2qd: call to initgd2qd failed",rc=rc)) return
    endif

    glat = dble(glatin)
    if (glat .ne. glatalf) then
      theta = (90.d0 - glat) * dtor
      call alfbasis(nmax,mmax,theta,gpbar,gvbar,gwbar)
      glatalf = glat
    endif
    phi = dble(glon) * dtor

    i = 0
    !dir$ assume_aligned sh:64,shgradtheta:64
    !dir$ assume_aligned gvbar:64,normadj:64
    !dir$ ivdep
    !dir$ code_align(32)
    !$omp simd simdlen(8)
    do n = 0, nmax
      sh(i) = gpbar(n,0)
      shgradtheta(i) =  gvbar(n,0) * normadj(n)
      shgradphi(i) = 0
      i = i + 1
    enddo
    do m = 1, mmax
      mphi = dble(m) * phi
      cosmphi = dcos(mphi)
      sinmphi = dsin(mphi)
    !dir$ assume_aligned sh:64,shgradtheta:64
    !dir$ assume_aligned gvbar:64,normadj:64
    !dir$ assume_aligned gwbar:64,gpbar:64
    !dir$ ivdep
    !dir$ code_align(32)
    !$omp simd simdlen(8)
      do n = m, nmax
        sh(i)   = gpbar(n,m) * cosmphi
        sh(i+1) = gpbar(n,m) * sinmphi
        shgradtheta(i)   =  gvbar(n,m) * normadj(n) * cosmphi
        shgradtheta(i+1) =  gvbar(n,m) * normadj(n) * sinmphi
        shgradphi(i)     = -gwbar(n,m) * normadj(n) * sinmphi
        shgradphi(i+1)   =  gwbar(n,m) * normadj(n) * cosmphi
        i = i + 2
      enddo
    enddo

    x = dot_product(sh, xcoeff)
    y = dot_product(sh, ycoeff)
    z = dot_product(sh, zcoeff)

    qlonrad = datan2(y,x)
    cosqlon = dcos(qlonrad)
    sinqlon = dsin(qlonrad)
    cosqlat = x*cosqlon + y*sinqlon

    qlat = sngl(datan2(z,cosqlat) / dtor)
    qlon = sngl(qlonrad / dtor)

    xgradtheta = dot_product(shgradtheta, xcoeff)
    ygradtheta = dot_product(shgradtheta, ycoeff)
    zgradtheta = dot_product(shgradtheta, zcoeff)

    xgradphi = dot_product(shgradphi, xcoeff)
    ygradphi = dot_product(shgradphi, ycoeff)
    zgradphi = dot_product(shgradphi, zcoeff)

    f1e = sngl(-zgradtheta*cosqlat + (xgradtheta*cosqlon + ygradtheta*sinqlon)*z )
    f1n = sngl(-zgradphi*cosqlat   + (xgradphi*cosqlon   + ygradphi*sinqlon)*z )
    f2e = sngl( ygradtheta*cosqlon - xgradtheta*sinqlon )
    f2n = sngl( ygradphi*cosqlon   - xgradphi*sinqlon )

    return

end subroutine gd2qd

!==============================================================================
!                  (Function) Calculate Magnetic Local Time
!==============================================================================

function mltcalc(qlat,qlon,day,ut,rc)
         !dir$ attributes forceinline :: mltcalc
         !dir$ attributes code_align : 32 :: mltcalc
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: mltcalc
    use omp_lib
    use hwm
    use gd2qdc
    use alf
!   use ipe_error_module

    implicit none

    real(4), intent(in)  :: qlat, qlon, day, ut
    real(4)              :: mltcalc
    integer, intent(out) :: rc

    integer                  :: lrc
    integer(4)               :: n, m, i
    real(8)                  :: asunglat, asunglon, asunqlon
    real(8)                  :: glat, theta, phi
    real(8)                  :: mphi, cosmphi, sinmphi
    real(8)                  :: x, y
    real(8)                  :: cosqlat, cosqlon, sinqlon
    real(8)                  :: qlonrad

    rc = IPE_SUCCESS

    if (gd2qdinit) then
      call initgd2qd(lrc)
      if (ipe_error_check(lrc,msg="mltcalc: call to initgd2qd failed",rc=rc)) return
    endif

    !COMPUTE GEOGRAPHIC COORDINATES OF ANTI-SUNWARD DIRECTION (LOW PRECISION)
    asunglat = -asin(sin((dble(day)+dble(ut)/24.0d0-80.0d0)*dtor) * sineps) / dtor
    asunglon = -ut * 15.d0

    !COMPUTE MAGNETIC COORDINATES OF ANTI-SUNWARD DIRECTION
    theta = (90.d0 - asunglat) * dtor
    call alfbasis(nmax,mmax,theta,spbar,svbar,swbar)
    phi = asunglon * dtor
    i = 0
    !dir$ assume_aligned sh:64,spbar:64
    !dir$ code_align(32)
    !dir$ ivdep
    !$omp simd simdlen(8)
    do n = 0, nmax
      sh(i) = spbar(n,0)
      i = i + 1
    enddo
    do m = 1, mmax
      mphi = dble(m) * phi
      cosmphi = dcos(mphi)
      sinmphi = dsin(mphi)
      !dir$ assume_aligned sh:64,spbar:64
      !dir$ ivdep
      !dir$ code_align(32)
      !$omp simd simdlen(8)
      do n = m, nmax
        sh(i)   = spbar(n,m) * cosmphi
        sh(i+1) = spbar(n,m) * sinmphi
        i = i + 2
      enddo
    enddo
    x = dot_product(sh, xcoeff)
    y = dot_product(sh, ycoeff)
    asunqlon = sngl(datan2(y,x) / dtor)

    !COMPUTE MLT
    mltcalc = (qlon - asunqlon) / 15.0

    return

end function mltcalc

!================================================================================
!                           Cubic Spline interpolation of Kp
!================================================================================

subroutine kpspl3(kp, kpterms)
         !dir$ attributes forceinline :: kpspl3
         !dir$ attributes code_align : 32 :: kpspl3
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: kpspl3
    implicit none

    real(4), intent(in)       :: kp
    real(4), intent(out)      :: kpterms(0:2)

    integer(4)                :: i, j
    real(4)                   :: x, kpspl(0:6)
    real(4), parameter        :: node(0:7)=(/-10., -8., 0., 2., 5., 8., 18., 20./)

    x = max(kp, 0.0)
    x = min(x,  8.0)

    kpterms(0:2) = 0.0
    do i = 0, 6
      kpspl(i) = 0.0
      if ((x .ge. node(i)) .and. (x .lt. node(i+1))) kpspl(i) = 1.0
    enddo
    do j = 2,3
      do i = 0, 8-j-1
        kpspl(i) = kpspl(i)   * (x - node(i))   / (node(i+j-1) - node(i)) &
                 + kpspl(i+1) * (node(i+j) - x) / (node(i+j)   - node(i+1))
      enddo
    enddo
    kpterms(0) = kpspl(0) + kpspl(1)
    kpterms(1) = kpspl(2)
    kpterms(2) = kpspl(3) + kpspl(4)

    return

end subroutine kpspl3

!================================================================================
!                           (Function) Latitude weighting factors
!================================================================================

function latwgt2(mlat, mlt, kp0, twidth)
         !dir$ attributes forceinline :: latwgt2
         !dir$ attributes code_align : 32 :: latwgt2
         !dir$ optimize : 3
         !dir$ attributes optimization_parameter:TARGET_ARCH=skylake_avx512 :: latwgt2
    implicit none

    real(4)                   :: latwgt2
    real(4)                   :: mlat, mlt, kp0, kp, twidth
    real(4)                   :: mltrad, sinmlt, cosmlt, tlat

    real(4), parameter :: coeff(0:5) = (/ 65.7633,  -4.60256,  -3.53915,  &
                                         -1.99971,  -0.752193,  0.972388 /)

    real(4), parameter :: pi=3.141592653590
    real(4), parameter :: dtor=pi/180.d0

    mltrad = mlt * 15.0 * dtor
    sinmlt = sin(mltrad)
    cosmlt = cos(mltrad)
    kp = max(kp0, 0.0)
    kp = min(kp,  8.0)
    tlat = coeff(0) + coeff(1)*cosmlt + coeff(2)*sinmlt +   &
           kp*(coeff(3) + coeff(4)*cosmlt + coeff(5)*sinmlt)
    latwgt2 = 1.0 / ( 1 + exp(-(abs(mlat)-tlat)/twidth) )

    return

end function latwgt2

! ========================================================================
! Utility to find and open the supporting data files
! ========================================================================

subroutine findandopen(datafile,unitid,rc)

    use ipe_error_module

    implicit none

    character(128)             :: datafile
    integer                    :: unitid
    integer,       intent(out) :: rc

    character(128)      :: hwmpath
    logical             :: havefile
    integer             :: i, ios

    rc = IPE_SUCCESS

    i = index(datafile,'bin')
    if (i .eq. 0) then
        inquire(file=trim(datafile),exist=havefile,iostat=ios)
        if (ipe_iostatus_check(ios,msg="error inquiring file "//datafile,rc=rc)) return
        if (havefile) then
            open(unit=unitid,file=trim(datafile),status='old',form='unformatted',iostat=ios)
            if (ipe_iostatus_check(ios,msg="error opening file "//datafile,rc=rc)) return
        else
            call get_environment_variable('HWMPATH',hwmpath)
            inquire(file=trim(hwmpath)//'/'//trim(datafile),exist=havefile,iostat=ios)
            if (ipe_iostatus_check(ios,msg="error inquiring HWMPATH/file "//&
                trim(hwmpath)//'/'//trim(datafile),rc=rc)) return
            if (havefile) then
                open(unit=unitid, file=trim(hwmpath)//'/'//trim(datafile), &
                    status='old',form='unformatted',iostat=ios)
                if (ipe_iostatus_check(ios,msg="error opening HWMPATH/file "//&
                    trim(hwmpath)//'/'//trim(datafile),rc=rc)) return
            end if
        endif
        if (.not. havefile) then
            inquire(file='../Meta/'//trim(datafile),exist=havefile,iostat=ios)
            if (ipe_iostatus_check(ios,msg="error inquiring ../Meta/file "//&
                '../Meta/'//trim(datafile),rc=rc)) return
            if (havefile) then
                open(unit=unitid, file='../Meta/'//trim(datafile),status='old',&
                    form='unformatted',iostat=ios)
                if (ipe_iostatus_check(ios,msg="error opening ../Meta/file "//&
                    '../Meta/'//trim(datafile),rc=rc)) return
            endif
        endif
    else
        inquire(file=trim(datafile),exist=havefile,iostat=ios)
        if (ipe_iostatus_check(ios,msg="error inquiring file "//datafile,rc=rc)) return
        if (havefile) then
            open(unit=unitid,file=trim(datafile),status='old',access='stream',iostat=ios)
            if (ipe_iostatus_check(ios,msg="error opening file "//datafile,rc=rc)) return
        else
            call get_environment_variable('HWMPATH',hwmpath)
            inquire(file=trim(hwmpath)//'/'//trim(datafile),exist=havefile,iostat=ios)
            if (ipe_iostatus_check(ios,msg="error inquiring HWMPATH/file "//&
                trim(hwmpath)//'/'//trim(datafile),rc=rc)) return
            if (havefile) then
                open(unit=unitid,file=trim(hwmpath)//'/'//trim(datafile),status='old',&
                    access='stream',iostat=ios)
                if (ipe_iostatus_check(ios,msg="error opening HWMPATH/file "//&
                    trim(hwmpath)//'/'//trim(datafile),rc=rc)) return
            endif
        endif
        if (.not. havefile) then
            inquire(file='../Meta/'//trim(datafile),exist=havefile,iostat=ios)
            if (ipe_iostatus_check(ios,msg="error inquiring ../Meta/file "//&
                '../Meta/'//trim(datafile),rc=rc)) return
            if (havefile) then
                open(unit=unitid,file='../Meta/'//trim(datafile),status='old',&
                    access='stream',iostat=ios)
                if (ipe_iostatus_check(ios,msg="error opening ../Meta/file "//&
                    '../Meta/'//trim(datafile),rc=rc)) return
            endif
        endif
    endif

    if (ipe_status_check(havefile,msg="Can not find file "//datafile,rc=rc)) return

end subroutine findandopen

#if 0
   Usage example!!
   program test_hwm
!! https://map.nrl.navy.mil/map/pub/nrl/HWM/HWM14/HWM14_ess224-sup-0002-supinfo/README.txt
use hwm_interface, only : hwm_14, dwm_07

implicit none (type, external)

integer :: day = 150
real ::  &
 utsec = 12 * 3600, &
 alt_km = 400., &
 glat = -45.0, &
 glon = -85.0, &
 Ap = 80.0

real :: Wmeridional, Wzonal, Dw(2)

call hwm_14(day, utsec, alt_km, glat, glat, Ap, Wmeridional, Wzonal)

if (abs(Wmeridional - (-34.1767464)) > 0.001) error stop 'Wmeridional'
if (abs(Wzonal - (-64.3156433)) > 0.001) error stop 'Wzonal'

call dwm_07(day, utsec, alt_km, glat, glat, Ap, Dw)
if (abs(DW(1)-(24.6438866)) > 0.001) error stop 'Dw(1)'
if (abs(DW(2)-(-10.9287968)) > 0.001) error stop 'Dw(2)'

print *, "OK: HWM14"

end program


#endif
