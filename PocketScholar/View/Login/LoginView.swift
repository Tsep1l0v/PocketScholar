//
//  LoginView.swift
//  PocketScholar
//
//  Created by Дмитрий Цепилов on 06.05.2023.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct LoginView: View {
    // Сведения о пользователе
    @State var emailID: String = ""
    @State var password: String = ""
    // Просмотр свойств
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    var body: some View {
        VStack(spacing: 10){
            Text("Вход в научный мир")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("С возвращением, \nНам тебя не хватало")
                .font(.title3)
                .hAlign(.leading)
            
            VStack(spacing: 12){
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top,25)
                
                SecureField("Пароль", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                Button("Сброс пароля", action: resetPassword)
                    .font(.callout)
                    .fontWeight(.medium)
                    .tint(.black)
                    .hAlign(.trailing)
                
                Button(action: loginUser) {
                    // Login Button
                    Text("Вход")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                .padding(.top,10)
            }
            
            // Кнопка регистрации
            HStack{
                Text("У вас нет профиля?")
                    .foregroundColor(.gray)
                
                Button("Регистрация"){
                    createAccount.toggle()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        // Просмотр реестра С ПОМОЩЬЮ таблиц
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        // Отображение предупреждения
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    func loginUser(){
        isLoading = true
        closeKeyboard()
        Task{
            do{
                // С помощью swift concurrency аутентификацию можно выполнить с помощью одной строки
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("Найденный пользователь")
                try await fetchUser()
            }catch{
                await setError(error)
            }
        }
    }
    
    // Если пользователь найден, то извлекаем пользовательские данные из firestore
    func fetchUser()async throws{
        guard let userID = Auth.auth().currentUser?.uid else{return}
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        // Обновление пользовательского интерфейса должно выполняться в основном потоке
        await MainActor.run(body: {
            // Установка пользовательских данных по умолчанию и изменение статуса приложения
            userUID = userID
            userNameStored = user.username
            profileURL = user.userProfileURL
            logStatus = true
        })
    }
    
    func resetPassword(){
        Task{
            do{
                // С помощью swift concurrency аутентификацию можно выполнить с помощью одной строки
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
                print("Отправленная ссылка")
                try await fetchUser()
            }catch{
                await setError(error)
            }
        }
    }
    
    
    // Отображение ошибок с помощью оповещения
    func setError(_ error: Error)async{
        //Пользовательский интерфейс должен быть обновлен в основном потоке
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

