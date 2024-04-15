grammar PL;

@header {
import backend.*;
}

@members {
    void printMessage(String message) {
        System.out.println(message);
    }
    
    void printStrings(String... strings){
        for (String s : strings) {
            System.out.println(s);
        }
    }
    
    void printExprDetails(java.util.List<backend.Expr> exprList) {
        System.out.println("Printing expressions:");
        for (backend.Expr expr : exprList) {
            if (expr != null) {
                System.out.println(expr.toString());
            } else {
                System.out.println("Null expression encountered.");
            }
        }
    }

}
//   a=expr OP b=expr  { $value = update(1, $a.value, $b.value, $OP.text);  }


program returns [Expr expr]: 
    {List<Expr> statements = new ArrayList<Expr>();}
    
    (statement 
        {
            statements.add($statement.exprValue);
        }
    )+ EOF
    
    {
        // TODO: Print List<Expr> statements
        // ========== START - statements where ForLoop containing program does not execute=============
        //printExprDetails(statements);
        $expr = new Block(statements);
        
        
        //printMessage(".g4: Program Block created");
         // ========== END - statemenets where ForLoop containing program does not execute=============
    }  // Evaluates all statements
    ;

statement returns [Expr exprValue]
    : assignment (';')?             {$exprValue = $assignment.exprValue;}
    | expression (';')?             {$exprValue = $expression.exprValue;}
    | print      (';')?             {$exprValue = $print.printResult;}
    | loop                          {$exprValue = $loop.loopResult;}
    | funDef                        {$exprValue = $funDef.funcResult;}
    | ifelse                        {$exprValue = $ifelse.ifelseExpr;}
    | listMethods                   {$exprValue = $listMethods.exprValue;}
    ;

// Store Data object of evaluated expression into symbolTable
assignment returns [Expr exprValue]
    : ID '=' expression {
        $exprValue = new Assign($ID.text, $expression.exprValue);
    }
    | ID '[' index=NUMERIC ']' '=' value=expression {
        $exprValue = new ListModify($ID.text, $index.text, $value.exprValue);
    }
    ;

// exprValue is Expression object
expression returns [Expr exprValue]
    : '(' expression ')'                       { $exprValue = $expression.exprValue;}                                         // Parenthesis
    | e1=expression '++' e2=expression         { $exprValue = new Concatenate($e1.exprValue, $e2.exprValue); }                // String concatenation
    | e1=expression '+' e2=expression          { $exprValue = new Arithmetics(Operator.Add, $e1.exprValue, $e2.exprValue); }  // Add
    | e1=expression '-' e2=expression          { $exprValue = new Arithmetics(Operator.Sub, $e1.exprValue, $e2.exprValue); }  // Subtract
    | e1=expression '*' e2=expression          { $exprValue = new Arithmetics(Operator.Mul, $e1.exprValue, $e2.exprValue); }  // Multiply (String or ints)
    | e1=expression '/' e2=expression          { $exprValue = new Arithmetics(Operator.Div, $e1.exprValue, $e2.exprValue); }  // Division
    | e1 = expression COMPARISON e2=expression { $exprValue = new Compare(ExprUtils.convertToComparator($COMPARISON.text), $e1.exprValue, $e2.exprValue); }   // Boolean comparison
    | ID '(' argList ')'                       { $exprValue = new Invoke($ID.text, $argList.args); }                          // Function call
    | ID                                       { $exprValue = new Deref($ID.text,null); }                                     // Variable dereference
    | ID '[' NUMERIC ']'                       { $exprValue = new Deref($ID.text, $NUMERIC.text); }                           // List variable dereference with single index
    | ID '[' SLICE ']'                         { $exprValue = new Deref($ID.text, $SLICE.text);}                              // List variable dereference with slicing (inclusive) using the NUMERIC token
    | NUMERIC                                  { $exprValue = new IntLiteral($NUMERIC.text); }                                // Number literal
    | STRING                                   { $exprValue = new StringLiteral($STRING.text); }                              // String literal 
    | BOOLEAN                                  { $exprValue = new BooleanLiteral($BOOLEAN.text); }                            // Boolean literal
    | c=collection                             { $exprValue = $c.exprValue; } 
    ;



// This rule parses the print statement and constructs a Print expression
print returns [Expr printResult]
    : 'print' '(' expression ')' { $printResult = new Print($expression.exprValue); }
    ;
    
// Define the rule for function definition
funDef returns [Expr funcResult]
    : { 
        List<Expr> functionStatements = new ArrayList<Expr>();
      }
      'function' funcName=ID '(' listOfParams=params ')' '{'
        (funcState=statement {functionStatements.add($funcState.exprValue);})*
      '}'
      {
          Block newBlock = new Block(functionStatements);
          $funcResult = new Declare($funcName.text, $listOfParams.paramList, new Block(functionStatements));
      }
    ;
    

/*=========================== FLOW CONTROL ==================================== */


// Define the rule for a loop expression
loop returns [Expr loopResult]
    // **** For Loop with numeric range ****
    : {
        List<Expr> loopStatements = new ArrayList<Expr>();
    }
    'for' '(' iterator=ID 'in' first=NUMERIC RANGE last=NUMERIC ')' '{'
        (loopState=statement {
            loopStatements.add($loopState.exprValue);
        })*
    '}'
    {
        $loopResult = new ForLoop($iterator.text, $first.text, $last.text, null, new Block(loopStatements));
    }
    // **** For Loop with collection ****
    | {
        List<Expr> loopStatements = new ArrayList<Expr>();
    }
    'for' '(' iterator=ID 'in' iterable=expression ')' '{'
        (loopState=statement {
            loopStatements.add($loopState.exprValue);
        })*
    '}'
    {
        $loopResult = new ForLoop($iterator.text, null, null, $iterable.exprValue, new Block(loopStatements));
    }
    ;


