module MetaDB

  class Term

    attr_reader :session, :name

    def initialize(vocabulary, value)
      @vocabulary = vocabulary
      @value = value
    end

    def export
      @value
    end
  end
end
