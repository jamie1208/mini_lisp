%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    void yyerror(const char *msg);
    int yylex(void);

    void type_error(char*s ){
        printf("Type error! %s\n",s);
        exit(0);
    }

    //define node type
    typedef enum{
        AST_INT, AST_BOOL, AST_VAR,
        
        //num-op
        AST_PLUS,AST_MINUS, AST_MULTIPLY, AST_DIVIDE, AST_MODULUS, 
        AST_GREATER, AST_SMALLEER, AST_EQUAL,

        //logical-op
        AST_AND, AST_OR, AST_NOT,

        //define
        AST_DEFINE,

        //print_stmt
        AST_PRINT_NUM,AST_PRINT_BOOL,

        //function
        AST_IF, AST_FUN, AST_CALL


    }ASTtype;

    //define ASTNode
    typedef struct ASTNode{
        ASTtype type;
        union{
            int ival;
            int bval;
            char* name;

            struct{struct ASTNode* a ; struct ASTNode* b;}bin; //num-op+and+or
            struct{struct ASTNode* a;}unary; //not
            struct{struct ASTNode* cond; struct ASTNode* tbr; struct ASTNode* ebr;}iff; //if
            struct{char* var; struct ASTNode* rhs;}def; //define
            struct{struct ASTNode* value;}p_stmt; //print_stmts;

            struct{char** idlist; struct ASTNode* body; int id_count;}fun; //fun
            struct{struct ArgList* arglist; struct ASTNode* fn; }fun_call; //fun call
        }u;
    }ASTNode;

    //arglist-存多參數
    typedef struct ArgList{
        ASTNode** args;
        int count;
    }ArgList;
    //創建新的Arglist
    ArgList* alist_new(){
        ArgList* a = malloc(sizeof(ArgList));
        a->count = 0;
        a->args = NULL;
        return a;
    }
    //append to arglist
    ArgList* alist_push(ArgList* a,ASTNode* n){
        a->count++;
        a->args = realloc(a->args,a->count*sizeof(ASTNode*));
        a->args[a->count - 1] = n;
        return a;
    }

    //make node
    ASTNode* make_var_node(char* s){
        ASTNode* n = malloc(sizeof(ASTNode));
        n->type = AST_VAR;
        n->u.name = strdup(s);
        return n;
    }
    ASTNode* make_bool_node(int b){
        ASTNode* n = malloc(sizeof(ASTNode));
        n->type = AST_BOOL;
        n->u.bval = b;
        return n;
    }
    ASTNode* make_int_node(int i){
        ASTNode* n = malloc(sizeof(ASTNode));
        n->type = AST_INT;
        n->u.ival = i;
        return n;
    }
    ASTNode* make_bin_node(ASTtype type,ASTNode* a,ASTNode* b){
        ASTNode* n = malloc(sizeof(ASTNode));
        n->type = type;
        n->u.bin.a = a;
        n->u.bin.b = b;
        return n;
    }
    ASTNode* make_unary_node(ASTtype type,ASTNode* a){
        ASTNode* n = malloc(sizeof(ASTNode));
        n->type = type;
        n->u.unary.a = a;
        return n;
    }
    ASTNode* make_define(ASTNode* name, ASTNode* value){
        ASTNode* n = malloc(sizeof(ASTNode));
        n->type = AST_DEFINE;
        n->u.def.var = strdup(name->u.name);
        n->u.def.rhs = value;
        return n;       
    }
    ASTNode* make_pstmt_node(ASTtype type,ASTNode* value){
        ASTNode* n = malloc(sizeof(ASTNode));
        n->type = type;
        n->u.p_stmt.value = value;
        return n;       
    }
    ASTNode* make_if_node(ASTNode* c,ASTNode* t, ASTNode* e){
        ASTNode* n = malloc(sizeof(ASTNode));
        n->type = AST_IF;
        n->u.iff.cond = c;
        n->u.iff.tbr = t;
        n->u.iff.ebr = e;
        return n;         
    }
    ASTNode* make_fun_node(char** idlist, ASTNode* body, int count){
        ASTNode* n = malloc(sizeof(ASTNode));
        n->type = AST_FUN;
        n->u.fun.idlist = idlist;
        n->u.fun.body = body;
        n->u.fun.id_count = count;
        return n;         
    }
    ASTNode* make_fun_call_node(ASTNode* fn,ArgList* arglist){
        ASTNode* n = malloc(sizeof(ASTNode));
        n->type = AST_CALL;
        n->u.fun_call.arglist = arglist;
        n->u.fun_call.fn = fn;
        return n;         
    }

    //function
    typedef struct Func{
        char** params; //參數id
        int params_count;
        struct ASTNode* body;
        struct Env *env;
    }Func;
    //make fun
    Func* makefun(char** p,int c, ASTNode* b,struct Env* e){
        Func* f = malloc(sizeof(Func));
        f->params_count = c;
        f->body = b;
        f->env = e;
        if(c>0){
            f->params = malloc(c*sizeof(char*));
            for(int i = 0;i<c;i++){
                f->params[i] =strdup(p[i]);
            }
        }else{f->params = NULL;}
        return f;
    }

    //id_list
    typedef struct IdList{
        char** ilist;
        int count;
    }IdList;

    //values
    typedef enum{VAL_INT,VAL_BOOL,VAL_FUN}ValKind;
    typedef struct Value{
        ValKind tag;
        union{
            int ival;
            int bval;
            struct Func* fval;
        }u;
    }Value;

    //某層的variable
    typedef struct Binding{
        char* name;
        Value* val;
        struct Binding* next;
    }Binding;
    //scope
    typedef struct Env{
        Binding* vars; //這一層的所有變數
        struct Env* parent; //上一層
    }Env;
    //make env
    Env* make_env(Env* parent){
        Env* e = malloc(sizeof(Env));
        e->vars = NULL;
        e->parent = parent;
        return e;
    }
    //make binding
    void make_binding(Env* e,char* name, Value* val){
        Binding* b = malloc(sizeof(Binding));
        b->name = strdup(name);
        b->val = val;
        b->next = e->vars;
        e->vars = b;
    }
    //lookup
    Value* lookup(Env* env,char* name){
        for(Env* e = env;e!=NULL;e = e->parent){
            for(Binding* b = e->vars ; b!=NULL ; b = b->next){
                if(strcmp(b->name,name) == 0){
                    return b->val;
                }
            }
        }
        return NULL;
    }

    //check_int
    int check_int(Value* v){
        return v->tag == VAL_INT ? 1 : 0;
    }
    //check_bool
    int check_bool(Value* v){
        return v->tag == VAL_BOOL ? 1 : 0;
    }

    // make value
    Value* make_int_value(int i){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_INT;
        v->u.ival = i;
        return v;
    }
    Value* make_bool_value(int b){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_BOOL;
        v->u.bval = b;
        return v;
    }
    Value* make_fun_value(Func* f){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_FUN;
        v->u.fval = f;
        return v;        
    }
    Value* int_plus(int a, int b){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_INT;
        v->u.ival = a+b;
        return v;
    }
    Value* int_minus(int a, int b){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_INT;
        v->u.ival = a-b;
        return v;
    }
    Value* int_mul(int a, int b){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_INT;
        v->u.ival = a*b;
        return v;
    }
    Value* int_div(int a, int b){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_INT;
        v->u.ival = a/b;
        return v;
    }
    Value* int_mod(int a, int b){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_INT;
        v->u.ival = a%b;
        return v;
    }
    Value* int_gr(int a, int b){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_BOOL;
        v->u.bval = a>b?1:0;
        return v;
    }
    Value* int_sm(int a, int b){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_BOOL;
        v->u.bval = a<b?1:0;
        return v;
    }
    Value* int_eq(int a, int b){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_BOOL;
        v->u.bval = a==b?1:0;
        return v;
    }
    Value* bool_and(int a, int b){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_BOOL;
        v->u.bval = a&&b?1:0;
        return v;
    }
    Value* bool_or(int a, int b){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_BOOL;
        v->u.bval = a||b?1:0;
        return v;
    }
    Value* bool_not(int a){
        Value* v = malloc(sizeof(Value));
        v->tag = VAL_BOOL;
        v->u.bval = !a;
        return v;
    }

    //eval
    Value* eval(ASTNode* n,Env* e){
        switch(n->type){
            case AST_INT : return make_int_value(n->u.ival);
            case AST_BOOL : return make_bool_value(n->u.bval);
            case AST_VAR : {
                Value* v = lookup(e,n->u.name);
                if(v == NULL){printf("undefined variable: %s\n", n->u.name);exit(0);}
                return v;
            }
            case AST_PLUS : {
                Value* a = eval(n->u.bin.a,e);
                Value* b = eval(n->u.bin.b,e);
                if(!check_int(a) || !check_int(b)) {type_error("Expect number bet get boolean\n");}
                return int_plus(a->u.ival,b->u.ival);
            }
            case AST_MINUS : {
                Value* a = eval(n->u.bin.a,e);
                Value* b = eval(n->u.bin.b,e);
                if(!check_int(a) || !check_int(b)) type_error("Expect number bet get boolean\n");
                return int_minus(a->u.ival,b->u.ival);
            }
            case AST_MULTIPLY : {
                Value* a = eval(n->u.bin.a,e);
                Value* b = eval(n->u.bin.b,e);
                if(!check_int(a) || !check_int(b)) type_error("Expect number bet get boolean\n");
                return int_mul(a->u.ival,b->u.ival);
            }
            case AST_DIVIDE : {
                Value* a = eval(n->u.bin.a,e);
                Value* b = eval(n->u.bin.b,e);
                if(!check_int(a) || !check_int(b)) type_error("Expect number bet get boolean\n");
                return int_div(a->u.ival,b->u.ival);
            }
            case AST_MODULUS : {
                Value* a = eval(n->u.bin.a,e);
                Value* b = eval(n->u.bin.b,e);
                if(!check_int(a) || !check_int(b)) type_error("Expect number bet get boolean\n");
                return int_mod(a->u.ival,b->u.ival);
            }
            case AST_GREATER : {
                Value* a = eval(n->u.bin.a,e);
                Value* b = eval(n->u.bin.b,e);
                if(!check_int(a) || !check_int(b)) type_error("Expect number bet get boolean\n");
                return int_gr(a->u.ival,b->u.ival);
            }
            case AST_SMALLEER : {
                Value* a = eval(n->u.bin.a,e);
                Value* b = eval(n->u.bin.b,e);
                if(!check_int(a) || !check_int(b)) type_error("Expect number bet get boolean\n");
                return int_sm(a->u.ival,b->u.ival);
            }
            case AST_EQUAL : {
                Value* a = eval(n->u.bin.a,e);
                Value* b = eval(n->u.bin.b,e);
                if(!check_int(a) || !check_int(b)) type_error("Expect number bet get boolean\n");
                return int_eq(a->u.ival,b->u.ival);
            }
            case AST_AND:{
                Value* a = eval(n->u.bin.a,e);
                Value* b = eval(n->u.bin.b,e);
                if(!check_bool(a) || !check_bool(b)) type_error("Expect boolean bet get number\n");
                return bool_and(a->u.bval,b->u.bval);
            }
            case AST_OR:{
                Value* a = eval(n->u.bin.a,e);
                Value* b = eval(n->u.bin.b,e);
                if(!check_bool(a) || !check_bool(b)) type_error("Expect boolean bet get number\n");
                return bool_or(a->u.bval,b->u.bval);                
            }
            case AST_NOT:{
                Value* a = eval(n->u.unary.a,e);
                if(!check_bool(a)) type_error("Expect boolean bet get number\n");
                return bool_not(a->u.bval);                
            }
            case AST_DEFINE:{
                Value* v = eval(n->u.def.rhs,e);
                make_binding(e,n->u.def.var,v);
                return v;
            }
            case AST_PRINT_NUM:{
                Value* v = eval(n->u.p_stmt.value,e);
                if(!check_int(v)){type_error("Expect number bet get boolean\n");}
                else{
                    printf("%d\n",v->u.ival);
                }
                return v;
            }
            case AST_PRINT_BOOL:{
                Value* v = eval(n->u.p_stmt.value,e);
                if(!check_bool(v)){type_error("Expect boolean bet get number\n");}
                else{
                    if(v->u.bval){printf("#t\n");}
                    else{printf("#f\n");}
                }
                return v;
            }
            case AST_IF:{
                Value* cond = eval(n->u.iff.cond,e);
                if(!check_bool(cond)){type_error("Expect boolean bet get number\n");}
                if(cond->u.bval){return eval(n->u.iff.tbr,e);}
                else{return eval(n->u.iff.ebr,e);;}
            }
            case AST_FUN:{
                Func* f = makefun(n->u.fun.idlist,n->u.fun.id_count,n->u.fun.body,e);
                return make_fun_value(f);
            }
            case AST_CALL:{
                Value* v = eval(n->u.fun_call.fn,e);
                Func* f = v->u.fval;
                if(f->params_count != n->u.fun_call.arglist->count){
                    printf("arg數量不匹配\n");
                }
                Env* new_e = make_env(f->env);
                for(int i=0;i<f->params_count;i++){
                    char* name = f->params[i];
                    ASTNode* node = n->u.fun_call.arglist->args[i];
                    Value* value = eval(node, e);
                    make_binding(new_e,name,value);
                }
                return eval(f->body,new_e);
            }
        }
    }

    //全域變數
    Env* global_env;
    //目前scope
    Env* current_env;
