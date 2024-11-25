import pandas as pd

df = pd.read_csv('./data_cleaned_manual_combined.csv')

# export only the questions as a text file
df['Question'].to_csv('./questions.txt', index=False, header=False)
