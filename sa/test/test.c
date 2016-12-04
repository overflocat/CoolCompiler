#include <stdio.h>

int main ( void )
{
    FILE *a = fopen( "a.txt", "r" );
    fprintf( a, "s" ); //warning
    freopen( "a.txt", "w", stdin );
    fprintf( a, "s" ); //nowarning
    fclose( fp );
    return 0;
}