%}
%union{
    int bval;
    int ival;
    struct ASTNode* node;
    struct ArgList* alist;
    char* sval;
    struct IdList* idlist;

    
}
%token DEFINE FUN IF AND OR NOT MOD PRINT_NUM PRINT_BOOL
%token <ival >NUMBER 
%token <sval> ID
%token <bval> BOOL_VAL

%type <node> exp num_op plus minus multiply divide modulus greater smaller equal
logical_op and_op or_op not_op def_stmt stmt print_stmt variable if_exp text_exp 
than_exp else_exp fun_exp fun_body param fun_name fun_call
%type <alist> exp_list param_list
%type <idlist> id_list fun_ids

%%
program : program stmt {eval($2,current_env);}
        |
        ;
stmt : exp {$$ = $1;}
     | print_stmt {$$ = $1;}
     | def_stmt {$$ = $1;}
     ;
print_stmt : '(' PRINT_NUM exp ')' {
                $$ = make_pstmt_node(AST_PRINT_NUM,$3)
            }
           | '(' PRINT_BOOL exp ')' {
                $$ = make_pstmt_node(AST_PRINT_BOOL,$3)
            }
           ; 
exp : BOOL_VAL {$$ = make_bool_node($1);}
    | NUMBER {$$ = make_int_node($1);}
    | num_op {$$ = $1;}
    | logical_op {$$ = $1;}
    | variable {$$ = $1;}
    | if_exp{$$ = $1;}
    | fun_exp{$$ = $1;}
    | fun_call{$$ = $1;}
    ;
