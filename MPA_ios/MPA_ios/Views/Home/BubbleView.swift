//
//  BubbleView.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/4/25.
//

import SwiftUI
import UIKit

// MARK: - SwiftUI View
struct BubbleView: View {
    
    let bubbles: [BubbleData] = [
        BubbleData(text: "One", color: .systemRed, size: 80),
        BubbleData(text: "Two", color: .systemBlue, size: 60),
        BubbleData(text: "Three", color: .systemGreen, size: 100),
        BubbleData(text: "Four", color: .systemOrange, size: 70),
        BubbleData(text: "Five", color: .systemPurple, size: 90)
    ]
    let height: CGFloat
    
    var body: some View {
        BubbleContainerViewRepresentable(
            bubbles: bubbles,
            frame: .zero
        )
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }
}

// MARK: - Bubble Data Model
struct BubbleData: Identifiable {
    let id = UUID()
    let text: String
    let color: UIColor
    let size: CGFloat
}

// MARK: - UIViewRepresentable
struct BubbleContainerViewRepresentable: UIViewRepresentable {
    let bubbles: [BubbleData]
    let frame: CGRect

    func makeUIView(context: Context) -> BubbleContainerView {
        let view = BubbleContainerView(frame: frame, bubbles: bubbles)
        return view
    }

    func updateUIView(_ uiView: BubbleContainerView, context: Context) {
        // 필요 시 업데이트
    }
}

// MARK: - UIKit Bubble Container
class BubbleContainerView: UIView {
    private var animator: UIDynamicAnimator!
    private var bubbleViews: [BubbleUIView] = []
    private let bubbles: [BubbleData]

    init(frame: CGRect, bubbles: [BubbleData]) {
        self.bubbles = bubbles
        super.init(frame: frame)
        let effect = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        effect.translatesAutoresizingMaskIntoConstraints = false
        effect.layer.cornerRadius = 24
        
        self.addSubview(effect)
        effect.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        effect.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        effect.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        effect.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        setupBubbles()
        setupPhysics()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupBubbles() {
        for bubble in bubbles {
            let bubbleView = BubbleUIView(bubble: bubble)
            // 랜덤 위치 배치(충돌 방지용)
            let enableWidth = (bounds.width - bubble.size) >= bubble.size
            let enableHeight = (bounds.height - bubble.size) >= bubble.size
            let x = CGFloat.random(in: enableWidth ? bubble.size...(bounds.width - bubble.size) : bubble.size...bubble.size)
            let y = CGFloat.random(in: enableHeight ? bubble.size...(bounds.height - bubble.size) : bubble.size...bubble.size)
            bubbleView.frame = CGRect(x: x, y: y, width: bubble.size, height: bubble.size)
            addSubview(bubbleView)
            bubbleViews.append(bubbleView)
        }
    }

    private func setupPhysics() {
        animator = UIDynamicAnimator(referenceView: self)
        let collision = UICollisionBehavior(items: bubbleViews)
        collision.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(collision)

        let dynamic = UIDynamicItemBehavior(items: bubbleViews)
        dynamic.elasticity = 0.8
        dynamic.friction = 0.1
        dynamic.resistance = 0.1
        animator.addBehavior(dynamic)

        // 각 방울에 터치 제스처 추가
        for bubbleView in bubbleViews {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            bubbleView.addGestureRecognizer(pan)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view as? BubbleUIView else { return }
        switch gesture.state {
        case .began:
            animator.removeAllBehaviors()
        case .changed:
            let translation = gesture.translation(in: self)
            view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
            
            if view.center.x > bounds.width {
                view.center.x = bounds.width - view.bounds.width
            } else if view.center.x < 0 {
                view.center.x = 0
            }
            if view.center.y > bounds.height {
                view.center.y = bounds.height - view.bounds.height
            } else if view.center.y < 0 {
                view.center.y = 0
            }
            
            gesture.setTranslation(.zero, in: self)
        case .ended, .cancelled:
            setupPhysics()
        default:
            break
        }
    }
}

// MARK: - Bubble UIView
class BubbleUIView: UIView {
    private let label = UILabel()
    private let bubble: BubbleData

    init(bubble: BubbleData) {
        self.bubble = bubble
        super.init(frame: .zero)
        backgroundColor = bubble.color
        layer.cornerRadius = bubble.size / 2
        layer.masksToBounds = true

        label.text = bubble.text
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.frame = bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(label)
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

#Preview {
    MainView()
        .padding()
}
