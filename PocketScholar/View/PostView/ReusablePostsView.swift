//
//  ReusablePostsView.swift
//  PocketScholar
//
//  Created by Дмитрий Цепилов on 07.05.2023.
//

import SwiftUI
import Firebase

struct ReusablePostsView:View {
    var basedOnUID: Bool = false
    var uid: String = ""
    @Binding var posts: [Post]
    // Просмотр свойств
    @State private var isFetching: Bool = true
    @State private var paginationDoc: QueryDocumentSnapshot?
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack{
                if isFetching{
                    ProgressView()
                        .padding(.top,30)
                }else{
                    if posts.isEmpty{
                        // На Firebase сообщение не найдено
                        Text("Постов не найдено")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top,30)
                        
                    }else{
                        // Отображение сообщения
                        Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            // Прокрутите страницу, чтобы обновить
            // Отключение обновления для записей на основе UID
            guard !basedOnUID else {return}
            isFetching = true
            posts = []
            // Сброс разбиения документа на страницы
            paginationDoc = nil
            await fetchPosts()
        }
        .task {
            // Выборка на один раз
            guard posts.isEmpty else{return}
            await fetchPosts()
        }
    }
    
    // Отображение выбранного сообщения
    @ViewBuilder
    func Posts()->some View{
        ForEach(posts){post in
            PostCardView(post: post) { updatedPost in
                // Обновление записи в массиве
                if let index = posts.firstIndex(where: { post in
                    post.id == updatedPost.id
                }){
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs = updatedPost.dislikedIDs
                }
                
            }onDelete: {
                // удаление записи из массива
                withAnimation(.easeInOut(duration: 0.25)){
                    posts.removeAll{post.id == $0.id}
                }
                
            }
            .onAppear {
                // Когда появится последнее сообщение, Извлеките новое сообщение (Если оно есть)
                if post.id == posts.last?.id && paginationDoc != nil{
                    Task{await fetchPosts()}
                }
            }
            
            Divider()
                .padding(.horizontal, -15)
        
        }
    }
    

    // Выборка сообщений
    func fetchPosts()async{
        do{
            var query: Query!
            // Реализация разбивки на страницы
            if let paginationDoc{
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20)
            }else{
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 20)
            }
            
            // Новый запрос для извлечения документа на основе UID
            // Просто отфильтруйте сообщение, которое не принадлежит этому UID
            if basedOnUID{
                query = query
                    .whereField("userUID", isEqualTo: uid)
            }
            
            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
            await MainActor.run(body: {
                posts.append(contentsOf: fetchedPosts)
                paginationDoc = docs.documents.last
                isFetching = false
            })
            
        }catch{
            print(error.localizedDescription)
        }
    }
}


struct ReusablePostsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
