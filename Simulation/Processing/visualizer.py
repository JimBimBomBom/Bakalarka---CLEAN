import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

simulation_run_id = sys.argv[1] # simulation id is provided as a command line argument
file_name = "simulation_data-" + simulation_run_id + ".csv"
# NOTE: The path to the data file is hardcoded here. This is not a good practice.
data_file = "C:\\Users\\filip\\AppData\\Roaming\\Godot\\app_userdata\\Simulation\\" + file_name

df = pd.read_csv(data_file)
df_latest = df[df['timestamp'] == df['timestamp'].max()]

gene_columns = ['size', 'speed', 'food_prefference', 'mating_rate']
gene_data = df[gene_columns]
gene_data_latest = df_latest[gene_columns]


# Heatmap - showing correlation at the end of the simulation run between individual genes
corr_matrix = gene_data_latest.corr()

plt.figure(figsize=(10, 6))
sns.heatmap(corr_matrix, annot=True, cmap='coolwarm')
plt.title('Correlation Matrix of Animal Genes', color='black', fontsize=20)
plt.show()



# Scatter plot - showing the evolution of animal size over time
size_gene_avg = df.groupby('timestamp')['size'].mean().reset_index()

plt.figure(figsize=(10, 6))
sns.lineplot(data=size_gene_avg, x='timestamp', y='size')
plt.title('Average animal size over time', color='black', fontsize=20)
plt.xlabel('Timestamp', fontsize=15)
plt.ylabel('Average size', fontsize=15)
plt.show()



# Scatter plot - showing the evolution of animal speed over time
size_gene_avg = df.groupby('timestamp')['speed'].mean().reset_index()

plt.figure(figsize=(10, 6))
sns.lineplot(data=size_gene_avg, x='timestamp', y='speed')
plt.title('Average animal speed over time', color='black', fontsize=20)
plt.xlabel('Timestamp', fontsize=15)
plt.ylabel('Average speed', fontsize=15)
plt.show()



# Scatter plot - showing the evolution of animal food_prefference over time
size_gene_avg = df.groupby('timestamp')['food_prefference'].mean().reset_index()

plt.figure(figsize=(10, 6))
sns.lineplot(data=size_gene_avg, x='timestamp', y='food_prefference')
plt.title('Average food_prefference over time', color='black', fontsize=20)
plt.xlabel('Timestamp', fontsize=15)
plt.ylabel('Average food_prefference', fontsize=15)
plt.show()



# Scatter plot - showing the evolution of animal mating_rate over time
size_gene_avg = df.groupby('timestamp')['mating_rate'].mean().reset_index()

plt.figure(figsize=(10, 6))
sns.lineplot(data=size_gene_avg, x='timestamp', y='mating_rate')
plt.title('Average animal mating_rate over time', color='black', fontsize=20)
plt.xlabel('Timestamp', fontsize=15)
plt.ylabel('Average mating_rate', fontsize=15)
plt.show()



speed_hist = df_latest["speed"]

plt.figure(figsize=(10, 6))
sns.histplot(speed_hist, kde=True, bins=30, color="blue", alpha=0.6)
plt.title("Distribution of animal speed")
plt.show()
