import pandas as pd
from statsmodels.tsa.holtwinters import ExponentialSmoothing

def train_tes(data):
    grouped_data = data.groupby('jenis_tanaman')
    forecasts_tes = {}
    
    best_params_per_tanaman_tes = {
        'Anggrek': {'trend': 'add', 'seasonal': 'add', 'alpha': 0.2, 'beta': 0.2, 'gamma': 0.2},
        'Koleksi Kita': {'trend': 'mul', 'seasonal': 'add', 'alpha': 0.2, 'beta': 0.4, 'gamma': 0.4},
        'Tanaman Besar': {'trend': 'add', 'seasonal': 'add', 'alpha': 0.4, 'beta': 0.6, 'gamma': 0.2}
    }
    
    for name, group in grouped_data:
        if name not in best_params_per_tanaman_tes:
            continue
        group = group.sort_values(by='waktu')
        group.set_index('waktu', inplace=True)
        train_data = group['jumlah_tersewa']
        
        params = best_params_per_tanaman_tes[name]
        model_tes = ExponentialSmoothing(train_data, trend=params['trend'], seasonal=params['seasonal'], seasonal_periods=12)
        model_fit_tes = model_tes.fit(smoothing_level=params['alpha'], smoothing_trend=params['beta'], smoothing_seasonal=params['gamma'])
        forecast_tes = model_fit_tes.forecast(steps=12)
        forecasts_tes[name] = forecast_tes
    
    return forecasts_tes
