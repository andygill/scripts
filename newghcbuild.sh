#!/bin/sh
# example:
#  sh scripts/newghcbuild.sh ghc-ABC <flavor> [local]
#  flavor == perf | quickest | quick |  devel1 | devel2 
#          | validate
# Create a new ghc build

if test "x$1" == "x" ; then
  echo "no dir name"
  exit;
fi

if test "x$2" == "x" ; then
  echo "no flavour"
  exit;
fi

echo $1
# need to have this :-)
#rm -f ghc-FREEZE
#bunzip2 -k ghc-FREEZE.bz2
tar xf ghc-HEAD.tar
mv ghc $1
cd $1
if test "x$3" == "x" ; then
  darcs pull -a 
else
  darcs pull -a ../ghc-HEAD	# does not WORK!!
fi
chmod +x darcs-all
./darcs-all pull -a
#./darcs-all --extra get
./darcs-all get
#./darcs-all --testsuite get
#./darcs-all --nofib get

# sh boot; ./configure; make -j3 is what ChillX suggests:r

if test "x$2" == "xvalidate" ; then
TMPSTR="s/#BuildFlavour = quick/BuildFlavour = quick/"
sed "$TMPSTR" mk/build.mk.sample > mk/build.mk
sh -x validate > LOG.val 2>&1 &


else

TMPSTR="s/#BuildFlavour = $2/BuildFlavour = $2/"
sed "$TMPSTR" mk/build.mk.sample > mk/build.mk

sh boot
./configure
make > LOG 2>&1 &
fi
disown %1
