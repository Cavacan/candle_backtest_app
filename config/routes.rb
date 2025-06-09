Rails.application.routes.draw do
  root 'home#index'

  resources :candles, only: [:index] do
    collection do
      post :import_csv
      get :chart
    end
  end
end
