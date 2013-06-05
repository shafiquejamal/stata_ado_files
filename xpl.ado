/*
xpl: stata based browser
Nov 19 2006,
Mikhail Bontch-Osmolovski
misha.bonch@gmail.com
*/
#delimit;
version 9;
cap program drop xpl;
program define xpl;
args type name;
global EXCELDIR = "C:\Program Files\Microsoft Office\Office11\excel.exe";
global WORDDIR  = "C:\Program Files\Microsoft Office\Office11\WINWORD.EXE";
global PDFDIR   = "C:\Program Files\adobe\acrobat 7.0\reader\acrord32.exe";

 /* Select what to do after a click */
if ("`type'" == "dir") {;
cd `"`name'"';
xpl;
exit;
};

if ("`type'" == "ado" | "`type'" == "do") {;
do "`name'";
xpl;
exit;
};

if ("`type'" == "dta") {;
use  "`name'", clear;
exit;
};

if ("`type'" == "log") {;
view   "`name'";
exit;
};

if ("`type'" == "txt") {;
view   "`name'";
exit;
};

if ("`type'" == "xml" | "`type'"=="xls") {;
winexec    "$EXCELDIR" "`name'";
exit;
};

if ("`type'" == "doc") {;
winexec "$WORDDIR" "`name'";
exit;
};

if ("`type'" == "pdf") {;
winexec "$PDFDIR" "`name'";
exit;
};



/* if no arguments - analyze and display files*/
	local cur_dir `c(pwd)';
	di "Current directory `cur_dir'"; 
	local dirs      : dir . dirs "*";
	local all_files : dir . files "*";
	local adofiles  : dir . files "*.ado";
	local dofiles   : dir . files "*.do";
	local dtafiles  : dir . files "*.dta";
	local docfiles  : dir . files "*.doc";
	local xlsfiles  : dir . files "*.xls";
	local xmlfiles  : dir . files "*.xml";
	local logfiles  : dir . files "*.log";
	local txtfiles  : dir . files "*.txt";
	local hlpfiles  : dir . files "*.hlp";
	local pdffiles  : dir . files "*.pdf";
	local other     : dir . other "*";
 /*Directories*/
noi di "Directories";
noi di `"{stata `"xpl dir .."' :    <..> }"';
foreach dir of local dirs {;
    local cmd "xpl dir  `"`c(pwd)'/`dir'"'";
noi di `"{stata `"`cmd'"' :    <`dir'> }"';
};
 /*Files*/
local n : word count `all_files'; 
if (`n'>0) {; 
noi di "Files:";
 //local dofiles; local adofiles; local wordfiles; local xlfiles; local dtafiles; local 
 //local txtfiles `"`adofiles'"' `"`dofiles'"' `"`txtfiles'"';
 //local txtfiles `" `adofiles' "' `" `dofiles' "' `" `txtfiles' "';

local txtfiles  `"`adofiles'   `dofiles'  `hlpfiles' `txtfiles'"' ;

foreach ext in ado do dta log pdf doc xls xml txt {;
        // noi di `"``ext'files'"';
        local n : word count ``ext'files'; 
        if (`n'>0) {; //``ext'files''"!="") {;
        noi di ".`ext'";
	foreach file of local `ext'files{;
		//local cmd "xpl `ext' `file'";
	         local cmd "xpl `ext' `"`c(pwd)'/`file'"'";
		
		noi di `"{stata `"`cmd'"' :    `file' }"';
		local all_files : subinstr local all_files "`file'" ".";
		}; // end foreach file;
	}; // end if n >0 	
}; // end foreach ext

foreach file of local all_files{;
	if "`file'"~="." {;noi di "`file'";};
	}; // end if foreach of files

noi di `other';
foreach file of local other{;
	noi di "`file'";
}; // end if foreach of other
}; // end if n of all files > 0 
 //"local a:  dir ["]dirname["] {files|dirs|other} ["]pattern["] [, nofail ]"
	
end; // prog xpl
 