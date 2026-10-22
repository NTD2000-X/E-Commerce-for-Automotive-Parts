package com.group05.autoparts;

import com.group05.autoparts.ui.*;
import javax.swing.*;

/**
 * Assigned Role: B1 (Architecture & JDBC)
 * Main application window integrating all squad panels.
 */
public class Main {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            JFrame frame = new JFrame("Topic 4: E-Commerce for Automotive Parts");
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            frame.setSize(1100, 750);
            frame.setLocationRelativeTo(null);

            JTabbedPane tabs = new JTabbedPane();
            tabs.addTab("1. Browse Data", new BrowsePanel());
            tabs.addTab("2. Search Catalogue", new SearchPanel());
            tabs.addTab("3. Orders (Master-Detail)", new MasterDetailPanel());
            tabs.addTab("4. Manage Records (CRUD)", new CrudEditPanel());
            tabs.addTab("5. Reports & Topic Queries", new AnalyticsReportPanel());

            frame.add(tabs);
            frame.setVisible(true);
        });
    }
}
