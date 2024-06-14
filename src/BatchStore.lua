local DataManager = {}

function DataManager.new(dataName)
	assert(dataName, "There needs to be a datastore name specified in order to construct a class")

	local self = table.clone(DataManager)

	self.dataConstructed = os.time();
	self.dataCapacity = 150000; -- YOU CAN CHANGE HOWEVER YOU WANT
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

function DataManager:_affirm(statement, errorMsg) -- Similar to assert() but assert() has performance issues soo!
	if not statement then
		error(errorMsg)
	end
end

function DataManager:RemoveAsync(dataName)
	DataManager:_affirm(dataName, "You have to provide a valid 'dataName' in order to call :RemoveAsync")
	
	local foundDataBatch = 0; -- starts at 1

	local dataFound = nil;

	while true do
		foundDataBatch += 1

		local dataBatch = self.dataCollected[foundDataBatch] or self:_safecall(self.DataStore.GetAsync, self.DataStore, "DATA-BATCH" .. foundDataBatch)

		if dataBatch then
			if typeof(dataBatch) == "string" then
				dataBatch = self:_safecall(self.HttpService.JSONDecode, self.HttpService, dataBatch)
			end

			-- self.dataCollected[foundDataBatch] = dataBatch;

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

		local success = self:_safecall(self.DataStore.SetAsync, self.DataStore, "DATA-BATCH" .. foundDataBatch, dataFound)
		
		if success then
			-- self.dataCollected[foundDataBatch] = dataFound;
		end

		if success == nil and self._debug then
			warn(">> DATA FAILED TO REMOVE RETURNING WITH A NIL VALUE")
		end
	end
end

function DataManager:GetAsync(dataName)
	DataManager:_affirm(dataName, "You have to provide a valid 'dataName' in order to call :GetAsync")
	
	local foundDataBatch = 0; -- starts at 1

	local dataFound = nil;
	
	while true do
		foundDataBatch += 1

		local dataBatch = self.dataCollected[foundDataBatch] or self:_safecall(self.DataStore.GetAsync, self.DataStore, "DATA-BATCH" .. foundDataBatch)

		if dataBatch then
			if typeof(dataBatch) == "string" then
				dataBatch = self:_safecall(self.HttpService.JSONDecode, self.HttpService, dataBatch)
			end

			-- self.dataCollected[foundDataBatch] = dataBatch;

			if dataBatch then
				dataFound = dataBatch[dataName]

				if dataFound then
					break
				end
			end
			
			task.wait(1)
		else
			break
		end
	end

	return dataFound
end

function DataManager:SetAsync(dataName, dataValue)
	DataManager:_affirm(dataName, "You have to provide a valid 'dataName' in order to call :SetAsync")
	DataManager:_affirm(dataValue, "You have to provide a valid 'dataValue' in order to call :SetAsync")
	
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

	local success = self:_safecall(self.DataStore.SetAsync, self.DataStore, "DATA-BATCH" .. i, i_data)
	
	if success then
		-- self.dataCollected[i] = i_data;
	end

	if success == nil and self._debug then
		warn(">> DATA FAILED TO SAVE RETURNING WITH A NIL VALUE")
	end
end

function DataManager:ListKeysAsync(prefix, pageSize, cursor, excludeDeleted)
	prefix = prefix or "";
	pageSize = pageSize or 0;
	cursor = cursor or "";
	
	local success, Pages = self:_safecall(self.DataStore.ListKeysAsync, self.DataStore, prefix, pageSize, cursor, excludeDeleted)

	if success == nil then
		warn(">> DATA FAILED TO RETURN LIST KEYS ASYNC")
		
		return {};
	end

	local returnedData = {};
	
	while true do
		task.wait()

		local pageItems = Pages:GetCurrentPage()

		for _, data in pageItems do
			local entries = self.DataStore:GetAsync(data.KeyName)

			table.insert(returnedData, entries)
		end
		
		if Pages.IsFinished then 
			break 
		else 
			Pages:AdvanceToNextPageAsync() 
		end
	end
	
	return returnedData
end

function DataManager:UpdateAsync(keyName, transformFunction)
	DataManager:_affirm(keyName, "You have to provide a valid 'keyName' in order to call :UpdateAsync")
	DataManager:_affirm(transformFunction, "You have to provide a valid 'transformFunction' in order to call :RemoveAsync")
	
	DataManager:_affirm((typeof(keyName) == "string" or typeof(keyName) == "number"), "You have to provide a valid (string/number) 'dataValue' in order to call :UpdateAsync")
	DataManager:_affirm(typeof(transformFunction) == "function", "You have to provide a valid 'transformFunction' in order to call :RemoveAsync")
	
	local currentData = self:GetAsync(keyName);
	
	local newRecievedData = self:_safecall(transformFunction, currentData)
	
	if not newRecievedData then
		return;
	end
	
	self:SetAsync(keyName, newRecievedData)
end

return {
	new = DataManager.new
}
