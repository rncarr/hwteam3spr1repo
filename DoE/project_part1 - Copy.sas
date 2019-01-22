%let title   = ZIPLINING TEST DESIGN;
%let var     = location price experience other;
%let factors = location=5 price=4 experience=3 other=4;
%let levels  =  location     cvals=('1' '2' '3' '4' '5')
                price  		 nvals=(15 20 25 30)
                experience   cvals=('Family Friendly' 'Thrill Seeker' 'Middle of the Road')
                other        cvals=('None' 'Arcade' 'Putt-Putt' 'Arcade and Putt-Putt')
                ;
%let class = location price experience other;
%let points  = n=30;
%let model   = location|price|experience|other@2;

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
           ITER=250
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
     multreg
        model = random
        nfullpredictors = 18
        ntestpredictors = 1
        partialcorr = 0 to 1 by 0.05
        ntotal = .
        power = .8;
run;

