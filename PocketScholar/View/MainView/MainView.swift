//
//  MainView.swift
//  PocketScholar
//
//  Created by Дмитрий Цепилов on 06.05.2023.
//

import SwiftUI

struct MainView: View {
    // Просмотр свойств
    @State var currentTab: Tab = .home
    @Namespace var animation
    init(){
        // Для скрытия собственной панели вкладок
        UITabBar.appearance().isHidden = true
    }
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentTab) {
                
                PostsView()
                    .tag(Tab.home)
                
                ProfileView()
                    .tag(Tab.profile)
            }
            TabBar()
        }
    }
    
    // Пользовательская панель вкладок
    @ViewBuilder
    func TabBar()->some View{
        HStack(spacing: 0){
            ForEach(Tab.allCases,id: \.rawValue){tab in
                Image(tab.rawValue)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(currentTab == tab ? .white : .gray.opacity(10))
                    .offset(y: currentTab == tab ? -30 : 0)
                    .background(content: {
                        if currentTab == tab{
                            Circle()
                                .fill(.black)
                                .scaleEffect(2.5)
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 5, y: 10)
                                .matchedGeometryEffect(id: "TAB", in: animation)
                                .offset(y: currentTab == tab ? -30 : 0)
                        }
                    })
                    .frame(maxWidth: .infinity)
                    .padding(.top,15)
                    .padding(.bottom,10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        currentTab = tab
                    }
            }
        }
        .padding(.horizontal,15)
        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.65, blendDuration: 0.65), value: currentTab)
        .background {
            // кастомныый угол
            CustomCorner(corners: [.topLeft, .topRight], radius: 25)
                .fill(Color("Tab"))
                .ignoresSafeArea()
        }
    }
    
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Исходное значение - это название изображения ресурса
enum Tab: String,CaseIterable{
    case home = "home"
    case profile = "profile"
}
