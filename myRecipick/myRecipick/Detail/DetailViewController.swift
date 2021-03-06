//
//  DetailViewController.swift
//  myRecipick
//
//  Created by hanwe lee on 2021/05/04.
//  Copyright © 2021 depromeet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import LinkPresentation

class DetailViewController: UIViewController, CoordinatorMVVMViewController, ClassIdentifiable {
    
    struct MySection: SectionModelType {
        typealias Item = CellModel
        var items: [CellModel]
        init(original: DetailViewController.MySection, items: [CellModel]) {
            self.items = items
            self = original
        }
    }
    
    enum CellModel {
        case header
        case customMenuObjModel(CustomMenuDetailOriginalMenuObjModel)
        case ingredient(CustomMenuDetailOptionGroupOptionsObjModel)
        case comment(String) // 모델 나오면 수정
    }
    
    typealias SelfType = DetailViewController
    typealias CoordinatorType = DetailViewCoordinator
    typealias MVVMViewModelClassType = DetailViewModel
    
    enum BackgroundColorEnum: CaseIterable {
        case green
        case pink
        case brown
        case blue
        case orange
        
        func getColor() -> UIColor {
            switch self {
            case .brown:
                return UIColor(asset: Colors.backgroundBrown) ?? .black
            case .blue:
                return UIColor(asset: Colors.backgroundBlue) ?? .blue
            case .green:
                return UIColor(asset: Colors.secondaryGreen) ?? .green
            case .orange:
                return UIColor(asset: Colors.backgroundOrange) ?? .orange
            case .pink:
                return UIColor(asset: Colors.backgroundPink) ?? .purple
            }
        }
        
        static func getTypeFromColor(_ inputedColor: UIColor) -> BackgroundColorEnum {
            var returnValue: BackgroundColorEnum = .green
            for item in BackgroundColorEnum.allCases {
                if inputedColor.isSameColor(item.getColor()) {
                    returnValue = item
                    break
                }
            }
            return returnValue
        }
    }

    // MARK: outlet
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var backgroundContainerView: UIView!
    @IBOutlet weak var backgroundBottomView: UIView!
    @IBOutlet weak var backgroundBottomViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainContainerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topContentsContainerView: UIView!
    @IBOutlet weak var topContentsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topContentsViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainImgView: UIImageView!
    @IBOutlet weak var mainImgContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainImgContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var customMenuTitleLabel: UILabel!
    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet weak var menuImgView: UIImageView!
    @IBOutlet weak var menuTitleLabel: UILabel!
    @IBOutlet weak var ingredientsContainerView: UIView!
    @IBOutlet weak var ingredientsContainerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var ingredientsContainerViewTraillingConstraint: NSLayoutConstraint!
    @IBOutlet weak var ingredientsContainerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var colorPickContainerView: UIView!
    @IBOutlet weak var colorPickContainerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var colorPickView: UIView!
    @IBOutlet weak var currentPickedColorView: UIView!
    @IBOutlet weak var currentPickedColorViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var otherColorPickContainerView: UIView!
    @IBOutlet weak var otherColorPickContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var otherColor1View: UIView!
    @IBOutlet weak var otherColor2View: UIView!
    @IBOutlet weak var otherColor3View: UIView!
    @IBOutlet weak var otherColor4View: UIView!
    @IBOutlet weak var otherColor5View: UIView!
    
    @IBOutlet weak var closeBtnTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomButtonContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var buttonContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollToTopButton: UIButton!
    
    // MARK: property
    
    var coordinator: DetailViewCoordinator!
    var disposeBag: DisposeBag = DisposeBag()
    var viewModel: DetailViewModel!
    var isViewModelBinded: Bool = false
    var isSelectableBackgroundColor: Bool = false {
        didSet {
            if self.isSelectableBackgroundColor {
                self.otherColorPickContainerView.isHidden = false
                self.otherColorPickContainerViewHeightConstraint.constant = self.originOtherColorPickContainerViewHeightConstraint
                self.otherColorPickContainerView.fadeIn(completeHandler: nil)
            } else {
                self.otherColorPickContainerView.fadeOut(completeHandler: { [weak self] in
                    self?.otherColorPickContainerViewHeightConstraint.constant = 0
                    self?.otherColorPickContainerView.isHidden = true
                })
            }
        }
    }
    
