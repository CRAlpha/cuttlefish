# Filter mail content by splitting out html and text parts
# and handling them separately
class Filters::Mail < Filters::Base

  def filter_mail(mail)
    if mail.multipart?
      if mail.html_part
        encoding = mail.html_part.body.encoding
        enc = Mail::Encodings::get_encoding(encoding)
        body = enc.present? ? enc.encode(filter_html(mail.html_part.decoded)) : filter_html(mail.html_part.decoded)
        mail.html_part.body = body
      end

      if mail.text_part
        encoding = mail.text_part.body.encoding
        enc = Mail::Encodings::get_encoding(encoding)
        body = enc.present? ? enc.encode(filter_text(mail.text_part.decoded)) : filter_html(mail.text_part.decoded)
        mail.text_part.body = body
      end
    else
      if mail.mime_type == "text/html"
        body = filter_html(mail.body.decoded)
      else
        body = filter_text(mail.body.decoded)
      end
      encoding = mail.body.encoding
      enc = Mail::Encodings::get_encoding(encoding)
      if enc.present?
        body = enc.encode(body)
      end
      mail.body = body
    end
    mail
  end

  # Override the following two methods in inherited class
  # Whatever you do don't change the encoding of the string because it will break things
  def filter_text(input)
    input
  end

  def filter_html(input)
    input
  end
end
