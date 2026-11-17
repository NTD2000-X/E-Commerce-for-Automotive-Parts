package com.group05.autoparts.config;

import javax.swing.table.DefaultTableModel;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.Properties;
import java.util.Vector;

/**
 * Connection layer of the application (Report Section 9A).
 *
 * <p>The connection settings (URL, user, password) are NOT written in the code.
 * They are read from the external file {@code db.properties} every time a connection
 * is requested, so the marker can point the application at another server by editing
 * that one text file - no recompiling needed.
 *
 * <p>Usage rule for every panel (B2, B3, B4, B5): always open resources with
 * try-with-resources so that they are closed automatically:
 * <pre>
 * try (Connection conn = DBConnection.getConnection();
 *      PreparedStatement ps = conn.prepareStatement("SELECT ... WHERE Brand = ?")) {
 *     ps.setString(1, brand);
 *     try (ResultSet rs = ps.executeQuery()) {
 *         table.setModel(DBConnection.resultSetToTableModel(rs));
 *     }
 * } catch (SQLException e) {
 *     // show a plain-language message with JOptionPane
 * }
 * </pre>
 * {@link #getConnection()} throws only {@link SQLException}, so one catch is enough.
 */
public final class DBConnection {

    /** Default location of the settings file: the folder the program is started from. */
    public static final String DEFAULT_PROPERTIES_FILE = "db.properties";

    /** Optional override: java -Ddb.properties=C:/other/db.properties -jar AutomotivePartsApp.jar */
    private static final String PROPERTIES_PATH_OPTION = "db.properties";

    private DBConnection() {
        // utility class - no instances
    }

    // ------------------------------------------------------------------
    // 1. Reading the external settings
    // ------------------------------------------------------------------

    private static Properties loadProperties() throws SQLException {
        String path = System.getProperty(PROPERTIES_PATH_OPTION, DEFAULT_PROPERTIES_FILE);
        Properties props = new Properties();
        try (FileInputStream in = new FileInputStream(path);
             InputStreamReader reader = new InputStreamReader(in, StandardCharsets.UTF_8)) {
            props.load(reader);
        } catch (IOException e) {
            // Wrap IOException so callers only ever have to catch SQLException.
            throw new SQLException("Cannot read db.properties: " + e.getMessage()
                    + " (looked for the file at: " + new java.io.File(path).getAbsolutePath() + ")", e);
        }
        return props;
    }

    private static String requiredSetting(Properties props, String key) throws SQLException {
        String value = props.getProperty(key);
        if (value == null || value.trim().isEmpty()) {
            throw new SQLException("db.properties is missing the setting \"" + key + "\".");
        }
        return value.trim();
    }

    // ------------------------------------------------------------------
    // 2. Opening a connection
    // ------------------------------------------------------------------

    /**
     * Opens a NEW connection using the settings in db.properties.
     * The caller must close it - always use try-with-resources.
     *
     * @throws SQLException if the file cannot be read, a setting is missing,
     *                      or MySQL refuses the connection
     */
    public static Connection getConnection() throws SQLException {
        Properties props = loadProperties();
        String url = requiredSetting(props, "db.url");
        String user = requiredSetting(props, "db.user");
        String password = props.getProperty("db.password", ""); // an empty password is allowed
        return DriverManager.getConnection(url, user, password);
    }

    /**
     * Startup check: opens a connection, runs a tiny query and closes everything again.
     *
     * @return a one-line description such as "Connected to database 'automotive_parts_db' on MySQL 8.0.46"
     * @throws SQLException if the database cannot be reached
     */
    public static String testConnection() throws SQLException {
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT DATABASE(), VERSION()");
             ResultSet rs = ps.executeQuery()) {
            rs.next();
            String database = rs.getString(1);
            String version = rs.getString(2);
            if (database == null) {
                throw new SQLException("Connected to MySQL " + version
                        + ", but db.url does not name a database (expected .../automotive_parts_db).");
            }
            return "Connected to database '" + database + "' on MySQL " + version;
        }
    }

    // ------------------------------------------------------------------
    // 3. Helpers that turn query results into a Swing table model
    // ------------------------------------------------------------------

    /**
     * Copies the whole current ResultSet into a read-only table model.
     * Column titles come from ResultSetMetaData, so it works for any query.
     * The caller still owns (and closes) the ResultSet.
     * Example: {@code table.setModel(DBConnection.resultSetToTableModel(rs));}
     */
    public static DefaultTableModel resultSetToTableModel(ResultSet rs) throws SQLException {
        ResultSetMetaData meta = rs.getMetaData();
        int columnCount = meta.getColumnCount();

        Vector<String> columnNames = new Vector<>();
        for (int c = 1; c <= columnCount; c++) {
            columnNames.add(meta.getColumnLabel(c)); // label = alias if the query used AS
        }

        Vector<Vector<Object>> rows = new Vector<>();
        while (rs.next()) {
            Vector<Object> row = new Vector<>();
            for (int c = 1; c <= columnCount; c++) {
                row.add(rs.getObject(c));
            }
            rows.add(row);
        }

        return new DefaultTableModel(rows, columnNames) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false; // grids are read-only; editing is done in the CRUD tab
            }
        };
    }

    /**
     * One-call version: runs a parameterised SELECT and returns the rows as a table model.
     * Every user value must be passed in {@code params} and written as a ? in the SQL -
     * never concatenate user text into {@code sql}.
     * Example: {@code DBConnection.queryToTableModel("SELECT * FROM ORDER_LINE WHERE OrderID = ?", orderId)}
     */
    public static DefaultTableModel queryToTableModel(String sql, Object... params) throws SQLException {
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return resultSetToTableModel(rs);
            }
        }
    }
}
