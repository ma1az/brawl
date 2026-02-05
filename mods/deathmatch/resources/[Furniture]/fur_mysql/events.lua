instance = {
	hostname = "191.96.94.176",
	username = "u4760_3RnhfDmBjO",
	password = "FDdAoc^9!=mJTKEHuXGkwggB",
	database = "u4760_3RnhfDmBjO",
	port = 3306,

	db_conn = nil,

	db = function(self)
		self.db_conn = Connection("mysql","dbname="..self.database..";host="..self.hostname, self.username, self.password, "autoreconnect=1");
		if not self.db_conn then
			print('Could not connect to database.')
		else
			print('Connect to database.')
		end
	end,
}
addEventHandler('onResourceStart', resourceRoot, function() instance:db() end)
function getConnection() return instance.db_conn end