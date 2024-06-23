import SwiftUI
import GoogleGenerativeAI

// Helper function to create colors more easily
private func createColor(_ red: Double, _ green: Double, _ blue: Double) -> Color {
    Color(red: red / 255, green: green / 255, blue: blue / 255)
}

// Define the colors and gradients used in the petals
private let gradientStart = createColor(230, 230, 250)
private let gradientEnd = createColor(216, 191, 216)
private let gradient = LinearGradient(gradient: Gradient(colors: [gradientStart, gradientEnd]), startPoint: .top, endPoint: .bottom)
private let maskGradient = LinearGradient(gradient: Gradient(colors: [.black]), startPoint: .top, endPoint: .bottom)

// Define the max and min sizes for the animation
private let maxSize: CGFloat = 150  // Adjusted max size
private let minSize: CGFloat = 75
private let inhaleTime: Double = 3
private let exhaleTime: Double = 4
private let pauseTime: Double = 0.5

// Define ghost sizes for animation effect
private let ghostMaxSize: CGFloat = maxSize * 0.99
private let ghostMinSize: CGFloat = maxSize * 0.95

// Google Generative AI model setup
func fetchAPIKey() -> String {
    return "AIzaSyDNlhowJbp1NEOhn_K7nz1SeTPh8yj3p5c" // Replace with your actual API key
}

let model = GenerativeModel(name: "gemini-pro", apiKey: fetchAPIKey())

// BreatheAnimation view implements the breathing flower animation
struct BreatheAnimation: View {
    @State private var size = minSize
    @State private var inhaling = false
    @State private var isAnimating = true
    
    @State private var ghostSize = ghostMaxSize
    @State private var ghostBlur: Double = 0
    @State private var ghostOpacity: Double = 0

    var body: some View {
        ZStack {
            Petals(size: ghostSize, inhaling: inhaling)
                .blur(radius: ghostBlur)
                .opacity(ghostOpacity)
                .drawingGroup()
            Petals(size: size, inhaling: inhaling, isMask: true)
            Petals(size: size, inhaling: inhaling)
            ParticleEffect(size: size, inhaling: inhaling)
        }
        .rotationEffect(Angle.degrees(inhaling ? 60 : -30))
        .onTapGesture {
            isAnimating.toggle()
            if isAnimating {
                performAnimations()
            }
        }
        .onAppear {
            performAnimations()
        }
    }
    
    private func performAnimations() {
        guard isAnimating else { return }

        withAnimation(.easeInOut(duration: inhaleTime)) {
            inhaling = true
            size = maxSize
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleTime + pauseTime) {
            guard isAnimating else { return }
            ghostSize = ghostMaxSize
            ghostBlur = 0
            ghostOpacity = 0.8
            DispatchQueue.main.asyncAfter(deadline: .now() + exhaleTime * 0.2) {
                withAnimation(.easeOut(duration: exhaleTime * 0.6)) {
                    ghostOpacity = 0
                    ghostBlur = 10
                }
            }
            withAnimation(.easeInOut(duration: exhaleTime)) {
                inhaling = false
                size = minSize
                ghostSize = ghostMinSize
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + exhaleTime + pauseTime) {
                performAnimations()
            }
        }
    }
}

// Petals view which renders each petal
private struct Petals: View {
    let size: CGFloat
    let inhaling: Bool
    var isMask = false
    
    var body: some View {
        let petalsGradient = isMask ? maskGradient : gradient
        ZStack {
            ForEach(0..<6) { index in
                petalsGradient
                    .mask(
                        Circle()
                            .frame(width: size, height: size)
                            .offset(x: inhaling ? size * 0.5 : size * 0.3)
                            .rotationEffect(Angle.degrees(Double(index) * 60))
                    )
                    .blendMode(isMask ? .normal : .screen)
            }
        }
        .frame(width: size * 2, height: size * 2)
    }
}

// TypingTextAnimation view for typing animation
struct TypingTextAnimation: View {
    let text: String
    @State private var visibleText = ""
    @State private var charIndex = 0

    var body: some View {
        Text(visibleText)
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.blue) // Changed text color to purple
            .onAppear {
                startTyping()
            }
    }

    private func startTyping() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if charIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: charIndex)
                visibleText += String(text[index])
                charIndex += 1
            } else {
                timer.invalidate()
            }
        }
        timer.fire()
    }
}

// Particle struct to represent individual particles
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var angle: Double
}

// ParticleEffect view for particle animation
struct ParticleEffect: View {
    @State private var particles = [Particle]()
    let size: CGFloat
    let inhaling: Bool

