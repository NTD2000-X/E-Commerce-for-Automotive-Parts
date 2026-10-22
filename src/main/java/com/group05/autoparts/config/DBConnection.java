package com.group05.autoparts.config;

import java.io.FileInputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Assigned Role: B1 (Architecture & JDBC)
 * Opens the database connection from external settings (db.properties).
 */
public class DBConnection {
    private static final String PROPERTIES_FILE = "db.properties";

    public static Connection getConnection() throws SQLException, IOException {
        Properties props = new Properties();
        try (FileInputStream fis = new FileInputStream(PROPERTIES_FILE)) {
            props.load(fis);
        }
        return DriverManager.getConnection(
                props.getProperty("db.url"),
                props.getProperty("db.user"),
                props.getProperty("db.password")
        );
    }
}
