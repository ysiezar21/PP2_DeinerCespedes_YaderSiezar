/**
 * Main.java - Punto de entrada del compilador.
 * Objetivo:   Orquestar el análisis léxico, sintáctico y semántico.
 * Entrada:    Archivo fuente (.txt) pasado como argumento.
 * Salida:     Archivos _tokens.txt, _symbols.txt y resultado en consola.
 */

import java.io.*;
import java_cup.runtime.*;

public class Main {
    public static void main(String[] args) {
        if (args.length == 0) {
            System.err.println("Uso: java Main <archivo_fuente>");
            System.exit(1);
        }

        String sourceFile = args[0];
        String baseName   = sourceFile.replaceAll("\\.[^.]+$", "");
        String tokenFile  = baseName + "_tokens.txt";
        String symbolFile = baseName + "_symbols.txt";

        try {
            Lexer.initTokenWriter(tokenFile);
            Lexer.initSymbolWriter(symbolFile);

            FileReader reader = new FileReader(sourceFile);
            Lexer  lexer  = new Lexer(reader);
            Parser parser = new Parser(lexer);

            System.out.println("Analizando: " + sourceFile);
            System.out.println("==============================");
            parser.parse();
            System.out.println("==============================");

            boolean ok = (parser.errorCount == 0 && parser.semErrorCount == 0);
            if (ok) {
                System.out.println("Resultado: El archivo SÍ puede ser generado por la gramática.");
            } else {
                System.out.println("Resultado: El archivo NO puede ser generado por la gramática.");
                if (parser.errorCount > 0)
                    System.out.println("  Errores sintácticos : " + parser.errorCount);
                if (parser.semErrorCount > 0)
                    System.out.println("  Errores semánticos  : " + parser.semErrorCount);
            }
            System.out.println("Archivos generados:");
            System.out.println("  Tokens   -> " + tokenFile);
            System.out.println("  Símbolos -> " + symbolFile);

        } catch (FileNotFoundException e) {
            System.err.println("Error: Archivo no encontrado - " + sourceFile);
        } catch (Exception e) {
            System.err.println("Error durante el análisis: " + e.getMessage());
            e.printStackTrace();
        } finally {
            Lexer.closeTokenWriter();
            Lexer.closeSymbolWriter();
        }
    }
}
