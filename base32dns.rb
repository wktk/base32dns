require 'async/dns'
require 'base32'

class TestServer < Async::DNS::Server
  IN = Resolv::DNS::Resource::IN

  attr_accessor :ip

  def ns=(name)
    @ns = Resolv::DNS::Name.create(name)
    @soa = [ns, Time.now.to_i, 10000, 24000, 10800, 60]
  end
  attr_reader :ns, :soa

  def process(name, resource_class, transaction)
    logger.info('remote_address', transaction.options[:remote_address].inspect)
    transaction.respond!(ns, resource_class: IN::NS)
    transaction.respond!(ip, resource_class: IN::A)
    dns_name = Resolv::DNS::Name.create(name)
    transaction.respond!(dns_name, *soa, resource_class: IN::SOA)
    logger.info('request', name)
    logger.info('decoded', Base32.decode(name.split('.')[0].upcase)) rescue nil
  end
end

server = TestServer.new(%i(udp tcp).map { |p| [p, '0.0.0.0', 53] })
server.ip = ENV['IP']
server.ns = ENV['NS']
server.run
