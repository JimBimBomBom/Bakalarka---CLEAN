import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os

# --- Configuration and File Handling --- (Copied from your script)
if len(sys.argv) < 2:
    print("Usage: python visualize_sim_data.py <simulation_run_id>")
    sys.exit(1)

simulation_run_id = sys.argv[1]
file_name = "simulation_data-" + simulation_run_id + ".csv"
# Adjust 'Simulation' if your Godot project name in app_userdata differs
godot_user_data_path = os.path.join(os.getenv('APPDATA', ''), 'Godot', 'app_userdata', 'Simulation')
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

# --- Helper Function for Saving Plots ---
def plot_and_save(figure, filename_suffix, title_prefix):
    full_title = f"{title_prefix} (Run ID: {simulation_run_id})"
    filename = f"{filename_suffix}_run_{simulation_run_id}.svg"
    plt.suptitle(full_title, fontsize=16)
    figure.tight_layout(rect=[0, 0, 1, 0.96])
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

df_filtered = df.copy() # Use a copy

# --- Vore Type Mapping (if vore_type is logged as integers) ---
# Assuming your Rust VoreType enum maps:
# Carnivore=0, Herbivore=1, Omnivore=2 (ADJUST THIS MAP to your actual logged integer values)
vore_type_mapping = {
    0: 'Carnivore',
    1: 'Herbivore',
    2: 'Omnivore'
}

# Check if 'vore_type' column is string, if so, use as is (assuming correct string values)
# If numeric, apply mapping.
if pd.api.types.is_numeric_dtype(df_filtered['vore_type']):
    df_filtered['vore_type_str'] = df_filtered['vore_type'].map(vore_type_mapping)
else:
    # Assume it's already the correct string representation
    df_filtered['vore_type_str'] = df_filtered['vore_type']

# Handle any vore_types that weren't in the mapping or were already NaN
df_filtered['vore_type_str'] = df_filtered['vore_type_str'].fillna('Unknown')


print("--- Data Info After Preprocessing ---")
print(f"Filtered data shape: {df_filtered.shape}")
print(f"Timestamp unique values count: {df_filtered['timestamp'].nunique()}")
if not df_filtered.empty:
    print(f"Timestamp min: {df_filtered['timestamp'].min()}, max: {df_filtered['timestamp'].max()}")
print(df_filtered[['timestamp', 'animal_id', 'vore_type', 'vore_type_str', 'age']].head())
print("Vore type string counts in filtered data:")
print(df_filtered['vore_type_str'].value_counts(dropna=False))
print("------------------------------------")


# --- MODIFIED Visualization Function for Vore Types ---
def plot_vore_type_population_stacked_area(data):
    if data.empty:
        print("Plot Vore Types (Stacked Area): No data.")
        return

    # Group by timestamp and vore_type_str, then count animals. This gives us the counts.
    # Use the mapped 'vore_type_str' column.
    vore_counts = data.groupby(['timestamp', 'vore_type_str']).size().unstack(fill_value=0)
    
    print("--- Vore Counts for Stacked Area Plot (Head) ---")
    print(vore_counts.head())
    print("-----------------------------------------------")

    if vore_counts.empty:
        print("Plot Vore Types (Stacked Area): No data after grouping by timestamp and vore_type_str.")
        return

    fig, ax = plt.subplots(figsize=(14, 8)) # Slightly larger figure

    # Define the order for stacking and legend, including 'Unknown' if it might appear
    vore_order = ['Herbivore', 'Omnivore', 'Carnivore']
    # Reindex columns to ensure all categories are present for plotting and legend, fill missing with 0
    vore_counts_ordered = vore_counts.reindex(columns=vore_order, fill_value=0)

    # Create the stacked area plot
    vore_counts_ordered.plot(kind='area', stacked=True, ax=ax, alpha=0.8)

    ax.set_title('Population Composition by Vore Type Over Time')
    ax.set_xlabel('Timestamp (Simulation Turn)')
    ax.set_ylabel('Total Animal Count') # Y-axis now shows total count
    ax.legend(title='Vore Type')
    ax.grid(True, linestyle='--', alpha=0.6)

    # Adjust Y-axis limit dynamically based on max total population
    if not vore_counts_ordered.empty:
        max_population = vore_counts_ordered.sum(axis=1).max()
        ax.set_ylim(0, max_population * 1.05 if max_population > 0 else 10) # Add 5% margin or default if 0
    else:
        ax.set_ylim(0,10) # Default if no data

    plot_and_save(fig, 'vore_type_stacked_area', 'Population Dynamics: Vore Type Counts')


