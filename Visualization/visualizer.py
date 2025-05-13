import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os

# --- Global Matplotlib Aesthetics for Thesis Legibility ---
plt.rcParams.update({
    'font.size': 14,          # Base font size
    'axes.titlesize': 18,     # Title font size for individual axes
    'axes.labelsize': 16,     # X and Y label font size
    'xtick.labelsize': 12,    # X tick label font size
    'ytick.labelsize': 12,    # Y tick label font size
    'legend.fontsize': 12,    # Legend font size
    'figure.titlesize': 20,   # Figure suptitle font size
    'lines.linewidth': 2,     # Default line width
    'lines.markersize': 6     # Default marker size
})

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

# --- Helper Function for Saving Plots ---
def plot_and_save(figure, filename_suffix, title_prefix, is_single_plot=False):
    # For single plots, suptitle acts as the main title. For multi-plots, it's an overall title.
    main_title = f"{title_prefix} (Run ID: {simulation_run_id})"
    filename = f"{filename_suffix}_run_{simulation_run_id}.svg"
    
    if is_single_plot:
        figure.axes[0].set_title(main_title, fontsize=plt.rcParams['axes.titlesize']) # Set title on the axis for single plots
    else:
        plt.suptitle(main_title, fontsize=plt.rcParams['figure.titlesize'])
    
    figure.tight_layout(rect=[0, 0.03, 1, 0.95] if not is_single_plot else None) # Adjust rect for suptitle if present
    plt.savefig(os.path.join(OUTPUT_DIR, filename), dpi=300) # Increased DPI for better quality
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

df_filtered = df.copy()

vore_type_mapping = {0: 'Carnivore', 1: 'Herbivore', 2: 'Omnivore'} # ADJUST THIS MAP
if pd.api.types.is_numeric_dtype(df_filtered['vore_type']):
    df_filtered['vore_type_str'] = df_filtered['vore_type'].map(vore_type_mapping)
else:
    df_filtered['vore_type_str'] = df_filtered['vore_type']
df_filtered['vore_type_str'] = df_filtered['vore_type_str'].fillna('Unknown')

print("--- Data Info After Preprocessing ---") # Keep this for your debugging
print(f"Filtered data shape: {df_filtered.shape}")
if not df_filtered.empty:
    print(f"Timestamp min: {df_filtered['timestamp'].min()}, max: {df_filtered['timestamp'].max()}")
# print(df_filtered.head()) # Can be verbose, enable if needed
# print("Vore type string counts:")
# print(df_filtered['vore_type_str'].value_counts(dropna=False))
print("------------------------------------")


# --- MODIFIED Visualization Function for Vore Types ---
def plot_vore_type_population_stacked_area(data):
    if data.empty:
        print("Plot Vore Types (Stacked Area): No data.")
        return

    vore_counts = data.groupby(['timestamp', 'vore_type_str']).size().unstack(fill_value=0)
    
    if vore_counts.empty:
        print("Plot Vore Types (Stacked Area): No data after grouping.")
        return

    fig, ax = plt.subplots(figsize=(15, 9)) # Increased figure size

    vore_order = ['Herbivore', 'Omnivore', 'Carnivore']
    vore_counts_ordered = vore_counts.reindex(columns=vore_order, fill_value=0)

    # Create the stacked area plot with thin or no edge lines
    vore_counts_ordered.plot(kind='area', stacked=True, ax=ax, alpha=0.75, linewidth=0.5) # Reduced alpha slightly, added thin linewidth

    # Title will be set by plot_and_save for consistency
    # ax.set_title('Population Composition by Vore Type Over Time') # Removed, handled by plot_and_save
    ax.set_xlabel('Timestamp (Simulation Turn)')
    ax.set_ylabel('Total Animal Count')
    ax.legend(title='Vore Type', title_fontsize='13', fontsize='11') # Slightly adjusted legend font sizes
    ax.grid(True, linestyle='--', alpha=0.6)

    if not vore_counts_ordered.empty:
        max_population = vore_counts_ordered.sum(axis=1).max()
        ax.set_ylim(0, max_population * 1.1 if max_population > 0 else 10) # Increased top margin
    else:
        ax.set_ylim(0,10)

    plot_and_save(fig, 'vore_type_stacked_area', 'Population Composition by Vore Type', is_single_plot=True)


