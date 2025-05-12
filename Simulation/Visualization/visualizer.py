import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os

# --- Configuration and File Handling ---
if len(sys.argv) < 2:
    print("Usage: python visualize_sim_data.py <simulation_run_id>")
    sys.exit(1)

simulation_run_id = sys.argv[1]
file_name = "simulation_data-" + simulation_run_id + ".csv"
godot_user_data_path = os.path.join(os.getenv('APPDATA', ''), 'Godot', 'app_userdata', 'Simulation') # Adjust 'Simulation' if your project name differs
data_file = os.path.join(godot_user_data_path, file_name)
OUTPUT_DIR = f'PLOTS/simulation_plots_run_{simulation_run_id}/'

try:
    with open(data_file, 'r') as f:
        pass
    print(f"Data file found: {data_file}")
except FileNotFoundError:
    print(f"Error: File {data_file} not found.")
    sys.exit(1)
except Exception as e:
    print(f"Error accessing file: {e}")
    sys.exit(1)

if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)
    print(f"Created output directory: {OUTPUT_DIR}")

GENE_NAMES = ['size', 'speed', 'food_preference', 'stealth', 'detection', 'mating_rate']
# --- Helper Function for Saving Plots (no change needed here if titles are okay) ---
def plot_and_save(figure, filename_suffix, title_prefix):
    full_title = f"{title_prefix} (Run ID: {simulation_run_id})"
    filename = f"{filename_suffix}_run_{simulation_run_id}.png"
    plt.suptitle(full_title, fontsize=16)
    figure.tight_layout(rect=[0, 0, 1, 0.96]) # Adjust for suptitle
    plt.savefig(os.path.join(OUTPUT_DIR, filename))
    print(f"Saved plot: {os.path.join(OUTPUT_DIR, filename)}")
    plt.close(figure)

# --- Data Loading and Preprocessing ---
try:
    df = pd.read_csv(data_file)
except Exception as e:
    print(f"Error reading CSV file '{data_file}': {e}")
    sys.exit(1)

if df.empty:
    print(f"Warning: The data file '{data_file}' is empty.")
    sys.exit(0)

# IMPORTANT: Add 'vore_type' to required_cols if it's logged directly
# and remove 'food_preference' from GENE_NAMES if it's *only* used to derive vore_type
# and you don't want to plot its average separately.
# For now, assuming 'vore_type' column exists and 'food_preference' is still a gene to plot.
required_cols = ['timestamp', 'animal_id', 'vore_type', 'age'] + GENE_NAMES
missing_cols = [col for col in required_cols if col not in df.columns]
if missing_cols:
    print(f"Error: CSV file '{data_file}' is missing required columns: {', '.join(missing_cols)}")
    print(f"Available columns: {', '.join(df.columns)}")
    sys.exit(1)

try:
    df['timestamp'] = pd.to_numeric(df['timestamp'])
except ValueError:
    print("Error: 'timestamp' column could not be converted to numeric. Please check data.")
    sys.exit(1)

# Filter data by expected timestamp range (adjust as necessary)
# MAX_EXPECTED_TIMESTAMP = 20000
# df_filtered = df[df['timestamp'] <= MAX_EXPECTED_TIMESTAMP].copy() # Use .copy() to avoid SettingWithCopyWarning
df_filtered = df
# if len(df_filtered) < len(df):
#     print(f"Warning: Filtered out {len(df) - len(df_filtered)} rows with timestamps > {MAX_EXPECTED_TIMESTAMP}")
# if df_filtered.empty:
#     print(f"No data remains after filtering for timestamps <= {MAX_EXPECTED_TIMESTAMP}.")
#     sys.exit(0)


# If vore_type is logged as integers (e.g., 0, 1, 2), map them to strings here
# Assuming your Rust VoreType enum maps: Carnivore=0, Herbivore=1, Omnivore=2 (ADJUST THIS MAP)
# vore_type_mapping = {
#     0: 'Carnivore',
#     1: 'Herbivore',
#     2: 'Omnivore'
# }
# Make sure the 'vore_type' column from CSV is of integer type if using map
# df_filtered['vore_type_str'] = df_filtered['vore_type'].map(vore_type_mapping)
# If it's already logged as "Carnivore", "Herbivore", "Omnivore" strings, no mapping needed.
# For the purpose of this example, let's assume it's already a string.

print("--- Data Info After Preprocessing ---")
print(f"Filtered data shape: {df_filtered.shape}")
print(f"Timestamp unique values count: {df_filtered['timestamp'].nunique()}")
if not df_filtered.empty:
    print(f"Timestamp min: {df_filtered['timestamp'].min()}, max: {df_filtered['timestamp'].max()}")
print(df_filtered.head())
print("Vore type counts in filtered data:")
print(df_filtered['vore_type'].value_counts())
print("------------------------------------")

# --- Visualization Functions ---

