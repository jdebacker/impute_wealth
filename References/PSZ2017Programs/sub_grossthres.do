/*
        ----------------------------------------------------------------
		Sets the thresholds at which tax units are required to file a
		return for each of the filing status.
        ----------------------------------------------------------------

Definitions:

gross1n: single under 65
gross1a: single 65+
gross2n0: married filing jointly both under 65
gross2a1: married filing jointly one 65+
gross2a2: married filing jointly both 65+
gross3n: head of household under 65
gross3a: head of household 65+

*/
gen tax_year = year-1

*generates the filing threshold variables
	gen gross1n = .
		replace gross1n = 9500*((1.025)^5) if tax_year>=2016
		replace gross1n = 9500*((1.025)^4) if tax_year==2015
		replace gross1n = 9500*((1.025)^3) if tax_year==2014
		replace gross1n = 9500*((1.025)^2) if tax_year==2013
		replace gross1n = 9500*(1.025) if tax_year==2012
		replace gross1n = 9500 if tax_year==2011
		replace gross1n = 9350 if tax_year==2010
		replace gross1n = 9350 if tax_year==2009
		replace gross1n = 8950 if tax_year==2008
		replace gross1n = 8750 if tax_year==2007
		replace gross1n = 8450 if tax_year==2006
		replace gross1n = 8200 if tax_year==2005
		replace gross1n = 7950 if tax_year==2004
		replace gross1n = 7800 if tax_year==2003
		replace gross1n = 7700 if tax_year==2002
		replace gross1n = 7450 if tax_year==2001
		replace gross1n = 7200 if tax_year==2000
		replace gross1n = 7050 if tax_year==1999
		replace gross1n = 6950 if tax_year==1998
		replace gross1n = 6800 if tax_year==1997
		replace gross1n = 6550 if tax_year==1996
		replace gross1n = 6400 if tax_year==1995
		replace gross1n = 6250 if tax_year==1994
		replace gross1n = 6050 if tax_year==1993
		replace gross1n = 5900 if tax_year==1992
		replace gross1n = 5500 if tax_year==1991
		replace gross1n = 5300 if tax_year==1990
		replace gross1n = 5100 if tax_year==1989
		replace gross1n = 4950 if tax_year==1988
		replace gross1n = 4440 if tax_year==1987
		replace gross1n = 3560 if tax_year==1986
		replace gross1n = 3430 if tax_year==1985
		replace gross1n = 3300 if tax_year<=1984 & tax_year>1978
		replace gross1n = 2950 if tax_year<=1978 & tax_year>1976
		replace gross1n = 2450 if tax_year==1976
		replace gross1n = 2350 if tax_year==1975
		replace gross1n = 2050 if (tax_year<=1974 & tax_year>1971)
		replace gross1n = 1700 if (tax_year<=1971 & tax_year>1969)
		replace gross1n = 600 if tax_year<=1969
	gen gross1a = .
		replace gross1a = 10950*((1.025)^5) if tax_year>=2016
		replace gross1a = 10950*((1.025)^4) if tax_year==2015
		replace gross1a = 10950*((1.025)^3) if tax_year==2014
		replace gross1a = 10950*((1.025)^2) if tax_year==2013
		replace gross1a = 10950*(1.025) if tax_year==2012
		replace gross1a = 10950 if tax_year==2011
		replace gross1a = 10750 if tax_year==2010
		replace gross1a = 10750 if tax_year==2009
		replace gross1a = 10300 if tax_year==2008
		replace gross1a = 10050 if tax_year==2007
		replace gross1a = 9700 if tax_year==2006
		replace gross1a = 9450 if tax_year==2005
		replace gross1a = 9150 if tax_year==2004
		replace gross1a = 8950 if tax_year==2003
		replace gross1a = 8850 if tax_year==2002
		replace gross1a = 8550 if tax_year==2001
		replace gross1a = 8300 if tax_year==2000
		replace gross1a = 8100 if tax_year==1999
		replace gross1a = 8000 if tax_year==1998
		replace gross1a = 7800 if tax_year==1997
		replace gross1a = 7550 if tax_year==1996
		replace gross1a = 7350 if tax_year==1995
		replace gross1a = 7200 if tax_year==1994
		replace gross1a = 6950 if tax_year==1993
		replace gross1a = 6800 if tax_year==1992
		replace gross1a = 6400 if tax_year==1991
		replace gross1a = 6100 if tax_year==1990
		replace gross1a = 5850 if tax_year==1989
		replace gross1a = 5700 if tax_year==1988
		replace gross1a = 5650 if tax_year==1987
		replace gross1a = 4640 if tax_year==1986
		replace gross1a = 4470 if tax_year==1985
		replace gross1a = 4300 if tax_year<=1984 & tax_year>1978
		replace gross1a = 3700 if tax_year<=1978 & tax_year>1976
		replace gross1a = 3200 if tax_year==1976
		replace gross1a = 3100 if tax_year==1975
		replace gross1a = 2800 if (tax_year<=1974 & tax_year>1971)
		replace gross1a = 2300 if (tax_year<=1971 & tax_year>1969)
		replace gross1a = 1200 if tax_year<=1969
	gen gross3n = .
		replace gross3n = 12200*((1.025)^5) if tax_year>=2016
		replace gross3n = 12200*((1.025)^4) if tax_year==2015
		replace gross3n = 12200*((1.025)^3) if tax_year==2014
		replace gross3n = 12200*((1.025)^2) if tax_year==2013
		replace gross3n = 12200*(1.025) if tax_year==2012
		replace gross3n = 12200  if tax_year==2011
		replace gross3n = 12000 if tax_year==2010
		replace gross3n = 12000 if tax_year==2009
		replace gross3n = 11500 if tax_year==2008
		replace gross3n = 11250 if tax_year==2007
		replace gross3n = 10850 if tax_year==2006
		replace gross3n = 10500 if tax_year==2005
		replace gross3n = 10250 if tax_year==2004
		replace gross3n = 10050 if tax_year==2003
		replace gross3n = 9900 if tax_year==2002
		replace gross3n = 9550 if tax_year==2001
		replace gross3n = 9250 if tax_year==2000
		replace gross3n = 9100 if tax_year==1999
		replace gross3n = 8950 if tax_year==1998
		replace gross3n = 8700 if tax_year==1997
		replace gross3n = 8450 if tax_year==1996
		replace gross3n = 8250 if tax_year==1995
		replace gross3n = 8050 if tax_year==1994
		replace gross3n = 7800 if tax_year==1993
		replace gross3n = 7550 if tax_year==1992
		replace gross3n = 7150 if tax_year==1991
		replace gross3n = 6800 if tax_year==1990
		replace gross3n = 6550 if tax_year==1989
		replace gross3n = 6350 if tax_year==1988
		replace gross3n = 4440 if tax_year==1987
		replace gross3n = 3560 if tax_year==1986
		replace gross3n = 3430 if tax_year==1985
		replace gross3n = 3300 if tax_year<=1984 & tax_year>1978
		replace gross3n = 2950 if tax_year<=1978 & tax_year>1976
		replace gross3n = 2450 if tax_year==1976
		replace gross3n = 2350 if tax_year==1975
		replace gross3n = 2050 if (tax_year<=1974 & tax_year>1971)
		replace gross3n = 1700 if (tax_year<=1971 & tax_year>1969)
		replace gross3n = 600 if tax_year<=1969
	gen gross3a = .
		replace gross3a = 13650*((1.025)^5) if tax_year>=2016
		replace gross3a = 13650*((1.025)^4) if tax_year==2015
		replace gross3a = 13650*((1.025)^3) if tax_year==2014
		replace gross3a = 13650*((1.025)^2) if tax_year==2013
		replace gross3a = 13650*(1.025) if tax_year==2012
		replace gross3a = 13650  if tax_year==2011
		replace gross3a = 13400 if tax_year==2010
		replace gross3a = 13400 if tax_year==2009
		replace gross3a = 12850 if tax_year==2008
		replace gross3a = 12500 if tax_year==2007
		replace gross3a = 12100 if tax_year==2006
		replace gross3a = 11750 if tax_year==2005
		replace gross3a = 11450 if tax_year==2004
		replace gross3a = 11200 if tax_year==2003
		replace gross3a = 11050 if tax_year==2002
		replace gross3a = 10650 if tax_year==2001
		replace gross3a = 10350 if tax_year==2000
		replace gross3a = 10150 if tax_year==1999
		replace gross3a = 10000 if tax_year==1998
		replace gross3a = 9700 if tax_year==1997
		replace gross3a = 9450 if tax_year==1996
		replace gross3a = 9200 if tax_year==1995
		replace gross3a = 9000 if tax_year==1994
		replace gross3a = 8700 if tax_year==1993
		replace gross3a = 8450 if tax_year==1992
		replace gross3a = 8000 if tax_year==1991
		replace gross3a = 7600 if tax_year==1990
		replace gross3a = 7300 if tax_year==1989
		replace gross3a = 7100 if tax_year==1988
		replace gross3a = 7050 if tax_year==1987
		replace gross3a = 4640 if tax_year==1986
		replace gross3a = 4470 if tax_year==1985
		replace gross3a = 4300 if tax_year<=1984 & tax_year>1978
		replace gross3a = 3700 if tax_year<=1978 & tax_year>1976
		replace gross3a = 3200 if tax_year==1976
		replace gross3a = 3100 if tax_year==1975
		replace gross3a = 2800 if (tax_year<=1974 & tax_year>1971)
		replace gross3a = 2300 if (tax_year<=1971 & tax_year>1969)
		replace gross3a = 1200 if tax_year<=1969
	gen gross2n0 = .
		replace gross2n0 = 19000*((1.025)^5) if tax_year>=2016
		replace gross2n0 = 19000*((1.025)^4) if tax_year==2015
		replace gross2n0 = 19000*((1.025)^3) if tax_year==2014
		replace gross2n0 = 19000*((1.025)^2) if tax_year==2013
		replace gross2n0 = 19000*(1.025) if tax_year==2012
		replace gross2n0 = 19000 if tax_year==2011
		replace gross2n0 = 18700 if tax_year==2010
		replace gross2n0 = 18700 if tax_year==2009
		replace gross2n0 = 17900 if tax_year==2008
		replace gross2n0 = 17500 if tax_year==2007
		replace gross2n0 = 16900 if tax_year==2006
		replace gross2n0 = 16400 if tax_year==2005
		replace gross2n0 = 15900 if tax_year==2004
		replace gross2n0 = 15600 if tax_year==2003
		replace gross2n0 = 13850 if tax_year==2002
		replace gross2n0 = 13400 if tax_year==2001
		replace gross2n0 = 12950 if tax_year==2000
		replace gross2n0 = 12700 if tax_year==1999
		replace gross2n0 = 12500 if tax_year==1998
		replace gross2n0 = 12200 if tax_year==1997
		replace gross2n0 = 11800 if tax_year==1996
		replace gross2n0 = 11550 if tax_year==1995
		replace gross2n0 = 11250 if tax_year==1994
		replace gross2n0 = 10900 if tax_year==1993
		replace gross2n0 = 10600 if tax_year==1992
		replace gross2n0 = 10000 if tax_year==1991
		replace gross2n0 = 9550 if tax_year==1990
		replace gross2n0 = 9200 if tax_year==1989
		replace gross2n0 = 8900 if tax_year==1988
		replace gross2n0 = 7560 if tax_year==1987
		replace gross2n0 = 5830 if tax_year==1986
		replace gross2n0 = 5620 if tax_year==1985
		replace gross2n0 = 5400 if tax_year<=1984 & tax_year>1978
		replace gross2n0 = 4700 if tax_year<=1978 & tax_year>1976
		replace gross2n0 = 3600 if tax_year==1976
		replace gross2n0 = 3400 if tax_year==1975
		replace gross2n0 = 2800 if (tax_year<=1974 & tax_year>1971)
		replace gross2n0 = 2300 if (tax_year<=1971 & tax_year>1969)
		replace gross2n0 = 600 if tax_year<=1969
	gen gross2a1 = .
		replace gross2a1 = 20150*((1.025)^5) if tax_year>=2016
		replace gross2a1 = 20150*((1.025)^4) if tax_year==2015
		replace gross2a1 = 20150*((1.025)^3) if tax_year==2014
		replace gross2a1 = 20150*((1.025)^2) if tax_year==2013
		replace gross2a1 = 20150*(1.025) if tax_year==2012
		replace gross2a1 = 20150 if tax_year==2011
		replace gross2a1 = 19800 if tax_year==2010
		replace gross2a1 = 19800 if tax_year==2009
		replace gross2a1 = 18950 if tax_year==2008
		replace gross2a1 = 18550 if tax_year==2007
		replace gross2a1 = 17900 if tax_year==2006
		replace gross2a1 = 17400 if tax_year==2005
		replace gross2a1 = 16850 if tax_year==2004
		replace gross2a1 = 16550 if tax_year==2003
		replace gross2a1 = 14750 if tax_year==2002
		replace gross2a1 = 14300 if tax_year==2001
		replace gross2a1 = 13800 if tax_year==2000
		replace gross2a1 = 13550 if tax_year==1999
		replace gross2a1 = 13350 if tax_year==1998
		replace gross2a1 = 13000 if tax_year==1997
		replace gross2a1 = 12600 if tax_year==1996
		replace gross2a1 = 12300 if tax_year==1995
		replace gross2a1 = 12000 if tax_year==1994
		replace gross2a1 = 11600 if tax_year==1993
		replace gross2a1 = 11300 if tax_year==1992
		replace gross2a1 = 10650 if tax_year==1991
		replace gross2a1 = 10200 if tax_year==1990
		replace gross2a1 = 9800 if tax_year==1989
		replace gross2a1 = 9500 if tax_year==1988
		replace gross2a1 = 9400 if tax_year==1987
		replace gross2a1 = 6910 if tax_year==1986
		replace gross2a1 = 6660 if tax_year==1985
		replace gross2a1 = 6400 if tax_year<=1984 & tax_year>1978
		replace gross2a1 = 5450 if tax_year<=1978 & tax_year>1976
		replace gross2a1 = 4350 if tax_year==1976
		replace gross2a1 = 4150 if tax_year==1975
		replace gross2a1 = 3550 if (tax_year<=1974 & tax_year>1971)
		replace gross2a1 = 2900 if (tax_year<=1971 & tax_year>1969)
		replace gross2a1 = 1200 if tax_year<=1969
	gen gross2a2 = .
		replace gross2a2 = 21300*((1.025)^5) if tax_year>=2016
		replace gross2a2 = 21300*((1.025)^4) if tax_year==2015
		replace gross2a2 = 21300*((1.025)^3) if tax_year==2014
		replace gross2a2 = 21300*((1.025)^2) if tax_year==2013
		replace gross2a2 = 21300*(1.025) if tax_year==2012
		replace gross2a2 = 21300 if tax_year==2011
		replace gross2a2 = 20900 if tax_year==2010
		replace gross2a2 = 20900 if tax_year==2009
		replace gross2a2 = 20000 if tax_year==2008
		replace gross2a2 = 19600 if tax_year==2007
		replace gross2a2 = 18900 if tax_year==2006
		replace gross2a2 = 18400 if tax_year==2005
		replace gross2a2 = 17800 if tax_year==2004
		replace gross2a2 = 17500 if tax_year==2003
		replace gross2a2 = 15650 if tax_year==2002
		replace gross2a2 = 15200 if tax_year==2001
		replace gross2a2 = 14650 if tax_year==2000
		replace gross2a2 = 14400 if tax_year==1999
		replace gross2a2 = 14200 if tax_year==1998
		replace gross2a2 = 13800 if tax_year==1997
		replace gross2a2 = 13400 if tax_year==1996
		replace gross2a2 = 13050 if tax_year==1995
		replace gross2a2 = 12750 if tax_year==1994
		replace gross2a2 = 12300 if tax_year==1993
		replace gross2a2 = 12000 if tax_year==1992
		replace gross2a2 = 11300 if tax_year==1991
		replace gross2a2 = 10850 if tax_year==1990
		replace gross2a2 = 10400 if tax_year==1989
		replace gross2a2 = 10100 if tax_year==1988
		replace gross2a2 = 10000 if tax_year==1987
		replace gross2a2 = 7990 if tax_year==1986
		replace gross2a2 = 7700 if tax_year==1985
		replace gross2a2 = 7400 if tax_year<=1984 & tax_year>1978
		replace gross2a2 = 6200 if tax_year<=1978 & tax_year>1976
		replace gross2a2 = 5100 if tax_year==1976
		replace gross2a2 = 4900 if tax_year==1975
		replace gross2a2 = 4300 if (tax_year<=1974 & tax_year>1971)
		replace gross2a2 = 3500 if (tax_year<=1971 & tax_year>1969)
		replace gross2a2 = 1200 if tax_year<=1969

gen ssincths = .
replace ssincths = 25000
*replace ssincths = 25000 if tax_year<=2009 & tax_year>1986

gen ssincthm = .
replace ssincthm = 32000
*replace ssincthm = 32000 if tax_year<=2009 & tax_year>1986

gen ssincth = .
replace ssincth = ssincthm if a_spouse!=0
replace ssincth = ssincths if a_spouse==0

gen oldth = 7500 // I am ignoring issues of whether married/single and how many seniors
