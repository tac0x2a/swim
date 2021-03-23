# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require_relative 'spec_helper'

describe 'Yasuri' do
  include_context 'httpserver'

  before do
    @agent = Mechanize.new
    @uri = uri
    @index_page = @agent.get(@uri)
  end

  ############
  # yam2tree #
  ############
  describe '.yaml2tree' do
    it "fail if empty yaml" do
      expect { Yasuri.yaml2tree(nil) }.to raise_error(RuntimeError)
    end

    it "return text node" do
      src = <<-EOB
content:
  node: text
  path: "/html/body/p[1]"
EOB
      generated = Yasuri.yaml2tree(src)
      original  = Yasuri::TextNode.new('/html/body/p[1]', "content")

      compare_generated_vs_original(generated, original, @index_page)
    end

    it "return text node as symbol" do
      src = <<-EOB
:content:
  :node: text
  :path: "/html/body/p[1]"
EOB
      generated = Yasuri.yaml2tree(src)
      original  = Yasuri::TextNode.new('/html/body/p[1]', "content")

      compare_generated_vs_original(generated, original, @index_page)
    end

    it "return LinksNode/TextNode" do

      src = <<-EOB
root:
  node: links
  path: "/html/body/a"
  children:
    - content:
        node: text
        path: "/html/body/p"
EOB
      generated = Yasuri.yaml2tree(src)
      original  = Yasuri::LinksNode.new('/html/body/a', "root", [
                    Yasuri::TextNode.new('/html/body/p', "content"),
                  ])

      compare_generated_vs_original(generated, original, @index_page)
    end

    it "return StructNode/StructNode/[TextNode,TextNode]" do
      src = <<-EOB
tables:
  node: struct
  path: "/html/body/table"
  children:
    - table:
        node: struct
        path: "./tr"
        children:
          - title:
              node: text
              path: "./td[1]"
          - pub_date:
              node: text
              path: "./td[2]"
