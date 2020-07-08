local qiwi_hook_id = config["qiwi_hook_id"]

local http_callback = nil;

http_backend_register('qiwi/set_callback', function (http_json)
	local server = http_json.callback
	return http_responce_ok_json("ok")
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

http_backend_register('qiwi/create_oplata', function(http_json)
	if not http_json.amount or not http_json.id or not http_json.billid then return http_responce_ok_json("Not enough parameters\n") end
	local expirationDateTime
	local data = {
		['amount'] = {
			['value'] = http_json.amount,
			['currency'] = 'RUB'
		},
		['customFields'] = {},
		['customer'] = {
			['account'] = http_json.id
		},
		['expirationDateTime'] = expirationDateTime
	}
	local themeCode = config.get('qiwi_themeCode')
	if themeCode then
		data['customFields']['themeCode'] = themeCode
	end
	local options = {
		host = 'api.qiwi.com',
		port = 80,
		path = string.format('/partner/bill/v1/bills/%s', http_json.billid),
		method = 'PUT',
		headers = {
			['Content-Type'] = 'application/json',
			['Accept'] = 'application/json',
			['Authorization'] = config.get('qiwi_secret_key')
		}
	}
end)
