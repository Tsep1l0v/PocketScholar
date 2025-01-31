//
//  PostCardView.swift
//  PocketScholar
//
//  Created by Дмитрий Цепилов on 07.05.2023.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct PostCardView: View {
    var post: Post
    // Обратные вызовы
    var onUpdate: (Post)->()
    var onDelete: ()->()
    // Просмотр свойств
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var docListner: ListenerRegistration?
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical,8)
                
                // Post Image If any
                if let postImageURL = post.imageURL{
                    GeometryReader{
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
                PostInteraction()
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            // Отображение кнопки "Удалено" (если это автор этого поста)
            if post.userUID == userUID{
                Menu {
                    Button("Удалить Пост", role: .destructive, action: deletedPost)
                }label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundColor(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)
            }
        })
        .onAppear {
            // Добавление только один раз
            if docListner == nil{
                guard let postID = post.id else {return}
                docListner = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({ snapshot,
                    error in
                    if let snapshot{
                        if snapshot.exists{
                            // Документ обновлен
                            // Получение обновленного документа
                            if let updatedPost = try? snapshot.data(as: Post.self){
                                onUpdate(updatedPost)
                            }
                        }else{
                            // Документ удален
                            onDelete()
                        }
                    }
                })
                
            }
        }
        .onDisappear{
            // Применение прослушивателя моментальных снимков только тогда, когда запись доступна на экране
            // Иначе удаление прослушивателя сохранит нежелательные текущие обновления из сообщений, которые были удалены с экрана
            if let docListner{
                docListner.remove()
                self.docListner = nil
            }
        }
    }
    // Взаимодействие "Нравится"/"Не нравится"
    @ViewBuilder
    func PostInteraction()->some View {
        HStack(spacing: 6) {
            Button(action: likePost) {
                Image(systemName: post.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: dislikePost) {
             Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .padding(.leading,25)
            
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
        }
        .foregroundColor(.black)
        .padding(.vertical,8)
    }
    
    // Сообщение с лайком
    func likePost(){
        Task{
            guard let postID = post.id else{return}
            if post.likedIDs.contains(userUID){
                // Удаление идентификатора пользователя из массива
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
                
            }else{
                // Добавление идентификатора пользователя в массив понравившихся и удаление присяжных из смещенного массива (если добавлено ранее)
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID]),
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            }
        }
    }
    
    // не нравится пост
    func dislikePost(){
        Task{
            guard let postID = post.id else{return}
            if post.dislikedIDs.contains(userUID){
                // Удаление идентификатора пользователя из массива
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
                
            }else{
                // Добавление идентификатора пользователя в массив понравившихся и удаление присяжных из смещенного массива (если добавлено ранее)
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID]),
                    "dislikedIDs": FieldValue.arrayUnion([userUID])
                ])
            }
        }
    }
    
    // удаление поста
    func deletedPost(){
        Task{
            // Шаг 1: Удалите изображение из хранилища Firebase, если оно присутствует
            do{
                if post.imageReferenceID != ""{
                    try await Storage.storage().reference().child("Post_Images").child(post.imageReferenceID).delete()
                    
                }
                // Шаг 2: Удалите документ Firestore
                guard let postID = post.id else{return}
                try await Firestore.firestore().collection("Posts").document(postID).delete()
                
            }catch{
                print(error.localizedDescription)
            }
        }
    }
}

