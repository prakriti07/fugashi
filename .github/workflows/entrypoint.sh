#!/bin/bash
# Install mecab, then build wheels
set -e

# prereqs
#yum -y install curl-devel libcurl3 git

# install MeCab
# TODO specify the commit used here
git clone --depth=1 git://github.com/taku910/mecab.git
cd mecab/mecab
if [ "$(uname -m)" == "aarch64" ]
then
    ./configure --enable-utf8-only --build=aarch64-unknown-linux-gnu
else
    ./configure --enable-utf8-only
fi
make
make install

# Hack
# see here:
# https://github.com/RalfG/python-wheels-manylinux-build/issues/26
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/

# Build the wheels
if [ "$(uname -m)" == "aarch64" ]
then
    Python="cp36-cp36m cp37-cp37m cp38-cp38 cp39-cp39"
else
    Python="cp35-cp35m cp36-cp36m cp37-cp37m cp38-cp38 cp39-cp39"
fi
for PYVER in $Python; do
  # install cython first
  /opt/python/$PYVER/bin/pip install cython setuptools-scm

  # build the wheels
  /opt/python/$PYVER/bin/pip wheel /github/workspace -w /github/workspace/wheels || { echo "Failed while buiding $PYVER wheel"; exit 1; }
done

# fix the wheels (bundles libs)
for wheel in /github/workspace/wheels/*.whl; do
  if [ "$(uname -m)" == "aarch64" ]
  then
    auditwheel repair "$wheel" --plat manylinux2014_aarch64 -w /github/workspace/manylinux-aarch64-wheels
  else
    auditwheel repair "$wheel" --plat manylinux1_x86_64 -w /github/workspace/manylinux1-wheels
  fi
done

echo "Built wheels:"
if [ "$(uname -m)" == "aarch64" ]
then
    ls /github/workspace/manylinux-aarch64-wheels
else
    ls /github/workspace/manylinux1-wheels
fi
