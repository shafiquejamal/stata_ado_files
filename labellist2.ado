*! version 1.0.7 08jun2012 Daniel Klein, with some modifications by Shafique Jamal (shafique.jamal@gmail.com) 05 December 2012

pr labellist2 ,rclass
        vers 9.2
        
        syntax [anything(id = "namelist")] ///
        [ , LAbels RC0 RETurnall noMissing Listonly ]
        
        // listonly message
        if ("`listonly'" != "") {
                di as txt "(note: option {bf:listonly} ignored)" _n
        }
        
        // This will be 1 or 0
        // nomissing option
        loc miss = ("`missing'" == "")
        
        // parse anything
        if (`"`anything'"' == "") { // if no arguments, then obtain and store list of all value label names
                if ("`labels'" != "") {
                        qui label dir
                        loc lblnamelist `r(names)'
                }
                else cap unab varlist : *
        }
        else { // otherwise, if arguments are present
                if ("`labels'" != "") {
                        if (`: list posof "_all" in anything') { // if the term _all is in the arguments, then remove it and obtain and store the list of all value label names
                                qui label dir
                                loc lblnamelist `r(names)'
                                loc anything : subinstr loc anything "_all" "" ,all
                        }
                }
                cap unab varlist : `anything'
                if _rc {
                        if ("`label'" == "") qui la di
                        loc lblnames `r(names)'
                        while (`"`anything'"' != "") {
                                gettoken tok anything : anything
                                if (`: list tok in lblnames') {
                                        cap conf v `tok'
                                        if !(_rc) loc varlist `varlist' `tok'
                                        else loc lblnamelist `lblnamelist' `tok'
                                }
                                else loc varlist `varlist' `tok'
                        }
                        if (`"`varlist'"' != "") unab varlist : `varlist'
                }
        }
        loc namelist `varlist' `lblnamelist'
        if ("`namelist'" == "") {
                di as err "no variables or value labels found"
                e 111
        }
        loc nvars : word count `varlist'
        loc nlbls : word count `lblnamelist'
        
        ret loc lblnamelist `lblnamelist'
        
        // loop thru namelist
        loc maxlen = cond(`nvars', 23, 25)
        token `namelist'
        forv j = 1/`=`nvars' + `nlbls'' {
                if (`j' <= `nvars') {
                        cap conf numeric v ``j''
                        if _rc continue
                        loc lbln : val l ``j''
                        if ("`lbln'" == "") continue
                }
                else loc lbln ``j''
                cap la li `lbln'
                if (_rc) | !r(k) | (mi(r(min)) & !(`miss')) continue
                
                di as res "`lbln':"
                
                // value label contents
                mata : mlabellist("`lbln'", `miss')
                if (strlen("`lbln'") > `maxlen') {
                        if ("`rc0'" == "") {
                                di as err "`lbln' name too long"
                                e 459
                        }
                        loc retlbln = abbrev("`lbln'", `maxlen')
                        loc retlbln : subinstr loc retlbln "~" "_"
                }
                else loc retlbln `lbln'
                foreach x in k nemiss max min {
                        ret sca `retlbln'_`x' = ``x''
                }
                if (`j' <= `nvars') {
                        if (`nvars' > 1) | ("`returnall'" != "") {
                                if (strlen("``j''") > `maxlen') {
                                        if ("`rc0'" == "") {
                                                di as err "``j'' name too long"
                                                e 459
                                        }
                                        loc pre = abbrev("``j''", `maxlen')
                                        loc pre : subinstr loc pre "~" "_"
                                }
                                else loc pre ``j''_
                        }
                        loc varl : var l ``j''
                        if (`"`macval(varl)'"' != "") {
                                if strpos(`"`macval(varl)'"', `"""') {
                                        if ("`pre'" == "") ret loc _varlabel `"`varl'"'
                                        ret loc `pre'varlabel `"`varl'"'
                                }
                                else {
                                        if ("`pre'" == "") ret loc _varlabel `"`varl'"'
                                        ret loc `pre'varlabel "`varl'"
                                }
                        }
                        ret loc `pre'lblname "`lbln'"
                        if ("`pre'" == "") ret loc _lblname "`lbln'"
                        foreach x in values labels {
                                if ("`pre'" == "") ret loc _`x' `"`macval(`x')'"'
                                ret loc `pre'`x' `"`macval(`x')'"'
                        }
                        continue
                }
                foreach x in values labels {
                        ret loc `retlbln'_`x' `"`macval(`x')'"'
                }
        }
end

vers 9.2
mata:
void mlabellist(string scalar lbln, real scalar miss)
{
        real vector v
        string vector t
        real scalar i
        string scalar vals, lb, lbls
        
        st_vlload(lbln, v = ., t = "")
        
        if (!(miss)) {
                v = select(v, v :< .)
                t = st_vlmap(lbln, v)
        }
        
        for (i = 1; i <= rows(v); ++i) {
                printf("%12s %s \n", strofreal(v[i, 1]), t[i, 1])
                lb = t[i, 1]
                if (!(strpos(lb, `"""'))) lb = `"""' + lb + `"""'
                else lb = "`" + `"""' + lb + `"""' + "'"
                if (i == 1) {
                        vals = strofreal(v[i, 1])
                        lbls = lb
                }
                else {
                        vals = vals + " " + strofreal(v[i, 1])
                        lbls = lbls + " " + lb
                }
        }
        st_local("values", vals)
        st_local("labels", lbls)
        st_local("min", strofreal(min(v)))
        st_local("max", strofreal(max(v)))
        st_local("nemiss", strofreal(colsum(v :> .)))
        st_local("k", strofreal(rows(v)))
}
end
e

1.0.7   08jun2012       decalare real scalar miss in mata function
                                        better error message if no variables defined
1.0.6   29mar2012       add new option -nomissing-
1.0.5   11mar2012       fix bug in r(_*) (not released)
1.0.4   04feb2012       change rc0 option now abbreviates names
1.0.3   04jan2012       use more Mata code
                                        solve problem with left single quotes
                                        more than one variable implies -returnall-
                                        new option -label-
                                        namelist may be varlist lblname-list or both
1.0.2   11aug2011       fix left single quote
                                        part of -labutil2- package
1.0.1   20may2011       typo corrected
                                        version 9.2
