run lambda { |env| env['REQUEST_PATH'] == '/' ? [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello World!\n")] : [404, {'Content-Type'=>'text/plain'}, StringIO.new("Not found\n")]}
