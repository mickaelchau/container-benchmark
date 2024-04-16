# Move to home directory.
cd

# Install compilers, libraries, and dependencies
apt-get update
apt-get install -y wget gcc openmpi-bin openmpi-common libopenmpi-dev libatlas-base-dev gfortran make

# Download and pre-install HPL
wget http://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz
tar -xf hpl-2.3.tar.gz
cd hpl-2.3/setup
sh make_generic
cd ..
cp setup/Make.UNKNOWN Make.rpi

# Edit Makefile
sed -i "64s/.*/ARCH = rpi/" Make.rpi
sed -i "70s/hpl/hpl-2.3/" Make.rpi
sed -i "86s/.*/MPlib = -lmpi/" Make.rpi

# Compile HPL
make arch=rpi

# Edit HPL.dat file
cd bin/rpi
sed -i 's/4            # of problems sizes (N)/1            # of problems sizes (N)/g' HPL.dat
sed -i 's/29 30 34 35  Ns/8832         Ns/g' HPL.dat
sed -i 's/4            # of NBs/1            # of NBs/g' HPL.dat
sed -i 's/1 2 3 4      NBs/192           NBs/g' HPL.dat
sed -i 's/3            # of process grids (P x Q)/1            # of process grids (P x Q)/g' HPL.dat
sed -i 's/2 1 4        Ps/1        Ps/g' HPL.dat
sed -i 's/2 4 1        Qs/1        Qs/g' HPL.dat
