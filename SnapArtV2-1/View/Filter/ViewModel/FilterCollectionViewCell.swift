import UIKit

class FilterCollectionViewCell: UICollectionViewCell {
    static let identifier = "FilterCollectionViewCell"
    
    // UI Elements
    private let iconLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 32)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    

    override var isSelected: Bool {
        didSet {
            contentView.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.5) : UIColor.black.withAlphaComponent(0.5)
            contentView.layer.borderWidth = isSelected ? 2 : 0
        }
    }
    
    // Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // UI Setup
    private func setupUI() {
        // Cell appearance
        contentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        contentView.layer.cornerRadius = 10
        contentView.layer.borderColor = UIColor.white.cgColor
        contentView.clipsToBounds = true
        
        // Add subviews
        contentView.addSubview(iconLabel)
        contentView.addSubview(nameLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            iconLabel.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 2),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])
    }
    
    // Configure cell with filter
    func configure(with filter: FilterType) {
        iconLabel.text = filter.icon
        nameLabel.text = filter.displayName
    }
    
    // Configure with CustomFilter
    func configure(with filter: CustomFilter) {
        iconLabel.text = filter.icon
        nameLabel.text = filter.displayName
    }
    
    // Reset cell for reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        iconLabel.text = nil
        nameLabel.text = nil
        isSelected = false
    }
} 
