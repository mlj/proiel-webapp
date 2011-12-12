def normalize_unicode_params!(params, *fields)
  if params
    fields.each do |field|
      if params.has_key?(field)
        if params[field] == ''
          params[field] = nil
        elsif params[field].is_a?(String)
          params[field] = params[field].mb_chars.normalize(UNICODE_NORMALIZATION_FORM)
        end
      end
    end
  end
end
