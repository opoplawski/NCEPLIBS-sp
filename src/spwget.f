C> @file
C>
C> SPWGET     GET WAVE-SPACE CONSTANTS
C>   @author IREDELL       ORG: W/NMC23       @date 96-02-29
C>
C> THIS SUBPROGRAM GETS WAVE-SPACE CONSTANTS.
C>
C> PROGRAM HISTORY LOG:
C>   96-02-29  IREDELL
C>
C> USAGE:    CALL SPWGET(IROMB,MAXWV,EPS,EPSTOP,ENN1,ELONN1,EON,EONTOP)
C>   INPUT ARGUMENTS:
C>     IROMB    - INTEGER SPECTRAL DOMAIN SHAPE
C>                (0 FOR TRIANGULAR, 1 FOR RHOMBOIDAL)
C>     MAXWV    - INTEGER SPECTRAL TRUNCATION
C>   OUTPUT ARGUMENTS:
C>     EPS      - REAL ((MAXWV+1)*((IROMB+1)*MAXWV+2)/2)
C>     EPSTOP   - REAL (MAXWV+1)
C>     ENN1     - REAL ((MAXWV+1)*((IROMB+1)*MAXWV+2)/2)
C>     ELONN1   - REAL ((MAXWV+1)*((IROMB+1)*MAXWV+2)/2)
C>     EON      - REAL ((MAXWV+1)*((IROMB+1)*MAXWV+2)/2)
C>     EONTOP   - REAL (MAXWV+1)
C>
C> SUBPROGRAMS CALLED:
C>   SPEPS        COMPUTE UTILITY SPECTRAL FIELDS
      SUBROUTINE SPWGET(IROMB,MAXWV,EPS,EPSTOP,ENN1,ELONN1,EON,EONTOP)
      REAL EPS((MAXWV+1)*((IROMB+1)*MAXWV+2)/2),EPSTOP(MAXWV+1)
      REAL ENN1((MAXWV+1)*((IROMB+1)*MAXWV+2)/2)
      REAL ELONN1((MAXWV+1)*((IROMB+1)*MAXWV+2)/2)
      REAL EON((MAXWV+1)*((IROMB+1)*MAXWV+2)/2),EONTOP(MAXWV+1)
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      MX=(MAXWV+1)*((IROMB+1)*MAXWV+2)/2
      MXTOP=MAXWV+1
      CALL SPEPS(IROMB,MAXWV,EPS,EPSTOP,ENN1,ELONN1,EON,EONTOP)
      END
