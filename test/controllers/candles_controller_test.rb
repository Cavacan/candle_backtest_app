require "test_helper"

class CandlesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get candles_index_url
    assert_response :success
  end

  test "should get import_csv" do
    get candles_import_csv_url
    assert_response :success
  end

  test "should get chart" do
    get candles_chart_url
    assert_response :success
  end
end
