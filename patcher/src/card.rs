fn encode_word(previous: u32, plain: u32) -> u32 {
    if previous & 0x800000 == 0 {
        (plain ^ previous ^ 0x360fa955).rotate_left(16) ^ 0x9e3b16a2
    } else {
        (plain ^ previous ^ 0xef4a9ab6).swap_bytes() ^ 0x764e28ca
    }
}

fn decode(data: &[u8]) -> Result<Vec<u8>, String> {
    if data.len() < 20 || data.len() % 4 != 0 || &data[..4] != b"ELUP" {
        return Err("invalid ELUP header or size".into());
    }
    let mut previous = u32::from_be_bytes(data[4..8].try_into().unwrap());
    let mut payload = Vec::new();
    let mut checksum = 0u32;
    for (index, bytes) in data[8..].chunks_exact(4).enumerate() {
        let cipher = u32::from_be_bytes(bytes.try_into().unwrap());
        let plain = previous ^ if previous & 0x800000 == 0 {
            (cipher ^ 0x9e3b16a2).rotate_right(16) ^ 0x360fa955
        } else {
            (cipher ^ 0x764e28ca).swap_bytes() ^ 0xef4a9ab6
        };
        previous = cipher;
        if 8 + (index + 1) * 4 == data.len() {
            if plain != checksum {
                return Err("ELUP checksum differs".into());
            }
        } else {
            checksum = checksum.wrapping_add(plain);
            payload.extend_from_slice(&plain.to_be_bytes());
        }
    }
    let size = u32::from_be_bytes(payload[..4].try_into().unwrap()) as usize;
    if size > payload.len() - 4 || payload.len() - 4 - size > 3
        || payload[4 + size..].iter().any(|byte| *byte != 0)
    {
        return Err("ELUP payload length or padding differs".into());
    }
    Ok(payload[4..4 + size].to_vec())
}

pub fn encode(container: &[u8]) -> Result<Vec<u8>, String> {
    let size = u32::try_from(container.len()).map_err(|_| "ELUP container is too large")?;
    let mut payload = size.to_be_bytes().to_vec();
    payload.extend_from_slice(container);
    payload.resize(payload.len().div_ceil(4) * 4, 0);
    let mut previous = 0x2f1349d2u32;
    let mut output = b"ELUP".to_vec();
    output.extend_from_slice(&previous.to_be_bytes());
    let mut checksum = 0u32;
    for bytes in payload.chunks_exact(4) {
        let plain = u32::from_be_bytes(bytes.try_into().unwrap());
        checksum = checksum.wrapping_add(plain);
        previous = encode_word(previous, plain);
        output.extend_from_slice(&previous.to_be_bytes());
    }
    output.extend_from_slice(&encode_word(previous, checksum).to_be_bytes());
    if decode(&output)? != container {
        return Err("ELUP container round trip differs".into());
    }
    Ok(output)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn transport_preserves_all_bytes_and_padding_lengths() {
        for size in 256..260 {
            let data: Vec<u8> = (0u8..=255).cycle().take(size).collect();
            assert_eq!(decode(&encode(&data).unwrap()).unwrap(), data);
        }
    }

    #[test]
    fn damaged_checksum_is_rejected() {
        let mut encoded = encode(b"synthetic container").unwrap();
        *encoded.last_mut().unwrap() ^= 1;
        assert!(decode(&encoded).unwrap_err().contains("checksum"));
    }
}
