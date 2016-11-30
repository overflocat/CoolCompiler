int main ( void )
{
    int i;

    for ( i = 0; i < 100; i++ )
    {
        if ( i == 50 )
            break;
    }

    if ( i == 100 )
        i++;
    else
        i--;

    return 0;
}
