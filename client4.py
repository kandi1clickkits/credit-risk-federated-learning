import warnings
import flwr as fl
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import log_loss
from sklearn.metrics import confusion_matrix
import utils
import pickle


if __name__ == "__main__":
    # Load credit risk data
    (X_train, y_train), (X_test, y_test) = utils.load_data(client="client4")
    counter = 0
    # Split train set into 10 partitions and randomly use one for training.
    partition_id = np.random.choice(10)
    (X_train, y_train) = utils.partition(X_train, y_train, 10)[partition_id]

    # Create LogisticRegression Model
    model = LogisticRegression(
        solver= 'saga',
        penalty="l2",
        max_iter=10,  # local epoch
        warm_start=True,  # prevent refreshing weights when fitting
    )

    # Setting initial parameters, akin to model.compile for keras models
    utils.set_initial_params(model)

    # Define Flower client
    class FlowerClient(fl.client.NumPyClient):
        def get_parameters(self, config):  # type: ignore
            return utils.get_model_parameters(model)

        def fit(self, parameters, config):  # type: ignore
            global counter
            utils.set_model_params(model, parameters)
            # Ignore convergence failure due to low local epochs
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                model.fit(X_train, y_train)
                filename = f"model/client4/client_4_round_{config['server_round']}_model.sav"
                pickle.dump(model, open(filename, 'wb'))
                counter += 1
            print(f"Training finished for round {config['server_round']}")
            return utils.get_model_parameters(model), len(X_train), {}

        def evaluate(self, parameters, config):  # type: ignore

            utils.set_model_params(model, parameters)
            preds = model.predict_proba(X_test)
            all_classes = {'1','0'}
            loss = log_loss(y_test, preds, labels=[1,0])
            accuracy = model.score(X_test, y_test)

            return loss, len(X_test), {"accuracy": accuracy}

    # Start Flower client
    fl.client.start_numpy_client(server_address="localhost:8080", client=FlowerClient())