    var body: some View {
        ForEach(particles) { particle in
            Circle()
                .fill(Color.white)
                .frame(width: particle.size, height: particle.size)
                .position(x: particle.x, y: particle.y)
                .opacity(particle.opacity)
                .animation(.easeInOut(duration: 0.5), value: inhaling)
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        particles.removeAll()
        for _ in 0..<20 {
            let x = CGFloat.random(in: -size...size)
            let y = CGFloat.random(in: -size...size)
            let size = CGFloat.random(in: 5...10)
            let opacity = Double.random(in: 0.5...1.0)
            let angle = Double.random(in: 0...360)
            let particle = Particle(x: x, y: y, size: size, opacity: opacity, angle: angle)
            particles.append(particle)
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            BreathingFlowerView()
                .background(Color.white)
        }
    }
}


struct BreathingFlowerView: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                ZStack {
                    BreatheAnimation()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Text("BridgeIt")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }

                Spacer()

                NavigationLink(destination: LoginView()) {
                    Text("Continue")
                        .font(.headline)
                        .padding()
                        .frame(width: 200)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.black]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(radius: 10)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// LoginView for user authentication
struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                ZStack {
                    BreatheAnimation()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Text("BridgeIt")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }

                Spacer()

                VStack {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button("Login") {
                        if username == "Karthik" && password == "karthik" {
                            isLoggedIn = true
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.black]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(25)
                    .shadow(radius: 10)
                    .padding(.horizontal)
                    // Navigate to ChildInfoView when isLoggedIn is true
                    NavigationLink(
                        destination: ChildInfoView(),
                        isActive: $isLoggedIn,
                        label: {
                            EmptyView()
                        })
                }
                .padding()

                Spacer()
            }
        }
    }
}



struct ChildInfoView: View {
    @State private var selectedMoods: Set<String> = []
    @State private var isContinueButtonPressed = false

    // Define allMoods here
    private let allMoods = ["ecom", "marketing", "tech", "admin"]

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                Spacer()

                Text("Choose a department to get info from")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(allMoods, id: \.self) { mood in
                            MoodButton(mood: mood, isSelected: selectedMoods.contains(mood)) {
                                if selectedMoods.contains(mood) {
                                    selectedMoods.remove(mood)
                                } else {
                                    selectedMoods.insert(mood)
                                }
                            }
                            .buttonStyle(MoodButtonStyle())
                        }
                    }
                    .padding()
                }

                Spacer()

                NavigationLink(destination: ChatView(), isActive: $isContinueButtonPressed) {
                    Text("Continue")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.black]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(radius: 10)
                        .padding()
                }
                .buttonStyle(ContinueButtonStyle())
            }
        }
    }
}


struct ChatView: View {
    @State private var userInput: String = ""
    @State private var chatHistory: [String] = []

    var body: some View {
        VStack {
            ScrollView {
                ForEach(chatHistory, id: \.self) { message in
                    Text(message)
                }
            }
            .padding()

            TextField("Ask me anything...", text: $userInput, onCommit: {
                sendMessage(userInput)
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
        }
        .navigationTitle("Saha Chat")
    }

    private func sendMessage(_ message: String) {
        chatHistory.append("You: \(message)")
        
        Task {
            let result = await generateContent(prompt: message)
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    chatHistory.append("BridgeIt: \(response)")
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    chatHistory.append("Gemini: Error - \(error.localizedDescription)")
                }
            }
        }
        
        userInput = ""
    }

    private func generateContent(prompt: String) async -> Result<String, Error> {
        do {
            let response = try await model.generateContent(prompt)
            if let text = response.text {
                return .success(text)
            } else {
                return .failure(NSError(domain: "No text found in response", code: 0, userInfo: nil))
            }
        } catch let error {
            return .failure(error)
        }
    }
}

struct MoodButton: View {
    let mood: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mood)
                .padding()
                .frame(minWidth: 300)
                .background(isSelected ? Color.blue.opacity(0.8) : Color.clear)
                .cornerRadius(30)
                .foregroundColor(.white) // Change text color to white
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 1) // Change stroke color to white
                )
                .font(.system(size: 14, weight: .bold))
        }
    }
}
struct ContinueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct MoodButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(15) // Increase padding
            .frame(minWidth: 200) // Ensure a minimum width
            .background(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue.opacity(0.5))
            .cornerRadius(20)
            .foregroundColor(.white)
            .font(.system(size: 18, weight: .bold)) // Increase font size
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

private extension View {
    func rotateIf(_ condition: Bool, _ angle: Angle) -> some View {
        self.rotationEffect(condition ? angle : .zero)
    }
    
    func rotateIfNot(_ condition: Bool, _ angle: Angle) -> some View {
        self.rotationEffect(!condition ? angle : . zero)
    }
    
    func xOffsetIf(_ condition: Bool, _ offset: CGFloat) -> some View {
        self.offset(x: condition ? offset : .zero)
    }
    
    func frameIf(_ condition: Bool, _ size: CGFloat) -> some View {
        self.frame(width: condition ? size : .none, height: condition ? size : .none)
    }
    
    func frameIfNot(_ condition: Bool, _ size: CGFloat) -> some View {
        self.frame(width: !condition ? size : .none, height: !condition ? size : .none)
    }
    
    func greedyFrame() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func backgroundColor(_ color: Color) -> some View {
        self.background(color)
    }
}

private func after(_ delay: Double, perform: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: perform)
}
