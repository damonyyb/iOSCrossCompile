

## 背景

iOS 平台经常遇到需要编译第三方库的情况，比如ffmpeg，openssl faad 、fdkaac、 curl  、mp4v2等等,一遇到编译的时候，免不了各种搜索编译脚本文件，但有些第三方库的脚本少,异常多，针对iOS平台的编译就更少了，有时候只是需要更新一下第三方库的版本又是一堆莫名其妙的报错，然后再编译调试，无形中成为了项目delay的风险点，也是程序员的噩梦。为了避免重复工作，这里编写一篇通用的iOS脚本库，可以适用于大部分的第三方库。经过测试已经支持 <u>**faad2 /curl / fdk-aac /flac/lame /opus/speex**</u> 第三方库，通用性极强。



## 脚本内容

buildIOS.sh

```ruby
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

```



## 举例

### 编译Lame(所有第三方库步骤完全一样)

新建build文件夹

- [下载lame 最新版本]( https://sourceforge.net/projects/lame/files/lame/) lame-3.100.tar.gz
- 解压 lame-3.100.tar.gz 到 build 文件夹 文件名为 lame-3.100 
- 拷贝 buildIOS.sh到build文件夹  修改buildIOS.sh 第8行NAME 为 lame-3.100   NAME="lame-3.100"



当前目录结构

```ruby
build/
├── buildIOS.sh #脚本
├── lame-3.100/ #解压缩的源代码
└── lame-3.100.tar.gz #下载的源代码
```



打开终端 执行

```ruby
cd ~./build 

chmod u+x buildIOS.sh

./buildIOS.sh
```



编译完成的最后打印 

```ruby
Architectures in the fat file: /Users/Downloads/build/buildIOS/fat/lib/libmp3lame.a are: i386 armv7 armv7s x86_64 arm64 
```



编译完成后会在build目录下生成一个buildIOS文件夹 

```ruby
build/
├── lame-3.100.tar.gz 
├── buildIOS.sh
├── lame-3.100/
└── buildIOS/
│   ├── lame-3.100/ #复制了一份文件用于编译
│   ├── fat/ #最终生成的多平台库 
│   │   ├── include/#头文件
│   │   │   └── lame/
│   │   │       └── lame.h
│   │   └── lib/#静态库
│   │       └── libmp3lame.a 
│   └── thin/ #对应个单独平台需要的库
│       ├── arm64/
│       ├── armv7/
│       ├── armv7s/
│       ├── i386/
│       └── x86_64/
```



## 备注

脚本并不是万能的，只能用于编译第三方库会按照configure标准编写的库，有些第三方会失败 ，比如openssl x264，ffmpeg ,需要找其他脚本编译。



## 实现原理

第三方库的交叉编译 需要调用configure脚本和make来实现，configure脚本需要通过传入的参数来指定 需要编译的编译器，编译环境，编译平台等相关信息，而在iOS平台下这些信息 是不变的，所以将这些不变的参数抽成一buildIOS脚本 ，当运行buildIOS时 ，就会将相关的参数导入configure 开始进行编译。



## 知识点

### 编译

在程序开发中，使用高级语言编写的代码被称为源代码，一般来说，无论是C、C++、还是pas，首先要把源代码编译成***\*中间代码文件\****，在Windows下也就是 .obj 文件，UNIX下是 .o 文件，即 Object File，这个动作叫做***\*编译（compile）\****。然后再把大量的***\*中间代码文件\****合成执行文件，这个动作叫作链接（link）。  

编译时 编译器需要的是语法的正确，函数与变量的声明的正确。对于后者，通常是你需要告诉编译器头文件的所在位置（头文件中应该只是声明，而定义应该放在C/C++文件中），只要所有的语法正确，编译器就可以编译出中间目标文件。一般来说，每个源文件都应该对应于一个中间目标文件（O文件或是OBJ文件）。 

链接时 主要是链接函数和全局变量，所以，我们可以使用这些中间目标文件（O文件或是OBJ文件）来链接我们的应用程序。链接器并不管函数所在的源文件，只管函数的中间目标文件（Object File），在大多数时候，由于源文件太多，编译生成的中间目标文件太多，而在链接时需要明显地指出中间目标文件名，这对于编译很不方便，所以，我们要给中间目标文件打个包，在Windows下这种包叫“***\*库文件”（Library File)\****，也就是 .lib 文件，在UNIX下，是Archive File，也就是 .a 文件。

