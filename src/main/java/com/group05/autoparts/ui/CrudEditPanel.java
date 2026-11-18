package com.group05.autoparts.ui;

import com.group05.autoparts.config.DBConnection;

import javax.swing.*;
import java.awt.*;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;

/**
 * Insert, update, and delete forms for PART and CUSTOMER, plus transactional order placement.
 */
public class CrudEditPanel extends JPanel {
    private static final BigDecimal MAX_UNIT_PRICE = new BigDecimal("99999999.99");
    private static final DateTimeFormatter DATE_FORMAT =
            DateTimeFormatter.ofPattern("uuuu-MM-dd").withResolverStyle(ResolverStyle.STRICT);

    public CrudEditPanel() {
        setLayout(new BorderLayout());

        JTabbedPane tableTabs = new JTabbedPane();
        tableTabs.addTab("PART", createPartPanel());
        tableTabs.addTab("CUSTOMER", createCustomerPanel());
        tableTabs.addTab("Place Order (Transaction)", createPlaceOrderForm());

        add(tableTabs, BorderLayout.CENTER);
    }

    private JTabbedPane createPartPanel() {
        JTabbedPane operationTabs = new JTabbedPane();
        operationTabs.addTab("Insert", createPartInsertForm());
        operationTabs.addTab("Update", createPartUpdateForm());
        operationTabs.addTab("Delete", createPartDeleteForm());
        return operationTabs;
    }

    private JPanel createPartInsertForm() {
        JTextField codeField = new JTextField(20);
        JTextField nameField = new JTextField(20);
        JTextField brandField = new JTextField(20);
        JTextField stockField = new JTextField(20);
        JTextField priceField = new JTextField(20);
        JTextField categoryField = new JTextField(20);

        JPanel form = createFormPanel();
        addField(form, "Part Code:", codeField);
        addField(form, "Name:", nameField);
        addField(form, "Brand:", brandField);
        addField(form, "Current Stock Level:", stockField);
        addField(form, "Unit Price:", priceField);
        addField(form, "Category ID:", categoryField);

        JButton insertButton = new JButton("Insert Part");
        addButton(form, insertButton);
        insertButton.addActionListener(event -> {
            String code = requiredText(codeField, "Part Code", 20);
            String name = requiredText(nameField, "Name", 150);
            String brand = requiredText(brandField, "Brand", 100);
            Integer stock = integerValue(stockField, "Current Stock Level", 0);
            BigDecimal price = priceValue(priceField);
            Integer categoryId = integerValue(categoryField, "Category ID", 1);
            if (code == null || name == null || brand == null || stock == null
                    || price == null || categoryId == null) {
                return;
            }

            executeDatabaseAction(conn -> {
                String sql = "INSERT INTO PART "
                        + "(Code, Name, Brand, CurrentStockLevel, UnitPrice, CategoryID) "
                        + "VALUES (?, ?, ?, ?, ?, ?)";
                try (PreparedStatement statement = conn.prepareStatement(sql)) {
                    statement.setString(1, code);
                    statement.setString(2, name);
                    statement.setString(3, brand);
                    statement.setInt(4, stock);
                    statement.setBigDecimal(5, price);
                    statement.setInt(6, categoryId);
                    statement.executeUpdate();
                }
                showSuccess("Part inserted successfully.");
            });
        });
        return form;
    }

    private JPanel createPartUpdateForm() {
        JTextField codeField = new JTextField(20);
        JTextField nameField = new JTextField(20);
        JTextField brandField = new JTextField(20);
        JTextField stockField = new JTextField(20);
        JTextField priceField = new JTextField(20);
        JTextField categoryField = new JTextField(20);

        JPanel form = createFormPanel();
        addField(form, "Part Code (record to update):", codeField);
        addField(form, "New Name:", nameField);
        addField(form, "New Brand:", brandField);
        addField(form, "New Current Stock Level:", stockField);
        addField(form, "New Unit Price:", priceField);
        addField(form, "New Category ID:", categoryField);

        JButton updateButton = new JButton("Update Part");
        addButton(form, updateButton);
        updateButton.addActionListener(event -> {
            String code = requiredText(codeField, "Part Code", 20);
            String name = requiredText(nameField, "Name", 150);
            String brand = requiredText(brandField, "Brand", 100);
            Integer stock = integerValue(stockField, "Current Stock Level", 0);
            BigDecimal price = priceValue(priceField);
            Integer categoryId = integerValue(categoryField, "Category ID", 1);
            if (code == null || name == null || brand == null || stock == null
                    || price == null || categoryId == null) {
                return;
            }

            executeDatabaseAction(conn -> {
                String sql = "UPDATE PART SET Name = ?, Brand = ?, CurrentStockLevel = ?, "
                        + "UnitPrice = ?, CategoryID = ? WHERE Code = ?";
                try (PreparedStatement statement = conn.prepareStatement(sql)) {
                    statement.setString(1, name);
                    statement.setString(2, brand);
                    statement.setInt(3, stock);
                    statement.setBigDecimal(4, price);
                    statement.setInt(5, categoryId);
                    statement.setString(6, code);
                    showUpdateResult(statement.executeUpdate());
                }
            });
        });
        return form;
    }

