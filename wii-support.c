
/* This file contains Wii-specific implementations of various
 * POSIX, GCC, and platform-init routines. It also contains the 
 * main entry point branching to GNUstep's entry point */

#include <ogcsys.h>
#include <network.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static inline s32 initialise_network() {
  s32 result;
  while ((result = net_init()) == -EAGAIN);
  return result;
}

static inline void wait_for_network_initialisation() {
  printf("Waiting for network to initialise...\n");
  if (initialise_network() >= 0) {
    char myIP[16];
    if (if_config(myIP, NULL, NULL, true) < 0) {
      printf("Error reading IP address, exiting");
      exit(1);
    }
    printf("Network initialised.  Wii IP address: %s\n", myIP);
  } else {
    printf("Unable to initialise network, exiting");
    exit(1);
  }
}

__attribute__((constructor)) void
wii_init ()
{
  
  void *xfb = NULL;
  GXRModeObj *rmode = NULL;
  
  // Initialise the video system
  VIDEO_Init();
  
  // This function initialises the attached controllers
  //WPAD_Init();
  
  // Obtain the preferred video mode from the system
  // This will correspond to the settings in the Wii menu
  rmode = VIDEO_GetPreferredMode(NULL);
  
  // Allocate memory for the display in the uncached region
  xfb = MEM_K0_TO_K1(SYS_AllocateFramebuffer(rmode));
  
  // Initialise the console, required for printf
  console_init(xfb,20,20,rmode->fbWidth,rmode->xfbHeight,rmode->fbWidth*VI_DISPLAY_PIX_SZ);
  
  // Set up the video registers with the chosen mode
  VIDEO_Configure(rmode);
  
  // Tell the video hardware where our display memory is
  VIDEO_SetNextFramebuffer(xfb);
  
  // Make the display visible
  VIDEO_SetBlack(FALSE);
  
  // Flush the video register changes to the hardware
  VIDEO_Flush();
  
  // Wait for Video setup to complete
  VIDEO_WaitVSync();
  if(rmode->viTVMode&VI_NON_INTERLACE) VIDEO_WaitVSync();
  
  
  // The console understands VT terminal escape codes
  // This positions the cursor on row 2, column 0
  // we can use variables for this with format codes too
  // e.g. printf ("\x1b[%d;%dH", row, column );
  printf("\x1b[2;0H");
  
  // Network debugging
  //wait_for_network_initialisation();
  
  //DEBUG_Init(GDBSTUB_DEVICE_TCP, 5656);
  //_break();
  
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


/* Backtrace routine for GNUstep stack debugging and EH 
 * Derived from libogc's `exception.c -> _cpu_print_stack` */

#include <ogc/machine/asm.h>

typedef struct _framerec {
  struct _framerec *up;
  void *lr;
} frame_rec, *frame_rec_t;

int backtrace(void** array, int size) {
  register u32 i = 0;
  register frame_rec_t p;
  
  __asm__ __volatile__("mr %0,%%r1" : "=r"(p));
  array[0] = p->lr;
  
  for(i=1;i<size && p->up;p=p->up,i++)
    array[i] = p->up->lr;
  
  return i;
}

#pragma mark Post-Constructor main

/* This is our post-constructor `main` function.
 * By this point, all Objective-C classes are loaded
 * and their `+load` method implementations have been executed
 * via constructor functions (like `wii_init` above).
 * 
 * This is a good place to set environment variables with `setenv`
 * before GNUstep initialises. 
 *
 * The `wiistep_main` function is the actual GNUstep entry
 * point. It will set up an initial autorelease pool and 
 * `NSProcessInfo` state. It will then branch to the user-code's
 * `main` function (which the preprocessor renamed to 
 * `gnustep_base_user_main` by `#include <Foundation/Foundation.h>`)
 */

int wiistep_main() __attribute__((weak));
int wiistep_main(int argc, char** argv, char** env) {
  printf("--- WIISTEP WARNING ---\n"
	 "This app didn't declare a `main` function or included\n"
	 "<Foundation/Foundation.h> without linking `foundation-wii`.\n"
	 "\n"
	 "Will exit in 10 seconds\n");
  sleep(10);
  return -1;
}
int main() __attribute__((weak));
int main(int argc, char** argv) {
  if (0 != wiistep_main) {
    setenv("GNUSTEP_STACK_TRACE", "1", 1);
    return wiistep_main(argc, argv, NULL);
  }
}

