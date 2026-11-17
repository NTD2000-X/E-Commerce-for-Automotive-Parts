package com.group05.autoparts.ui;
import com.group05.autoparts.config.DBConnection;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.io.IOException;
import java.sql.*;
import java.util.Vector;
public class AnalyticsReportPanel extends JPanel {
    private final JTable resultsTable = new JTable();
    private final JLabel rowCountLabel = new JLabel("Rows loaded: 0");
    private final JLabel statusLabel = new JLabel("Choose a report or query.");
    private final JTextField makeField = new JTextField("Toyota", 9);
    private final JTextField modelField = new JTextField("Vios", 9);
    private final JTextField yearField = new JTextField("2019", 6);
    private static final String MONTHLY_REPORT = """
        SELECT DATE_FORMAT(o.OrderDate, '%Y-%m') AS OrderMonth,
               COUNT(DISTINCT o.OrderID) AS TotalOrders,
               SUM(ol.Quantity) AS TotalItemsSold,
               SUM(ol.Quantity * ol.Price) AS MonthlyRevenue
        FROM ORDERS o
        JOIN ORDER_LINE ol ON ol.OrderID = o.OrderID
        WHERE o.OrderStatus != 'Cancelled'
        GROUP BY DATE_FORMAT(o.OrderDate, '%Y-%m')
        ORDER BY OrderMonth
        """;
    private static final String SHIPMENT_REPORT = """
        SELECT DeliveryStatus,
               COUNT(*) AS ShipmentCount,
               MIN(ShippingDate) AS EarliestShipping,
               MAX(ShippingDate) AS LatestShipping
        FROM SHIPMENT
        GROUP BY DeliveryStatus
        """;
    private static final String[] TOPIC4_SQL = {
        """
        SELECT p.Code, p.Name, p.Brand, p.UnitPrice
        FROM PART p
        INNER JOIN PART_COMPATIBILITY pc ON pc.Code = p.Code
        INNER JOIN VEHICLE_MODEL vm ON vm.ModelID = pc.ModelID
        WHERE vm.Make = ?
          AND vm.ModelName = ?
          AND vm.YearRange = ?
        """,
        """
        SELECT p.Code, p.Name, p.Brand, p.UnitPrice,
               SUM(ol.Quantity * ol.Price) AS TotalRevenue
        FROM PART p
        JOIN ORDER_LINE ol ON ol.Code = p.Code
        JOIN ORDERS o ON o.OrderID = ol.OrderID
        WHERE o.OrderDate BETWEEN '2026-07-01' AND '2026-09-30'
          AND o.OrderStatus != 'Cancelled'
        GROUP BY p.Code, p.Name, p.Brand
        ORDER BY TotalRevenue DESC
        LIMIT 10
        """,
        """
        SELECT o.OrderID, o.CustomerID, o.OrderDate
        FROM ORDERS o
        WHERE EXISTS (
            SELECT 1
            FROM ORDER_LINE ol
            JOIN PART p ON p.Code = ol.Code
            WHERE ol.OrderID = o.OrderID
              AND p.CurrentStockLevel = 0
        )
        """,
        """
        SELECT c.CustomerID, c.Name
        FROM CUSTOMER c
        WHERE NOT EXISTS (
            SELECT 1 FROM PART pb
            WHERE NOT EXISTS (
                SELECT 1
                FROM ORDERS o
                JOIN ORDER_LINE ol ON ol.OrderID = o.OrderID
                JOIN PART p ON p.Code = ol.Code
                WHERE o.CustomerID = c.CustomerID
                  AND p.Brand = pb.Brand
            )
        )
        """,
        """
        SELECT c.CategoryID, c.CategoryName,
               COUNT(p.Code) AS PartCount,
               ROUND(AVG(p.UnitPrice), 2) AS AvgPrice
        FROM CATEGORY c
        JOIN PART p ON p.CategoryID = c.CategoryID
        GROUP BY c.CategoryID, c.CategoryName
        """
    };
    public AnalyticsReportPanel() {
        setLayout(new BorderLayout(10, 10));
        setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));

        JLabel heading = new JLabel("Analytics & Query Reports");
        heading.setFont(heading.getFont().deriveFont(Font.BOLD, 20f));
        JPanel controls = new JPanel();
        controls.setLayout(new BoxLayout(controls, BoxLayout.Y_AXIS));
        controls.add(heading);
        controls.add(Box.createVerticalStrut(8));
        controls.add(buildAggregatePanel());
        controls.add(Box.createVerticalStrut(8));
        controls.add(buildTopic4Panel());
        JScrollPane controlsScroll = new JScrollPane(
                controls,
                ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED,
                ScrollPaneConstants.HORIZONTAL_SCROLLBAR_NEVER
        );
        controlsScroll.setBorder(BorderFactory.createEmptyBorder());
        controlsScroll.setPreferredSize(new Dimension(900, 205));
        add(controlsScroll, BorderLayout.NORTH);
        resultsTable.setModel(createEmptyModel());
        resultsTable.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
        resultsTable.setAutoCreateRowSorter(true);
        resultsTable.setFillsViewportHeight(true);
        resultsTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        add(new JScrollPane(resultsTable), BorderLayout.CENTER);
        JPanel footer = new JPanel(new BorderLayout(12, 0));
        footer.add(rowCountLabel, BorderLayout.WEST);
        footer.add(statusLabel, BorderLayout.CENTER);
        add(footer, BorderLayout.SOUTH);
    }
    private JPanel buildAggregatePanel() {
        JPanel panel = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 6));
        panel.setBorder(BorderFactory.createTitledBorder("Aggregate Reports"));

        JButton monthlyButton = new JButton("Monthly Order & Revenue");
        monthlyButton.addActionListener(
                e -> runQuery("Monthly Order & Revenue Report", MONTHLY_REPORT)
        );

        JButton shipmentButton = new JButton("Shipment Delivery Status");
        shipmentButton.addActionListener(
                e -> runQuery("Shipment Delivery Status Report", SHIPMENT_REPORT)
        );
        panel.add(monthlyButton);
        panel.add(shipmentButton);
        panel.setAlignmentX(Component.LEFT_ALIGNMENT);
        return panel;
    }
    private JPanel buildTopic4Panel() {
        JPanel panel = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 6));
        panel.setBorder(BorderFactory.createTitledBorder("Topic 4 Queries"));
        panel.add(new JLabel("Make:"));
        panel.add(makeField);
        panel.add(new JLabel("Model:"));
        panel.add(modelField);
        panel.add(new JLabel("Year:"));
        panel.add(yearField);
        JButton compatiblePartsButton = new JButton("1. Compatible Parts");
        compatiblePartsButton.addActionListener(e -> runVehicleQuery());
        panel.add(compatiblePartsButton);
        String[] labels = {
                "2. Top 10 Revenue",
                "3. Out-of-stock Orders",
                "4. Customers / Every Brand",
                "5. Parts by Category"
        };
        for (int i = 1; i < TOPIC4_SQL.length; i++) {
            final int queryIndex = i;
            JButton button = new JButton(labels[i - 1]);
            button.addActionListener(e ->
                    runQuery("Topic 4 Query " + (queryIndex + 1), TOPIC4_SQL[queryIndex])
            );
            panel.add(button);
        }
        panel.setAlignmentX(Component.LEFT_ALIGNMENT);
        return panel;
    }
    private void runVehicleQuery() {
        String make = makeField.getText().trim();
        String model = modelField.getText().trim();
        String year = yearField.getText().trim();
        if (make.isEmpty() || model.isEmpty() || year.isEmpty()) {
            showError("Make, Model and Year are required.");
            return;
        }
        runQuery(
                "Topic 4 Query 1 - Compatible Parts",
                TOPIC4_SQL[0],
                statement -> {
                    statement.setString(1, make);
                    statement.setString(2, model);
                    statement.setString(3, year);
                }
        );
    }
    @FunctionalInterface
    private interface ParameterBinder {
        void bind(PreparedStatement statement) throws SQLException;
    }
    private void runQuery(String title, String sql) {
        runQuery(title, sql, statement -> {
        });
    }
    private void runQuery(String title, String sql, ParameterBinder binder) {
        statusLabel.setText("Running: " + title + " ...");
        setCursor(Cursor.getPredefinedCursor(Cursor.WAIT_CURSOR));
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            binder.bind(statement);
            try (ResultSet resultSet = statement.executeQuery()) {
                displayResultSet(resultSet);
                statusLabel.setText("Completed: " + title);
            }
        } catch (SQLException | IOException exception) {
            resultsTable.setModel(createEmptyModel());
            rowCountLabel.setText("Rows loaded: 0");
            statusLabel.setText("Query failed. Check the database connection and schema.");
            showError(
                    "Unable to run " + title + ".\n"
                            + safeMessage(exception)
                            + "\n\nCheck db.properties and confirm "
                            + "database/01_schema_and_data.sql was executed."
            );
        } finally {
            setCursor(Cursor.getDefaultCursor());
        }
    }
    private void displayResultSet(ResultSet resultSet) throws SQLException {
        ResultSetMetaData metadata = resultSet.getMetaData();
        int columnCount = metadata.getColumnCount();
        Vector<String> headers = new Vector<>();
        for (int column = 1; column <= columnCount; column++) {
            headers.add(metadata.getColumnLabel(column));
        }
        Vector<Vector<Object>> rows = new Vector<>();
        while (resultSet.next()) {
            Vector<Object> row = new Vector<>();
            for (int column = 1; column <= columnCount; column++) {
                row.add(resultSet.getObject(column));
            }
            rows.add(row);
        }
        DefaultTableModel model = new DefaultTableModel(rows, headers) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        resultsTable.setModel(model);
        rowCountLabel.setText("Rows loaded: " + rows.size());
        for (int column = 0; column < columnCount; column++) {
            resultsTable.getColumnModel()
                    .getColumn(column)
                    .setPreferredWidth(160);
        }
    }
    private DefaultTableModel createEmptyModel() {
        return new DefaultTableModel(new Object[0][0], new Object[0]) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
    }
    private String safeMessage(Exception exception) {
        String message = exception.getMessage();
        return message == null
                ? exception.getClass().getSimpleName()
                : message;
    }
    private void showError(String message) {
        JOptionPane.showMessageDialog(
                this,
                message,
                "Analytics",
                JOptionPane.ERROR_MESSAGE
        );
    }
}
