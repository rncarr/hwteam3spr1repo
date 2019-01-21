%let title   = ZIPLINING TEST DESIGN;
%let var     = location price experience other;
%let factors = location=5 price=4 experience=3 other=4;
%let levels  =  location     nvals=(1 2 3 4 5)
                price  		 nvals=(1 2 3 4)
                experience   nvals=(1 2 3)
                other        nvals=(1 2 3 4)
                ;
%let class = location price experience other;
%let points  = n=28;
%let model   = location|price|experience|other;

PROC PLAN ORDERED seed=940522;
  FACTORS &factors
          /NOPRINT;
  OUTPUT OUT=ENUM
         &levels;
Run;

PROC OPTEX DATA=ENUM SEED=112358;
  CLASS &class;
  MODEL &model;
  GENERATE &points
           ITER=500
           criterion=D

           ;
  OUTPUT OUT=DSGN1;
  title &title;
run; 

proc sort data=dsgn1;
  by &var;

PROC PRINT DATA=DSGN1;
run;

proc tabulate 
  data=dsgn1 noseps;
  class &var;
  table &var all
        ,
	     n='Design Points'     
          *f=comma15.
	    /rts=10;
run;

proc power; 
   twosamplefreq test=fisher
     groupproportions = (.005 .01) 
     npergroup = .
     power = .80 
     sides = 1
     alpha=.05;
run;


proc power;
     multreg
        model = random
        nfullpredictors = 18
        ntestpredictors = 1
        partialcorr = 0 to 1 by 0.05
        ntotal = .
        power = .8;
run;



 proc power;
   logistic
      vardist("location") = ordinal((1 2 3 4 5) : (0.2,0.2,0.2,0.2,0.2))
      vardist("price") = ordinal((1 2 3 4) : (0.25,0.25,0.25,0.25))
      vardist("experience") = ordinal((1 2 3) : (0.33,0.33,0.34))
      vardist("other") = ordinal((1 2 3 4) : (0.25,0.25,0.25,0.25))
      responseprob = 0.005 0.015
      alpha = 0.1
      power = 0.8
      ntotal = .;
run;

 proc power;
   logistic
      vardist("Heat") = ordinal((5 10 15 20) : (0.2 0.3 0.3 0.2))
      vardist("Soak") = ordinal((2 4 6) : (0.4 0.4 0.2))
      vardist("Mass1") = normal(4, 1)
      vardist("Mass2") = normal(4, 2)
      testpredictor = "Heat"
      covariates = "Soak" | "Mass1" "Mass2"
      responseprob = 0.15 0.25
      testoddsratio = 1.2
      units= ("Heat" = 5)
      covoddsratios = 1.4 | 1 1.3
      alpha = 0.1
      power = 0.9
      ntotal = .;
run;
