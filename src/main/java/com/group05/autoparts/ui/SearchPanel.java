package com.group05.autoparts.ui;

import com.group05.autoparts.config.DBConnection;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.*;
import java.util.Vector;

public class SearchPanel extends JPanel {

    private JTextField txtKeyword;
    private JComboBox<String> cboBrand;
    private JTextField txtMake;
    private JTextField txtModel;
    private JTextField txtYear;
    private JTextField txtMaxPrice;
    private JCheckBox chkInStock;
    private JButton btnSearch, btnClear;
    private JLabel lblStatus;
    private JTable table;

    public SearchPanel() {
        setLayout(new BorderLayout());
        JPanel filterPanel = new JPanel(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.anchor = GridBagConstraints.WEST;

        gbc.gridx = 0; gbc.gridy = 0;
        filterPanel.add(new JLabel("Part Name/Code:"), gbc);
        gbc.gridx = 1;
        txtKeyword = new JTextField(15);
        filterPanel.add(txtKeyword, gbc);

        gbc.gridx = 2;
        filterPanel.add(new JLabel("Brand:"), gbc);
        gbc.gridx = 3;
        String[] brands = {"All", "NGK", "Denso", "Bosch", "Brembo", "Castrol"};
        cboBrand = new JComboBox<>(brands);
        filterPanel.add(cboBrand, gbc);

        gbc.gridx = 0; gbc.gridy = 1;
        filterPanel.add(new JLabel("Make (e.g. Toyota):"), gbc);
        gbc.gridx = 1;
        txtMake = new JTextField(15);
        filterPanel.add(txtMake, gbc);

        gbc.gridx = 2;
        filterPanel.add(new JLabel("Model Name:"), gbc);
        gbc.gridx = 3;
        txtModel = new JTextField(15);
        filterPanel.add(txtModel, gbc);

        gbc.gridx = 4;
        filterPanel.add(new JLabel("Year:"), gbc);
        gbc.gridx = 5;
        txtYear = new JTextField(6);
        filterPanel.add(txtYear, gbc);

        gbc.gridx = 0; gbc.gridy = 2;
        filterPanel.add(new JLabel("Max Unit Price:"), gbc);
        gbc.gridx = 1;
        txtMaxPrice = new JTextField(15);
        filterPanel.add(txtMaxPrice, gbc);

        gbc.gridx = 2;
        chkInStock = new JCheckBox("In-Stock Only");
        filterPanel.add(chkInStock, gbc);

        gbc.gridx = 3; gbc.gridwidth = 3;
        JPanel btnPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        btnSearch = new JButton("Search");
        btnClear = new JButton("Clear Filters");
        btnPanel.add(btnSearch);
        btnPanel.add(btnClear);
        filterPanel.add(btnPanel, gbc);

        add(filterPanel, BorderLayout.NORTH);

        table = new JTable();
        table.setFillsViewportHeight(true);
        add(new JScrollPane(table), BorderLayout.CENTER);

        JPanel statusPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 5));
        lblStatus = new JLabel("Matching rows found: 0");
        lblStatus.setFont(new Font("Arial", Font.BOLD, 12));
        statusPanel.add(lblStatus);
        add(statusPanel, BorderLayout.SOUTH);

        btnSearch.addActionListener(e -> performSearch());
        btnClear.addActionListener(e -> clearFilters());

        performSearch();
    }

    private void performSearch() {

        double maxPrice = Double.MAX_VALUE;
        String priceText = txtMaxPrice.getText().trim();
        if (!priceText.isEmpty()) {
            try {
                maxPrice = Double.parseDouble(priceText);
                if (maxPrice < 0) {
                    throw new NumberFormatException();
                }
            } catch (NumberFormatException ex) {
                JOptionPane.showMessageDialog(this,
                        "The maximum unit price must be a valid positive number!",
                        "Invalid data",
                        JOptionPane.WARNING_MESSAGE);
                return;
            }
        }

        String sql = "SELECT DISTINCT p.Code, p.Name, p.Brand, c.CategoryName, p.UnitPrice, p.CurrentStockLevel " +
                "FROM PART p " +
                "JOIN CATEGORY c ON p.CategoryID = c.CategoryID " +
                "LEFT JOIN PART_COMPATIBILITY pc ON p.Code = pc.Code " +
                "LEFT JOIN VEHICLE_MODEL vm ON pc.ModelID = vm.ModelID " +
                "WHERE (p.Name LIKE ? OR p.Code LIKE ?) " +
                "AND (? = 'All' OR p.Brand = ?) " +
                "AND (? = '' OR vm.Make LIKE ?) " +
                "AND (? = '' OR vm.ModelName LIKE ?) " +
                "AND (? = '' OR vm.YearRange LIKE ?) " +
                "AND (? = 0 OR p.CurrentStockLevel > 0) " +
                "AND p.UnitPrice <= ? " +
                "ORDER BY p.Code";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            String keyword = "%" + txtKeyword.getText().trim() + "%";
            String brand = cboBrand.getSelectedItem().toString();
            String make = txtMake.getText().trim();
            String model = txtModel.getText().trim();
            String year = txtYear.getText().trim();
            boolean inStock = chkInStock.isSelected();

            ps.setString(1, keyword);
            ps.setString(2, keyword);

            ps.setString(3, brand);
            ps.setString(4, brand);

            ps.setString(5, make);
            ps.setString(6, "%" + make + "%");

            ps.setString(7, model);
            ps.setString(8, "%" + model + "%");

            ps.setString(9, year);
            ps.setString(10, "%" + year + "%");

            ps.setInt(11, inStock ? 1 : 0);
            ps.setDouble(12, maxPrice);

            try (ResultSet rs = ps.executeQuery()) {
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

                DefaultTableModel modelTable = new DefaultTableModel(data, columnNames) {
                    @Override
                    public boolean isCellEditable(int row, int column) {
                        return false;
                    }
                };

                table.setModel(modelTable);
                lblStatus.setText("Matching rows found: " + rowCount);
            }

        } catch (Exception ex) {
            ex.printStackTrace();
            JOptionPane.showMessageDialog(this,
                    "Search error: " + ex.getMessage(),
                    "Database error",
                    JOptionPane.ERROR_MESSAGE);
        }
    }

    private void clearFilters() {
        txtKeyword.setText("");
        cboBrand.setSelectedIndex(0);
        txtMake.setText("");
        txtModel.setText("");
        txtYear.setText("");
        txtMaxPrice.setText("");
        chkInStock.setSelected(false);
        performSearch();
    }
}
