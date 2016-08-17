/*--------------------------------------------------------------------------------

Program: paneled_box_plot.sas

Purpose: Provide a starting place for programmers wanting to produce a paneled
         box plot with SGPLOT. Lots of comments are provided. The code is written
         for readability.

Notes:
   -  Subtleties/gotchas noted by the use of slash comments. E.g., see the 
      colaxis statement at the very bottom.
   -  Macro variables are used only for variables that appear multiple times, 
      just in case any of the variable name assumptions prove to be incompatible
      with your particular use case.

--------------------------------------------------------------------------------*/



*--------------------------------------------------------------------------------;
*---------- typical macro variables and libname at Rho ----------;
*--------------------------------------------------------------------------------;

%let PgmDir = H:\D2G\PaneledBoxPlot;
%let Fig = paneled_box_plot;
libname derive "&PgmDir\Data";



*--------------------------------------------------------------------------------;
*---------- use macro variables to store variable names ----------;
*---------- in case the ADaM variables are not quite perfect as is ----------;
*--------------------------------------------------------------------------------;

%let panelbyn = avisitn;
%let panelbyc = avisit;
%let grpn = trtpn;
%let grpc = trtp;
%let font = Courier New;



*--------------------------------------------------------------------------------;
*---------- select data to display ----------;
*--------------------------------------------------------------------------------;

proc sort data=derive.adlb out=pbp00;
   by &panelbyn &panelbyc &grpn &grpc;
   where paramcd = "ALT";
run;



*--------------------------------------------------------------------------------;
*---------- create yaxis label ----------;
*--------------------------------------------------------------------------------;

proc sql noprint;
   select   distinct strip(param)
   into     :ylabel
   from     pbp00
   ;
quit;

%let ylabel = &ylabel;
%put &=ylabel;



*--------------------------------------------------------------------------------;
*---------- create format for panel headers ----------;
*--------------------------------------------------------------------------------;

proc sql;
   create   table &panelbyn as
   select   distinct "&panelbyn" as fmtname, 
            &panelbyn as start, 
            &panelbyc as label
   from     pbp00
   ;
quit;

proc format cntlin=&panelbyn;
run;

proc sql noprint;
   alter    table pbp00
   modify   &panelbyn format=&panelbyn..
   ;
quit;



*--------------------------------------------------------------------------------;
*---------- create format for column axis ----------;
*--------------------------------------------------------------------------------;

proc sql;
   create   table &grpn as
   select   distinct "&grpn" as fmtname, &grpn as start, &grpc as label
   from     pbp00
   ;
quit;

proc format cntlin=&grpn;
run;

proc sql noprint;
   alter    table pbp00
   modify   &grpn format=&grpn..
   ;
quit;



*--------------------------------------------------------------------------------;
*---------- template modifications ----------;
*--------------------------------------------------------------------------------;

proc template;
   define style styles.pbpstyle;
      parent=styles.rtf;
      class GraphFonts /
         "GraphDataFont"  = ("&font", 7pt)
         "GraphValueFont" = ("&font", 9pt)
         "GraphLabelFont" = ("&font",10pt)
         ;
   end;
run;



*--------------------------------------------------------------------------------;
*---------- sgplot it ----------;
*--------------------------------------------------------------------------------;

options 
   nonumber 
   nodate 
   orientation=landscape
   ;

ods graphics / 
   noborder 
   height=4in 
   width=8in
   ;

ods rtf 
   style=styles.pbpstyle
   file="&PgmDir\&Fig..rtf"
   ;

title1;

proc sgpanel data=pbp00;
   *--- panel structure ---;
   panelby &panelbyn / 
      rows=2
      columns=5
      novarname
      ;
   *--- draw box plots ---;
   vbox aval /
      category=&grpn
      fillattrs=(color=ltgray)
      ;
   *--- cosmetics ---;
   rowaxis
      label="&ylabel"
      ;
   colaxis
      label="Treatment"
      fitpolicy=stagger
      ;
run;

ods rtf close;

