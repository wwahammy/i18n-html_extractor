describe I18n::HTMLExtractor::Runner do
  describe '#run' do
    it 'replaces text in files' do
      with_file_copy(source_file) do |copy|
        runner = described_class.new(file_pattern: copy)

        runner.run

        expect_file_to_have_i18n(copy)
        expect_translations_to_be_present
      end
    end

    def expect_translations_to_be_present
      raw_translations = YAML.load(File.read("config/locales/en.yml"))
      translations = raw_translations.dig("en", "test_copied")

      aggregate_failures "translations" do
        expect(translations["hello"]).to eq "Hello"
        expect(translations["hello_title"]).to eq "hello-title"
        expect(translations["hi"]).to eq "Hi"
        expect(translations["my_textarea_placeholder"]).to eq "my textarea placeholder"
        expect(translations["my_input_placeholder"]).to eq "my input placeholder"
        expect(translations["here_i_have_a_super_cool_paragraph_with_"]).to eq "Here I have a super cool paragraph with an %{inline_link:inline link}.
  The text even carries on after - it's a miracle!!"
      end
    end

    def expect_file_to_have_i18n(copy)
      text = File.read(copy)
      expected_text = File.read(translated_source_file)

      expect(text).to eq expected_text
    end

    def with_file_copy(source_file)
      copy = create_copy_of_file_to_edit(source_file)
      copy_existing_translations

      yield copy

      clean_up_config_locale_file
      remove_file(copy)
    end

    def copy_existing_translations
      translations = YAML.load(File.read("config/locales/en.yml"))
      translations["en"]["test_copied"] = translations["en"]["test"]
      File.open("config/locales/en.yml", "w") do |file|
        file.rewind
        file.write(translations.to_yaml)
        file.close
      end
    end

    def clean_up_config_locale_file
      translations = YAML.load(File.read("config/locales/en.yml"))
      translations["en"].delete("test_copied")
      File.open("config/locales/en.yml", "w") do |file|
        file.rewind
        file.write(translations.to_yaml)
        file.close
      end
    end

    def remove_file(copy)
      FileUtils.rm(copy)
    end

    def create_copy_of_file_to_edit(source_file)
      FileUtils.cp(source_file, copied_file)
      copied_file
    end

    def copied_file
      "spec/files/test_copied.html.erb"
    end

    def translated_source_file
      "spec/files/test_translated.html.erb"
    end

    def source_file
      "spec/files/test.html.erb"
    end
  end
end