    lazy var ingredientsContainerViewMaxWidth: CGFloat = UIScreen.main.bounds.width - self.ingredientsContainerViewLeadingConstraint.constant - self.ingredientsContainerViewTraillingConstraint.constant
    var ingredientsContainerViewTotalLineCnt: Int = 0
    let ingredientsCellRightInterval: CGFloat = 4
    let ingredientsCellBottomInterval: CGFloat = 4
    let ingredientsCellViewWidth: CGFloat = 70
    let ingredientsCellViewHeight: CGFloat = 70
    
    var originTopContentsViewHeightConstraint: CGFloat = 0
    var originMainImgContainerViewWidthConstraint: CGFloat = 0
    var originMainImgContainerViewHeightConstraint: CGFloat = 0
    var originColorPickContainerViewTopConstraint: CGFloat = 0
    var originCloseBtnTopConstraint: CGFloat = 0
    var originOtherColorPickContainerViewHeightConstraint: CGFloat = 0
    let minImgResizeScrollYOffset: CGFloat = 50
    
    var currentBackgroundColor: BackgroundColorEnum = .green {
        didSet {
            if self.currentPickedColorView != nil {
                self.currentPickedColorView.backgroundColor = self.currentBackgroundColor.getColor()
            }
            if self.backgroundContainerView != nil {
                self.backgroundContainerView.backgroundColor = self.currentBackgroundColor.getColor()
            }
        }
    }
    
    var isFirstScrollDidScrollFlag: Bool = false // 이 플레그를 사용하지않고싶음..
    
    // MARK: lifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bindingViewModel(viewModel: self.viewModel)
        self.coordinator.setClearNavigation()
        self.coordinator.navigationController?.navigationBar.isHidden = true
        self.tableView.register(UINib(nibName: DetailTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: DetailTableViewCell.identifier)
        self.tableView.register(UINib(nibName: DetailHeaderTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: DetailHeaderTableViewCell.identifier)
        self.tableView.register(UINib(nibName: DetailCommentTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: DetailCommentTableViewCell.identifier)
        self.tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        print("- \(type(of: self)) deinit")
    }
    
    
    func bind(viewModel: MVVMViewModel) {
        if type(of: viewModel) == DetailViewModel.self {
            guard let vm: DetailViewModel = (viewModel as? DetailViewModel) else { return }
            
            self.tableView.rx.didScroll
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    let yOffset = self.tableView.contentOffset.y + self.originTopContentsViewHeightConstraint
                    self.topContentsViewTopConstraint.constant = -yOffset
                    self.colorPickContainerViewTopConstraint.constant = -yOffset + self.originColorPickContainerViewTopConstraint
                    self.closeBtnTopConstraint.constant = -yOffset + self.originCloseBtnTopConstraint
                    
                    var percent: CGFloat = yOffset/self.originTopContentsViewHeightConstraint
                    if 0 > percent {
                        percent = 0
                    }
                    if percent > 1 {
                        percent = 1
                    }
                    
                    if yOffset > 50 {
                        if self.scrollToTopButton.tag == 2 || self.scrollToTopButton.tag == 0 {
                            self.scrollToTopButton.tag = 1
                            self.scrollToTopButton.isHidden = false
                            self.scrollToTopButton.fadeIn(completeHandler: nil)
                        }
                    } else {
                        if self.scrollToTopButton.tag == 1 || self.scrollToTopButton.tag == 0 {
                            self.scrollToTopButton.tag = 2
                            self.scrollToTopButton.fadeOut(completeHandler: { [weak self] in
                                self?.scrollToTopButton.isHidden = true
                            })
                        }
                    }
            })
            .disposed(by: self.disposeBag)
            
            self.tableView.rx.didScroll
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    let height = self.tableView.frame.size.height
                    let contentYOffset = self.tableView.contentOffset.y
                    let distanceFromBottom = self.tableView.contentSize.height - contentYOffset
                    if distanceFromBottom < height {
                        if self.isFirstScrollDidScrollFlag { // 왜 처음에 스크롤하지 않았는데 호출되는것일까.. 이걸 처음인지 어떻게 알까
                            let newBottomPaddingViewHeight: CGFloat = (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0) + -(distanceFromBottom - height) + self.bottomButtonContainerViewHeightConstraint.constant
                            self.backgroundBottomViewHeightConstraint.constant = newBottomPaddingViewHeight
                        }
                    }
                    self.isFirstScrollDidScrollFlag = true
            })
            .disposed(by: self.disposeBag)
            
            self.tableView.rx.didScroll
                .subscribe(onNext: { [weak self] in
                    if self?.isSelectableBackgroundColor ?? false {
                        self?.isSelectableBackgroundColor = false
                    }
                })
                .disposed(by: self.disposeBag)
            
