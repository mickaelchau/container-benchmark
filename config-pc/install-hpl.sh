#!/bin/bash

#Run this script via sudo
#The device must be connected into Internet

sudo apt-get update

#installing compilers, libraries and packets required
sudo apt-get install wget gcc install openmpi-bin openmpi-common libopenmpi-dev libatlas-base-dev gfortran make

#Donwload and pre-installing of HPL
wget http://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz
tar -xf hpl-2.3.tar.gz
cd hpl-2.3/setup
sh make_generic
cd ..
cp setup/Make.UNKNOWN Make.rpi

#Edit Makefile 
sed -i "64s/.*/ARCH         = rpi/" Make.rpi
sed -i "70s/hpl/hpl-2.3/" Make.rpi
sed -i "86s/.*/MPlib        = -lmpi/" Make.rpi

#Compiling HPL
make arch=rpi
cd





