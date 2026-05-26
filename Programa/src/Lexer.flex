/**
 * Lexer.flex - Analizador Léxico
 * Objetivo:   Convertir código fuente en tokens para el Parser.
 * Entrada:    Archivo fuente (.txt)
 * Salida:     Archivo _tokens.txt (tokens) y _symbols.txt (tablas por scope)
 * Restricción: Case-sensitive, recuperación en modo pánico ante errores.
 */

import java_cup.runtime.*;
import java.io.*;

%%

%class Lexer
%cup
%line
%column
%public
%unicode

%{
    // ===== ESCRITURA DE TOKENS =====
    // Objetivo: Registrar cada token en _tokens.txt
    // Columnas: ID_LEXEMA, LÍNEA, COLUMNA, TOKEN, LEXEMA
    private static PrintWriter tokenWriter = null;

    // ===== IDENTIFICADORES DE LEXEMAS =====
    // Objetivo: Asignar un ID único a cada lexema diferente
    // Entrada: lexema (String) -> Salida: ID (Integer, desde 1)
    // Restricción: Mismo lexema = mismo ID
    private static java.util.LinkedHashMap<String, Integer> lexemaIds =
        new java.util.LinkedHashMap<>();
    private static int nextLexemaId = 1;

    /** Inicializa el archivo de tokens */
    public static void initTokenWriter(String filename) throws IOException {
        tokenWriter = new PrintWriter(new FileWriter(filename));
        tokenWriter.println("ID_LEXEMA \tLÍNEA \tCOLUMNA \tTOKEN                \tLEXEMA");
        tokenWriter.println("-------------------------------------------------------------------------------");
    }

    /** Cierra el archivo de tokens */
    public static void closeTokenWriter() {
        if (tokenWriter != null) {
            tokenWriter.close();
            tokenWriter = null;
        }
    }

    /** Retorna ID único para un lexema */
    private int getLexemaId(String lexema) {
        if (!lexemaIds.containsKey(lexema)) {
            lexemaIds.put(lexema, nextLexemaId++);
        }
        return lexemaIds.get(lexema);
    }

    // -----------------------------------------------------------------------
    // Métodos internos del lexer
    // -----------------------------------------------------------------------

    /**
     * Crea token sin valor (palabras reservadas, símbolos).
     * Entrada: tipo de token -> Salida: Symbol con línea y columna
     */
    private Symbol symbol(int type) {
        String tokenName = sym.terminalNames[type];
        String lexema = yytext();
        int lexId = getLexemaId(lexema);
        writeToken(lexId, tokenName, lexema);
        return new Symbol(type, yyline + 1, yycolumn + 1);
    }

    /**
     * Crea token con valor (literales, identificadores).
     * Si es ID, se agrega a la tabla de símbolos del scope actual.
     */
    private Symbol symbol(int type, Object value) {
        String tokenName = sym.terminalNames[type];
        String lexema = yytext();
        int lexId = getLexemaId(lexema);
        writeToken(lexId, tokenName, lexema);
        if (type == sym.ID) {
            addSymbol(lexema, tokenName,
                value != null ? value.toString() : lexema,
                yyline + 1, yycolumn + 1);
        }
        return new Symbol(type, yyline + 1, yycolumn + 1, value);
    }

    /** Escribe una línea en el archivo de tokens */
    private void writeToken(int lexId, String tokenName, String lexema) {
        if (tokenWriter != null) {
            tokenWriter.printf("%-10d\t%-6d\t%-8d\t%-21s\t%s%n",
                lexId, yyline + 1, yycolumn + 1, tokenName, lexema);
            tokenWriter.flush();
        }
    }

    // ===== TABLAS DE SÍMBOLOS POR SCOPE =====
    // Objetivo: Almacenar identificadores y literales agrupados por scope
    // Entrada: nombre, tipo, valor, línea, columna
    // Salida: Archivo _symbols.txt con una tabla por cada scope (main, funcion, if, etc.)
    // Restricción: Solo se guarda la primera aparición de cada símbolo por scope
    private static java.util.ArrayList<java.util.LinkedHashMap<String, String[]>> symbolTables =
        new java.util.ArrayList<>();
    private static java.util.ArrayList<String> tableNames = new java.util.ArrayList<>();
    private static PrintWriter symbolWriter = null;

    /** Inicializa el archivo de símbolos */
    public static void initSymbolWriter(String filename) throws IOException {
        symbolWriter = new PrintWriter(new FileWriter(filename));
    }

    /** Cierra el archivo de símbolos e imprime todas las tablas por scope */
    public static void closeSymbolWriter() {
        if (symbolWriter != null) {
            symbolWriter.println("================================================================================");
            symbolWriter.println("TABLAS DE SÍMBOLOS POR SCOPE");
            symbolWriter.println("================================================================================");
            for (int i = 0; i < symbolTables.size(); i++) {
                String tableName = tableNames.get(i);
                java.util.LinkedHashMap<String, String[]> table = symbolTables.get(i);
                symbolWriter.println();
                symbolWriter.println("SCOPE: " + tableName);
                symbolWriter.println("-------------------------------------------------------------------------------");
                symbolWriter.println("NOMBRE            \tTIPO              \tVALOR             \tLÍNEA \tCOLUMNA");
                symbolWriter.println("-------------------------------------------------------------------------------");
                for (java.util.Map.Entry<String, String[]> entry : table.entrySet()) {
                    String[] info = entry.getValue();
                    symbolWriter.printf("%-18s\t%-18s\t%-18s\t%-6s\t%s%n",
                        entry.getKey(), info[0], info[1], info[2], info[3]);
                }
            }
            symbolWriter.close();
            symbolWriter = null;
        }
    }

    // ===== PILA DE SCOPES =====
    // Objetivo: Controlar el scope actual para las tablas de símbolos
    // El Parser llama a pushScope al entrar a main/funcion/if/do/switch
    // y a popScope al salir
    private static java.util.Stack<String> scopeStack = new java.util.Stack<>();
    public static int ifCount = 0;
    public static int doCount = 0;
    public static int switchCount = 0;
    public static int caseCount = 0;
    public static int elseCount = 0;

    /** Crea un nuevo scope con el nombre dado */
    public static void pushScope(String scopeName) {
        scopeStack.push(scopeName);
        String fullName = String.join("_", scopeStack);
        if (!tableNames.contains(fullName)) {
            tableNames.add(fullName);
            symbolTables.add(new java.util.LinkedHashMap<String, String[]>());
        }
    }

    /** Sale del scope actual */
    public static void popScope() {
        if (!scopeStack.isEmpty()) {
            scopeStack.pop();
        }
    }

    /** Scope para if: ifN_nombreFuncion */
    public static void pushIfScope(String funcName) {
        ifCount++;
        String name = "if" + ifCount;
        pushScope(name);
    }

    public static void pushElseScope(String funcName) {
        elseCount++;
        String name = "else" + elseCount;
        pushScope(name);
    }

    /** Scope para do-while: doN_nombreFuncion */
    public static void pushDoScope(String funcName) {
        doCount++;
        String name = "do" + doCount;
        pushScope(name);
    }

    /** Scope para switch: switchN_nombreFuncion */
    public static void pushSwitchScope(String funcName) {
        caseCount = 0;
        switchCount++;
        String name = "switch" + switchCount;
        pushScope(name);
    }

    public static void pushCaseScope(String funcName, String cName) {
        caseCount++;
        String name = "switch" + switchCount "_" + cName + caseCount;
        pushScope(name);
    }

    /**
     * Agrega un símbolo a la tabla del scope actual.
     * Solo guarda la primera aparición de cada nombre en cada scope.
     */
    public static void addSymbol(String name, String tipo, String valor, int line, int col) {
        if (scopeStack.isEmpty()) return;
        String fullName = String.join("_", scopeStack);
        int tableIndex = tableNames.indexOf(fullName);
        if (tableIndex >= 0) {
            java.util.LinkedHashMap<String, String[]> table = symbolTables.get(tableIndex);
            if (!table.containsKey(name)) {
                table.put(name, new String[]{tipo, valor, String.valueOf(line), String.valueOf(col)});
            }
        }
    }
%}

