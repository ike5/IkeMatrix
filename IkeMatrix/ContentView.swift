//
//  ContentView.swift
//  IkeMatrix
//
//  Created by Ike Maldonado on 7/18/25.
//

import SwiftUI

struct TaskItem: Identifiable, Hashable, Codable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

struct ContentView: View {
    @State private var urgentImportant: [TaskItem] = []
    @State private var notUrgentImportant: [TaskItem] = []
    @State private var urgentNotImportant: [TaskItem] = []
    @State private var notUrgentNotImportant: [TaskItem] = []

    @State private var newTaskText = ""
    @State private var selectedQuadrant = 0

    let quadrantTitles = [
        "Urgent & Important",
        "Not Urgent & Important",
        "Urgent & Not Important",
        "Not Urgent & Not Important"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<4) { index in
                    SectionView(
                        title: quadrantTitles[index],
                        color: color(for: index),
                        tasks: binding(for: index),
                        onDelete: saveTasks
                    )
                }

                VStack {
                    TextField("New Task", text: $newTaskText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Picker("Quadrant", selection: $selectedQuadrant) {
                        ForEach(0..<4) { index in
                            Text(quadrantTitles[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    Button("Add Task") {
                        addTask()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .onAppear() {
            loadTasks()
        }
    }

    private func binding(for index: Int) -> Binding<[TaskItem]> {
        switch index {
        case 0: return $urgentImportant
        case 1: return $notUrgentImportant
        case 2: return $urgentNotImportant
        case 3: return $notUrgentNotImportant
        default: return .constant([])
        }
    }

    private func color(for index: Int) -> Color {
        switch index {
        case 0: return .red.opacity(0.8)
        case 1: return .green.opacity(0.8)
        case 2: return .orange.opacity(0.8)
        case 3: return .gray.opacity(0.6)
        default: return .clear
        }
    }

    private func addTask() {
        guard !newTaskText.isEmpty else { return }
        let newTask = TaskItem(text: newTaskText)
        binding(for: selectedQuadrant).wrappedValue.append(newTask)
        newTaskText = ""
        saveTasks()
    }
    
    let storageKeys = [
        "urgentImportant",
        "notUrgentImportant",
        "urgentNotImportant",
        "notUrgentNotImportant"
    ]

    func saveTasks() {
        let encoder = JSONEncoder()
        let allTasks = [urgentImportant, notUrgentImportant, urgentNotImportant, notUrgentNotImportant]
        for (index, tasks) in allTasks.enumerated() {
            if let data = try? encoder.encode(tasks) {
                UserDefaults.standard.set(data, forKey: storageKeys[index])
            }
        }
    }

    func loadTasks() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: storageKeys[0]),
           let decoded = try? decoder.decode([TaskItem].self, from: data) {
            urgentImportant = decoded
        }
        if let data = UserDefaults.standard.data(forKey: storageKeys[1]),
           let decoded = try? decoder.decode([TaskItem].self, from: data) {
            notUrgentImportant = decoded
        }
        if let data = UserDefaults.standard.data(forKey: storageKeys[2]),
           let decoded = try? decoder.decode([TaskItem].self, from: data) {
            urgentNotImportant = decoded
        }
        if let data = UserDefaults.standard.data(forKey: storageKeys[3]),
           let decoded = try? decoder.decode([TaskItem].self, from: data) {
            notUrgentNotImportant = decoded
        }
    }
}

struct SectionView: View {
    var title: String
    var color: Color
    @Binding var tasks: [TaskItem]
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)

            ForEach(tasks) { task in
                HStack {
                    Text(task.text)
                        .padding(.vertical, 5)
                        .padding(.horizontal)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(5)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        if let index = tasks.firstIndex(of: task) {
                            tasks.remove(at: index)
                            onDelete()
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(color)
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