num_op : plus {$$=$1;}
       | minus {$$=$1;}
       | multiply {$$=$1;}
       | divide {$$=$1;}
       | modulus {$$=$1;}
       | greater {$$=$1;}
       | smaller {$$=$1;}
       | equal{$$=$1;}
       ;
plus : '(' '+' exp exp_list ')'
    {
        ASTNode* t = $3;
        for (int i=0;i<$4->count;i++){
            t = make_bin_node(AST_PLUS,t,$4->args[i]);
        }
        $$ = t;
    }   
     ;
minus : '(' '-' exp exp ')'
        {
            $$ = make_bin_node(AST_MINUS,$3,$4);
        }   
      ;
multiply : '(' '*' exp exp_list ')'
         {
            ASTNode* t = $3;
            for (int i=0;i<$4->count;i++){
                t = make_bin_node(AST_MULTIPLY,t,$4->args[i]);
            }
            $$ = t;
         }   
         ;
divide : '(' '/' exp exp ')'
       {
            $$ = make_bin_node(AST_DIVIDE,$3,$4);
       }   
       ;
modulus : '(' MOD exp exp ')'
        {
            $$ = make_bin_node(AST_MODULUS,$3,$4);
        }   
        ;
greater : '(' '>' exp exp ')'
        {
            $$ = make_bin_node(AST_GREATER,$3,$4);
        }   
        ;
