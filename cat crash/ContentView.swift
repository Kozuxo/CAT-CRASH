

import Combine
import SwiftUI

let gerakawal = 35
let lineWidth: CGFloat = 5
let radius: CGFloat = 70
struct GameView: View {
    @AppStorage("scoretinggi") var scoretinggi = 0
    typealias ViewModel = GameViewModel
    @StateObject private var viewModel: ViewModel
    @State private var kotak = [Int: CGRect]()
    @State private var pilihindex: Int? = nil
    @State private var pilihopacity = 0.5
    @State private var bisagerak = true
    @State private var score : Int = 0
    @State private var aktifatau = false
    @State private var toggleAlert = false
    @State private var gameselesai = false
    @State private var banyakgerak = gerakawal
    @State private var bonusterus: Int = 0
    @State private var lebarbar: CGFloat = 70
    @State private var tinggibar: CGFloat = 10
    @State private var warnaa = Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))
    @State private var warnab = Color(#colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1))

    private enum Space: Hashable {
        case board
    }
    init() {
        _viewModel = .init(wrappedValue: .init())
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .topLeading) {
                ZStack {
                    VStack(spacing:2){
                        
                      
                        ForEach(0..<GameViewModel.Constant.lebarpapan, id: \.self) { y in
                            HStack (spacing: 2) {
                                ForEach(0..<GameViewModel.Constant.lebarpapan, id: \.self) { x in
                                    let index = x + y * GameViewModel.Constant.lebarpapan
                                    let background = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
                                    GeometryReader { proxy in
                                        RoundedRectangle(cornerRadius: proxy.size.width*0.1)
                                            .aspectRatio(1, contentMode: .fit)
                                            .preference(
                                                key: SquaresPreferenceKey.self,
                                                value: [index: proxy.frame(in: .named(Space.board))]
                                            )
                                            .foregroundColor(Color(background))
                                    }
                                    .onTapGesture { Task { await handleTap(at: index);bonusterus=1 } }
                                }
                            }
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    ToolbarItem(placement:.navigationBarLeading) {
                        VStack (alignment:.center) {
                            Image ("crashcat")
                                .resizable()
                                .frame(width: 400, height: 70, alignment: .center)
                        }
                    }
                    ToolbarItem(placement:.bottomBar) {
                        VStack{
                            Image("score")
                                 .resizable()
                                 .frame(width: 100, height: 25, alignment: .center)
                             Text("\(score)")
                                 .bold()
                                 .font(.title)
                                 .foregroundColor(.black)
                        HStack {
                            Text("Move:\(banyakgerak)")
                                .bold()
                                .foregroundColor(.black)
                                .padding(.bottom, 60)
                            let multiplier = lebarbar / 35
                            ZStack (alignment:.leading) {
                                RoundedRectangle(cornerRadius: tinggibar,style: .continuous)
                                    .frame(width:lebarbar, height: tinggibar)
                                    .foregroundColor(Color.black.opacity(0.1))
                                RoundedRectangle(cornerRadius: tinggibar,style: .continuous)
                                    .frame(width:CGFloat(banyakgerak) * multiplier, height: tinggibar)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [warnaa,warnab]), startPoint: .leading, endPoint:.trailing)
                                    .clipShape(RoundedRectangle(cornerRadius: 5,style: .continuous))
                                    )
                                    .foregroundColor(.clear)
                                    .padding(.bottom, 60)
                            }
                            Button {
                                viewModel.papanbaru()
                                banyakgerak = gerakawal
                                score = 0
                                toggleAlert = false
                            } label: {
                                Image(systemName: "arrow.counterclockwise.circle")
                                    .resizable()
                                    .frame(width: 40, height: 40, alignment: .center)
                                    .padding(.bottom, 60)
                            }
                        }
                        }
                        .alert(isPresented: $gameselesai) {
                            Alert(title: Text("Game Over"), message:Text("Your Score:\(score)"), dismissButton: .default(Text("restart"), action: {
                                banyakgerak = gerakawal;
                                score = 0;
                                viewModel.papanbaru();
                                toggleAlert = false;
                                if scoretinggi < score {
                                    scoretinggi = score
                                };
                            }))
                    }
                    }
                }
                .background(Image("pastel"))
                if let pilihindex = pilihindex, let rect = kotak[pilihindex] {
                    RoundedRectangle(cornerRadius: rect.width*0.1)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: rect.size.width)
                        .offset(x: rect.minX, y: rect.minY)
                        .foregroundColor(Color.blue)
                        .opacity(pilihopacity)
                        .onAppear { pilihopacity = 1.0 }
                        .onDisappear { pilihopacity = 0.5 }
                        .animation(Animation.easeInOut(duration: 1).repeatForever(), value: pilihopacity)
                        .allowsHitTesting(false)
                }
                ForEach(viewModel.cells) { cell in
                    let square = kotak[cell.position] ?? .init(origin: .zero, size: .zero)
                    let rect = square.insetBy(dx: square.size.width * 0.1, dy: square.size.height * 0.1)
                    Image(ViewModel.Constant.cellContents[cell.content])
                        .resizable()
                        .foregroundColor(Color(ViewModel.Constant.colors[cell.content]))
                        .frame(width: rect.size.width, height: rect.size.height)
                        .scaleEffect(cell.isMatched ? 1e-6 : 1, anchor: .center)
                        .offset(x: rect.minX, y: rect.minY)
                        .transition(.move(edge: .top))
                        .shadow(radius: 2)
                        .allowsHitTesting(false)
                }
            }
                .background(Color(.red)).ignoresSafeArea()
                .coordinateSpace(name: Space.board)
                .onPreferenceChange(SquaresPreferenceKey.self) { kotak = $0 }
        }
    }
    private func handleTap(at index: Int) async {
        let cell = viewModel.cells[index]
        guard pilihindex != cell.position else { return pilihindex = nil }
        guard let pilihindex = pilihindex else { return pilihindex = cell.position }
        guard bisagerak, ViewModel.bersebelahan(pilihindex, to: cell.position) else { return }
        self.pilihindex = nil
        bisagerak = false
        defer { bisagerak = true }
        await animate(with: .easeInOut(duration:0.5)) {
            viewModel.tukar(pilihindex, with: cell.position)
            banyakgerak -= 1
            if banyakgerak == 0 {
                gameselesai.toggle()
            }
        }
        guard viewModel.hasMatches else {
            return await animate(with: .easeInOut(duration:0.5)) {
                viewModel.tukar(pilihindex, with: cell.position)
                banyakgerak += 1
            }
        }
        while viewModel.hasMatches {
            score = score + 10 * bonusterus
            bonusterus += 1
            await animate(with: .linear(duration:0.25)) {
                viewModel.buangsama()
            }
            while(viewModel.canCollapse) {
                await animate(with: .linear(duration:0.15)) {
                    viewModel.runtuh()
                }
            }
        }
    }
}

