/*--------------------------------------------------------------------------------

Program: Forest_Succinct.sas

Purpose: Provide a starting place for programmers wanting to produce a subgrouped 
         forest plot with SGPLOT. Lots of comments are provided. The code is 
         written for readability.

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

/*%let PgmDir = H:\D2G\ForestPlot;*/
%let PgmDir = T:\Biostat\srosanba\ForestPlot;
%let Fig = Forest_Succinct;
libname derive "&PgmDir\Data";



/*--------------------------------------------------------------------------------
Because I cannot possibly predict the exact set of statistics or derivation 
methods that you are going to want to use in your forest plot, this sample 
program begins with pre-summarized data. 
--------------------------------------------------------------------------------*/



*--------------------------------------------------------------------------------;
*---------- formats ----------;
*--------------------------------------------------------------------------------;

proc format;
   value notdot
      . = ' '
      other = [best.]
      ;
   value $txt
      "T" = "Therapy Better (*ESC*){Unicode '2192'x}"  /* 9.4m3 */
      "P" = "(*ESC*){Unicode '2190'x} PCI Better"      /* 9.4m3 */
      ;                             
run;



*--------------------------------------------------------------------------------;
*---------- data manipulation ----------;
*--------------------------------------------------------------------------------;

data stats10;
   set derive.stats00;

   *--- for banding ---;
   retain levelcount 0;
   if level = 1 then levelcount + 1;
   if mod(levelcount,2) = 0 then
      band = record;

   *--- for indentation ---;
   if level=1 then 
      indentWt = 0;
   else
      indentWt = 1;

   *--- missing values appear as spaces ---;
   format pcigroup group pvalue notdot.;
run;



*--------------------------------------------------------------------------------;
*---------- hazard ratio interpretation text ----------;
*--------------------------------------------------------------------------------;

data hazratinterp;
   set stats20 (keep=record) end=eof;
   if eof then do;
      record + 1;
      x1 = 0.7;
      text = "P";
      output;
      x1 = 1.4;
      text = "T";
      output;
   end;
run;

data stats30;
   set stats20 hazratinterp;
   format text $txt.;
run;



*--------------------------------------------------------------------------------;
*---------- discrete attribute map for bold text ----------;
*--------------------------------------------------------------------------------;

data attrmap;
   input id $ value textcolor $ textsize textweight $;
   datalines;
text 1 black 7 bold
text 2 black 5 normal
;
run;



*--------------------------------------------------------------------------------;
*---------- template modifications ----------;
*--------------------------------------------------------------------------------;

proc template;
   define style styles.forest;
      parent=styles.rtf;
      class GraphFonts /
         "GraphDataFont"  = ("Courier New", 7pt)
         "GraphValueFont" = ("Courier New", 8pt)
         "GraphLabelFont" = ("Courier New", 8pt)
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
   outputfmt=png
   ;

ods rtf 
   style=styles.forest
   file="&PgmDir\&Fig..rtf"
   ;

title1;

proc sgplot data=stats40 
      dattrmap=attrmap 
      noautolegend 
      nocycleattrs
      nowall
      ;
   *--- remove box around plot ---;
   styleattrs 
      axisextent=data
      ;
   *--- banding and reference line ---;
   refline band / 
      lineattrs=(thickness=26 color=cxf0f0f7)
      ;
   refline 1 /
      axis=x
      ;
   *--- estimates and CIs ---;
   scatter y=record x=mean / 
      markerattrs=(symbol=squarefilled)
      ;
   highlow y=record low=low high=high;
   *--- adding yaxis table at left ---;
   yaxistable subgroup / 
      location=inside
      position=left
      textgroup=level
      textgroupid=text
      indentweight=indentWt         /* 9.4m3 */
      ;
   *--- a second yaxis table at left ---;
   yaxistable countpct /
      location=inside
      position=left
      ;
   *--- adding yaxis table at right ---;
   yaxistable pcigroup group pvalue /
      location=inside
      position=right
      ;
   *--- primary axes ---;
   yaxis
      reverse
      display=none
      offsetmin=0
      colorbands=odd
      colorbandsattrs=(transparency=1) 
      ;
   xaxis 
      display=(nolabel) 
      ;
   *--- text above xaxis ---;
   text x=x1 y=record text=text / 
      position=bottom 
      contributeoffsets=none 
      strip
      ;
   *--- text above x2axis ---;
   scatter y=record x=mean / 
      markerattrs=(size=0) 
      x2axis
      ;
   x2axis 
      label='Hazard Ratio' 
      display=(noline noticks novalues) 
      ;
run;

ods rtf close;

