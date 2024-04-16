local DataManager = {}

function DataManager.new(dataName)
	assert(dataName, "There needs to be a datastore name specified in order to construct a class")
	
	local self = table.clone(DataManager)

	self.dataConstructed = os.time();
	self.dataCapacity = 50_000; -- YOU CAN CHANGE HOWEVER YOU WANT
	self.dataCollected = {};

	self.DataStoreService = game:GetService("DataStoreService")
	self.HttpService = game:GetService("HttpService")

	self.DataStore = self.DataStoreService:GetDataStore(dataName)

	self._debug = true; -- set to true if you want to debug

	return self
end

function DataManager:_safecall(method, methodParent, ...)
	local success, err = pcall(method, methodParent, ...)

	if not success then
		error(debug.traceback(err))

		return nil
	end

	return err
end

function DataManager:RemoveAsync(dataName)
	local foundDataBatch = 0; -- starts at 1

	local dataFound = nil;

	while true do
		foundDataBatch += 1

		local dataBatch = self.dataCollected[foundDataBatch] or self:_safecall(self.DataStore.GetAsync, self.DataStore, "DATA-BATCH" .. foundDataBatch)

		if dataBatch then
			if typeof(dataBatch) == "string" then
				dataBatch = self:_safecall(self.HttpService.JSONDecode, self.HttpService, dataBatch)
			end

			self.dataCollected[foundDataBatch] = dataBatch;

			if dataBatch[dataName] then
				dataFound = dataBatch;
				
				break
			end
		else
			break
		end

		task.wait(1)
	end

	if dataFound then
		dataFound[dataName] = nil;

		self.dataCollected[foundDataBatch] = dataFound;

		local success = self:_safecall(self.DataStore.SetAsync, self.DataStore, "DATA-BATCH" .. foundDataBatch, dataFound)

		if success == nil and self._debug then
			warn(">> DATA FAILED TO REMOVE RETURNING WITH A NIL VALUE")
		end
	end
end

function DataManager:GetAsync(dataName)
	local foundDataBatch = 0; -- starts at 1

	local dataFound = nil;

	while true do
		foundDataBatch += 1

		local dataBatch = self.dataCollected[foundDataBatch] or self:_safecall(self.DataStore.GetAsync, self.DataStore, "DATA-BATCH" .. foundDataBatch)

		if dataBatch then
			if typeof(dataBatch) == "string" then
				dataBatch = self:_safecall(self.HttpService.JSONDecode, self.HttpService, dataBatch)
			end

			self.dataCollected[foundDataBatch] = dataBatch;

			if dataBatch[dataName] then
				dataFound = dataBatch[dataName]

				break
			end
		else
			break
		end

		task.wait(2)
	end

	return dataFound
end

function DataManager:SetAsync(dataName, dataValue)
	assert(dataName, "There has to be valid DATA_NAME in order to save data")
	assert(dataValue, "There has to be valid DATA_VALUE in order to save data")

	-- TODO: Finish Data

	local i = 0;
	local i_data = {};

	while true do
		i += 1

		local dataBatch = self.dataCollected[i] or self:_safecall(self.DataStore.GetAsync, self.DataStore, "DATA-BATCH" .. i)

		if dataBatch then
			if dataBatch then
				local characterLeft = self:_safecall(self.HttpService.JSONEncode, self.HttpService, dataBatch)

				if string.len(characterLeft) >= self.dataCapacity then
					if self._debug then
						warn(">> SKIPPED OVER DATA-BATCH" .. i .. " DUE TO THERE BEING OVER " .. string.len(characterLeft) .. " CHARACTERS")
					end

					continue
				end

				i_data = dataBatch;

				break
			end
		else
			break
		end
	end

	i_data[dataName] = dataValue;
	
	self.dataCollected[i] = i_data;

	local success = self:_safecall(self.DataStore.SetAsync, self.DataStore, "DATA-BATCH" .. i, i_data)

	if success == nil and self._debug then
		warn(">> DATA FAILED TO SAVE RETURNING WITH A NIL VALUE")
	end
end

return {
	new = DataManager.new
}
