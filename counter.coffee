getRawMongoCollection = (collectionName) ->
  if MongoInternals?
    mongo = MongoInternals.defaultRemoteCollectionDriver().mongo
    if mongo.rawCollection?
      mongo.rawCollection(collectionName)
    else
      mongo._getCollection(collectionName)
  else
    Meteor._RemoteCollectionDriver.mongo._getCollection(collectionName)


getCounterCollection = (collectionName) ->
  getRawMongoCollection(collectionName)


callCounter = (method, collectionName, args...) ->
  Counters = getCounterCollection(collectionName)
  Meteor.wrapAsync(_.bind(Counters[method], Counters))(args...)

_deleteCounters = (collectionName) ->
  callCounter('remove', collectionName, {}, {safe: true})


_incrementCounter = (collectionName, counterName, amount = 1) ->
  newDoc = callCounter(
    'findAndModify',
    collectionName,
    {_id: counterName},         # query
    null,                       # sort
    {$inc: {next_val: amount}},      # update
    {new: true, upsert: true},  # options
  )                             # callback added by wrapAsync
  return newDoc.next_val


_decrementCounter = (collectionName, counterName, amount = 1) ->
  _incrementCounter(collectionName, counterName, -amount)


_setCounter = (collectionName, counterName, value) ->
  callCounter(
    'update',
    collectionName,
    {_id: counterName},
    {$set: {next_val: value}}
  )
  return


if Package?
  incrementCounter = _incrementCounter
  decrementCounter = _decrementCounter
  setCounter = _setCounter
  deleteCounters = _deleteCounters
else
  @incrementCounter = _incrementCounter
  @decrementCounter = _decrementCounter
  @setCounter = _setCounter
  @deleteCounters = _deleteCounters
