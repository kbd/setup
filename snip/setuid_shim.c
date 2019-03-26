#include <errno.h>
#include <stdio.h>
#include <unistd.h>

// compile with cc setuid_shim.c -o setuid_shim
// set suid bit with chmod +s setuid_shim

static char* EXE = "/path/to/interpreter";
static char* PROGRAM = "/path/to/script";

int main(int argc, char* argv[]){
    char* args[] = { EXE, PROGRAM, NULL };
    int err = execv(EXE, args);
    printf("Error %d, %d", err, errno);
}
