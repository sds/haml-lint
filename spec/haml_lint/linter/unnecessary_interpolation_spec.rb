require 'spec_helper'

describe HamlLint::Linter::UnnecessaryInterpolation do
  include_context 'linter'

  context 'when tag contains inline text without interpolation' do
    let(:haml) { '%tag Some inline text' }
    it { should_not report_lint }
  end

  context 'when tag contains inline text with some interpolation' do
    let(:haml) { '%tag Some #{interpolated} text' }
    it { should_not report_lint }
  end

  context 'when tag contains inline text with interpolation at the start' do
    let(:haml) { '%tag #{interpolation} -- #{more_interpolation}' }
    it { should_not report_lint }
  end

  context 'when tag contains inline text with only interpolation' do
    let(:haml) { '%tag #{only_interpolation}' }
    it { should report_lint }
  end

  context 'when tag contains nested content' do
    let(:haml) { <<-HAML }
      %tag
        \#{some_interpolation}
    HAML
    it { should_not report_lint }
  end
end
