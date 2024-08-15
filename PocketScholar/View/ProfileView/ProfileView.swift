//
//  ProfileView.swift
//  PocketScholar
//
//  Created by Дмитрий Цепилов on 06.05.2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore


struct ProfileView: View {
    // Данные моего профиля
    @State private var myProfile: User?
    @AppStorage("log_status") var logStatus: Bool = false
    // Просмотр свойств
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    var body: some View {
        NavigationStack{
            VStack{
                if let myProfile{
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            // Обновить пользовательские данные
                            self.myProfile = nil
                            await fetchUserData()
                        }
                }else{
                    ProgressView()
                }
            }
            
            .navigationTitle("Мой профиль")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Два действия
                        // 1. Выход из системы
                        // 2. Удалить учетную запись
                        Button("Выход", action: logOutUser)
                        
                        Button("Удаление аккаунта",role: .destructive, action: deleteAccount)
                        }label: {
                            Image(systemName: "ellipsis")
                                .rotationEffect(.init(degrees: 90))
                                .tint(.black)
                                .scaleEffect(0.8)
                        }
                    }
                }
            }
        .overlay {
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError) {
            
        }
        .task {
            // Этот модификатор похож на появившийся
            // Таким образом, выборка выполняется только в первый раз
            if myProfile != nil{return}
            // Начальная выборка
            await fetchUserData()
        }
    }
    
    // Извлечение пользовательских данных
    func fetchUserData()async{
        guard let userUID = Auth.auth().currentUser?.uid else{return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else{return}
        await MainActor.run(body: {
            myProfile = user
        })
    }
    
    // Выход пользователя из системы
    func logOutUser(){
        try? Auth.auth().signOut()
        logStatus = false
    }
    
    // Удаление всей учетной записи пользователя
    func deleteAccount(){
        isLoading = true
        Task{
            do{
                guard let userUID = Auth.auth().currentUser?.uid else{return}
                // Шаг 1: Сначала Удалите Изображение профиля из Хранилища
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                // Шаг 2: Удаление пользовательского документа Firestore
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                // Заключительный шаг: Удаление учетной записи авторизации и установка статуса журнала в False
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            }catch{
                await setError(error)
            }
        }
    }
    
    // Ошибка настройки
    func setError(_ error: Error)async{
        // Пользовательский интерфейс должен быть запущен в основном потоке
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}


    
    struct ProfileView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
