class CandlesController < ApplicationController
  require 'csv'

  def index
    @yearly_stats = Candle.where.not(date: nil).group_by_year(:date).map do |year, records|
      analyze_group(year, records)
    end.compact

    @monthly_stats = Candle.where.not(date: nil).group_by_month(:date).map do | month, records|
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

    highs = records.map(&:high)
    lows = records.map(&:low)
    ranges = highs.zip(lows).map { |h, l| h - l }
    bodies = records.map { |r| (r.close - r.open).abs }

    {
      period: key,
      high: highs.max,
      low: lows.min,
      range_avg: ranges.sum / ranges.size,
      body_avg: bodies.sum / bodies.size,
      volume_avg: records.map(&:volume).sum / records.size
    }
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
    Date.parse(value.to_s) rescue nil
  end
  
  def parse_number(value)
    return nil if value.blank?
    value.to_s.delete(",").to_f
  end
end
