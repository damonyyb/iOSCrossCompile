#!/bin/sh

rm -rf buildIOS
mkdir -p buildIOS

#文件名
NAME="lame-3.100"

BUILDPATH="buildIOS/$NAME/"
cp -r $NAME $BUILDPATH
cd $BUILDPATH

PWD=`pwd`

#运行make
makeFunc(){
	echo "-----make开始执行-----"
	make clean
	make -j8
	make install
	echo "-----make执行完毕-----"
}

#编译真机
buildIphonesFunc() {
	echo "-----开始编译 $1 环境!-----"
	echo "-----configure开始执行-----"

	ARCH=$1
	CC="xcrun -sdk iphoneos clang -arch $ARCH"
	CFLAGS="-arch $ARCH -fembed-bitcode -miphoneos-version-min=10.0"
	CONFIGURE="--disable-shared  --disable-frontend"
	$PWD/configure \
	$CONFIGURE \
	--prefix="$PWD/../thin/$ARCH" \
	--host=arm-apple-darwin \
	CC="$CC" \
	CXX="$CC" \
	CPP="$CC -E" \
	CFLAGS="$CFLAGS" \
	LDFLAGS="$CFLAGS" \
	CPPFLAGS="$CFLAGS" 
	echo "-----configure执行执行-----"
	makeFunc
	echo "-----完成编译 $1 环境!-----"
}



#编译模拟器
buildIPhonesimulatorFunc() {
	echo "-----开始编译 $1 环境!-----"
	echo "-----configure开始执行-----"

	ARCH=$1
	CC="xcrun -sdk iphonesimulator clang -arch $ARCH"
	CFLAGS="-arch $ARCH -fembed-bitcode -miphoneos-version-min=10.0"
	CONFIGURE="--disable-shared    --disable-frontend"
	$PWD/configure \
	$CONFIGURE \
	--host=$ARCH-apple-darwin \
	--prefix="$PWD/../thin/$ARCH" \
	CC="$CC" \
	CXX="$CC" \
	CPP="$CC -E" \
	CFLAGS="$CFLAGS" \
	LDFLAGS="$CFLAGS" \
	CPPFLAGS="$CFLAGS" 

	echo "-----configure执行执行-----"

	makeFunc

	echo "-----完成编译 $1 环境!-----"
}



#arm64 最少要编译这个
buildIphonesFunc arm64

#armv7 不编译注释此行
buildIphonesFunc armv7

#armv7s 不编译注释此行
buildIphonesFunc armv7s

#x86_64 不编译注释此行
buildIPhonesimulatorFunc x86_64

#i386 不编译注释此行
buildIPhonesimulatorFunc i386

cd ..
echo "-----合并静态库开始-----"

rm -rf fat/lib
rm -rf fat/include

mkdir -p fat/lib
mkdir -p fat/include

#合并静态库
CWD=`pwd`
FINDPATH=$CWD/thin
FAT_LIB=$CWD/fat/lib
cp -rf thin/arm64/include/ fat/include
cd thin/arm64/lib/
for LIB in *.a
do
	res=`find $FINDPATH -name $LIB`
	lipo -create $res -output $FAT_LIB/$LIB
	lipo -info $FAT_LIB/$LIB
done
echo "-----合并静态库结束-----"