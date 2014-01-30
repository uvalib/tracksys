if Rails.env.development?
  %w[master_file jpeg_two_thousand].each do |c|
    require_dependency File.join(Rails.root, "app","models","#{c}.rb")
  end
end
