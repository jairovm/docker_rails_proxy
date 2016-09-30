class String
  def parameterize(separator = '-'.freeze)
    downcase.gsub(/\W/, separator).gsub('_'.freeze, separator)
  end

  def classify
    gsub(/\W/, ''.freeze)
      .gsub('_'.freeze, ''.freeze)
      .sub(/^[a-z\d]*/, &:capitalize)
  end

  def constantize
    split('::'.freeze).inject(Object) do |constant, name|
      constant.const_get(name.classify)
    end
  end

  def underscore
    downcase.gsub('::'.freeze, '/'.freeze).gsub('-'.freeze, '_'.freeze)
  end
end
