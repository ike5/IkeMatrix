//
//  ContentView.swift
//  IkeMatrix
//
//  Created by Ike Maldonado on 7/18/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct TaskItem: Identifiable, Hashable, Codable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

extension TaskItem: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .taskItem)
    }
}

extension UTType {
    static let taskItem = UTType(exportedAs: "com.ikematrix.taskitem", conformingTo: .data)
}

struct ContentView: View {
    @State private var urgentImportant: [TaskItem] = []
    @State private var notUrgentImportant: [TaskItem] = []
    @State private var urgentNotImportant: [TaskItem] = []
    @State private var notUrgentNotImportant: [TaskItem] = []

    @State private var newTaskText = ""
    @State private var selectedQuadrant = 0
    
    @State private var showingInspector = false
    @State private var inspectorQuadrantIndex: Int? = nil
    @State private var inspectorText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var editingTask: TaskItem? = nil

    let quadrantTitles = [
        "Urgent & Important",
        "Not Urgent & Important",
        "Urgent & Not Important",
        "Not Urgent & Not Important"
    ]
    
    let quadrantTitlesPicker = [
        "U + I",
        "NU + I",
        "U + NI",
        "NU + NI"
    ]
    

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<4) { index in
                    SectionView(
                        title: quadrantTitles[index],
                        color: color(for: index),
                        tasks: binding(for: index),
                        onDelete: saveTasks,
                        onTitleTapped: {
                            inspectorQuadrantIndex = index
                            inspectorText = ""
                            editingTask = nil
                            showingInspector = true
                        },
                        onDrop: { task in
                            moveTask(task, to: index)
                        },
                        onEdit: { task in
                            inspectorText = task.text
                            inspectorQuadrantIndex = index
                            editingTask = task
                            showingInspector = true
                        },
                        onDeleteTask: { task in
                            if let idx = binding(for: index).wrappedValue.firstIndex(of: task) {
                                binding(for: index).wrappedValue.remove(at: idx)
                                saveTasks()
                            }
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
        .onAppear() {
            loadTasks()
        }
        .inspector(isPresented: $showingInspector) {
            VStack(spacing: 24) {
                if let _ = editingTask {
                    Text("Edit Task in \(quadrantTitles[inspectorQuadrantIndex ?? 0])")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                } else {
                    Text("Add to \(quadrantTitles[inspectorQuadrantIndex ?? 0])")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                }

                TextField("Describe your task here...", text: $inspectorText)
                    .font(.title2)
                    .padding()
                    .frame(minHeight: 60)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .submitLabel(.done)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        addTaskFromInspector()
                    }

                let trimmedText = inspectorText.trimmingCharacters(in: .whitespaces)
                let isAddMode = editingTask == nil
                let isValid = !trimmedText.isEmpty
                let isModified = editingTask?.text != trimmedText
                let shouldEnable = isAddMode ? isValid : isValid && isModified

                Button(action: {
                    addTaskFromInspector()
                }) {
                    Text(isAddMode ? "Add Task" : "Save Task")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(shouldEnable ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!shouldEnable)
                .padding(.horizontal)

                Button("Cancel") {
                    showingInspector = false
                    editingTask = nil
                }
                .foregroundColor(.red)
                .padding(.bottom)

                Spacer()
            }
            .padding()
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    private func addTaskFromInspector() {
        if let index = inspectorQuadrantIndex, !inspectorText.trimmingCharacters(in: .whitespaces).isEmpty {
            if let task = editingTask {
                if let taskIndex = binding(for: index).wrappedValue.firstIndex(of: task) {
                    binding(for: index).wrappedValue[taskIndex].text = inspectorText.trimmingCharacters(in: .whitespaces)
                }
            } else {
                binding(for: index).wrappedValue.append(TaskItem(text: inspectorText.trimmingCharacters(in: .whitespaces)))
            }
            saveTasks()
            inspectorText = ""
            showingInspector = false
            editingTask = nil
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

    private func moveTask(_ task: TaskItem, to targetIndex: Int) {
        for i in 0..<4 {
            if let index = binding(for: i).wrappedValue.firstIndex(of: task) {
                binding(for: i).wrappedValue.remove(at: index)
                break
            }
        }

        if !binding(for: targetIndex).wrappedValue.contains(task) {
            binding(for: targetIndex).wrappedValue.append(task)
        }

        saveTasks()
    }
}

struct SectionView: View {
    var title: String
    var color: Color
    @Binding var tasks: [TaskItem]
    var onDelete: () -> Void
    var onTitleTapped: () -> Void = { }
    var onDrop: (TaskItem) -> Void
    var onEdit: (TaskItem) -> Void
    var onDeleteTask: (TaskItem) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                
            
            if tasks.isEmpty {
                Text("No tasks yet")
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)

            } else {
                ForEach(tasks) { task in
                    HStack {
                        Text(task.text)
                            .padding(.vertical, 5)
                            .padding(.horizontal)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(5)
                            .foregroundColor(.white)
                            .draggable(task)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .onTapGesture {
                        onEdit(task)
                    }
                    .contextMenu {
                        Button("Edit") { onEdit(task) }
                        Button("Delete", role: .destructive) { onDeleteTask(task) }
                    }
                }
            }
        }
        .padding()
        .background(color)
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
        .onTapGesture {
            onTitleTapped()
        }
        .dropDestination(for: TaskItem.self) { droppedItems, location in
            if let item = droppedItems.first {
                onDrop(item)
                return true
            }
            return false
        }
    }
}

#Preview {
    ContentView()
}
