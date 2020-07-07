describe I18n::HTMLExtractor::Match::LinkMatch do
  let(:document) do
    I18n::HTMLExtractor::ErbDocument.parse_string(erb_string)
  end
  let(:fragment) { document.erb_directives.keys.first }
  subject { described_class.create(document, fragment) }

  context 'when parsing link_to' do
    let(:erb_string) { %Q(<%= link_to "Hello", some_url, title: "Some title" %>) }

    it 'extracts both text and title' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(2)
      subject.map(&:replace_text!)
      expect(document.erb_directives[fragment]).to eq(
           %Q(link_to t(".hello"), some_url, title: t(".some_title"))
       )
    end
  end
end
