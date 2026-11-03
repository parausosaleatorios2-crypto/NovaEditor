//
//  NovaZip.swift
//
//  Leitor/escritor ZIP minimalista (STORE + DEFLATE via Compression.framework),
//  pensado apenas pro formato .nova. Zero dependências externas.
//
//  Formato implementado: ZIP tradicional 32-bit (sem zip64), com Local File
//  Header + Central Directory + End of Central Directory.
//

import Foundation
#if canImport(Compression)
import Compression
#endif

public enum NovaZipError: Error, Equatable {
    case malformed(String)
    case unsupportedCompression(UInt16)
    case decompressionFailed
}

public enum NovaZip {

    // MARK: Read

    /// Devolve um dicionário [path: conteudo].
    public static func read(_ data: Data) throws -> [String: Data] {
        let eocd = try findEOCD(in: data)
        let cdOffset  = Int(readU32(data, eocd + 16))
        let cdEntries = Int(readU16(data, eocd + 10))

        var entries: [String: Data] = [:]
        var p = cdOffset
        for _ in 0..<cdEntries {
            guard readU32(data, p) == 0x02014b50 else {
                throw NovaZipError.malformed("central header magic @\(p)")
            }
            let method   = readU16(data, p + 10)
            let compSize = Int(readU32(data, p + 20))
            let uncSize  = Int(readU32(data, p + 24))
            let nameLen  = Int(readU16(data, p + 28))
            let extraLen = Int(readU16(data, p + 30))
            let commLen  = Int(readU16(data, p + 32))
            let lfhOff   = Int(readU32(data, p + 42))
            let name = String(data: data.subdata(in: (p+46)..<(p+46+nameLen)), encoding: .utf8) ?? ""

            // Local File Header to find data start
            guard readU32(data, lfhOff) == 0x04034b50 else {
                throw NovaZipError.malformed("local header magic @\(lfhOff)")
            }
            let lNameLen  = Int(readU16(data, lfhOff + 26))
            let lExtraLen = Int(readU16(data, lfhOff + 28))
            let dataStart = lfhOff + 30 + lNameLen + lExtraLen
            let compressed = data.subdata(in: dataStart..<(dataStart + compSize))
            let payload: Data
            switch method {
            case 0:  payload = compressed // STORE
            case 8:  payload = try inflate(compressed, uncompressedSize: uncSize) // DEFLATE
            default: throw NovaZipError.unsupportedCompression(method)
            }
            if !name.hasSuffix("/") { entries[name] = payload }
            p += 46 + nameLen + extraLen + commLen
        }
        return entries
    }

    // MARK: Write

    /// Escreve ZIP com DEFLATE (fallback STORE para payloads pequenos).
    public static func write(_ entries: [(String, Data)]) -> Data {
        var out = Data()
        var central = Data()
        var count: UInt16 = 0

        for (name, payload) in entries {
            let nameBytes = Array(name.utf8)
            let crc = crc32(payload)
            let (method, stored): (UInt16, Data) = {
                if let d = try? deflate(payload), d.count < payload.count {
                    return (8, d)
                }
                return (0, payload)
            }()
            let offset = UInt32(out.count)

            // Local File Header
            out.append(contentsOf: u32(0x04034b50))
            out.append(contentsOf: u16(20))      // version needed
            out.append(contentsOf: u16(0))       // flags
            out.append(contentsOf: u16(method))  // method
            out.append(contentsOf: u16(0))       // mtime
            out.append(contentsOf: u16(0))       // mdate
            out.append(contentsOf: u32(crc))
            out.append(contentsOf: u32(UInt32(stored.count)))
            out.append(contentsOf: u32(UInt32(payload.count)))
            out.append(contentsOf: u16(UInt16(nameBytes.count)))
            out.append(contentsOf: u16(0))
            out.append(contentsOf: nameBytes)
            out.append(stored)

            // Central Directory Header
            central.append(contentsOf: u32(0x02014b50))
            central.append(contentsOf: u16(20))                      // ver made by
            central.append(contentsOf: u16(20))                      // ver needed
            central.append(contentsOf: u16(0))                       // flags
            central.append(contentsOf: u16(method))
            central.append(contentsOf: u16(0))                       // mtime
            central.append(contentsOf: u16(0))                       // mdate
            central.append(contentsOf: u32(crc))
            central.append(contentsOf: u32(UInt32(stored.count)))
            central.append(contentsOf: u32(UInt32(payload.count)))
            central.append(contentsOf: u16(UInt16(nameBytes.count)))
            central.append(contentsOf: u16(0))                       // extra
            central.append(contentsOf: u16(0))                       // comment
            central.append(contentsOf: u16(0))                       // disk
            central.append(contentsOf: u16(0))                       // int attrs
            central.append(contentsOf: u32(0))                       // ext attrs
            central.append(contentsOf: u32(offset))
            central.append(contentsOf: nameBytes)
            count += 1
        }
        let cdOffset = UInt32(out.count)
        let cdSize   = UInt32(central.count)
        out.append(central)

        // End Of Central Directory
        out.append(contentsOf: u32(0x06054b50))
        out.append(contentsOf: u16(0))
        out.append(contentsOf: u16(0))
        out.append(contentsOf: u16(count))
        out.append(contentsOf: u16(count))
        out.append(contentsOf: u32(cdSize))
        out.append(contentsOf: u32(cdOffset))
        out.append(contentsOf: u16(0))
        return out
    }

