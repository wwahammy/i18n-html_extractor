describe 'tasks' do
  before(:each) { FileUtils.cp_r("#{Rails.root}/spec/files", "#{Rails.root}/spec/tmp") }
  after(:each) { FileUtils.rm_rf("#{Rails.root}/spec/tmp") }

  describe 'i18n:extract_html:auto' do
    it 'Returns and replaces a list of matched data' do
      expect do
        expect do
          expect do
            Rake::Task['i18n:extract_html:auto'].invoke('spec/tmp/folder/minimal/*.erb')
          end.to output(/Found "Hello".*/).to_stdout
        end.not_to raise_exception
      end.to change { File.read('spec/tmp/folder/minimal/file.html.erb') }.to('<%= link_to t(".hello") %>')
        .and(change { File.read('spec/tmp/folder/minimal/bug.html.erb') }.to('<div><%= t(".hello") %></div>'))
    end
  end
end
