class String
  def parameterize(separator = '-'.freeze)
    downcase.gsub(/\W/, separator).gsub('_'.freeze, separator)
  end

  def classify
    gsub('-'.freeze, '_'.freeze)
      .gsub(/\W/, ''.freeze)
      .split('_'.freeze)
      .map{|s| s.sub(/^[a-z\d]*/, &:capitalize) }.join
  end

  def constantize
    split('::'.freeze).inject(Object) do |constant, name|
      constant.const_get(name.classify)
    end
  end

  def underscore
    downcase.gsub('::'.freeze, '/'.freeze).gsub('-'.freeze, '_'.freeze)
  end

  def present?
    !empty?
  end

  def blank?
    nil? or empty?
  end
end
