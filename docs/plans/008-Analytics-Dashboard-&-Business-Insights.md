# Plan 008 — Analytics Dashboard & Business Insights

Act as the CTO, Product Architect, UX Designer, and Business Intelligence Specialist.

Design an Analytics Dashboard for an offline-first Flutter POS application.

The dashboard must remain extremely simple.

Remember:

The target users are small shop owners with little accounting knowledge.

The dashboard should answer questions instantly without requiring the user to read reports.

---

## Dashboard Goals

Transform raw numbers into visual insights.

The owner should immediately understand:

* Is my business improving?
* Is today better than yesterday?
* Which products sell the most?
* Where is my money going?

---

## Time Filters

Support:

* Today
* Yesterday
* Last 7 Days
* Last 30 Days
* This Month
* Custom Date Range

Every chart must update automatically.

---

## Sales Analytics

Design visual charts for:

* Sales trend
* Daily sales
* Monthly sales
* Hourly sales (future)

Recommend the best chart type for each.

---

## Cashbox Analytics

Visualize:

* Cash In
* Cash Out
* Expenses
* Withdrawals
* Closing Balance

Recommend the most readable chart.

---

## Product Analytics

Display:

* Best selling products
* Slow moving products
* Products with low stock
* Products with highest profit

Recommend the best visualization.

---

## Customer Analytics

Display:

* Customers with highest purchases
* Customers with highest debt
* Customers with recent payments

---

## Inventory Analytics

Visualize:

* Inventory value
* Low stock products
* Stock movements
* Inventory turnover

---

## Business Health

Design a simple business health overview.

Possible indicators:

* Daily Revenue
* Estimated Profit
* Cash Balance
* Outstanding Debts
* Inventory Value

Recommend KPI cards that are understandable for non-technical users.

---

## UX Requirements

Avoid complicated BI dashboards.

No more than 5–7 key charts on the main screen.

Everything should be readable on a mobile phone.

Large touch targets.

Arabic-first RTL support.

Fast loading.

---

## Technical Analysis

Recommend:

* Flutter chart library
* Performance strategy
* Offline rendering
* Data aggregation
* Caching strategy

Analyze how to generate charts efficiently from Drift (SQLite) without slowing down the application.

---

## Future Compatibility

Prepare the architecture so future versions can support:

* Weekly reports
* Monthly reports
* AI insights
* Business recommendations
* Export charts as images
* Share charts through WhatsApp

No implementation.

Only produce a complete Product Design Plan.
