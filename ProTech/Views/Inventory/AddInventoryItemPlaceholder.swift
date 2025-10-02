import SwiftUI

struct AddInventoryItemView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("Add Inventory Item")
                .font(.title2)
                .bold()
            Text("The full add-item workflow is coming soon. In the meantime you can create items directly from the dashboard or list views once the editor is implemented.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(width: 400, height: 300)
    }
}

struct EditInventoryItemView: View {
    @Environment(\.dismiss) private var dismiss
    let item: InventoryItem

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit \(item.name ?? "Inventory Item")")
                .font(.title3)
                .bold()
            Text("Editing is not yet available in this preview build.")
                .foregroundColor(.secondary)
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(width: 400, height: 250)
    }
}

struct StockAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    let item: InventoryItem

    var body: some View {
        VStack(spacing: 16) {
            Text("Adjust Stock for \(item.name ?? "Item")")
                .font(.title3)
                .bold()
            Text("Stock adjustments will be available soon.")
                .foregroundColor(.secondary)
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .frame(width: 400, height: 250)
    }
}
