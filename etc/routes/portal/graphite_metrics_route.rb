add_route(:name => "graphite", :type => ["metric", "status"]) do |event, routes|
    routes << "/queue/unimatrix.test.graphite"
end
