#!/bin/sh
[ -n "$(docker image ls -q f)" ] || \
docker build -t f - << 'EOF' || exit $?
FROM alpine:latest
RUN apk --no-cache add vim build-base gdb musl-dbg && rm -f /etc/vim/vimrc && \
    printf '#!/bin/sh\nexec /usr/bin/gdb -q $*\n' > /usr/local/bin/gdb && chmod +x /usr/local/bin/gdb
RUN echo "aug reset_term | exe 'au! vimenter * sleep 100m | set term&' | aug END" > /etc/vim/vimrc
RUN printf "\
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
--init \
-i $TTY \
--security-opt=seccomp=unconfined \
--cap-add sys_ptrace \
--mount type=volume,src=f.,dst=/lab \
-w /lab \
-e COLORFGBG \
-e CXXFLAGS="-g -Og -std=c++17 -ftrapv -D_GLIBCXX_DEBUG" \
-e CPLUS_INCLUDE_PATH=/lab/.include \
-e VIMINIT="ru defaults.vim | set et sts=-1 sw=2" \
f "$@"
