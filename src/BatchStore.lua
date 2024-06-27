local DataManager = {}

-- This module is a module used to store a large amount of data, if you'd like more information and documentation PLEASE check https://github.com/aisarwinning/batchstore
-- FULL CREDITS GO TO @notaisar ON DISCORD

function DataManager.new(dataName) -- Creates a constructor function for the BatchStore data manager
	assert(dataName, "There needs to be a datastore name specified in order to construct a class") -- self:_affirm isn't used here because self isn't even defined yet

	local self = table.clone(DataManager) -- table.clone is less resource extensive than metatables

    -- general initializement of variables to be used throughout the script

	self.dataConstructed = os.time();
	self.dataCapacity = 150000; -- YOU CAN CHANGE HOWEVER YOU WANT
	self.dataCollected = {};

	self.DataStoreService = game:GetService("DataStoreService")
	self.HttpService = game:GetService("HttpService")

	self.DataStore = self.DataStoreService:GetDataStore(dataName)

	self._debug = true; -- set to true if you want to debug

	return self
end

function DataManager:_safecall(method, methodParent, ...) -- pcall function, used to easily pcall methods without having to write like 15 lines
	local success, err = pcall(method, methodParent, ...) -- run the pcall with the arguments from :_safecall

	if not success then -- if the pcall errors
		error(debug.traceback(err)) -- then error

		return nil
	end

	return err
end

function DataManager:_affirm(statement, errorMsg) -- similar to assert() but assert() has performance issues soo
	if not statement then
		error(errorMsg)
	end
end

function DataManager:RemoveAsync(dataName)
	DataManager:_affirm(dataName, "You have to provide a valid 'dataName' in order to call :RemoveAsync")
	
	local foundDataBatch = 0; -- starts at 1

	local dataFound = nil;

	while true do -- Run a while true do loop to find the key throughout the entire batch data store
		foundDataBatch += 1

		local dataBatch = self.dataCollected[foundDataBatch] or self:_safecall(self.DataStore.GetAsync, self.DataStore, "DATA-BATCH" .. foundDataBatch) -- run a pcall to getAsync every data batch

		if dataBatch then
			if typeof(dataBatch) == "string" then -- usually every data batch is encoded in json so we have to decode it
				dataBatch = self:_safecall(self.HttpService.JSONDecode, self.HttpService, dataBatch) -- we decode it here using HttpService:JSONDecode (. because pcall doesn't accept :)
			end

			if dataBatch[dataName] then -- if the data batch DOES exist then break the while loop
				dataFound = dataBatch;

				break
			end
		else
			break
		end

		task.wait(1) -- rate limit prevention :p
	end

	if dataFound then -- if the data is found then
		dataFound[dataName] = nil; -- remove it from the table

		local success = self:_safecall(self.DataStore.SetAsync, self.DataStore, "DATA-BATCH" .. foundDataBatch, dataFound) -- setAsync to save the data changes

		if success == nil and self._debug then
			warn(">> DATA FAILED TO REMOVE RETURNING WITH A NIL VALUE")
		end
	end
end

function DataManager:GetAsync(dataName)
	DataManager:_affirm(dataName, "You have to provide a valid 'dataName' in order to call :GetAsync")
	
	local foundDataBatch = 0; -- starts at 1

	local dataFound = nil;
	
	while true do -- while true do loop to run throug hevery key
		foundDataBatch += 1

		local dataBatch = self.dataCollected[foundDataBatch] or self:_safecall(self.DataStore.GetAsync, self.DataStore, "DATA-BATCH" .. foundDataBatch) -- get data of each data batch

		if dataBatch then
			if typeof(dataBatch) == "string" then -- like i said, every key is a string so decode it
				dataBatch = self:_safecall(self.HttpService.JSONDecode, self.HttpService, dataBatch)
			end

			-- self.dataCollected[foundDataBatch] = dataBatch;

			if dataBatch then -- if it does exist then return it
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

	local i = 0;
	local i_data = {}; -- create an empty table first

	while true do
		i += 1

		local dataBatch = self.dataCollected[i] or self:_safecall(self.DataStore.GetAsync, self.DataStore, "DATA-BATCH" .. i) -- getAsync to see if it exists to begin with

		if dataBatch then
			if dataBatch then
				local characterLeft = self:_safecall(self.HttpService.JSONEncode, self.HttpService, dataBatch)

				if string.len(characterLeft) >= self.dataCapacity then -- check how many characters are left first in the encode, skip to prevent overload (250,000 char limit of roblox)
					if self._debug then
						warn(">> SKIPPED OVER DATA-BATCH" .. i .. " DUE TO THERE BEING OVER " .. string.len(characterLeft) .. " CHARACTERS")
					end

					continue
				end

				i_data = dataBatch; -- set the variable so we can use it later

				break
			end
		else
			break
		end
	end

	i_data[dataName] = dataValue;

	local success = self:_safecall(self.DataStore.SetAsync, self.DataStore, "DATA-BATCH" .. i, i_data) -- set async the data :)

	if success == nil and self._debug then
		warn(">> DATA FAILED TO SAVE RETURNING WITH A NIL VALUE")
	end
end

function DataManager:ListKeysAsync(prefix, pageSize, cursor, excludeDeleted) -- used to get all keys in a batchstore datastore (or a regular datastore tbh)
    -- define defaults for variables

	prefix = prefix or "";
	pageSize = pageSize or 0;
	cursor = cursor or "";
	
	local success, Pages = self:_safecall(self.DataStore.ListKeysAsync, self.DataStore, prefix, pageSize, cursor, excludeDeleted) -- make sure to pcall incase anything errors

	if success == nil then -- oops error!
		warn(">> DATA FAILED TO RETURN LIST KEYS ASYNC")
		
		return {};
	end

	local returnedData = {};
	
	while true do -- while true do loop to get all datastore pages
		task.wait()

		local pageItems = Pages:GetCurrentPage() -- get the current page items

		for _, data in pageItems do -- run a loop thru them
			local entries = self.DataStore:GetAsync(data.KeyName) -- data.KeyName is the key name of the datastore key (sellf explanatory) and then we get it

			table.insert(returnedData, entries) -- insert it into the returned data (entries is plural because there's multiple in one data batch)
		end
		
		if Pages.IsFinished then -- if it's already finished, then just break
			break
		else
			Pages:AdvanceToNextPageAsync() -- advance to the next page if otherwise
		end
	end
	
	return returnedData
end

function DataManager:UpdateAsync(keyName, transformFunction) -- this is basically just :UpdateAsync from roblox but transported to BatchStore for easy changes
	DataManager:_affirm(keyName, "You have to provide a valid 'keyName' in order to call :UpdateAsync")
	DataManager:_affirm(transformFunction, "You have to provide a valid 'transformFunction' in order to call :RemoveAsync")
	
	DataManager:_affirm((typeof(keyName) == "string" or typeof(keyName) == "number"), "You have to provide a valid (string/number) 'dataValue' in order to call :UpdateAsync")
	DataManager:_affirm(typeof(transformFunction) == "function", "You have to provide a valid 'transformFunction' in order to call :RemoveAsync")
	
	local currentData = self:GetAsync(keyName); -- get the current data to begin with so we can pass it unto the transform function coming from the user
	
	local newRecievedData = self:_safecall(transformFunction, currentData) -- safecall the transform function using a pcall with the currentData
	
	if not newRecievedData then -- if it's nil, don't change anything
		return;
	end
	
	self:SetAsync(keyName, newRecievedData) -- otherwise, just change it :)
end

return {
	new = DataManager.new -- return just .new because that's really all we need
}
