package com.mycompany.mtisteoria.security;

import org.mindrot.jbcrypt.BCrypt;

/**
 * Hash y verificación de contraseñas con bcrypt (memoria MTIS).
 */
public final class PasswordHasher {

    private PasswordHasher() {
    }

    public static String hash(String password) {
        return BCrypt.hashpw(password, BCrypt.gensalt(10));
    }

    public static boolean verify(String plainPassword, String storedHash) {
        if (plainPassword == null || storedHash == null) {
            return false;
        }
        try {
            return BCrypt.checkpw(plainPassword, storedHash);
        } catch (IllegalArgumentException ex) {
            return false;
        }
    }

    /**
     * Genera un hash para usar en SQL o pruebas: mvn -q exec:java -Dexec.mainClass="com.mycompany.mtisteoria.security.PasswordHasher"
     */
    public static void main(String[] args) {
        String pwd = args.length > 0 ? args[0] : "password123";
        System.out.println(hash(pwd));
    }
}
