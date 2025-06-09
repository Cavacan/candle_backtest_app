class CandlesController < ApplicationController
  require 'csv'

  def index
    @yearly_stats = Candle.where.not(date: nil).group_by_year(:date).map do |year, records|
      analyze_group(year, records)
    end.compact

    @monthly_stats = Candle.where.not(date: nil).group_by_month(:date).map do |month, records|
      analyze_group(month, records)
    end
  end

  def import_csv
    file = params[:csv_file]
    CSV.foreach(file.path, headers: true, encoding: "bom|utf-8") do |row|
      normalized_row = row.to_h.transform_keys { |key| key.to_s.delete_prefix("\uFEFF").strip }
      Candle.create!(candle_data(normalized_row))
    end
    redirect_to candles_path, notice: "CSVを読み込みました"
  end

  def chart
    @candles = Candle.order(:date).last(100)
  end

  private

  def analyze_group(key, records)
    return nil if records.blank?

    highs, lows, volumes = extract_highs_lows_volumes(records)
    ranges = highs.zip(lows).map { |h, l| h - l }
    bodies = records.map { |r| (r.close - r.open).abs }

    stats = {
      highs: highs,
      lows: lows,
      ranges: ranges,
      bodies: bodies,
      volumes: volumes
    }

    build_stat_hash(key, stats)
  end

  def extract_highs_lows_volumes(records)
    highs = records.map(&:high)
    lows  = records.map(&:low)
    volumes = records.map(&:volume)
    [highs, lows, volumes]
  end

  def average(arr)
    return 0 if arr.blank?

    arr.sum.to_f / arr.size
  end

  def candle_data(row)
    {
      date: parse_date(row['date']),
      open: parse_number(row['open']),
      high: parse_number(row['high']),
      low: parse_number(row['low']),
      close: parse_number(row['close']),
      volume: parse_number(row['volume'])
    }
  end

  def parse_date(value)
    return nil if value.blank?

    begin
      Date.parse(value.to_s)
    rescue StandardError
      nil
    end
  end

  def parse_number(value)
    return nil if value.blank?

    value.to_s.delete(",").to_f
  end

  def build_stat_hash(key, stats)
    {
      period: key,
      high: stats[:highs].max,
      low: stats[:lows].min,
      range_avg: average(stats[:ranges]),
      body_avg: average(stats[:bodies]),
      volume_avg: average(stats[:volumes])
    }
  end
end
