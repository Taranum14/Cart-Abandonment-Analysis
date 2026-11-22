"""Generate a SMALL FAKE sample in the same format as the Kaggle file.

This is only for testing that your code runs before you download the real data.
Never use its numbers in your README or dashboard.

Usage:
    python notebooks/00_make_sample_data.py   # writes data/raw/sample_fake.csv
"""
import random
from datetime import datetime, timedelta
from pathlib import Path

random.seed(7)
cats = ["electronics.smartphone", "appliances.kitchen", "apparel.shoes", "furniture.living_room", "computers.notebook"]
brands = ["samsung", "apple", "xiaomi", "nike", "lg", "", "acer"]
products = {i: (random.choice(cats), random.choice(brands), round(random.uniform(5, 900), 2)) for i in range(1000, 1300)}

rows = []
start = datetime(2019, 10, 1)
for s in range(5000):
    user = random.randint(1, 2000)
    sess = f"sess-{s}"
    t = start + timedelta(minutes=random.randint(0, 40000))
    for _ in range(random.randint(1, 6)):
        pid = random.choice(list(products))
        cat, brand, price = products[pid]
        t += timedelta(seconds=random.randint(5, 300))
        rows.append((t, "view", pid, cat, brand, price, user, sess))
        if random.random() < 0.25:
            t += timedelta(seconds=30)
            rows.append((t, "cart", pid, cat, brand, price, user, sess))
            if random.random() < 0.35:
                t += timedelta(seconds=60)
                rows.append((t, "purchase", pid, cat, brand, price, user, sess))

Path("data/raw").mkdir(parents=True, exist_ok=True)
with open("data/raw/sample_fake.csv", "w") as f:
    f.write("event_time,event_type,product_id,category_id,category_code,brand,price,user_id,user_session\n")
    for t, e, pid, cat, brand, price, user, sess in rows:
        f.write(f"{t:%Y-%m-%d %H:%M:%S} UTC,{e},{pid},1,{cat},{brand},{price},{user},{sess}\n")
print("rows:", len(rows))
