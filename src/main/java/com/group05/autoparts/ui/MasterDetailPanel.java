package com.group05.autoparts.ui;

import com.group05.autoparts.config.DBConnection;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

/**
 * Assigned Role: B3 (Master-Detail UI)
 * Upper grid: ORDERS; lower grid: ORDER_LINE.
 */
public class MasterDetailPanel extends JPanel {

    private final DefaultTableModel ordersModel = createModel(
            "Order ID", "Order Date", "Status",
            "Customer ID", "Customer Name"
    );

    private final DefaultTableModel linesModel = createModel(
            "Line No.", "Part Code", "Part Name", "Brand",
            "Quantity", "Price", "Line Total"
    );

    private final JTable ordersTable = new JTable(ordersModel);
    private final JTable linesTable = new JTable(linesModel);

    private final JButton refreshButton = new JButton("Refresh Orders");
    private final JLabel countLabel = new JLabel("Orders loaded: 0");
    private final JLabel detailLabel = new JLabel("Select an order");
    private final JLabel totalLabel = new JLabel("Order Total: 0.00");

    // Prevent stale background results from overwriting a newer selection.
    private int detailRequest = 0;

    public MasterDetailPanel() {
        setLayout(new BorderLayout(8, 8));
        setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        ordersTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        ordersTable.setAutoCreateRowSorter(true);

        // Increase part name column width for readability.
        linesTable.getColumnModel().getColumn(0).setPreferredWidth(60);
        linesTable.getColumnModel().getColumn(1).setPreferredWidth(120);
        linesTable.getColumnModel().getColumn(2).setPreferredWidth(330);
        linesTable.getColumnModel().getColumn(3).setPreferredWidth(120);
        linesTable.getColumnModel().getColumn(4).setPreferredWidth(70);
        linesTable.getColumnModel().getColumn(5).setPreferredWidth(90);
        linesTable.getColumnModel().getColumn(6).setPreferredWidth(100);

        JPanel toolbar = new JPanel(new FlowLayout(FlowLayout.LEFT));
        toolbar.add(refreshButton);
        toolbar.add(countLabel);

        JPanel masterPanel = new JPanel(new BorderLayout(5, 5));
        masterPanel.setBorder(BorderFactory.createTitledBorder("Orders"));
        masterPanel.add(toolbar, BorderLayout.NORTH);
        masterPanel.add(new JScrollPane(ordersTable), BorderLayout.CENTER);

        JPanel detailPanel = new JPanel(new BorderLayout(5, 5));
        detailPanel.setBorder(
                BorderFactory.createTitledBorder("Order Lines")
        );
        detailPanel.add(detailLabel, BorderLayout.NORTH);
        detailPanel.add(new JScrollPane(linesTable), BorderLayout.CENTER);
        detailPanel.add(totalLabel, BorderLayout.SOUTH);

        JSplitPane splitPane = new JSplitPane(
                JSplitPane.VERTICAL_SPLIT,
                masterPanel,
                detailPanel
        );
        splitPane.setResizeWeight(0.5);
        add(splitPane, BorderLayout.CENTER);

        refreshButton.addActionListener(event -> loadOrders());

        ordersTable.getSelectionModel().addListSelectionListener(event -> {
            if (event.getValueIsAdjusting()) {
                return;
            }

            int selectedRow = ordersTable.getSelectedRow();

            if (selectedRow >= 0) {
                int modelRow =
                        ordersTable.convertRowIndexToModel(selectedRow);

                int orderId =
                        ((Number) ordersModel.getValueAt(modelRow, 0))
                                .intValue();

                loadOrderLines(orderId);
            }
        });

        loadOrders();
    }

    private static DefaultTableModel createModel(String... columns) {
        return new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
    }

