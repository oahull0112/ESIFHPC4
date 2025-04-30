# HPL example build and run

The "script" in this directory was used to download, build, and run HPL
on NREL's Kestrel platform.  The script also encapsulates an input file.
 As stated in script the input file was generated using the form at
https://www.advancedclustering.com/act_kb/tune-hpl-dat-file/

This example is small.  It only uses a fraction of the memory and cores
on two nodes of Kestrel.

It does show an alternative method for creating the executable using
configure as apposed to editing the make include files shipped with the
source.

Here we:

1. Download/untar the source ball
2. Load a set of modules
3. export LDFLAGS to point to the directory containing libblas
4. ./configure
5. make clean
6. make 
7. make install

We then:
1. Copy the exicutable to our starting directory
2. Create our input file
3. Run on two nodes with 10 tasks per node.

Output is in the file small.out