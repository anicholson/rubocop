# encoding: utf-8

require 'spec_helper'

module Rubocop
  module Cop
    module Style
      describe Blocks do
        let(:cop) { Blocks.new }

        it 'accepts a multiline block with do-end' do
          inspect_source(cop, ['each do |x|',
                               'end'])
          expect(cop.offences).to be_empty
        end

        it 'registers an offence for a single line block with do-end' do
          inspect_source(cop, ['each do |x| end'])
          expect(cop.messages).to eq([Blocks::SINGLE_LINE_MSG])
        end

        it 'accepts a single line block with braces' do
          inspect_source(cop, ['each { |x| }'])
          expect(cop.offences).to be_empty
        end

        context 'when there are braces around a multi-line block' do
          it 'registers an offence in the simple case' do
            inspect_source(cop, ['each { |x|',
                                 '}'])
            expect(cop.messages).to eq([Blocks::MULTI_LINE_MSG])
          end

          it 'accepts braces if do-end would change the meaning' do
            src = ['scope :foo, lambda { |f|',
                   '  where(condition: "value")',
                   '}',
                   '',
                   'expect { something }.to raise_error(ErrorClass) { |error|',
                   '  # ...',
                   '}',
                   '',
                   'expect { x }.to change {',
                   '  Counter.count',
                   '}.from(0).to(1)']
            inspect_source(cop, src)
            expect(cop.offences).to be_empty
          end

          it 'registers an offence for braces if do-end would not change ' +
            'the meaning' do
            src = ['scope :foo, (lambda { |f|',
                   '  where(condition: "value")',
                   '})',
                   '',
                   'expect { something }.to(raise_error(ErrorClass) { |error|',
                   '  # ...',
                   '})']
            inspect_source(cop, src)
            expect(cop.offences).to have(2).items
          end

          it 'can handle special method names such as []= and done?' do
            src = ['h2[k2] = Hash.new { |h3,k3|',
                   '  h3[k3] = 0',
                   '}',
                   '',
                   'x = done? list.reject { |e|',
                   '  e.nil?',
                   '}']
            inspect_source(cop, src)
            expect(cop.messages).to eq([Blocks::MULTI_LINE_MSG])
          end
        end
      end
    end
  end
end