            vm.outputs.customMenuInfo
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let url = data.imageUrl {
                        self.mainImgView.kf.setImage(with: URL(string: url), placeholder: nil, options: [.cacheMemoryOnly], completionHandler: { [weak self] _ in
                            self?.mainImgView.fadeIn(duration: 0.1, completeHandler: nil)
                        })
                        self.menuImgView.kf.setImage(with: URL(string: url), placeholder: nil, options: [.cacheMemoryOnly], completionHandler: { [weak self] _ in
                            self?.mainImgView.fadeIn(duration: 0.1, completeHandler: nil)
                        })
                    }
                    self.customMenuTitleLabel.text = data.name
                })
                .disposed(by: self.disposeBag)
            
            vm.outputs.detailCustomMenu
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                
                    self.menuTitleLabel.text = data.menu?.name ?? data.name
                
            })
            .disposed(by: self.disposeBag)
            
            vm.outputs.allIngredients
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    self.ingredientsContainerViewHeightConstraint.constant = self.calculateIngredientsContainerViewHeight(data: data)
                    self.makeIngredientsViews(data: data)
                    self.refreshTableViewInset()
            })
            .disposed(by: self.disposeBag)
            
            Observable.zip(vm.outputs.customMenuInfo, vm.outputs.allIngredients, vm.detailCustomMenu)
                .subscribe(onNext: { [weak self] response in
                    var ingredientCellArr: [CellModel] = []
                    for i in 0..<response.1.count {
                        ingredientCellArr.append(CellModel.ingredient(response.1[i]))
                    }
                    let sections = Observable.just([
                        SectionModel(model: "header", items: [
                            CellModel.header
                        ]),
                        SectionModel(model: "menu", items: [
                            CellModel.customMenuObjModel(response.2.menu ?? CustomMenuDetailOriginalMenuObjModel())
                        ]),
                        SectionModel(model: "ingredients", items: ingredientCellArr)
//                        SectionModel(model: "comment", items: [
//                            CellModel.comment("데이터 나오면 바꿔야함")
//                        ])
                    ])
                    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, CellModel>>(configureCell: { dataSource, table, indexPath, item in
                        switch item {
                        case .header:
                            return self?.makeHeaderCell(from: table) ?? UITableViewCell()
                        case .customMenuObjModel(let contents):
                            return self?.makeMenuCell(with: contents, from: table) ?? UITableViewCell()
                        case .ingredient(let contents):
                            return self?.makeIngredientCell(with: contents, from: table) ?? UITableViewCell()
                        case .comment(let contents):
                            return self?.makeCommentCell(with: contents, from: table) ?? UITableViewCell()
                        }
                    })
                    guard let self = self else { return }
                    sections
                        .bind(to: self.tableView.rx.items(dataSource: dataSource))
                        .disposed(by: self.disposeBag)
                    
                })
                .disposed(by: self.disposeBag)
            
        }
    }
    
    // MARK: func
    
    static func makeViewController(coordinator: DetailViewCoordinator, viewModel: DetailViewModel) -> DetailViewController {
        return DetailViewController.makeViewController(coordinator: coordinator, viewModel: viewModel, backgroundColor: .white)
    }
    
    static func makeViewController(coordinator: DetailViewCoordinator, viewModel: DetailViewModel, backgroundColor: UIColor) -> DetailViewController {
        let detailViewController: DetailViewController = UIStoryboard(name: "Detail", bundle: nil).instantiateViewController(identifier: DetailViewController.identifier)
        detailViewController.coordinator = coordinator
        detailViewController.viewModel = viewModel
        detailViewController.currentBackgroundColor = DetailViewController.BackgroundColorEnum.getTypeFromColor(backgroundColor)
        return detailViewController
    }
    
    func initUI() {
        self.backgroundContainerView.backgroundColor = self.currentBackgroundColor.getColor()
        self.backgroundBottomView.backgroundColor = UIColor(asset: Colors.white)
        self.backgroundBottomViewHeightConstraint.constant = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0
        self.mainContainerView.backgroundColor = .clear
        self.mainContainerView.layer.masksToBounds = true
        self.topContentsContainerView.backgroundColor = .clear
        self.topContentsContainerView.isUserInteractionEnabled = false
        self.customMenuTitleLabel.font = UIFont.myRecipickFont(.detailMenuTitle)
        self.customMenuTitleLabel.textColor = UIColor(asset: Colors.white)
        self.menuContainerView.backgroundColor = UIColor(asset: Colors.white)
        self.menuContainerView.layer.cornerRadius = 17.5
        self.menuTitleLabel.font = UIFont.myRecipickFont(.yourRecipe)
        self.menuTitleLabel.textColor = UIColor(asset: Colors.grayScale33)
        self.ingredientsContainerView.backgroundColor = .clear
        self.ingredientsContainerView.isUserInteractionEnabled = false
        self.tableView.backgroundColor = .clear
        self.tableView.separatorStyle = .none
        
        self.originMainImgContainerViewWidthConstraint = self.mainImgContainerViewWidthConstraint.constant
        self.originMainImgContainerViewHeightConstraint = self.mainImgContainerViewHeightConstraint.constant
        
        self.colorPickView.backgroundColor = UIColor(asset: Colors.white)
        self.colorPickView.layer.cornerRadius = 6
        self.currentPickedColorView.layer.cornerRadius = self.currentPickedColorViewWidthConstraint.constant/2
        self.currentPickedColorView.backgroundColor = self.currentBackgroundColor.getColor()
        self.originColorPickContainerViewTopConstraint = self.colorPickContainerViewTopConstraint.constant
        self.originCloseBtnTopConstraint = self.closeBtnTopConstraint.constant
        
        self.otherColorPickContainerView.backgroundColor = UIColor(asset: Colors.white)
        self.otherColorPickContainerView.layer.cornerRadius = 6
        self.otherColorPickContainerView.layer.masksToBounds = true
        self.originOtherColorPickContainerViewHeightConstraint = self.otherColorPickContainerViewHeightConstraint.constant
        self.otherColorPickContainerViewHeightConstraint.constant = 0
        self.otherColorPickContainerView.alpha = 0
        self.otherColorPickContainerView.isHidden = true
        
        self.otherColor1View.layer.cornerRadius = self.currentPickedColorViewWidthConstraint.constant/2
        self.otherColor1View.backgroundColor = DetailViewController.BackgroundColorEnum.pink.getColor()
        
        self.otherColor2View.layer.cornerRadius = self.currentPickedColorViewWidthConstraint.constant/2
        self.otherColor2View.backgroundColor = DetailViewController.BackgroundColorEnum.brown.getColor()
        
        self.otherColor3View.layer.cornerRadius = self.currentPickedColorViewWidthConstraint.constant/2
        self.otherColor3View.backgroundColor = DetailViewController.BackgroundColorEnum.blue.getColor()
        
        self.otherColor4View.layer.cornerRadius = self.currentPickedColorViewWidthConstraint.constant/2
        self.otherColor4View.backgroundColor = DetailViewController.BackgroundColorEnum.orange.getColor()
        
        self.otherColor5View.layer.cornerRadius = self.currentPickedColorViewWidthConstraint.constant/2
        self.otherColor5View.backgroundColor = DetailViewController.BackgroundColorEnum.green.getColor()
        
        self.shareBtn.adjustsImageWhenHighlighted = false
        self.shareBtn.showsTouchWhenHighlighted = false
        self.shareBtn.setBackgroundColor(UIColor(asset: Colors.primaryNormal) ?? .orange, for: .normal)
        self.shareBtn.setBackgroundColor(UIColor(asset: Colors.primaryDark) ?? .orange, for: .highlighted)
        self.shareBtn.setTitle("공유하기", for: .normal)
        self.shareBtn.setTitleColor(.white, for: .normal)
        self.shareBtn.titleLabel?.font = UIFont.myRecipickFont(.subTitle2)
        self.shareBtn.layer.cornerRadius = 10
        self.shareBtn.layer.masksToBounds = true
        
    }
    
    // MARK: private func
    
    private func calculateIngredientsContainerViewHeight(data: [CustomMenuDetailOptionGroupOptionsObjModel]) -> CGFloat {
        var resultValue: CGFloat = self.ingredientsCellViewHeight
        self.ingredientsContainerViewTotalLineCnt = 1
        let totalIngredientsCnt: Int = data.count
        var currentLineWidth: CGFloat = 0
        for _ in 0..<totalIngredientsCnt {
            if (currentLineWidth + ingredientsCellViewWidth) > self.ingredientsContainerViewMaxWidth {
                resultValue += (self.ingredientsCellBottomInterval + self.ingredientsCellViewHeight)
                self.ingredientsContainerViewTotalLineCnt += 1
                currentLineWidth = 0
            }
            currentLineWidth += (self.ingredientsCellViewWidth + self.ingredientsCellRightInterval)
        }
        
        return resultValue
    }
    
    private func makeNewIngredientsView(data: CustomMenuDetailOptionGroupOptionsObjModel) -> IngredientsView? {
        let newView: IngredientsView? = IngredientsView.instance()
        newView?.infoData = data
        return newView
    }
    
    private func makeIngredientsViews(data: [CustomMenuDetailOptionGroupOptionsObjModel]) {
        self.ingredientsContainerView.removeAllSubview()
        let roundHalfDownNumberOfItemInLine: Int = data.count/self.ingredientsContainerViewTotalLineCnt
        var isExsistRemainder: Bool = false
        if data.count%self.ingredientsContainerViewTotalLineCnt != 0 {
            isExsistRemainder = true
        }
        print("roundHalfDownNumberOfItemInLine:\(roundHalfDownNumberOfItemInLine)")
        var currentYOffset: CGFloat = 0
        var currentIndex: Int = 0
        var numberOfItemInLineCorrectionValue: Int = 0
        while true {
            if currentIndex > data.count - 1 {
                break
            }
            let lineContainerView: ReleaseCheckPrintView = ReleaseCheckPrintView()
            lineContainerView.backgroundColor = .clear
            self.ingredientsContainerView.addSubview(lineContainerView)
            lineContainerView.snp.makeConstraints { (make) in
                make.top.equalTo(self.ingredientsContainerView.snp.top).offset(currentYOffset)
                make.centerX.equalTo(self.ingredientsContainerView.snp.centerX).offset(0)
                make.height.equalTo(self.ingredientsCellViewHeight)
            }
            weak var beforeItemView: IngredientsView?
            if isExsistRemainder {
                numberOfItemInLineCorrectionValue = numberOfItemInLineCorrectionValue == 0 ? 1 : 0
            }
            let numberOfItemInLine = roundHalfDownNumberOfItemInLine + numberOfItemInLineCorrectionValue
            for i in 0..<numberOfItemInLine {
                if currentIndex > data.count - 1 {
                    break
                }
                let item = data[currentIndex]
                guard let itemView: IngredientsView = self.makeNewIngredientsView(data: item) else { print("detail Item Index error") ; continue }
                lineContainerView.addSubview(itemView)
                if i == 0 && currentIndex == data.count - 1 {
                    itemView.snp.makeConstraints { (make) in
                        make.top.equalTo(lineContainerView.snp.top).offset(0)
                        make.width.equalTo(self.ingredientsCellViewWidth)
                        make.height.equalTo(self.ingredientsCellViewHeight)
                        make.leading.equalTo(lineContainerView.snp.leading).offset(0)
                        make.trailing.equalTo(lineContainerView.snp.trailing).offset(0)
                    }
                } else if i == 0 {
                    itemView.snp.makeConstraints { (make) in
                        make.top.equalTo(lineContainerView.snp.top).offset(0)
                        make.leading.equalTo(lineContainerView.snp.leading).offset(0)
                        make.width.equalTo(self.ingredientsCellViewWidth)
                        make.height.equalTo(self.ingredientsCellViewHeight)
                    }
                    beforeItemView = itemView
                } else if i == (numberOfItemInLine - 1) || currentIndex == data.count - 1 {
                    guard let nonNullBeforeItemView = beforeItemView else { print("detail Item Index error") ; continue }
                    itemView.snp.makeConstraints { (make) in
                        make.top.equalTo(lineContainerView.snp.top).offset(0)
                        make.leading.equalTo(nonNullBeforeItemView.snp.trailing).offset(self.ingredientsCellRightInterval)
                        make.width.equalTo(self.ingredientsCellViewWidth)
                        make.height.equalTo(self.ingredientsCellViewHeight)
                        make.trailing.equalTo(lineContainerView.snp.trailing).offset(0)
                    }
                    currentYOffset += (self.ingredientsCellViewHeight + self.ingredientsCellBottomInterval)
                } else {
                    guard let nonNullBeforeItemView = beforeItemView else { print("detail Item Index error") ; continue }
                    itemView.snp.makeConstraints { (make) in
                        make.top.equalTo(lineContainerView.snp.top).offset(0)
                        make.leading.equalTo(nonNullBeforeItemView.snp.trailing).offset(self.ingredientsCellRightInterval)
                        make.width.equalTo(self.ingredientsCellViewWidth)
                        make.height.equalTo(self.ingredientsCellViewHeight)
                    }
                    beforeItemView = itemView
                }
                currentIndex += 1
            }
        }
    }
    
    private func refreshTableViewInset() {
        self.topContentsViewHeightConstraint.constant += self.ingredientsContainerViewHeightConstraint.constant
        self.originTopContentsViewHeightConstraint = self.topContentsViewHeightConstraint.constant
        self.tableView.contentInset = UIEdgeInsets(top: self.topContentsViewHeightConstraint.constant, left: 0, bottom: 0, right: 0)
        self.tableView.contentOffset = CGPoint(x: 0, y: -self.originTopContentsViewHeightConstraint)
    }
    
    private func makeMenuCell(with element: CustomMenuDetailOriginalMenuObjModel, from table: UITableView) -> UITableViewCell {
        guard let cell = table.dequeueReusableCell(withIdentifier: DetailTableViewCell.identifier) as? DetailTableViewCell else { return UITableViewCell() }
        cell.type = .menu
        cell.menuInfoData = element
        return cell
    }
    
    private func makeIngredientCell(with element: CustomMenuDetailOptionGroupOptionsObjModel, from table: UITableView) -> UITableViewCell {
        guard let cell = table.dequeueReusableCell(withIdentifier: DetailTableViewCell.identifier) as? DetailTableViewCell else { return UITableViewCell() }
        cell.type = .ingredients
        cell.detailMenuInfoData = element
        return cell
    }
    
    private func makeHeaderCell(from table: UITableView) -> UITableViewCell {
        guard let cell = table.dequeueReusableCell(withIdentifier: DetailHeaderTableViewCell.identifier) as? DetailHeaderTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeCommentCell(with element: String, from table: UITableView) -> UITableViewCell { // 모델 나오면 수정
        guard let cell = table.dequeueReusableCell(withIdentifier: DetailCommentTableViewCell.identifier) as? DetailCommentTableViewCell else { return UITableViewCell() }
        return cell
    }
    
    // todo 나머지 셀들 구현하기
    
    // MARK: action
    @IBAction func dismissAction(_ sender: Any) {
        self.coordinator.dismiss(animated: true, completion: nil)
    }
    @IBAction func colorPickViewAction(_ sender: Any) {
        self.isSelectableBackgroundColor = !self.isSelectableBackgroundColor
    }
    @IBAction func otherColor1Action(_ sender: Any) {
        self.currentBackgroundColor = .pink
        self.isSelectableBackgroundColor = false
    }
    @IBAction func otherColor2Action(_ sender: Any) {
        self.currentBackgroundColor = .brown
        self.isSelectableBackgroundColor = false
    }
    @IBAction func otherColor3Action(_ sender: Any) {
        self.currentBackgroundColor = .blue
        self.isSelectableBackgroundColor = false
    }
    @IBAction func otherColor4Action(_ sender: Any) {
        self.currentBackgroundColor = .orange
        self.isSelectableBackgroundColor = false
    }
    @IBAction func otherColor5Action(_ sender: Any) {
        self.currentBackgroundColor = .green
        self.isSelectableBackgroundColor = false
    }
    
    @IBAction func scrollToTopAction(_ sender: Any) {
        self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.contentInset.top), animated: true)
    }
    
    @IBAction func shareAction(_ sender: Any) {
        let statusbarArea = (self.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0)
        let bottomPadding = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0
        let extraHeight: CGFloat = statusbarArea + self.topContentsViewHeightConstraint.constant + buttonContainerViewHeightConstraint.constant + bottomPadding
        _ = self.containerView.snapshot(scrollView: self.tableView, extraHeight: extraHeight) // todo 수정
        if let snapshot = self.containerView.snapshot(scrollView: self.tableView, extraHeight: extraHeight) {
            self.backgroundBottomViewHeightConstraint.constant = (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0)
           let imageToShare = [ snapshot, self ]
           let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
           activityViewController.popoverPresentationController?.sourceView = self.shareBtn
           activityViewController.isModalInPresentation = true

           activityViewController.excludedActivityTypes = [.airDrop, .message]

           self.present(activityViewController, animated: true, completion: nil)
       }
    }
    
}

extension DetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var returnValue: CGFloat = 0
        if indexPath.section == 0 {
            returnValue = 85
        } else if indexPath.section == 1 {
            returnValue = 72
        } else if indexPath.section == 2 {
            returnValue = 72
        } else {
            returnValue = 113
        }
        
        return returnValue
    }
}

extension DetailViewController: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return nil
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "나의 레시피를 공유해보세요!"
        return metadata
    }
}
