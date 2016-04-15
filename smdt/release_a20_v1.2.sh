# !/bin/sh
#
# Description	: Auto build some git functions.
# Authors			: jianjun jiang - jerryjianjun@gmail.com
# 						wwwen@smit.com.cn
# Version	: 0.01
# Notes		: None
#

A20_VERSION=A20-420-V12
GIT_SERVER_IP=git@192.9.50.101
GITOSIS_PREFIX=A20/$A20_VERSION.git

ROOT_DIR=`pwd`

PRODUCT=$2
auto_upload=`expr substr "$1" 1 6`
PROJECT=wordchip-a20/Android4.2/TVB_v1.2/${PRODUCT}
OUTPUTDIR=wordchip-a20/
if [ "${auto_upload}" = build_ ];then
only_upload=yes
BUILDDIR=~/$1
echo $BUILDDIR
else
only_upload=no
BUILDDIR=
fi
UPDATEDIR=
LOG=
BRANCH=$1

USAGE()
{
  echo Usage: $(basename "$0") '<branch project>'
  echo '       branch = the project branch name'
  echo '       project = the project product name'
  echo 'e.g. '$(basename "$0")' <mbox203 mbox203>'
  echo '                   <master k70>'
}

remove_directory()
{
	rm -fr ~/build_*;
	sync; sync; sync;
}

build_env_ready()
{
	remove_directory || exit 1;

	BUILDDIR=~/build_$$
	while [ -e ${BUILDDIR} ] ; do BUILDDIR=${BUILDDIR}$$; done
	
        UPDATEDIR=$BUILDDIR/$PROJECT/$BRANCH/update-$(date +[%Y-%m-%d]-[%H:%M:%S]);

	LOG=${UPDATEDIR}/log.txt
	
	mkdir -p $BUILDDIR || { echo "Could not create build directory."; exit 1; }
	mkdir -p $UPDATEDIR || { echo "Could not create update directory."; exit 1; }
}

get_source_and_build()
{
	cd ${BUILDDIR} 2>&1 >> $LOG || exit 1;
	echo $HOSTNAME >> $LOG || exit 1;
        git clone  $GIT_SERVER_IP:$GITOSIS_PREFIX 2>&1 >> $LOG || exit 1;
        cd ${BUILDDIR}/$A20_VERSION 2>&1 >> $LOG || exit 1;

        if [ ! ${BRANCH} = "master" ]; then
                git checkout -b ${BRANCH} origin/${BRANCH} 2>&1 >> $LOG || exit 1;
        fi
	echo wing_prj=wing_${PRODUCT}-eng > ./prj.sh
	./build.sh -a -p=${PRODUCT}
	./build.sh -o
	git log >${UPDATEDIR}/Version.txt
	cp -adR ${BUILDDIR}/$A20_VERSION/lichee/tools/pack/chips/sun7i/configs/android/wing-${PRODUCT}/sys_config.fex ${UPDATEDIR}/sys_cfg.txt || exit 1;
	cp -adR ${BUILDDIR}/$A20_VERSION/lichee/tools/pack/sun7i_android_wing-${PRODUCT}.img ${UPDATEDIR}/sun7i_android_${BRANCH}.img || exit 1;
	cp -adR ${BUILDDIR}/$A20_VERSION/android4.2/out/target/product/wing-${PRODUCT}/*-ota-*.zip ${UPDATEDIR}/update.zip || exit 1;
	sync;
}

upload_files()
{
cat > $BUILDDIR/upload << "EOF"
	set src [lindex $argv 0]
	set dst [lindex $argv 1]

	spawn scp -rp $src share@192.9.50.250:~/$dst
	set timeout 300
	expect "*password:"
	set timeout 300
	send "share\r"
	set timeout 300
	send "exit\r"
	expect eof
EOF
	expect -f ./upload || exit 1;
}


if [ "${only_upload}" = yes ]; then
	echo "only upload to server"
else
[ -z "$2" ] && { USAGE; exit 1; }

build_env_ready || exit 1;

get_source_and_build || exit 1;
fi
upload_files $BUILDDIR/$OUTPUTDIR ./ || exit 1;

remove_directory || exit 1;

echo "^_^ : build successed!";

