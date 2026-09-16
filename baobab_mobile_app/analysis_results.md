# Baobab ML Model Analysis Results

## 1. Dataset Overview & Feature Engineering

### Original Datasets
- **`baobab_uses.csv`**: 207 rows, 22 columns
- **`agronomic_dataset.csv`**: 273 rows, 24 columns
- **Merged Base Dataset**: 256 rows, 39 columns

### Final Training Matrix
- **Total Records Evaluated**: 256 samples
- **Total Features Used**: 23 columns (after cleaning and encoding)

### Engineered Features
To improve the machine learning models' ability to detect complex patterns, several new features were mathematically derived from the raw data:
- **`height_dbh_ratio`**: Height to Trunk Diameter ratio.
- **`crown_trunk_ratio`**: Crown Diameter to Trunk Diameter ratio.
- **`canopy_volume_proxy`**: Estimated volume using Height × Crown Diameter².
- **`trunk_slenderness`**: A measure of tree stability (Height / Trunk Diameter).
- **`altitude_normalized`**: Min-Max scaled elevation.
- **`altitude_height_interaction`**: Interaction term between Altitude and Height.
- **`altitude_crown_interaction`**: Interaction term between Altitude and Crown Diameter.
- **`total_parts_used`**: A sum of all tree parts utilized (Fruit, Leaf, Stem, Root, Seed).
- **Categorical Encodings**: `Geographic_Zone`, `Tree_Growth_Habitat`, `Topography`, `Soil_Texture`, and `Farm_Cultivated` were all label-encoded for the algorithms.

## 2. Model Evaluation & Best Algorithms

```text
TRAINING: baobab_food
MODEL EVALUATION - FOOD
--- Random Forest --- Acc: 0.885 | F1: 0.883 | AUC: 0.968
--- Gradient Boosting --- Acc: 0.872 | F1: 0.868 | AUC: 0.957
--- Xgboost --- Acc: 0.897 | F1: 0.897 | AUC: 0.968
--- Svm --- Acc: 0.910 | F1: 0.909 | AUC: 0.982
--- Neural Network --- Acc: 0.897 | F1: 0.892 | AUC: 0.968
★ BEST MODEL FOR FOOD: SVM (Accuracy: 0.9103)

TRAINING: baobab_beverage
MODEL EVALUATION - BEVERAGE
--- Random Forest --- Acc: 0.724 | F1: 0.720 | AUC: 0.793
--- Gradient Boosting --- Acc: 0.741 | F1: 0.740 | AUC: 0.812
--- Xgboost --- Acc: 0.706 | F1: 0.706 | AUC: 0.781
--- Svm --- Acc: 0.655 | F1: 0.654 | AUC: 0.723
--- Neural Network --- Acc: 0.689 | F1: 0.689 | AUC: 0.730
★ BEST MODEL FOR BEVERAGE: Gradient Boosting (Accuracy: 0.7413)

TRAINING: baobab_medicine
MODEL EVALUATION - MEDICINE
--- Random Forest --- Acc: 0.631 | F1: 0.630 | AUC: 0.701
--- Gradient Boosting --- Acc: 0.666 | F1: 0.665 | AUC: 0.724
--- Xgboost --- Acc: 0.648 | F1: 0.648 | AUC: 0.710
--- Svm --- Acc: 0.596 | F1: 0.595 | AUC: 0.651
--- Neural Network --- Acc: 0.614 | F1: 0.613 | AUC: 0.672
★ BEST MODEL FOR MEDICINE: Gradient Boosting (Accuracy: 0.6666)

TRAINING: agronomic
MODEL EVALUATION - AGRONOMIC
--- Random Forest --- Acc: 0.883 | F1: 0.882 | AUC: 0.970
--- Gradient Boosting --- Acc: 0.916 | F1: 0.916 | AUC: 0.981
--- Xgboost --- Acc: 0.900 | F1: 0.900 | AUC: 0.978
--- Svm --- Acc: 0.866 | F1: 0.865 | AUC: 0.961
--- Neural Network --- Acc: 0.850 | F1: 0.849 | AUC: 0.955
★ BEST MODEL FOR AGRONOMIC: Gradient Boosting (Accuracy: 0.9166)
```

## 3. Ensemble Method Used

The primary ensemble methods evaluated in this project are **Random Forest** and **Gradient Boosting (including XGBoost)**. 
These ensemble methods work by combining multiple decision trees to improve overall predictive accuracy and control over-fitting. 
The models are selected dynamically for each target (Food, Beverage, Medicine, Agronomic) based on the highest cross-validation accuracy. As seen above, **Gradient Boosting** proved to be the most effective ensemble method for the majority of the targets.

## 4. Exploratory Graphs (Outliers & Distributions)

### Combined Outlier Analysis
![Combined Outliers](./combined_outliers.png)

### Target Class Distributions
![Target Distributions](./target_distributions.png)
