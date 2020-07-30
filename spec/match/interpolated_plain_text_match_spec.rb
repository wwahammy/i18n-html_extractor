describe I18n::HTMLExtractor::Match::InterpolatedPlainTextMatch do
  let(:document) do
    I18n::HTMLExtractor::ErbDocument.parse_string(erb_string)
  end
  let(:node) { document.xpath('./div').first }
  subject { described_class.create(document, node) }

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
      expect(subject.first.text).to eq("Hey there, %{current_user_name}! We can't wait to interpolate you.")
      subject.map(&:replace_text!)
      expect(document.erb_directives.count).to eq(1)
      expect(document.erb_directives.values.first).to eq(
          %Q(t(".hey_there_current_user_name_we_can_t_wai", current_user_name: current_user.name))
      )
    end

    context 'when parsing text that contains multiple interpolable erb directives' do
      let(:erb_string) { %Q(<div>
  Hey there, <%= current_user.name %>! We can't wait to interpolate <%= you %>.
</div>
 )}
      it 'successfully combines the strings and interpolates the directives' do
        puts document.inspect
        expect(subject).to be_a(Array)
        subject.compact!
        expect(subject.count).to eq(1)
        expect(subject.first.text).to eq("Hey there, %{current_user_name}! We can't wait to interpolate %{you}.")
        subject.map(&:replace_text!)
        expect(document.erb_directives.count).to eq(1)
        expect(document.erb_directives.values.first).to eq(
            %Q(t(".hey_there_current_user_name_we_can_t_wai", current_user_name: current_user.name, you: you))
        )
      end
    end
  end
end

