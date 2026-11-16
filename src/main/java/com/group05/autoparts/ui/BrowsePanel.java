package com.group05.autoparts.ui;

import com.group05.autoparts.config.DBConnection;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.*;
import java.util.Vector;

public class BrowsePanel extends JPanel {
    private JComboBox<String> cboTables;
    private JButton btnRefresh;
    private JLabel lblRowCount;
    private JTable table;

    private final String[] tableNames = {
            "CUSTOMER", "CATEGORY", "VEHICLE_MODEL", "PART",
            "PART_COMPATIBILITY", "CUSTOMER_ADDRESS", "ORDERS",
            "ORDER_LINE", "SHIPMENT", "PAYMENT"
    };
    public BrowsePanel() {
        setLayout(new BorderLayout());
        JPanel controlPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 10));
        cboTables = new JComboBox<>(tableNames);
        btnRefresh = new JButton("Load / Refresh Table");
        lblRowCount = new JLabel("Rows loaded: 0");
        lblRowCount.setFont(new Font("Arial", Font.BOLD, 12));

        controlPanel.add(new JLabel("Select Table: "));
        controlPanel.add(cboTables);
        controlPanel.add(btnRefresh);
        controlPanel.add(Box.createHorizontalStrut(20));
        controlPanel.add(lblRowCount);

        add(controlPanel, BorderLayout.NORTH);

        table = new JTable();
        table.setFillsViewportHeight(true);
        add(new JScrollPane(table), BorderLayout.CENTER);

        btnRefresh.addActionListener(e -> loadTableData());

        loadTableData();
    }

    private void loadTableData() {
        String selectedTable = (String) cboTables.getSelectedItem();
        if (selectedTable == null) return;

        String sql = "SELECT * FROM " + selectedTable;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            ResultSetMetaData metaData = rs.getMetaData();
            int columnCount = metaData.getColumnCount();

            Vector<String> columnNames = new Vector<>();
            for (int i = 1; i <= columnCount; i++) {
                columnNames.add(metaData.getColumnName(i));
            }

            Vector<Vector<Object>> data = new Vector<>();
            int rowCount = 0;
            while (rs.next()) {
                Vector<Object> row = new Vector<>();
                for (int i = 1; i <= columnCount; i++) {
                    row.add(rs.getObject(i));
                }
                data.add(row);
                rowCount++;
            }

            DefaultTableModel model = new DefaultTableModel(data, columnNames) {
                @Override
                public boolean isCellEditable(int row, int column) {
                    return false;
                }
            };

            table.setModel(model);
            lblRowCount.setText("Rows loaded: " + rowCount);

        } catch (Exception ex) {
            ex.printStackTrace();
            JOptionPane.showMessageDialog(this,
                    "Error loading data from table " + selectedTable + ":\n" + ex.getMessage(),
                    "Database error",
                    JOptionPane.ERROR_MESSAGE);
        }
    }
}
