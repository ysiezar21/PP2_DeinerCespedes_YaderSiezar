/**
 * Main.java - Punto de entrada del compilador.
 * Objetivo:   Orquestar el análisis léxico y sintáctico de un archivo fuente.
 * Entrada:    Archivo fuente (.txt) pasado como argumento.
 * Salida:     Archivos _tokens.txt, _symbols.txt y resultado en consola.
 * Restricción: Requiere los archivos Lexer.java, Parser.java y sym.java generados.
 */

import java.io.*;
import java_cup.runtime.*;

public class Main {
    /**
     * Método principal.
     * @param args args[0] = ruta del archivo fuente a analizar
     */
    public static void main(String[] args) {
        // Validar argumento
        if (args.length == 0) {
            System.err.println("Uso: java Main <archivo_fuente>");
            System.exit(1);
        }

        // Preparar nombres de archivos de salida
        String sourceFile = args[0];
        String baseName   = sourceFile.replaceAll("\\.[^.]+$", "");
        String tokenFile  = baseName + "_tokens.txt";
        String symbolFile = baseName + "_symbols.txt";

        try {
            // Inicializar archivos de salida
            Lexer.initTokenWriter(tokenFile);
            Lexer.initSymbolWriter(symbolFile);

            // Crear lexer y parser
            FileReader reader = new FileReader(sourceFile);
            Lexer  lexer  = new Lexer(reader);
            Parser parser = new Parser(lexer);

            // Ejecutar análisis sintáctico
            System.out.println("Analizando: " + sourceFile);
            System.out.println("==============================");
            parser.parse();
            System.out.println("==============================");

            // Mostrar resultado
            if (parser.errorCount > 0) {
                System.out.println("Resultado: El archivo NO puede ser generado por la gramática.");
                System.out.println("Errores encontrados: " + parser.errorCount);
            } else {
                System.out.println("Resultado: El archivo SÍ puede ser generado por la gramática.");
            }
            System.out.println("Archivos generados:");
            System.out.println("  Tokens   -> " + tokenFile);
            System.out.println("  Símbolos -> " + symbolFile);

        } catch (FileNotFoundException e) {
            System.err.println("Error: Archivo no encontrado - " + sourceFile);
        } catch (Exception e) {
            System.err.println("Error durante el análisis: " + e.getMessage());
        } finally {
            // Cerrar archivos de salida
            Lexer.closeTokenWriter();
            Lexer.closeSymbolWriter();
        }
    }
}