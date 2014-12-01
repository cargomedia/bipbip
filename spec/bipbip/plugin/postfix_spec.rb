require 'bipbip'
require 'bipbip/plugin/postfix'

describe Bipbip::Plugin::Postfix do
  let(:plugin) { Bipbip::Plugin::Postfix.new('postfix', {}, 10) }

  it 'should collect queue size' do

    postqueue = <<EOS
-Queue ID- --Size-- ----Arrival Time---- -Sender/Recipient-------
6E49C3823C9*    7577 Mon Dec  1 10:05:14  noreply@fuckbook.com
                                         aromj.lanz@hispeed.ch

9B29D383452*    7660 Mon Dec  1 10:05:14  noreply@fuckbook.com
                                         arthur_note_92@hotmail.com

E0233383459*    8404 Mon Dec  1 10:05:14  noreply@fuckbook.com
                                         564610248@qq.com

07B703833CF*    7520 Mon Dec  1 10:05:14  noreply@fuckbook.com
                                         premlals@yahoo.com

E54C738334B*    7504 Mon Dec  1 10:05:13  noreply@fuckbook.com
                                         martinkrcmar82@seznam.cz

4E0E8383430*    7480 Mon Dec  1 10:05:14  noreply@fuckbook.com
                                         rikkku@op.pl

728D7383449*    7557 Mon Dec  1 10:05:14  noreply@fuckbook.com
                                         mmitrovic1@hotmail.com

-- 54 Kbytes in 7 Requests.
EOS

    plugin.stub(:postqueue).and_return(postqueue)

    data = plugin.monitor
    data['mails_queued_total'].should eq(7)
  end

end
