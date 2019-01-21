%let title   = ZIPLINING TEST DESIGN;
%let var     = location price experience other;
%let factors = location=5 price=4 experience=3 other=4;
%let levels  =  location     nvals=(1 2 3 4 5)
                price  		 nvals=(1 2 3 4)
                experience   nvals=(1 2 3)
                other        nvals=(1 2 3 4)
                ;
%let points  = 30;
%let model   = location|price|experience|other
               location*location price*price experience*experience other*other
               ;
*%let class = experience;

PROC PLAN ORDERED seed=940522;
  FACTORS &factors
          /NOPRINT;
  OUTPUT OUT=ENUM
         &levels
  ;
Run;

PROC OPTEX DATA=ENUM SEED=112358;
  *CLASS &class;
  MODEL &model;
  GENERATE &points
           ITER=1000
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
         nfullpredictors = 19
         ntestpredictors = 1  
         partialcorr = 0.35
         ntotal = . 
         power = 0.8;
 run;

