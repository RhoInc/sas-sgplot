/*--------------------------------------------------------------------------------

Program: means_over_time.sas

Purpose: Provide a starting place for programmers wanting to produce a means over
         time plot with SGPLOT. Lots of comments are provided. The code is written
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

%let PgmDir = H:\D2G\MeansOverTime;
%let Fig = means_over_time;
libname derive "&PgmDir\Data";



*--------------------------------------------------------------------------------;
*---------- use macro variables to store variable names ----------;
*---------- in case the ADaM variables are not quite perfect as is ----------;
*--------------------------------------------------------------------------------;

%let grpn = trtpn;
%let grpc = trtp;
%let xvar = avisitn;
%let font = Courier New;



*--------------------------------------------------------------------------------;
*---------- calculate n, mean, and stderr for each &grpn*&xvar ----------;
*--------------------------------------------------------------------------------;

proc sort data=derive.adlb out=mot00;
   by &grpn &grpc &xvar;
   where paramcd = "ALT";
run;

proc means data=mot00 noprint;
   var aval;
   by &grpn &grpc &xvar;
   output out=mot10 n=n mean=mean stderr=stderr;
run;



*--------------------------------------------------------------------------------;
*---------- create yaxis label ----------;
*--------------------------------------------------------------------------------;

proc sql noprint;
   select   distinct strip(param) || " +/- SE"
   into     :ylabel
   from     mot00
   ;
quit;

%let ylabel = &ylabel;
%put &=ylabel;



*--------------------------------------------------------------------------------;
*---------- determine xaxis values to display ----------;
*--------------------------------------------------------------------------------;

proc sql noprint;
   select   distinct &xvar
   into     :values separated by " "
   from     mot10
   ;
quit;

%put &=values;

*---------- If you see the following message in your log... ----------;
*---------- NOTE: Some of the tick values have been thinned. ----------;
*---------- ...then you will probably want to overwrite &values. ----------;

%let values = 0 2 4 6 8 12 16 20 24;
%put &=values;



*--------------------------------------------------------------------------------;
*---------- create format for xaxis values ----------;
*--------------------------------------------------------------------------------;

proc format;
   value &xvar                      /* used in sgplot xaxis statement */
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
   from     mot10
   ;
quit;

proc format cntlin=&grpc;
run;



*--------------------------------------------------------------------------------;
*---------- calculate error bar endpoints ----------;
*---------- create new variable for xaxistable ----------;
*---------- format stuff ----------;
*--------------------------------------------------------------------------------;

data mot20;
   set mot10;

   upper = mean + stderr;
   lower = mean - stderr;

   if &xvar in (&values) then       /* only want values where there are ticks */
      xatn = n;
   format xatn xatn.;

   format &grpn &grpc..;
run;



*--------------------------------------------------------------------------------;
*---------- template modifications ----------;
*--------------------------------------------------------------------------------;

*---------- marker and line updates in modstyle ----------;
%modstyle
   (name=motstyle0                  /* do not include "styles." in modstyle */
   ,parent=rtf                      /* do not include "styles." in modstyle */
   ,type=CLM
   ,colors=black black black black
   ,markers=circle square diamond star
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
   style=styles.motstyle
   file="&PgmDir\&Fig..rtf"
   ;

title1;

proc sgplot data=mot20;
   *--- draw the markers and lines ---;
   series y=mean x=&xvar / 
      group=&grpn 
      groupdisplay=cluster          /* spreads the groups out */
      markers                       /* markers added here for legend */
      markerattrs=(size=10px)       /* cannot adjust marker size in style */
      name="series"
      ;
   *--- draw the error bars ---;
   scatter y=mean x=&xvar /
      group=&grpn 
      groupdisplay=cluster          /* spreads the groups out */
      yerrorupper=upper 
      yerrorlower=lower
      markerattrs=(size=0px)        /* hide the scatter-based markers */
      ;
   *--- add the sample sizes ---;
   xaxistable xatn /                /* 9.4 statement */
      class=&grpn
      colorgroup=&grpn
      ;
   *--- cosmetics ---;
   yaxis
      label="&ylabel"
      ;
   xaxis 
      values=(&values) 
      valuesformat=&xvar..          /* 9.4 option */
      label="Weeks"
      ;
   keylegend "series" /
      title="Treatment Group"       /* to remove the title specify title="" */
      noborder
      linelength=15pct              /* 9.4m2 option */
      outerpad=(bottom=10pt)        /* a little space before the xaxistable */
      ;
run;

ods rtf close;