    // MARK: - helpers

    static func findEOCD(in data: Data) throws -> Int {
        let maxComment = 65535 + 22
        let end = data.count
        let start = max(0, end - maxComment)
        for i in stride(from: end - 22, through: start, by: -1) {
            if readU32(data, i) == 0x06054b50 { return i }
        }
        throw NovaZipError.malformed("EOCD not found")
    }

    static func readU16(_ d: Data, _ off: Int) -> UInt16 {
        return UInt16(d[off]) | (UInt16(d[off+1]) << 8)
    }
    static func readU32(_ d: Data, _ off: Int) -> UInt32 {
        return UInt32(d[off]) | (UInt32(d[off+1]) << 8) | (UInt32(d[off+2]) << 16) | (UInt32(d[off+3]) << 24)
    }
    static func u16(_ v: UInt16) -> [UInt8] { [UInt8(v & 0xff), UInt8((v >> 8) & 0xff)] }
    static func u32(_ v: UInt32) -> [UInt8] { [UInt8(v & 0xff), UInt8((v >> 8) & 0xff), UInt8((v >> 16) & 0xff), UInt8((v >> 24) & 0xff)] }

    // DEFLATE / INFLATE via Compression.framework (disponível no iOS 9+/macOS 10.11+)
    static func deflate(_ data: Data) throws -> Data {
        #if canImport(Compression)
        return try data.withUnsafeBytes { raw -> Data in
            let src = raw.bindMemory(to: UInt8.self).baseAddress!
            let dstCap = max(data.count, 64)
            let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCap)
            defer { dst.deallocate() }
            let n = compression_encode_buffer(dst, dstCap, src, data.count, nil, COMPRESSION_ZLIB)
            guard n > 0 else { throw NovaZipError.decompressionFailed }
            return Data(bytes: dst, count: n)
        }
        #else
        return data
        #endif
    }

    static func inflate(_ data: Data, uncompressedSize: Int) throws -> Data {
        #if canImport(Compression)
        return try data.withUnsafeBytes { raw -> Data in
            let src = raw.bindMemory(to: UInt8.self).baseAddress!
            let cap = max(uncompressedSize, 1)
            let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: cap)
            defer { dst.deallocate() }
            let n = compression_decode_buffer(dst, cap, src, data.count, nil, COMPRESSION_ZLIB)
            guard n > 0 else { throw NovaZipError.decompressionFailed }
            return Data(bytes: dst, count: n)
        }
        #else
        return data
        #endif
    }

    // CRC-32 (IEEE 802.3)
    static let crcTable: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 { c = (c & 1) == 1 ? 0xEDB88320 ^ (c >> 1) : (c >> 1) }
            return c
        }
    }()
    static func crc32(_ data: Data) -> UInt32 {
        var c: UInt32 = 0xFFFFFFFF
        for b in data { c = crcTable[Int((c ^ UInt32(b)) & 0xff)] ^ (c >> 8) }
        return c ^ 0xFFFFFFFF
    }
}
