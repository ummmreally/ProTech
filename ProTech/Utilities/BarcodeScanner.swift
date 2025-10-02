import Foundation
import AVFoundation
import AppKit

class BarcodeScanner: NSObject, ObservableObject {
    @Published var scannedCode: String?
    @Published var isScanning = false
    @Published var error: String?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Camera Scanning
    
    /// Check if camera is available
    func isCameraAvailable() -> Bool {
        return AVCaptureDevice.default(for: .video) != nil
    }
    
    /// Request camera permission
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// Start camera scanning
    func startScanning() {
        guard !isScanning else { return }
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            error = "No camera available"
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            self.error = "Could not create video input: \(error.localizedDescription)"
            return
        }
        
        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        } else {
            error = "Could not add video input"
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .code128,
                .qr,
                .aztec,
                .ean13,
                .ean8,
                .upce
            ]
        } else {
            error = "Could not add metadata output"
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
            DispatchQueue.main.async {
                self?.isScanning = true
            }
        }
    }
    
    /// Stop camera scanning
    func stopScanning() {
        captureSession?.stopRunning()
        captureSession = nil
        isScanning = false
    }
    
    /// Get preview layer for displaying camera feed
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let captureSession = captureSession else { return nil }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        return previewLayer
    }
    
    // MARK: - Manual Input
    
    /// Validate and process manually entered barcode
    func processManualBarcode(_ barcode: String) -> Bool {
        guard !barcode.isEmpty else {
            error = "Barcode cannot be empty"
            return false
        }
        
        scannedCode = barcode
        return true
    }
    
    // MARK: - USB Scanner Support
    
    /// Process barcode from USB scanner (keyboard wedge)
    func processUSBScannerInput(_ input: String) {
        // USB scanners typically send the barcode followed by Enter
        let cleanedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !cleanedInput.isEmpty {
            scannedCode = cleanedInput
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        
        // Vibrate or beep on successful scan
        NSSound.beep()
        
        scannedCode = stringValue
        
        // Stop scanning after successful scan
        stopScanning()
    }
}

// MARK: - Barcode Lookup Service

class BarcodeLookupService {
    static let shared = BarcodeLookupService()
    
    private let coreDataManager = CoreDataManager.shared
    private let barcodeGenerator = BarcodeGenerator.shared
    
    private init() {}
    
    /// Find ticket by barcode
    func findTicket(byBarcode barcode: String) -> Ticket? {
        // Try to extract ticket number from barcode
        if let ticketNumber = barcodeGenerator.extractTicketNumber(from: barcode) {
            return findTicket(byNumber: ticketNumber)
        }
        
        // Try direct ticket number
        if let ticketNumber = Int32(barcode) {
            return findTicket(byNumber: ticketNumber)
        }
        
        // Try parsing QR code data
        let qrData = barcodeGenerator.parseQRCodeData(barcode)
        if let ticketNumberString = qrData["TICKET"],
           let ticketNumber = Int32(ticketNumberString) {
            return findTicket(byNumber: ticketNumber)
        }
        
        // Try finding by UUID if present in QR code
        if let idString = qrData["ID"],
           let uuid = UUID(uuidString: idString) {
            return findTicket(byId: uuid)
        }
        
        return nil
    }
    
    /// Find ticket by ticket number
    private func findTicket(byNumber ticketNumber: Int32) -> Ticket? {
        let request = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "ticketNumber == %d", ticketNumber)
        request.fetchLimit = 1
        
        return try? coreDataManager.viewContext.fetch(request).first
    }
    
    /// Find ticket by ID
    private func findTicket(byId id: UUID) -> Ticket? {
        let request = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? coreDataManager.viewContext.fetch(request).first
    }
    
    /// Get ticket details for display
    func getTicketDetails(_ ticket: Ticket) -> TicketDetails {
        let customer = ticket.customerId != nil ? coreDataManager.fetchCustomer(id: ticket.customerId!) : nil
        
        return TicketDetails(
            ticketNumber: ticket.ticketNumber,
            customerName: customer != nil ? "\(customer!.firstName ?? "") \(customer!.lastName ?? "")" : "Unknown",
            deviceType: ticket.deviceType ?? "Unknown",
            deviceModel: ticket.deviceModel ?? "",
            status: ticket.status ?? "Unknown",
            issueDescription: ticket.issueDescription ?? ""
        )
    }
}

// MARK: - Supporting Types

struct TicketDetails {
    let ticketNumber: Int32
    let customerName: String
    let deviceType: String
    let deviceModel: String
    let status: String
    let issueDescription: String
}