smaller : '(' '<' exp exp ')'
        {
            $$ = make_bin_node(AST_SMALLEER,$3,$4);
        }
        ;
equal : '(' '=' exp exp_list ')'
        {
            ASTNode* t = $3;
            for (int i=0;i<$4->count;i++){
                t = make_bin_node(AST_EQUAL,t,$4->args[i]);
            }
            $$ = t;
        }
        ;
logical_op : and_op {$$ = $1;}
           | or_op {$$ = $1;}
           | not_op {$$ = $1;}
           ;
and_op : '(' AND exp exp_list ')'
        {
            ASTNode* t = $3;
            for (int i=0;i<$4->count;i++){
                t = make_bin_node(AST_AND,t,$4->args[i]);
            }
            $$ = t;
        }
        ;
or_op : '(' OR exp exp_list ')'
        {
            ASTNode* t = $3;
            for (int i=0;i<$4->count;i++){
                t = make_bin_node(AST_OR,t,$4->args[i]);
            }
            $$ = t;
        }
    ;
not_op : '(' NOT exp ')'
        {
            $$ = make_unary_node(AST_NOT,$3);
        }
        ;
exp_list : exp {$$ = alist_new();$$ = alist_push($$,$1);}
        | exp_list exp 
        {
            $$ = alist_push($1,$2);
        }
        ;
