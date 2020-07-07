describe I18n::HTMLExtractor::Match::ErbDirectiveMatch do
  let(:document) do
    I18n::HTMLExtractor::ErbDocument.parse_string(erb_string)
  end
  let(:fragment) { document.erb_directives.keys.first }
  subject { described_class.create(document, fragment) }

  context 'when parsing *_fields' do
    let(:erb_string) { '<%= some.email_field :email, placeholder: "email", class: "some" %>' }

    it 'extracts placeholder' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives[fragment]).to eq(
        %Q(some.email_field :email, placeholder: t(".email"), class: "some")
      )
    end
  end

  context 'when parsing text_areas' do
    let(:erb_string) { '<%= some.text_area :text, placeholder: "some text", class: "some" %>' }

    it 'extracts placeholder' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives[fragment]).to eq(
        %Q(some.text_area :text, placeholder: t(".some_text"), class: "some")
      )
    end
  end

  context 'when parsing labels' do
    let(:erb_string) { '<%= some.label :email, "text" %>' }

    it 'extracts text' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives[fragment]).to eq(
        %Q(some.label :email, t(".text"))
      )
    end
  end

  context 'when parsing submit buttons' do
    let(:erb_string) { '<%= some.submit "text" %>' }

    it 'extracts text' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives[fragment]).to eq(
        %Q(some.submit t(".text"))
      )
    end
  end
end
