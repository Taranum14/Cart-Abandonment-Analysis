# DAX measures used in the dashboard

All measures are in the Power BI file `cart_abandonment.pbix`. Create each one separately, as a single line. Table names `Headline`, `Category`, `Hour`, `PriceBand`, `Funnel`, `Scenario` and `Recovery Rate` come from the CSV result files in `data/processed/results/`.

`Hour` is also a DAX function name, so the table is always written in single quotes: `'Hour'`.

## Headline (page 1)

```
Abandonment Rate % = DIVIDE(SUM(Headline[abandoned_final_items]), SUM(Headline[cart_items]))
Revenue at Risk (total) = SUM(Headline[revenue_at_risk_final])
Cart Items = SUM(Headline[cart_items])
Items Abandoned = SUM(Headline[abandoned_final_items])
Strict Rate % = DIVIDE(SUM(Headline[abandoned_strict_items]), SUM(Headline[cart_items]))
Definition Gap (pts) = ([Strict Rate %] - [Abandonment Rate %]) * 100
```

`Strict Rate %` and `Definition Gap (pts)` are supporting measures. They are not shown on a dashboard page, and their figures (51.5% and 7.5 points) are explained in the README.

## Category (pages 1 and 2)

```
Revenue at Risk = SUM(Category[revenue_at_risk])
Revenue at Risk (M) = DIVIDE(SUM(Category[revenue_at_risk]), 1000000)
Revenue Share = DIVIDE(SUM(Category[revenue_at_risk]), SUM(Headline[revenue_at_risk_final]))
Category Carts = SUM(Category[cart_items])
Category Abandon Rate % = DIVIDE(SUMX(Category, Category[abandon_rate_final_pct] / 100 * Category[cart_items]), SUM(Category[cart_items]))
```

The rate is weighted by cart items, so totals and filtered views stay correct.

## Funnel (page 1)

Stage names must match the values in the `Funnel[Stage]` column exactly.

```
View to Cart % = DIVIDE(CALCULATE(SUM(Funnel[Sessions]), Funnel[Stage] = "Added to cart"), CALCULATE(SUM(Funnel[Sessions]), Funnel[Stage] = "Viewed a product"))
Cart to Purchase % = DIVIDE(CALCULATE(SUM(Funnel[Sessions]), Funnel[Stage] = "Bought same visit"), CALCULATE(SUM(Funnel[Sessions]), Funnel[Stage] = "Added to cart"))
```

## Hour of day (page 2)

```
Hour Carts = SUM('Hour'[cart_items])
Hour Abandon Rate % = DIVIDE(SUMX('Hour', 'Hour'[abandon_rate_final_pct] / 100 * 'Hour'[cart_items]), SUM('Hour'[cart_items]))
Peak Window Rate % = CALCULATE([Hour Abandon Rate %], 'Hour'[hour] >= 15, 'Hour'[hour] <= 18)
Morning Rate % = CALCULATE([Hour Abandon Rate %], 'Hour'[hour] >= 3, 'Hour'[hour] <= 10)
Peak vs Morning (pts) = ([Peak Window Rate %] - [Morning Rate %]) * 100
```

## Price band (page 2)

```
Band Carts = SUM(PriceBand[cart_items])
Band Abandon Rate % = DIVIDE(SUMX(PriceBand, PriceBand[abandon_rate_final_pct] / 100 * PriceBand[cart_items]), SUM(PriceBand[cart_items]))
```

Calculated column used for the axis labels (sorted by `price_band`):

```
Band Label = MID(PriceBand[price_band], 4, 20) & " · " & FORMAT(PriceBand[cart_items] / 1000, "0") & "K carts"
```

## Recovery what-if (page 3)

`Scenario` is a small typed table with `Label` (5%, 10%, 15%) and `Rate` (0.05, 0.10, 0.15). `Recovery Rate` is a What-if numeric parameter from 0 to 0.30 in steps of 0.01.

```
Scenario Value = SUM(Headline[revenue_at_risk_final]) * MAX(Scenario[Rate])
Recovered Value (slider) = SUM(Headline[revenue_at_risk_final]) * 'Recovery Rate'[Parameter Value]
Electronics Value per Point = DIVIDE(CALCULATE(SUM(Category[revenue_at_risk]), Category[category] = "electronics"), CALCULATE(MAX(Category[abandon_rate_final_pct]), Category[category] = "electronics"))
```

```
Afternoon Opportunity =
VAR MorningRate = CALCULATE(DIVIDE(SUMX('Hour', 'Hour'[abandon_rate_final_pct] * 'Hour'[cart_items]), SUM('Hour'[cart_items])), 'Hour'[hour] >= 3, 'Hour'[hour] <= 10)
VAR AvgPrice = DIVIDE(SUM(Headline[revenue_at_risk_final]), SUM(Headline[abandoned_final_items]))
VAR ExcessItems = SUMX(FILTER('Hour', 'Hour'[hour] >= 15 && 'Hour'[hour] <= 18), ('Hour'[abandon_rate_final_pct] - MorningRate) / 100 * 'Hour'[cart_items])
RETURN ExcessItems * AvgPrice
```

`Electronics Value per Point` and `Afternoon Opportunity` are estimates: they assume the average price of abandoned items stays constant.

## Formats

| Measure type | Format code |
|---|---|
| Percentages | `0.0%` |
| Millions with 2 decimals | `0.00"M"` |
| Plain number with 1 decimal | `0.0` |
