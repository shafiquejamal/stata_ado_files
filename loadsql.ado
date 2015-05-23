program define loadsql
*! Load the output of an SQL file into Stata, version 1.2 (dvmaster@gmail.com)
version 12.1
syntax using/, DSN(string) [CLEAR NOQuote LOWercase SQLshow ALLSTRing DATESTRing]

#delimit;
tempname mysqlfile exec line;

file open `mysqlfile' using `"`using'"', read text;
file read `mysqlfile' `line';

while r(eof)==0 {;
    local `exec' `"``exec'' ``line''"';
    file read `mysqlfile' `line';
};

file close `mysqlfile';


odbc load, exec(`"``exec''"') dsn(`"`dsn'"') `clear' `noquote' `lowercase' `sqlshow' `allstring' `datestring';

end;

/* All done! 

Syntax:

loadsql using "./sqlfile.sql", dsn("mysqlodbcdata") 

// https://stackoverflow.com/questions/12270275/stata-odbc-sqlfile

*/
