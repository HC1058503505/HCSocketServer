//
//  HCSocketServer.swift
//  HCSocketProtocolBuf
//
//  Created by UltraPower on 2017/7/3.
//  Copyright © 2017年 UltraPower. All rights reserved.
//

import Foundation


// 状态
enum HCSocketServerStatus {
    case listen(Bool,String)
    case connect(Bool,String)
    case read(Bool,String)
    case send(Bool,String)
    case other(Bool,String)
}

typealias Result = (_ tcpClient:TCPClient? ,_ success:HCSocketServerStatus) -> Void

class HCSocketServer {
    var address: String = ""
    var port: Int = 0
    
    var isForever:Bool = true
    
    var tcpClients:[TCPClient] = [TCPClient]()
    var currentTcpClient:TCPClient?
    
    fileprivate lazy var tcpServer: TCPServer = {
        return TCPServer()
    }()
    
    
    // 单例
    static let socketServerManager:HCSocketServer = HCSocketServer()
    // 私有化构造方法
    fileprivate init() {
        
    }
    
    static func socketServer(address: String, port: Int) -> HCSocketServer {
        socketServerManager.address = address
        socketServerManager.port = port
        return socketServerManager
    }
    
    // 开始监听
    func start(result: @escaping Result) -> HCSocketServer{
        
        self.tcpServer.addr = self.address
        self.tcpServer.port = self.port
        let listentResult = self.tcpServer.listen()
        result(nil, HCSocketServerStatus.listen(listentResult.0, listentResult.1))
        return self
    }
    
    // 接受客户端
    func accept(result:@escaping Result){
        
        // 读取客户端发送的消息
        // 这里需要循环读取
        DispatchQueue.global().async {
            
            while self.isForever {
                print(#function,#line)
                // 未连接到客户端
                guard let tcpClient = self.tcpServer.accept() else {
                    result(nil, HCSocketServerStatus.connect(false, "连接失败"))
                    continue
                }
                // 连接到客户端同时进行保存
                self.tcpClients.append(tcpClient)
                self.currentTcpClient = tcpClient
                result(tcpClient, HCSocketServerStatus.connect(true, "连接成功"))
                self.readMessage(result: result)
            }
        }
    }
    
    // 读取信息
    func readMessage(result:Result) {
        var contentLength = 0
        let sizeofInt = MemoryLayout.size(ofValue: contentLength)
        
        while true {
            guard let currentClient = currentTcpClient else {
                return
            }
            
            guard let contentSize = currentClient.read(sizeofInt) else {
                result(currentTcpClient, HCSocketServerStatus.read(false, "读取内容长度失败"))
                continue
            }
            
            let data = NSData(bytes: contentSize, length: sizeofInt)
            data.getBytes(&contentLength, length:sizeofInt)
            
            guard let content = currentClient.read(contentLength) else {
                result(currentTcpClient, HCSocketServerStatus.read(false, "读取失败"))
                // 继续读取消息
                continue
            }
            
            let contentData = Data(bytes: content)
            
            do {
                let person = try Person.parseFrom(data: contentData)
                result(currentClient, HCSocketServerStatus.read(true, person.info))
            } catch {
                result(currentClient, HCSocketServerStatus.read(false, "ProtocolBuf解析失败"))
            }
            
        }

    }
    
    // 回复消息
    func reply(message: String,result: Result) {
        let personBuilder = Person.Builder()
        personBuilder.id = 123
        personBuilder.name = "server"
        personBuilder.email = "1058503505@qq.com"
        personBuilder.info = message
        
        let person = try! personBuilder.build()
        
        var sizeOfPerson = person.data().count
        
        let sizeData = Data(bytes: &sizeOfPerson, count: MemoryLayout.size(ofValue: sizeOfPerson))
        
        print(sizeOfPerson)
        guard let sendResult = self.currentTcpClient?.send(data:sizeData + person.data()) else {
            return
        }
        result(self.currentTcpClient!, HCSocketServerStatus.send(sendResult.0, sendResult.1))
    }
}
