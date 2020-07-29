I18n HTML Extractor
---------------

# Introduction

Fork of a fork of a repo. I've improved to use the `it` gem for interpolated links and fix a few other bugs. Please note there are certain cases that are ignored/break as they were irrelevant to my context but needed for a "complete" feature set.

# Installation

```ruby
gem 'i18n-html_extractor', github: 'UsAndRufus/i18n-html_extractor'
```

# How it works

It scans all your HTML templates for strings and moves them to locales file.

Running `rake i18n:extract_html:auto`, all strings are moved to i18n locale file of your default language.