// String list symbols bound to values at time of function invocation. Symbols in function scope
params returns [List<String> paramList]
    : { $paramList = new ArrayList<>(); } // Initialize the list
      (firstId=ID { $paramList.add($firstId.text); } // Capture the first ID and add to the list
      (',' nextId=ID { $paramList.add($nextId.text); })* // Capture subsequent IDs separated by commas
      )?
    ;
    
argList returns [List<Expr> args]
    : { $args = new ArrayList<>(); } // Initialize the list
      firstArg=expression  { $args.add($firstArg.exprValue); } // Add the first argument
      (',' nextArg=expression { $args.add($nextArg.exprValue); })* //Add subsequent arguments
    ;
    

ifelse returns [Expr ifelseExpr]
    : { 
        List<Expr> trueStatements = new ArrayList<Expr>();
        List<Expr> falseStatements = new ArrayList<Expr>();
      }
    'if' '(' cond=expression ')' '{'
        (trueState=statement {trueStatements.add($trueState.exprValue);})*
    '}' 'else' '{'
        (falseState=statement {falseStatements.add($falseState.exprValue);})*
    '}'
    {
        $ifelseExpr = new Ifelse($cond.exprValue, new Block(trueStatements), new Block(falseStatements));
    }
    ;
    
    
    
/*=========================== AGGREGATE DATA TYPES ==================================== */


collection returns [Expr exprValue]
    : list                                     { $exprValue = $list.exprValue;}                                               // List inside brackets
    | listAccess                               { $exprValue = $listAccess.exprValue;}                                         // List index access or slice
    ;    



list returns [Expr exprValue]
    :
      '[' elements=exprList ']'
        { 
        //printMessage("list: creating list with " + $elements.listValues.size() + " elements.");
        //printMessage("list: Type of elements object returned by exprList: " + $elements.listValues.getClass().getSimpleName());

        // Debugging: Print each element's value and check for null
        boolean hasNull = false;
        for (Expr expr : $elements.listValues) {
            if (expr == null) {
                printMessage("list: Null element found in list");
                hasNull = true;
            } else {
                //printMessage("list: list element - " + expr.toString() + " [Type: " + expr.getClass().getSimpleName() + "]");
            }
        }
        if (!hasNull) {
            $exprValue = new ListExpr($elements.listValues); 
            if ($exprValue != null) {
                //printMessage("list: ListExpr created successfully: " + $exprValue);
            } else {
                //printMessage("list: ListExpr creation failed, object is null");
            }
        } else {
            //printMessage("list: Null detected in elements, cannot create ListExpr");
            $exprValue = null; // Handle null scenario appropriately
        }
      }
    ;


// List of comma separated values contained with '[]' brackets
// List initialization values
exprList returns [List<Expr> listValues]
    : 
    first=expression 
      { 
        $listValues = new ArrayList<Expr>(); // Initialize the list
        $listValues.add($first.exprValue);   // Add the first parsed expression to the list
        //System.out.println("exprList: Added first expression to list: " + $first.exprValue);
      }
      (',' next=expression 
      { 
        $listValues.add($next.exprValue);   // Add each subsequent parsed expression to the list
        //System.out.println("exprList: Added expression to list: " + $next.exprValue);
      })*
    ;

// Returns ListAccessor Expr that evaluates to ListData object
// Can access list values using single index or slice
listAccess returns [Expr exprValue]
    : ID '[' NUMERIC ']' {
        // Handling single index access
        $exprValue = new ListAccessor($ID.text, $NUMERIC.text);
    }
    | ID '[' SLICE ']' {
        // Handling slicing access
        $exprValue = new ListAccessor($ID.text, $SLICE.text);
    }
    ;

listMethods returns [Expr exprValue]
    : ID '.' 'append' '(' expr=expression ')' { $exprValue = new ListOperation($ID.text, "append", $expr.exprValue); }
    | ID '.' 'extend' '(' expr=expression ')' { $exprValue = new ListOperation($ID.text, "extend", $expr.exprValue); }
    | ID '.' 'remove' '(' expr=expression ')' { $exprValue = new ListOperation($ID.text, "remove", $expr.exprValue); }
    | ID '.' 'count' '(' ')'  { $exprValue = new ListOperation($ID.text, "count", null); }
    | ID '.' 'sort' '(' ')'                   { $exprValue = new ListOperation($ID.text, "sort", null); }
    ;




/*=========================== LEXER RULES ==================================== */


//NUMERIC : ('0' .. '9')+ ('.' ('0' ..'9')*)?;

NUMERIC : [0-9]+; // Only matches whole numbers
FLOAT : NUMERIC '.' [0-9]+; // Matches floating-point numbers
RANGE : '..'; // Explicit token for the range operator
SLICE: NUMERIC ':' NUMERIC;

COMPARISON: '<' | '>' | '<=' | '>=' | '==' | '!='; 

STRING: '"' ( '\\"' | ~'"' )* '"';

BOOLEAN: 'true' | 'false';

ID: ('a' ..'z' | 'A' .. 'Z' | '_') ('a' ..'z' | 'A' .. 'Z' | '0' .. '9' | '_')*;

COMMENT: '/*' .*? '*/' -> skip;

WHITESPACE : (' ' | '\t' | '\r' | '\n')+ -> skip;
