import SwiftUI

struct LiquidGlassBackground: View {
    let depth: GlassDepth
    @Environment(\.colorScheme) var colorScheme
    
    enum GlassDepth {
        case shallow
        case medium
        case deep
        
        var opacity: Double {
            switch self {
            case .shallow: return 0.15
            case .medium: return 0.25
            case .deep: return 0.35
            }
        }
        
        var blur: CGFloat {
            switch self {
            case .shallow: return 10
            case .medium: return 20
            case .deep: return 30
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Base gradient layer
            LinearGradient(
                colors: glassColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Translucent overlay with blur
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(depth.opacity)
            
            // Specular highlight layer
            GeometryReader { geometry in
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.clear,
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: UnitPoint(x: 0.8, y: 0.8)
                )
                .blendMode(.overlay)
                
                // Secondary highlight for depth
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.2, y: 0.2),
                    startRadius: 5,
                    endRadius: geometry.size.width * 0.5
                )
                .blendMode(.screen)
            }
            
            // Subtle noise texture for realism
            Rectangle()
                .fill(.white.opacity(0.02))
                .blendMode(.overlay)
        }
        .background(.black.opacity(0.4))
    }
    
    private var glassColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.05, green: 0.1, blue: 0.2, opacity: 0.7),
                Color(red: 0.08, green: 0.12, blue: 0.25, opacity: 0.8),
                Color(red: 0.03, green: 0.08, blue: 0.18, opacity: 0.75)
            ]
        } else {
            return [
                Color(red: 0.95, green: 0.97, blue: 1.0, opacity: 0.6),
                Color(red: 0.92, green: 0.95, blue: 0.98, opacity: 0.7),
                Color(red: 0.96, green: 0.98, blue: 1.0, opacity: 0.65)
            ]
        }
    }
}

// Card component with Liquid Glass styling
struct LiquidGlassCard<Content: View>: View {
    let content: Content
    let depth: LiquidGlassBackground.GlassDepth
    
    init(depth: LiquidGlassBackground.GlassDepth = .medium, @ViewBuilder content: () -> Content) {
        self.depth = depth
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

// Refined text styles for Liquid Glass
extension View {
    func glassTitle() -> some View {
        self
            .fontWeight(.semibold)
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, .white.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
    
    func glassCaption() -> some View {
        self
            .foregroundColor(.white.opacity(0.7))
            .fontWeight(.medium)
    }
    
    func glassBody() -> some View {
        self
            .foregroundColor(.white.opacity(0.85))
    }
}