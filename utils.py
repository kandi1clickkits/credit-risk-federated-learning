from typing import Tuple, Union, List
import numpy as np
from sklearn.linear_model import LogisticRegression
import openml
import pandas as pd
from sklearn.preprocessing import LabelEncoder
from imblearn.over_sampling import SMOTE
import glob
import os.path
import pickle
XY = Tuple[np.ndarray, np.ndarray]
Dataset = Tuple[XY, XY]
LogRegParams = Union[XY, Tuple[np.ndarray]]
XYList = List[XY]


def get_model_parameters(model: LogisticRegression) -> LogRegParams:
    """Returns the paramters of a sklearn LogisticRegression model."""
    if model.fit_intercept:
        params = [
            model.coef_,
            model.intercept_,
        ]
    else:
        params = [
            model.coef_,
        ]
    return params


def set_model_params(
    model: LogisticRegression, params: LogRegParams
) -> LogisticRegression:
    """Sets the parameters of a sklean LogisticRegression model."""
    model.coef_ = params[0]
    if model.fit_intercept:
        model.intercept_ = params[1]
    return model


def set_initial_params(model: LogisticRegression):
    """Sets initial parameters as zeros Required since model params are
    uninitialized until model.fit is called.

    But server asks for initial parameters from clients at launch. Refer
    to sklearn.linear_model.LogisticRegression documentation for more
    information.
    """
    n_classes = 2
    n_features = 86

    try:
        folder_path = f'model/agg_models'
        file_type = r'\*.sav'
        files = glob.glob(folder_path + file_type)
        max_file = max(files, key=os.path.getctime)
        last_updated_model = max_file
        latest_model = pickle.load(open(f'{last_updated_model}', 'rb'))
        model.classes_ = np.array([i for i in range(2)])
        model.coef_ = latest_model.coef_
        if model.fit_intercept:
            model.intercept_ = latest_model.intercept_
    except:
        model.classes_ = np.array([i for i in range(2)])
        model.coef_ = np.zeros((n_classes, n_features))
        if model.fit_intercept:
            model.intercept_ = np.zeros((n_classes,))

def load_data(client) -> Dataset:
    if client=="client1":
        data = pd.read_csv('data/data1.csv')
    elif client=="client2":
        data = pd.read_csv('data/data2.csv')
    elif client=="client3":
        data = pd.read_csv('data/data3.csv')
    elif client=="client4":
        data = pd.read_csv('data/data4.csv')
    elif client=="test":
        data = pd.read_csv('data/test.csv')

    le= LabelEncoder()
    df =np.array(data)
    X = df[:,:-1]
    y =df[:,-1]
    sm = SMOTE(sampling_strategy='minority', random_state=42)
    X, y= sm.fit_resample(X, y)
    y_encoded=le.fit_transform(y)

    """ Select the 80% of the data as Training data and 20% as test data """
    from sklearn.model_selection import train_test_split
    x_train, x_test, y_train, y_test = train_test_split(X, y_encoded, random_state=1, stratify=y)
    from sklearn.preprocessing import StandardScaler
    scaler = StandardScaler()
    X_scaler = scaler.fit(x_train)
    x_train = X_scaler.transform(x_train)
    x_test = X_scaler.transform(x_test)
    return (x_train, y_train), (x_test, y_test)

def shuffle(X: np.ndarray, y: np.ndarray) -> XY:
    """Shuffle X and y."""
    rng = np.random.default_rng()
    idx = rng.permutation(len(X))
    return X[idx], y[idx]

def partition(X: np.ndarray, y: np.ndarray, num_partitions: int) -> XYList:
    """Split X and y into a number of partitions."""
    return list(
        zip(np.array_split(X, num_partitions), np.array_split(y, num_partitions))
    )
