from flask import Blueprint, jsonify
import pandas as pd
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.holtwinters import ExponentialSmoothing
from extensions import mysql
from datetime import datetime

prediction_blueprint = Blueprint('prediction', __name__)

@prediction_blueprint.route('/predict')
def predict():
    csv_data = pd.read_csv('data/dataset_fix.csv')
    csv_data['waktu'] = pd.to_datetime(csv_data['waktu'], format='%Y-%m')
    
    cur = mysql.connection.cursor()
    cur.execute("SELECT nama_tanaman, jenis_tanaman, quantity, bulan, tahun FROM aggregated_bookings")
    aggregated_data = cur.fetchall()
    cur.close()

    aggregated_df = pd.DataFrame(aggregated_data, columns=['nama_tanaman', 'jenis_tanaman', 'total_quantity', 'bulan', 'tahun'])
    print("Aggregated Data from DB:")
    print(aggregated_df.head())

    aggregated_df['waktu'] = pd.to_datetime(aggregated_df['tahun'].astype(str) + '-' + aggregated_df['bulan'].astype(str) + '-01')

    csv_data = csv_data.rename(columns={'jumlah_tersewa': 'total_quantity'})
    combined_data = pd.concat([csv_data, aggregated_df[['waktu', 'jenis_tanaman', 'nama_tanaman', 'total_quantity']]], ignore_index=True)
    print("Combined Data:")
    print(combined_data.head())

    grouped_data = combined_data.groupby('jenis_tanaman')

    forecasts_arima = {}
    forecasts_tes = {}

    arima_params = {
        'Anggrek': {'order': (2, 1, 1)},
        'Koleksi Kita': {'order': (0, 0, 0)},
        'Tanaman Besar': {'order': (0, 1, 1)},
    }
    tes_params = {
        'Anggrek': {'trend': 'add', 'seasonal': 'add', 'seasonal_periods': 12, 'alpha': 0.2, 'beta': 0.2, 'gamma': 0.2},
        'Koleksi Kita': {'trend': 'mul', 'seasonal': 'add', 'seasonal_periods': 12, 'alpha': 0.2, 'beta': 0.4, 'gamma': 0.4},
        'Tanaman Besar': {'trend': 'add', 'seasonal': 'add', 'seasonal_periods': 12, 'alpha': 0.4, 'beta': 0.6, 'gamma': 0.2},
    }

    default_arima_params = {'order': (1, 1, 1)}
    default_tes_params = {'trend': 'add', 'seasonal': 'add', 'seasonal_periods': 12, 'alpha': 0.3, 'beta': 0.3, 'gamma': 0.3}

    for name, group in grouped_data:
        print(f"Processing group: {name}")
        group = group.sort_values(by='waktu')
        group = group.drop_duplicates(subset='waktu', keep='first')  
        group.set_index('waktu', inplace=True)
        group = group.asfreq('MS')

        if len(group) < 12:
            print(f"Skipping {name} due to insufficient data")
            continue

        train_data = group['total_quantity'].iloc[:-12]
        test_data = group['total_quantity'].iloc[-12:]

        if len(train_data) == 0 or len(test_data) == 0:
            print(f"Skipping {name} due to empty train or test data")
            continue

        try:
            arima_param = arima_params.get(name, default_arima_params)
            model_arima = ARIMA(train_data, order=arima_param['order'])
            model_fit_arima = model_arima.fit()
            forecast_arima = model_fit_arima.forecast(steps=12)
            forecast_arima.index = pd.date_range(start=train_data.index[-1], periods=12, freq='MS')
            forecasts_arima[name] = forecast_arima.tolist()
        except Exception as e:
            print(f"Error fitting ARIMA for {name}: {e}")
            continue

        try:
            tes_param = tes_params.get(name, default_tes_params)
            model_tes = ExponentialSmoothing(train_data, **{k: v for k, v in tes_param.items() if k not in ['alpha', 'beta', 'gamma']})
            model_fit_tes = model_tes.fit(smoothing_level=tes_param['alpha'], smoothing_trend=tes_param['beta'], smoothing_seasonal=tes_param['gamma'])
            forecast_tes = model_fit_tes.forecast(steps=12)
            forecast_tes.index = pd.date_range(start=train_data.index[-1], periods=12, freq='MS')
            forecasts_tes[name] = forecast_tes.tolist()
        except Exception as e:
            print(f"Error fitting TES for {name}: {e}")
            continue

    return jsonify({'arima': forecasts_arima, 'tes': forecasts_tes})
