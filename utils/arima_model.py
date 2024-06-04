import pandas as pd
from statsmodels.tsa.arima.model import ARIMA

def train_arima(data):
    grouped_data = data.groupby('jenis_tanaman')
    forecasts_arima = {}
    
    best_params_per_tanaman_arima = {
        'Anggrek': {'p': 2, 'd': 1, 'q': 1},
        'Koleksi Kita': {'p': 0, 'd': 0, 'q': 0},
        'Tanaman Besar': {'p': 0, 'd': 1, 'q': 1}
    }
    
    for name, group in grouped_data:
        if name not in best_params_per_tanaman_arima:
            continue
        group = group.sort_values(by='waktu')
        group.set_index('waktu', inplace=True)
        train_data = group['jumlah_tersewa']
        
        params = best_params_per_tanaman_arima[name]
        model_arima = ARIMA(train_data, order=(params['p'], params['d'], params['q']))
        model_fit_arima = model_arima.fit()
        forecast_arima = model_fit_arima.forecast(steps=12)
        forecasts_arima[name] = forecast_arima
    
    return forecasts_arima
