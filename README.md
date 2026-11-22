
# Cart Abandonment Analysis: where an online store loses its money

> **44% of items added to a cart are never bought, worth about 92.6M in cart value. Electronics alone holds 82.5% of it.**
> End-to-end analysis of 628K cart items from a multi-category online store, built with Python, DuckDB, SQL and Power BI.

**Skills shown:** SQL (CTEs, joins, CASE logic) · Python · DuckDB on multi-GB data · data cleaning and validation · funnel analysis · metric definition · Power BI and DAX · business recommendations

<img width="1377" height="733" alt="01_overview png" src="https://github.com/user-attachments/assets/80f29c37-bd5e-4c46-8bb2-e12607c9b255" />
---

## 1. The business question

An online store sees many shoppers add items to their cart and then leave without buying. The manager's question:

> **How much money are we losing to abandoned carts, where is it leaking, and what should we fix first?**

## 2. Key findings

| # | Finding | Number |
|---|---|---|
| 1 | Share of cart items never bought | **44.0%** (276,061 of 628,109 items) |
| 2 | Cart value at risk | **about 92.6M** (store currency) |
| 3 | Where the money sits | **Electronics: 76.4M, 82.5% of the total** |
| 4 | Cheap items leak most | **Under 20: 59.5%** abandoned, against 40.9% for items priced 100 to 300 |
| 5 | Mid-afternoon rise | **About 49% at 15:00 to 18:00 UTC**, against about 41% in the morning (the highest among busy hours) |
| 6 | Funnel | 6.2% of viewing sessions add to cart; 50.9% of cart sessions also include a purchase |

**What recovery could be worth** (scenarios, not forecasts; cart value, not profit)

| Share of the 92.6M recovered | Value |
|---|---|
| 5% | about 4.6M |
| 10% | about 9.3M |
| 15% | about 13.9M |

Targeted levers: each 1-point drop in electronics abandonment is worth about 1.9M, and bringing the 15:00 to 18:00 UTC window down to the morning rate is worth roughly 3M (rough estimate at the average item price).

## 3. Dashboard

Three Power BI pages: **Overview**, **Where and when** and **Recovery what-if**. The method, definitions, data issues and limitations are documented in this README.

<img width="1377" height="733" alt="01_overview png" src="https://github.com/user-attachments/assets/a73c09f3-74f0-425c-84e1-4f849fcd61f4" />
<img width="1377" height="732" alt="02_where_and_when png" src="https://github.com/user-attachments/assets/70d718ce-2c9d-49b7-b8c1-8f01fe1be8fd" />

<img width="1375" height="745" alt="03_recovery_what_if png" src="https://github.com/user-attachments/assets/5ebd826c-ace9-4339-8d0f-bea09c871d2d" />





## 4. Recommendations

1. **Retarget high-value electronics carts first.** 82.5% of the money at risk sits there, so reminder emails or retargeting ads for carts above a value threshold have the largest payoff. Track: electronics abandonment rate (41.0% today).
2. **A/B test a timed nudge at 15:00 to 18:00 UTC.** Abandonment is about 49% in that window against 41% in the morning, the highest among busy hours. Track: abandonment rate for carts started in the window.
3. **Treat cheap items as impulse adds.** Items under 20 are abandoned 59% of the time. Try quick checkout or a bundle offer instead of a discount. This is a hypothesis: the data shows where people leave, not why, so it needs testing.

## 5. Data

- **Source:** [eCommerce behavior data from a multi-category store](https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store) (Kaggle, `mkechinov`).
- **Used:** one month of events ([MONTH YEAR]), several GB of raw CSV.
- **Columns:** `event_time`, `event_type` (view, cart, remove_from_cart, purchase), `product_id`, `category_code`, `brand`, `price`, `user_id`, `user_session`.
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
- Prices are in the dataset's own currency, which is not stated.
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
01-cart-abandonment/
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
git clone https://github.com/[YOUR-USERNAME]/cart-abandonment-analysis.git
cd cart-abandonment-analysis
pip install -r requirements.txt

# 1. download one month of data from Kaggle into data/raw/ (see PUT_DATA_HERE.txt)
# 2. clean and load it
python notebooks/01_load_and_clean.py data/raw/[FILE-NAME].csv

# 3. run the analysis; results land in data/processed/results/
python notebooks/run_sql.py sql/02_funnel.sql
python notebooks/run_sql.py sql/03_abandonment.sql
```

Then open `dashboard/cart_abandonment.pbix` and refresh the data source paths.

## 13. About me

**Taranum M Patel** · aspiring data analyst · 
www.linkedin.com/in/taranum-patel · taranum14patel@gmail.com
