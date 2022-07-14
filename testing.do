clear all
set more off

run "C:\Users\WB378870\GitHub\sp_groupfunction\sp_groupfunction.ado"

sysuse auto, clear

gen cheap = "Cheap" if price<5000
replace cheap = "Not cheap" if price>=5000
gen pline = 7000
sp_groupfunction [aw=weight], mean(price) gini(price trunk) poverty(price) povertyline(pline) by(foreign cheap)


