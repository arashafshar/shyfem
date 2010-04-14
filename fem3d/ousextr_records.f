c
c $Id: ousextr.f,v 1.3 2009-09-14 08:20:58 georg Exp $
c
c info on OUS files
c
c revision log :
c
c 02.09.2003	ggu	adapted to new OUS format
c 24.01.2005	ggu	computes maximum velocities for 3D (only first level)
c 23.03.2010	ggu	extracts reocrds
c 26.03.2010	ggu	bug fix: set nkn and nel
c
c***************************************************************

	program ousextr_records

c reads ous file and writes extracted records to new ous file

	implicit none

        include 'param.h'

        integer nrdim
        parameter ( nrdim = 2000 )

        integer irec(nrdim)

	character*80 title
	integer nkn,nel,nrz,nrq,nrb,nbc,ngr,mbw
	common /nkonst/ nkn,nel,nrz,nrq,nrb,nbc,ngr,mbw

	real xgv(nkndim), ygv(nkndim)
	real hm3v(3,neldim)
	integer nen3v(3,neldim)
	integer ipev(neldim), ipv(nkndim)
	integer iarv(neldim)
	common /xgv/xgv, /ygv/ygv
	common /hm3v/hm3v
	common /nen3v/nen3v
	common /ipev/ipev, /ipv/ipv
	common /iarv/iarv

	integer ilhv(neldim)
	real hlv(nlvdim)
        real utlnv(nlvdim,neldim)
        real vtlnv(nlvdim,neldim)
	common /ilhv/ilhv
	common /hlv/hlv
        common /utlnv/utlnv
        common /vtlnv/vtlnv

	real hev(neldim)

	real znv(nkndim)
	real zenv(3,neldim)

	real ulnv(nlvdim,nkndim)
	real vlnv(nlvdim,nkndim)
	real ut2v(neldim)
	real vt2v(neldim)
	real u2v(neldim)
	real v2v(neldim)

	integer ilnv(nlvdim,nkndim)

	character*80 name,file
        integer nvers,nin,nlv
        integer itanf,itend,idt,idtous
	integer it,ie,i
        integer ierr,nread,nextr,nb
        integer nknous,nelous,nlvous
        real href,hzoff,hlvmin
	real zmin,zmax
	real umin,umax
	real vmin,vmax
	real xe,ye
	integer k,ke,ivar
	integer lmax,l

	integer iapini,ideffi,ifileo
	logical berror

c-------------------------------------------------------------------
c initialize params
c-------------------------------------------------------------------

	nread=0
	nextr=0

c-------------------------------------------------------------------
c get simulation
c-------------------------------------------------------------------

	if(iapini(2,nkndim,neldim,0).eq.0) then
		stop 'error stop : iapini'
	end if

        nin=ideffi('datdir','runnam','.nos','unform','old')
        if(nin.le.0) goto 100

c--------------------------------------------------------------------
c open OUS file and read header
c--------------------------------------------------------------------

	nvers=1
        call rfous(nin
     +			,nvers
     +			,nknous,nelous,nlvous
     +			,href,hzoff
     +			,title
     +			,ierr)
        if(ierr.ne.0) goto 100

        write(6,*)
        write(6,*)   title
        write(6,*)
        write(6,*) ' nvers        : ',nvers
        write(6,*) ' href,hzoff   : ',href,hzoff
        write(6,*) ' nkn,nel      : ',nknous,nelous
        write(6,*) ' nlv          : ',nlvous
        write(6,*)

	nkn=nknous
	nel=nelous
	nlv=nlvous
	call dimous(nin,nkndim,neldim,nlvdim)

	call rsous(nin,ilhv,hlv,hev,ierr)
        if(ierr.ne.0) goto 100

        write(6,*) 'Available levels: ',nlv
        write(6,*) (hlv(l),l=1,nlv)

c-------------------------------------------------------------------
c get records to extract from STDIN
c-------------------------------------------------------------------

        call get_records_from_stdin(nrdim,irec)

c-------------------------------------------------------------------
c open OUS output file
c-------------------------------------------------------------------

        call mkname(' ','extract','.ous',file)
        write(6,*) 'writing file ',file(1:50)
        nb = ifileo(55,file,'unform','new')
        if( nb .le. 0 ) goto 98
	call wfous(nb,1,nkn,nel,nlv,href,hzoff,title,ierr)
        if( ierr .ne. 0 ) goto 99
	call wsous(nb,ilhv,hlv,hev,ierr)
        if( ierr .ne. 0 ) goto 99

c-------------------------------------------------------------------
c loop on input records
c-------------------------------------------------------------------

  300   continue

        call rdous(nin,it,nlvdim,ilhv,znv,zenv,utlnv,vtlnv,ierr)

        if(ierr.gt.0) write(6,*) 'error in reading file : ',ierr
        if(ierr.ne.0) goto 100

	nread=nread+1
	if( nread .gt. nrdim ) goto 100
	write(6,*) 'time : ',nread,it,irec(nread)

        if( irec(nread) .ne. 0 ) then
          call wrous(nb,it,nlvdim,ilhv,znv,zenv,utlnv,vtlnv,ierr)
          if( ierr .ne. 0 ) goto 99
          nextr = nextr + 1
        end if

	goto 300

  100	continue

c-------------------------------------------------------------------
c end of loop
c-------------------------------------------------------------------

	write(6,*)
	write(6,*) nread,' records read'
        write(6,*) nextr,' records written to file extract.ous'
	write(6,*)

        if( nextr .le. 0 ) stop 'no file written'

c-------------------------------------------------------------------
c end of routine
c-------------------------------------------------------------------

	stop
   98   continue
        write(6,*) 'error opening file'
        stop 'error stop ousextr_records'
   99   continue
        write(6,*) 'error writing file'
        stop 'error stop ousextr_records'
	end

c******************************************************************

        subroutine get_records_from_stdin(ndim,irec)

c gets records to extract from stdin

        implicit none

        integer ndim
        integer irec(ndim)

        integer i,ir

        do i=1,ndim
          irec(i) = 0
        end do

        write(6,*) 'Please enter the record numbers to be extracted.'
        write(6,*) 'Enter every record on a single line.'
        write(6,*) 'Finish with 0 on the last line.'
        write(6,*) 'example:'
        write(6,*) '   5'
        write(6,*) '  10'
        write(6,*) '  15'
        write(6,*) '  0'
        write(6,*) ' '

        do while(.true.)
          write(6,*) 'Enter record to extract (0 to end): '
          ir = 0
          read(5,'(i10)') ir

          if( ir .le. 0 ) then
            return
          else if( ir .gt. ndim ) then
            write(6,*) 'Cannot extract records higher than ',ndim
            write(6,*) 'Please change ndim and recompile.'
          else
            irec(ir) = 1
          end if
        end do

        end

c******************************************************************
