import pandas as pd

path = "data/raw/wuenic2025rev_web-update.xlsx"

df = pd.read_excel(path, sheet_name="country")

print(df.shape)
print(df.columns.tolist())
print(df.head())
import pandas as pd

path = "data/raw/wuenic2025rev_web-update.xlsx"
df = pd.read_excel(path, sheet_name="country")

# Step 1: keep only the 6 columns we need
keep = ["iso3c", "country", "vaccine", "year", "target_grp", "coverage"]
df = df[keep]
print(df.shape)