EOB

      generated = Yasuri.yaml2tree(src)
      original  = Yasuri::StructNode.new('/html/body/table', "tables", [
        Yasuri::StructNode.new('./tr', "table", [
          Yasuri::TextNode.new('./td[1]', "title"),
          Yasuri::TextNode.new('./td[2]', "pub_date"),
        ])
      ])
      page = @agent.get(@uri + "/struct/structual_text.html")
      compare_generated_vs_original(generated, original, page)
    end

  end # end of describe '.yaml2tree'


  #############
  # json2tree #
  #############
  describe '.json2tree' do
    it "fail if empty json" do
      expect { Yasuri.json2tree("{}") }.to raise_error(RuntimeError)
    end

    it "return TextNode" do
      src = %q|
      {
        "text_content": "/html/body/p[1]"
      }|
      generated = Yasuri.json2tree(src)
      original  = Yasuri::TextNode.new('/html/body/p[1]', "content")

      compare_generated_vs_original(generated, original, @index_page)
    end

    it "return TextNode with truncate_regexp" do
      src = %q|
      { "text_content": {
          "path": "/html/body/p[1]",
          "truncate"  : "^[^,]+"
        }
      }|
      generated = Yasuri.json2tree(src)
      original  = Yasuri::TextNode.new('/html/body/p[1]', "content", truncate:/^[^,]+/)
      compare_generated_vs_original(generated, original, @index_page)
    end

    it "return MapNode with TextNodes" do
      src = %q| {
        "text_content01": "/html/body/p[1]",
        "text_content02": "/html/body/p[2]"
      }|
      generated = Yasuri.json2tree(src)
      original  = Yasuri::MapNode.new('parent', [
        Yasuri::TextNode.new('/html/body/p[1]', "content01"),
        Yasuri::TextNode.new('/html/body/p[2]', "content02"),
      ])
      compare_generated_vs_original(generated, original, @index_page)
    end

    it "return LinksNode/TextNode" do
      src = %q| {
        "links_root": {
          "path": "/html/body/a",
          "text_content": "/html/body/p"
        }
      }|

      generated = Yasuri.json2tree(src)
      original  = Yasuri::LinksNode.new('/html/body/a', "root", [
                    Yasuri::TextNode.new('/html/body/p', "content"),
                  ])

      compare_generated_vs_original(generated, original, @index_page)
    end

    it "return PaginateNode/TextNode" do
      src = %q|
      {
        "pages_root": {
          "path": "/html/body/nav/span/a[@class=\'next\']",
          "text_content": "/html/body/p"
        }
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
      src = %q|
      {
        "pages_root": {
          "path": "/html/body/nav/span/a[@class=\'next\']",
          "limit": 2,
          "text_content": "/html/body/p"
        }
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
      src = %q|
      {
        "struct_tables": {
          "path": "/html/body/table",
          "struct_table": {
            "path": "./tr",
            "text_title": "./td[1]",
            "text_pub_date": "./td[2]"
          }
        }
      }|
      generated = Yasuri.json2tree(src)
      original  = Yasuri::StructNode.new('/html/body/table', "tables", [
        Yasuri::StructNode.new('./tr', "table", [
          Yasuri::TextNode.new('./td[1]', "title"),
          Yasuri::TextNode.new('./td[2]', "pub_date"),
        ])
      ])
      page = @agent.get(@uri + "/struct/structual_text.html")
      compare_generated_vs_original(generated, original, page)
    end
  end

  #############
  # tree2json #
  #############
  describe '.tree2json' do
    it "return empty json" do
      json = Yasuri.tree2json(nil)
      expect(json).to match "{}"
    end

    it "return text node" do
      node = Yasuri::TextNode.new("/html/head/title", "title")
      json = Yasuri.tree2json(node)
      expected_str = %q| { "node": "text",
                           "name": "title",
                           "path": "/html/head/title"
                         } |
      expected = JSON.parse(expected_str)
      actual   = JSON.parse(json)
      expect(actual).to match expected
    end

    it "return text node with truncate_regexp" do
      node = Yasuri::TextNode.new("/html/head/title", "title", truncate:/^[^,]+/)
      json = Yasuri.tree2json(node)
      expected_str = %q| { "node": "text",
                           "name": "title",
                           "path": "/html/head/title",
                           "truncate": "^[^,]+"
                         } |
      expected = Yasuri.tree2json(Yasuri.json2tree(expected_str))
      actual   = Yasuri.tree2json(Yasuri.json2tree(json))
      expect(actual).to match expected
    end

    it "return map node with text nodes" do
      tree = Yasuri::MapNode.new('parent', [
        Yasuri::TextNode.new('/html/body/p[1]', "content01"),
        Yasuri::TextNode.new('/html/body/p[2]', "content02"),
      ])
      actual_json = Yasuri.tree2json(tree)

      expected_json = %q| { "node" : "map",
        "name"  : "parent",
        "children" : [
          { "node"  : "text",
            "name"  : "content01",
            "path"  : "/html/body/p[1]"
          },
          { "node"  : "text",
            "name"  : "content02",
            "path"  : "/html/body/p[2]"
          }
        ]
      }|
      expected = Yasuri.tree2json(Yasuri.json2tree(expected_json))
      actual   = Yasuri.tree2json(Yasuri.json2tree(actual_json))
      expect(actual).to match expected
    end

    it "return LinksNode/TextNode" do
      tree  = Yasuri::LinksNode.new('/html/body/a', "root", [
                Yasuri::TextNode.new('/html/body/p', "content"),
              ])
      json   = Yasuri.tree2json(tree)
      expected_src = %q| { "node"     : "links",
                           "name"     : "root",
                           "path"     : "/html/body/a",
                           "children" : [ { "node" : "text",
                                            "name" : "content",
                                            "path" : "/html/body/p"
                                          } ]
                         }|
      expected  = JSON.parse(expected_src)
      actual    = JSON.parse(json)
      expect(actual).to match expected
    end

    it "return PaginateNode/TextNode with limit" do
      tree = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
                Yasuri::TextNode.new('/html/body/p', "content"),
             ], limit:10)

      json   = Yasuri.tree2json(tree)
      expected_src = %q|
      {
        "pages_root": {
          "path": "/html/body/nav/span/a[@class='next']",
          "limit": 10,
          "flatten": false,
          "text_content": "/html/body/p"
        }
      }|
      expected  = JSON.parse(expected_src)
      actual    = JSON.parse(json)
      expect(actual).to match expected
    end
  end


  it 'has a version number' do
    expect(Yasuri::VERSION).not_to be nil
  end
end