def plot_individual_gene_stats(data):
    if data.empty:
        print("Plot Individual Gene Stats: No data.")
        return

    gene_stats = data.groupby('timestamp')[GENE_NAMES].agg(['mean', 'min', 'max'])
    
    if gene_stats.empty:
        print("Plot Individual Gene Stats: No aggregated data to plot.")
        return

    if not GENE_NAMES:
        print("Plot Individual Gene Stats: GENE_NAMES list is empty.")
        return

    for gene in GENE_NAMES:
        # Create a new figure for each gene
        fig, ax = plt.subplots(figsize=(12, 7)) # Good size for individual plot

        mean_col = (gene, 'mean')
        min_col = (gene, 'min')
        max_col = (gene, 'max')

        if mean_col in gene_stats.columns and \
           min_col in gene_stats.columns and \
           max_col in gene_stats.columns:

            gene_stats[mean_col].plot(ax=ax, kind='line', marker='.', linestyle='-', label='Average', color='blue', zorder=3)
            gene_stats[min_col].plot(ax=ax, kind='line', linestyle='--', label='Min', color='dimgray', alpha=0.8, zorder=2) # Darker gray
            gene_stats[max_col].plot(ax=ax, kind='line', linestyle='--', label='Max', color='dimgray', alpha=0.8, zorder=2)
            ax.fill_between(gene_stats.index, gene_stats[min_col], gene_stats[max_col], color='skyblue', alpha=0.4, zorder=1, label='Min-Max Range')

            # Title is set via plot_and_save
            ax.set_ylabel('Gene Value')
            ax.set_xlabel('Timestamp (Simulation Turn)')
            ax.grid(True, linestyle='--', alpha=0.7)
            ax.set_ylim(-0.05, 1.05)
            ax.legend(title_fontsize='13', fontsize='11') # Add legend to each plot
            
            plot_and_save(fig, f'gene_stats_{gene}', f'{gene.replace("_", " ").title()} Gene Distribution', is_single_plot=True)
        else:
            print(f"Warning: Aggregated stats (mean, min, or max) for gene '{gene}' not found. Skipping plot for this gene.")
            plt.close(fig) # Close the empty figure


# --- Correlation Heatmap Function (Keep as is or apply similar size increases) ---
def plot_gene_correlation_heatmap(data):
    if data.empty or len(data) < 2:
        print("Plot Correlation: Not enough data.")
        return

    last_timestamp = data['timestamp'].max()
    data_last_timestamp = data[data['timestamp'] == last_timestamp]
    
    if len(data_last_timestamp) < 2:
        print(f"Plot Correlation: Not enough animals at last timestamp ({last_timestamp}).")
        return

    gene_data = data_last_timestamp[GENE_NAMES].copy() 
    valid_cols_for_corr = [col for col in GENE_NAMES if col in gene_data.columns and gene_data[col].nunique(dropna=True) > 1]

    if len(valid_cols_for_corr) < 2:
        print("Plot Correlation: Not enough varying gene columns for correlation.")
        return
    
    gene_data_for_corr = gene_data[valid_cols_for_corr]
    correlation_matrix = gene_data_for_corr.corr()
    
    if correlation_matrix.isnull().all().all() or correlation_matrix.empty:
        print("Plot Correlation: Correlation matrix is NaN or empty.")
        return

    fig, ax = plt.subplots(figsize=(12, 10)) # Increased size
    sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', fmt=".2f", linewidths=.5, ax=ax, vmin=-1, vmax=1, annot_kws={"size": 10}) # Adjust annot_kws for number size
    # ax.set_title(f'Gene Correlation Matrix (Timestamp: {last_timestamp})') # Title set by plot_and_save
    plt.xticks(rotation=45, ha='right')
    plt.yticks(rotation=0)
    plot_and_save(fig, 'gene_correlation_heatmap', f'Gene Correlation Matrix (Timestamp: {last_timestamp})', is_single_plot=True)


# --- Main Execution ---
if __name__ == "__main__":
    print(f"Processing data for simulation run ID: {simulation_run_id} from file: {data_file}")
    
    plot_vore_type_population_stacked_area(df_filtered.copy())
    plot_individual_gene_stats(df_filtered.copy()) # Call the new gene plotting function
    plot_gene_correlation_heatmap(df_filtered.copy())

    print(f"\nAll plots saved to '{os.path.abspath(OUTPUT_DIR)}' directory.")