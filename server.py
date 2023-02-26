import flwr as fl
import utils
from sklearn.metrics import log_loss
from sklearn.linear_model import LogisticRegression
from typing import Dict
import pickle

def fit_round(server_round: int) -> Dict:
    """Send round number to client."""
    return {"server_round": server_round}


def get_evaluate_fn(model: LogisticRegression, counter):
    """Return an evaluation function for server-side evaluation."""

    # Load test data here to avoid the overhead of doing it in `evaluate` itself
    _, (X_test, y_test) = utils.load_data(client="client1")

    # The `evaluate` function will be called after every round
    def evaluate(server_round, parameters: fl.common.NDArrays, config):
        global counter
        # Update model with the latest parameters
        from sklearn.metrics import confusion_matrix, accuracy_score, classification_report
        utils.set_model_params(model, parameters)
        preds = model.predict_proba(X_test)
        predictions = model.predict(X_test)
        loss = log_loss(y_test, preds, labels=[1,0])
        accuracy = model.score(X_test, y_test)
        print(confusion_matrix(y_test, predictions))
        print(classification_report(y_test, predictions))
        print({"accuracy_score": accuracy_score(y_test, predictions)})
        if counter > 0:
            filename = f"model/agg_models/agg_round_{str(counter)}_model.sav"
            pickle.dump(model, open(filename, 'wb'))
        counter = counter + 1
        return  {"Aggregated Results: loss ":loss}, {"accuracy": accuracy}
    return evaluate


# Start Flower server for five rounds of federated learning
if __name__ == "__main__":
    counter = 0  
    model = LogisticRegression(
        solver= 'saga',
        penalty="l2",
        max_iter=1,  # local epoch
        warm_start=True,  # prevent refreshing weights when fitting
    )
    utils.set_initial_params(model)
    strategy = fl.server.strategy.FedAvg(
        min_available_clients=4,
        min_fit_clients=2,
        fraction_fit = 0.8,
        evaluate_fn=get_evaluate_fn(model, counter),
        on_fit_config_fn=fit_round,
    )
    fl.server.start_server(
        server_address="localhost:8080",
        strategy=strategy,
        config=fl.server.ServerConfig(num_rounds=5),
    )
