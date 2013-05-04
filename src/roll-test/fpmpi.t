#!/usr/bin/perl -w
# fpmpi roll installation test.  Usage:
# fpmpi.t [nodetype [submituser]]
#   where nodetype is one of "Compute", "Dbnode", "Frontend" or "Login"
#   if not specified, the test assumes either Compute or Frontend.
#   submituser is the login id through which jobs will be submitted to the
#   batch queue; defaults to diag.

use Test::More qw(no_plan);

my $appliance = $#ARGV >= 0 ? $ARGV[0] :
                -d '/export/rocks/install' ? 'Frontend' : 'Compute';
my $installedOnAppliancesPattern = '.';
my $output;

my $TESTFILE = 'tmpfpmpi';

my $NODECOUNT = 3;
my $LASTNODE = $NODECOUNT - 1;
my $SUBMITUSER = $ARGV[1] || 'diag';
my $SUBMITDIR = "/home/$SUBMITUSER/fpmpiroll";
`su -c "mkdir $SUBMITDIR" $SUBMITUSER`;

# sendrecv.c from fpmpi/test
open(OUT, ">$TESTFILE.c");
print OUT <<END;
#include <stdio.h>
#include <stdlib.h>
#include "mpi.h"

int f( int );

int f( int i )
{ 
    return i + 1;
}

int main( int argc, char *argv[] )
{
    int *buf = 0, size, rank, i;
    int largeN = 100000;

    MPI_Init( &argc, &argv );
    MPI_Comm_size( MPI_COMM_WORLD, &size );
    MPI_Comm_rank( MPI_COMM_WORLD, &rank );

    if (size < 3) {
	fprintf( stderr, "This program requires at least 3 processes\\n" );
	MPI_Abort( MPI_COMM_WORLD, 1 );
    }
    buf = (int *)malloc( largeN * sizeof(int) );
    if (!buf) {
	fprintf( stderr, "Unable to allocate a buffer of size %d\\n", 
		 (int)(largeN * sizeof(int)) );
	MPI_Abort( MPI_COMM_WORLD, 1 );
    }

    MPI_Barrier( MPI_COMM_WORLD );
    if (rank == 0) {
	MPI_Recv( MPI_BOTTOM, 0, MPI_INT, 2, 0, MPI_COMM_WORLD, 
		  MPI_STATUS_IGNORE );
	MPI_Recv( buf, largeN, MPI_INT, 1, 1, MPI_COMM_WORLD, 
		  MPI_STATUS_IGNORE );
    }
    else if (rank == 1) {
	/* This send won't complete quickly because the message should
	   exceed the eager threshold for most MPI implementations */
	MPI_Send( buf, largeN, MPI_INT, 0, 1, MPI_COMM_WORLD );
    }
    else if (rank == 2) {
	/* Delay a little */
	for (i=0; i<10000; i++) { i = f(i); }
	MPI_Send( MPI_BOTTOM, 0, MPI_INT, 0, 0, MPI_COMM_WORLD );
    }

    free( buf );
    MPI_Finalize();

    return 0;
}
END
close(OUT);

my @COMPILERS = split(/\s+/, 'ROLLCOMPILER');
my @NETWORKS = split(/\s+/, 'ROLLNETWORK');
my @MPIS = split(/\s+/, 'ROLLMPI');

my $modulesInstalled = -f '/etc/profile.d/modules.sh';

# fpmpi-common.xml
foreach my $mpi (@MPIS) {
  foreach my $compiler (@COMPILERS) {

    SKIP: {

      skip "$mpi/$compiler not installed", 5 if ! -d "/opt/$mpi/$compiler";

      foreach my $network (@NETWORKS) {

        my $FPMPIOUT  = "$SUBMITDIR/fpmpi_profile.txt";
        my $SUBMITERR = "$SUBMITDIR/$TESTFILE.$mpi.$compiler.$network.err";
        my $SUBMITEXE = "$SUBMITDIR/$TESTFILE.$mpi.$compiler.$network.exe";
        my $SUBMITFP  = "$SUBMITDIR/$TESTFILE.$mpi.$compiler.$network.fpmpi";
        my $SUBMITOUT = "$SUBMITDIR/$TESTFILE.$mpi.$compiler.$network.out";

        my $setup = $modulesInstalled ?
          ". /etc/profile.d/modules.sh; module load $compiler ${mpi}_$network" :
          'echo > /dev/null'; # noop
        my $command = "$setup; which mpicc; " .
                      "mpicc -o $TESTFILE $TESTFILE.c -L\$MPIHOME/lib -lfpmpi";
        $output = `$command`;
        $output =~ /(\S*mpicc)/;
        my $mpicc = $1 || 'mpicc';
        my $mpirun = $mpicc;
        $mpirun =~ s/mpicc/mpirun/;
        ok(-x $TESTFILE, "Compile with $mpicc");

        SKIP: {

          skip 'No exe', 1 if ! -x $TESTFILE;
          chomp(my $hostName = `hostname`);
          $hostName =~ s/\..*//;
          chomp(my $submitHosts = `qmgr -c 'list server submit_hosts'`);
          skip 'Not submit machine', 1
            if $appliance ne 'Frontend' && $submitHosts !~ /$hostName/;
          `su -c "cp $TESTFILE $SUBMITEXE" $SUBMITUSER`;

          my $fileopt = $mpi =~ /^(openmpi|mpich)$/ ?
                        "-machinefile \$PBS_NODEFILE" : "-f \$PBS_NODEFILE";
          open(OUT, ">$TESTFILE.qsub");
          print OUT <<END;
#!/bin/csh
#PBS -l nodes=$NODECOUNT
#PBS -l walltime=5:00
#PBS -e $SUBMITERR
#PBS -o $SUBMITOUT
#PBS -V
#PBS -m n
cd $SUBMITDIR
$setup
$mpirun $fileopt -np $NODECOUNT $SUBMITEXE
END
          close(OUT);
          $output = `su -c "/opt/torque/bin/qsub $TESTFILE.qsub" $SUBMITUSER`;
          $output =~ /(\d+)/;
          my $jobId = $1;
          while(`qstat $jobId` =~ / (Q|R) /) {
            sleep(1);
          }
          for(my $sec = 0; $sec < 60; $sec++) {
            last if -f $SUBMITOUT;
            sleep(1);
          }
          `su -c "mv $FPMPIOUT $SUBMITFP" $SUBMITUSER`;
          ok($? == 0, "Run with $mpirun");
          $output = `su -c "cat $SUBMITFP" $SUBMITUSER`;
          like($output, qr/Data Sent.*400000/, "Output from run with $mpirun");

        }

        `rm -f $TESTFILE`;

      }

    }

  }
}

`rm -f $TESTFILE*`;
`su -c "rm -fr $SUBMITDIR" $SUBMITUSER`;
