describe I18n::HTMLExtractor::Match::PlainTextMatch do
  let(:document) do
    I18n::HTMLExtractor::ErbDocument.parse_string(erb_string)
  end
  let(:node) { document.xpath('./div').first }
  subject { described_class.create(document, node) }

  context 'when parsing plain text' do
    let(:erb_string) { '<div>Some Text</div>' }

    it 'transforms text to erb directive' do
      expect(subject).to be_a(Array)
      subject.compact!
      result = subject.first
      expect(result.text).to eq('Some Text')
      result.replace_text!
      expect(node.text).to match(/^@@=.*@@$/)
      expect(document.erb_directives.keys.count).to eq(1)
    end
  end

  context 'when parsing plain text with spacing' do
    let(:erb_string) { "<div>\n       Some Text  \n    </div>" }

    it 'keeps spacing' do
      expect(subject).to be_a(Array)
      subject.compact!
      result = subject.first
      expect(result.text).to eq('Some Text')
      result.replace_text!
      expect(node.text).to match(/\s+@@=.*@@\s+/)
      expect(document.erb_directives.keys.count).to eq(1)
    end
  end

  context 'when parsing plain text that includes erb' do
    let(:erb_string) { "<div><% if a == b %>\n       Some Text\n      <% end %> Other text</div>" }
    let(:matched_text) { ['Some Text', 'Other text'] }
    it 'matches multiple elements' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(2)
      subject.each_with_index do |result, i|
        expect(result.text).to eq(matched_text[i])
        result.replace_text!
        expect(node.text).to match(/\s+@@=.*@@\s+/)
      end
      expect(document.erb_directives.keys.count).to eq(4)
    end
  end

  context 'when parsing plain text that contains a link directive' do
    let(:erb_string) { '<div>Some Text !@!= link_to "Hello"!@!</div>' }

    it 'ignores match and leaves it for the link matcher' do
      expect(subject).to be_nil
    end
  end

  context 'when parsing text that contains an interpolable erb directive' do
    let(:erb_string) { %Q(<div>
  Hey there, <%= current_user.name %>! We can't wait to interpolate you.
</div>
 )}
    it 'successfully combines the strings either side and interpolates the directives' do
      puts document.inspect
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives.count).to eq(1)
      expect(document.erb_directives.values.first).to eq(
          %Q(t(".hey_there_current_user_name_we_can_t_wai", current_user_name: current_user.name))
      )
    end
  end
end
