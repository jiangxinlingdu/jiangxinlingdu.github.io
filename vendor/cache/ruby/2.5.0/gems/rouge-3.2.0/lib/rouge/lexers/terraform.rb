# -*- coding: utf-8 -*- #

module Rouge
  module Lexers
    load_lexer 'hcl.rb'

    class Terraform < Hcl
      title "Terraform"
      desc "Terraform HCL Interpolations"

      tag 'terraform'
      aliases 'tf'
      filenames '*.tf'

      def self.keywords
        @keywords ||= Set.new %w(
          terraform module provider variable resource data provisioner output
        )
      end

      def self.declarations
        @declarations ||= Set.new %w(
          var local
        )
      end

      def self.reserved
        @reserved ||= Set.new %w()
      end

      def self.constants
        @constants ||= Set.new %w(true false null)
      end

      def self.builtins
        @builtins ||= %w()
      end

      state :strings do
        rule /\\./, Str::Escape
        rule /\$\{/ do
          token Keyword
          push :interpolation
        end
      end

      state :dq do
        rule /[^\\"\$]+/, Str::Double
        mixin :strings
        rule /"/, Str::Double, :pop!
      end

      state :sq do
        rule /[^\\'\$]+/, Str::Single
        mixin :strings
        rule /'/, Str::Single, :pop!
      end

      state :heredoc do
        rule /\n/, Str::Heredoc, :heredoc_nl
        rule /[^$\n\$]+/, Str::Heredoc
        rule /[$]/, Str::Heredoc
        mixin :strings
      end

      state :interpolation do
        rule /\}/ do
          token Keyword
          pop!
        end

        mixin :expression
      end

      id = /[$a-z_\-][a-z0-9_\-]*/io

      state :expression do
        mixin :primitives
        rule /\s+/, Text

        rule %r(\+\+ | -- | ~ | && | \|\| | \\(?=\n) | << | >>>? | == | != )x, Operator
        rule %r([-<>+*%&|\^/!=?:]=?), Operator
        rule /[(\[,]/, Punctuation
        rule /[)\].]/, Punctuation

        rule id do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          elsif self.class.declarations.include? m[0]
            token Keyword::Declaration
          elsif self.class.reserved.include? m[0]
            token Keyword::Reserved
          elsif self.class.constants.include? m[0]
            token Keyword::Constant
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          else
            token Name::Other
          end
        end
      end
    end
  end
end
