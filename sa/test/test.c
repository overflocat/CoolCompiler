#include <stdio.h>

int main ( void )
{
    FILE *a = fopen( "a.txt", "r" );
    if ( a != NULL )
    {
	fprintf( a, "s" ); //warning
    	freopen( "a.txt", "w", a );
    	fprintf( a, "s" ); //nowarning
    	fclose( a );
    }
    return 0;
}