def plot_vore_type_distribution(data):
    if data.empty:
        print("Plot Vore Types: No data.")
        return
    
    # Use the logged 'vore_type' column directly
    # Ensure 'vore_type' column exists and has the correct string/categorical data
    vore_counts = data.groupby(['timestamp', 'vore_type']).size().unstack(fill_value=0)
    print("--- Vore Counts for Plot (Head) ---")
    print(vore_counts.head())
    print("----------------------------------")

    total_population_per_timestamp = vore_counts.sum(axis=1)
    if total_population_per_timestamp.empty:
        print("Plot Vore Types: No population data after grouping.")
        return
        
    vore_percentages = vore_counts.divide(total_population_per_timestamp.replace(0, np.nan), axis=0).fillna(0) * 100
    print("--- Vore Percentages for Plot (Head) ---")
    print(vore_percentages.head())
    print("---------------------------------------")

    if vore_percentages.empty:
        print("Plot Vore Types: No percentage data to plot.")
        return

    fig, ax = plt.subplots(figsize=(12, 7))
    # Define colors to ensure consistency if some types are missing at times
    vore_order = ['Herbivore', 'Omnivore', 'Carnivore'] # Define expected order
    # Reindex to ensure all types are present, fill missing with 0
    vore_percentages = vore_percentages.reindex(columns=vore_order, fill_value=0)

    vore_percentages.plot(kind='line', ax=ax) # Use 'area' for stacked plot
    ax.set_title('Vore Type Distribution Over Time')
    ax.set_xlabel('Timestamp (Simulation Turn)')
    ax.set_ylabel('Percentage of Population (%)')
    ax.legend(title='Vore Type')
    ax.grid(True, linestyle='--', alpha=0.7)
    ax.set_ylim(0, 100) # Percentages are 0-100
    plot_and_save(fig, 'vore_type_distribution', 'Population Dynamics: Vore Types')

def plot_gene_averages(data):
    if data.empty:
        print("Plot Gene Averages: No data.")
        return

    gene_averages = data.groupby('timestamp')[GENE_NAMES].mean()
    print("--- Gene Averages for Plot (Head) ---")
    print(gene_averages.head())
    print("------------------------------------")
    if gene_averages.empty:
        print("Plot Gene Averages: No average data to plot.")
        return

    num_genes = len(GENE_NAMES)
    if num_genes == 0: return

    n_cols = 3 if num_genes > 2 else num_genes
    n_rows = (num_genes + n_cols - 1) // n_cols

    fig, axes = plt.subplots(nrows=n_rows, ncols=n_cols, figsize=(15, 4 * n_rows), sharex=True, squeeze=False)
    axes = axes.flatten()

    plotted_something = False
    for i, gene in enumerate(GENE_NAMES):
        if gene in gene_averages.columns:
            gene_averages[gene].plot(ax=axes[i], kind='line', marker='.', linestyle='-')
            axes[i].set_title(f'Average {gene.replace("_", " ").title()}')
            axes[i].set_ylabel('Average Gene Value')
            axes[i].grid(True, linestyle='--', alpha=0.7)
            axes[i].set_ylim(0, 1)
            if i // n_cols == n_rows -1 :
                axes[i].set_xlabel('Timestamp (Simulation Turn)')
            plotted_something = True
        else:
            print(f"Warning: Gene '{gene}' not found in averaged data.")


    for j in range(i + 1, len(axes)):
        fig.delaxes(axes[j])
    
    if plotted_something:
        plot_and_save(fig, 'gene_averages', 'Evolutionary Trends: Average Gene Values')
    else:
        print("Plot Gene Averages: Nothing was plotted.")
        plt.close(fig)


def plot_gene_correlation_heatmap(data):
    if data.empty or len(data) < 2:
        print("Plot Correlation: Not enough data (need at least 2 rows).")
        return

    last_timestamp = data['timestamp'].max()
    data_last_timestamp = data[data['timestamp'] == last_timestamp]
    print(f"--- Correlation Heatmap Debug ---")
    print(f"Last timestamp for correlation: {last_timestamp}")
    print(f"Number of animals at last timestamp: {len(data_last_timestamp)}")

    if len(data_last_timestamp) < 2:
        print(f"Plot Correlation: Not enough animals at last timestamp ({last_timestamp}) (need at least 2).")
        print("-------------------------------")
        return

    gene_data = data_last_timestamp[GENE_NAMES]
    
    # Check for columns with zero variance
    variance = gene_data.var()
    constant_cols = variance[variance == 0].index.tolist()
    if constant_cols:
        print(f"Warning: Constant gene columns at last timestamp (will result in NaN in correlation): {constant_cols}")
        # Optionally remove constant columns, or let .corr() handle it (it produces NaNs)
        # gene_data = gene_data.drop(columns=constant_cols)
        # if gene_data.shape[1] < 2:
        #     print("Plot Correlation: Not enough varying genes for correlation after removing constant columns.")
        #     print("-------------------------------")
        #     return

    if gene_data.shape[1] < 2: # Need at least two columns for correlation
        print("Plot Correlation: Not enough gene columns to compute correlation.")
        print("-------------------------------")
        return

    correlation_matrix = gene_data.corr()
    print("Correlation matrix:")
    print(correlation_matrix)
    print("-------------------------------")

    # Check if correlation matrix has any non-NaN values to plot
    if correlation_matrix.isnull().all().all():
        print("Plot Correlation: Correlation matrix is all NaN. Cannot plot heatmap.")
        return

    fig, ax = plt.subplots(figsize=(10, 8))
    sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', fmt=".2f", linewidths=.5, ax=ax, vmin=-1, vmax=1)
    ax.set_title(f'Gene Correlation Matrix (at Final Timestamp: {last_timestamp})')
    plt.xticks(rotation=45, ha='right')
    plt.yticks(rotation=0)
    plot_and_save(fig, 'gene_correlation_heatmap', 'Genetic Linkages: Gene Correlation')

# --- Main Execution ---
if __name__ == "__main__":
    print(f"Processing data for simulation run ID: {simulation_run_id} from file: {data_file}")
    
    plot_vore_type_distribution(df_filtered.copy())
    plot_gene_averages(df_filtered.copy())
    plot_gene_correlation_heatmap(df_filtered.copy())

    print(f"\nAll plots saved to '{os.path.abspath(OUTPUT_DIR)}' directory.")