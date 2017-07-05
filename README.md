# HCSocketServer
HCSocketServer ProtocolBuffer

> 该Demo是基于Swift 3.1来实现的，使用了开源的`ysocket`以及`ProtocolBuffers-Swift`,客户端请穿越到[HCSocketClient](https://github.com/HC1058503505/HCSocketClient)

# HCSocketServer的使用
```swift
// 链式编程
// socket的连接与接入
HCSocketServer.socketServer(address: "172.16.40.33", port: 8888)
            .start { (_, status) in
                switch status {
                case let .listen(_, info):
                    self.connectStatus.stringValue = info
                default:
                    break
                }
            }
            .accept { (client, status) in
                DispatchQueue.main.async {
                    switch status {
                    case let .connect(_, info),let .other(false, info),let .read(false, info):
                        self.connectStatus.stringValue = info
                    case let .read(true, info):
                        self.clientText.string =  (self.clientText.string ?? "") + "\nFriend:" + info
                    default:
                        break
                    }
                }
          }

// socket 服务端消息回复
 @IBAction func replyAction(_ sender: NSButton) {
        if message.stringValue.characters.count == 0 {
            return
        }
        HCSocketServer.socketServerManager.reply(message: message.stringValue) { (client, status) in
            switch status {
            case let .send(false, info):
                self.connectStatus.stringValue = info
            case .send(true, _):
                self.clientText.string = (self.clientText.string ?? "") + "\nME:" + self.message.stringValue
                self.message.stringValue = ""
            default:
                break
            }
        }
 }
```