// ===== DEFINICIONES REGULARES =====
// Objetivo: Definir patrones base para reconocer tokens
// Restricción: El orden de definición en literales es crucial
//              (más específicos primero: exp > frac > float > int)

LineTerminator  = \r|\n|\r\n
WhiteSpace      = {LineTerminator} | [ \t\f]

// Comentarios: ¡¡ una línea, {- multilínea -}
CommentSingle   = "¡¡" [^\r\n]* {LineTerminator}?
CommentMulti    = "{-" ~"-}"

// Componentes básicos
letra_sub       = [a-zA-Z_]
digito          = [0-9]
digito_no_cero  = [1-9]

// Identificador: letra o _ seguido de letras, dígitos o _
id              = {letra_sub}({letra_sub}|{digito})*

// Literales numéricos (orden importante)
int_lit         = {digito}+
float_lit       = {digito}+"."{digito}+
int_lit_pos     = {digito_no_cero}{digito}*
exp_lit         = {digito}+[eE]{int_lit_pos}
frac_lit        = {digito}+"//"{digito}+

// Carácter: cualquier carácter entre comillas simples
char_lit        = \'([^\']|\\\')\'

// Cadena: cualquier texto entre comillas dobles
string_lit      = \"[^\"]*\"

%%

// ===== IGNORAR ESPACIOS Y COMENTARIOS =====
{WhiteSpace}            { /* ignorar: espacios, tabs, saltos de línea */ }
{CommentSingle}         { /* ignorar: comentario de una línea */ }
{CommentMulti}          { /* ignorar: comentario multilínea */ }