总结一下，源文件首先会生成中间目标文件，再由中间目标文件生成执行文件。在编译时，编译器只检测程序语法，和函数、变量是否被声明。如果函数未被声明，编译器会给出一个警告，但可以生成Object File。而在链接程序时，链接器会在所有的Object File中找寻函数的实现，如果找不到，那到就会报链接错误码（Linker Error），



与交叉编译相对应的是本地编译,理解本地编译有助于更好地理解交叉编译



### 本地编译

所谓"本地编译"，是指编译源代码的平台和执行源代码编译后程序的平台是同一个平台。比如，在Mac下编译给mac应用使用的程序。编译环境是Mac ，程序最后运行的环境也是Mac，平台相同。



### 交叉编译

所谓"交叉编译"，是指编译源代码的平台和执行源代码编译后程序的平台是两个不同的平台。比如，在MAC平台下、使用交叉编译工具链生成的可执行文件，在iOS平台上使用，平台不同。



### MakeFile

make命令执行时，需要一个 Makefile 文件，以告诉make命令需要怎么样的去编译和链接程序。make命令会自动智能地根据当前的文件修改的情况来确定哪些文件需要重编译，从而自己编译所需要的文件和链接目标程序。

一般来说，我们不需要自己去写makefile文件，makefile文件会由第三方库的源代码来提供，我们只需要知道，编译需要使用make即可。

常见的命令 包括、` make clean` 清除缓存， `make -jn` 其中 n代表多核加速编译数字， `make install` 开始编译



比如 本地编译的常见操作 

cd 到第三方库源码的目录下 

```ruby
./configure
make
make install
```

其中 make 就是单核的编译 make install开始编译



而这里的configure 是什么呢 其实是一个脚本，用来传入变量，代表编译时可配置的选项，可以` configure --help`来查看有哪些可配置选项，当你进行标准编译却无法编译通过时，很可能需要关闭或者打开一些配置项，才能编译通过。



### 编译参数

```ruby
./configure：代表执行configure shell脚本 后续是脚本参数
CC：编译器，对C源文件进行编译处理，生成汇编文件
CXX/CPP： 编译器，对C++/C源文件进行编译处理，生成汇编文件
CFLAGS:编译C时需要带的参数
CPPFLAGS:编译C时需要带的参数
LDFLAGS:链接时的参数
--prefix:编译结束后的库放置的目录
--host:编译的目标机器 iphone 或者mac平台
xcrun -sdk iphonesimulator/iphoneos clang 使用xcrun 找到 clang编译器
-arch:编译环境 arm64等
-fembed-bitcode 苹果要求的bitcode支持
-miphoneos-version-min=10.0 最小支持版本 10.0 
--disable-shared 不编译动态库 苹果不支持
--disable-frontend 不编译可执行文件
```





### 目标环境

iPhone和mac电脑核心处理器也更新换代多次，而代码为了能够在不同的处理器上运行，所以需要给不同的处理器平台编译对应的可执行文件，比如iPhone的armv7、 armv7s 和arm64 环境，mac环境下的i386 和x86_64。



现在电脑和手机已经都是64位机器了，大家使用的mac 就是x86_64环境 而iphone 则是arm64环境，苹果商店已经不允许上架32位的应用了。所以如果要编译一个iPhone程序，并且不需要在模拟器中运行的话，那么只需要编译arm64环境即可。如果需要在真机和模拟器中都能运行的话，那么编译arm64 和x86_64环境即可。一般先在arm64上进行编译后，再一口气编译出 armv7 armv7s arm64  i386 X86_64这5个环境下的库文件，并通过lipo命令将这5个库文件合并成一个库文件输出 是最为标准的做法。



## 参考文章

[iOS | 交叉编译 ]()



## [代码路径](https://github.com/damonyyb/iOSCrossCompile)







