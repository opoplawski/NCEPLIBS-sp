C> @file
C>
C> SPTRUNGV   SPECTRALLY INTERPOLATE VECTORS TO STATIONS
C>   @author IREDELL       ORG: W/NMC23       @date 96-02-29
C>
C> THIS SUBPROGRAM SPECTRALLY TRUNCATES VECTORS FIELDS
C>           ON A GLOBAL CYLINDRICAL GRID, RETURNING THE FIELDS
C>           TO SPECIFIED SETS OF STATION POINTS ON THE GLOBE.
C>           THE WAVE-SPACE CAN BE EITHER TRIANGULAR OR RHOMBOIDAL.
C>           THE GRID-SPACE CAN BE EITHER AN EQUALLY-SPACED GRID
C>           (WITH OR WITHOUT POLE POINTS) OR A GAUSSIAN GRID.
C>           THE GRID AND POINT FIELDS MAY HAVE GENERAL INDEXING.
C>           THE TRANSFORMS ARE ALL MULTIPROCESSED.
C>           TRANSFORM SEVERAL FIELDS AT A TIME TO IMPROVE VECTORIZATION.
C>           SUBPROGRAM CAN BE CALLED FROM A MULTIPROCESSING ENVIRONMENT.
C>
C> PROGRAM HISTORY LOG:
C>   96-02-29  IREDELL
C> 1998-12-15  IREDELL  OPENMP DIRECTIVES INSERTED
C>
C> USAGE:    CALL SPTRUNGV(IROMB,MAXWV,IDRTI,IMAXI,JMAXI,KMAX,NMAX,
C>    &                    IPRIME,ISKIPI,JSKIPI,KSKIPI,KGSKIP,
C>    &                    NRSKIP,NGSKIP,JCPU,RLAT,RLON,GRIDUI,GRIDVI,
C>    &                    LUV,UP,VP,LDZ,DP,ZP,LPS,PP,SP)
C>   INPUT ARGUMENTS:
C>     IROMB    - INTEGER SPECTRAL DOMAIN SHAPE
C>                (0 FOR TRIANGULAR, 1 FOR RHOMBOIDAL)
C>     MAXWV    - INTEGER SPECTRAL TRUNCATION
C>     IDRTI    - INTEGER INPUT GRID IDENTIFIER
C>                (IDRTI=4 FOR GAUSSIAN GRID,
C>                 IDRTI=0 FOR EQUALLY-SPACED GRID INCLUDING POLES,
C>                 IDRTI=256 FOR EQUALLY-SPACED GRID EXCLUDING POLES)
C>     IMAXI    - INTEGER EVEN NUMBER OF INPUT LONGITUDES.
C>     JMAXI    - INTEGER NUMBER OF INPUT LATITUDES.
C>     KMAX     - INTEGER NUMBER OF FIELDS TO TRANSFORM.
C>     NMAX     - INTEGER NUMBER OF STATION POINTS TO RETURN
C>     IPRIME   - INTEGER INPUT LONGITUDE INDEX FOR THE PRIME MERIDIAN.
C>                (DEFAULTS TO 1 IF IPRIME=0)
C>                (OUTPUT LONGITUDE INDEX FOR PRIME MERIDIAN ASSUMED 1.)
C>     ISKIPI   - INTEGER SKIP NUMBER BETWEEN INPUT LONGITUDES
C>                (DEFAULTS TO 1 IF ISKIPI=0)
C>     JSKIPI   - INTEGER SKIP NUMBER BETWEEN INPUT LATITUDES FROM SOUTH
C>                (DEFAULTS TO -IMAXI IF JSKIPI=0)
C>     KSKIPI   - INTEGER SKIP NUMBER BETWEEN INPUT GRID FIELDS
C>                (DEFAULTS TO IMAXI*JMAXI IF KSKIPI=0)
C>     KGSKIP   - INTEGER SKIP NUMBER BETWEEN STATION POINT SETS
C>                (DEFAULTS TO NMAX IF KGSKIP=0)
C>     NRSKIP   - INTEGER SKIP NUMBER BETWEEN STATION LATS AND LONS
C>                (DEFAULTS TO 1 IF NRSKIP=0)
C>     NGSKIP   - INTEGER SKIP NUMBER BETWEEN STATION POINTS
C>                (DEFAULTS TO 1 IF NGSKIP=0)
C>     RLAT     - REAL (*) STATION LATITUDES IN DEGREES
C>     RLON     - REAL (*) STATION LONGITUDES IN DEGREES
C>     JCPU     - INTEGER NUMBER OF CPUS OVER WHICH TO MULTIPROCESS
C>                (DEFAULTS TO ENVIRONMENT NCPUS IF JCPU=0)
C>     GRIDUI   - REAL (*) INPUT GRID U-WINDS
C>     GRIDVI   - REAL (*) INPUT GRID V-WINDS
C>     LUV      - LOGICAL FLAG WHETHER TO RETURN WINDS
C>     LDZ      - LOGICAL FLAG WHETHER TO RETURN DIVERGENCE AND VORTICITY
C>     LPS      - LOGICAL FLAG WHETHER TO RETURN POTENTIAL AND STREAMFCN
C>   OUTPUT ARGUMENTS:
C>     UP       - REAL (*) STATION U-WINDS IF LUV
C>     VP       - REAL (*) STATION V-WINDS IF LUV
C>     DP       - REAL (*) STATION DIVERGENCES IF LDZ
C>     ZP       - REAL (*) STATION VORTICITIES IF LDZ
C>     PP       - REAL (*) STATION POTENTIALS IF LPS
C>     SP       - REAL (*) STATION STREAMFCNS IF LPS
C>
C> SUBPROGRAMS CALLED:
C>   SPWGET       GET WAVE-SPACE CONSTANTS
C>   SPLAPLAC     COMPUTE LAPLACIAN IN SPECTRAL SPACE
C>   SPTRANV      PERFORM A VECTOR SPHERICAL TRANSFORM
C>   SPTGPT       TRANSFORM SPECTRAL SCALAR TO STATION POINTS
C>   SPTGPTV      TRANSFORM SPECTRAL VECTOR TO STATION POINTS
C>   NCPUS        GETS ENVIRONMENT NUMBER OF CPUS
C>
C> REMARKS: MINIMUM GRID DIMENSIONS FOR UNALIASED TRANSFORMS TO SPECTRAL:
C>   DIMENSION                    LINEAR              QUADRATIC
C>   -----------------------      ---------           -------------
C>   IMAX                         2*MAXWV+2           3*MAXWV/2*2+2
C>   JMAX (IDRT=4,IROMB=0)        1*MAXWV+1           3*MAXWV/2+1
C>   JMAX (IDRT=4,IROMB=1)        2*MAXWV+1           5*MAXWV/2+1
C>   JMAX (IDRT=0,IROMB=0)        2*MAXWV+3           3*MAXWV/2*2+3
C>   JMAX (IDRT=0,IROMB=1)        4*MAXWV+3           5*MAXWV/2*2+3
C>   JMAX (IDRT=256,IROMB=0)      2*MAXWV+1           3*MAXWV/2*2+1
C>   JMAX (IDRT=256,IROMB=1)      4*MAXWV+1           5*MAXWV/2*2+1
C>   -----------------------      ---------           -------------
C>
C>
C-------------------------------------------------------------------------
      SUBROUTINE SPTRUNGV(IROMB,MAXWV,IDRTI,IMAXI,JMAXI,KMAX,NMAX,
     &                    IPRIME,ISKIPI,JSKIPI,KSKIPI,KGSKIP,
     &                    NRSKIP,NGSKIP,JCPU,RLAT,RLON,GRIDUI,GRIDVI,
     &                    LUV,UP,VP,LDZ,DP,ZP,LPS,PP,SP)

      LOGICAL LUV,LDZ,LPS
      REAL RLAT(*),RLON(*),GRIDUI(*),GRIDVI(*)
      REAL UP(*),VP(*),DP(*),ZP(*),PP(*),SP(*)
      REAL EPS((MAXWV+1)*((IROMB+1)*MAXWV+2)/2),EPSTOP(MAXWV+1)
      REAL ENN1((MAXWV+1)*((IROMB+1)*MAXWV+2)/2)
      REAL ELONN1((MAXWV+1)*((IROMB+1)*MAXWV+2)/2)
      REAL EON((MAXWV+1)*((IROMB+1)*MAXWV+2)/2),EONTOP(MAXWV+1)
      REAL WD((MAXWV+1)*((IROMB+1)*MAXWV+2)/2*2+1,KMAX)
      REAL WZ((MAXWV+1)*((IROMB+1)*MAXWV+2)/2*2+1,KMAX)
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  TRANSFORM INPUT GRID TO WAVE
      JC=JCPU
      IF(JC.EQ.0) JC=NCPUS()
      MX=(MAXWV+1)*((IROMB+1)*MAXWV+2)/2
      MDIM=2*MX+1
      JN=-JSKIPI
      IF(JN.EQ.0) JN=IMAXI
      JS=-JN
      INP=(JMAXI-1)*MAX(0,-JN)+1
      ISP=(JMAXI-1)*MAX(0,-JS)+1
      CALL SPTRANV(IROMB,MAXWV,IDRTI,IMAXI,JMAXI,KMAX,
     &             IPRIME,ISKIPI,JN,JS,MDIM,KSKIPI,0,0,JC,
     &             WD,WZ,
     &             GRIDUI(INP),GRIDUI(ISP),GRIDVI(INP),GRIDVI(ISP),-1)
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  TRANSFORM WAVE TO OUTPUT WINDS
      IF(LUV) THEN
        CALL SPTGPTV(IROMB,MAXWV,KMAX,NMAX,MDIM,KGSKIP,NRSKIP,NGSKIP,
     &               RLAT,RLON,WD,WZ,UP,VP)
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  TRANSFORM WAVE TO OUTPUT DIVERGENCE AND VORTICITY
      IF(LDZ) THEN
        CALL SPTGPT(IROMB,MAXWV,KMAX,NMAX,MDIM,KGSKIP,NRSKIP,NGSKIP,
     &              RLAT,RLON,WD,DP)
        CALL SPTGPT(IROMB,MAXWV,KMAX,NMAX,MDIM,KGSKIP,NRSKIP,NGSKIP,
     &              RLAT,RLON,WZ,ZP)
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  TRANSFORM WAVE TO OUTPUT POTENTIAL AND STREAMFUNCTION
      IF(LPS) THEN
        CALL SPWGET(IROMB,MAXWV,EPS,EPSTOP,ENN1,ELONN1,EON,EONTOP)
C$OMP PARALLEL DO
        DO K=1,KMAX
          CALL SPLAPLAC(IROMB,MAXWV,ENN1,WD(1,K),WD(1,K),-1)
          CALL SPLAPLAC(IROMB,MAXWV,ENN1,WZ(1,K),WZ(1,K),-1)
          WD(1:2,K)=0.
          WZ(1:2,K)=0.
        ENDDO
        CALL SPTGPT(IROMB,MAXWV,KMAX,NMAX,MDIM,KGSKIP,NRSKIP,NGSKIP,
     &              RLAT,RLON,WD,PP)
        CALL SPTGPT(IROMB,MAXWV,KMAX,NMAX,MDIM,KGSKIP,NRSKIP,NGSKIP,
     &              RLAT,RLON,WZ,SP)
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      END
