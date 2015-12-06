require 'bipbip'
require 'bipbip/plugin/postfix'

describe Bipbip::Plugin::Postfix do
  let(:plugin) { Bipbip::Plugin::Postfix.new('postfix', {}, 10) }

  it 'should collect more than one mail in queue' do
    postqueue = <<EOS
-Queue ID- --Size-- ----Arrival Time---- -Sender/Recipient-------
6E49C3823C9*    7577 Mon Dec  1 10:05:14  noreply@example.com
                                         aromj.12@hispeed.ch

9B29D383452*    7660 Mon Dec  1 10:05:14  noreply@example.com
                                         arth12_note_92@hotmail.com

E0233383459*    8404 Mon Dec  1 10:05:14  noreply@example.com
                                         234324234234@qq.com

07B703833CF*    7520 Mon Dec  1 10:05:14  noreply@example.com
                                         prem23lals@yahoo.com

E54C738334B*    7504 Mon Dec  1 10:05:13  noreply@example.com
                                         mtinkrcmar82@seznam.cz

4E0E8383430*    7480 Mon Dec  1 10:05:14  noreply@example.com
                                         riu@op.pl

728D7383449*    7557 Mon Dec  1 10:05:14  noreply@example.com
                                         mmvic1@hotmail.com

-- 54 Kbytes in 7 Requests.
EOS

    plugin.stub(:postqueue).and_return(postqueue)

    data = plugin.monitor
    data['mails_queued_total'].should eq(7)
  end

  it 'should collect exact one mail in queue' do
    postqueue = <<EOS
-Queue ID- --Size-- ----Arrival Time---- -Sender/Recipient-------
6E49C3823C9*    7577 Mon Dec  1 10:05:14  noreply@example.com
                                         aromj.12@hispeed.ch

-- 14 Kbytes in 1 Request.
EOS

    plugin.stub(:postqueue).and_return(postqueue)

    data = plugin.monitor
    data['mails_queued_total'].should eq(1)
  end

  it 'should return zero' do
    plugin.stub(:postqueue).and_return('Mail queue is empty')

    data = plugin.monitor
    data['mails_queued_total'].should eq(0)
  end
end
