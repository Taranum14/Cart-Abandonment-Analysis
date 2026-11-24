# Cart Abandonment Analysis

**44% of cart items are never bought, and electronics holds 82.5% of the value at risk (about 92.6M currency units).**

End-to-end analysis of 628K cart items from a multi-category online store (October 2019), built with Python, DuckDB, SQL and Power BI.

> **Why 44.0% and not 51.5%?** 51.5% counts an item as abandoned if it was not bought in the same visit. 44.0% also counts later purchases by the same user, so it is the fairer number and the one used throughout this project.

![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)
![DuckDB](https://img.shields.io/badge/DuckDB-SQL-FFF000?logo=duckdb&logoColor=black)
![SQL](https://img.shields.io/badge/SQL-analysis-336791)
![Power BI](https://img.shields.io/badge/Power%20BI-dashboard-F2C811?logo=powerbi&logoColor=black)

![Overview dashboard page](dashboard/screenshots/01_overview.png)

**Quick links:** [Key findings](#2-key-findings) · [Recommendations](#3-recommendations) · [Dashboard](#4-dashboard) · [Data issues found](#8-data-issues-found-and-fixed) · [How to reproduce](#12-how-to-reproduce)

| At a glance | |
|---|---|
| **Data** | One month (October 2019) of shopper clicks from a multi-category store: 9.24M sessions viewed products, 628K items were added to carts |
| **Tools** | Python, DuckDB, SQL, Power BI, DAX |
| **Output** | A three-page dashboard, three recommendations, and recovery scenarios |
| **Skills shown** | SQL (CTEs, joins, CASE logic) · multi-GB data handling · data cleaning and validation · funnel analysis · metric definition · DAX · business recommendations |

**60-second summary**
- **Problem:** a large share of carted items never turn into sales.
- **Finding:** 44% are never bought. Electronics holds 82.5% of the value at risk, cheap items under 20 leak most (59.5%), and mid-afternoon abandonment is higher.
- **Action:** retarget high-value electronics carts first, A/B test a nudge in the afternoon window, and investigate cheap items before spending on discounts.

---

## 1. The business question

An online store sees many shoppers add items to their cart and then leave without buying. The manager's question:

> **How much money are we losing to abandoned carts, where is it leaking, and what should we fix first?**

## 2. Key findings

All money figures are in the dataset's own currency units. The source does not state a currency, so "92.6M" means 92.6 million of those units.

| # | Finding | Number |
|---|---|---|
| 1 | Share of cart items never bought | **44.0%** (276,061 of 628,109 items) |
| 2 | Cart value at risk | **about 92.6M currency units** |
| 3 | Where the money sits | **Electronics: 76.4M, 82.5% of the total** |
| 4 | Cheap items leak most | **Under 20: 59.5%** abandoned, against 40.9% for items priced 100 to 300 |
| 5 | Mid-afternoon rise | **About 49% at 15:00 to 18:00 UTC**, against about 41% in the morning (the highest among busy hours) |
| 6 | Funnel | 6.2% of viewing sessions add to cart; 50.9% of cart sessions also include a purchase |

**Strict against final abandonment:** the same-visit (strict) view gives 51.5% and the final view gives 44.0%. The 7.5-point gap is roughly 47K items that people carted in one visit and bought in a later one.

**What recovery could be worth** (scenarios, not forecasts; cart value, not profit)

| Share of the 92.6M recovered | Value (currency units) |
|---|---|
| 5% | about 4.6M |
| 10% | about 9.3M |
| 15% | about 13.9M |

## 3. Recommendations

| # | Recommendation | Evidence | Size of the prize | How to measure it |
|---|---|---|---|---|
| 1 | **Retarget high-value electronics carts first.** Use reminder emails or retargeting ads for carts above a value threshold. | 82.5% of the value at risk (76.4M of 92.6M) is in electronics, where 41.0% of carts are abandoned. | Each 1-point drop in electronics abandonment is worth about 1.9M (76.4M ÷ 41.0 points). | Electronics abandonment rate (41.0% today) |
| 2 | **A/B test a timed nudge at 15:00 to 18:00 UTC.** Try a reminder or small incentive inside that window only. | Abandonment is about 49% in that window against about 41% in the morning, across 113K carts. | About 3M if the window matched the morning rate (113K carts × about 8-point gap × average abandoned-item value of about 335). A rough estimate. | Abandonment rate for carts started in the window |
| 3 | **Test quick checkout or a bundle offer for cheap items** instead of a discount. | Items under 20 are abandoned 59.5% of the time, against 40.9% for items priced 100 to 300. | Not sized: the reason is unknown, so this is a hypothesis to test. | Abandonment rate for items under 20 |

**How to prioritise:** start with recommendation 1, because it is where the money is. Recommendation 2 is cheap to test. Recommendation 3 needs investigation first, because the data shows where people leave, not why.

## 4. Dashboard

Three Power BI pages:
- **Overview** (shown at the top): headline abandonment, value at risk and the funnel.
- **Where and when:** abandonment by category, price band and hour.
- **Recovery what-if:** what 5%, 10% and 15% recovery would be worth.

![Where and when](dashboard/screenshots/02_where_and_when.png)
![Recovery what-if](dashboard/screenshots/03_recovery_what_if.png)

Files: [`dashboard/cart_abandonment.pbix`](dashboard/cart_abandonment.pbix) · [PDF export](dashboard/cart_abandonment.pdf) · [DAX measures](dashboard/dax_measures.md)

## 5. Data

- **Source:** [eCommerce behavior data from a multi-category store](https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store) (Kaggle, `mkechinov`). Data credit goes to the dataset's author.
- **Used:** one month of events (**October 2019**, file `2019-Oct.csv`), several GB of raw CSV.
- **Columns:** `event_time`, `event_type` (view, cart, remove_from_cart, purchase), `product_id`, `category_code`, `brand`, `price`, `user_id`, `user_session`.
- **Currency:** the dataset does not state one, so money figures are in the dataset's own currency units.
- The raw file is not in this repo because of its size. See [`data/raw/PUT_DATA_HERE.txt`](data/raw/PUT_DATA_HERE.txt) to download it. Check the dataset's licence on Kaggle before reusing it.

## 6. Approach

```
Raw CSV (millions of rows)
   -> 01_load_and_clean.py   clean in DuckDB, save an `events` table
   -> sql/02_funnel.sql      session funnel, overall and by category
   -> sql/03_abandonment.sql one row per carted item, flagged abandoned or bought
   -> run_sql.py             runs the SQL, saves each result as a CSV
   -> Power BI               three-page dashboard built from those CSVs
```

**Why DuckDB:** pandas would try to load several GB into memory. DuckDB reads the file in chunks and runs SQL quickly on a normal laptop.

**Cleaning steps and why**

| Step | Why |
|---|---|
| Remove exact duplicate rows | Duplicates inflate views, carts and purchases |
| Drop rows with price of zero or below | Errors or test data that distort revenue |
| Drop rows with no `user_session` | The session is the key for building a funnel |
| Keep only the four event types | Nothing unexpected enters the analysis |
| Missing brand becomes `unknown` | Keeps those rows instead of silently losing them |
| Main category taken from `category_code` | `electronics.smartphone` becomes `electronics`, easier to chart |

## 7. Metric definitions

- **Cart item:** one product added to the cart in one session.
- **Abandoned (final, the headline):** the same user never bought that product at or after the time it was carted, anywhere in the data period.
- **Abandoned (strict, the upper bound):** the product was not bought in the same session.
- **Revenue at risk:** total price of abandoned cart items.

I report both because shoppers often cart in one visit and buy in a later one. The strict view says 51.5%, the final view says 44.0%, a gap of about 7.5 points (roughly 47K items bought in a later visit).

## 8. Data issues found and fixed

1. **The first funnel showed an impossible 110% cart-to-purchase rate.** 54% of purchasing sessions (338K of 630K) had no cart event in that visit, so dividing all purchases by carts broke the logic. Fixed by counting only sessions that carted and then bought, and by reporting "purchased without cart" separately.
2. **Missing category codes.** About 3.4M sessions viewed products with no category code. They sit in an `unknown` category, about 12% of cart items, and are read with care.
3. **Missing brands** were set to `unknown` so the rows stay in.
4. **No quantity field,** so each cart item is counted once at its price.

## 9. Limitations

- One month of one store, so results may not generalise.
- Carts made late in the month may still be bought after the data ends, so abandonment is slightly overstated.
- Prices are in the dataset's own currency units, and the source does not say which currency.
- Hours are in UTC, and the store's location is unknown.
- Hours 0 and 1 have the highest rates (about 53%) but fewer than 6K carts each, so the afternoon is the highest among hours with real volume.
- The data shows when and where people leave, not why. The price and time findings are hypotheses to test.
- Small categories such as kids and sport have under 2,000 carts each, so their rates are weak evidence.

## 10. What I would do next

- Run the analysis across several months and check that the patterns hold.
- Split by new against returning users, and by device if the data allows.
- Test the recommendations with an A/B experiment and measure real lift.
- Add time-to-purchase analysis to see how long carted items take to convert.

## 11. Repository structure

```
Cart-Abandonment-Analysis/
├── README.md                    this file
├── requirements.txt             Python libraries
├── .gitignore                   keeps the multi-GB CSV and database out of Git
├── data/
│   ├── raw/PUT_DATA_HERE.txt    where to download and place the dataset
│   └── processed/results/       small result CSVs that feed the dashboard
├── notebooks/
│   ├── 00_make_sample_data.py   tiny fake dataset to test the pipeline (not used for results)
│   ├── 01_load_and_clean.py     loads the CSV into DuckDB and cleans it
│   └── run_sql.py               runs a .sql file and saves each result as a CSV
├── sql/
│   ├── 02_funnel.sql            view -> cart -> purchase funnel, overall and by category
│   └── 03_abandonment.sql       cart outcomes, revenue at risk, by category, hour and price band
└── dashboard/
    ├── cart_abandonment.pbix    Power BI file
    ├── cart_abandonment.pdf     export of all three pages
    ├── dax_measures.md          the DAX measures used
    └── screenshots/             images used in this README
```

## 12. How to reproduce

```bash
git clone https://github.com/Taranum14/Cart-Abandonment-Analysis.git
cd Cart-Abandonment-Analysis
pip install -r requirements.txt

# 1. download 2019-Oct.csv from Kaggle into data/raw/ (see PUT_DATA_HERE.txt)
# 2. clean and load it
python notebooks/01_load_and_clean.py data/raw/2019-Oct.csv

# 3. run the analysis; results land in data/processed/results/
python notebooks/run_sql.py sql/02_funnel.sql
python notebooks/run_sql.py sql/03_abandonment.sql
```

Then open `dashboard/cart_abandonment.pbix` and refresh the data source paths.

## 13. About me

**Taranum M Patel** · aspiring data analyst
[LinkedIn](https://www.linkedin.com/in/taranum-patel) · taranum14patel@gmail.com
