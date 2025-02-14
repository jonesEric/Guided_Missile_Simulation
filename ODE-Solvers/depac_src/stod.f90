!** STOD
SUBROUTINE STOD(Neq,Y,Yh,Nyh,Yh1,Ewt,Savf,Acor,Wm,Iwm,F,JAC)
   use mod_kinds, only : i4,sp
   use omp_lib
  !> Subsidiary to DEBDF
  !***
  ! **Library:**   SLATEC
  !***
  ! **Type:**      SINGLE PRECISION (STOD-S, DSTOD-D)
  !***
  ! **Author:**  Watts, H. A., (SNLA)
  !***
  ! **Description:**
  !
  !   STOD integrates a system of first order odes over one step in the
  !   integrator package DEBDF.
  ! ----------------------------------------------------------------------
  ! STOD  performs one step of the integration of an initial value
  ! problem for a system of ordinary differential equations.
  ! Note.. STOD  is independent of the value of the iteration method
  ! indicator MITER, when this is /= 0, and hence is independent
  ! of the type of chord method used, or the Jacobian structure.
  ! Communication with STOD  is done with the following variables..
  !
  ! Y      = An array of length >= n used as the Y argument in
  !          all calls to F and JAC.
  ! NEQ    = Integer array containing problem size in NEQ(1), and
  !          passed as the NEQ argument in all calls to F and JAC.
  ! YH     = An NYH by LMAX array containing the dependent variables
  !          and their approximate scaled derivatives, where
  !          LMAX = MAXORD + 1.  YH(I,J+1) contains the approximate
  !          J-th derivative of Y(I), scaled by H**J/Factorial(j)
  !          (J = 0,1,...,NQ).  On entry for the first step, the first
  !          two columns of YH must be set from the initial values.
  ! NYH    = A constant integer >= N, the first dimension of YH.
  ! YH1    = A one-dimensional array occupying the same space as YH.
  ! EWT    = An array of N elements with which the estimated local
  !          errors in YH are compared.
  ! SAVF   = An array of working storage, of length N.
  ! ACOR   = A work array of length N, used for the accumulated
  !          corrections.  On a successful return, ACOR(I) contains
  !          the estimated one-step local error in Y(I).
  ! WM,IWM = Real and integer work arrays associated with matrix
  !          operations in chord iteration (MITER /= 0).
  ! PJAC   = Name of routine to evaluate and preprocess Jacobian matrix
  !          if a chord method is being used.
  ! SLVS   = Name of routine to solve linear system in chord iteration.
  ! H      = The step size to be attempted on the next step.
  !          H is altered by the error control algorithm during the
  !          problem.  H can be either positive or negative, but its
  !          sign must remain constant throughout the problem.
  ! HMIN   = The minimum absolute value of the step size H to be used.
  ! HMXI   = Inverse of the maximum absolute value of H to be used.
  !          HMXI = 0.0 is allowed and corresponds to an infinite HMAX.
  !          HMIN and HMXI may be changed at any time, but will not
  !          take effect until the next change of H is considered.
  ! TN     = The independent variable. TN is updated on each step taken.
  ! JSTART = An integer used for input only, with the following
  !          values and meanings..
  !               0  Perform the first step.
  !           >0  Take a new step continuing from the last.
  !              -1  Take the next step with a new value of H, MAXORD,
  !                    N, METH, MITER, and/or matrix parameters.
  !              -2  Take the next step with a new value of H,
  !                    but with other inputs unchanged.
  !          On return, JSTART is set to 1 to facilitate continuation.
  ! KFLAG  = a completion code with the following meanings..
  !               0  The step was successful.
  !              -1  The requested error could not be achieved.
  !              -2  Corrector convergence could not be achieved.
  !          A return with KFLAG = -1 or -2 means either
  !          ABS(H) = HMIN or 10 consecutive failures occurred.
  !          On a return with KFLAG negative, the values of TN and
  !          the YH array are as of the beginning of the last
  !          step, and H is the last step size attempted.
  ! MAXORD = The maximum order of integration method to be allowed.
  ! METH/MITER = The method flags.  See description in driver.
  ! N      = The number of first-order differential equations.
  ! ----------------------------------------------------------------------
  !
  !***
  ! **See also:**  DEBDF
  !***
  ! **Routines called:**  CFOD, PJAC, SLVS, VNWRMS
  !***
  ! COMMON BLOCKS    DEBDF1

  !* REVISION HISTORY  (YYMMDD)
  !   800901  DATE WRITTEN
  !   890531  Changed all specific intrinsics to generic.  (WRB)
  !   891214  Prologue converted to Version 4.0 format.  (BAB)
  !   900328  Added TYPE section.  (WRB)
  !   910722  Updated AUTHOR section.  (ALS)
  !   920422  Changed DIMENSION statement.  (WRB)
  USE DEBDF1, ONLY : conit_com, crate_com, el_com, elco_com, hold_com, rc_com, &
    rmax_com, tesco_com, el0_com, h_com, hmin_com, hmxi_com, hu_com, tn_com, &
    ksteps_com, ialth_com, ipup_com, lmax_com, meo_com, nqnyh_com, nstepj_com, &
    ier_com, jstart_com, kflag_com, l_com, meth_com, miter_com, maxord_com, n_com, &
    nq_com, nst_com, nfe_com, nqu_com
  !
  INTERFACE
    SUBROUTINE F(X,U,Uprime)
      IMPORT sp,i4
      REAL(sp), INTENT(IN) :: X
      REAL(sp), INTENT(IN) :: U(:)
      REAL(sp), INTENT(OUT) :: Uprime(:)
    END SUBROUTINE F
    PURE SUBROUTINE JAC(X,U,Pd,Nrowpd)
      IMPORT sp,i4
      INTEGER(i4), INTENT(IN) :: Nrowpd
      REAL(sp), INTENT(IN) :: X
      REAL(sp), INTENT(IN) :: U(:)
      REAL(sp), INTENT(OUT) :: Pd(:,:)
    END SUBROUTINE JAC
  END INTERFACE
  INTEGER(i4), INTENT(IN) :: Neq, Nyh
  INTEGER(i4), INTENT(INOUT) :: Iwm(:)
  REAL(sp), INTENT(IN) :: Ewt(n_com)
  REAL(sp), INTENT(INOUT) :: Yh(Nyh,maxord_com+1), Yh1(Nyh*maxord_com+Nyh), Wm(:)
  REAL(sp), INTENT(OUT) :: Y(n_com), Savf(n_com), Acor(n_com)
  !
  INTEGER(i4) :: i, i1, iredo, iret, j, jb, m, ncf, newq
  REAL(sp) :: dcon, ddn, del, delp, dsm, dup, exdn, exsm, exup, r, rh, rhdn, rhsm, &
    rhup, told
  !
  !* FIRST EXECUTABLE STATEMENT  STOD
  kflag_com = 0
  told = tn_com
  ncf = 0
  delp = 0._sp
  IF( jstart_com>0 ) GOTO 400
  IF( jstart_com==-1 ) THEN
    !-----------------------------------------------------------------------
    ! THE FOLLOWING BLOCK HANDLES PRELIMINARIES NEEDED WHEN JSTART = -1.
    ! IPUP IS SET TO MITER TO FORCE A MATRIX UPDATE.
    ! IF AN ORDER INCREASE IS ABOUT TO BE CONSIDERED (IALTH = 1),
    ! IALTH IS RESET TO 2 TO POSTPONE CONSIDERATION ONE MORE STEP.
    ! IF THE CALLER HAS CHANGED METH, CFOD  IS CALLED TO RESET
    ! THE COEFFICIENTS OF THE METHOD.
    ! IF THE CALLER HAS CHANGED MAXORD TO A VALUE LESS THAN THE CURRENT
    ! ORDER NQ, NQ IS REDUCED TO MAXORD, AND A NEW H CHOSEN ACCORDINGLY.
    ! IF H IS TO BE CHANGED, YH MUST BE RESCALED.
    ! IF H OR METH IS BEING CHANGED, IALTH IS RESET TO L = NQ + 1
    ! TO PREVENT FURTHER CHANGES IN H FOR THAT MANY STEPS.
    !-----------------------------------------------------------------------
    ipup_com = miter_com
    lmax_com = maxord_com + 1
    IF( ialth_com==1 ) ialth_com = 2
    IF( meth_com/=meo_com ) THEN
      CALL CFOD(meth_com,elco_com,tesco_com)
      meo_com = meth_com
      IF( nq_com<=maxord_com ) THEN
        ialth_com = l_com
        iret = 1
        GOTO 100
      END IF
    ELSEIF( nq_com<=maxord_com ) THEN
      GOTO 200
    END IF
    nq_com = maxord_com
    l_com = lmax_com
    DO i = 1, l_com
      el_com(i) = elco_com(i,nq_com)
    END DO
    nqnyh_com = nq_com*Nyh
    rc_com = rc_com*el_com(1)/el0_com
    el0_com = el_com(1)
    conit_com = 0.5_sp/(nq_com+2)
    ddn = VNWRMS(n_com,Savf,Ewt)/tesco_com(1,l_com)
    exdn = 1._sp/l_com
    rhdn = 1._sp/(1.3_sp*ddn**exdn+0.0000013_sp)
    rh = MIN(rhdn,1._sp)
    iredo = 3
    IF( h_com==hold_com ) THEN
      rh = MAX(rh,hmin_com/ABS(h_com))
    ELSE
      rh = MIN(rh,ABS(h_com/hold_com))
      h_com = hold_com
    END IF
    GOTO 300
  ELSE
    IF( jstart_com==-2 ) GOTO 200
    !-----------------------------------------------------------------------
    ! ON THE FIRST CALL, THE ORDER IS SET TO 1, AND OTHER VARIABLES ARE
    ! INITIALIZED.  RMAX IS THE MAXIMUM RATIO BY WHICH H CAN BE INCREASED
    ! IN A SINGLE STEP.  IT IS INITIALLY 1.E4 TO COMPENSATE FOR THE SMALL
    ! INITIAL H, BUT THEN IS NORMALLY EQUAL TO 10.  IF A FAILURE
    ! OCCURS (IN CORRECTOR CONVERGENCE OR ERROR TEST), RMAX IS SET AT 2
    ! FOR THE NEXT INCREASE.
    !-----------------------------------------------------------------------
    lmax_com = maxord_com + 1
    nq_com = 1
    l_com = 2
    ialth_com = 2
    rmax_com = 10000._sp
    rc_com = 0._sp
    el0_com = 1._sp
    crate_com = 0.7_sp
    delp = 0._sp
    hold_com = h_com
    meo_com = meth_com
    nstepj_com = 0
    iret = 3
    !-----------------------------------------------------------------------
    ! CFOD  IS CALLED TO GET ALL THE INTEGRATION COEFFICIENTS FOR THE
    ! CURRENT METH.  THEN THE EL VECTOR AND RELATED CONSTANTS ARE RESET
    ! WHENEVER THE ORDER NQ IS CHANGED, OR AT THE START OF THE PROBLEM.
    !-----------------------------------------------------------------------
    CALL CFOD(meth_com,elco_com,tesco_com)
  END IF
  100 CONTINUE
  DO i = 1, l_com
    el_com(i) = elco_com(i,nq_com)
  END DO
  nqnyh_com = nq_com*Nyh
  rc_com = rc_com*el_com(1)/el0_com
  el0_com = el_com(1)
  conit_com = 0.5_sp/(nq_com+2)
  SELECT CASE (iret)
    CASE (2)
      rh = MAX(rh,hmin_com/ABS(h_com))
      GOTO 300
    CASE (3)
      GOTO 400
    CASE DEFAULT
  END SELECT
  !-----------------------------------------------------------------------
  ! IF H IS BEING CHANGED, THE H RATIO RH IS CHECKED AGAINST
  ! RMAX, HMIN, AND HMXI, AND THE YH ARRAY RESCALED.  IALTH IS SET TO
  ! L = NQ + 1 TO PREVENT A CHANGE OF H FOR THAT MANY STEPS, UNLESS
  ! FORCED BY A CONVERGENCE OR ERROR TEST FAILURE.
  !-----------------------------------------------------------------------
  200 CONTINUE
  IF( h_com==hold_com ) GOTO 400
  rh = h_com/hold_com
  h_com = hold_com
  iredo = 3
  300  rh = MIN(rh,rmax_com)
  rh = rh/MAX(1._sp,ABS(h_com)*hmxi_com*rh)
  r = 1._sp
  DO j = 2, l_com
    r = r*rh
    DO i = 1, n_com
      Yh(i,j) = Yh(i,j)*r
    END DO
  END DO
  h_com = h_com*rh
  rc_com = rc_com*rh
  ialth_com = l_com
  IF( iredo==0 ) THEN
    rmax_com = 10._sp
    GOTO 1200
  END IF
  !-----------------------------------------------------------------------
  ! THIS SECTION COMPUTES THE PREDICTED VALUES BY EFFECTIVELY
  ! MULTIPLYING THE YH ARRAY BY THE PASCAL TRIANGLE MATRIX.
  ! RC IS THE RATIO OF NEW TO OLD VALUES OF THE COEFFICIENT  H*EL(1).
  ! WHEN RC DIFFERS FROM 1 BY MORE THAN 30 PERCENT, IPUP IS SET TO MITER
  ! TO FORCE PJAC TO BE CALLED, IF A JACOBIAN IS INVOLVED.
  ! IN ANY CASE, PJAC IS CALLED AT LEAST EVERY 20-TH STEP.
  !-----------------------------------------------------------------------
  400 CONTINUE
  IF( ABS(rc_com-1._sp)>0.3_sp ) ipup_com = miter_com
  IF( nst_com>=nstepj_com+20 ) ipup_com = miter_com
  tn_com = tn_com + h_com
  i1 = nqnyh_com + 1
  DO jb = 1, nq_com
    i1 = i1 - Nyh
    !$omp simd reduction(+:Yh1) if(nqnyh_com>=16)
    DO i = i1, nqnyh_com
      Yh1(i) = Yh1(i) + Yh1(i+Nyh)
    END DO
  END DO
  ksteps_com = ksteps_com + 1
  !-----------------------------------------------------------------------
  ! UP TO 3 CORRECTOR ITERATIONS ARE TAKEN.  A CONVERGENCE TEST IS
  ! MADE ON THE R.M.S. NORM OF EACH CORRECTION, WEIGHTED BY THE ERROR
  ! WEIGHT VECTOR EWT.  THE SUM OF THE CORRECTIONS IS ACCUMULATED IN THE
  ! VECTOR ACOR(I).  THE YH ARRAY IS NOT ALTERED IN THE CORRECTOR LOOP.
  !-----------------------------------------------------------------------
  500  m = 0
  DO i = 1, n_com
    Y(i) = Yh(i,1)
  END DO
  CALL F(tn_com,Y,Savf)
  nfe_com = nfe_com + 1
  IF( ipup_com>0 ) THEN
    !-----------------------------------------------------------------------
    ! IF INDICATED, THE MATRIX P = I - H*EL(1)*J IS REEVALUATED AND
    ! PREPROCESSED BEFORE STARTING THE CORRECTOR ITERATION.  IPUP IS SET
    ! TO 0 AS AN INDICATOR THAT THIS HAS BEEN DONE.
    !-----------------------------------------------------------------------
    ipup_com = 0
    rc_com = 1._sp
    nstepj_com = nst_com
    crate_com = 0.7_sp
    CALL PJAC(Neq,Y,Yh,Nyh,Ewt,Acor,Savf,Wm,Iwm,F,JAC)
    IF( ier_com/=0 ) GOTO 800
  END IF
  DO i = 1, n_com
    Acor(i) = 0._sp
  END DO
  600 CONTINUE
  IF( miter_com/=0 ) THEN
    !-----------------------------------------------------------------------
    ! IN THE CASE OF THE CHORD METHOD, COMPUTE THE CORRECTOR ERROR,
    ! AND SOLVE THE LINEAR SYSTEM WITH THAT AS RIGHT-HAND SIDE AND
    ! P AS COEFFICIENT MATRIX.
    !-----------------------------------------------------------------------
    DO i = 1, n_com
      Y(i) = h_com*Savf(i) - (Yh(i,2)+Acor(i))
    END DO
    CALL SLVS(Wm,Iwm,Y)
    IF( ier_com/=0 ) GOTO 700
    del = VNWRMS(n_com,Y,Ewt)
    DO i = 1, n_com
      Acor(i) = Acor(i) + Y(i)
      Y(i) = Yh(i,1) + el_com(1)*Acor(i)
    END DO
  ELSE
    !-----------------------------------------------------------------------
    ! IN THE CASE OF FUNCTIONAL ITERATION, UPDATE Y DIRECTLY FROM
    ! THE RESULT OF THE LAST FUNCTION EVALUATION.
    !-----------------------------------------------------------------------
    DO i = 1, n_com
      Savf(i) = h_com*Savf(i) - Yh(i,2)
      Y(i) = Savf(i) - Acor(i)
    END DO
    del = VNWRMS(n_com,Y,Ewt)
    DO i = 1, n_com
      Y(i) = Yh(i,1) + el_com(1)*Savf(i)
      Acor(i) = Savf(i)
    END DO
  END IF
  !-----------------------------------------------------------------------
  ! TEST FOR CONVERGENCE.  IF M>0, AN ESTIMATE OF THE CONVERGENCE
  ! RATE CONSTANT IS STORED IN CRATE, AND THIS IS USED IN THE TEST.
  !-----------------------------------------------------------------------
  IF( m/=0 ) crate_com = MAX(0.2_sp*crate_com,del/delp)
  dcon = del*MIN(1._sp,1.5_sp*crate_com)/(tesco_com(2,nq_com)*conit_com)
  IF( dcon<=1._sp ) THEN
    !-----------------------------------------------------------------------
    ! THE CORRECTOR HAS CONVERGED.  IPUP IS SET TO -1 IF MITER /= 0,
    ! TO SIGNAL THAT THE JACOBIAN INVOLVED MAY NEED UPDATING LATER.
    ! THE LOCAL ERROR TEST IS MADE AND CONTROL PASSES TO STATEMENT 500
    ! IF IT FAILS.
    !-----------------------------------------------------------------------
    IF( miter_com/=0 ) ipup_com = -1
    IF( m==0 ) dsm = del/tesco_com(2,nq_com)
    IF( m>0 ) dsm = VNWRMS(n_com,Acor,Ewt)/tesco_com(2,nq_com)
    IF( dsm>1._sp ) THEN
      !-----------------------------------------------------------------------
      ! THE ERROR TEST FAILED.  KFLAG KEEPS TRACK OF MULTIPLE FAILURES.
      ! RESTORE TN AND THE YH ARRAY TO THEIR PREVIOUS VALUES, AND PREPARE
      ! TO TRY THE STEP AGAIN.  COMPUTE THE OPTIMUM STEP SIZE FOR THIS OR
      ! ONE LOWER ORDER.  AFTER 2 OR MORE FAILURES, H IS FORCED TO DECREASE
      ! BY A FACTOR OF 0.2 OR LESS.
      !-----------------------------------------------------------------------
      kflag_com = kflag_com - 1
      tn_com = told
      i1 = nqnyh_com + 1
      DO jb = 1, nq_com
        i1 = i1 - Nyh
        !$omp simd reduction(-:Yh1)
        DO i = i1, nqnyh_com
          Yh1(i) = Yh1(i) - Yh1(i+Nyh)
        END DO
      END DO
      rmax_com = 2._sp
      IF( ABS(h_com)<=hmin_com*1.00001_sp ) THEN
        !-----------------------------------------------------------------------
        ! ALL RETURNS ARE MADE THROUGH THIS SECTION.  H IS SAVED IN HOLD
        ! TO ALLOW THE CALLER TO CHANGE H ON THE NEXT STEP.
        !-----------------------------------------------------------------------
        kflag_com = -1
        GOTO 1300
      ELSEIF( kflag_com<=-3 ) THEN
        !-----------------------------------------------------------------------
        ! CONTROL REACHES THIS SECTION IF 3 OR MORE FAILURES HAVE OCCURRED.
        ! IF 10 FAILURES HAVE OCCURRED, EXIT WITH KFLAG = -1.
        ! IT IS ASSUMED THAT THE DERIVATIVES THAT HAVE ACCUMULATED IN THE
        ! YH ARRAY HAVE ERRORS OF THE WRONG ORDER.  HENCE THE FIRST
        ! DERIVATIVE IS RECOMPUTED, AND THE ORDER IS SET TO 1.  THEN
        ! H IS REDUCED BY A FACTOR OF 10, AND THE STEP IS RETRIED,
        ! UNTIL IT SUCCEEDS OR H REACHES HMIN.
        !-----------------------------------------------------------------------
        IF( kflag_com==-10 ) THEN
          kflag_com = -1
          GOTO 1300
        ELSE
          rh = 0.1_sp
          rh = MAX(hmin_com/ABS(h_com),rh)
          h_com = h_com*rh
          DO i = 1, n_com
            Y(i) = Yh(i,1)
          END DO
          CALL F(tn_com,Y,Savf)
          nfe_com = nfe_com + 1
          DO i = 1, n_com
            Yh(i,2) = h_com*Savf(i)
          END DO
          ipup_com = miter_com
          ialth_com = 5
          IF( nq_com==1 ) GOTO 400
          nq_com = 1
          l_com = 2
          iret = 3
          GOTO 100
        END IF
      ELSE
        iredo = 2
        rhup = 0._sp
        GOTO 900
      END IF
    ELSE
      !-----------------------------------------------------------------------
      ! AFTER A SUCCESSFUL STEP, UPDATE THE YH ARRAY.
      ! CONSIDER CHANGING H IF IALTH = 1.  OTHERWISE DECREASE IALTH BY 1.
      ! IF IALTH IS THEN 1 AND NQ < MAXORD, THEN ACOR IS SAVED FOR
      ! USE IN A POSSIBLE ORDER INCREASE ON THE NEXT STEP.
      ! IF A CHANGE IN H IS CONSIDERED, AN INCREASE OR DECREASE IN ORDER
      ! BY ONE IS CONSIDERED ALSO.  A CHANGE IN H IS MADE ONLY IF IT IS BY A
      ! FACTOR OF AT LEAST 1.1.  IF NOT, IALTH IS SET TO 3 TO PREVENT
      ! TESTING FOR THAT MANY STEPS.
      !-----------------------------------------------------------------------
      kflag_com = 0
      iredo = 0
      nst_com = nst_com + 1
      hu_com = h_com
      nqu_com = nq_com
      DO j = 1, l_com
        DO i = 1, n_com
          Yh(i,j) = Yh(i,j) + el_com(j)*Acor(i)
        END DO
      END DO
      ialth_com = ialth_com - 1
      IF( ialth_com==0 ) THEN
        !-----------------------------------------------------------------------
        ! REGARDLESS OF THE SUCCESS OR FAILURE OF THE STEP, FACTORS
        ! RHDN, RHSM, AND RHUP ARE COMPUTED, BY WHICH H COULD BE MULTIPLIED
        ! AT ORDER NQ - 1, ORDER NQ, OR ORDER NQ + 1, REspECTIVELY.
        ! IN THE CASE OF FAILURE, RHUP = 0.0 TO AVOID AN ORDER INCREASE.
        ! THE LARGEST OF THESE IS DETERMINED AND THE NEW ORDER CHOSEN
        ! ACCORDINGLY.  IF THE ORDER IS TO BE INCREASED, WE COMPUTE ONE
        ! ADDITIONAL SCALED DERIVATIVE.
        !-----------------------------------------------------------------------
        rhup = 0._sp
        IF( l_com/=lmax_com ) THEN
          DO i = 1, n_com
            Savf(i) = Acor(i) - Yh(i,lmax_com)
          END DO
          dup = VNWRMS(n_com,Savf,Ewt)/tesco_com(3,nq_com)
          exup = 1._sp/(l_com+1)
          rhup = 1._sp/(1.4_sp*dup**exup+0.0000014_sp)
        END IF
        GOTO 900
      ELSE
        IF( ialth_com<=1 ) THEN
          IF( l_com/=lmax_com ) THEN
            DO i = 1, n_com
              Yh(i,lmax_com) = Acor(i)
            END DO
          END IF
        END IF
        GOTO 1200
      END IF
    END IF
  ELSE
    m = m + 1
    IF( m/=3 ) THEN
      IF( m<2 .OR. del<=2._sp*delp ) THEN
        delp = del
        CALL F(tn_com,Y,Savf)
        nfe_com = nfe_com + 1
        GOTO 600
      END IF
    END IF
  END IF
  !-----------------------------------------------------------------------
  ! THE CORRECTOR ITERATION FAILED TO CONVERGE IN 3 TRIES.
  ! IF MITER /= 0 AND THE JACOBIAN IS OUT OF DATE, PJAC IS CALLED FOR
  ! THE NEXT TRY.  OTHERWISE THE YH ARRAY IS RETRACTED TO ITS VALUES
  ! BEFORE PREDICTION, AND H IS REDUCED, IF POSSIBLE.  IF H CANNOT BE
  ! REDUCED OR 10 FAILURES HAVE OCCURRED, EXIT WITH KFLAG = -2.
  !-----------------------------------------------------------------------
  700 CONTINUE
  IF( ipup_com/=0 ) THEN
    ipup_com = miter_com
    GOTO 500
  END IF
  800  tn_com = told
  ncf = ncf + 1
  rmax_com = 2._sp
  i1 = nqnyh_com + 1
  DO jb = 1, nq_com
    i1 = i1 - Nyh
    !$omp simd reduction(-:Yh1)
    DO i = i1, nqnyh_com
      Yh1(i) = Yh1(i) - Yh1(i+Nyh)
    END DO
  END DO
  IF( ABS(h_com)<=hmin_com*1.00001_sp ) THEN
    kflag_com = -2
    GOTO 1300
  ELSEIF( ncf==10 ) THEN
    kflag_com = -2
    GOTO 1300
  ELSE
    rh = 0.25_sp
    ipup_com = miter_com
    iredo = 1
    rh = MAX(rh,hmin_com/ABS(h_com))
    GOTO 300
  END IF
  900  exsm = 1._sp/l_com
  rhsm = 1._sp/(1.2_sp*dsm**exsm+0.0000012_sp)
  rhdn = 0._sp
  IF( nq_com/=1 ) THEN
    ddn = VNWRMS(n_com,Yh(:,l_com),Ewt)/tesco_com(1,nq_com)
    exdn = 1._sp/nq_com
    rhdn = 1._sp/(1.3_sp*ddn**exdn+0.0000013_sp)
  END IF
  IF( rhsm>=rhup ) THEN
    IF( rhsm>=rhdn ) THEN
      newq = nq_com
      rh = rhsm
      GOTO 1000
    END IF
  ELSEIF( rhup>rhdn ) THEN
    newq = l_com
    rh = rhup
    IF( rh<1.1_sp ) THEN
      ialth_com = 3
      GOTO 1200
    ELSE
      r = el_com(l_com)/l_com
      DO i = 1, n_com
        Yh(i,newq+1) = Acor(i)*r
      END DO
      GOTO 1100
    END IF
  END IF
  newq = nq_com - 1
  rh = rhdn
  IF( kflag_com<0 .AND. rh>1._sp ) rh = 1._sp
  1000 CONTINUE
  IF( (kflag_com==0) .AND. (rh<1.1_sp) ) THEN
    ialth_com = 3
    GOTO 1200
  ELSE
    IF( kflag_com<=-2 ) rh = MIN(rh,0.2_sp)
    !-----------------------------------------------------------------------
    ! IF THERE IS A CHANGE OF ORDER, RESET NQ, L, AND THE COEFFICIENTS.
    ! IN ANY CASE H IS RESET ACCORDING TO RH AND THE YH ARRAY IS RESCALED.
    ! THEN EXIT FROM 680 IF THE STEP WAS OK, OR REDO THE STEP OTHERWISE.
    !-----------------------------------------------------------------------
    IF( newq==nq_com ) THEN
      rh = MAX(rh,hmin_com/ABS(h_com))
      GOTO 300
    END IF
  END IF
  1100 nq_com = newq
  l_com = nq_com + 1
  iret = 2
  GOTO 100
  1200 r = 1._sp/tesco_com(2,nqu_com)
  DO i = 1, n_com
    Acor(i) = Acor(i)*r
  END DO
  1300 hold_com = h_com
  jstart_com = 1
  !----------------------- END OF SUBROUTINE STOD  -----------------------
END SUBROUTINE STOD
