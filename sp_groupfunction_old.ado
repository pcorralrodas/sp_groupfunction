*! sp_groupfunction
* Paul Corral - World Bank Group 
cap prog drop sp_groupfunction
program define sp_groupfunction, eclass
	version 11.2
	#delimit ;
	syntax [aw pw fw],
	by(varlist)
	[
		equivalization(varlist numeric max=1)
		coverage(varlist numeric)
		targeting(varlist numeric)
		dependency(varlist numeric)
		dependency_d(varlist numeric)
		poverty(varlist numeric)
		povertyline(varlist numeric)
		mean(varlist numeric)
		conditional
	];
#delimit cr;
//Housekeeping
local meth coverage targeting dependency poverty mean 

foreach x of local meth{
	if ("``x''"!="") local todo `todo' `x'
}
if ("`todo'"==""){
	dis as error "You must specify at least one option:" 
	dis as error "`meth'"
	error 301
	exit
}

if (("`poverty'"!="" & "`povertyline'"=="")|("`povertyline'"!="" & "`poverty'"=="")){
	dis as error "poverty and povertyline options must be specified jointly"
	error 301
	exit
}

if (("`dependency'"!="" & "`dependency_d'"=="")|("`dependency_d'"!="" & "`dependency'"=="")){
	dis as error "dependency and dependency_d options must be specified jointly"
	error 301
	exit
}

if ("`conditional'"!="" & "`dependency'"==""){
	dis as error "Conditional option only valid when dependency is specified"
	error 301
	exit
}

qui{
	tempvar _useit _gr0up _thesort
	//gen `_thesort'   =_n
	gen `_useit'	 = 1
	
	//Weights
	if "`exp'"=="" {
		tempvar w
		qui:gen `w' = 1
		local wvar `w'
	}
	else{
		tempvar w 
		qui:gen double `w' `exp'
	}
	mata: st_view(_w=., .,"`w'")
	
	if ("`equivalization'"!="")	mata: st_view(hhs=.,.,"`equivalization'")
	else mata: hhs = J(rows(_w),1,1)
	
	

//Generate the variables for the analysis, poverty is special
local pov poverty
local dep dependency
local me mean
local todo1: list todo - pov
local todo1: list todo1 - dep
local todo1: list todo1 - me

foreach method of local todo1{
	local `method': list uniq `method'
	local prefn = "_" + substr("`method'", 1,3)
	foreach x of local `method'{
		gen double `prefn'_`x' = .
		local `method'2 ``method'2' `prefn'_`x'
	}
}
forval a = 0/2{
	foreach line of local povertyline{
		foreach pov of local poverty{		
			gen `pov'_`line'_`a' = .
			local `line'_`a' ``line'_`a'' `pov'_`line'_`a'
		}
	}
}


foreach l of local dependency_d{
	local prefn = "_"+"dep"
	foreach dep of local dependency{
		gen double `prefn'_`dep'_`l' = .
		local 	_`l' `_`l'' `prefn'_`dep'_`l'
	}
}


*===============================================================================
//Prepare indicators
*===============================================================================
if ("`coverage'"!=""){
	mata: st_view(y=.,.,"`coverage'",.)
	mata:st_store(.,tokens(st_local("coverage2")),.,((y:>0):*(y:!=.)))
}
if ("`targeting'"!=""){
	mata: st_view(y=.,.,"`targeting'",.)
	mata:st_store(.,tokens(st_local("targeting2")),.,y)
}
if ("`dependency'"!=""){
	mata: st_view(y=.,.,"`dependency'",.)
	foreach l of local dependency_d{
		mata: st_view(p=.,.,"`l'",.) 
		if ("`conditional'"!="") mata:st_store(.,tokens(st_local("_`l'")),.,((y:/p):*((y:>0):*(y:!=.))))
		else mata:st_store(.,tokens(st_local("_`l'")),.,((y:/p):*(y:!=.))))
		local alldep `alldep' `_`l''
	}
}	

if ("`poverty'"!=""){
	mata: st_view(y=.,.,"`poverty'",.)	
	foreach line of local povertyline{
	mata: st_view(p=.,.,"`line'",.)
		forval a = 0/2{
		/*
		noi{
		dis as error "``line'_`a''"
		mata: cols(y)
		mata: rows(y)
		mata: cols(p)
		mata: rows(p)
		mata: mean(p)
		mata: tokens(st_local("`line'_`a'"))
		}
		*/
		mata:st_store(.,tokens(st_local("`line'_`a'")),.,((y:<p):*(-(y:/p):+1):^`a'))
		local allpov `allpov' ``line'_`a''
		}
	}		
}

//Data is ready

gen double _population=`w'

groupfunction [aw=`w'], mean(`mean' `coverage2' `allpov' `alldep') ///
sum(`targeting2') rawsum(_population) by(`by') 

}
end







