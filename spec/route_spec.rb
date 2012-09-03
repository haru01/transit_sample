# encoding: utf-8

class RouteMap
  def initialize(&block)
    @links = []
    block.call(self) if block_given?
  end

  def link(station_a, station_b, cost_minute=0)
    @links << Link.new(station_a, station_b, cost_minute)
  end

  def routes(from, to, visited_stations=[], routes=[])
    # 計算量を減らす工夫はしていない。
    visited_stations << from
    next_stations = other_stations(from) - visited_stations

    routes << new_route(visited_stations << to) if next_stations.include?(to)

    next_stations.reduce(routes) do |routes, other|
      routes(other, to, visited_stations.clone, routes)
    end
  end

  def route(from, to)
    routes = routes(from, to)
    return nil if routes.empty?

    routes.sort_by { |route| route.cost_minute }.first
  end

  def new_route(visited_stations)
    links = (0..visited_stations.size-2).map { |n|
      from, to = visited_stations[n..n+1]
      @links.find { |l| l.link?(from, to) }
    }

    Route.new(visited_stations, links)
  end

  def other_stations(station)
    links_by(station).map { |link| link.other_station(station) }
  end

  def links_by(station)
    @links.select { |link| link.include?(station) }
  end
end

class Link
  attr_reader :cost_minute

  def initialize(station_a, station_b, cost_minute=0)
    @station_a, @station_b, @cost_minute = station_a, station_b, cost_minute
  end

  def include?(station)
    @station_a == station || @station_b == station
  end

  def link?(station_a, station_b)
    (@station_a == station_a && @station_b == station_b) ||
    (@station_a == station_b && @station_b == station_a)
  end

  def other_station(station)
    @station_a == station ? @station_b : @station_a
  end
end

class Route
  attr_reader :stations

  def initialize(stations, links)
    @stations = stations
    @links = links
  end

  def cost_minute
    @links.map {|l| l.cost_minute }.reduce(:+)
  end
end

class Fixnum
  def min
    return self
  end
end

shared_context '標準の経路マップ設定' do
  subject(:route_map) do
    route_map = RouteMap.new do |c|
     [['横浜', '川崎', 14.min],
      ['川崎', '東京', 24.min],
      ['東京', '秋葉原', 6.min],
      ['秋葉原', '田端', 11.min],
      ['田端', '赤羽', 14.min],
      ['赤羽', '南浦和', 16.min],
      ['南浦和', '大宮', 12.min],
      ['横浜', '武蔵小杉', 23.min],
      ['川崎', '武蔵小杉', 19.min],
      ['武蔵小杉', '西国分寺', 50.min],
      ['西国分寺', '南浦和', 36.min],
      ['武蔵小杉', '渋谷', 21.min],
      ['渋谷', '新宿', 10.min],
      ['渋谷', '東京', 25.min],
      ['新宿', '西国分寺', 32.min],
      ['新宿', '池袋', 11.min],
      ['新宿', 'お茶の水', 16.min],
      ['東京', 'お茶の水', 10.min],
      ['お茶の水', '秋葉原', 8.min],
      ['池袋', '田端', 12.min],
      ['池袋', '赤羽', 15.min],
      ['横浜', 'AAA', 999.min],
      ['西国分寺', 'BBB', 888.min],].each {|a, b, cost_minute| c.link(a, b, cost_minute) }
    end
  end
end

describe '経路マップ#route 2つの駅が直接つながっている場合' do
  subject(:route_map) do
    route_map = RouteMap.new do |c|
      c.link('大宮', '横浜')
    end
  end

  it '直接つながっている区間は電車で行けること' do
    route_map.route('横浜', '大宮').stations.should == ['横浜', '大宮']
    route_map.route('大宮', '横浜').stations.should == ['大宮', '横浜']
  end

  it 'つながっていない区間は電車で行けないこと' do
    route_map.route('大島', '横浜').should be_nil
  end
end

describe '経路マップ#route 経由駅がある場合も' do
  subject(:route_map) do
    route_map = RouteMap.new do |c|
      c.link('横浜', '東京')
      c.link('東京', '大宮')
    end
  end

  it '電車で行けること' do
    route_map.route('横浜', '大宮').stations.should == ['横浜', '東京', '大宮']
  end
end

describe '経路マップ#route 多数の駅がある場合も' do
  include_context '標準の経路マップ設定'

  it '電車で行けること' do
    route_map.route('横浜', '大宮').stations.should == ['横浜', '川崎', '東京', '秋葉原', '田端', '赤羽', '南浦和', '大宮']
    route_map.route('横浜', '渋谷').stations.should == ["横浜", "武蔵小杉", "渋谷"]
  end
end


describe '経路マップ#route' do
  include_context '標準の経路マップ設定'

  it '最短時間の経路検索できること' do
    route_map.route('川崎', '渋谷').stations.should == ['川崎', '武蔵小杉', '渋谷']
    route_map.route('川崎', '渋谷').cost_minute.should == 19.min + 21.min
    route_map.route('新宿', '横浜').stations.should == ['新宿', '渋谷', '武蔵小杉', '横浜']
    route_map.route('新宿', '横浜').cost_minute.should == 10.min + 21.min + 23.min
    route_map.route('赤羽', 'お茶の水').stations.should == ["赤羽", "田端", "秋葉原", "お茶の水"]
    route_map.route('お茶の水', '赤羽').cost_minute.should == 14.min + 11.min + 8.min
  end
end

shared_context '縮小版経路マップ設定' do
  subject(:route_map) do
    route_map = RouteMap.new do |c|
     [['横浜', '川崎', 14.min],
      ['川崎', '東京', 24.min],
      ['横浜', '武蔵小杉', 23.min],
      ['川崎', '武蔵小杉', 19.min],
      ['武蔵小杉', '渋谷', 21.min],
      ['渋谷', '東京', 25.min],].each { |a, b, cost_minute| c.link(a, b, cost_minute) }
    end
  end
end

describe '経路マップ#cost_minute' do
  include_context '縮小版経路マップ設定'

  it '複数の経路検索できること' do
    route_map.routes('川崎', '渋谷').sort_by { |route| route.cost_minute }[0].stations.should == ['川崎', '武蔵小杉', '渋谷']
    route_map.routes('川崎', '渋谷').sort_by { |route| route.cost_minute }[1].stations.should == ['川崎', '東京', '渋谷']
    route_map.routes('川崎', '渋谷').sort_by { |route| route.cost_minute }[2].stations.should == ["川崎", "横浜", "武蔵小杉", "渋谷"]
  end
end
