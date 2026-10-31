import SwiftUI

struct DrinksListView: View {
    @StateObject private var viewModel = DrinksViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.12)
                    .ignoresSafeArea()
                
                if viewModel.drinks.isEmpty && viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        Text(error)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Button("Повторить запрос") {
                            Task { await viewModel.loadDrinks() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if viewModel.drinks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "wineglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("Пока пусто")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.drinks) { drink in
                                DrinkRowView(drink: drink, isBarCheckedIn: false, onDrinkLogged: {})
                                    .onAppear {
                                        if drink.id == viewModel.drinks.last?.id {
                                            Task { await viewModel.loadDrinks() }
                                        }
                                    }
                            }
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Bar Menu")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("BAR MENU")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .task {
                await viewModel.loadDrinks()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    DrinksListView()
}
