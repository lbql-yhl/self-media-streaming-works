//
//  VelonAmbientCanvas.swift
//  velon
//

import UIKit

/// Food-planner atmosphere: warm gradients, floating plate orbs, steam ribbons.
final class VelonAmbientCanvas: UIView {
    private let gradient = CAGradientLayer()
    private let orbA = UIView()
    private let orbB = UIView()
    private let orbC = UIView()
    private let plateRing = UIView()
    private let steamLayer = CAShapeLayer()
    private var didStartMotion = false

    enum Mood {
        case discover
        case routes
        case digest
        case profile
        case detail
    }

    var mood: Mood = .discover {
        didSet { applyMood() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.addSublayer(gradient)
        [orbA, orbB, orbC, plateRing].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        orbA.layer.cornerRadius = 90
        orbB.layer.cornerRadius = 70
        orbC.layer.cornerRadius = 50
        plateRing.layer.borderWidth = 18
        plateRing.layer.cornerRadius = 110
        plateRing.backgroundColor = .clear
        layer.addSublayer(steamLayer)
        steamLayer.fillColor = UIColor.clear.cgColor
        steamLayer.lineWidth = 2.5
        steamLayer.lineCap = .round
        applyMood()
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        orbA.frame = CGRect(x: bounds.width * 0.55, y: -40, width: 180, height: 180)
        orbB.frame = CGRect(x: -50, y: bounds.height * 0.28, width: 140, height: 140)
        orbC.frame = CGRect(x: bounds.width * 0.72, y: bounds.height * 0.62, width: 100, height: 100)
        plateRing.frame = CGRect(x: bounds.width * 0.18, y: bounds.height * 0.55, width: 220, height: 220)
        rebuildSteam()
        if !didStartMotion {
            didStartMotion = true
            startMotion()
        }
    }

    private func applyMood() {
        switch mood {
        case .discover:
            gradient.colors = [
                VelonTheme.creamSurface.cgColor,
                VelonTheme.mist.cgColor,
                UIColor(red: 1, green: 0.82, blue: 0.78, alpha: 1).cgColor
            ]
            orbA.backgroundColor = VelonTheme.primary.withAlphaComponent(0.35)
            orbB.backgroundColor = VelonTheme.saffron.withAlphaComponent(0.28)
            orbC.backgroundColor = VelonTheme.plum.withAlphaComponent(0.22)
            plateRing.layer.borderColor = VelonTheme.primary.withAlphaComponent(0.18).cgColor
            steamLayer.strokeColor = VelonTheme.coralGlow.withAlphaComponent(0.45).cgColor
        case .routes:
            gradient.colors = [
                UIColor(red: 1, green: 0.93, blue: 0.88, alpha: 1).cgColor,
                VelonTheme.mist.cgColor,
                UIColor(red: 0.98, green: 0.86, blue: 0.74, alpha: 1).cgColor
            ]
            orbA.backgroundColor = VelonTheme.saffron.withAlphaComponent(0.32)
            orbB.backgroundColor = VelonTheme.primary.withAlphaComponent(0.24)
            orbC.backgroundColor = VelonTheme.basil.withAlphaComponent(0.2)
            plateRing.layer.borderColor = VelonTheme.saffron.withAlphaComponent(0.2).cgColor
            steamLayer.strokeColor = VelonTheme.saffron.withAlphaComponent(0.4).cgColor
        case .digest:
            gradient.colors = [
                UIColor(red: 1, green: 0.94, blue: 0.95, alpha: 1).cgColor,
                VelonTheme.creamSurface.cgColor,
                UIColor(red: 0.95, green: 0.84, blue: 0.9, alpha: 1).cgColor
            ]
            orbA.backgroundColor = VelonTheme.plum.withAlphaComponent(0.28)
            orbB.backgroundColor = VelonTheme.primary.withAlphaComponent(0.3)
            orbC.backgroundColor = VelonTheme.coralGlow.withAlphaComponent(0.25)
            plateRing.layer.borderColor = VelonTheme.plum.withAlphaComponent(0.18).cgColor
            steamLayer.strokeColor = VelonTheme.plum.withAlphaComponent(0.35).cgColor
        case .profile:
            gradient.colors = [
                VelonTheme.creamSurface.cgColor,
                UIColor(red: 0.98, green: 0.91, blue: 0.86, alpha: 1).cgColor,
                UIColor(red: 0.93, green: 0.84, blue: 0.78, alpha: 1).cgColor
            ]
            orbA.backgroundColor = VelonTheme.deepAccent.withAlphaComponent(0.12)
            orbB.backgroundColor = VelonTheme.primary.withAlphaComponent(0.22)
            orbC.backgroundColor = VelonTheme.basil.withAlphaComponent(0.18)
            plateRing.layer.borderColor = VelonTheme.deepAccent.withAlphaComponent(0.12).cgColor
            steamLayer.strokeColor = VelonTheme.warmStone.withAlphaComponent(0.25).cgColor
        case .detail:
            gradient.colors = [
                VelonTheme.charcoal.withAlphaComponent(0.92).cgColor,
                UIColor(red: 0.35, green: 0.18, blue: 0.18, alpha: 1).cgColor,
                VelonTheme.primaryDeep.cgColor
            ]
            orbA.backgroundColor = VelonTheme.primary.withAlphaComponent(0.35)
            orbB.backgroundColor = VelonTheme.saffron.withAlphaComponent(0.2)
            orbC.backgroundColor = .white.withAlphaComponent(0.12)
            plateRing.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
            steamLayer.strokeColor = UIColor.white.withAlphaComponent(0.25).cgColor
        }
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.locations = [0, 0.45, 1]
    }

    private func rebuildSteam() {
        let path = UIBezierPath()
        let origin = CGPoint(x: bounds.width * 0.3, y: bounds.height * 0.18)
        path.move(to: origin)
        path.addCurve(
            to: CGPoint(x: origin.x + 40, y: origin.y - 70),
            controlPoint1: CGPoint(x: origin.x - 20, y: origin.y - 30),
            controlPoint2: CGPoint(x: origin.x + 55, y: origin.y - 40)
        )
        path.move(to: CGPoint(x: origin.x + 28, y: origin.y + 8))
        path.addCurve(
            to: CGPoint(x: origin.x + 70, y: origin.y - 55),
            controlPoint1: CGPoint(x: origin.x + 10, y: origin.y - 20),
            controlPoint2: CGPoint(x: origin.x + 90, y: origin.y - 25)
        )
        steamLayer.path = path.cgPath
        steamLayer.frame = bounds
    }

    private func startMotion() {
        animateFloat(orbA, dx: 18, dy: 26, duration: 5.2)
        animateFloat(orbB, dx: -16, dy: 20, duration: 6.4)
        animateFloat(orbC, dx: 12, dy: -18, duration: 4.8)
        animateFloat(plateRing, dx: -10, dy: 14, duration: 7.2)
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 0.25
        pulse.toValue = 0.7
        pulse.duration = 2.4
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        steamLayer.add(pulse, forKey: "steam")
    }

    private func animateFloat(_ view: UIView, dx: CGFloat, dy: CGFloat, duration: CFTimeInterval) {
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .repeat, .autoreverse, .allowUserInteraction]) {
            view.transform = CGAffineTransform(translationX: dx, y: dy).rotated(by: 0.05)
        }
    }
}
