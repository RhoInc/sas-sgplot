/*--------------------------------------------------------------------------------

Program: kaplan_meier.sas

Purpose: Provide a starting place for programmers wanting to produce a Kaplan 
         Meier plot with SGPLOT. Lots of comments are provided. The code is written
         for readability.

Notes:
   -  Subtleties/gotchas noted by the use of slash comments. E.g., see the 
      keylegend statement at the very bottom.
   -  Macro variables are used only for variables that appear multiple times, 
      just in case any of the variable name assumptions prove to be incompatible
      with your particular use case.

--------------------------------------------------------------------------------*/



*--------------------------------------------------------------------------------;
*---------- typical macro variables and libname at Rho ----------;
*--------------------------------------------------------------------------------;

%let PgmDir = H:\D2G\KaplanMeier;
%let Fig = kaplan_meier;
libname derive "&PgmDir\Data";



*--------------------------------------------------------------------------------;
*---------- use macro variables to store variable names ----------;
*---------- in case the ADaM variables are not quite perfect as is ----------;
*--------------------------------------------------------------------------------;

%let grpn = trtpn;
%let grpc = trtp;
%let font = Courier New;



*--------------------------------------------------------------------------------;
*---------- determine xaxis values to display ----------;
*--------------------------------------------------------------------------------;

%let values = 0 2 4 6 8 12 16 20 24;
%put &=values;



*--------------------------------------------------------------------------------;
*---------- calculate KM statistics for each &grpn ----------;
*---------- the ATRISK option gets us the xaxistable numbers ----------;
*--------------------------------------------------------------------------------;

proc sort data=derive.adtte out=km00;
   by &grpn &grpc;
   where paramcd = "OS";
run;

ods graphics on;
ods listing close; 

proc lifetest data=km00 plots=(survival(atrisk=&values));
   ods output survivalplot=km10;
   time aval*cnsr(1);
   strata &grpn;
run;



*--------------------------------------------------------------------------------;
*---------- create yaxis label ----------;
*--------------------------------------------------------------------------------;

proc sql noprint;
   select   distinct strip(param) || " Probability"
   into     :ylabel
   from     km00
   ;
quit;

%let ylabel = &ylabel;
%put &=ylabel;



*--------------------------------------------------------------------------------;
*---------- create format for xaxis values ----------;
*--------------------------------------------------------------------------------;

proc format;
   value timefmt                    /* used in sgplot xaxis statement */
   0 = "B/L"
   other = [best.]
   ;
run;



*--------------------------------------------------------------------------------;
*---------- create format for xaxistable ----------;
*--------------------------------------------------------------------------------;

proc format;
   value xatn
   . = " "                          /* do not want dots to show up */
   other = [best.]
   ;
run;



*--------------------------------------------------------------------------------;
*---------- create format for legend entries ----------;
*--------------------------------------------------------------------------------;

proc sql;
   create   table &grpc as
   select   distinct "&grpc" as fmtname, &grpn as start, &grpc as label
   from     km00
   ;
quit;

proc format cntlin=&grpc;
run;



*--------------------------------------------------------------------------------;
*---------- create new variable for xaxistable ----------;
*---------- format stuff ----------;
*--------------------------------------------------------------------------------;

data km20;
   set km10;

   if n(tatrisk) then               /* only want values where there are ticks */
      xatn = atrisk;
   format xatn xatn.;

   format stratumnum &grpc..;
run;



*--------------------------------------------------------------------------------;
*---------- template modifications ----------;
*--------------------------------------------------------------------------------;

*---------- marker and line updates in modstyle ----------;
%modstyle
   (name=kmstyle0                   /* do not include "styles." in modstyle */
   ,parent=rtf                      /* do not include "styles." in modstyle */
   ,type=CLM
   ,colors=black black black black
   );

*---------- font updates in template ----------;
proc template;
   define style styles.motstyle;
      parent=styles.motstyle0;
      class GraphFonts /
         "GraphDataFont"  = ("&font, <MTserif>, <serif>", 7pt)
         "GraphValueFont" = ("&font, <MTserif>, <serif>", 9pt)
         "GraphLabelFont" = ("&font, <MTserif>, <serif>",10pt)
         ;
   end;
run;



*--------------------------------------------------------------------------------;
*---------- sgplot it ----------;
*--------------------------------------------------------------------------------;

options 
   nonumber 
   nodate 
   orientation=portrait
   ;

ods graphics / 
   noborder 
   height=6in 
   width=6in
   outputfmt=png
   ;

ods rtf 
   style=styles.kmstyle
   file="&PgmDir\&Fig..rtf"
   ;

title1;

proc sgplot data=km20;
   *--- draw the survival curves ---;
   step y=survival x=time / 
      group=stratumnum
      name="step"
      ;
   *--- draw censor indicators for censoring symbol legend purposes ---;
   scatter y=censored x=time /
      markerattrs=(symbol=circle)     
      name="censor"
      ;
   *--- draw censor indicators for grouping purposes ---;
   scatter y=censored x=time /
      group=stratumnum 
      markerattrs=(symbol=circle)     
      ;
   *--- add the sample sizes ---;
   xaxistable xatn /                /* 9.4 statement */
      class=stratumnum
      colorgroup=stratumnum
      ;
   *--- cosmetics ---;
   yaxis
      label="&ylabel"
      ;
   xaxis 
      values=(&values) 
      valueshint
      valuesformat=timefmt.         /* 9.4 option */
      label="Weeks"
      ;
   keylegend "step" /
      title="Treatment Group"       /* to remove the title specify title="" */
      noborder
      linelength=15pct              /* 9.4m2 option */
      outerpad=(bottom=10pt)        /* a little space before the xaxistable */
      ;
   keylegend "censor" /             /* censoring legend inside plot */
      location=inside
      position=bottomleft
      ;
run;

ods rtf close;

