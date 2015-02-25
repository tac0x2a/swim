# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require_relative 'spec_helper'

#require_relative '../lib/yasuri/yasuri'

describe 'Yasuri' do
  include_context 'httpserver'

  before do
    @agent = Mechanize.new
    @uri = uri
    @index_page = @agent.get(@uri)
  end

  ########
  # Node #
  ########
  def compare_generated_vs_original(generated, original, page = @index_page)
    expected = original.inject(@agent, page)
    actual   = generated.inject(@agent, page)
    expect(actual).to match expected
  end

  ########
  # Text #
  ########
  describe '::TextNode' do
    before { @node = Yasuri::TextNode.new('/html/body/p[1]', "title") }

    it 'scrape text text <p>Hello,Yasuri</p>' do
      actual = @node.inject(@agent, @index_page)
      expect(actual).to eq "Hello,Yasuri"
    end

    it 'return empty text if no match node' do
      no_match_node = Yasuri::TextNode.new('/html/body/no_match_node', "title")
      actual = no_match_node.inject(@agent, @index_page)
      expect(actual).to be_empty
    end

    it 'fail with invalid xpath' do
      invalid_xpath = '/html/body/no_match_node['
      node = Yasuri::TextNode.new(invalid_xpath, "title")
      expect { node.inject(@agent, @index_page) }.to raise_error
    end

    it "can be defined by DSL, return single TextNode title" do
      generated = Yasuri.text_title '/html/body/p[1]'
      original  = Yasuri::TextNode.new('/html/body/p[1]', "title")
      compare_generated_vs_original(generated, original)
    end

    it "can be truncated with regexp" do
      node  = Yasuri.text_title '/html/body/p[1]', /^[^,]+/
      actual = node.inject(@agent, @index_page)
      expect(actual).to eq "Hello"
    end

    it "can be truncated with regexp" do
      node = Yasuri.text_title '/html/body/p[1]', /[^,]+$/
      actual = node.inject(@agent, @index_page)
      expect(actual).to eq "Yasuri"
    end

    it "return empty string if truncated with no match to regexp" do
      node = Yasuri.text_title '/html/body/p[1]', /^hoge/
      actual = node.inject(@agent, @index_page)
      expect(actual).to be_empty
    end
  end

  ##########
  # Struct #
  ##########
  describe '::StructNode' do
    before do
      @page = @agent.get(@uri + "/structual_text.html")
      @table_1996 = [
        { "title"    => "The Perfect Insider",
          "pub_date" => "1996/4/5" },
        { "title"    => "Doctors in Isolated Room",
          "pub_date" => "1996/7/5" },
        { "title"    => "Mathematical Goodbye",
          "pub_date" => "1996/9/5" },
      ]
      @table_1997 = [
        { "title"    => "Jack the Poetical Private",
          "pub_date" => "1997/1/5" },
        { "title"    => "Who Inside",
          "pub_date" => "1997/4/5" },
        { "title"    => "Illusion Acts Like Magic",
          "pub_date" => "1997/10/5" },
      ]
      @table_1998 = [
        { "title"    => "Replaceable Summer",
          "pub_date" => "1998/1/7" },
        { "title"    => "Switch Back",
          "pub_date" => "1998/4/5" },
        { "title"    => "Numerical Models",
          "pub_date" => "1998/7/5" },
        { "title"    => "The Perfect Outsider",
          "pub_date" => "1998/10/5" },
      ]
      @all_tables = [
        {"table" => @table_1996},
        {"table" => @table_1997},
        {"table" => @table_1998},
      ]
    end
    it 'scrape single table contents' do
      node = Yasuri::StructNode.new('/html/body/table[1]/tr', "table", [
        Yasuri::TextNode.new('./td[1]', "title"),
        Yasuri::TextNode.new('./td[2]', "pub_date"),
      ])
      expected = @table_1996
      actual = node.inject(@agent, @page)
      expect(actual).to match expected
    end

    it 'return empty text if no match node' do
      no_match_xpath = '/html/body/table[1]/t'
      node = Yasuri::StructNode.new(no_match_xpath, "table", [
        Yasuri::TextNode.new('./td[1]', "title")
      ])
      actual = node.inject(@agent, @page)
      expect(actual).to be_empty
    end

    it 'fail with invalid xpath' do
      invalid_xpath = '/html/body/table[1]/table[1]/tr['
      node = Yasuri::StructNode.new(invalid_xpath, "table", [
        Yasuri::TextNode.new('./td[1]', "title")
      ])
      expect { node.inject(@agent, @page) }.to raise_error
    end

    it 'fail with invalid xpath in children' do
      invalid_xpath = './td[1]['
      node = Yasuri::StructNode.new('/html/body/table[1]/tr', "table", [
        Yasuri::TextNode.new(invalid_xpath, "title"),
        Yasuri::TextNode.new('./td[2]', "pub_date"),
      ])
      expect { node.inject(@agent, @page) }.to raise_error
    end

    it 'scrape all tables' do
      node = Yasuri::StructNode.new('/html/body/table', "tables", [
        Yasuri::StructNode.new('./tr', "table", [
          Yasuri::TextNode.new('./td[1]', "title"),
          Yasuri::TextNode.new('./td[2]', "pub_date"),
        ])
      ])
      expected = @all_tables
      actual = node.inject(@agent, @page)
      expect(actual).to match expected
    end

    it 'can be defined by DSL, scrape all tables' do
      generated = Yasuri.struct_tables '/html/body/table' do
        struct_table './tr' do
          text_title    './td[1]'
          text_pub_date './td[2]'
        end
      end
      original = Yasuri::StructNode.new('/html/body/table', "tables", [
        Yasuri::StructNode.new('./tr', "table", [
          Yasuri::TextNode.new('./td[1]', "title"),
          Yasuri::TextNode.new('./td[2]', "pub_date"),
        ])
      ])
      compare_generated_vs_original(generated, original)
    end
  end

  #########
  # Links #
  #########
  describe '::LinksNode' do
    it 'scrape links' do
      root_node = Yasuri::LinksNode.new('/html/body/a', "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])

      actual = root_node.inject(@agent, @index_page)
      expected = [
        {"content" => "Child 01 page."},
        {"content" => "Child 02 page."},
        {"content" => "Child 03 page."},
      ]
      expect(actual).to match expected
    end

    it 'return empty set if no match node' do
      missing_xpath = '/html/body/b'
      root_node = Yasuri::LinksNode.new(missing_xpath, "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])

      actual = root_node.inject(@agent, @index_page)
      expect(actual).to be_empty
    end

    it 'scrape links, recursive' do
      root_node = Yasuri::LinksNode.new('/html/body/a', "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
        Yasuri::LinksNode.new('/html/body/ul/li/a', "sub_link", [
          Yasuri::TextNode.new('/html/head/title', "sub_page_title"),
        ]),
      ])
      actual = root_node.inject(@agent, @index_page)
      expected = [
        {"content"  => "Child 01 page.",
         "sub_link" => [{"sub_page_title" => "Child 01 SubPage Test"},
                        {"sub_page_title" => "Child 02 SubPage Test"}],},
        {"content" => "Child 02 page.",
         "sub_link" => [],},
        {"content" => "Child 03 page.",
         "sub_link" => [{"sub_page_title" => "Child 03 SubPage Test"}],},
      ]
      expect(actual).to match expected
    end
    it 'can be defined by DSL, return single LinkNode title' do
      generated = Yasuri.links_title '/html/body/a'
      original  = Yasuri::LinksNode.new('/html/body/a', "title")
      compare_generated_vs_original(generated, original)
    end
    it 'can be defined by DSL, return nested contents under link' do
      generated = Yasuri.links_title '/html/body/a' do
                     text_name '/html/body/p'
                  end
      original = Yasuri::LinksNode.new('/html/body/a', "root", [
        Yasuri::TextNode.new('/html/body/p', "name"),
      ])
      compare_generated_vs_original(generated, original)
    end

    it 'can be defined by DSL, return recursive links node' do
      generated = Yasuri.links_root '/html/body/a' do
        text_content '/html/body/p'
        links_sub_link '/html/body/ul/li/a' do
          text_sub_page_title '/html/head/title'
        end
      end

      original = Yasuri::LinksNode.new('/html/body/a', "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
        Yasuri::LinksNode.new('/html/body/ul/li/a', "sub_link", [
          Yasuri::TextNode.new('/html/head/title', "sub_page_title"),
        ]),
      ])
      compare_generated_vs_original(generated, original)
    end
  end

  ############
  # Paginate #
  ############
  describe '::PaginateNode' do
    before do
      @uri += "/pagination/page01.html"
      @page = @agent.get(@uri)
    end

    it "scrape each paginated pages" do
      root_node = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])
      actual = root_node.inject(@agent, @page)
      expected = [
        {"content" => "PaginationTest01"},
        {"content" => "PaginationTest02"},
        {"content" => "PaginationTest03"},
        {"content" => "PaginationTest04"},
      ]
      expect(actual).to match expected
    end

    it "scrape each paginated pages limited" do
      root_node = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ], limit:3)
      actual = root_node.inject(@agent, @page)
      expected = [
        {"content" => "PaginationTest01"},
        {"content" => "PaginationTest02"},
        {"content" => "PaginationTest03"},
      ]
      expect(actual).to match expected
    end


    it 'return first content if paginate link node is not found' do
      missing_xpath = "/html/body/nav/span/b[@class='next']"
      root_node = Yasuri::PaginateNode.new(missing_xpath, "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])
      actual = root_node.inject(@agent, @page)
      expected = [ {"content" => "PaginationTest01"}, ]
      expect(actual).to match_array expected
    end

    it 'return empty hashes if content node is not found' do
      root_node = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Yasuri::TextNode.new('/html/body/hoge', "content"),
      ])
      actual = root_node.inject(@agent, @page)
      expected = [ {"content" => ""}, {"content" => ""}, {"content" => ""}, {"content" => ""},]
      expect(actual).to match_array expected
    end

    it 'can be defined by DSL, return single PaginateNode content' do
      generated = Yasuri.pages_next "/html/body/nav/span/a[@class='next']" do
        text_content '/html/body/p'
      end
      original = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])
      compare_generated_vs_original(generated, original, @page)
    end

    it 'can be defined by DSL, return single PaginateNode content limited' do
      generated = Yasuri.pages_next "/html/body/nav/span/a[@class='next']", 2 do
        text_content '/html/body/p'
      end
      original = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ], limit: 2)
      compare_generated_vs_original(generated, original, @page)
    end
  end

  #############
  # json2tree #
  #############
  describe '.json2tree' do
    it "return empty tree" do
      tree = Yasuri.json2tree("{}")
      expect(tree).to be_nil
    end

    it "return TextNode" do
      src = %q| { "node"  : "text",
                  "name"  : "content",
                  "path"  : "/html/body/p[1]"
                }|
      generated = Yasuri.json2tree(src)
      original  = Yasuri::TextNode.new('/html/body/p[1]', "content")
      compare_generated_vs_original(generated, original)
    end

    it "return TextNode with truncate_regexp" do
      src = %q| { "node"  : "text",
                  "name"  : "content",
                  "path"  : "/html/body/p[1]",
                  "truncate"  : "^[^,]+"
                }|
      generated = Yasuri.json2tree(src)
      original  = Yasuri::TextNode.new('/html/body/p[1]', "content", truncate_regexp:/^[^,]+/)
      compare_generated_vs_original(generated, original)
    end


    it "return LinksNode/TextNode" do
      src = %q| { "node"     : "links",
                  "name"     : "root",
                  "path"     : "/html/body/a",
                  "children" : [ { "node" : "text",
                                   "name" : "content",
                                   "path" : "/html/body/p"
                                 } ]
                }|
      generated = Yasuri.json2tree(src)
      original  = Yasuri::LinksNode.new('/html/body/a', "root", [
                    Yasuri::TextNode.new('/html/body/p', "content"),
                  ])
      compare_generated_vs_original(generated, original)
    end

    it "return PaginateNode/TextNode" do
      src = %q|{ "node"     : "pages",
                 "name"     : "root",
                 "path"     : "/html/body/nav/span/a[@class=\'next\']",
                 "children" : [ { "node" : "text",
                                  "name" : "content",
                                  "path" : "/html/body/p"
                                } ]
               }|
      generated = Yasuri.json2tree(src)
      original = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
                   Yasuri::TextNode.new('/html/body/p', "content"),
                 ])

      paginate_test_uri  = @uri + "/pagination/page01.html"
      paginate_test_page = @agent.get(paginate_test_uri)
      compare_generated_vs_original(generated, original, paginate_test_page)
    end

    it "return PaginateNode/TextNode with limit" do
      src = %q|{ "node"     : "pages",
                 "name"     : "root",
                 "path"     : "/html/body/nav/span/a[@class=\'next\']",
                 "limit"    : 2,
                 "children" : [ { "node" : "text",
                                  "name" : "content",
                                  "path" : "/html/body/p"
                                } ]
               }|
      generated = Yasuri.json2tree(src)
      original = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
                   Yasuri::TextNode.new('/html/body/p', "content"),
                 ], limit:2)

      paginate_test_uri  = @uri + "/pagination/page01.html"
      paginate_test_page = @agent.get(paginate_test_uri)
      compare_generated_vs_original(generated, original, paginate_test_page)
    end

    it "return StructNode/StructNode/[TextNode,TextNode]" do
     src = %q| { "node"     : "struct",
                 "name"     : "tables",
                 "path"     : "/html/body/table",
                 "children" : [
                   { "node"       : "struct",
                     "name"       : "table",
                     "path"       : "./tr",
                     "children"   : [
                       { "node" : "text",
                         "name" : "title",
                         "path" : "./td[1]"
                       },
                       { "node" : "text",
                         "name" : "pub_date",
                         "path" : "./td[2]"
                       }]
                   }]
               }|
      generated = Yasuri.json2tree(src)
      original  = Yasuri::StructNode.new('/html/body/table', "tables", [
        Yasuri::StructNode.new('./tr', "table", [
          Yasuri::TextNode.new('./td[1]', "title"),
          Yasuri::TextNode.new('./td[2]', "pub_date"),
        ])
      ])
      page = @agent.get(@uri + "/structual_text.html")
      compare_generated_vs_original(generated, original, page)
    end
  end

  #############
  # tree2json #
  #############
  describe '.tree2json' do
    it "return empty json" do
      json = Yasuri.tree2json(nil)
      expect(json).to be_empty
    end

    it "return text node" do
      node = Yasuri::TextNode.new("/html/head/title", "title")
      json = Yasuri.tree2json(node)
      expected_str = %q| { "node": "text",
                           "name": "title",
                           "path": "/html/head/title"
                         } |
      expected = JSON.parse(expected_str)
      expect(json).to match expected
    end

    it "return LinksNode/TextNode" do
      tree  = Yasuri::LinksNode.new('/html/body/a', "root", [
                Yasuri::TextNode.new('/html/body/p', "content"),
              ])
      actual   = Yasuri.tree2json(tree)
      expected_src = %q| { "node"     : "links",
                           "name"     : "root",
                           "path"     : "/html/body/a",
                           "children" : [ { "node" : "text",
                                            "name" : "content",
                                            "path" : "/html/body/p"
                                          } ]
                         }|
      expected  = JSON.parse(expected_src)
      expect(actual).to match expected
    end


  end


  it 'has a version number' do
    expect(Yasuri::VERSION).not_to be nil
  end
end
