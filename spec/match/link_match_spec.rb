describe I18n::HTMLExtractor::Match::LinkMatch do
  let(:document) do
    I18n::HTMLExtractor::ErbDocument.parse_string(erb_string)
  end
  let(:node) { document.xpath('./p').first }
  subject { described_class.create(document, node) }

  context 'when parsing a link_to on its own' do
    let(:erb_string) { %Q(<p><%= link_to "Hello", some_url %></p>) }

    it 'still use it' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives.values.first).to eq(
          %Q(!i!t(".hello", hello: It.link(some_url)))
      )
    end
  end

  context 'when parsing link_to with a title' do
    let(:erb_string) { %Q(<p><%= link_to "Hello", some_url, title: "Some title" %></p>) }

    # it 'extracts both text and title' do
    #   expect(subject).to be_a(Array)
    #   subject.compact!
    #   expect(subject.count).to eq(2)
    #   subject.map(&:replace_text!)
    #   expect(document.erb_directives.values.first).to eq(
    #        %Q(link_to t(".hello"), some_url, title: t(".some_title"))
    #    )
    # end

    it 'extracts only text and ignores title' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives.values.first).to eq(
           %Q(!i!t(".hello", hello: It.link(some_url, title: "Some title")))
       )
    end
  end

  context 'when parsing a link that only has one parameter' do
    let(:erb_string) { %Q(<p><%= link_to "Hello" %></p>) }

    it 'extracts the text' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives.values.first).to eq(
          %Q(!i!t(".hello", hello: It.link()))
      )
    end
  end

  context 'when parsing a node without a link' do
    let(:erb_string) { "<p>\n  Some Text\n  </p>" }

    it 'returns nil' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(0)
    end
  end

  context 'when parsing link_to in the middle of a tag' do
    let(:erb_string) { %Q(<p>I would just like to say <%= link_to "Hello", some_url %> to you my friend!</p>) }

    it 'extracts surrounding and the link' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives.values.first).to eq(
           %Q(!i!t(".i_would_just_like_to_say_hello_to_you_my", hello: It.link(some_url)))
       )
    end
  end

  context 'when parsing link_to in the middle of a tag with extra attributes' do
    let(:erb_string) { %Q(<p>I would just like to say <%= link_to "Hello", some_url, class: "my-cool-link" %> to you my friend!</p>) }

    it 'extracts surrounding and the link' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives.values.first).to eq(
           %Q(!i!t(".i_would_just_like_to_say_hello_to_you_my", hello: It.link(some_url, class: "my-cool-link")))
       )
    end
  end

  context 'when parsing link_to in a tag that has newlines' do
    let(:erb_string) { %Q(
    <p>
        Here I have a super cool paragraph with an <%= link_to "inline link", "www.example.com", class: "my-cool-link" %>.\n
        The text even carries on after - it's a miracle!!
    </p>
    ) }

    it 'extracts surrounding and the link' do
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives.values.first).to eq(
          %Q(!i!t(".here_i_have_a_super_cool_paragraph_with_", inline_link: It.link("www.example.com", class: "my-cool-link")))
      )
    end
  end

  context 'when parsing a link_to that already has a t() tag as its name' do
    let(:erb_string) { %Q(<p><%= link_to t('.cool_link_name'), some_url %></p>) }

    it 'leaves link as is' do
      puts node
      expect(subject).to be_a(Array)
      subject.compact!
      expect(subject.count).to eq(1)
      subject.map(&:replace_text!)
      expect(document.erb_directives.values.first).to eq(
          %Q(link_to t('.cool_link_name'), some_url)
      )
      puts node
    end
  end
end
