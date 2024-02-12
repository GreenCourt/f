#!/bin/sh
[ -n "$(docker image ls -q f)" ] || \
docker build -t f - << 'EOF' || exit $?
FROM alpine:latest
RUN apk --no-cache add vim build-base gdb musl-dbg && rm -f /etc/vim/vimrc
RUN \
printf "%s\n" "set startup-quietly on" > /root/.gdbearlyinit && \
printf "\
python\n\
import sys,glob\n\
sys.path.insert(0, glob.glob('/usr/share/gcc-*')[0] + '/python')\n\
from libstdcxx.v6.printers import register_libstdcxx_printers\n\
from libstdcxx.v6.xmethods import register_libstdcxx_xmethods\n\
register_libstdcxx_printers(None)\n\
register_libstdcxx_xmethods(None)\n\
end\n\
" > /root/.gdbinit
CMD ["vim"]
EOF

[ -t 0 -a -t 1 ] && TTY=-t || TTY=
exec docker container run \
--rm \
-i $TTY \
--net=host \
--log-driver=none \
--detach-keys "ctrl-_,ctrl-_,ctrl-_,ctrl-_,ctrl-_" \
--security-opt=seccomp=unconfined \
--cap-add sys_ptrace \
--mount type=volume,src=f.,dst=/lab \
-w /lab \
-e TERM \
-e COLORFGBG \
-e CXXFLAGS="-std=c++17 -g -ftrapv -D_GLIBCXX_ASSERTIONS -Wall -Wextra -Wno-sign-compare -Wfloat-equal -Wfloat-conversion -Wshadow=local" \
-e CPLUS_INCLUDE_PATH=/lab/.include \
-e VIMINIT="ru defaults.vim | set et sts=-1 sw=2" \
f "$@"
