_ = require('underscore')

class RouteMap
  constructor: (conf) ->
    @links = []
    conf(this)

  link: (from, to) ->
    @links.push(new Link(from, to))

  route: (from, to, visitedStations=[]) ->
    # TODO 未完
    visitedStations.push(from)
    nextStations = this.otherStationsExcudeVisited(from, visitedStations)

    return this.newRoute(visitedStations, to) if _.include(nextStations, to)

    for next in nextStations
      route = this.route(next, to, _.clone(visitedStations))
      return route if (route)

    return null

  otherStationsExcudeVisited: (station, visitedStations) ->
    (link.other(station) for link in @links when !_.include(visitedStations, link.other(station)) && link.include(station))

  newRoute: (visitedStations, to) ->
    visitedStations.push(to)
    return new Route(visitedStations)


class Route
  constructor: (@stations) ->

class Link
  constructor: (@stationA, @stationB) ->

  isLink: (stationA, stationB) ->
    (@stationA == stationA && @stationB == stationB) ||
    (@stationB == stationA && @stationA == stationB)

  include: (station) ->
    (@stationA == station || @stationB == station)

  other: (station) ->
    if (@stationA == station)
      return @stationB
    else if (@stationB == station)
      return @stationA
    return null

describe '経路マップ#route。 駅同士は直接つながっている', ->
  beforeEach ->
    @routeMap = new RouteMap (conf)->
      conf.link('横浜', '大宮')
      conf.link('横浜', '武蔵小杉')

  it '経路を返すこと', ->
    expect( @routeMap.route('横浜', '大宮').stations ).toEqual(['横浜', '大宮'])
    expect( @routeMap.route('大宮', '横浜').stations ).toEqual(['大宮', '横浜'])
    expect( @routeMap.route('横浜', '武蔵小杉').stations ).toEqual(['横浜', '武蔵小杉'])

  it '見つからない場合は null を返すこと', ->
    expect( @routeMap.route('大宮', 'NOT_CONNECT') ).toBeNull()

describe '経路マップ#route 途中にも駅がある場合', ->
  beforeEach ->
    @routeMap = new RouteMap (conf)->
      conf.link('横浜', '東京')
      conf.link('東京', '大宮')

  it '経路を返すこと', ->
    expect( @routeMap.route('東京', '横浜').stations ).toEqual(['東京', '横浜'])
    expect( @routeMap.route('東京', '大宮').stations ).toEqual(['東京', '大宮'])

  it '経由しても経路を返すこと', ->
    expect( @routeMap.route('横浜', '大宮').stations ).toEqual(['横浜', '東京', '大宮'])



standardMap = ()-> new RouteMap (conf) ->
      conf.link(row[0], row[1], row[2]) for row in [  ['横浜', 'XXX', 14],
                                                      ['横浜', '川崎', 14],
                                                      ['川崎', '東京', 24],
                                                      ['東京', '秋葉原', 6],
                                                      ['秋葉原', '田端', 11],
                                                      ['田端', '赤羽', 14],
                                                      ['赤羽', '南浦和', 16],
                                                      ['南浦和', '大宮', 12],
                                                      ['横浜', '武蔵小杉', 23],
                                                      ['川崎', '武蔵小杉', 19],
                                                      ['武蔵小杉', '西国分寺', 50],
                                                      ['西国分寺', '南浦和', 36],
                                                      ['武蔵小杉', '渋谷', 21],
                                                      ['渋谷', '新宿', 10],
                                                      ['渋谷', '東京', 25],
                                                      ['新宿', '西国分寺', 32],
                                                      ['新宿', '池袋', 11],
                                                      ['新宿', 'お茶の水', 16],
                                                      ['東京', 'お茶の水', 10],
                                                      ['お茶の水', '秋葉原', 8],
                                                      ['池袋', '田端', 12],
                                                      ['池袋', '赤羽', 15],]

describe '経路マップ#route 多くの数の経路マップが登録されている場合', ->
  beforeEach ->
    @routeMap = standardMap()

  it '経路を返すこと', ->
    # XXX 最短時間はまだ。見つかったものを返している
    expect( @routeMap.route('東京', '横浜').stations ).toEqual(['東京', '川崎', '横浜'])
    expect( @routeMap.route('東京', '大宮').stations ).toEqual(['東京', '川崎', '横浜', '武蔵小杉', '西国分寺', '南浦和', '大宮'])
    expect( @routeMap.route('渋谷', '田端').stations ).toEqual(['渋谷', '武蔵小杉', '横浜', '川崎', '東京', '秋葉原', '田端'])
    expect( @routeMap.route('新宿', '赤羽').stations ).toEqual(['新宿', '渋谷', '武蔵小杉', '横浜', '川崎', '東京', '秋葉原', '田端', '赤羽'])