# --- Other Plotting Functions (plot_gene_stats, plot_gene_correlation_heatmap) ---
# (Keep these as they were in your last provided script or my previous correct version)
def plot_gene_stats(data):
    if data.empty:
        print("Plot Gene Stats: No data.")
        return
    gene_stats = data.groupby('timestamp')[GENE_NAMES].agg(['mean', 'min', 'max'])
    if gene_stats.empty:
        print("Plot Gene Stats: No aggregated data (mean, min, max) to plot.")
        return
    num_genes = len(GENE_NAMES)
    if num_genes == 0: return
    n_cols = 3 if num_genes > 2 else num_genes
    n_rows = (num_genes + n_cols - 1) // n_cols
    fig, axes = plt.subplots(nrows=n_rows, ncols=n_cols, figsize=(18, 5 * n_rows), sharex=True, squeeze=False)
    axes = axes.flatten()
    plotted_something = False
    for i, gene in enumerate(GENE_NAMES):
        ax = axes[i]
        mean_col, min_col, max_col = (gene, 'mean'), (gene, 'min'), (gene, 'max')
        if mean_col in gene_stats.columns and min_col in gene_stats.columns and max_col in gene_stats.columns:
            gene_stats[mean_col].plot(ax=ax, kind='line', marker='.', linestyle='-', label='Average', color='blue', zorder=3)
            gene_stats[min_col].plot(ax=ax, kind='line', linestyle='--', label='Min', color='gray', alpha=0.7, zorder=2)
            gene_stats[max_col].plot(ax=ax, kind='line', linestyle='--', label='Max', color='gray', alpha=0.7, zorder=2)
            ax.fill_between(gene_stats.index, gene_stats[min_col], gene_stats[max_col], color='skyblue', alpha=0.3, zorder=1, label='Min-Max Range')
            ax.set_title(f'{gene.replace("_", " ").title()} (Min/Avg/Max)')
            ax.set_ylabel('Gene Value')
            ax.grid(True, linestyle='--', alpha=0.7)
            ax.set_ylim(-0.05, 1.05)
            ax.legend()
            if i // n_cols == n_rows -1 :
                ax.set_xlabel('Timestamp (Simulation Turn)')
            plotted_something = True
        else:
            print(f"Warning: Aggregated stats for gene '{gene}' not found.")
            ax.set_title(f'{gene.replace("_", " ").title()} (Data Missing)')
            ax.text(0.5, 0.5, 'Data Missing', ha='center', va='center', transform=ax.transAxes)
    for j in range(num_genes, len(axes)):
        fig.delaxes(axes[j])
    if plotted_something:
        plot_and_save(fig, 'gene_min_avg_max', 'Evolutionary Trends: Gene Value Distribution')
    else:
        print("Plot Gene Stats: Nothing was plotted.")
        plt.close(fig)

def plot_gene_correlation_heatmap(data):
    if data.empty or len(data) < 2:
        print("Plot Correlation: Not enough data (need at least 2 rows).")
        return
    last_timestamp = data['timestamp'].max()
    data_last_timestamp = data[data['timestamp'] == last_timestamp]
    if len(data_last_timestamp) < 2:
        print(f"Plot Correlation: Not enough animals at last timestamp ({last_timestamp}) (need at least 2).")
        return
    gene_data = data_last_timestamp[GENE_NAMES].copy()
    valid_cols_for_corr = [col for col in GENE_NAMES if col in gene_data.columns and gene_data[col].nunique(dropna=True) > 1]
    if len(valid_cols_for_corr) < 2:
        print("Plot Correlation: Not enough varying gene columns for correlation at last timestamp.")
        return
    gene_data_for_corr = gene_data[valid_cols_for_corr]
    correlation_matrix = gene_data_for_corr.corr()
    if correlation_matrix.isnull().all().all() or correlation_matrix.empty:
        print("Plot Correlation: Correlation matrix is all NaN or empty.")
        return
    fig, ax = plt.subplots(figsize=(10, 8))
    sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', fmt=".2f", linewidths=.5, ax=ax, vmin=-1, vmax=1)
    ax.set_title(f'Gene Correlation Matrix (Timestamp: {last_timestamp})')
    plt.xticks(rotation=45, ha='right'); plt.yticks(rotation=0)
    plot_and_save(fig, 'gene_correlation_heatmap', 'Genetic Linkages: Gene Correlation')

# --- Main Execution ---
if __name__ == "__main__":
    print(f"Processing data for simulation run ID: {simulation_run_id} from file: {data_file}")
    
    # Ensure 'vore_type_str' is correctly created and used if 'vore_type' in CSV is integer
    # The logic above assumes 'vore_type_str' is created in the preprocessing block
    plot_vore_type_population_stacked_area(df_filtered.copy())
    plot_gene_stats(df_filtered.copy())
    plot_gene_correlation_heatmap(df_filtered.copy())

    print(f"\nAll plots saved to '{os.path.abspath(OUTPUT_DIR)}' directory.")