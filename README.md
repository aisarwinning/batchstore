# Batchstore
Batchstore is a data store module that splits your data into batches of data in JSON that is maximum of 50,000 characters (or however you want it) and allows you to use basic roblox `DataStore` methods like `:GetAsync`, `:SetAsync` and `:RemoveAsync`, a little diagram on how it works:

![Untitled Diagram drawio](https://github.com/aisarwinning/batchstore/assets/81717063/1640c773-5f87-4479-baa2-b557c32bc821)

What this module is built for is massive data loading, in order to load data faster and having to go through less keys but recieving the same type of data back through the batches; this module has some pros and cons though; the pros is that you can store a bunch of data and avoid giant rate-limits when going through a big list of data keys, the cons are that loading times depend on the amount of Batches (you are allowed **150,000 characters** by default and 200,000 is the maximum); for every patch 1 second is added to the delay *(first batch ignores the limit)*
# Documentation
In order to save and get data, you can follow this example:
```lua
local BatchStore = require(path).new("NewData") -- NewData can be anything

local serverData = {
  ServerWeather = "Rainy";
  ServerSeason = "Winter";
  -- etc..
}

BatchStore:SetAsync(game.JobId, serverData)

print(BatchStore:GetAsync(game.JobId)) --> This would return the data we inserted earlier

BatchStore:RemoveAsync(game.JobId)

print(BatchStore:GetAsync(game.JobId)) --> This would return nil because we removed it
```

Self-explanatory module, only intermediates should really use this and **I only made this for fun; if you want to use it you should probably tweak it.**
You are allowed to make changes to it by making a pull request! 😄
