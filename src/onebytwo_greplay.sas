*--------------------------------------------------------------------------------;
*--------------------------------------------------------------------------------;
*---------- setup ----------;
*--------------------------------------------------------------------------------;
*--------------------------------------------------------------------------------;

%include "S:\basestat\autocall\rt4init.sas";
%rt4init
   (Tracker=NO
   ,ID=8675309
   );

%let pgmdir = H:\D2G\OutputCapture\OneByTwo;
%let tbl = FIG_TAB;

proc sort data=sashelp.cars out=cars;
   by cylinders;
   where n(cylinders);
run;



*--------------------------------------------------------------------------------;
*---------- create one PNG per plot ----------;
*--------------------------------------------------------------------------------;

*---------- empty WORK.GSEG ----------;
%macro delcat(cat);
 
   %if %sysfunc(cexist(&cat)) %then %do; 

      proc greplay nofs igout=&cat; 
         delete _all_; 
      run;quit; 

   %end; 

%mend delcat; 
    
%delcat(work.gseg);

*---------- setup ----------; 
options 
   nodate 
   nonumber
   orientation=landscape
   ;
goptions reset=all;
ods _all_ close;
ods listing 
   gpath="&pgmdir" 
   image_dpi=300
   ;
ods graphics /
   reset=index 
   height=4in
   width=4in
   noborder
   ;

*---------- left plot ----------;
ods graphics / imagename="greplay_&tbl._left";

proc sgplot data=cars;
   scatter y=enginesize x=horsepower;
run;

*---------- right plot ----------;
ods graphics / imagename="greplay_&tbl._right";

proc sgplot data=cars;
   scatter y=enginesize x=horsepower;
   yaxis type=log;
run;



*--------------------------------------------------------------------------------;
*---------- create one GSLIDE per plot ----------;
*--------------------------------------------------------------------------------;

ods listing;
goptions
   reset=all
   device=png300
   nodisplay
   xmax=4in
   ymax=4in
   ;

goptions iback="&pgmdir/greplay_&tbl._left.png" imagestyle=fit;
proc gslide;
run;quit;

goptions iback="&pgmdir/greplay_&tbl._right.png" imagestyle=fit;
proc gslide;
run;quit;



*--------------------------------------------------------------------------------;
*---------- create template to hold the above GSLIDEs ----------;
*--------------------------------------------------------------------------------;

proc greplay 
      nofs 
      tc=work.tempcat
      ;
   tdef onebytwo
      1/ ulx=0    uly=100
         urx=50   ury=100
         llx=0    lly=0
         lrx=50   lry=0
         color=white
      2/ ulx=50   uly=100
         urx=100  ury=100
         llx=50   lly=0
         lrx=100  lry=0
         color=white
         ;
run;quit;



*--------------------------------------------------------------------------------;
*---------- combine GSLIDEs into one graphic ----------;
*--------------------------------------------------------------------------------;

goptions 
   display
   xmax=8in
   ymax=4in
   ;

ods results off;
ods listing close;
ods rtf file="&pgmdir/greplay_&tbl._pre.rtf";

proc greplay
      igout=work.gseg
      nofs
      tc=work.tempcat
      template=onebytwo
      ;
   treplay 
      1:gslide 
      2:gslide1
      ;
run;quit;

ods rtf close;
ods listing;
ods results on;



*--------------------------------------------------------------------------------;
*---------- finish with RT4 ----------;
*--------------------------------------------------------------------------------;

data dummy;
   x = " ";
run;

%rt4resetDefs;
%let Def1 = COL|1|C|%rt4pic(&pgmdir\greplay_&tbl._pre.rtf)|wid(135);

%RhoTables4
   (Data=dummy
   ,Out=&pgmdir\greplay_&tbl..rtf
   ,Style=Table
   );
