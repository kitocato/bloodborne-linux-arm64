/* libm.so for libbbaot.so built by bb-recomp against Android bionic: it imports eight math
   functions with bionic's symbol version LIBC. Forward them to glibc's libm.so.6. */
#include <dlfcn.h>

typedef double (*f1)(double);
typedef double (*f2)(double, double);
static f1 p_sin, p_cos, p_tan, p_exp2, p_log2;
static f2 p_atan2, p_fmod, p_remainder;

__attribute__((constructor)) static void init(void)
{
    void *m = dlopen("libm.so.6", RTLD_NOW | RTLD_GLOBAL);
    p_sin = (f1)dlsym(m, "sin");   p_cos = (f1)dlsym(m, "cos");   p_tan = (f1)dlsym(m, "tan");
    p_exp2 = (f1)dlsym(m, "exp2"); p_log2 = (f1)dlsym(m, "log2");
    p_atan2 = (f2)dlsym(m, "atan2"); p_fmod = (f2)dlsym(m, "fmod");
    p_remainder = (f2)dlsym(m, "remainder");
}

double sin(double x) { return p_sin(x); }
double cos(double x) { return p_cos(x); }
double tan(double x) { return p_tan(x); }
double exp2(double x) { return p_exp2(x); }
double log2(double x) { return p_log2(x); }
double atan2(double y, double x) { return p_atan2(y, x); }
double fmod(double x, double y) { return p_fmod(x, y); }
double remainder(double x, double y) { return p_remainder(x, y); }