def_stmt : '(' DEFINE variable exp ')'
        {
            $$ = make_define($3,$4);
        }
         ;
variable : ID {$$ = make_var_node($1);}
         ;
if_exp : '(' IF text_exp than_exp else_exp ')'
        {
            $$ = make_if_node($3,$4,$5);
        }
       ;
text_exp : exp {$$ = $1;}
         ;
than_exp : exp {$$ = $1;}
         ;
else_exp : exp {$$ = $1;}
         ;
fun_call : '(' fun_exp param_list ')'  
         {
            $$ = make_fun_call_node($2,$3);
         }
         | '(' fun_name param_list ')'
         {
            $$ = make_fun_call_node($2,$3);
         }
         ;
fun_exp : '(' FUN fun_ids fun_body ')' 
        {   
            $$ = make_fun_node($3->ilist,$4,$3->count);
        }
        ;
fun_ids : '(' id_list ')' {$$ = $2;}
        ;
id_list : {$$ = malloc(sizeof(IdList));$$->count = 0;$$->ilist = NULL;}
        | id_list ID
        {
            $1->count = $1->count+1;
            $1->ilist = realloc($1->ilist,$1->count*sizeof(char*));
            $1->ilist[$1->count-1] = strdup($2);
            $$ = $1;
        }
        ;
fun_body : exp {$$ = $1;}
         ;
param : exp {$$ = $1;}
      ;
param_list :  {$$ = malloc(sizeof(ArgList));$$->count = 0;$$->args = NULL;}
      | param_list param
      {
        $1->count ++;
        $1->args = realloc($1->args,$1->count*sizeof(ASTNode*));
        $1->args[$1->count - 1] = $2;
        $$ = $1;
      }
      ;
fun_name : ID {$$ = make_var_node($1);}
         ;
%%
void yyerror(const char*msg){
    fprintf(stderr,"%s\n",msg);
}
int main(int argc,char *argv[]){
    global_env = make_env(NULL);
    current_env = global_env;
    yyparse();
    return(0);
}