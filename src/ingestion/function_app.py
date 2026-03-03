import azure.functions as func
import logging
import requests
import json
import os
from datetime import datetime
from azure.storage.filedatalake import DataLakeServiceClient

app = func.FunctionApp()

# Déclenchement toutes les 5 minutes
@app.timer_trigger(schedule="0 */5 * * * *", arg_name="myTimer", run_on_startup=False)
def fetch_opensky_data(myTimer: func.TimerRequest) -> None:
    if myTimer.past_due:
        logging.info('Le timer est en retard !') 

    logging.info('Exécution de la fonction Azure pour récupérer les données OpenSky.')

    # 1. Appel à l'API OpenSky (Bounding box pour la France/Occitanie pour limiter la taille)
    # lamin, lomin, lamax, lomax
    url = "https://opensky-network.org/api/states/all?lamin=42.0&lomin=-5.0&lamax=51.0&lomax=8.0"
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        flight_data = response.json()
        
        # 2. Préparation du nom de fichier avec un timestamp
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        file_name = f"flights_france_{timestamp}.json"
        
        # 3. Connexion à Azure Data Lake Storage (ADLS Gen2)
        # La chaîne de connexion doit être dans les variables d'environnement (ou local.settings.json)
        connection_string = os.environ["ADLS_CONNECTION_STRING"]
        service_client = DataLakeServiceClient.from_connection_string(connection_string)
        
        # On cible le conteneur "bronze" (données brutes)
        file_system_client = service_client.get_file_system_client(file_system="bronze")
        
        # Création du client pour le fichier et upload
        file_client = file_system_client.get_file_client(f"opensky/{datetime.utcnow().strftime('%Y/%m/%d')}/{file_name}")
        
        # Upload des données JSON converties en string
        file_client.upload_data(json.dumps(flight_data), overwrite=True)
        
        logging.info(f"Fichier {file_name} sauvegardé avec succès dans le Data Lake (Bronze).")

    except Exception as e:
        logging.error(f"Erreur lors de l'ingestion : {str(e)}")