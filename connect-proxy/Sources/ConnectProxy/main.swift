//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2019 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import NIOPosix
import NIOHTTP1
import Logging
import Dispatch

let logger = Logger(label: "com.nio.main")
let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let bootstrap = ServerBootstrap(group: group)
    .serverChannelOption(ChannelOptions.socket(.init(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .childChannelOption(ChannelOptions.socket(.init(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .childChannelInitializer { channel in
        channel.pipeline.addHandler(ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .forwardBytes)))
            .flatMap { channel.pipeline.addHandler(HTTPResponseEncoder()) }
            .flatMap { channel.pipeline.addHandler(ConnectHandler(logger: Logger(label: "com.nio.ConnectHandler"))) }
    }

let port = 3128
private extension ServerBootstrap {
    func bindTo(socket: SocketAddress) {
        bind(to: socket).whenComplete { result in
            switch result {
            case .success(let channel):
                logger.info("Listening on \(String(describing: channel.localAddress))")
            case .failure(let error):
                logger.error("Failed to bind \(socket.ipAddress ?? ""):\(port), \(error)")
            }
        }
    }
}

if let socket = try? SocketAddress(ipAddress: "0.0.0.0", port: port) {
    bootstrap.bindTo(socket: socket)
}

if let socket = try? SocketAddress(ipAddress: "::1", port: port) {
    bootstrap.bindTo(socket: socket)
}

// Run forever
dispatchMain()
