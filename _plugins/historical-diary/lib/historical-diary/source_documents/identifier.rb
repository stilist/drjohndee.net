# frozen_string_literal: true

module HistoricalDiary
  module SourceDocuments
    # An identifier has a 'source key' and 'edition key', and optionally a
    # 'volume key'; the keys are combined into a string separated by `", "`. For
    # example, in the identifier `"Brief Lives, clarendon"`, the source key is
    # `"Brief Lives` and the edition key is `clarendon`. The source key should
    # match a Jekyll Data File that provides metadata about the source. (For
    # example, `_data/sources/Brief Lives.yaml`.)
    Identifier = Data.define(:source, :edition, :volume) do
      def initialize(source:, edition:, volume:)
        raise ArgumentError, 'source must not be nil' if source.nil?
        raise ArgumentError, 'edition must not be nil' if edition.nil?

        super
      end

      def to_s = [source, edition, volume].compact.join(', ')
    end
  end
end
