
/* (C)opyleft 2001-2002 Frank DENIS <j@pureftpd.org> */

#ifndef __PUREDB_P_H__
#define __PUREDB_P_H__ 1

#include <stdio.h>

# include <stdlib.h>
# include <stddef.h>
# include <stdarg.h>

#include <string.h>
//#include <strings.h>

#include <limits.h>
#include <errno.h>
# include <unistd.h>

#include <sys/types.h>
#include <sys/stat.h>

# include <fcntl.h>

# include <sys/ioctl.h>


# include <netinet/in_systm.h>


# include <netinet/in.h>


# include <sys/mman.h>


# include <sys/param.h>



#  include <alloca.h>

# define ALLOCA(X) alloca(X)
# define ALLOCA_FREE(X) do { } while (0)


#ifndef O_NOFOLLOW
# define O_NOFOLLOW 0
#endif

#ifndef O_BINARY
# define O_BINARY 0
#endif

#if !defined(O_NDELAY) && defined(O_NONBLOCK)
# define O_NDELAY O_NONBLOCK
#endif

#ifndef FNDELAY
# define FNDELAY O_NDELAY
#endif

#ifndef MAP_FILE
# define MAP_FILE 0
#endif

#ifndef MAP_FAILED
# define MAP_FAILED ((void *) -1)
#endif

#if defined(HAVE_MAPVIEWOFFILE) || defined(HAVE_MMAP)
# define USE_MAPPED_IO 1
#endif

#ifndef errno
extern int errno;
#endif

#endif

