# encoding: ascii-8bit
class ImageSpec
  module Parser
    class JPEG

      CONTENT_TYPE = 'image/jpeg'

      def self.attributes(stream)
        width, height = dimensions(stream)
        {:width => width, :height => height, :content_type => CONTENT_TYPE, :dimensions => [width, height], :file_size => size(stream)}
      end

      def self.detected?(stream)
        stream.rewind
        stream.read(2) == "\xff\xd8"
      end

      def self.dimensions(stream)
        stream.rewind
        raise ImageSpec::Error, 'malformed JPEG' unless stream.readbyte.chr == "\xFF" && stream.readbyte.chr == "\xD8" # SOI

        class << stream
          def readint
            (readbyte.ord << 8) + readbyte.ord
          end

          def readframe
            read(readint - 2)
          end

          def readsof
            [readint, readbyte.chr, readint, readint, readbyte.chr]
          end

          def next
            c = readbyte.chr while c != "\xFF"
            c = readbyte.chr while c == "\xFF"
            c
          end
        end

        while marker = stream.next
          case marker
          when "\xC0".."\xC3", "\xC5".."\xC7", "\xC9".."\xCB", "\xCD".."\xCF"
            length, bits, height, width, components = stream.readsof
            raise ImageSpec::Error, 'malformed JPEG' unless length == 8 + components[0].ord * 3
            return [width, height]
          when "\xD9", "\xDA"
            break
          when "\xFE"
            @comment = stream.readframe
          else
            stream.readframe
          end
        end
      end

      def self.size(stream)
        stream.size
      end

    end
  end
end
