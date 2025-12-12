%{
    #include "y.tab.h"
%}
letter [a-z]
digit [0-9]
seperator "\t"|"\n"|"\r"|" "
%% 
{seperator}+ {}

"#t" {yylval.bval = 1;return BOOL_VAL;}
"#f" {yylval.bval = 0;return BOOL_VAL;}

0|-?[1-9]{digit}* {yylval.ival = atoi(yytext);return NUMBER;} 

"print-num" {return PRINT_NUM;}
"print-bool" {return PRINT_BOOL;}
"and" {return AND;}
"or" {return OR;}
"not" {return NOT;}
"define" {return DEFINE;}
"fun" {return FUN;}
"if" {return IF;}
"mod" {return MOD;}

{letter}({letter}|{digit}|"-")* {yylval.sval = strdup(yytext); return ID;}

[+\-*/\(\)><=] {return yytext[0];}

. {printf("%s error",yytext);}

%% 