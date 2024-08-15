//
//  RegisterView.swift
//  PocketScholar
//
//  Created by Дмитрий Цепилов on 06.05.2023.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

// Просмотр регистра
struct RegisterView: View{
    // Сведения о пользователе
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilePicData: Data?
    // Просмотр свойств
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    // Пользовательские ошибки
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    var body: some View{
        VStack(spacing: 10){
            Text("Регистрация\nАккаунта")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Привет пользователь, удачного путешествия")
                .font(.title3)
                .hAlign(.leading)
            
            // Для оптимизации меньших размеров
            ViewThatFits {
                ScrollView(.vertical, showsIndicators: false) {
                    HelperView()
                }
                
                HelperView()
            }
            
            // Кнопка регистрации
            HStack{
                Text("У вас уже есть профиль?")
                    .foregroundColor(.gray)
                
                Button("Войти"){
                    dismiss()
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
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { newValue in
            // Извлечение UIImage из элемента фотографии
            if let newValue{
                Task{
                    do{
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else{return}
                        // Пользовательский интерфейс должен быть обновлен в основном потоке
                        await MainActor.run(body: {
                            userProfilePicData = imageData
                        })
                    }
                }
            }
        }
        // Отображение предупреждения
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    @ViewBuilder
    func HelperView()->some View{
        VStack(spacing: 12){
            ZStack{
                if let userProfilePicData,let image = UIImage(data: userProfilePicData){
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }else{
                    Image("NullProfile")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top,25)
            
            
            TextField("Имя", text: $userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                
            
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            SecureField("Пароль", text: $password)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("О вас", text: $userBio,axis: .vertical)
                .frame(minHeight: 100,alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Ссылка на соцсеть (необязательно)", text: $userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            
            Button(action: registerUser) {

                Text("Регистрация")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .disableWithOpacity(userName == "" || userBio == "" || emailID == "" || password == "" || userProfilePicData == nil)
            .padding(.top,10)
        }
    }
    
    func registerUser() {
        isLoading = true
        closeKeyboard()
        Task{
            do{
               // Шаг 1: Создание учетной записи Firebase
                try await Auth.auth().createUser(withEmail: emailID, password: password)
                //Шаг 2: Загрузка фотографии профиля в хранилище Firebase
                guard let userUID = Auth.auth().currentUser?.uid else {return}
                guard let imageData = userProfilePicData else {return}
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                // Шаг 3: Загрузка URL-адреса фотографии
                let downloadURL = try await storageRef.downloadURL()
                // Шаг 4: Создание пользовательского объекта Firestore
                let user = User(username: userName, userBio: userBio, userBioLink: userBioLink, userUID: userUID, userEmail: emailID, userProfileURL: downloadURL)
                // Шаг 5: Сохранение пользовательского документа в базу данных Firestore
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: {
                    error in
                    if error == nil{
                        // Печать успешно сохранена
                        print("Сохранено успешно")
                        userNameStored = userName
                        self.userUID = userName
                        profileURL = downloadURL
                        logStatus = true
                }
                })
            }catch{
                // Удаление созданной учетной записи в случае сбоя
                try await Auth.auth().currentUser?.delete()
                await setError(error)
            }
        }
    }
    // Отображение ошибок с помощью оповещения
    func setError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
    
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
