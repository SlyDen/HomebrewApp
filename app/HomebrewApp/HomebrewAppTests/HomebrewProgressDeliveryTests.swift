import Foundation
import Testing
@testable import HomebrewApp

@MainActor
struct HomebrewProgressDeliveryTests {
    @Test func finishWaitsForOrderedMainActorDeliveryAcrossObservers() async {
        var receivedMessages: [String] = []
        let delivery = HomebrewProgressDelivery { message in
            receivedMessages.append(message)
        }
        let outputObserver = HomebrewProcessOutputObserver(delivery: delivery)
        let errorObserver = HomebrewProcessOutputObserver(delivery: delivery)

        outputObserver.consume(Data("==> Upgrading alpha\n".utf8))
        errorObserver.consume(Data("Error: alpha: upgrade failed\n".utf8))
        outputObserver.consume(Data("==> Upgrading beta".utf8))
        outputObserver.finish()
        errorObserver.finish()

        await delivery.finish()

        #expect(
            receivedMessages == [
                "Upgrading alpha",
                "Error: alpha: upgrade failed",
                "Upgrading beta"
            ]
        )
    }
}
