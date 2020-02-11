module Support
  module Dump
    def dump_indent(level)
      "| #{' ' * 2 * level}"
    end

    def dump_level(buf, node, level)
      buf << dump_indent(level)
      level += 1
      case node
      when Gammo::Node::Error
        raise 'unexpected error node'
      when Gammo::Node::Text
        buf << ('"%s"' % node.data)
      when Gammo::Node::Document
        raise 'unexpected document node'
      when Gammo::Node::Element
        if node.namespace
          buf << ('<%s %s>' % [node.namespace, node.data])
        else
          buf << ('<%s>' % node.data)
        end
        sorted_attrs = node.attributes.sort_by(&:key)
        sorted_attrs.each do |attr|
          buf << ?\n
          buf << dump_indent(level)
          if attr.namespace
            buf << ('%s %s="%s"' % [attr.namespace, attr.key, attr.value])
          else
            buf << ('%s="%s"' % [attr.key, attr.value])
          end
        end
        if !node.namespace && node.tag == Gammo::Tags::Template
          buf << ?\n
          buf << dump_indent(level)
          level += 1
          buf << 'content'
        end
      when Gammo::Node::Comment
        buf << ('<!-- %s -->' % node.data)
      when Gammo::Node::Doctype
        buf << ('<!DOCTYPE %s' % node.data)
        unless node.attributes.empty?
          p = s = ''
          node.attributes.each do |attr|
            case attr.key
            when 'public'
              p = attr.value
            when 'system'
              s = attr.value
            end
          end
          if !(p.empty? && s.empty?)
            buf << (' "%s"' % p)
            buf << (' "%s"' % s)
          end
        end
        buf << '>'
      when Gammo::Node::ScopeMarker
        raise 'unexpected scope marker node'
      else
        raise 'unknown node type'
      end
      buf << ?\n
      child = node.first_child
      while child
        dump_level(buf, child, level)
        child = child.next_sibling
      end
    end

    def dump_for(node)
      return '' if node.nil? || node.first_child.nil?
      child = node.first_child
      buf = ''
      while child
        dump_level(buf, child, 0)
        child = child.next_sibling
      end
      buf.force_encoding(Encoding::UTF_8)
    end

  end
end
