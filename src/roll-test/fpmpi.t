#!/usr/bin/perl -w
# fpmpi roll installation test.  Usage:
# fpmpi.t [nodetype]
#   where nodetype is one of "Compute", "Dbnode", "Frontend" or "Login"
#   if not specified, the test assumes either Compute or Frontend.

use Test::More qw(no_plan);

my $appliance = $#ARGV >= 0 ? $ARGV[0] :
                -d '/export/rocks/install' ? 'Frontend' : 'Compute';
my $installedOnAppliancesPattern = '.';
my $output;

my $TESTFILE = 'tmpfpmpi';

my @COMPILERS = split(/\s+/, 'ROLLCOMPILER');
my @MPIS = split(/\s+/, 'ROLLMPI');

my $NODECOUNT = 3;
my $LASTNODE = $NODECOUNT - 1;

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

# fpmpi-common.xml
foreach my $mpi (@MPIS) {
  foreach my $compiler (@COMPILERS) {

    SKIP: {

      my $command = "module load $compiler $mpi; " .
                    "mpicc -o $TESTFILE $TESTFILE.c -L\$MPIHOME/lib -lfpmpi";
      $output = `$command`;
      ok(-x $TESTFILE, "Compile with $compiler/$mpi");

      SKIP: {

        skip 'No exe', 1 if ! -x $TESTFILE;

        open(OUT, ">$TESTFILE.sh");
        print OUT <<END;
#!/bin/csh
module load $compiler $mpi
mpirun -np $NODECOUNT ./$TESTFILE
mv fpmpi_profile.txt $TESTFILE.fpmpi
cat $TESTFILE.fpmpi
END
        close(OUT);
        $output = `bash $TESTFILE.sh 2>&1`;
        like($output, qr/Data Sent.*400000/, "Output from run with $compiler/$mpi");

      }

      `rm -f $TESTFILE $TESTFILE.fpmpi`;


    }

  }
}

`rm -f $TESTFILE*`;
