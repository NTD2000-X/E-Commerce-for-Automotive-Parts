package com.group05.autoparts;

import com.group05.autoparts.config.DBConnection;
import com.group05.autoparts.ui.*;
import javax.swing.*;
import java.awt.*;
import java.sql.SQLException;

/**
 * Assigned Role: B1 (Architecture & JDBC)
 * Main application window integrating all squad panels and connection status bar.
 */
public class Main {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            JFrame frame = new JFrame("Topic 4: E-Commerce for Automotive Parts");
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            frame.setSize(1100, 750);
            frame.setLocationRelativeTo(null);
            frame.setLayout(new BorderLayout());

            JTabbedPane tabs = new JTabbedPane();
            tabs.addTab("1. Browse Data", new BrowsePanel());
            tabs.addTab("2. Search Catalogue", new SearchPanel());
            tabs.addTab("3. Orders (Master-Detail)", new MasterDetailPanel());
            tabs.addTab("4. Manage Records (CRUD)", new CrudEditPanel());
            tabs.addTab("5. Reports & Topic Queries", new AnalyticsReportPanel());

            JLabel statusBar = new JLabel();
            statusBar.setBorder(BorderFactory.createEmptyBorder(4, 10, 4, 10));
            try {
                statusBar.setText(DBConnection.testConnection());
            } catch (SQLException e) {
                statusBar.setText("Database connection warning: " + e.getMessage());
            }

            frame.add(tabs, BorderLayout.CENTER);
            frame.add(statusBar, BorderLayout.SOUTH);
            frame.setVisible(true);
        });
    }
}
