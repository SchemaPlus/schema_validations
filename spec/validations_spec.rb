require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Validations" do

  before(:all) do
    define_schema
  end

  after(:each) do
    remove_all_models
  end

  context "auto-created" do
    before(:each) do
      with_auto_validations do
        class Article < ActiveRecord::Base ; end

        class Review < ActiveRecord::Base
          belongs_to :article
          belongs_to :news_article, :class_name => 'Article', :foreign_key => :article_id
          schema_validations :except => :content
        end
      end
    end

    it "should create validations for introspection with validators" do
      expect(Article.validators.map{|v| v.class.name.demodulize}.uniq).to match_array(%W[
        InclusionValidator
        LengthValidator
        NumericalityValidator
        PresenceValidator
        UniquenessValidator
      ])
    end

    it "should create validations for introspection with validators_on" do
      expect(Article.validators_on(:content).map{|v| v.class.name.demodulize}.uniq).to match_array(%W[
        PresenceValidator
      ])
    end

    it "should be valid with valid attributes" do
      expect(Article.new(valid_article_attributes)).to be_valid
    end

    it "should validate content presence" do
      expect(Article.new.error_on(:content).size).to eq(1)
    end

    it "should check title length" do
      expect(Article.new(:title => 'a' * 100).error_on(:title).size).to eq(1)
    end

    it "should validate state numericality" do
      expect(Article.new(:state => 'unknown').error_on(:state).size).to eq(1)
    end

    it "should validate if state is integer" do
      expect(Article.new(:state => 1.23).error_on(:state).size).to eq(1)
    end

    it "should validate average_mark numericality" do
      expect(Article.new(:average_mark => "high").error_on(:average_mark).size).to eq(1)
    end

    it "should validate boolean fields" do
      expect(Article.new(:active => nil).error_on(:active).size).to eq(1)
    end

    it "should validate title uniqueness" do
      article1 = Article.create(valid_article_attributes)
      article2 = Article.new(:title => valid_article_attributes[:title])
      expect(article2.error_on(:title).size).to eq(1)
      article1.destroy
    end

    it "should validate state uniqueness in scope of 'active' value" do
      article1 = Article.create(valid_article_attributes)
      article2 = Article.new(valid_article_attributes.merge(:title => 'SchemaPlus 2.0 released'))
      expect(article2).not_to be_valid
      article2.toggle(:active)
      expect(article2).to be_valid
      article1.destroy
    end

    it "should validate presence of belongs_to association" do
      review = Review.new
      expect(review.error_on(:article).size).to eq(1)
    end

    it "should validate uniqueness of belongs_to association" do
      article = Article.create(valid_article_attributes)
      expect(article).to be_valid
      review1 = Review.create(:article => article, :author => 'michal')
      expect(review1).to be_valid
      review2 = Review.new(:article => article, :author => 'michal')
      expect(review2.error_on(:article_id).size).to be >= 1
    end

    it "should validate associations with unmatched column and name" do
      expect(Review.new.error_on(:news_article).size).to eq(1)
    end

  end

  context "auto-created but changed" do
    before(:each) do
      with_auto_validations do
        class Article < ActiveRecord::Base ; end
        class Review < ActiveRecord::Base
          belongs_to :article
          belongs_to :news_article, :class_name => 'Article', :foreign_key => :article_id
        end
      end
      @too_big_content = 'a' * 1000
    end

    it "would normally have an error" do
      @review = Review.new(:content => @too_big_content)
      expect(@review.error_on(:content).size).to eq(1)
      expect(@review.error_on(:author).size).to eq(1)
    end

    it "shouldn't validate fields passed to :except option" do
      Review.schema_validations :except => :content
      @review = Review.new(:content => @too_big_content)
      expect(@review.errors_on(:content).size).to eq(0)
      expect(@review.error_on(:author).size).to eq(1)
    end

    it "shouldn't validate types passed to :except_type option using full validation" do
      Review.schema_validations :except_type => :validates_length_of
      @review = Review.new(:content => @too_big_content)
      expect(@review.errors_on(:content).size).to eq(0)
      expect(@review.error_on(:author).size).to eq(1)
    end

    it "shouldn't validate types passed to :except_type option using shorthand" do
      Review.schema_validations :except_type => :length
      @review = Review.new(:content => @too_big_content)
      expect(@review.errors_on(:content).size).to eq(0)
      expect(@review.error_on(:author).size).to eq(1)
    end

    it "should only validate type passed to :only_type option" do
      Review.schema_validations :only_type => :length
      @review = Review.new(:content => @too_big_content)
      expect(@review.error_on(:content).size).to eq(1)
      expect(@review.errors_on(:author).size).to eq(0)
    end


    it "shouldn't create validations if locally disabled" do
      Review.schema_validations :auto_create => false
      @review = Review.new(:content => @too_big_content)
      expect(@review.errors_on(:content).size).to eq(0)
      expect(@review.error_on(:author).size).to eq(0)
    end
  end

  context "auto-created disabled" do
    around(:each) do |example|
      with_auto_validations(false, &example)
    end

    before(:each) do
      class Review < ActiveRecord::Base
        belongs_to :article
        belongs_to :news_article, :class_name => 'Article', :foreign_key => :article_id
      end
      @too_big_content = 'a' * 1000
    end

    it "should not create validation" do
      expect(Review.new(:content => @too_big_title).errors_on(:content).size).to eq(0)
    end

    it "should create validation if locally enabled explicitly" do
      Review.schema_validations :auto_create => true
      expect(Review.new(:content => @too_big_content).error_on(:content).size).to eq(1)
    end

    it "should create validation if locally enabled implicitly" do
      Review.schema_validations
      expect(Review.new(:content => @too_big_content).error_on(:content).size).to eq(1)
    end

  end

  context "manually invoked" do
    before(:each) do
      class Article < ActiveRecord::Base ; end
      Article.schema_validations :only => [:title, :state]

      class Review < ActiveRecord::Base
        belongs_to :dummy_association
        schema_validations :except => :content
      end
    end

    it "should validate fields passed to :only option" do
      too_big_title = 'a' * 100
      wrong_state = 'unknown'
      article = Article.new(:title => too_big_title, :state => wrong_state)
      expect(article.error_on(:title).size).to eq(1)
      expect(article.error_on(:state).size).to eq(1)
    end

    it "shouldn't validate skipped fields" do
      article = Article.new
      expect(article.errors_on(:content).size).to eq(0)
      expect(article.errors_on(:average_mark).size).to eq(0)
    end

    it "shouldn't validate association on unexisting column" do
      expect(Review.new.errors_on(:dummy_association).size).to eq(0)
    end

    it "shouldn't validate fields passed to :except option" do
      expect(Review.new.errors_on(:content).size).to eq(0)
    end

    it "should validate all fields but passed to :except option" do
      expect(Review.new.error_on(:author).size).to eq(1)
    end

  end

  context "manually invoked" do
    before(:each) do
      class Review < ActiveRecord::Base
        belongs_to :article
      end
      @columns = Review.content_columns.dup
      Review.schema_validations :only => [:title]
    end

    it "shouldn't validate associations not included in :only option" do
      expect(Review.new.errors_on(:article).size).to eq(0)
    end

    it "shouldn't change content columns of the model" do
      expect(@columns).to eq(Review.content_columns)
    end

  end

  context "when used with STI" do
    around(:each) { |example| with_auto_validations(&example) }

    it "should set validations on base class" do
      class Review < ActiveRecord::Base ; end
      class PremiumReview < Review ; end
      PremiumReview.new
      expect(Review.new.error_on(:author).size).to eq(1)
    end

    it "shouldn't create doubled validations" do
      class Review < ActiveRecord::Base ; end
      Review.new
      class PremiumReview < Review ; end
      expect(PremiumReview.new.error_on(:author).size).to eq(1)
    end

  end

  context "when used with enum" do
    it "does not validate numericality" do
      class Article < ActiveRecord::Base
        enum :state => [:happy, :sad]
      end
      expect(Article.new(valid_article_attributes.merge(:state => :happy))).to be_valid
    end
  end if ActiveRecord::Base.respond_to? :enum

  protected
  def with_auto_validations(value = true)
    old_value = SchemaValidations.config.auto_create
    begin
      SchemaValidations.setup do |config|
        config.auto_create = value
      end
      yield
    ensure
      SchemaValidations.config.auto_create = old_value
    end
  end

  def define_schema
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        connection.tables.each do |table| drop_table table end

        create_table :articles, :force => true do |t|
          t.string :title, :limit => 50
          t.text  :content, :null => false
          t.integer :state
          t.float   :average_mark, :null => false
          t.boolean :active, :null => false
        end
        add_index :articles, :title, :unique => true
        add_index :articles, [:state, :active], :unique => true

        create_table :reviews, :force => true do |t|
          t.integer :article_id, :null => false
          t.string :author, :null => false
          t.string :content, :limit => 200
          t.string :type
        end
        add_index :reviews, :article_id, :unique => true

      end
    end
  end

  def valid_article_attributes
    {
      :title => 'SchemaPlus released!',
      :content => "Database matters. Get full use of it but don't write unecessary code. Get SchemaPlus!",
      :state => 3,
      :average_mark => 9.78,
      :active => true
    }
  end


end
