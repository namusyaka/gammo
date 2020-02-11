require 'gammo/node'
require 'gammo/tags'

module Gammo
  class Parser
    # A set of methods and contants for parsing foreign content.
    # Section 12.2.6.5.
    # @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inforeign
    module Foreign
      # Element names that are broken out on parsing foreign content.
      BREAKOUT = {
        "b" =>           true,
        "big" =>         true,
        "blockquote" =>  true,
        "body" =>        true,
        "br" =>          true,
        "center" =>      true,
        "code" =>        true,
        "dd" =>          true,
        "div" =>         true,
        "dl" =>          true,
        "dt" =>          true,
        "em" =>          true,
        "embed" =>       true,
        "h1" =>          true,
        "h2" =>          true,
        "h3" =>          true,
        "h4" =>          true,
        "h5" =>          true,
        "h6" =>          true,
        "head" =>        true,
        "hr" =>          true,
        "i" =>           true,
        "img" =>         true,
        "li" =>          true,
        "listing" =>     true,
        "menu" =>        true,
        "meta" =>        true,
        "nobr" =>        true,
        "ol" =>          true,
        "p" =>           true,
        "pre" =>         true,
        "ruby" =>        true,
        "s" =>           true,
        "small" =>       true,
        "span" =>        true,
        "strong" =>      true,
        "strike" =>      true,
        "sub" =>         true,
        "sup" =>         true,
        "table" =>       true,
        "tt" =>          true,
        "u" =>           true,
        "ul" =>          true,
        "var" =>         true
      }.freeze

      # If the token's tag name which is parsed as foreign content and has "svg"
      # namespace matches with the key in the hash below, replace the key with
      # corresponding value.
      SVG_TAG_NAME_ADJUSTMENTS = {
        "altglyph" =>             "altGlyph",
        "altglyphdef" =>          "altGlyphDef",
        "altglyphitem" =>         "altGlyphItem",
        "animatecolor" =>         "animateColor",
        "animatemotion" =>        "animateMotion",
        "animatetransform" =>     "animateTransform",
        "clippath" =>             "clipPath",
        "feblend" =>              "feBlend",
        "fecolormatrix" =>        "feColorMatrix",
        "fecomponenttransfer" =>  "feComponentTransfer",
        "fecomposite" =>          "feComposite",
        "feconvolvematrix" =>     "feConvolveMatrix",
        "fediffuselighting" =>    "feDiffuseLighting",
        "fedisplacementmap" =>    "feDisplacementMap",
        "fedistantlight" =>       "feDistantLight",
        "feflood" =>              "feFlood",
        "fefunca" =>              "feFuncA",
        "fefuncb" =>              "feFuncB",
        "fefuncg" =>              "feFuncG",
        "fefuncr" =>              "feFuncR",
        "fegaussianblur" =>       "feGaussianBlur",
        "feimage" =>              "feImage",
        "femerge" =>              "feMerge",
        "femergenode" =>          "feMergeNode",
        "femorphology" =>         "feMorphology",
        "feoffset" =>             "feOffset",
        "fepointlight" =>         "fePointLight",
        "fespecularlighting" =>   "feSpecularLighting",
        "fespotlight" =>          "feSpotLight",
        "fetile" =>               "feTile",
        "feturbulence" =>         "feTurbulence",
        "foreignobject" =>        "foreignObject",
        "glyphref" =>             "glyphRef",
        "lineargradient" =>       "linearGradient",
        "radialgradient" =>       "radialGradient",
        "textpath" =>             "textPath",
      }.freeze

      # If any attribute key of the current token which is parsed as foreign content and has "math"
      # namespace matches with the key in the hash below, replace the key with
      # corresponding value.
      # Section 12.2.6.1.
      # https://html.spec.whatwg.org/multipage/parsing.html#creating-and-inserting-nodes
      MATH_ML_ATTRIBUTE_ADJUSTMENTS = {
        "definitionurl" => "definitionURL",
      }.freeze

      # If any attribute key of the current token which is parsed as foreign content and has "svg"
      # namespace matches with the key in the hash below, replace the key with
      # corresponding value.
      # Section 12.2.6.1.
      # https://html.spec.whatwg.org/multipage/parsing.html#creating-and-inserting-nodes
      SVG_ATTRIBUTE_ADJUSTMENTS = {
        "attributename" =>              "attributeName",
        "attributetype" =>              "attributeType",
        "basefrequency" =>              "baseFrequency",
        "baseprofile" =>                "baseProfile",
        "calcmode" =>                   "calcMode",
        "clippathunits" =>              "clipPathUnits",
        "contentscripttype" =>          "contentScriptType",
        "contentstyletype" =>           "contentStyleType",
        "diffuseconstant" =>            "diffuseConstant",
        "edgemode" =>                   "edgeMode",
        "externalresourcesrequired" =>  "externalResourcesRequired",
        "filterunits" =>                "filterUnits",
        "glyphref" =>                   "glyphRef",
        "gradienttransform" =>          "gradientTransform",
        "gradientunits" =>              "gradientUnits",
        "kernelmatrix" =>               "kernelMatrix",
        "kernelunitlength" =>           "kernelUnitLength",
        "keypoints" =>                  "keyPoints",
        "keysplines" =>                 "keySplines",
        "keytimes" =>                   "keyTimes",
        "lengthadjust" =>               "lengthAdjust",
        "limitingconeangle" =>          "limitingConeAngle",
        "markerheight" =>               "markerHeight",
        "markerunits" =>                "markerUnits",
        "markerwidth" =>                "markerWidth",
        "maskcontentunits" =>           "maskContentUnits",
        "maskunits" =>                  "maskUnits",
        "numoctaves" =>                 "numOctaves",
        "pathlength" =>                 "pathLength",
        "patterncontentunits" =>        "patternContentUnits",
        "patterntransform" =>           "patternTransform",
        "patternunits" =>               "patternUnits",
        "pointsatx" =>                  "pointsAtX",
        "pointsaty" =>                  "pointsAtY",
        "pointsatz" =>                  "pointsAtZ",
        "preservealpha" =>              "preserveAlpha",
        "preserveaspectratio" =>        "preserveAspectRatio",
        "primitiveunits" =>             "primitiveUnits",
        "refx" =>                       "refX",
        "refy" =>                       "refY",
        "repeatcount" =>                "repeatCount",
        "repeatdur" =>                  "repeatDur",
        "requiredextensions" =>         "requiredExtensions",
        "requiredfeatures" =>           "requiredFeatures",
        "specularconstant" =>           "specularConstant",
        "specularexponent" =>           "specularExponent",
        "spreadmethod" =>               "spreadMethod",
        "startoffset" =>                "startOffset",
        "stddeviation" =>               "stdDeviation",
        "stitchtiles" =>                "stitchTiles",
        "surfacescale" =>               "surfaceScale",
        "systemlanguage" =>             "systemLanguage",
        "tablevalues" =>                "tableValues",
        "targetx" =>                    "targetX",
        "targety" =>                    "targetY",
        "textlength" =>                 "textLength",
        "viewbox" =>                    "viewBox",
        "viewtarget" =>                 "viewTarget",
        "xchannelselector" =>           "xChannelSelector",
        "ychannelselector" =>           "yChannelSelector",
        "zoomandpan" =>                 "zoomAndPan",
      }.freeze

      def parse_foreign_content
        case token
        when Tokenizer::TextToken
          self.frameset_ok = token.data.lstrip.sub(/\A\x00*/, '').lstrip.empty? if frameset_ok
          token.data = token.data.gsub(/\x00/, "\ufffd")
          add_text token.data
        when Tokenizer::CommentToken
          add_child Node::Comment.new(data: token.data)
        when Tokenizer::StartTagToken
          unless fragment?
            breakout = BREAKOUT[token.data]
            if token.tag == Tags::Font
              token.attributes.each do |attr|
                case attr.key
                when 'color', 'face', 'size'
                  breakout = true
                  break
                end
              end
            end
            if breakout
              open_elements.reverse_each_with_index do |elm, index|
                if !elm.namespace || html_integration_point?(elm) || math_ml_text_integration_point?(elm)
                  self.open_elements = open_elements.slice(0, index + 1)
                  break
                end
              end
              return false
            end
          end
          current = adjusted_current_node
          case current.namespace
          when 'math'
            adjust_attribute_names(token.attributes, MATH_ML_ATTRIBUTE_ADJUSTMENTS)
          when 'svg'
            x = SVG_TAG_NAME_ADJUSTMENTS[token.data]
            if x
              token.tag = Tags.lookup(x)
              token.data = x
            end
            adjust_attribute_names(token.attributes, SVG_ATTRIBUTE_ADJUSTMENTS)
          else
            raise ParseError, 'bad parser state: unexpected namespace'
          end
          adjust_foreign_attributes(token.attributes)
          namespace = current.namespace
          add_element
          top.namespace = namespace
          tokenizer.next_is_not_raw_text! if namespace
          if has_self_closing_token
            open_elements.pop
            acknowledge_self_closing_tag
          end
        when Tokenizer::EndTagToken
          open_elements.reverse_each_with_index do |elm, index|
            return insertion_mode.new(self).process unless elm.namespace
            if elm.data.downcase == token.data.downcase
              self.open_elements = open_elements.slice(0, index)
              break
            end
          end
          return true
        end
        # ignore the token
        true
      end

      def in_foreign_content?
        return false if open_elements.length.zero?
        node = adjusted_current_node
        return false unless node.namespace
        if math_ml_text_integration_point?(node)
          return false if token.instance_of?(Tokenizer::StartTagToken) && token.tag != Tags::Mglyph &&
            token.tag != Tags::Malignmark
          return false if token.instance_of?(Tokenizer::TextToken)
        end
        return false if node.namespace == 'math' && node.tag == Tags::AnnotationXml && \
          token.instance_of?(Tokenizer::StartTagToken) && token.tag == Tags::Svg
        return false if html_integration_point?(node) && (token.instance_of?(Tokenizer::StartTagToken) || token.instance_of?(Tokenizer::TextToken))
        return false if token.instance_of? Tokenizer::ErrorToken
        true
      end

      def math_ml_text_integration_point?(node)
        return false unless node.namespace == 'math'
        case node.data
        when 'mi', 'mo', 'mn', 'ms', 'mtext' then return true
        else return false
        end
      end

      def html_integration_point?(node)
        return false unless node.instance_of? Node::Element
        case node.namespace
        when 'math'
          node.attributes.each do |attr|
            next unless attr.key == 'encoding'
            val = attr.value.downcase
            return true if val == 'text/html' || val == 'application/xhtml+xml'
          end if node.data == 'annotation-xml'
        when 'svg'
          case node.data
          when 'desc', 'foreignObject', 'title'
            return true
          end
        else return false
        end
        false
      end

      def adjust_attribute_names(attrs, map)
        attrs.each { |attr| attr.key = map[attr.key] if map.key?(attr.key) }
      end

      def adjust_foreign_attributes(attrs)
        attrs.each_with_index do |attr, index|
          next if attr.key == "" || !attr.key.start_with?(?x)
          case attr.key
          when "xlink:actuate", "xlink:arcrole", "xlink:href", "xlink:role",
            "xlink:show", "xlink:title", "xlink:type", "xml:base", "xml:lang",
            "xml:space", "xmlns:xlink"
            j = attr.key.index(?:)
            attrs[index].namespace = attr.key.slice(0, j)
            attrs[index].key = attr.key.slice(j + 1 .. -1)
          end
        end
      end
    end
  end
end
