require_relative 'term'

module MetaDB

  class Vocabulary

    attr_reader :session, :name

    def initialize(session, name, terms = [])
      @session = session
      @name = name
      @terms = terms
    end

    def read(limit = nil)
      query = "SELECT contents FROM controlled_vocab WHERE vocab_name=$1"
      query += " LIMIT #{limit}" unless limit.nil?

      res = @session.conn.exec_params(query, [@name])

      res.each do | term_record |
        term_values = term_record['contents']
        term_values.split(/;/).each do |term_value|
          @terms << Term.new(self, term_value)
        end
      end
    end

    def export
      read
      {
        :vocabulary => @name,
        :terms => @terms.map { |term| term.export }
      }
    end
  end
end
