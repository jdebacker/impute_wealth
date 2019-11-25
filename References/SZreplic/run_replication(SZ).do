* Replicates Saez-Zucman "The Distribution of Wealth in the United Statse since 1913" QJE 2016

clear
clear matrix

global dropbox "/Users/gzucman/Dropbox"
global dirirs "$dropbox/SharedData/irs" /* directory with raw PUF tax files */
global dirsmall "$dropbox/SaezZucman2014/build_usdina/Data/irs_small" 
global dirreplic "$dropbox/SaezZucman2014/PaperWealth/OnlineFiles"
global parameters "$dirreplic/ReplicationPrograms/parameters(SZ).csv"
global years "1962 1964 1966/2008"
global nbyears=45

cd $dirreplic/ReplicationPrograms

* Creates homogenous IRS "small files" from raw NBER PUF in $dirirs
 do "build60_08(SZ)"

* Creates and saves DINA micro-files with wealth obtained by capitalizing income and income matching macro totals. Tax-unit level
do "build_usdina(SZ)"

* Computes top shares (all variants)
do "top_shares(SZ)"

* Compute all SCF related statistics using publicly posted SCF files
do "scf(SZ)"

* Analysis of matched estates-income tax data for estates filed in 1977
do "estate76(SZ)"

* Analysis of publicly available foundation tax returns
do "foundation(SZ)"

* Programs run on internal IRS files
* Available upon request (file internalIRSprogs_output(donotpost).zip)