    private JPanel createPartDeleteForm() {
        JTextField codeField = new JTextField(20);
        JPanel form = createFormPanel();
        addField(form, "Part Code:", codeField);

        JButton deleteButton = new JButton("Delete Part");
        addButton(form, deleteButton);
        deleteButton.addActionListener(event -> {
            String code = requiredText(codeField, "Part Code", 20);
            if (code == null || !confirmDelete()) {
                return;
            }

            executeDatabaseAction(conn -> {
                try (PreparedStatement statement =
                             conn.prepareStatement("DELETE FROM PART WHERE Code = ?")) {
                    statement.setString(1, code);
                    showDeleteResult(statement.executeUpdate());
                }
            });
        });
        return form;
    }

    private JTabbedPane createCustomerPanel() {
        JTabbedPane operationTabs = new JTabbedPane();
        operationTabs.addTab("Insert", createCustomerInsertForm());
        operationTabs.addTab("Update", createCustomerUpdateForm());
        operationTabs.addTab("Delete", createCustomerDeleteForm());
        return operationTabs;
    }

    private JPanel createCustomerInsertForm() {
        JTextField idField = new JTextField(20);
        JTextField nameField = new JTextField(20);
        JPanel form = createFormPanel();
        addField(form, "Customer ID:", idField);
        addField(form, "Name:", nameField);

        JButton insertButton = new JButton("Insert Customer");
        addButton(form, insertButton);
        insertButton.addActionListener(event -> {
            Integer customerId = integerValue(idField, "Customer ID", 1);
            String name = requiredText(nameField, "Name", 100);
            if (customerId == null || name == null) {
                return;
            }

            executeDatabaseAction(conn -> {
                try (PreparedStatement statement = conn.prepareStatement(
                        "INSERT INTO CUSTOMER (CustomerID, Name) VALUES (?, ?)")) {
                    statement.setInt(1, customerId);
                    statement.setString(2, name);
                    statement.executeUpdate();
                }
                showSuccess("Customer inserted successfully.");
            });
        });
        return form;
    }

    private JPanel createCustomerUpdateForm() {
        JTextField idField = new JTextField(20);
        JTextField nameField = new JTextField(20);
        JPanel form = createFormPanel();
        addField(form, "Customer ID (record to update):", idField);
        addField(form, "New Name:", nameField);

        JButton updateButton = new JButton("Update Customer");
        addButton(form, updateButton);
        updateButton.addActionListener(event -> {
            Integer customerId = integerValue(idField, "Customer ID", 1);
            String name = requiredText(nameField, "Name", 100);
            if (customerId == null || name == null) {
                return;
            }

            executeDatabaseAction(conn -> {
                try (PreparedStatement statement =
                             conn.prepareStatement("UPDATE CUSTOMER SET Name = ? WHERE CustomerID = ?")) {
                    statement.setString(1, name);
                    statement.setInt(2, customerId);
                    showUpdateResult(statement.executeUpdate());
                }
            });
        });
        return form;
    }

    private JPanel createCustomerDeleteForm() {
        JTextField idField = new JTextField(20);
        JPanel form = createFormPanel();
        addField(form, "Customer ID:", idField);

        JButton deleteButton = new JButton("Delete Customer");
        addButton(form, deleteButton);
        deleteButton.addActionListener(event -> {
            Integer customerId = integerValue(idField, "Customer ID", 1);
            if (customerId == null || !confirmDelete()) {
                return;
            }

            executeDatabaseAction(conn -> {
                try (PreparedStatement statement =
                             conn.prepareStatement("DELETE FROM CUSTOMER WHERE CustomerID = ?")) {
                    statement.setInt(1, customerId);
                    showDeleteResult(statement.executeUpdate());
                }
            });
        });
        return form;
    }

