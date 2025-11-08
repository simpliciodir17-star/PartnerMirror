import UIKit

final class WebViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fundo vermelho bem forte pra não confundir com nada
        view.backgroundColor = .red

        // Label central dizendo que a tela carregou
        let label = UILabel()
        label.text = "DEBUG OK"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
