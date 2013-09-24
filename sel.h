#ifndef SEL_HPP__
#define SEL_HPP__

typedef enum { SELECT_FROM,WHERE,GROUP,ORDER } commEnum;
typedef enum { typeCon,typeComm,typeOpr} nodeEnum;

/* constants */
typedef struct {
   char value[10]; /*value of constant */
} conNodeType;
/* command identifiers */
typedef struct {
   int i ; 
} commNodeType;
typedef struct {
   int oper; /* operator */
   int nops; /* number of operands */
   struct nodeTypeTag *op[1]; /*operands(expandable)*/
} oprNodeType;
typedef struct nodeTypeTag {
   nodeEnum type ; /* type of node */
   /* union must be last entry in nodeType */
   /* because operNodeType may dynamically increase */
   union {
      conNodeType con; /* constants */
      commNodeType comm; /* sql key word */
      oprNodeType opr; /* operator */
   };
} nodeType;

#endif
