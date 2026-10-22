package com.group05.autoparts.ui;

import javax.swing.*;
import java.awt.*;

/**
 * Assigned Role: B3 (Master-Detail UI)
 * Description: Master-Detail form: Upper grid (ORDERS) loads lower grid (ORDER_LINE).
 */
public class MasterDetailPanel extends JPanel {
    public MasterDetailPanel() {
        setLayout(new BorderLayout());
        add(new JLabel("MasterDetailPanel - Assigned to B3 (Master-Detail UI)", SwingConstants.CENTER), BorderLayout.CENTER);
    }
}
