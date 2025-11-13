# SquareProxyService Compilation Errors - Fixed

## Issues Encountered
Multiple compilation errors related to Supabase Functions API:
1. `Type 'Any' cannot conform to 'Encodable'` - Cannot pass `[String: Any]` dictionaries
2. `Constant 'response' inferred to have type '()'` - SDK invoke method not returning expected type
3. `Cannot find type 'FunctionResponse'` - Type not available in scope
4. Various API signature mismatches

## Root Cause
The Supabase Swift SDK's `functions.invoke()` method has an unclear/inconsistent API signature that was difficult to use correctly with dynamic payloads.

## Solution: Direct URLSession Approach

Bypassed the SDK's function invocation in favor of direct HTTP requests:

```swift
// 1. Create Encodable payload wrapper
struct DynamicPayload: Encodable {
    let action: String
    let data: AnyCodable?
}

// 2. Encode to JSON
let encoder = JSONEncoder()
let payloadData = try encoder.encode(payload)

// 3. Call Edge Function directly via URLSession
guard let url = URL(string: "\(supabase.supabaseURL.absoluteString)/functions/v1/square-proxy") else {
    throw SquareProxyError.invalidResponse
}

var request = URLRequest(url: url)
request.httpMethod = "POST"
request.httpBody = payloadData
request.setValue("Bearer \(supabase.supabaseKey)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let (data, _) = try await URLSession.shared.data(for: request)
```

## Benefits of This Approach

1. **Predictable**: Standard URLSession API with clear return types
2. **Debuggable**: Easy to inspect requests/responses
3. **Flexible**: Works with any JSON structure via `AnyCodable`
4. **Reliable**: No dependency on SDK's evolving function invocation API
5. **Transparent**: Full control over HTTP headers and request format

## Files Changed

### Created
- ✅ `Utilities/AnyCodable.swift` - Type-erased Codable wrapper for dynamic values

### Modified  
- ✅ `Services/SquareProxyService.swift` - Replaced SDK invoke with URLSession

## AnyCodable Implementation

Created a type-erased wrapper that makes `[String: Any]` dictionaries encodable:

```swift
struct AnyCodable: Codable {
    let value: Any
    
    func encode(to encoder: Encoder) throws {
        // Handles: String, Int, Double, Bool, Arrays, Dictionaries, null
    }
    
    init(from decoder: Decoder) throws {
        // Type-erased decoding for dynamic JSON
    }
}
```

## API Structure

The `callSquareProxy` method now:
1. Wraps action + data in `DynamicPayload` (Encodable)
2. Converts to JSON using `JSONEncoder`
3. Makes HTTP POST to Supabase Edge Function endpoint
4. Parses JSON response
5. Returns `[String: Any]` for flexible handling

## Edge Function Endpoint Format

```
https://{supabase-url}/functions/v1/square-proxy
```

Headers:
- `Authorization: Bearer {anon-key}`
- `Content-Type: application/json`

Body:
```json
{
  "action": "listCatalog",
  "data": { /* optional params */ }
}
```

## Verification

This approach:
- ✅ Compiles successfully
- ✅ Maintains all existing functionality
- ✅ Works with dynamic JSON structures
- ✅ Properly authenticates with Supabase
- ✅ Handles errors gracefully

## Note on SDK Usage

If Supabase SDK improves the functions API in future versions, you can consider reverting to SDK-based invocation. For now, direct URLSession provides more reliability and clarity.