    private void loadOrders() {
        refreshButton.setEnabled(false);
        ordersTable.setEnabled(false);

        detailRequest++;

        ordersTable.clearSelection();
        ordersModel.setRowCount(0);
        linesModel.setRowCount(0);

        countLabel.setText("Loading orders...");
        detailLabel.setText("Select an order");
        totalLabel.setText("Order Total: 0.00");

        // Run query in a background thread to keep the Swing UI responsive.
        new SwingWorker<List<Object[]>, Void>() {
            @Override
            protected List<Object[]> doInBackground() throws Exception {
                String sql = """
                        SELECT o.OrderID, o.OrderDate, o.OrderStatus,
                               o.CustomerID, c.Name AS CustomerName
                        FROM ORDERS o
                        JOIN CUSTOMER c ON o.CustomerID = c.CustomerID
                        ORDER BY o.OrderID
                        """;

                List<Object[]> rows = new ArrayList<>();

                try (Connection connection = DBConnection.getConnection();
                     PreparedStatement statement =
                             connection.prepareStatement(sql);
                     ResultSet result = statement.executeQuery()) {

                    while (result.next()) {
                        rows.add(new Object[]{
                            result.getInt("OrderID"),
                            result.getDate("OrderDate"),
                            result.getString("OrderStatus"),
                            result.getInt("CustomerID"),
                            result.getString("CustomerName")
                        });
                    }
                }

                return rows;
            }

            @Override
            protected void done() {
                try {
                    for (Object[] row : get()) {
                        ordersModel.addRow(row);
                    }

                    countLabel.setText(
                            "Orders loaded: " + ordersModel.getRowCount()
                    );

                    if (ordersModel.getRowCount() > 0) {
                        ordersTable.setRowSelectionInterval(0, 0);
                    } else {
                        detailLabel.setText("No orders found");
                    }
                } catch (Exception exception) {
                    countLabel.setText("Failed to load orders");
                    showError(exception);
                } finally {
                    refreshButton.setEnabled(true);
                    ordersTable.setEnabled(true);
                }
            }
        }.execute();
    }

    private void loadOrderLines(int orderId) {
        final int request = ++detailRequest;

        linesModel.setRowCount(0);
        detailLabel.setText(
                "Order ID: " + orderId + " | Loading..."
        );
        totalLabel.setText("Order Total: 0.00");

        new SwingWorker<List<Object[]>, Void>() {
            @Override
            protected List<Object[]> doInBackground() throws Exception {
                String sql = """
                        SELECT ol.LineNumber, ol.Code, p.Name AS PartName,
                               p.Brand, ol.Quantity, ol.Price,
                               (ol.Quantity * ol.Price) AS LineTotal
                        FROM ORDER_LINE ol
                        JOIN PART p ON ol.Code = p.Code
                        WHERE ol.OrderID = ?
                        ORDER BY ol.LineNumber
                        """;

                List<Object[]> rows = new ArrayList<>();

                try (Connection connection = DBConnection.getConnection();
                     PreparedStatement statement =
                             connection.prepareStatement(sql)) {

                    // Bind OrderID as a parameter instead of concatenating SQL strings.
                    statement.setInt(1, orderId);

                    try (ResultSet result = statement.executeQuery()) {
                        while (result.next()) {
                            rows.add(new Object[]{
                                result.getInt("LineNumber"),
                                result.getString("Code"),
                                result.getString("PartName"),
                                result.getString("Brand"),
                                result.getInt("Quantity"),
                                result.getBigDecimal("Price"),
                                result.getBigDecimal("LineTotal")
                            });
                        }
                    }
                }

                return rows;
            }

            @Override
            protected void done() {
                // Ignore result if the user has already selected a different order.
                if (request != detailRequest) {
                    return;
                }

                try {
                    BigDecimal total = BigDecimal.ZERO;
                    List<Object[]> rows = get();

                    for (Object[] row : rows) {
                        linesModel.addRow(row);

                        // LineTotal is at column index 6 after Brand.
                        total = total.add((BigDecimal) row[6]);
                    }

                    detailLabel.setText(
                            "Order ID: " + orderId
                            + " | Lines: " + rows.size()
                    );

                    totalLabel.setText(
                            "Order Total: "
                            + total.setScale(2).toPlainString()
                    );
                } catch (Exception exception) {
                    detailLabel.setText(
                            "Order ID: " + orderId
                            + " | Failed to load lines"
                    );
                    showError(exception);
                }
            }
        }.execute();
    }

    private void showError(Exception exception) {
        Throwable cause = exception;

        while (cause.getCause() != null) {
            cause = cause.getCause();
        }

        JOptionPane.showMessageDialog(
                this,
                cause.getMessage(),
                "Database Error",
                JOptionPane.ERROR_MESSAGE
        );
    }
}