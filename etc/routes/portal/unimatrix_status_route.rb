add_route(:name => "unimatrix_status", :type => ["status", "alert"]) do |event, routes|
    routes << "/queue/unimatrix.test.status"
end
