# encoding: utf-8

require 'spec_helper'
require 'tempfile'

module Rubocop
  module Formatter
    describe FormatterSet do
      subject(:formatter_set) { FormatterSet.new }

      it 'responds to all formatter API methods' do
        [:started, :file_started, :file_finished, :finished].each do |method|
          expect(formatter_set).to respond_to(method)
        end
      end

      describe 'formatter API method' do
        before do
          formatter_set.add_formatter('simple')
          formatter_set.add_formatter('emacs')
        end

        let(:files) { ['/path/to/file1', '/path/to/file2'] }

        it 'invokes same method of all containing formatters' do
          formatter_set.each do |formatter|
            formatter.should_receive(:started).with(files)
          end
          formatter_set.started(files)
        end
      end

      describe 'add_formatter' do
        it 'adds a formatter to itself' do
          formatter_set.add_formatter('simple')
          expect(formatter_set).to have(1).item
        end

        it 'adds a formatter with specified formatter type' do
          formatter_set.add_formatter('simple')
          expect(formatter_set.first.class).to eq(SimpleTextFormatter)
        end

        it 'can add multiple formatters by being invoked multiple times' do
          formatter_set.add_formatter('simple')
          formatter_set.add_formatter('emacs')
          expect(formatter_set[0].class).to eq(SimpleTextFormatter)
          expect(formatter_set[1].class).to eq(EmacsStyleFormatter)
        end

        context 'when output path is omitted' do
          it 'adds a formatter outputs to $stdout' do
            formatter_set.add_formatter('simple')
            expect(formatter_set.first.output).to eq($stdout)
          end
        end

        context 'when output path is specified' do
          it 'adds a formatter outputs to the specified file' do
            output_path = Tempfile.new('').path
            formatter_set.add_formatter('simple', output_path)
            expect(formatter_set.first.output.class).to eq(File)
            expect(formatter_set.first.output.path).to eq(output_path)
          end
        end
      end

      describe '#close_output_files' do
        before do
          2.times do
            output_path = Tempfile.new('').path
            formatter_set.add_formatter('simple', output_path)
          end
          formatter_set.add_formatter('simple')
        end

        it 'closes all output files' do
          formatter_set.close_output_files
          formatter_set[0..1].each do |formatter|
            expect(formatter.output).to be_closed
          end
        end

        it 'does not close non file output' do
          expect(formatter_set[2].output).not_to be_closed
        end
      end

      describe '#builtin_formatter_class' do
        def builtin_formatter_class(string)
          FormatterSet.new.send(:builtin_formatter_class, string)
        end

        it 'returns class which matches passed alias name exactly' do
          expect(builtin_formatter_class('simple'))
            .to eq(SimpleTextFormatter)
        end

        it 'returns class whose first letter of alias name ' +
           'matches passed letter' do
          expect(builtin_formatter_class('s'))
            .to eq(SimpleTextFormatter)
        end
      end

      describe '#custom_formatter_class' do
        def custom_formatter_class(string)
          FormatterSet.new.send(:custom_formatter_class, string)
        end

        it 'returns constant represented by the passed string' do
          expect(custom_formatter_class('Rubocop')).to eq(Rubocop)
        end

        it 'can handle namespaced constant name' do
          expect(custom_formatter_class('Rubocop::CLI')).to eq(Rubocop::CLI)
        end

        it 'can handle top level namespaced constant name' do
          expect(custom_formatter_class('::Rubocop::CLI')).to eq(Rubocop::CLI)
        end

        context 'when non-existent constant name is passed' do
          it 'raises error' do
            expect { custom_formatter_class('Rubocop::NonExistentClass') }
              .to raise_error(NameError)
          end
        end
      end
    end
  end
end