    private JPanel createPlaceOrderForm() {
        JTextField orderIdField = new JTextField(20);
        JTextField customerIdField = new JTextField(20);
        JTextField orderDateField = new JTextField(20);
        JTextField codeField = new JTextField(20);
        JTextField quantityField = new JTextField(20);

        JPanel form = createFormPanel();
        addField(form, "Order ID:", orderIdField);
        addField(form, "Customer ID:", customerIdField);
        addField(form, "Order Date (YYYY-MM-DD):", orderDateField);
        addField(form, "Part Code:", codeField);
        addField(form, "Quantity:", quantityField);

        JButton placeOrderButton = new JButton("Place Order");
        addButton(form, placeOrderButton);
        placeOrderButton.addActionListener(event -> {
            Integer orderId = integerValue(orderIdField, "Order ID", 1);
            Integer customerId = integerValue(customerIdField, "Customer ID", 1);
            LocalDate orderDate = dateValue(orderDateField);
            String code = requiredText(codeField, "Part Code", 20);
            Integer quantity = integerValue(quantityField, "Quantity", 1);
            if (orderId == null || customerId == null || orderDate == null
                    || code == null || quantity == null) {
                return;
            }

            executeDatabaseAction(conn -> placeOrder(conn, orderId, customerId, orderDate, code, quantity));
        });
        return form;
    }

    private void placeOrder(Connection conn, int orderId, int customerId, LocalDate orderDate,
                            String code, int quantity) throws SQLException {
        conn.setAutoCommit(false);
        try {
            BigDecimal unitPrice;
            int currentStock;
            try (PreparedStatement statement = conn.prepareStatement(
                    "SELECT UnitPrice, CurrentStockLevel FROM PART WHERE Code = ? FOR UPDATE")) {
                statement.setString(1, code);
                try (ResultSet result = statement.executeQuery()) {
                    if (!result.next()) {
                        conn.rollback();
                        showWarning("The referenced Part Code does not exist.");
                        return;
                    }
                    unitPrice = result.getBigDecimal("UnitPrice");
                    currentStock = result.getInt("CurrentStockLevel");
                }
            }

            if (currentStock < quantity) {
                conn.rollback();
                showWarning("Insufficient stock for this part. Available quantity: " + currentStock + ".");
                return;
            }

            try (PreparedStatement statement = conn.prepareStatement(
                    "INSERT INTO ORDERS (OrderID, OrderDate, OrderStatus, CustomerID) VALUES (?, ?, ?, ?)")) {
                statement.setInt(1, orderId);
                statement.setDate(2, Date.valueOf(orderDate));
                statement.setString(3, "Pending");
                statement.setInt(4, customerId);
                statement.executeUpdate();
            }

            try (PreparedStatement statement = conn.prepareStatement(
                    "INSERT INTO ORDER_LINE (OrderID, LineNumber, Quantity, Price, Code) "
                            + "VALUES (?, ?, ?, ?, ?)")) {
                statement.setInt(1, orderId);
                statement.setInt(2, 1);
                statement.setInt(3, quantity);
                statement.setBigDecimal(4, unitPrice);
                statement.setString(5, code);
                statement.executeUpdate();
            }

            try (PreparedStatement statement = conn.prepareStatement(
                    "UPDATE PART SET CurrentStockLevel = CurrentStockLevel - ? "
                            + "WHERE Code = ? AND CurrentStockLevel >= ?")) {
                statement.setInt(1, quantity);
                statement.setString(2, code);
                statement.setInt(3, quantity);
                if (statement.executeUpdate() != 1) {
                    throw new SQLException("Part stock changed while placing the order.");
                }
            }

            conn.commit();
            showSuccess("Order placed successfully.");
        } catch (SQLException ex) {
            try {
                conn.rollback();
            } catch (SQLException rollbackError) {
                ex.addSuppressed(rollbackError);
            }
            throw ex;
        }
    }

    private JPanel createFormPanel() {
        JPanel panel = new JPanel(new GridBagLayout());
        panel.setBorder(BorderFactory.createEmptyBorder(25, 30, 25, 30));
        return panel;
    }

    private void addField(JPanel panel, String label, JTextField field) {
        GridBagConstraints constraints = new GridBagConstraints();
        constraints.insets = new Insets(8, 8, 8, 8);
        constraints.anchor = GridBagConstraints.WEST;
        constraints.gridx = 0;
        constraints.gridy = panel.getComponentCount() / 2;
        panel.add(new JLabel(label), constraints);

        constraints.gridx = 1;
        constraints.fill = GridBagConstraints.HORIZONTAL;
        constraints.weightx = 1.0;
        panel.add(field, constraints);
    }

    private void addButton(JPanel panel, JButton button) {
        GridBagConstraints constraints = new GridBagConstraints();
        constraints.gridx = 1;
        constraints.gridy = panel.getComponentCount() / 2;
        constraints.insets = new Insets(15, 8, 8, 8);
        constraints.anchor = GridBagConstraints.WEST;
        panel.add(button, constraints);
    }

