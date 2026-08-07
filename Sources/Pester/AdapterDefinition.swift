import PesterProtocol
import SwiftUI

struct AdapterDefinition: Equatable {
    let id: AdapterID
    let displayName: String

    static func bundled(_ id: AdapterID) -> AdapterDefinition {
        switch id {
        case .claude:
            AdapterDefinition(id: id, displayName: "Claude Code")
        case .pi:
            AdapterDefinition(id: id, displayName: "Pi")
        }
    }
}

struct AdapterIconView: View {
    let adapter: AdapterDefinition
    let size: CGFloat

    @ViewBuilder
    var body: some View {
        switch adapter.id {
        case .claude:
            ClaudeMascotView(size: size)
        case .pi:
            PiLogoView(size: size)
        }
    }
}
