

/* devkitPPC's toolchain doesn't properly emit code
 * running all CTORS from low-mem to high-mem (as clang's
 * emitted objc runtime load routines are laid out).
 * Therefore, this behaves as an alternate entry method. */
#include <stdint.h>
extern int wiistep_main(int argc, char *argv[]);
extern void(*__CTOR_END__)(void);
int main(int argc, char** argv) {
  const void* CTOR = (&__CTOR_END__)-1;
  while (*(const uint32_t*)CTOR != 0xffffffff)
    CTOR -= 4;
  CTOR += 4;
  while (CTOR != (&__CTOR_END__)) {
    void(*CTOR_FPTR)(void) = ((void(*)(void))(*(const uint32_t*)CTOR));
    CTOR_FPTR();
    CTOR += 4;
  }
  return wiistep_main(argc, argv);
}


#include <stdio.h>

void * __stack_chk_guard = NULL;
 
void __stack_chk_guard_setup()
{
    unsigned char * p;
    p = (unsigned char *) &__stack_chk_guard;
 
    /* If you have the ability to generate random numbers in your kernel then use them,
       otherwise for 32-bit code: */
    *p =  (unsigned char)0x00000aff;
}
 
void __attribute__((noreturn)) __stack_chk_fail()
{ 
    /* put your panic function or similar in here */
    printf ("Stack smash detected\n");
    unsigned char * vid = (unsigned char *)0xB8000;
    vid[1] = 7;
    for(;;)
    vid[0]++;
}

#include <unistd.h>
#include <ogc/system.h>
#define PAGE_SZ 32

int getpagesize() {return PAGE_SZ;}

long sysconf(int name) {
  switch(name) {
    case _SC_PHYS_PAGES:
      return SYS_GetArenaSize()/PAGE_SZ;
    case _SC_NPROCESSORS_CONF:
      return 1;
    case _SC_NPROCESSORS_ONLN:
      return 1;
    default:
      return -1;
  }
}

int access(const char *path, int amode) {return 0;}

int chown(const char *path, uid_t owner, gid_t group) {return 0;}

uid_t geteuid() {return 0;}

int pipe(int fildes[2]) {return -1;}