    private String requiredText(JTextField field, String label, int maxLength) {
        String value = field.getText().trim();
        if (value.isEmpty()) {
            showWarning(label + " is required.");
            field.requestFocusInWindow();
            return null;
        }
        if (value.length() > maxLength) {
            showWarning(label + " must be no more than " + maxLength + " characters.");
            field.requestFocusInWindow();
            return null;
        }
        return value;
    }

    private Integer integerValue(JTextField field, String label, int minimum) {
        String value = field.getText().trim();
        if (value.isEmpty()) {
            showWarning(label + " is required.");
            field.requestFocusInWindow();
            return null;
        }
        try {
            int parsed = Integer.parseInt(value);
            if (parsed < minimum) {
                showWarning(label + " must be " + (minimum == 0 ? "0 or greater." : "greater than 0."));
                field.requestFocusInWindow();
                return null;
            }
            return parsed;
        } catch (NumberFormatException ex) {
            showWarning(label + " must be a whole number.");
            field.requestFocusInWindow();
            return null;
        }
    }

    private BigDecimal priceValue(JTextField field) {
        String value = field.getText().trim();
        if (value.isEmpty()) {
            showWarning("Unit Price is required.");
            field.requestFocusInWindow();
            return null;
        }
        try {
            BigDecimal price = new BigDecimal(value);
            if (price.signum() <= 0) {
                showWarning("Unit Price must be greater than 0.");
                field.requestFocusInWindow();
                return null;
            }
            if (price.compareTo(MAX_UNIT_PRICE) > 0 || price.stripTrailingZeros().scale() > 2) {
                showWarning("Unit Price must fit DECIMAL(10,2).");
                field.requestFocusInWindow();
                return null;
            }
            return price.setScale(2);
        } catch (NumberFormatException ex) {
            showWarning("Unit Price must be a valid number.");
            field.requestFocusInWindow();
            return null;
        }
    }

    private LocalDate dateValue(JTextField field) {
        String value = field.getText().trim();
        if (value.isEmpty()) {
            showWarning("Order Date is required in YYYY-MM-DD format.");
            field.requestFocusInWindow();
            return null;
        }
        try {
            return LocalDate.parse(value, DATE_FORMAT);
        } catch (DateTimeParseException ex) {
            showWarning("Order Date must be a valid date in YYYY-MM-DD format.");
            field.requestFocusInWindow();
            return null;
        }
    }

    private boolean confirmDelete() {
        return JOptionPane.showConfirmDialog(
                this,
                "Are you sure you want to delete this record?",
                "Confirm Delete",
                JOptionPane.YES_NO_OPTION
        ) == JOptionPane.YES_OPTION;
    }

    private void executeDatabaseAction(DatabaseAction action) {
        try (Connection conn = DBConnection.getConnection()) {
            action.run(conn);
        } catch (SQLException ex) {
            showDatabaseError(ex);
        }
    }

    private void showUpdateResult(int rows) {
        if (rows > 0) {
            showSuccess("Record updated successfully.");
        } else {
            showInformation("No matching record was found.");
        }
    }

    private void showDeleteResult(int rows) {
        if (rows > 0) {
            showSuccess("Record deleted successfully.");
        } else {
            showInformation("No matching record was found.");
        }
    }

    private void showDatabaseError(SQLException exception) {
        String message = "The database operation failed. Please verify the entered values and try again.";
        for (SQLException current = exception; current != null; current = current.getNextException()) {
            switch (current.getErrorCode()) {
                case 1451 -> message =
                        "Cannot delete this record because it is still referenced by existing orders or parts in the database.";
                case 1062 -> message =
                        "A record with this ID, Part Code, or Category Name already exists.";
                case 1452 -> message =
                        "The referenced Category ID, Customer ID, or Part Code does not exist.";
                case 3819 -> message =
                        "The entered value violates a database rule (for example, stock cannot go below 0 and price must be greater than 0).";
                default -> {
                    continue;
                }
            }
            break;
        }
        JOptionPane.showMessageDialog(this, message, "Database Error", JOptionPane.ERROR_MESSAGE);
    }

    private void showSuccess(String message) {
        JOptionPane.showMessageDialog(this, message, "Success", JOptionPane.INFORMATION_MESSAGE);
    }

    private void showInformation(String message) {
        JOptionPane.showMessageDialog(this, message, "Information", JOptionPane.INFORMATION_MESSAGE);
    }

    private void showWarning(String message) {
        JOptionPane.showMessageDialog(this, message, "Invalid Input", JOptionPane.WARNING_MESSAGE);
    }

    @FunctionalInterface
    private interface DatabaseAction {
        void run(Connection connection) throws SQLException;
    }
}