// ===== PALABRAS RESERVADAS =====
// Objetivo: Reconocer palabras clave del lenguaje
"empty"                 { return symbol(sym.EMPTY); }
"int"                   { return symbol(sym.INT); }
"float"                 { return symbol(sym.FLOAT); }
"char"                  { return symbol(sym.CHAR); }
"bool"                  { return symbol(sym.BOOL); }
"string"                { return symbol(sym.STRING); }
"if"                    { return symbol(sym.IF); }
"else"                  { return symbol(sym.ELSE); }
"do"                    { return symbol(sym.DO); }
"while"                 { return symbol(sym.WHILE); }
"switch"                { return symbol(sym.SWITCH); }
"case"                  { return symbol(sym.CASE); }
"default"               { return symbol(sym.DEFAULT); }
"return"                { return symbol(sym.RETURN); }
"break"                 { return symbol(sym.BREAK); }
"cin"                   { return symbol(sym.CIN); }
"cout"                  { return symbol(sym.COUT); }
"true"                  { return symbol(sym.BOOL_LIT, Boolean.valueOf(true)); }
"false"                 { return symbol(sym.BOOL_LIT, Boolean.valueOf(false)); }

// ===== OPERADORES RELACIONALES =====
"equal"                 { return symbol(sym.EQUAL); }
"n_equal"               { return symbol(sym.N_EQUAL); }
"less_t"                { return symbol(sym.LESS_T); }
"less_te"               { return symbol(sym.LESS_TE); }
"greather_t"            { return symbol(sym.GREATHER_T); }
"greather_te"           { return symbol(sym.GREATHER_TE); }

// ===== IDENTIFICADOR ESPECIAL =====
"__main__"              { return symbol(sym.MAIN); }

// ===== SÍMBOLOS COMPUESTOS (antes que simples para coincidencia correcta) =====
"<|"                    { return symbol(sym.LPAR); }
"|>"                    { return symbol(sym.RPAR); }
"|:"                    { return symbol(sym.LBLOCK); }
":|"                    { return symbol(sym.RBLOCK); }
"<<"                    { return symbol(sym.LBRACKET); }
">>"                    { return symbol(sym.RBRACKET); }
"<-"                    { return symbol(sym.ASSIGN); }
"++"                    { return symbol(sym.INCREMENT); }
"--"                    { return symbol(sym.DECREMENT); }

// ===== SÍMBOLOS SIMPLES =====
"~"                     { return symbol(sym.SEPARATOR); }
"!"                     { return symbol(sym.EXCLAMATION); }
","                     { return symbol(sym.COMMA); }
":"                     { return symbol(sym.COLON); }
"+"                     { return symbol(sym.PLUS); }
"-"                     { return symbol(sym.MINUS); }
"*"                     { return symbol(sym.TIMES); }
"/"                     { return symbol(sym.DIVIDE); }
"%"                     { return symbol(sym.MOD); }
"^"                     { return symbol(sym.POWER); }
"@"                     { return symbol(sym.AND); }
"#"                     { return symbol(sym.OR); }
"$"                     { return symbol(sym.NOT); }

// ===== LITERALES (orden: más específicos primero) =====
{exp_lit}               { return symbol(sym.EXP_LIT, yytext()); }
{frac_lit}              { return symbol(sym.FRAC_LIT, yytext()); }
{float_lit}             { return symbol(sym.FLOAT_LIT, Float.parseFloat(yytext())); }
{int_lit}               { return symbol(sym.INT_LIT, Integer.parseInt(yytext())); }
{char_lit}              { return symbol(sym.CHAR_LIT, yytext().charAt(1)); }
{string_lit}            {
                            String str = yytext();
                            return symbol(sym.STRING_LIT, str.substring(1, str.length() - 1));
                        }

// ===== IDENTIFICADOR (después de palabras reservadas) =====
{id}                    { return symbol(sym.ID, yytext()); }

// ===== ERROR LÉXICO (recuperación en modo pánico) =====
// Objetivo: Reportar caracteres no reconocidos y continuar el análisis
[^]                     {
                            String lex = yytext();
                            int lin = yyline + 1, col = yycolumn + 1;
                            System.err.println("Error léxico en línea " + lin +
                                ", columna " + col +
                                ": carácter no reconocido '" + lex + "'");
                            return new Symbol(sym.error, lin, col, lex);
                        }