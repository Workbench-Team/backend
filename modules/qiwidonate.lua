local qiwi_hook_id = config["qiwi_hook_id"]

local http_callback = nil;

http_backend_register('qiwi/set_callback', function (http_json)
	local server = http_json.callback
	return http_response_ok_json("ok")
end)

--[[http.createServer("0.0.0.0", 4080, function (head, body)
p(body)

if not head.method == 'POST' then return { code = 405, {"Server", "Natsuki bot"}, {"Content-Length", 11} }, "Fuck you!\n" end

local body_json = json.decode(body)

if not body_json["hookId"] == qiwi_hook_id then return { code = 401 }, "\n" end
if body_json["test"] == true then print('Test hook!') return { code = 200, {"Server", "Natsuki bot"}, {"Content-Type", "text/plain"}, {"Content-Length", 1}, }, "\n" end
if not body_json["payment"] == "SUCCESS" then return { code = 200, {"Server", "Natsuki bot"}, {"Content-Type", "text/plain"}, {"Content-Length", 1}, }, "\n" end

donation_new( body_json["payment"]["total"]["amount"], body_json["payment"]["total"]["currency"], body_json["payment"]["comment"], body_json["payment"]["txnId"], body_json["payment"]["date"] )

return { code = 200, {"Server", "Natsuki bot"}, {"Content-Type", "text/plain"}, {"Content-Length", 12}, }, "Hello World\n"
end)]]

http_backend_register('qiwi/create_payment', function(res, http_json)
	if not http_json.amount or not http_json.id or not http_json.billid then return http_responce_error_json(res, "Not enough parameters\n") end
	local expirationDateTime = os.time() + 60*60*24*7
	expirationDateTime = os.date('%Y-%m-%dT%H:%M:%S+00:00', expirationDateTime)
	local data = {
		['amount'] = {
			['value'] = http_json.amount,
			['currency'] = 'RUB'
		},
		['customFields'] = {},
		['customer'] = {
			['account'] = http_json.id
		},
		['expirationDateTime'] = expirationDateTime,
	}
	local themeCode = config.get('qiwi_themeCode')
	if themeCode then
		data['customFields']['themeCode'] = themeCode
	end
	local json_data = json.encode(data)
	p(json_data)
	local options = {
		host = 'api.qiwi.com',
		port = 443,
		path = string.format('/partner/bill/v1/bills/%s', http_json.billid),
		method = 'PUT',
		headers = {
			{'Content-Type', 'application/json'},
			{'Content-Length', #json_data},
			{'Accept', 'application/json'},
			{'Authorization', config.get('qiwi_secret_key')}
		}
	}
	local response_data = {}
	local req = https.request(options, function(res)
		local buffer = {}
		res:on('data', function(chunk)
			table.insert(buffer, chunk)
		end)
		res:on('error', function(error)
			p("Error: ", error)
			local error_str = json.encode(error)
			http_response_error_json(res, string.format('Error has occurred: { %s }', error_str))
		end)
		res:on('end', function()
			response_data = json.decode(buffer[1])
			if response_data.payUrl and response_data.billId then
				return http_response_ok_json(res, response_data.payUrl)
			else
				return http_response_error_json(res, json.encode(response_data))
			end
		end)
	end)
	req:done(json_data)
end)
